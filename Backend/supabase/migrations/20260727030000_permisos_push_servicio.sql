-- ============================================================================
-- 16 · Permisos de service_role sobre las suscripciones push
-- ============================================================================
-- La Edge Function `enviar-push` corre como service_role. Ese rol ignora las
-- RLS, pero NO los permisos de tabla: como el proyecto tiene desactivada la
-- exposicion automatica, la tabla nueva nacio sin GRANTs y la funcion fallaba
-- con "permission denied for table push_subscriptions".
--
-- DELETE hace falta para depurar suscripciones vencidas (404/410): sin eso,
-- un dispositivo desinstalado se reintentaria en cada notificacion.
-- ============================================================================

grant select, delete on public.push_subscriptions to service_role;
