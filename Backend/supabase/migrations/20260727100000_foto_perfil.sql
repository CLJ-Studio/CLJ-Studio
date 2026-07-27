-- ============================================================================
-- 23 · Foto de perfil y logo editable del local
-- ============================================================================
-- El perfil solo mostraba la inicial del nombre en un circulo. Quien vende
-- con marca propia (galletas "Dulce Campus") necesita ademas un logo, y quien
-- vende de forma casual quiere su cara: son dos identidades distintas y la
-- app debe permitir ambas sin obligar a ninguna.
--
-- `avatar_path` va en profiles (la persona) y `logo_path` ya existe en stores
-- (el negocio). Un vendedor casual solo usa el primero.
-- ============================================================================

alter table public.profiles add column avatar_path text;

-- El avatar es lo unico del perfil que el cliente puede escribir directo,
-- junto a is_on_campus: es una ruta del bucket, sin nada que validar.
grant update (avatar_path) on public.profiles to authenticated;

-- ----------------------------------------------------------------------------
-- Edicion del local ya existente (nombre, descripcion, emoji, logo).
-- Antes solo se podia definir al crearlo.
-- ----------------------------------------------------------------------------
create or replace function public.actualizar_local(
  p_nombre      text,
  p_descripcion text,
  p_emoji       text,
  p_categoria   text,
  p_logo_path   text
)
returns public.stores
language plpgsql
security definer
set search_path = public
as $$
declare
  v_local public.stores%rowtype;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  if length(trim(coalesce(p_nombre, ''))) < 3 then
    raise exception 'NOMBRE_INVALIDO: minimo 3 caracteres' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.categories where id = p_categoria and is_active
  ) then
    raise exception 'CATEGORIA_INVALIDA' using errcode = '22023';
  end if;

  -- El trigger de contenido revisa nombre y descripcion al actualizar.
  update public.stores
     set name        = trim(p_nombre),
         description = trim(coalesce(p_descripcion, '')),
         emoji       = coalesce(p_emoji, emoji),
         category_id = p_categoria,
         logo_path   = coalesce(p_logo_path, logo_path),
         is_personal = false
   where owner_id = auth.uid()
     and is_active
  returning * into v_local;

  if v_local.id is null then
    raise exception 'SIN_LOCAL: primero abre tu local' using errcode = '22023';
  end if;

  return v_local;
end;
$$;

revoke all on function public.actualizar_local(text, text, text, text, text)
  from public;
grant execute on function public.actualizar_local(text, text, text, text, text)
  to authenticated;
