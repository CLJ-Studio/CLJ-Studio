-- ============================================================================
-- 38 · Estado intermedio: uno marco la entrega, falta que el otro la confirme
-- ============================================================================
-- Va solo en su archivo por lo de siempre: Postgres no deja usar un valor de
-- enum recien anadido dentro de la misma transaccion que lo anade.
--
-- Ejecutar ANTES que 20260729160000.
-- ============================================================================

alter type public.estado_pedido
  add value if not exists 'por_confirmar' after 'aceptado';

alter type public.tipo_notificacion
  add value if not exists 'entrega_por_confirmar';
