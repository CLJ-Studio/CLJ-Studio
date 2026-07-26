-- ============================================================================
-- 10 · Normaliza la capitalizacion del nombre institucional
-- ============================================================================
-- Google devuelve el nombre de las cuentas UPSA en MAYUSCULAS
-- ("JUAN DIEGO SALAZAR MENDEZ"). Al pasar a ser de solo lectura, ese texto
-- se muestra tal cual en el perfil, el saludo y las tarjetas de producto,
-- y grita en toda la interfaz.
--
-- Se convierte a capitalizacion de titulo solo cuando el nombre viene
-- integramente en mayusculas: si el proveedor ya lo entrega bien escrito
-- ("Ana de la Cruz"), no se toca para no romper particulas ni apellidos.
-- ============================================================================

create or replace function public.normalizar_nombre(p_nombre text)
returns text
language sql
immutable
as $$
  select case
    when p_nombre is null then null
    -- Solo si NO contiene ninguna minuscula (es decir, esta todo en mayusculas).
    when p_nombre !~ '[a-záéíóúñü]' then initcap(lower(trim(p_nombre)))
    else trim(p_nombre)
  end;
$$;

-- ----------------------------------------------------------------------------
-- Alta de usuario: normaliza lo que llega de Google.
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
    public.normalizar_nombre(
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        nullif(trim(new.raw_user_meta_data->>'name'), ''),
        v_local
      )
    ),
    '🎓'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- Onboarding: normaliza tambien el nombre escrito a mano (caso sin Google).
-- ----------------------------------------------------------------------------
create or replace function public.completar_onboarding(
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
  v_whatsapp       text;
  v_nombre_actual  text;
  v_nombre_final   text;
  v_perfil         public.profiles;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  select full_name into v_nombre_actual
    from public.profiles where id = auth.uid();

  -- Se conserva el nombre institucional salvo que sea el codigo de estudiante
  -- (el valor de reserva cuando Google no entrega nombre).
  if v_nombre_actual is not null
     and length(trim(v_nombre_actual)) >= 3
     and v_nombre_actual !~ '^a\d{10}$'
  then
    v_nombre_final := v_nombre_actual;
  else
    v_nombre_final := public.normalizar_nombre(coalesce(p_full_name, ''));
    if length(coalesce(v_nombre_final, '')) < 3 then
      raise exception 'NOMBRE_INVALIDO: minimo 3 caracteres' using errcode = '22023';
    end if;
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
     set full_name            = v_nombre_final,
         career_id            = p_career_id,
         whatsapp             = v_whatsapp,
         onboarding_completed = true
   where id = auth.uid()
  returning * into v_perfil;

  -- Sin fila actualizada el usuario fue borrado con el JWT aun vigente.
  if v_perfil.id is null then
    raise exception 'PERFIL_INEXISTENTE: vuelve a iniciar sesion'
      using errcode = '42501';
  end if;

  return v_perfil;
end;
$$;

-- Corrige los perfiles ya creados en MAYUSCULAS.
update public.profiles
   set full_name = public.normalizar_nombre(full_name)
 where full_name !~ '[a-záéíóúñü]';
