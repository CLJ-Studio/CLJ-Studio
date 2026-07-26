-- ============================================================================
-- 04 · Logica critica de pedidos
-- ============================================================================
-- Regla de oro: el cliente NUNCA hace UPDATE sobre orders.status ni sobre
-- products.stock. Todo pasa por estas funciones SECURITY DEFINER, que validan
-- quien es el actor y que la transicion sea legal.
--
-- Decision sobre el stock: se descuenta AL ACEPTAR, no al solicitar.
--   - Al solicitar no se reserva nada -> varios compradores pueden pedir el
--     mismo producto y el vendedor decide a quien le vende.
--   - Al aceptar se descuenta de forma atomica -> imposible sobrevender.
--   - Si luego se cancela antes de entregar, se restituye.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Helper interno: registra el evento de auditoria y notifica al destinatario.
-- ----------------------------------------------------------------------------
create or replace function public.registrar_evento_pedido(
  p_order_id    uuid,
  p_actor_id    uuid,
  p_from        public.estado_pedido,
  p_to          public.estado_pedido,
  p_destinatario uuid,
  p_tipo        public.tipo_notificacion,
  p_titulo      text,
  p_cuerpo      text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.order_events (order_id, actor_id, from_status, to_status)
  values (p_order_id, p_actor_id, p_from, p_to);

  insert into public.notifications (user_id, type, title, body, order_id)
  values (p_destinatario, p_tipo, p_titulo, p_cuerpo, p_order_id);
end;
$$;

-- ----------------------------------------------------------------------------
-- crear_pedido · lo dispara BotonContinuarPedido ("Contactar con el vendedor")
-- Entrada: [{"product_id": "...", "quantity": 2}, ...]
--
-- Los precios NO se aceptan del cliente: se leen de la base. Si el frontend
-- manda "precio 1 Bs", se ignora. El total lo calcula el servidor.
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

  -- Snapshots por linea: nombre, emoji y precio quedan congelados.
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

    insert into public.order_items (
      order_id, product_id, product_name, product_emoji, unit_price, quantity
    )
    values (
      v_order_id, v_producto.id, v_producto.name, v_producto.emoji,
      v_producto.price, v_cantidad
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

-- ----------------------------------------------------------------------------
-- aceptar_pedido · SOLO el vendedor. Descuenta stock atomicamente.
-- Tras esto el frontend puede revelar el WhatsApp (get_contacto_pedido).
-- ----------------------------------------------------------------------------
create or replace function public.aceptar_pedido(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor  uuid := auth.uid();
  v_pedido public.orders%rowtype;
  v_item   record;
  v_filas  integer;
begin
  -- FOR UPDATE serializa contra un cancelar/vencer simultaneo:
  -- solo una transaccion puede cambiar este pedido a la vez.
  select * into v_pedido
    from public.orders
   where id = p_order_id
   for update;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_pedido.seller_id <> v_actor then
    raise exception 'SOLO_EL_VENDEDOR_PUEDE_ACEPTAR' using errcode = '42501';
  end if;
  if v_pedido.status <> 'solicitado' then
    raise exception 'ESTADO_INVALIDO: el pedido ya esta %', v_pedido.status
      using errcode = '22023';
  end if;
  if v_pedido.expires_at <= now() then
    raise exception 'PEDIDO_VENCIDO' using errcode = '22023';
  end if;

  -- Descuento atomico: el WHERE stock >= cantidad es la barrera anti-sobreventa.
  -- Si dos vendedores aceptan a la vez, solo uno logra actualizar la fila.
  for v_item in
    select product_id, quantity
      from public.order_items
     where order_id = p_order_id
       and product_id is not null
  loop
    update public.products
       set stock = stock - v_item.quantity
     where id = v_item.product_id
       and kind = 'producto'
       and stock >= v_item.quantity;

    get diagnostics v_filas = row_count;

    -- 0 filas puede significar "sin stock" o "es un servicio" (sin inventario).
    if v_filas = 0 and exists (
      select 1 from public.products
       where id = v_item.product_id and kind = 'producto'
    ) then
      raise exception 'STOCK_INSUFICIENTE_AL_ACEPTAR' using errcode = '22023';
    end if;
  end loop;

  update public.orders
     set status = 'aceptado', accepted_at = now()
   where id = p_order_id
  returning * into v_pedido;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, 'solicitado', 'aceptado', v_pedido.buyer_id,
    'pedido_aceptado', 'Pedido aceptado',
    'El vendedor acepto tu pedido. Ya puedes coordinar por WhatsApp.'
  );

  return v_pedido;
end;
$$;

-- ----------------------------------------------------------------------------
-- Helper interno: devuelve stock cuando un pedido aceptado se cae.
-- ----------------------------------------------------------------------------
create or replace function public.restituir_stock(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.products p
     set stock = p.stock + oi.quantity
    from public.order_items oi
   where oi.order_id = p_order_id
     and oi.product_id = p.id
     and p.kind = 'producto';
end;
$$;

-- ----------------------------------------------------------------------------
-- rechazar_pedido · SOLO el vendedor, solo si sigue 'solicitado'
-- (No hay stock que devolver: aun no se habia descontado.)
-- ----------------------------------------------------------------------------
create or replace function public.rechazar_pedido(
  p_order_id uuid,
  p_motivo   text default null
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor  uuid := auth.uid();
  v_pedido public.orders%rowtype;
begin
  select * into v_pedido from public.orders where id = p_order_id for update;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_pedido.seller_id <> v_actor then
    raise exception 'SOLO_EL_VENDEDOR_PUEDE_RECHAZAR' using errcode = '42501';
  end if;
  if v_pedido.status <> 'solicitado' then
    raise exception 'ESTADO_INVALIDO' using errcode = '22023';
  end if;

  update public.orders
     set status = 'rechazado', resolved_at = now()
   where id = p_order_id
  returning * into v_pedido;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, 'solicitado', 'rechazado', v_pedido.buyer_id,
    'pedido_rechazado', 'Pedido rechazado',
    coalesce(p_motivo, 'El vendedor no pudo atender tu pedido.')
  );

  return v_pedido;
end;
$$;

-- ----------------------------------------------------------------------------
-- cancelar_pedido · SOLO el comprador, mientras no este entregado.
-- Tambien cubre el boton "atras" de PantallaContactandoVendedor.
-- ----------------------------------------------------------------------------
create or replace function public.cancelar_pedido(
  p_order_id uuid,
  p_motivo   text default null
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor  uuid := auth.uid();
  v_pedido public.orders%rowtype;
  v_previo public.estado_pedido;
begin
  select * into v_pedido from public.orders where id = p_order_id for update;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_pedido.buyer_id <> v_actor then
    raise exception 'SOLO_EL_COMPRADOR_PUEDE_CANCELAR' using errcode = '42501';
  end if;
  if v_pedido.status not in ('solicitado', 'aceptado') then
    raise exception 'ESTADO_INVALIDO: no se puede cancelar un pedido %',
      v_pedido.status using errcode = '22023';
  end if;

  v_previo := v_pedido.status;

  -- Solo se devuelve stock si ya se habia descontado (es decir, si estaba aceptado).
  if v_previo = 'aceptado' then
    perform public.restituir_stock(p_order_id);
  end if;

  update public.orders
     set status = 'cancelado', resolved_at = now()
   where id = p_order_id
  returning * into v_pedido;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, v_previo, 'cancelado', v_pedido.seller_id,
    'pedido_cancelado', 'Pedido cancelado',
    coalesce(p_motivo, 'El comprador cancelo el pedido.')
  );

  return v_pedido;
end;
$$;

-- ----------------------------------------------------------------------------
-- marcar_entregado · cualquiera de las dos partes cierra el pedido.
-- ----------------------------------------------------------------------------
create or replace function public.marcar_entregado(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor  uuid := auth.uid();
  v_pedido public.orders%rowtype;
  v_otro   uuid;
begin
  select * into v_pedido from public.orders where id = p_order_id for update;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_actor not in (v_pedido.buyer_id, v_pedido.seller_id) then
    raise exception 'NO_PARTICIPAS_EN_ESTE_PEDIDO' using errcode = '42501';
  end if;
  if v_pedido.status <> 'aceptado' then
    raise exception 'ESTADO_INVALIDO: solo un pedido aceptado puede entregarse'
      using errcode = '22023';
  end if;

  update public.orders
     set status = 'entregado', resolved_at = now()
   where id = p_order_id
  returning * into v_pedido;

  v_otro := case when v_actor = v_pedido.buyer_id
                 then v_pedido.seller_id else v_pedido.buyer_id end;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, 'aceptado', 'entregado', v_otro,
    'pedido_entregado', 'Pedido entregado', 'El pedido se marco como entregado.'
  );

  return v_pedido;
end;
$$;

-- ----------------------------------------------------------------------------
-- get_contacto_pedido · REVELACION CONTROLADA DEL WHATSAPP
-- El numero NO es legible por RLS en profiles. Solo sale por aqui, y solo si:
--   1) quien pregunta es comprador o vendedor DE ESE pedido, y
--   2) el pedido esta 'aceptado' o 'entregado'.
-- Un pedido 'solicitado' o 'rechazado' no revela nada.
-- ----------------------------------------------------------------------------
create or replace function public.get_contacto_pedido(p_order_id uuid)
returns table (
  contraparte_id       uuid,
  contraparte_nombre   text,
  contraparte_whatsapp text,
  enlace_whatsapp      text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor  uuid := auth.uid();
  v_pedido public.orders%rowtype;
  v_otro   uuid;
begin
  select * into v_pedido from public.orders where id = p_order_id;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_actor not in (v_pedido.buyer_id, v_pedido.seller_id) then
    raise exception 'NO_PARTICIPAS_EN_ESTE_PEDIDO' using errcode = '42501';
  end if;
  if v_pedido.status not in ('aceptado', 'entregado') then
    raise exception 'CONTACTO_NO_DISPONIBLE: el pedido aun no fue aceptado'
      using errcode = '42501';
  end if;

  v_otro := case when v_actor = v_pedido.buyer_id
                 then v_pedido.seller_id else v_pedido.buyer_id end;

  return query
    select p.id,
           p.full_name,
           p.whatsapp,
           'https://wa.me/' || p.whatsapp as enlace_whatsapp
      from public.profiles p
     where p.id = v_otro;
end;
$$;

-- ----------------------------------------------------------------------------
-- vencer_pedidos_pendientes · lo llama pg_cron (ver migracion 06)
-- Un pedido 'solicitado' sin respuesta no bloquea stock, pero si deja al
-- comprador esperando en PantallaContactandoVendedor para siempre.
-- ----------------------------------------------------------------------------
create or replace function public.vencer_pedidos_pendientes()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pedido public.orders%rowtype;
  v_total  integer := 0;
begin
  for v_pedido in
    select * from public.orders
     where status = 'solicitado'
       and expires_at <= now()
     for update skip locked          -- no pelea con un aceptar en curso
  loop
    update public.orders
       set status = 'vencido', resolved_at = now()
     where id = v_pedido.id;

    perform public.registrar_evento_pedido(
      v_pedido.id, null, 'solicitado', 'vencido', v_pedido.buyer_id,
      'pedido_vencido', 'Pedido vencido',
      'El vendedor no respondio a tiempo.'
    );

    v_total := v_total + 1;
  end loop;

  return v_total;
end;
$$;

-- ----------------------------------------------------------------------------
-- Permisos: solo usuarios autenticados pueden invocar la logica de negocio.
-- ----------------------------------------------------------------------------
revoke all on function public.crear_pedido(jsonb, uuid, text, text, integer) from public;
revoke all on function public.aceptar_pedido(uuid)          from public;
revoke all on function public.rechazar_pedido(uuid, text)   from public;
revoke all on function public.cancelar_pedido(uuid, text)   from public;
revoke all on function public.marcar_entregado(uuid)        from public;
revoke all on function public.get_contacto_pedido(uuid)     from public;

grant execute on function public.crear_pedido(jsonb, uuid, text, text, integer) to authenticated;
grant execute on function public.aceptar_pedido(uuid)        to authenticated;
grant execute on function public.rechazar_pedido(uuid, text) to authenticated;
grant execute on function public.cancelar_pedido(uuid, text) to authenticated;
grant execute on function public.marcar_entregado(uuid)      to authenticated;
grant execute on function public.get_contacto_pedido(uuid)   to authenticated;

-- Helpers internos y barrido: nadie los llama desde el cliente.
revoke all on function public.registrar_evento_pedido(uuid, uuid, public.estado_pedido, public.estado_pedido, uuid, public.tipo_notificacion, text, text) from public;
revoke all on function public.restituir_stock(uuid)          from public;
revoke all on function public.vencer_pedidos_pendientes()    from public;
