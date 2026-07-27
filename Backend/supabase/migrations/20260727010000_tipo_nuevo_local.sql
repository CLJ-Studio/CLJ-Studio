-- ============================================================================
-- 14a · Nuevo tipo de notificacion: apertura de local
-- ============================================================================
-- Separado del trigger que lo usa: Postgres no permite USAR un valor de enum
-- en la misma transaccion que lo agrega, y cada migracion corre en una.
-- ============================================================================

alter type public.tipo_notificacion add value if not exists 'nuevo_local';
