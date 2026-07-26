-- ============================================================================
-- 03 · Validacion de dominio institucional + alta de perfil
-- ============================================================================
-- REQUISITO DE SEGURIDAD: hoy el dominio esta QUEMADO EN EL CLIENTE
--   ControladorAccesoUpsa.dominio = '@estudiantes.upsa.edu.bo'
--   ServicioAutenticacionGoogle.simularAcceso() -> correo.endsWith(...)
-- Eso es solo cosmetico: la anon key de Supabase es publica, asi que cualquiera
-- puede registrarse llamando la API directamente saltandose Flutter.
-- La validacion REAL vive aqui, en un trigger BEFORE INSERT sobre auth.users:
-- si el dominio no esta autorizado, el usuario NUNCA llega a existir.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Bloquea el alta si el dominio no esta en la lista configurable.
-- ----------------------------------------------------------------------------
create or replace function public.validar_dominio_institucional()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dominio text;
begin
  -- Toma todo lo que viene despues de '@' y normaliza a minusculas.
  v_dominio := lower(split_part(coalesce(new.email, ''), '@', 2));

  if v_dominio = '' then
    raise exception 'CORREO_INVALIDO: la cuenta no tiene correo asociado'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
      from public.institutional_domains
     where domain = v_dominio
       and is_active
  ) then
    raise exception 'DOMINIO_NO_INSTITUCIONAL: % no esta autorizado', v_dominio
      using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger validar_dominio_antes_de_crear_usuario
  before insert on auth.users
  for each row execute function public.validar_dominio_institucional();

-- ----------------------------------------------------------------------------
-- Crea el profile automaticamente tras un alta valida.
-- El onboarding (carrera + WhatsApp) queda pendiente: onboarding_completed=false.
-- ----------------------------------------------------------------------------
create or replace function public.crear_perfil_de_usuario_nuevo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_local  text;
  v_codigo text;
begin
  v_local := split_part(new.email, '@', 1);

  -- El frontend arma el correo como 'a' + 10 digitos (ControladorAccesoUpsa).
  -- Si el patron calza lo guardamos como codigo de estudiante; si no, null.
  v_codigo := case when v_local ~ '^a\d{10}$' then v_local else null end;

  insert into public.profiles (id, email, student_code, full_name, avatar_emoji)
  values (
    new.id,
    new.email,
    v_codigo,
    -- Google entrega el nombre en raw_user_meta_data.
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
      nullif(trim(new.raw_user_meta_data->>'name'), ''),
      v_local
    ),
    '🎓'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger crear_perfil_despues_de_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_de_usuario_nuevo();

-- ----------------------------------------------------------------------------
-- Completar onboarding · nombre + carrera + WhatsApp
-- Se hace por funcion (y no por UPDATE directo) para normalizar el telefono
-- y para que el cliente no pueda marcar onboarding_completed sin los datos.
-- ----------------------------------------------------------------------------
create or replace function public.completar_onboarding(
  p_full_name text,
  p_career    text,
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

  if length(trim(coalesce(p_career, ''))) < 3 then
    raise exception 'CARRERA_INVALIDA' using errcode = '22023';
  end if;

  -- Deja solo digitos: acepta '+591 700-12345', '70012345', etc.
  v_whatsapp := regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g');
  if length(v_whatsapp) < 8 then
    raise exception 'WHATSAPP_INVALIDO: revisa el numero' using errcode = '22023';
  end if;

  update public.profiles
     set full_name            = trim(p_full_name),
         career               = trim(p_career),
         whatsapp             = v_whatsapp,
         onboarding_completed = true
   where id = auth.uid()
  returning * into v_perfil;

  return v_perfil;
end;
$$;

revoke all on function public.completar_onboarding(text, text, text) from public;
grant execute on function public.completar_onboarding(text, text, text) to authenticated;
