-- ============================================================================
-- 24 · Mas categorias, relanzar publicaciones y vitrina publica
-- ============================================================================
-- 1. Cuatro categorias no alcanzan para lo que realmente se vende en un
--    campus: ropa, cuentas de streaming, clases particulares, paginas web...
--    Con pocas categorias todo cae en "Servicios" y el filtro deja de servir.
--
-- 2. `bumped_at` permite relanzar: cuando el catalogo crece, una publicacion
--    vieja queda enterrada. Relanzar la sube sin obligar a borrarla y volver
--    a crearla (que perderia su historial y sus favoritos).
--
-- 3. `locales_publicos` expone el avatar del vendedor. La RLS de `profiles`
--    solo deja ver la fila propia, asi que un join normal devolveria vacio;
--    la vista corre como owner y expone unicamente datos publicos.
-- ============================================================================

insert into public.categories (id, name, icon_name, sort_order) values
  ('ropa',        'Ropa',                  'checkroom_rounded',        5),
  ('streaming',   'Streaming',             'subscriptions_rounded',    6),
  ('clases',      'Clases y tutorias',     'school_rounded',           7),
  ('web',         'Diseño y desarrollo',   'code_rounded',             8),
  ('belleza',     'Belleza y cuidado',     'spa_rounded',              9),
  ('deportes',    'Deportes',              'sports_soccer_rounded',   10),
  ('accesorios',  'Accesorios',            'watch_rounded',           11),
  ('hogar',       'Hogar',                 'chair_rounded',           12),
  ('arte',        'Arte y manualidades',   'palette_rounded',         13),
  ('mascotas',    'Mascotas',              'pets_rounded',            14),
  ('musica',      'Música',                'music_note_rounded',      15),
  ('fotografia',  'Fotografía',            'photo_camera_rounded',    16),
  ('eventos',     'Eventos',               'celebration_rounded',     17),
  ('transporte',  'Transporte',            'directions_bike_rounded', 18),
  ('salud',       'Salud y bienestar',     'medical_services_rounded',19),
  ('otros',       'Otros',                 'category_rounded',        99)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- Relanzar: sube la publicacion sin recrearla.
-- ----------------------------------------------------------------------------
alter table public.products
  add column bumped_at timestamptz not null default now();

create index products_recientes_idx
  on public.products(store_id, bumped_at desc);

create or replace function public.relanzar_producto(p_producto_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.products p
     set bumped_at = now(),
         is_available = true   -- relanzar tambien lo vuelve visible
    from public.stores s
   where p.id = p_producto_id
     and s.id = p.store_id
     and s.owner_id = auth.uid();

  if not found then
    raise exception 'PRODUCTO_AJENO_O_INEXISTENTE' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.relanzar_producto(uuid) from public;
grant execute on function public.relanzar_producto(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- Vitrina publica de locales, con el avatar de quien vende.
-- ----------------------------------------------------------------------------
create view public.locales_publicos
with (security_invoker = off) as
  select
    s.id,
    s.name,
    s.description,
    s.category_id,
    s.emoji,
    s.color_hex,
    s.estimated_time,
    s.delivery_cost,
    s.is_open,
    s.rating_average,
    s.is_personal,
    s.logo_path,
    s.owner_id,
    c.name  as categoria_nombre,
    p.full_name   as vendedor_nombre,
    p.avatar_path as vendedor_avatar,
    -- Portada: la primera foto de producto sirve de vitrina cuando el local
    -- no subio logo, en vez de dejar una tarjeta sin imagen.
    (
      select pr.image_path
        from public.products pr
       where pr.store_id = s.id
         and pr.image_path is not null
         and pr.is_available
       order by pr.bumped_at desc
       limit 1
    ) as portada_path
  from public.stores s
  join public.profiles p on p.id = s.owner_id
  left join public.categories c on c.id = s.category_id
 where s.is_active;

grant select on public.locales_publicos to authenticated;
