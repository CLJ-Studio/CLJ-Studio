-- ============================================================================
-- 05 · Row Level Security
-- ============================================================================
-- Sin RLS, la anon key publica permitiria leer TODA la base desde el navegador.
-- Regla general: lectura amplia de catalogo, escritura solo sobre lo propio,
-- y CERO escritura directa sobre estados de pedido o stock.
-- ============================================================================

alter table public.institutional_domains enable row level security;
alter table public.profiles              enable row level security;
alter table public.categories            enable row level security;
alter table public.campus_locations      enable row level security;
alter table public.stores                enable row level security;
alter table public.products              enable row level security;
alter table public.product_images        enable row level security;
alter table public.favorites             enable row level security;
alter table public.orders                enable row level security;
alter table public.order_items           enable row level security;
alter table public.order_events          enable row level security;
alter table public.notifications         enable row level security;

-- ----------------------------------------------------------------------------
-- Catalogo de referencia: lectura para autenticados, escritura solo backend.
-- ----------------------------------------------------------------------------
create policy categorias_lectura on public.categories
  for select to authenticated using (is_active);

create policy puntos_encuentro_lectura on public.campus_locations
  for select to authenticated using (is_active);

-- institutional_domains no tiene policy de lectura a proposito:
-- la lista de dominios solo la usa el trigger (SECURITY DEFINER, ignora RLS).

-- ----------------------------------------------------------------------------
-- profiles
-- ATENCION: la columna whatsapp es visible para el DUENO del perfil.
-- Para que el comprador vea el del vendedor NO se usa RLS: se usa
-- get_contacto_pedido(), que exige pedido aceptado. Por eso aqui no hay
-- ninguna policy del tipo "puedes ver perfiles con los que tienes pedidos":
-- eso filtraria el telefono desde un pedido apenas 'solicitado'.
--
-- Para mostrar el nombre del vendedor en el feed se usa la vista
-- perfiles_publicos (definida abajo), que no incluye whatsapp.
-- ----------------------------------------------------------------------------
create policy perfil_propio_lectura on public.profiles
  for select to authenticated using (id = auth.uid());

create policy perfil_propio_escritura on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Vista sin datos sensibles para pintar vendedores en el feed.
-- security_invoker = off: la vista puede leer profiles saltandose la RLS de
-- arriba, pero solo expone las columnas listadas aqui. whatsapp jamas sale.
create view public.perfiles_publicos
with (security_invoker = off) as
  select id, full_name, avatar_emoji, career, is_on_campus,
         rating_average, rating_count
    from public.profiles;

grant select on public.perfiles_publicos to authenticated;

-- ----------------------------------------------------------------------------
-- stores · el feed necesita ver todos los locales activos
-- ----------------------------------------------------------------------------
create policy locales_lectura_publica on public.stores
  for select to authenticated using (is_active);

create policy local_propio_crear on public.stores
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    -- No puedes abrir un local sin haber completado el onboarding.
    and exists (
      select 1 from public.profiles
       where id = auth.uid() and onboarding_completed
    )
  );

create policy local_propio_editar on public.stores
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy local_propio_borrar on public.stores
  for delete to authenticated using (owner_id = auth.uid());

-- ----------------------------------------------------------------------------
-- products · lectura publica del catalogo; escritura solo del dueno del local
-- ----------------------------------------------------------------------------
create policy productos_lectura_publica on public.products
  for select to authenticated
  using (
    exists (
      select 1 from public.stores s
       where s.id = products.store_id and s.is_active
    )
  );

create policy productos_del_dueno_crear on public.products
  for insert to authenticated
  with check (
    exists (
      select 1 from public.stores s
       where s.id = products.store_id and s.owner_id = auth.uid()
    )
  );

-- El dueno puede editar precio/nombre/stock de su inventario (PantallaMiLocal).
-- El descuento de stock por venta NO pasa por aqui: lo hace aceptar_pedido().
create policy productos_del_dueno_editar on public.products
  for update to authenticated
  using (
    exists (
      select 1 from public.stores s
       where s.id = products.store_id and s.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.stores s
       where s.id = products.store_id and s.owner_id = auth.uid()
    )
  );

create policy productos_del_dueno_borrar on public.products
  for delete to authenticated
  using (
    exists (
      select 1 from public.stores s
       where s.id = products.store_id and s.owner_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- product_images (fase 2)
-- ----------------------------------------------------------------------------
create policy imagenes_lectura_publica on public.product_images
  for select to authenticated using (true);

create policy imagenes_del_dueno on public.product_images
  for all to authenticated
  using (
    exists (
      select 1 from public.products p
        join public.stores s on s.id = p.store_id
       where p.id = product_images.product_id and s.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.products p
        join public.stores s on s.id = p.store_id
       where p.id = product_images.product_id and s.owner_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- favorites · estrictamente privados (ControladorFavoritos)
-- ----------------------------------------------------------------------------
create policy favoritos_propios on public.favorites
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- orders · visibles solo para las dos partes
-- NO hay policy de INSERT ni de UPDATE: crear y cambiar estado pasa
-- obligatoriamente por las funciones (crear_pedido, aceptar_pedido, ...).
-- Asi un cliente no puede escribir status='aceptado' por su cuenta.
-- ----------------------------------------------------------------------------
create policy pedidos_de_las_partes on public.orders
  for select to authenticated
  using (buyer_id = auth.uid() or seller_id = auth.uid());

create policy items_de_las_partes on public.order_items
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
       where o.id = order_items.order_id
         and (o.buyer_id = auth.uid() or o.seller_id = auth.uid())
    )
  );

create policy eventos_de_las_partes on public.order_events
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
       where o.id = order_events.order_id
         and (o.buyer_id = auth.uid() or o.seller_id = auth.uid())
    )
  );

-- ----------------------------------------------------------------------------
-- notifications · cada quien ve las suyas y solo puede marcarlas leidas
-- ----------------------------------------------------------------------------
create policy notificaciones_propias_lectura on public.notifications
  for select to authenticated using (user_id = auth.uid());

create policy notificaciones_propias_marcar on public.notifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Realtime · PantallaContactandoVendedor escucha el cambio de estado
-- ----------------------------------------------------------------------------
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.notifications;
