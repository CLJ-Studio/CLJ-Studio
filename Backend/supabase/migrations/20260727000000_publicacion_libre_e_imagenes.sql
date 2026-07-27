-- ============================================================================
-- 13 · Publicacion sin local formal + imagenes reales
-- ============================================================================
-- Decision de producto: no todo vendedor tiene un "emprendimiento". Publicar
-- debe funcionar sin abrir un local. El esquema exige que todo producto
-- pertenezca a un store (los pedidos, el stock y las RLS dependen de eso),
-- asi que la app crea por detras un store PERSONAL invisible para el
-- estudiante casual. `is_personal` lo distingue de un local formal, para que
-- la interfaz pueda tratarlos distinto sin duplicar tablas ni logica.
--
-- Un store personal no tiene categoria (no es un comercio): category_id
-- pasa a ser opcional.
--
-- Ademas: columnas para imagenes reales servidas desde Supabase Storage.
-- ============================================================================

alter table public.stores add column is_personal boolean not null default false;
alter table public.stores add column logo_path text;
alter table public.stores alter column category_id drop not null;

alter table public.products add column image_path text;

-- ----------------------------------------------------------------------------
-- Bucket publico de imagenes
-- ----------------------------------------------------------------------------
-- Publico en LECTURA a proposito: las fotos de productos son contenido del
-- marketplace (cualquiera con el enlace puede verlas, igual que en cualquier
-- tienda online). La ESCRITURA si esta restringida: cada quien solo puede
-- subir dentro de su carpeta <uid>/..., asi nadie pisa imagenes ajenas.
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('imagenes', 'imagenes', true)
on conflict (id) do nothing;

create policy "imagenes_lectura"
  on storage.objects for select to authenticated
  using (bucket_id = 'imagenes');

create policy "imagenes_subir_propias"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'imagenes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "imagenes_actualizar_propias"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'imagenes'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'imagenes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "imagenes_borrar_propias"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'imagenes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
