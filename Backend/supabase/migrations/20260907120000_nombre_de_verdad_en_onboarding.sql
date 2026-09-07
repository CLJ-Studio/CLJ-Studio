-- ============================================================================
-- 48 · Que el nombre escrito a mano parezca un nombre
-- ============================================================================
-- Quien entra con Google trae el nombre oficial de la UPSA y el campo queda
-- bloqueado. Pero el acceso por codigo al correo (el que usa la aplicacion
-- hoy) solo demuestra que la persona abre ese buzon: Supabase no entrega
-- ningun nombre con el OTP. El perfil nace llamandose 'a2023115833' y el
-- onboarding tiene que preguntarlo.
--
-- Hasta ahora ese camino aceptaba cualquier cosa de tres letras, y alguien
-- se registro como "MOMO". Importa mas de lo que parece: `editar_perfil`
-- NO deja cambiar el nombre despues, asi que el apodo queda para siempre, y
-- es el nombre con el que la otra parte lo espera para entregarle algo en
-- persona.
--
-- No se puede verificar que el nombre sea el suyo sin una lista de la
-- universidad. Lo que si se puede es exigir que TENGA FORMA de nombre:
--   - nombre y apellido (dos partes, dos letras minimo cada una),
--   - solo letras, sin numeros ni el propio codigo de registro,
--   - y que pase el mismo filtro de contenido que la biografia y los
--     productos, que hasta ahora no se aplicaba aqui.
--
-- Esto no convierte el nombre en verdad verificada; solo sube el precio de
-- mentir. El unico camino a un nombre garantizado sigue siendo entrar con
-- Google, que es de donde salia antes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ¿Esto tiene forma de nombre de persona?
-- ----------------------------------------------------------------------------
-- En su propia funcion y no incrustada en el if: la expresion armada a mano
-- ocupa tres lineas de simbolos y ahi dentro nadie la vuelve a leer.
create or replace function public.nombre_parece_persona(p_nombre text)
returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  -- Una letra, con las tildes y la ñ que llevan los apellidos de aqui.
  v_letra text := '[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]';
  -- Una parte del nombre: palabra de dos letras o mas, o compuesta con guion
  -- o apostrofo ("Ana-Maria", "O''Connor"). El apostrofo va DENTRO de la
  -- parte y no separando: si no, "O''Connor" se leeria como una "O" suelta.
  v_parte text;
begin
  v_parte := '(' || v_letra || '{2,}|'
                 || v_letra || '+([''-]' || v_letra || '+)+)';

  -- Nombre y apellido: al menos dos partes separadas por espacio.
  return coalesce(trim(p_nombre), '') ~ ('^' || v_parte || '( ' || v_parte || ')+$');
end;
$$;

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
  v_termino        text;
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

    -- Deja pasar "Ana Maria Vaca", "Ana-Maria Vaca" y "Juan O''Connor";
    -- corta "MOMO", "xX", "a2023115833" y "Juan 2".
    if not public.nombre_parece_persona(v_nombre_final) then
      raise exception
        'NOMBRE_INVALIDO: escribe tu nombre y tu apellido, sin apodos'
        using errcode = '22023';
    end if;

    if length(v_nombre_final) > 60 then
      raise exception 'NOMBRE_INVALIDO: es demasiado largo'
        using errcode = '22023';
    end if;

    -- El mismo filtro que ya cuida las publicaciones y la biografia. Sin
    -- esto, el unico texto libre del perfil que nadie miraba era justo el
    -- que aparece en cada tarjeta de producto.
    v_termino := public.termino_ofensivo(v_nombre_final);
    if v_termino is not null then
      raise exception 'CONTENIDO_NO_PERMITIDO: revisa tu nombre'
        using errcode = '22023';
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

-- ----------------------------------------------------------------------------
-- Los que ya entraron con un apodo
-- ----------------------------------------------------------------------------
-- No se tocan automaticamente: renombrar a alguien por su codigo de registro
-- sin avisarle es peor que dejarle el apodo. Para revisarlos a mano:
--
--   select id, email, student_code, full_name
--     from public.profiles
--    where onboarding_completed
--      and not public.nombre_parece_persona(full_name);
--
-- Y para corregir uno concreto (el nombre no se puede editar desde la app):
--
--   update public.profiles set full_name = 'Nombre Apellido'
--    where email = 'a2023110000@estudiantes.upsa.edu.bo';
-- ----------------------------------------------------------------------------
