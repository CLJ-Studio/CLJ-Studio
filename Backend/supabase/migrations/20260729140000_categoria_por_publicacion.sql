-- ============================================================================
-- 37 · Cada publicacion con su propia categoria
-- ============================================================================
-- La categoria vivia solo en `stores`, asi que el filtro del inicio comparaba
-- contra la categoria de la TIENDA. Eso tiene dos consecuencias malas:
--
-- 1. El espacio personal se crea por detras al publicar y nace sin categoria
--    (la columna es nullable desde la migracion 11). Por tanto NINGUNA
--    publicacion suelta aparecia jamas al filtrar: la barra de categorias
--    estaba de adorno para la mitad del catalogo.
--
-- 2. Un local que vende comida y tambien apuntes quedaba entero bajo una
--    sola etiqueta. La categoria describe lo que se vende, no quien lo vende.
--
-- Se anade a `products`. Queda nullable a proposito: lo ya publicado no tiene
-- categoria y no hay forma de adivinarla, asi que cae a la de su tienda, que
-- es lo que se venia usando. Lo nuevo si la pide.
-- ============================================================================

alter table public.products
  add column if not exists category_id text references public.categories(id);

-- El filtro del inicio ordena y filtra por aqui.
create index if not exists products_categoria_idx
  on public.products(category_id) where is_available;

-- ----------------------------------------------------------------------------
-- Rellenar lo que ya existe con la categoria de su tienda.
-- ----------------------------------------------------------------------------
-- Asi lo antiguo se comporta igual que antes en vez de desaparecer de los
-- filtros. Lo del espacio personal se queda en null, que es la verdad: nunca
-- tuvo una.
update public.products p
   set category_id = s.category_id
  from public.stores s
 where p.store_id = s.id
   and p.category_id is null
   and s.category_id is not null;
