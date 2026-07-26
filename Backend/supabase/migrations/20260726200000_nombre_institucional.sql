-- ============================================================================
-- 09 · El nombre lo define la cuenta institucional, no el formulario
-- ============================================================================
-- El trigger crear_perfil_de_usuario_nuevo ya guarda el nombre que entrega
-- Google (que en las cuentas UPSA es el nombre oficial del estudiante).
--
-- Hasta ahora completar_onboarding lo sobrescribia con lo que mandara el
-- cliente, asi que cualquiera podia registrarse con un nombre inventado
-- llamando la RPC directamente. En un marketplace donde la gente queda en
-- verse en persona, esa identidad importa: pasa a ser de solo lectura.
--
-- Excepcion: si Google no entrego nombre, el trigger cae al usuario del
-- correo (p. ej. 'a2023115833'). En ese caso si se acepta el del formulario,
-- porque un codigo no sirve para identificar a nadie.
-- ============================================================================

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
    v_nombre_final := trim(coalesce(p_full_name, ''));
    if length(v_nombre_final) < 3 then
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
