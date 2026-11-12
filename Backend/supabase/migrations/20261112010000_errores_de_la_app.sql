-- ============================================================================
-- Los errores de la app, anotados en la base
--
-- Hasta ahora un fallo en el telefono de alguien solo se sabia si esa persona
-- mandaba una captura por WhatsApp. Ahora la app manda aqui los errores que
-- nadie atrapo (los que Flutter pinta en rojo o los que se escapan de una
-- tarea), con la version y la plataforma. Se leen en el Table Editor de
-- Supabase: tabla `errores_app`, ordenada por `ultima_vez`.
--
--   · El mismo error dentro de la misma hora no es otra fila: suma `veces`.
--   · Lo manda tambien quien no inicio sesion (los fallos del acceso son de
--     los que mas importan), con un tope de 300 errores nuevos por hora para
--     que nadie la llene de basura.
--   · Solo los administradores pueden leerla desde la app. Se borra sola a
--     los 60 dias.
-- ============================================================================

create table public.errores_app (
  id          bigint generated always as identity primary key,
  -- El mensaje y el comienzo de la pila: lo que dice que es "el mismo" error.
  firma       text not null,
  mensaje     text not null,
  pila        text,
  contexto    text,
  version     text,
  plataforma  text,
  usuario_id  uuid references public.profiles(id) on delete set null,
  veces       integer not null default 1,
  primera_vez timestamptz not null default now(),
  ultima_vez  timestamptz not null default now()
);

create index errores_app_por_firma on public.errores_app (firma, ultima_vez desc);
create index errores_app_recientes on public.errores_app (primera_vez desc);

alter table public.errores_app enable row level security;

create policy errores_app_administradores on public.errores_app
  for select to authenticated using (public.soy_administrador());

-- Nadie escribe directo: solo registrar_error.
revoke all on public.errores_app from anon, authenticated;
grant select on public.errores_app to authenticated;

create or replace function public.registrar_error(
  p_mensaje    text,
  p_pila       text default null,
  p_contexto   text default null,
  p_version    text default null,
  p_plataforma text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mensaje text := left(coalesce(nullif(btrim(p_mensaje), ''), '(sin mensaje)'), 500);
  v_pila    text := left(p_pila, 4000);
  v_firma   text;
begin
  v_firma := md5(
    v_mensaje || E'\n' ||
    coalesce(array_to_string((string_to_array(v_pila, E'\n'))[1:3], E'\n'), '')
  );

  -- El mismo error en la ultima hora: una vez mas, no otra fila.
  update public.errores_app
     set veces = veces + 1,
         ultima_vez = now(),
         version = coalesce(left(p_version, 60), version)
   where id = (
     select id from public.errores_app
      where firma = v_firma and ultima_vez > now() - interval '1 hour'
      order by ultima_vez desc
      limit 1
   );
  if found then
    return;
  end if;

  -- Tope: la app manda pocos; si llegan cientos, alguien la esta llenando.
  if (select count(*) from public.errores_app
       where primera_vez > now() - interval '1 hour') >= 300 then
    return;
  end if;

  insert into public.errores_app
    (firma, mensaje, pila, contexto, version, plataforma, usuario_id)
  values
    (v_firma, v_mensaje, v_pila, left(p_contexto, 300), left(p_version, 60),
     left(p_plataforma, 30), auth.uid());
end;
$$;

revoke all on function public.registrar_error(text, text, text, text, text) from public;
grant execute on function public.registrar_error(text, text, text, text, text)
  to anon, authenticated;

-- Se borran solos a los 60 dias.
select cron.unschedule('limpiar-errores-app')
 where exists (select 1 from cron.job where jobname = 'limpiar-errores-app');

select cron.schedule(
  'limpiar-errores-app',
  '30 4 * * *',
  $$delete from public.errores_app where ultima_vez < now() - interval '60 days';$$
);

notify pgrst, 'reload schema';
