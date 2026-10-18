-- ============================================================================
-- 57a · Tipos de aviso para los egresados
-- ============================================================================
-- Separado de la 57b, que los usa: Postgres no permite USAR un valor de enum
-- en la misma transaccion que lo agrega. Hay que correr esta primero.
--
--   egresado_por_verificar: a los admins, cuando alguien pide la marca.
--   egresado_resuelto:      al estudiante, cuando un admin aprueba o rechaza.
-- ============================================================================

alter type public.tipo_notificacion add value if not exists 'egresado_por_verificar';
alter type public.tipo_notificacion add value if not exists 'egresado_resuelto';
