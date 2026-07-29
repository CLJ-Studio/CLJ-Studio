-- ============================================================================
-- 29 · Un tipo de notificacion nuevo: recordar la ubicacion del local
-- ============================================================================
-- Va sola en su archivo a proposito. Postgres no deja usar un valor de enum
-- recien anadido dentro de la misma transaccion que lo anade, y el editor SQL
-- de Supabase envuelve cada ejecucion en una. Si esto viviera junto a la
-- funcion que lo usa, fallaria con "unsafe use of new value of enum type".
--
-- Ejecutar este archivo ANTES que 20260728180000.
-- ============================================================================

alter type public.tipo_notificacion add value if not exists 'ubicacion_pendiente';
