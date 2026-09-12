-- ============================================================================
-- 49 · Publicidad que se cambia sin volver a publicar la app
-- ============================================================================
-- Los dos espacios publicitarios del inicio viven hoy dentro del codigo
-- Flutter, con imagenes en `assets/`. Cambiar un aviso obliga a compilar,
-- subir a App Store y a Google Play, y esperar la revision de Apple: dias
-- para reemplazar una imagen. Y quien quiera anunciar tiene que esperar a
-- que salga una version.
--
-- Aqui la publicidad pasa a ser contenido: filas en una tabla e imagenes en
-- un bucket. Se reemplaza desde el panel de Supabase y aparece en iOS,
-- Android y la PWA a la vez, sin tocar el codigo.
--
-- LO QUE **NO** CAMBIA: si no hay avisos activos (o no hay internet), la app
-- sigue mostrando los banners locales de siempre. La publicidad remota
-- reemplaza a los de asset solo cuando de verdad hay algo que mostrar; una
-- pantalla de inicio vacia por un fallo de red seria peor que un banner viejo.
--
-- QUIEN PUEDE TOCARLA: solo `administradores`, la misma tabla sin policies
-- que ya decide quien modera los reportes (migracion 43). Un estudiante
-- cualquiera no puede publicar avisos aunque llame la API directamente, y la
-- clave `service_role` no vive en la aplicacion.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · Donde va cada aviso
-- ----------------------------------------------------------------------------
-- Enum y no texto libre: cada valor tiene una proporcion distinta en la
-- pantalla, y un 'main-banner' con guion en vez de raya baja se mostraria
-- como "no hay publicidad" sin que nadie entienda por que.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'ubicacion_publicidad') then
    create type public.ubicacion_publicidad as enum (
      'main_banner',      -- el grande de arriba, proporcion 1.68:1
      'company_carousel'  -- los rectangulos de empresas, 2.596:1
    );
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- 2 · Los avisos
-- ----------------------------------------------------------------------------
create table if not exists public.advertisements (
  id          uuid primary key default gen_random_uuid(),

  -- Nombre interno, para reconocerlo en el panel. No se muestra en la app;
  -- la imagen ya lleva su propio texto.
  title       text not null,

  -- Ruta dentro del bucket `advertisements`, no una URL completa: la URL
  -- publica la arma el cliente. Guardar el dominio aqui obligaria a editar
  -- todas las filas si el proyecto cambia de host.
  image_path  text not null,

  placement   public.ubicacion_publicidad not null,

  -- Opcional: a donde lleva el aviso al tocarlo. Null = no hace nada.
  link_url    text,

  sort_order  integer not null default 0,
  is_active   boolean not null default true,

  -- Ventana de vigencia. Ambas opcionales: null en `starts_at` es "desde ya"
  -- y null en `ends_at` es "hasta que alguien lo apague". Sirve para dejar
  -- programada la campana de una empresa sin tener que acordarse de
  -- encenderla y apagarla a mano el dia exacto.
  starts_at   timestamptz,
  ends_at     timestamptz,

  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  constraint publicidad_titulo_util
    check (length(trim(title)) between 2 and 80),

  constraint publicidad_ruta_util
    check (length(trim(image_path)) > 0),

  -- La aplicacion ABRE este enlace. Sin esta restriccion, un `javascript:` o
  -- un `intent://` guardado aqui se convierte en codigo que corre en el
  -- telefono de quien toque el aviso. Solo web, y con dominio.
  constraint publicidad_enlace_web
    check (link_url is null or link_url ~* '^https?://[^\s/$.?#].[^\s]*$'),

  -- Una campana que termina antes de empezar no se mostraria nunca, y el
  -- error seria invisible: el aviso simplemente "no sale".
  constraint publicidad_ventana_coherente
    check (ends_at is null or starts_at is null or ends_at > starts_at)
);

-- El inicio pide siempre lo mismo: los activos de una ubicacion, en orden.
create index if not exists publicidad_visible_idx
  on public.advertisements (placement, sort_order, created_at)
  where is_active;

create trigger advertisements_updated_at
  before update on public.advertisements
  for each row execute function public.tocar_updated_at();

-- ----------------------------------------------------------------------------
-- 3 · Quien ve que
-- ----------------------------------------------------------------------------
alter table public.advertisements enable row level security;

-- Leer: cualquiera con sesion, pero SOLO lo que esta vigente ahora mismo.
-- El filtro de fechas vive aqui y no en el cliente a proposito: si estuviera
-- en el cliente, una campana ya vencida seguiria viajando al telefono y
-- bastaria con mirar la respuesta de la API para ver los avisos del mes que
-- viene, o los de un anunciante que todavia no salio al aire.
create policy publicidad_vigente_lectura on public.advertisements
  for select to authenticated
  using (
    is_active
    and (starts_at is null or starts_at <= now())
    and (ends_at   is null or ends_at   >  now())
  );

-- Los administradores ven todo, incluso lo apagado y lo programado: sin esto
-- no podrian editar una campana antes de que empiece.
create policy publicidad_administrador_lectura on public.advertisements
  for select to authenticated
  using (public.soy_administrador());

create policy publicidad_administrador_escritura on public.advertisements
  for all to authenticated
  using (public.soy_administrador())
  with check (public.soy_administrador());

grant select, insert, update, delete on public.advertisements to authenticated;

-- ----------------------------------------------------------------------------
-- 4 · El bucket de las imagenes
-- ----------------------------------------------------------------------------
-- Publico en LECTURA, igual que `imagenes`: un aviso publicitario es, por
-- definicion, algo que queremos que todos vean, y servirlo por URL publica
-- deja que el navegador y el telefono lo cacheen.
--
-- La ESCRITURA es solo de administradores. Es la diferencia con el bucket
-- `imagenes`, donde cada quien escribe en su carpeta: aqui no hay carpeta
-- por usuario porque no hay usuarios subiendo, hay una sola persona
-- decidiendo que se anuncia en el campus.
insert into storage.buckets (id, name, public)
values ('advertisements', 'advertisements', true)
on conflict (id) do nothing;

create policy "publicidad_lectura"
  on storage.objects for select to authenticated
  using (bucket_id = 'advertisements');

create policy "publicidad_subir_admin"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'advertisements' and public.soy_administrador());

create policy "publicidad_actualizar_admin"
  on storage.objects for update to authenticated
  using (bucket_id = 'advertisements' and public.soy_administrador())
  with check (bucket_id = 'advertisements' and public.soy_administrador());

create policy "publicidad_borrar_admin"
  on storage.objects for delete to authenticated
  using (bucket_id = 'advertisements' and public.soy_administrador());

-- ----------------------------------------------------------------------------
-- 5 · Como se carga un aviso, a mano
-- ----------------------------------------------------------------------------
-- 1. Storage > bucket `advertisements` > subir la imagen.
--      main_banner       -> proporcion 1.68:1   (ideal 1680 x 1000)
--      company_carousel  -> proporcion 2.596:1  (ideal 1620 x 624)
--
-- 2. Insertar la fila con la ruta del archivo (NO la URL completa).
--    PLANTILLA: los cuatro valores son de mentira, hay que reemplazarlos.
--    Corriendo esto tal cual queda un aviso activo apuntando a un archivo
--    que no existe, y como la publicidad remota tiene prioridad sobre los
--    banners de assets/, el inicio se queda sin banner hasta que alguien
--    borre la fila.
--
--      insert into public.advertisements (title, image_path, placement, link_url, sort_order)
--      values ('<nombre>', '<carpeta/archivo.jpg>', 'main_banner', '<https://...>', 1);
--
-- 3. Para reemplazar la imagen de un aviso que ya existe, subir el archivo
--    con un NOMBRE NUEVO y apuntar la fila ahi. Pisar el archivo anterior
--    deja la version vieja cacheada en los telefonos que ya la bajaron. El
--    cliente igual agrega ?v=<updated_at> a la URL como segunda defensa.
--
-- 4. Para apagar un aviso: `update public.advertisements set is_active = false
--    where id = '...'`. Borrar la fila tambien vale, pero apagarla conserva
--    el historial de lo que se anuncio.
-- ----------------------------------------------------------------------------
