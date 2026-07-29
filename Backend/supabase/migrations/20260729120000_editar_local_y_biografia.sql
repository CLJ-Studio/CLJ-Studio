-- ============================================================================
-- 35 · Editar solo el negocio, y una biografia en el perfil
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · `actualizar_local` tocaba los dos locales de la persona
-- ----------------------------------------------------------------------------
-- La funcion es de cuando solo cabia un store activo por dueño: filtraba por
-- `owner_id` y `is_active` sin mirar el tipo, y ademas forzaba
-- `is_personal = false`.
--
-- Desde que conviven el espacio personal y el negocio, editar el negocio
-- reescribia TAMBIEN el espacio personal con el mismo nombre y lo convertia
-- en un segundo negocio. Las publicaciones sueltas habrian aparecido como
-- catalogo de una tienda duplicada.
--
-- Ahora solo alcanza al negocio, y si no hay ninguno lo dice en vez de
-- inventarse uno.
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
         logo_path   = coalesce(p_logo_path, logo_path)
   where owner_id = auth.uid()
     and is_active
     and not is_personal
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

-- ----------------------------------------------------------------------------
-- 2 · Biografia del perfil
-- ----------------------------------------------------------------------------
-- Una linea breve para contar quien eres o que vendes. El nombre y la carrera
-- los pone la universidad y no se tocan; esto es lo unico del perfil que
-- escribe la propia persona, asi que pasa por el filtro de contenido como
-- cualquier otro texto publico.
-- ----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists bio text;

alter table public.profiles
  drop constraint if exists profiles_bio_breve;
alter table public.profiles
  add constraint profiles_bio_breve check (bio is null or length(bio) <= 160);

grant update (bio) on public.profiles to authenticated;

-- Se revisa como el resto de textos que ve la comunidad.
create or replace function public.validar_bio_perfil()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.bio is not null and public.termino_ofensivo(new.bio) then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa tu descripcion'
      using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists validar_bio_antes_de_guardar on public.profiles;
create trigger validar_bio_antes_de_guardar
  before insert or update of bio on public.profiles
  for each row execute function public.validar_bio_perfil();

-- ----------------------------------------------------------------------------
-- 3 · La vista publica la expone
-- ----------------------------------------------------------------------------
create or replace view public.perfiles_publicos
with (security_invoker = off) as
  select p.id, p.full_name, p.avatar_emoji, c.name as career,
         p.is_on_campus, p.rating_average, p.rating_count,
         p.avatar_path, p.show_view_count, p.show_favorites,
         p.bio
    from public.profiles p
    left join public.careers c on c.id = p.career_id;

grant select on public.perfiles_publicos to authenticated;
