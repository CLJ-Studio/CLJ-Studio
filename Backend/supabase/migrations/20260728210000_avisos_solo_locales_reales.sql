-- ============================================================================
-- 33 · El recordatorio de ubicacion solo para locales de verdad
-- ============================================================================
-- Dos correcciones sobre lo que ya se envio.
--
-- 1. `recordar_ubicacion_locales()` filtraba por is_active e is_open pero se
--    olvidaba de excluir los espacios personales. Un espacio personal se crea
--    solo al publicar algo suelto y nace con is_open en true, asi que la
--    gente recibia "Tienes Ventas de Juan abierto, confirma donde estas"
--    hablando de un local que nunca abrio ni existe como tal.
--
-- 2. Las notificaciones de "Nuevo local" anteriores a la migracion 32 nacieron
--    sin store_id, asi que tocarlas no lleva a ninguna parte. Se rellena a
--    partir del nombre que quedo escrito en el propio aviso.
-- ============================================================================

create or replace function public.recordar_ubicacion_locales()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_avisados integer := 0;
begin
  with pendientes as (
    select s.id, s.owner_id, s.name
      from public.stores s
     where s.is_active
       and s.is_open
       -- El espacio personal no es un local abierto: es el contenedor
       -- invisible de las publicaciones sueltas. Nadie va a buscarte ahi.
       and not s.is_personal
       and (
         s.location_updated_at is null
         or s.location_updated_at < now() - interval '6 hours'
       )
       and not exists (
         select 1 from public.notifications n
          where n.store_id = s.id
            and n.type = 'ubicacion_pendiente'
            and n.created_at > now() - interval '6 hours'
       )
  )
  insert into public.notifications (user_id, type, title, body, store_id)
  select
    p.owner_id,
    'ubicacion_pendiente',
    'Actualiza tu ubicación',
    'Tienes ' || p.name || ' abierto. Confirma dónde estás para que te '
      || 'encuentren.',
    p.id
  from pendientes p;

  get diagnostics v_avisados = row_count;
  return v_avisados;
end;
$$;

revoke all on function public.recordar_ubicacion_locales() from public;

-- ----------------------------------------------------------------------------
-- Limpieza de los avisos que nunca debieron salir.
-- ----------------------------------------------------------------------------
-- Se borran y no se marcan como leidos porque no informan de nada: piden
-- confirmar la ubicacion de algo que no aparece en ningun mapa.
delete from public.notifications n
 using public.stores s
 where n.type = 'ubicacion_pendiente'
   and n.store_id = s.id
   and s.is_personal;

-- ----------------------------------------------------------------------------
-- Rellenar el destino de los "Nuevo local" antiguos.
-- ----------------------------------------------------------------------------
-- El cuerpo se construyo como '<emoji> <nombre> acaba de abrir...', asi que
-- el nombre sigue ahi y sirve para reencontrar el local. Si se cerro desde
-- entonces, no habra coincidencia y el aviso se queda sin destino, que es lo
-- correcto: ya no hay nada que abrir.
update public.notifications n
   set store_id = s.id
  from public.stores s
 where n.type = 'nuevo_local'
   and n.store_id is null
   and s.is_active
   and n.body like '%' || s.name || ' acaba de abrir%';
