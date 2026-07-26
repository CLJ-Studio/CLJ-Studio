-- ============================================================================
-- 11 · Vista de pedidos con todo lo que la pantalla necesita
-- ============================================================================
-- La pantalla de Pedidos debe mostrar el nombre de la contraparte, pero la
-- RLS de `profiles` solo deja ver la fila propia: un join normal devolveria
-- el nombre vacio para el otro participante.
--
-- Esta vista corre como owner (security_invoker = off) para poder leer ambos
-- perfiles, y se filtra a si misma con auth.uid() en el WHERE. Expone unica-
-- mente nombres: el WhatsApp sigue saliendo solo por get_contacto_pedido().
-- ============================================================================

create view public.pedidos_detallados
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
    ) as items
  from public.orders o
  join public.stores   s         on s.id = o.store_id
  join public.profiles comprador on comprador.id = o.buyer_id
  join public.profiles vendedor  on vendedor.id  = o.seller_id
  left join public.campus_locations punto on punto.id = o.meeting_point_id
  -- Filtro de seguridad: sin esto la vista expondria los pedidos de todos.
  where o.buyer_id = auth.uid() or o.seller_id = auth.uid();

grant select on public.pedidos_detallados to authenticated;
