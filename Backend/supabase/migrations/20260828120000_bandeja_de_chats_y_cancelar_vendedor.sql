-- ============================================================================
-- 46 · Bandeja de chats, y que el vendedor tambien pueda cancelar
-- ============================================================================
-- Dos cosas que salieron de probarlo con gente de verdad.
--
-- 1 · NO HABIA COMO LLEGAR AL CHAT.
--     Existia el boton dentro del pedido, pero para llegar hay que acordarse
--     de que la conversacion vive ahi dentro. En la practica todos entraban
--     desde la notificacion, y quien la descartaba se quedaba sin puerta.
--     `listar_chats()` da lo necesario para una bandeja de verdad.
--
-- 2 · EL VENDEDOR NO PODIA CANCELAR.
--     `cancelar_pedido` exigia ser el comprador. Pero al vendedor se le puede
--     acabar el producto, o quemar, o no llegar a tiempo, y su unica salida
--     era dejar el pedido colgado hasta que venciera. Ahora cancelan los dos,
--     y el aviso dice quien fue.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · La bandeja
-- ----------------------------------------------------------------------------
-- Una fila por pedido vivo, tenga mensajes o no: la conversacion existe desde
-- que el pedido se acepta, no desde que alguien escribe. Si solo saliera lo
-- que ya tiene mensajes, el primero en escribir tendria que volver al pedido
-- para encontrar la puerta, que es justo el problema que esto resuelve.
--
-- Corre como owner porque la RLS de `profiles` solo deja leer la fila propia:
-- un join normal devolveria vacio el nombre del otro. Expone nombre y foto y
-- nada mas; el WhatsApp sigue saliendo solo por get_contacto_pedido().
create or replace function public.listar_chats()
returns table (
  order_id          uuid,
  contraparte_id    uuid,
  contraparte       text,
  contraparte_foto  text,
  local             text,
  emoji             text,
  estado            text,
  ultimo_mensaje    text,
  ultimo_en         timestamptz,
  ultimo_mio        boolean,
  sin_leer          bigint,
  actualizado_en    timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'SESION_REQUERIDA' using errcode = '42501';
  end if;

  return query
    select
      o.id,
      contraparte.id,
      contraparte.full_name,
      contraparte.avatar_path,
      s.name,
      s.emoji,
      o.status::text,
      ultimo.cuerpo,
      ultimo.creado_en,
      ultimo.autor_id = v_actor,
      coalesce(pendientes.cuantos, 0),
      -- Ordena por lo ultimo que paso: si nadie escribio todavia, manda la
      -- hora en que se acepto, para que un pedido recien aceptado no caiga al
      -- fondo por no tener mensajes.
      coalesce(ultimo.creado_en, o.accepted_at, o.created_at)
      from public.orders o
      join public.stores   s on s.id = o.store_id
      join public.profiles contraparte
        on contraparte.id = case when o.buyer_id = v_actor
                                 then o.seller_id else o.buyer_id end
      left join lateral (
        select m.cuerpo, m.creado_en, m.autor_id
          from public.mensajes_pedido m
         where m.order_id = o.id
         order by m.creado_en desc
         limit 1
      ) ultimo on true
      left join lateral (
        select count(*) as cuantos
          from public.mensajes_pedido m
         where m.order_id = o.id
           and m.autor_id <> v_actor
           and m.leido_en is null
      ) pendientes on true
     where (o.buyer_id = v_actor or o.seller_id = v_actor)
       -- Los mismos dos estados que abren el chat. Sin esta condicion la
       -- bandeja mostraria conversaciones que al abrirlas dicen "cerrada".
       and o.status in ('aceptado', 'por_confirmar')
     order by coalesce(ultimo.creado_en, o.accepted_at, o.created_at) desc;
end;
$$;

revoke all on function public.listar_chats() from public;
grant execute on function public.listar_chats() to authenticated;

-- ----------------------------------------------------------------------------
-- 2 · Cancelar tambien del lado del vendedor
-- ----------------------------------------------------------------------------
-- Se conserva todo lo demas igual: los estados en los que se puede, la
-- devolucion de stock y el registro del evento. Lo unico que cambia es quien
-- puede llamarla y a quien se avisa.
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
  v_actor       uuid := auth.uid();
  v_pedido      public.orders%rowtype;
  v_previo      public.estado_pedido;
  v_otro        uuid;
  v_soy_vendedor boolean;
begin
  select * into v_pedido from public.orders where id = p_order_id for update;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_actor not in (v_pedido.buyer_id, v_pedido.seller_id) then
    raise exception 'NO_PARTICIPAS_EN_ESTE_PEDIDO' using errcode = '42501';
  end if;
  if v_pedido.status not in ('solicitado', 'aceptado') then
    raise exception 'ESTADO_INVALIDO: no se puede cancelar un pedido %',
      v_pedido.status using errcode = '22023';
  end if;

  v_previo       := v_pedido.status;
  v_soy_vendedor := v_actor = v_pedido.seller_id;
  v_otro := case when v_soy_vendedor then v_pedido.buyer_id
                 else v_pedido.seller_id end;

  -- Solo se devuelve stock si ya se habia descontado (es decir, si estaba
  -- aceptado). Vale igual cancele quien cancele.
  if v_previo = 'aceptado' then
    perform public.restituir_stock(p_order_id);
  end if;

  update public.orders
     set status = 'cancelado', resolved_at = now()
   where id = p_order_id
  returning * into v_pedido;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, v_previo, 'cancelado', v_otro,
    'pedido_cancelado', 'Pedido cancelado',
    coalesce(
      p_motivo,
      case when v_soy_vendedor
           then 'El vendedor cancelo el pedido.'
           else 'El comprador cancelo el pedido.' end
    )
  );

  return v_pedido;
end;
$$;

revoke all on function public.cancelar_pedido(uuid, text) from public;
grant execute on function public.cancelar_pedido(uuid, text) to authenticated;
