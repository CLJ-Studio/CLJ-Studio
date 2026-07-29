-- ============================================================================
-- 36 · Arreglar el filtro de la biografia
-- ============================================================================
-- `termino_ofensivo` no devuelve un booleano: devuelve EL TERMINO encontrado,
-- o null si el texto esta limpio. El trigger de la migracion 35 lo trataba
-- como si fuera booleano:
--
--   if new.bio is not null and public.termino_ofensivo(new.bio) then
--
-- y Postgres respondia "argument of AND must be type boolean, not type text".
-- Como el trigger salta antes de escribir, guardar la descripcion fallaba
-- siempre, incluso con un texto perfectamente limpio.
--
-- El resto de triggers del proyecto ya usaban el patron correcto: guardar el
-- resultado y comprobar si es null.
-- ============================================================================

create or replace function public.validar_bio_perfil()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_termino text;
begin
  if new.bio is null or trim(new.bio) = '' then
    return new;
  end if;

  v_termino := public.termino_ofensivo(new.bio);

  if v_termino is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa tu descripcion'
      using errcode = '22023';
  end if;

  return new;
end;
$$;
