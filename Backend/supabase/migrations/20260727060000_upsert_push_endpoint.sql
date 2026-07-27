-- ============================================================================
-- 19 · UPDATE completo para el upsert de suscripciones push
-- ============================================================================
-- La migracion anterior otorgo UPDATE solo sobre (user_id, p256dh, auth),
-- dejando `endpoint` fuera por considerarla la identidad de la fila. Pero
-- PostgREST construye el DO UPDATE con TODAS las columnas del payload, y el
-- cliente envia `endpoint` tambien: sin permiso sobre ella, seguia el 403.
--
-- Aqui el permiso por columnas no aporta seguridad: la tabla solo contiene
-- datos de la propia suscripcion, sin nada sensible que proteger (a
-- diferencia de `profiles`, donde si se acota para que nadie se infle la
-- reputacion). La RLS ya limita la operacion a las filas propias, y la
-- restriccion unica sobre `endpoint` impide apropiarse del dispositivo ajeno.
-- ============================================================================

grant update on public.push_subscriptions to authenticated;
