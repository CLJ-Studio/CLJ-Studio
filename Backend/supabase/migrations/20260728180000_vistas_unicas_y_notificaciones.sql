-- ============================================================================
-- 30 · Vistas por persona, notificaciones que llevan a algun sitio,
--      ubicacion del local y menos categorias
-- ============================================================================
-- Requiere haber ejecutado antes 20260728170000_tipo_notificacion_ubicacion.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · Una vista por persona y publicacion
-- ----------------------------------------------------------------------------
-- El contador subia en cada apertura, asi que quien recargaba diez veces su
-- propia publicacion (o pedia a un amigo que lo hiciera) se colocaba entre los
-- destacados. Guardar quien vio que convierte el numero en algo comparable.
--
-- Se guarda la fila y no solo el total porque sin ella no hay forma de saber
-- si esta persona ya paso por aqui.
-- ----------------------------------------------------------------------------
create table if not exists public.product_views (
  product_id uuid not null references public.products(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (product_id, user_id)
);

create table if not exists public.store_views (
  store_id   uuid not null references public.stores(id)   on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (store_id, user_id)
);

-- Sin policies: nadie las toca desde el cliente. Las dos funciones de abajo
-- son SECURITY DEFINER y son la unica puerta de entrada.
alter table public.product_views enable row level security;
alter table public.store_views   enable row level security;

create or replace function public.registrar_vista_producto(p_producto uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_total bigint;
begin
  -- Sin sesion, o siendo el dueno, se devuelve el total sin tocarlo: nadie
  -- infla su propio contador mirandose.
  if v_actor is null or exists (
    select 1
      from public.products p
      join public.stores s on s.id = p.store_id
     where p.id = p_producto and s.owner_id = v_actor
  ) then
    select view_count into v_total from public.products where id = p_producto;
    return coalesce(v_total, 0);
  end if;

  insert into public.product_views (product_id, user_id)
  values (p_producto, v_actor)
  on conflict do nothing;

  -- FOUND es falso cuando el ON CONFLICT descarto la fila, es decir cuando
  -- esta persona ya habia visto la publicacion.
  if found then
    update public.products
       set view_count = view_count + 1
     where id = p_producto
    returning view_count into v_total;
  else
    select view_count into v_total from public.products where id = p_producto;
  end if;

  return coalesce(v_total, 0);
end;
$$;

create or replace function public.registrar_vista_local(p_local uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_total bigint;
begin
  if v_actor is null or exists (
    select 1 from public.stores
     where id = p_local and owner_id = v_actor
  ) then
    select view_count into v_total from public.stores where id = p_local;
    return coalesce(v_total, 0);
  end if;

  insert into public.store_views (store_id, user_id)
  values (p_local, v_actor)
  on conflict do nothing;

  if found then
    update public.stores
       set view_count = view_count + 1
     where id = p_local and is_active
    returning view_count into v_total;
  else
    select view_count into v_total from public.stores where id = p_local;
  end if;

  return coalesce(v_total, 0);
end;
$$;

revoke all on function public.registrar_vista_producto(uuid) from public;
revoke all on function public.registrar_vista_local(uuid)    from public;
grant execute on function public.registrar_vista_producto(uuid) to authenticated;
grant execute on function public.registrar_vista_local(uuid)    to authenticated;

-- ----------------------------------------------------------------------------
-- 2 · Cada notificacion sabe a donde lleva
-- ----------------------------------------------------------------------------
-- Solo se guardaba `order_id`, asi que un aviso que no fuera de un pedido no
-- tenia a donde abrirse y quedaba como texto muerto en la bandeja.
-- ----------------------------------------------------------------------------
alter table public.notifications
  add column if not exists store_id   uuid references public.stores(id)   on delete cascade,
  add column if not exists product_id uuid references public.products(id) on delete cascade;

-- ----------------------------------------------------------------------------
-- 3 · Ubicacion del local dentro del campus
-- ----------------------------------------------------------------------------
-- El selector ya existia en la pantalla, pero vivia en memoria: se perdia al
-- recargar y nadie mas la veia. Sin guardarla no hay nada que recordar
-- renovar, ni forma de que el comprador sepa donde esta el vendedor.
-- ----------------------------------------------------------------------------
alter table public.stores
  add column if not exists campus_location     text,
  add column if not exists location_updated_at timestamptz;

create or replace function public.actualizar_ubicacion_local(
  p_local     uuid,
  p_ubicacion text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.stores
     set campus_location = nullif(trim(p_ubicacion), ''),
         location_updated_at = now()
   where id = p_local
     and owner_id = auth.uid()
     and is_active;

  if not found then
    raise exception 'LOCAL_AJENO_O_INEXISTENTE' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.actualizar_ubicacion_local(uuid, text) from public;
grant execute on function public.actualizar_ubicacion_local(uuid, text) to authenticated;

-- ----------------------------------------------------------------------------
-- 4 · Recordatorio periodico de ubicacion, solo a quien tiene el local abierto
-- ----------------------------------------------------------------------------
-- Un local abierto con la ubicacion de ayer manda al comprador al sitio
-- equivocado. Se avisa solo a quien esta abierto: a quien tiene el local
-- cerrado no le sirve de nada y seria ruido.
-- ----------------------------------------------------------------------------
create or replace function public.recordar_ubicacion_locales()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_avisados integer := 0;
begin
  with pendientes as (
    select s.id, s.owner_id, s.name
      from public.stores s
     where s.is_active
       and s.is_open
       and (
         s.location_updated_at is null
         or s.location_updated_at < now() - interval '6 hours'
       )
       -- Sin repetir el aviso si ya se le mando uno hoy y sigue sin tocarla.
       and not exists (
         select 1 from public.notifications n
          where n.store_id = s.id
            and n.type = 'ubicacion_pendiente'
            and n.created_at > now() - interval '6 hours'
       )
  )
  insert into public.notifications (user_id, type, title, body, store_id)
  select
    p.owner_id,
    'ubicacion_pendiente',
    'Actualiza tu ubicación',
    'Tienes ' || p.name || ' abierto. Confirma dónde estás para que te '
      || 'encuentren.',
    p.id
  from pendientes p;

  get diagnostics v_avisados = row_count;
  return v_avisados;
end;
$$;

revoke all on function public.recordar_ubicacion_locales() from public;

-- Se desprograma antes por si el archivo se ejecuta dos veces.
select cron.unschedule('recordar-ubicacion-locales')
 where exists (
   select 1 from cron.job where jobname = 'recordar-ubicacion-locales'
 );

-- Cada hora. El aviso en si solo sale si la ubicacion lleva mas de seis horas
-- sin tocarse, asi que la frecuencia del cron no es la del recordatorio.
select cron.schedule(
  'recordar-ubicacion-locales',
  '0 * * * *',
  $$select public.recordar_ubicacion_locales();$$
);

-- ----------------------------------------------------------------------------
-- 5 · Menos categorias
-- ----------------------------------------------------------------------------
-- Veinte categorias en una barra de chips obligan a desplazarse mucho para
-- encontrar la propia, y varias se solapaban. Se quitan las que un campus
-- practicamente no usa; lo que colgara de ellas pasa a "Otros" en vez de
-- quedar huerfano, que ademas es lo que exige la clave foranea.
--
-- Si alguna hace falta, se vuelve a insertar con su fila original.
-- ----------------------------------------------------------------------------
do $$
declare
  v_sobran text[] := array[
    'hogar', 'arte', 'mascotas', 'musica', 'fotografia', 'accesorios'
  ];
begin
  update public.stores
     set category_id = 'otros'
   where category_id = any(v_sobran);

  delete from public.categories where id = any(v_sobran);
end;
$$;
