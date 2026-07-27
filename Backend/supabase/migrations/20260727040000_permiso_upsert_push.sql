-- ============================================================================
-- 17 · Permiso de UPDATE para el upsert de suscripciones push
-- ============================================================================
-- El cliente registra el dispositivo con un upsert sobre `endpoint`, para que
-- reabrir la app no duplique la fila. Un upsert necesita INSERT **y UPDATE**:
-- con solo INSERT, PostgREST responde 403 Forbidden y el interruptor de
-- notificaciones fallaba con "No se pudieron activar en este dispositivo".
--
-- Se acota a las columnas que el registro rescribe. `endpoint` queda fuera:
-- es la identidad de la fila y quien resuelve el conflicto.
-- La RLS ya limita la operacion a las filas propias.
-- ============================================================================

grant update (user_id, p256dh, auth) on public.push_subscriptions
  to authenticated;
