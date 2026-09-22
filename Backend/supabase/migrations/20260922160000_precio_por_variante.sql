-- ----------------------------------------------------------------------------
-- Cada sabor puede costar lo suyo
--
-- POR QUE: la version anterior daba por hecho que los sabores valen lo mismo,
-- y en el campus no siempre es asi: la empanada de queso a 8 y la de carne a
-- 10 son el mismo producto con la misma foto. Sin esto, quien vende tiene que
-- volver a publicar por separado, que es justo lo que las variantes vinieron
-- a evitar.
--
-- El precio es OPCIONAL: nulo significa "vale lo que el producto". Asi las
-- variantes que ya existen siguen funcionando sin tocarlas, y quien tiene
-- todos sus sabores al mismo precio no tiene que escribirlo doce veces.
-- ----------------------------------------------------------------------------

alter table public.product_variants
  add column if not exists price numeric(10,2);

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'product_variants_precio_positivo'
  ) then
    alter table public.product_variants
      add constraint product_variants_precio_positivo
      check (price is null or price > 0);
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- crear_pedido cobra el precio del sabor elegido
--
-- El precio sigue SIN aceptarse del cliente: llega el id de la variante y el
-- servidor lee de la base cuanto vale. Si la variante no tiene precio propio,
-- se cobra el del producto, como hasta ahora.
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
  v_precio     numeric(10,2);
  v_hay_sabores boolean;
begin
  if v_buyer_id is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

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

    if v_producto.kind = 'producto' and v_producto.stock < v_cantidad then
      raise exception 'STOCK_INSUFICIENTE: % (disponible %)',
        v_producto.name, v_producto.stock using errcode = '22023';
    end if;

    v_variante := nullif(v_item->>'variant_id', '')::uuid;
    v_sabor := null;
    -- Por defecto manda el precio del producto.
    v_precio := v_producto.price;

    select exists (
      select 1 from public.product_variants
       where product_id = v_producto.id and is_available
    ) into v_hay_sabores;

    if v_variante is not null then
      -- Que la variante sea de ESTE producto: con el id suelto se podria
      -- colar el sabor de otra publicacion, y ahora tambien su precio.
      select name, coalesce(price, v_producto.price)
        into v_sabor, v_precio
        from public.product_variants
       where id = v_variante
         and product_id = v_producto.id
         and is_available;

      if v_sabor is null then
        raise exception 'VARIANTE_NO_DISPONIBLE: %', v_producto.name
          using errcode = '22023';
      end if;
    elsif v_hay_sabores then
      raise exception 'VARIANTE_REQUERIDA: %', v_producto.name
        using errcode = '22023';
    end if;

    insert into public.order_items (
      order_id, product_id, product_name, product_emoji, unit_price, quantity,
      variant_name
    )
    values (
      v_order_id, v_producto.id, v_producto.name, v_producto.emoji,
      v_precio, v_cantidad, v_sabor
    );

    v_subtotal := v_subtotal + (v_precio * v_cantidad);
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
