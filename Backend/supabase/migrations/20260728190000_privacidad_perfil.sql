-- ============================================================================
-- 31 · Qué de mi perfil ve el resto
-- ============================================================================
-- Hasta ahora todo lo del perfil era publico sin remedio: las vistas de cada
-- publicacion y lo guardado en favoritos se veian siempre. Son dos cosas que
-- alguien puede querer para si:
--
--   · Las vistas delatan que una publicacion no interesa a nadie, y un cero
--     grande la hunde mas todavia.
--   · Los favoritos dicen qué te gusta y a quien le compras.
--
-- Los valores por defecto no son iguales a proposito. Las vistas quedan
-- visibles porque hoy ya lo estan y apagarlas de golpe cambiaria la app a
-- quien no lo pidio. Los favoritos arrancan ocultos porque hoy NO se muestran
-- a nadie: encenderlos solos seria publicar algo que nunca fue publico.
-- ============================================================================

alter table public.profiles
  add column if not exists show_view_count boolean not null default true,
  add column if not exists show_favorites  boolean not null default false;

-- El dueno del perfil es el unico que decide. El resto de columnas ya tenian
-- su grant por separado, asi que estas siguen el mismo camino.
grant update (show_view_count, show_favorites) on public.profiles to authenticated;

-- ----------------------------------------------------------------------------
-- La vista publica las expone para que el perfil ajeno sepa que puede pintar.
-- security_invoker sigue apagado: lee profiles saltandose su RLS, pero solo
-- deja salir las columnas de aqui. whatsapp jamas aparece.
-- ----------------------------------------------------------------------------
create or replace view public.perfiles_publicos
with (security_invoker = off) as
  select p.id, p.full_name, p.avatar_emoji, c.name as career,
         p.is_on_campus, p.rating_average, p.rating_count,
         p.avatar_path, p.show_view_count, p.show_favorites
    from public.profiles p
    left join public.careers c on c.id = p.career_id;

grant select on public.perfiles_publicos to authenticated;

-- ----------------------------------------------------------------------------
-- Los locales tambien lo arrastran: el carrusel y el perfil publico leen de
-- aqui, y necesitan saber si pueden ensenar el contador de quien vende.
-- ----------------------------------------------------------------------------
create or replace view public.locales_publicos
with (security_invoker = off) as
  select
    s.id, s.name, s.description, s.category_id, s.emoji, s.color_hex,
    s.estimated_time, s.delivery_cost, s.is_open, s.rating_average,
    s.is_personal, s.logo_path, s.owner_id,
    c.name as categoria_nombre,
    p.full_name as vendedor_nombre,
    p.avatar_path as vendedor_avatar,
    (
      select pr.image_path
        from public.products pr
       where pr.store_id = s.id
         and pr.image_path is not null
         and pr.is_available
       order by pr.bumped_at desc
       limit 1
    ) as portada_path,
    s.view_count,
    s.campus_location,
    s.location_updated_at,
    p.show_view_count as vendedor_muestra_vistas
  from public.stores s
  join public.profiles p on p.id = s.owner_id
  left join public.categories c on c.id = s.category_id
 where s.is_active;

grant select on public.locales_publicos to authenticated;
