-- ----------------------------------------------------------------------------
-- Variantes de una publicacion: los sabores de un mismo producto
--
-- POR QUE: una empanada de queso y una de carne son el mismo producto, la
-- misma foto, el mismo precio y el mismo vendedor. Sin esto hay que publicar
-- una por cada sabor, el catalogo se llena de copias y quien vende tiene que
-- editar el precio en cinco sitios cuando sube.
--
-- Deliberadamente minimo: una variante es un nombre y nada mas. Sin precio
-- propio y sin stock propio, porque el caso que se pidio es el de comida, y
-- ahi los sabores valen lo mismo. Meter precio por variante obligaria a
-- tocar el carrito, el total del pedido y el historial, y a cambio resolveria
-- un problema que todavia nadie tiene.
-- ----------------------------------------------------------------------------

create table if not exists public.product_variants (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  name       text not null,
  position   integer not null default 0,
  -- El sabor que hoy se acabo. Se apaga en vez de borrarse para que los
  -- pedidos viejos sigan nombrandolo y para no volver a escribirlo manana.
  is_available boolean not null default true,
  created_at timestamptz not null default now(),

  constraint product_variants_nombre_no_vacio check (length(trim(name)) > 0),
  constraint product_variants_nombre_corto     check (length(name) <= 40),
  -- Dos sabores con el mismo nombre en un producto no significan nada y
  -- convierten el desplegable en una adivinanza.
  constraint product_variants_sin_repetidos    unique (product_id, name)
);

create index if not exists product_variants_producto_idx
  on public.product_variants(product_id, position);

alter table public.product_variants enable row level security;

-- Se leen como se lee el catalogo: cualquiera autenticado.
create policy variantes_lectura_publica on public.product_variants
  for select to authenticated using (true);

create policy variantes_del_dueno on public.product_variants
  for all to authenticated
  using (
    exists (
      select 1 from public.products p
        join public.stores s on s.id = p.store_id
       where p.id = product_variants.product_id and s.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.products p
        join public.stores s on s.id = p.store_id
       where p.id = product_variants.product_id and s.owner_id = auth.uid()
    )
  );

grant select, insert, update, delete on public.product_variants to authenticated;

-- ----------------------------------------------------------------------------
-- El sabor elegido, congelado en la linea del pedido
--
-- Igual que product_name y product_emoji: el vendedor puede renombrar o
-- retirar un sabor manana, y el pedido de hoy tiene que seguir diciendo que
-- fue lo que se pidio.
-- ----------------------------------------------------------------------------
alter table public.order_items
  add column if not exists variant_name text;

-- ----------------------------------------------------------------------------
-- crear_pedido acepta la variante elegida
--
-- Entrada: [{"product_id": "...", "quantity": 2, "variant_id": "..."}, ...]
--
-- Igual que con los precios, el nombre del sabor NO se acepta del cliente: se
-- manda el id y el servidor lee el nombre. Y se comprueba que la variante sea
-- de ese producto: sin eso se podria pedir "empanada de carne" mandando el id
-- de un sabor de otro vendedor.
-- ----------------------------------------------------------------------------
create or replace function public.crear_pedido(
  p_items              jsonb,
  p_meeting_point_id   uuid default null,
  p_meeting_point_note text default null,
  p_buyer_note         text default null,
  p_ventana_minutos    integer default 15
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer_id   uuid := auth.uid();
  v_store_id   uuid;
  v_seller_id  uuid;
  v_delivery   numeric(10,2);
  v_subtotal   numeric(10,2) := 0;
  v_order_id   uuid;
  v_item       jsonb;
  v_producto   public.products%rowtype;
  v_cantidad   integer;
  v_locales    integer;
  v_variante   uuid;
  v_sabor      text;
  v_hay_sabores boolean;
begin
  if v_buyer_id is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  -- Onboarding obligatorio antes de pedir (requisito del spec).
  if not exists (
    select 1 from public.profiles
     where id = v_buyer_id and onboarding_completed
  ) then
    raise exception 'ONBOARDING_INCOMPLETO: completa tu perfil antes de pedir'
      using errcode = '42501';
  end if;

  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'CARRITO_VACIO' using errcode = '22023';
  end if;

  -- Un pedido = un local. Simplifica la coordinacion de entrega y evita que
  -- el vendedor A vea items que no le corresponden.
  select count(distinct pr.store_id)
    into v_locales
    from jsonb_array_elements(p_items) as it
    join public.products pr on pr.id = (it->>'product_id')::uuid;

  if v_locales = 0 then
    raise exception 'PRODUCTOS_INEXISTENTES' using errcode = '22023';
  end if;
  if v_locales > 1 then
    raise exception 'CARRITO_MULTIPLE_LOCAL: haz un pedido por cada local'
      using errcode = '22023';
  end if;

  select pr.store_id into v_store_id
    from jsonb_array_elements(p_items) as it
    join public.products pr on pr.id = (it->>'product_id')::uuid
   limit 1;

  select s.owner_id, s.delivery_cost
    into v_seller_id, v_delivery
    from public.stores s
   where s.id = v_store_id and s.is_active and s.is_open;

  if v_seller_id is null then
    raise exception 'LOCAL_CERRADO: el local no esta disponible ahora'
      using errcode = '22023';
  end if;

  if v_seller_id = v_buyer_id then
    raise exception 'AUTOCOMPRA_NO_PERMITIDA' using errcode = '22023';
  end if;

  insert into public.orders (
    buyer_id, store_id, seller_id, status,
    delivery_cost, meeting_point_id, meeting_point_note, buyer_note, expires_at
  )
  values (
    v_buyer_id, v_store_id, v_seller_id, 'solicitado',
    v_delivery, p_meeting_point_id, p_meeting_point_note, p_buyer_note,
    now() + make_interval(mins => greatest(p_ventana_minutos, 1))
  )
  returning id into v_order_id;

  -- Snapshots por linea: nombre, emoji, sabor y precio quedan congelados.
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_cantidad := coalesce((v_item->>'quantity')::integer, 0);
    if v_cantidad <= 0 then
      raise exception 'CANTIDAD_INVALIDA' using errcode = '22023';
    end if;

    select * into v_producto
      from public.products
     where id = (v_item->>'product_id')::uuid
       and is_available;

    if not found then
      raise exception 'PRODUCTO_NO_DISPONIBLE: %', v_item->>'product_id'
        using errcode = '22023';
    end if;

    -- Aviso temprano; el control real (atomico) ocurre en aceptar_pedido.
    if v_producto.kind = 'producto' and v_producto.stock < v_cantidad then
      raise exception 'STOCK_INSUFICIENTE: % (disponible %)',
        v_producto.name, v_producto.stock using errcode = '22023';
    end if;

    v_variante := nullif(v_item->>'variant_id', '')::uuid;
    v_sabor := null;

    select exists (
      select 1 from public.product_variants
       where product_id = v_producto.id and is_available
    ) into v_hay_sabores;

    if v_variante is not null then
      -- Que la variante sea de ESTE producto: con el id suelto se podria
      -- colar el sabor de otra publicacion en la linea del pedido.
      select name into v_sabor
        from public.product_variants
       where id = v_variante
         and product_id = v_producto.id
         and is_available;

      if v_sabor is null then
        raise exception 'VARIANTE_NO_DISPONIBLE: %', v_producto.name
          using errcode = '22023';
      end if;
    elsif v_hay_sabores then
      -- Con sabores publicados, pedir "la empanada" a secas deja al vendedor
      -- sin saber cual preparar.
      raise exception 'VARIANTE_REQUERIDA: %', v_producto.name
        using errcode = '22023';
    end if;

    insert into public.order_items (
      order_id, product_id, product_name, product_emoji, unit_price, quantity,
      variant_name
    )
    values (
      v_order_id, v_producto.id, v_producto.name, v_producto.emoji,
      v_producto.price, v_cantidad, v_sabor
    );

    v_subtotal := v_subtotal + (v_producto.price * v_cantidad);
  end loop;

  update public.orders
     set subtotal = v_subtotal,
         total    = v_subtotal + v_delivery
   where id = v_order_id;

  perform public.registrar_evento_pedido(
    v_order_id, v_buyer_id, null, 'solicitado', v_seller_id,
    'pedido_recibido', 'Nuevo pedido',
    'Tienes un pedido por Bs ' || to_char(v_subtotal + v_delivery, 'FM999999990.00')
  );

  return v_order_id;
end;
$$;

revoke all on function public.crear_pedido(jsonb, uuid, text, text, integer) from public;
grant execute on function public.crear_pedido(jsonb, uuid, text, text, integer) to authenticated;
