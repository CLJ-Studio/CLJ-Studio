-- ============================================================================
-- 08 · Carreras reales de la UPSA + normalizacion del WhatsApp
-- ============================================================================
-- 1. `career` era texto libre: cada estudiante escribiria su carrera distinto
--    ("Ing. Sistemas", "ingenieria de sistemas"...), rompiendo cualquier
--    filtro o estadistica futura. Pasa a ser FK contra un catalogo cerrado.
--
-- 2. BUG CORREGIDO: completar_onboarding guardaba el telefono tal cual, asi
--    que un numero boliviano de 8 digitos producia https://wa.me/70012345,
--    que WhatsApp NO resuelve: exige codigo de pais. Ahora se antepone 591.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Catalogo de carreras
-- ----------------------------------------------------------------------------
create table public.careers (
  id         text primary key,          -- 'ing-sistemas'
  name       text not null,             -- 'Ingenieria de Sistemas'
  faculty    text not null,             -- 'Ingenieria'
  sort_order integer not null default 0,
  is_active  boolean not null default true
);

alter table public.careers enable row level security;

create policy carreras_lectura on public.careers
  for select to authenticated using (is_active);

grant select on public.careers to authenticated;

insert into public.careers (id, name, faculty, sort_order) values
  -- Arquitectura, Diseno y Urbanismo
  ('arquitectura',        'Arquitectura',                        'Arquitectura, Diseño y Urbanismo', 10),
  ('diseno-industrial',   'Diseño Industrial',                   'Arquitectura, Diseño y Urbanismo', 11),
  -- Ciencias Empresariales
  ('admin-empresas',      'Administración de Empresas',          'Ciencias Empresariales', 20),
  ('auditoria-finanzas',  'Auditoría y Finanzas',                'Ciencias Empresariales', 21),
  ('comercio-intl',       'Comercio Internacional',              'Ciencias Empresariales', 22),
  ('ing-comercial',       'Ingeniería Comercial',                'Ciencias Empresariales', 23),
  ('ing-economica',       'Ingeniería Económica',                'Ciencias Empresariales', 24),
  ('ing-financiera',      'Ingeniería Financiera',               'Ciencias Empresariales', 25),
  ('marketing-publicidad','Marketing y Publicidad',              'Ciencias Empresariales', 26),
  -- Ciencias Juridicas y Sociales
  ('derecho',             'Derecho',                             'Ciencias Jurídicas y Sociales', 30),
  -- Humanidades, Comunicacion y Artes
  ('comunicacion',        'Comunicación Estratégica y Corporativa','Humanidades, Comunicación y Artes', 40),
  ('diseno-grafico',      'Diseño Gráfico',                      'Humanidades, Comunicación y Artes', 41),
  ('moda',                'Diseño y Gestión de la Moda',         'Humanidades, Comunicación y Artes', 42),
  ('psicologia',          'Psicología',                          'Humanidades, Comunicación y Artes', 43),
  -- Ingenieria
  ('ing-civil',           'Ingeniería Civil',                    'Ingeniería', 50),
  ('ing-informatica-adm', 'Ingeniería Informática Administrativa','Ingeniería', 51),
  ('ing-industrial',      'Ingeniería Industrial y de Sistemas', 'Ingeniería', 52),
  ('ing-mecatronica',     'Ingeniería Mecatrónica y Robótica',   'Ingeniería', 53),
  ('ing-sistemas',        'Ingeniería de Sistemas',              'Ingeniería', 54),
  ('ing-energias',        'Ingeniería de Energías Sostenibles',  'Ingeniería', 55);

-- ----------------------------------------------------------------------------
-- profiles.career (texto libre) -> profiles.career_id (FK)
-- ----------------------------------------------------------------------------
-- La vista se elimina primero: depende de la columna `career` y bloquearia
-- el DROP COLUMN. Se recrea mas abajo apuntando al catalogo.
drop view if exists public.perfiles_publicos;

alter table public.profiles drop constraint profiles_onboarding_completo;
alter table public.profiles add column career_id text references public.careers(id);
alter table public.profiles drop column career;

alter table public.profiles add constraint profiles_onboarding_completo
  check (
    not onboarding_completed
    or (length(trim(full_name)) > 0 and career_id is not null and whatsapp is not null)
  );

-- La vista publica expone la carrera legible, no el id interno.
create view public.perfiles_publicos
with (security_invoker = off) as
  select p.id, p.full_name, p.avatar_emoji, c.name as career,
         p.is_on_campus, p.rating_average, p.rating_count
    from public.profiles p
    left join public.careers c on c.id = p.career_id;

grant select on public.perfiles_publicos to authenticated;

-- ----------------------------------------------------------------------------
-- completar_onboarding · ahora valida carrera contra el catalogo y
-- normaliza el telefono a formato internacional.
-- ----------------------------------------------------------------------------
-- Se elimina primero: la firma sigue siendo (text,text,text), y Postgres no
-- permite renombrar un parametro (p_career -> p_career_id) con CREATE OR REPLACE.
drop function if exists public.completar_onboarding(text, text, text);

create function public.completar_onboarding(
  p_full_name text,
  p_career_id text,
  p_whatsapp  text
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_whatsapp text;
  v_perfil   public.profiles;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  if length(trim(coalesce(p_full_name, ''))) < 3 then
    raise exception 'NOMBRE_INVALIDO: minimo 3 caracteres' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.careers where id = p_career_id and is_active
  ) then
    raise exception 'CARRERA_INVALIDA: selecciona una carrera de la lista'
      using errcode = '22023';
  end if;

  -- Deja solo digitos: acepta '+591 700-12345', '70012345', etc.
  v_whatsapp := regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g');

  -- Los celulares bolivianos son 8 digitos. wa.me exige codigo de pais,
  -- asi que se antepone 591 cuando el usuario escribe solo el local.
  if length(v_whatsapp) = 8 then
    v_whatsapp := '591' || v_whatsapp;
  end if;

  if length(v_whatsapp) < 11 or length(v_whatsapp) > 15 then
    raise exception 'WHATSAPP_INVALIDO: revisa el numero' using errcode = '22023';
  end if;

  update public.profiles
     set full_name            = trim(p_full_name),
         career_id            = p_career_id,
         whatsapp             = v_whatsapp,
         onboarding_completed = true
   where id = auth.uid()
  returning * into v_perfil;

  return v_perfil;
end;
$$;

revoke all on function public.completar_onboarding(text, text, text) from public;
grant execute on function public.completar_onboarding(text, text, text) to authenticated;
