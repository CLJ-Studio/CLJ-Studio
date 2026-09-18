-- ============================================================================
-- 50 · Se quita el recordatorio de ubicacion, y la del comprador deja de
--      perderse
-- ============================================================================
-- Dos cosas distintas que la gente vivia como una sola ("me pide la ubicacion
-- aunque ya la puse, y la otra se me borra"). No tienen nada que ver entre si.
--
-- 1 · EL RECORDATORIO DEL LOCAL
--
-- Guardar funcionaba bien: `actualizar_ubicacion_local` escribe la ubicacion
-- y su marca de tiempo. Lo que molestaba era el recordatorio: un cron cada
-- hora avisaba a todo local ABIERTO cuya ubicacion llevara mas de seis horas
-- sin tocarse.
--
-- La intencion era razonable: quien vende se mueve por el campus, y una
-- ubicacion de ayer manda al comprador al sitio equivocado. El defecto es que
-- no terminaba nunca. Nada cierra un local solo, asi que a quien lo dejaba
-- abierto le llegaba el aviso a las seis horas, a las doce, a las dieciocho,
-- de madrugada incluido, y sin manera de responder "no me muevo de aca". Un
-- recordatorio que no se puede acallar deja de leerse, y de paso ensena a
-- ignorar TODAS las notificaciones de la aplicacion, incluidas las de pedidos,
-- que si importan.
--
-- Se quita entero. Cambiar la ubicacion sigue estando a un toque en Mi Local,
-- que es donde tiene sentido hacerlo: cuando te movés.
--
-- 2 · LA UBICACION DEL COMPRADOR
--
-- Es otra: no es la del local, es la zona que elige quien mira el catalogo.
-- Vivia SOLO en el dispositivo, a proposito. En la PWA eso significa el
-- almacenamiento del navegador, que se va cuando se limpian datos del sitio,
-- en ventana privada, o cuando Safari lo descarta solo tras unos dias sin
-- entrar. De ahi que "se borre sola" en web y no en el telefono.
--
-- Pasa a guardarse tambien en el perfil, como respaldo. El dispositivo sigue
-- mandando (es instantaneo y es donde estas AHORA); el perfil solo responde
-- cuando el dispositivo no tiene nada que decir.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · Fuera el recordatorio
-- ----------------------------------------------------------------------------
do $$
begin
  if exists (
    select 1 from cron.job where jobname = 'recordar-ubicacion-locales'
  ) then
    perform cron.unschedule('recordar-ubicacion-locales');
  end if;
end;
$$;

drop function if exists public.recordar_ubicacion_locales();

-- Los avisos que ya estaban en la bandeja se borran, no se marcan leidos:
-- piden una accion que ya no existe, y dejarlos obliga a cada persona a
-- limpiar a mano una lista de recordatorios repetidos.
delete from public.notifications where type = 'ubicacion_pendiente';

-- El valor del enum se queda. Postgres no deja quitar valores de un enum sin
-- recrearlo, y no hay ninguna razon para pagar ese precio por una etiqueta
-- que ya no usa nadie.

-- ----------------------------------------------------------------------------
-- 2 · La zona del comprador, con respaldo en el perfil
-- ----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists campus_zone text;

-- Tope de longitud y nada mas. La lista de zonas vive en el cliente
-- (`ControladorMiLocal.ubicacionesCampus`) y repetirla aqui como CHECK
-- obligaria a una migracion cada vez que se abre un punto nuevo en el campus,
-- con el riesgo de que una version vieja de la app no pueda guardar.
alter table public.profiles
  drop constraint if exists profiles_campus_zone_corta;
alter table public.profiles
  add constraint profiles_campus_zone_corta
  check (campus_zone is null or length(campus_zone) <= 60);

-- La migracion 12 revoco el UPDATE general sobre `profiles` y lo devolvio
-- columna por columna, para que nadie pudiera inflarse la reputacion ni
-- cambiarse el nombre institucional desde el navegador. Se suma esta columna
-- a esa lista corta: es un dato propio, solo lo ve su dueno (la RLS de
-- `profiles` deja leer la fila propia y nada mas) y no da ventaja ninguna.
grant update (is_on_campus, campus_zone) on public.profiles to authenticated;
