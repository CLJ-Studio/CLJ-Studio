-- ============================================================================
-- 39 · La entrega la cierran las dos partes
-- ============================================================================
-- `marcar_entregado` la podia llamar cualquiera de los dos y cerraba el
-- pedido de golpe. O sea que una sola persona decidia por las dos: el
-- vendedor podia dar por entregado algo que nunca entrego, y al comprador
-- solo le llegaba el aviso de que ya estaba hecho, sin poder decir que no.
--
-- Ahora quien entrega lo marca, y el pedido queda 'por_confirmar' hasta que
-- la otra parte lo confirme. Con dos cautelas para que no moleste:
--
--   · Un solo aviso, en el momento. Nada periodico: el recordatorio vive en
--     la pantalla de Pedidos, no persiguiendo a nadie.
--   · A las 24 horas se cierra solo y EN SILENCIO. Sin esto la mitad de los
--     pedidos quedarian colgados para siempre, porque cuando dos personas ya
--     se encontraron en el campus nadie vuelve a abrir la aplicacion.
--
-- Se guarda quien marco y quien confirmo, que es lo que hoy no existia y lo
-- que hara que una valoracion futura signifique algo.
--
-- Requiere haber ejecutado antes 20260729150000.
-- ============================================================================

alter table public.orders
  add column if not exists delivered_marked_by uuid references public.profiles(id),
  add column if not exists delivered_marked_at timestamptz,
  add column if not exists confirmed_by uuid references public.profiles(id);

-- ----------------------------------------------------------------------------
-- marcar_entregado · ya no cierra, abre la confirmacion
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
     set status = 'por_confirmar',
         delivered_marked_by = v_actor,
         delivered_marked_at = now()
   where id = p_order_id
  returning * into v_pedido;

  v_otro := case when v_actor = v_pedido.buyer_id
                 then v_pedido.seller_id else v_pedido.buyer_id end;

  -- Lo puede marcar cualquiera de los dos, asi que el aviso cambia segun
  -- quien hablo primero. Un texto fijo le preguntaria al vendedor si recibio
  -- su pedido.
  perform public.registrar_evento_pedido(
    p_order_id, v_actor, 'aceptado', 'por_confirmar', v_otro,
    'entrega_por_confirmar',
    case when v_actor = v_pedido.seller_id
         then '¿Recibiste tu pedido?'
         else '¿Entregaste el pedido?' end,
    case when v_actor = v_pedido.seller_id
         then 'Quien vende marco el pedido como entregado. Confirmalo para cerrarlo.'
         else 'Quien compra marco el pedido como recibido. Confirmalo para cerrarlo.'
    end
  );

  return v_pedido;
end;
$$;

-- ----------------------------------------------------------------------------
-- confirmar_entrega · la cierra la OTRA parte
-- ----------------------------------------------------------------------------
create or replace function public.confirmar_entrega(p_order_id uuid)
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
  if v_actor not in (v_pedido.buyer_id, v_pedido.seller_id) then
    raise exception 'NO_PARTICIPAS_EN_ESTE_PEDIDO' using errcode = '42501';
  end if;
  if v_pedido.status <> 'por_confirmar' then
    raise exception 'ESTADO_INVALIDO: este pedido no espera confirmacion'
      using errcode = '22023';
  end if;
  -- Confirmar lo propio no confirma nada: la gracia es que lo diga el otro.
  if v_actor = v_pedido.delivered_marked_by then
    raise exception 'YA_LO_MARCASTE: espera a que lo confirme la otra parte'
      using errcode = '42501';
  end if;

  update public.orders
     set status = 'entregado',
         confirmed_by = v_actor,
         resolved_at = now()
   where id = p_order_id
  returning * into v_pedido;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, 'por_confirmar', 'entregado',
    v_pedido.delivered_marked_by,
    'pedido_entregado', 'Entrega confirmada',
    'La otra parte confirmo que todo salio bien.'
  );

  return v_pedido;
end;
$$;

revoke all on function public.confirmar_entrega(uuid) from public;
grant execute on function public.confirmar_entrega(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- Cierre automatico a las 24 horas, sin avisar a nadie
-- ----------------------------------------------------------------------------
-- `confirmed_by` se queda en null: asi consta que lo cerro el sistema y no
-- una persona, que es la diferencia entre "los dos dijeron que si" y "uno lo
-- dijo y el otro no contesto".
create or replace function public.cerrar_entregas_sin_confirmar()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cerrados integer := 0;
begin
  update public.orders
     set status = 'entregado', resolved_at = now()
   where status = 'por_confirmar'
     and delivered_marked_at < now() - interval '24 hours';

  get diagnostics v_cerrados = row_count;
  return v_cerrados;
end;
$$;

revoke all on function public.cerrar_entregas_sin_confirmar() from public;

select cron.unschedule('cerrar-entregas-sin-confirmar')
 where exists (
   select 1 from cron.job where jobname = 'cerrar-entregas-sin-confirmar'
 );

-- Cada hora basta: el plazo es de 24, no hace falta afinar al minuto.
select cron.schedule(
  'cerrar-entregas-sin-confirmar',
  '15 * * * *',
  $$select public.cerrar_entregas_sin_confirmar();$$
);

-- ----------------------------------------------------------------------------
-- El contacto sigue disponible mientras se confirma
-- ----------------------------------------------------------------------------
-- `get_contacto_pedido` solo abria el WhatsApp en 'aceptado' y 'entregado'.
-- Con el estado nuevo en medio, el numero se ocultaria justo cuando mas hace
-- falta: entre que uno marca la entrega y el otro la confirma es cuando se
-- estan escribiendo para cuadrar el encuentro.
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
  if v_pedido.status not in ('aceptado', 'por_confirmar', 'entregado') then
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

revoke all on function public.get_contacto_pedido(uuid) from public;
grant execute on function public.get_contacto_pedido(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- La vista dice quien marco, para saber de quien es el turno
-- ----------------------------------------------------------------------------
-- Sin esto la pantalla ve el estado 'por_confirmar' pero no sabe si el boton
-- de confirmar le toca a quien esta mirando o a la otra persona, y acabaria
-- ofreciendoselo a los dos.
--
-- Las columnas nuevas van al final: `create or replace view` no deja meterlas
-- en medio ni cambiar las que ya estaban.
create or replace view public.pedidos_detallados
with (security_invoker = off) as
  select
    o.id,
    o.status,
    o.buyer_id,
    o.seller_id,
    o.store_id,
    o.subtotal,
    o.delivery_cost,
    o.total,
    o.buyer_note,
    o.meeting_point_note,
    o.expires_at,
    o.accepted_at,
    o.resolved_at,
    o.created_at,
    s.name  as store_name,
    s.emoji as store_emoji,
    comprador.full_name as buyer_name,
    vendedor.full_name  as seller_name,
    punto.name as meeting_point_name,
    -- Los items viajan embebidos: evita una segunda consulta por pedido.
    coalesce(
      (
        select json_agg(
                 json_build_object(
                   'id',            oi.id,
                   'product_name',  oi.product_name,
                   'product_emoji', oi.product_emoji,
                   'unit_price',    oi.unit_price,
                   'quantity',      oi.quantity,
                   'line_total',    oi.line_total
                 )
                 order by oi.product_name
               )
          from public.order_items oi
         where oi.order_id = o.id
      ),
      '[]'::json
    ) as items,
    o.delivered_marked_by,
    o.delivered_marked_at,
    o.confirmed_by
  from public.orders o
  join public.stores   s         on s.id = o.store_id
  join public.profiles comprador on comprador.id = o.buyer_id
  join public.profiles vendedor  on vendedor.id  = o.seller_id
  left join public.campus_locations punto on punto.id = o.meeting_point_id
  -- Filtro de seguridad: sin esto la vista expondria los pedidos de todos.
  where o.buyer_id = auth.uid() or o.seller_id = auth.uid();

grant select on public.pedidos_detallados to authenticated;
