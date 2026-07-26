-- ============================================================================
-- 02 · Tablas
-- ============================================================================
-- Cada columna esta mapeada contra un widget/modelo real del Frontend.
-- La referencia Dart aparece como comentario para mantener la coherencia.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Dominios institucionales permitidos (configurable, NO hardcodeado)
-- Reemplaza al dominio quemado en ControladorAccesoUpsa.dominio.
-- ----------------------------------------------------------------------------
create table public.institutional_domains (
  domain      text primary key,                    -- 'estudiantes.upsa.edu.bo'
  label       text not null,                       -- 'Estudiantes UPSA'
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- profiles · extiende auth.users
-- Frontend: UsuarioUpsa {nombre, codigo, correo, carrera} + onboarding
-- ----------------------------------------------------------------------------
create table public.profiles (
  id                   uuid primary key references auth.users(id) on delete cascade,
  email                text not null unique,        -- UsuarioUpsa.correo
  student_code         text unique,                 -- UsuarioUpsa.codigo -> 'a2024113311'
  full_name            text not null default '',    -- UsuarioUpsa.nombre
  career               text,                        -- UsuarioUpsa.carrera
  -- PRIVADO: nunca se expone por RLS directa. Solo via get_order_contact().
  whatsapp             text,
  avatar_emoji         text not null default '🎓',
  is_on_campus         boolean not null default false,  -- perfil "en campus/fuera"
  onboarding_completed boolean not null default false,  -- bloquea publicar/pedir
  rating_average       numeric(3,2) not null default 0,
  rating_count         integer not null default 0,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  -- El frontend construye el correo como 'a' + 10 digitos (ControladorAccesoUpsa).
  constraint profiles_student_code_formato
    check (student_code is null or student_code ~ '^a\d{10}$'),
  -- Si completo onboarding, nombre/carrera/whatsapp son obligatorios.
  constraint profiles_onboarding_completo
    check (
      not onboarding_completed
      or (length(trim(full_name)) > 0 and career is not null and whatsapp is not null)
    )
);

-- ----------------------------------------------------------------------------
-- categories
-- Frontend: CategoriaMarketplace {id, nombre, icono: IconData}
-- IconData no es serializable -> se guarda el NOMBRE del icono y Dart lo mapea.
-- ----------------------------------------------------------------------------
create table public.categories (
  id          text primary key,               -- 'comida', 'tecnologia'
  name        text not null,                  -- 'Comida'
  icon_name   text not null,                  -- 'lunch_dining_rounded'
  sort_order  integer not null default 0,
  is_active   boolean not null default true
);

-- ----------------------------------------------------------------------------
-- campus_locations · puntos de encuentro seguros
-- ----------------------------------------------------------------------------
create table public.campus_locations (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,                  -- 'Bloque A - Recepcion'
  description text,
  is_active   boolean not null default true,
  sort_order  integer not null default 0
);

-- ----------------------------------------------------------------------------
-- stores (locales) · CAMBIO CLAVE frente al spec original
-- El frontend NO es vendedor-por-producto: es "local que agrupa productos"
-- (modulos locales_universitarios + mi_local).
-- Frontend: LocalUniversitario {id,nombre,categoriaId,categoria,descripcion,
--           calificacion,tiempoEstimado,estaAbierto,costoEntrega,emoji,colorHexadecimal}
-- ----------------------------------------------------------------------------
create table public.stores (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references public.profiles(id) on delete cascade,
  name            text not null,                        -- .nombre
  description     text not null default '',             -- .descripcion
  category_id     text not null references public.categories(id),  -- .categoriaId
  emoji           text not null default '🍽️',            -- .emoji (PantallaCrearLocal)
  -- .colorHexadecimal llega como 0xFFFFE8D6 = 4294962902 -> excede int4, usar bigint.
  color_hex       bigint not null default 4294962902,
  estimated_time  text not null default '15–25 min',    -- .tiempoEstimado
  delivery_cost   numeric(10,2) not null default 0,     -- .costoEntrega
  is_open         boolean not null default true,        -- .estaAbierto
  is_active       boolean not null default true,
  -- .calificacion: denormalizada, se recalcula desde ratings (fase 2).
  rating_average  numeric(3,2) not null default 0,
  rating_count    integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint stores_nombre_minimo check (length(trim(name)) >= 3),
  constraint stores_precio_entrega_positivo check (delivery_cost >= 0)
);

-- MVP: un local activo por estudiante (ControladorMiLocal.tieneLocal es booleano).
create unique index stores_un_local_por_dueno
  on public.stores(owner_id) where is_active;

create index stores_categoria_idx on public.stores(category_id) where is_active;
create index stores_busqueda_idx  on public.stores using gin (name gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- products
-- Frontend: ProductoMarketplace {id,localId,nombre,descripcion,precio,emoji}
--         + ProductoInventario {nombre,precio,cantidad}  (stock)
--         + BorradorPublicacion.tipo                      (producto/servicio)
-- ----------------------------------------------------------------------------
create table public.products (
  id            uuid primary key default gen_random_uuid(),
  store_id      uuid not null references public.stores(id) on delete cascade,  -- .localId
  name          text not null,                                -- .nombre
  description   text not null default '',                     -- .descripcion
  price         numeric(10,2) not null,                       -- .precio
  emoji         text not null default '🛍️',                    -- .emoji
  stock         integer not null default 0,                   -- ProductoInventario.cantidad
  kind          public.tipo_publicacion not null default 'producto',
  is_available  boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  constraint products_precio_positivo check (price >= 0),
  constraint products_stock_no_negativo check (stock >= 0),
  constraint products_nombre_minimo check (length(trim(name)) > 0)
);

create index products_store_idx     on public.products(store_id);
create index products_disponible_idx on public.products(store_id) where is_available;
create index products_busqueda_idx  on public.products using gin (name gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- product_images · FASE 2
-- Hoy el frontend usa emoji (SelectorImagenesPublicacion no sube nada todavia).
-- La tabla queda lista para cuando se conecte Supabase Storage.
-- ----------------------------------------------------------------------------
create table public.product_images (
  id           uuid primary key default gen_random_uuid(),
  product_id   uuid not null references public.products(id) on delete cascade,
  storage_path text not null,                  -- ruta dentro del bucket 'productos'
  position     integer not null default 0,
  created_at   timestamptz not null default now()
);

create index product_images_producto_idx on public.product_images(product_id, position);

-- ----------------------------------------------------------------------------
-- favorites · ControladorFavoritos.alternar()
-- ----------------------------------------------------------------------------
create table public.favorites (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

-- ----------------------------------------------------------------------------
-- orders · CAMBIO CLAVE: el carrito permite VARIOS productos por pedido
-- Frontend: ControladorCarritoCompras (subtotal + costoEntrega = total)
--           BotonContinuarPedido -> PantallaContactandoVendedor
-- ----------------------------------------------------------------------------
create table public.orders (
  id                 uuid primary key default gen_random_uuid(),
  buyer_id           uuid not null references public.profiles(id) on delete restrict,
  store_id           uuid not null references public.stores(id) on delete restrict,
  -- Denormalizado desde stores.owner_id: permite RLS simple y sobrevive
  -- a que el local cambie de dueno o se desactive.
  seller_id          uuid not null references public.profiles(id) on delete restrict,
  status             public.estado_pedido not null default 'solicitado',

  -- Snapshots monetarios: el precio del pedido NO cambia si el vendedor
  -- edita el producto despues. Se calculan en servidor, nunca desde el cliente.
  subtotal           numeric(10,2) not null default 0,
  delivery_cost      numeric(10,2) not null default 0,
  total              numeric(10,2) not null default 0,

  meeting_point_id   uuid references public.campus_locations(id),
  meeting_point_note text,
  buyer_note         text,

  expires_at         timestamptz not null,
  accepted_at        timestamptz,
  resolved_at        timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  constraint orders_comprador_no_es_vendedor check (buyer_id <> seller_id),
  constraint orders_totales_no_negativos
    check (subtotal >= 0 and delivery_cost >= 0 and total >= 0)
);

create index orders_comprador_idx on public.orders(buyer_id, created_at desc);
create index orders_vendedor_idx  on public.orders(seller_id, created_at desc);
-- Soporta el barrido de vencimiento sin escanear toda la tabla.
create index orders_pendientes_idx on public.orders(expires_at)
  where status = 'solicitado';

-- ----------------------------------------------------------------------------
-- order_items · ElementoCarrito {producto, cantidad}
-- ----------------------------------------------------------------------------
create table public.order_items (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references public.orders(id) on delete cascade,
  -- on delete set null: si el vendedor borra el producto, el historial del
  -- pedido sigue siendo legible gracias a los snapshots de abajo.
  product_id    uuid references public.products(id) on delete set null,
  product_name  text not null,                    -- snapshot
  product_emoji text not null default '🛍️',        -- snapshot
  unit_price    numeric(10,2) not null,           -- snapshot
  quantity      integer not null,
  line_total    numeric(10,2) generated always as (unit_price * quantity) stored,

  constraint order_items_cantidad_positiva check (quantity > 0)
);

create index order_items_pedido_idx on public.order_items(order_id);

-- ----------------------------------------------------------------------------
-- order_events · auditoria de transiciones
-- ----------------------------------------------------------------------------
create table public.order_events (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  actor_id    uuid references public.profiles(id) on delete set null,
  from_status public.estado_pedido,
  to_status   public.estado_pedido not null,
  note        text,
  created_at  timestamptz not null default now()
);

create index order_events_pedido_idx on public.order_events(order_id, created_at);

-- ----------------------------------------------------------------------------
-- notifications · in-app (Realtime). Web Push/FCM queda para fase 2.
-- ----------------------------------------------------------------------------
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  type       public.tipo_notificacion not null,
  title      text not null,
  body       text not null default '',
  order_id   uuid references public.orders(id) on delete cascade,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_usuario_idx on public.notifications(user_id, created_at desc);
create index notifications_no_leidas_idx on public.notifications(user_id)
  where read_at is null;

-- ----------------------------------------------------------------------------
-- updated_at automatico
-- ----------------------------------------------------------------------------
create or replace function public.tocar_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.tocar_updated_at();
create trigger stores_updated_at before update on public.stores
  for each row execute function public.tocar_updated_at();
create trigger products_updated_at before update on public.products
  for each row execute function public.tocar_updated_at();
create trigger orders_updated_at before update on public.orders
  for each row execute function public.tocar_updated_at();
