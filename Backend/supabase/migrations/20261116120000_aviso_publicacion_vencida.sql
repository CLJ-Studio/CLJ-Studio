-- ============================================================================
-- Aviso de publicacion vencida
-- ============================================================================
-- Va solo en su archivo: Postgres no deja usar un valor de enum en la misma
-- transaccion que lo crea, y la migracion siguiente ya lo usa.
-- ============================================================================

alter type public.tipo_notificacion add value if not exists 'publicacion_vencida';
