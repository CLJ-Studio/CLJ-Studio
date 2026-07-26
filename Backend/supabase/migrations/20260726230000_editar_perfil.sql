-- ============================================================================
-- 12 · Edicion de perfil acotada
-- ============================================================================
-- HUECO QUE SE CIERRA: la policy `perfil_propio_escritura` permite UPDATE
-- sobre la fila propia, pero sin restringir columnas. Con el GRANT de UPDATE
-- sobre toda la tabla, cualquiera podia escribir desde el navegador:
--   .from('profiles').update({'rating_average': 5, 'full_name': 'otro'})
-- es decir, inflarse la reputacion o cambiar el nombre institucional.
--
-- Se revoca el UPDATE general y solo se otorga sobre `is_on_campus`, que es
-- un interruptor sin validaciones. Carrera y WhatsApp pasan por funcion,
-- porque necesitan normalizarse y validarse contra el catalogo.
-- ============================================================================

revoke update on public.profiles from authenticated;
grant update (is_on_campus) on public.profiles to authenticated;

-- ----------------------------------------------------------------------------
-- actualizar_perfil · carrera y WhatsApp
-- El nombre no se toca: sigue siendo el de la cuenta institucional.
-- ----------------------------------------------------------------------------
create or replace function public.actualizar_perfil(
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

  if not exists (
    select 1 from public.careers where id = p_career_id and is_active
  ) then
    raise exception 'CARRERA_INVALIDA: selecciona una carrera de la lista'
      using errcode = '22023';
  end if;

  v_whatsapp := regexp_replace(coalesce(p_whatsapp, ''), '\D', '', 'g');

  -- Igual que en el onboarding: wa.me exige codigo de pais.
  if length(v_whatsapp) = 8 then
    v_whatsapp := '591' || v_whatsapp;
  end if;

  if length(v_whatsapp) < 11 or length(v_whatsapp) > 15 then
    raise exception 'WHATSAPP_INVALIDO: revisa el numero' using errcode = '22023';
  end if;

  update public.profiles
     set career_id = p_career_id,
         whatsapp  = v_whatsapp
   where id = auth.uid()
  returning * into v_perfil;

  if v_perfil.id is null then
    raise exception 'PERFIL_INEXISTENTE: vuelve a iniciar sesion'
      using errcode = '42501';
  end if;

  return v_perfil;
end;
$$;

revoke all on function public.actualizar_perfil(text, text) from public;
grant execute on function public.actualizar_perfil(text, text) to authenticated;
