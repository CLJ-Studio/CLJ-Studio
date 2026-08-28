-- ============================================================================
-- 44 · Tipo de aviso para los mensajes del pedido
-- ============================================================================
-- Va solo en su archivo por lo de siempre: Postgres no deja usar un valor de
-- enum recien anadido dentro de la misma transaccion que lo anade.
--
-- Ejecutar ANTES que 20260806130000.
-- ============================================================================

alter type public.tipo_notificacion
  add value if not exists 'mensaje_pedido';
