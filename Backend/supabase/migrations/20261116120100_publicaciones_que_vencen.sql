-- ============================================================================
-- Publicaciones que vencen
-- ============================================================================
-- Hasta ahora una publicacion no vencia nunca: la entrada para la fiesta del
-- sabado seguia en el catalogo el domingo, y la calculadora ya vendida seguia
-- ahi como agotada. Ahora:
--
--   · expires_at dice hasta cuando se ve. Nulo es "sin fecha".
--   · Cada minuto, lo vencido sale del catalogo (is_available = false) y a
--     quien lo publico le llega un aviso que abre la publicacion. Todo lo que
--     ya filtraba por is_available (inicio, buscador, destacados, perfil,
--     pedir) deja de mostrarla sin tocar nada mas.
--   · Una vencida no vuelve a verse sin elegir otra fecha:
--     volver_a_publicar(id, fecha). Relanzarla o mostrarla a mano se rechaza.
--   · Una publicacion personal que se agota sale sola cuando se confirma la
--     entrega (sold_at). No al aceptar: si el pedido se cancela, el stock
--     vuelve y la publicacion tiene que seguir ahi. Si la vendio por fuera de
--     la app, la marca con marcar_vendida(id). Una vendida le queda oculta a
--     quien la publico, que puede reponer y volver a publicarla.
--   · Siete dias despues de vencer o venderse se borra, con sus fotos. Lo
--     hace la Edge Function limpiar-publicaciones (desde SQL no se pueden
--     borrar archivos de Storage) con las dos funciones del punto 5. Nunca se
--     borra una con un pedido en curso.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · Las columnas
-- ----------------------------------------------------------------------------
alter table public.products
  add column if not exists expires_at timestamptz,
  add column if not exists sold_at    timestamptz;

comment on column public.products.expires_at is
  'Hasta cuando se ve en el catalogo. Nulo: sin fecha.';
comment on column public.products.sold_at is
  'Cuando salio sola por venderse (publicacion personal agotada y entregada).';

-- Lo unico que se busca cada minuto: las visibles con fecha.
create index if not exists products_por_vencer_idx
  on public.products (expires_at)
  where is_available and expires_at is not null;

-- ----------------------------------------------------------------------------
-- 2 · Una fecha que ya paso no se acepta, y una vencida no se muestra
-- ----------------------------------------------------------------------------
-- Solo mira lo que cambia: aceptar un pedido toca el stock de una publicacion
-- que pudo vencer hace segundos (antes de que pase la limpieza del minuto), y
-- eso no puede fallar.
create or replace function public.products_validar_vencimiento()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.expires_at is not null and new.expires_at <= now() then
    if tg_op = 'INSERT' then
      raise exception 'VENCIMIENTO_INVALIDO: la fecha ya paso'
        using errcode = '22023';
    end if;
    if new.expires_at is distinct from old.expires_at then
      raise exception 'VENCIMIENTO_INVALIDO: la fecha ya paso'
        using errcode = '22023';
    end if;
  end if;

  if tg_op = 'UPDATE' and new.is_available and not old.is_available then
    if new.expires_at is not null and new.expires_at <= now() then
      raise exception 'PUBLICACION_VENCIDA: elige hasta cuando se ve'
        using errcode = '22023';
    end if;
    -- Vuelve a verse: ya no esta "vendida".
    new.sold_at := null;
  end if;

  return new;
end;
$$;

drop trigger if exists products_vencimiento on public.products;
create trigger products_vencimiento
  before insert or update of expires_at, is_available on public.products
  for each row execute function public.products_validar_vencimiento();

-- ----------------------------------------------------------------------------
-- 3 · Cada minuto: lo vencido sale del catalogo y se avisa
-- ----------------------------------------------------------------------------
create or replace function public.vencer_publicaciones()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cantidad integer;
begin
  with vencidas as (
    update public.products p
       set is_available = false
     where p.is_available
       and p.expires_at <= now()
    returning p.id, p.store_id, p.name
  )
  insert into public.notifications (user_id, type, title, body, product_id)
  select s.owner_id,
         'publicacion_vencida',
         'Tu publicación venció',
         format('«%s» ya no se ve en el catálogo. Tócala para volver a publicarla.',
                v.name),
         v.id
    from vencidas v
    join public.stores s on s.id = v.store_id;

  get diagnostics v_cantidad = row_count;
  return v_cantidad;
end;
$$;

select cron.schedule(
  'vencer-publicaciones',
  '* * * * *',
  $$ select public.vencer_publicaciones(); $$
);

-- ----------------------------------------------------------------------------
-- 4 · Volver a publicar, y la personal vendida que sale sola
-- ----------------------------------------------------------------------------
-- Para una vencida (o vendida, u oculta): se ve de nuevo, arriba del
-- catalogo, hasta p_vence_en. Nulo es "sin fecha" (o, en una personal,
-- "hasta que se venda"). Con p_stock, repone en el mismo paso: una vendida
-- vuelve con lo que el vendedor tenga ahora.
create or replace function public.volver_a_publicar(
  p_producto_id uuid,
  p_vence_en    timestamptz,
  p_stock       integer default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  if p_vence_en is not null and p_vence_en <= now() then
    raise exception 'VENCIMIENTO_INVALIDO: la fecha ya paso'
      using errcode = '22023';
  end if;
  if p_stock is not null and p_stock < 1 then
    raise exception 'STOCK_INVALIDO: para volver a publicar hace falta al menos uno'
      using errcode = '22023';
  end if;

  update public.products p
     set expires_at   = p_vence_en,
         stock        = coalesce(p_stock, p.stock),
         is_available = true,
         bumped_at    = now()
    from public.stores s
   where p.id = p_producto_id
     and s.id = p.store_id
     and s.owner_id = auth.uid();

  if not found then
    raise exception 'PRODUCTO_AJENO_O_INEXISTENTE' using errcode = '42501';
  end if;
end;
$$;

-- "Ya lo vendi": lo vendio por fuera de la app, asi que el stock nunca llego
-- a cero. Sale del catalogo igual que una vendida por pedido.
create or replace function public.marcar_vendida(p_producto_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  update public.products p
     set is_available = false,
         sold_at      = now()
    from public.stores s
   where p.id = p_producto_id
     and s.id = p.store_id
     and s.owner_id = auth.uid();

  if not found then
    raise exception 'PRODUCTO_AJENO_O_INEXISTENTE' using errcode = '42501';
  end if;
end;
$$;

-- Se confirma una entrega: las publicaciones personales de ese pedido que
-- quedaron sin stock ya se vendieron. Las de un local no: un local repone.
create or replace function public.retirar_vendidas_del_pedido()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.products p
     set is_available = false,
         sold_at      = now()
    from public.stores s
   where s.id = p.store_id
     and s.is_personal
     and p.kind = 'producto'
     and p.is_available
     and p.stock = 0
     and p.id in (select oi.product_id
                    from public.order_items oi
                   where oi.order_id = new.id);
  return null;
end;
$$;

drop trigger if exists orders_retirar_vendidas on public.orders;
create trigger orders_retirar_vendidas
  after update of status on public.orders
  for each row
  when (new.status = 'entregado' and old.status is distinct from 'entregado')
  execute function public.retirar_vendidas_del_pedido();

-- ----------------------------------------------------------------------------
-- 5 · Lo que borra la limpieza diaria
-- ----------------------------------------------------------------------------
-- Vencida o vendida hace mas de siete dias, que no se ve, y sin un pedido en
-- curso. La misma condicion decide que se lista y que se borra.
create or replace function public.publicacion_limpiable(p public.products)
returns boolean
language sql
stable
set search_path = public
as $$
  select not p.is_available
     and (p.expires_at < now() - interval '7 days'
          or p.sold_at < now() - interval '7 days')
     and not exists (
       select 1
         from public.order_items oi
         join public.orders o on o.id = oi.order_id
        where oi.product_id = p.id
          and o.status in ('solicitado', 'aceptado', 'por_confirmar')
     );
$$;

-- Que borrar y que fotos llevarse. Una foto que tambien usa otra publicacion,
-- un local o un perfil se queda; y lo que no es una ruta del bucket (un
-- enlace de afuera) no se toca.
create or replace function public.publicaciones_para_limpiar(
  p_limite integer default 100
)
returns table (id uuid, rutas text[])
language sql
stable
security definer
set search_path = public
as $$
  select p.id,
         coalesce(array(
           select distinct f.ruta
             from (
               select p.image_path as ruta
               union all
               select i.storage_path
                 from public.product_images i
                where i.product_id = p.id
             ) f
            where f.ruta is not null
              and f.ruta <> ''
              and f.ruta !~* '^(https?:|blob:|data:)'
              and not exists (select 1 from public.products o
                               where o.id <> p.id and o.image_path = f.ruta)
              and not exists (select 1 from public.product_images o
                               where o.product_id <> p.id and o.storage_path = f.ruta)
              and not exists (select 1 from public.stores s
                               where s.logo_path = f.ruta)
              and not exists (select 1 from public.profiles u
                               where u.avatar_path = f.ruta)
         ), '{}')
    from public.products p
   where public.publicacion_limpiable(p)
   order by coalesce(p.sold_at, p.expires_at), p.id
   limit least(greatest(coalesce(p_limite, 100), 1), 500);
$$;

-- Borra las que la funcion de arriba listo, si siguen cumpliendo: alguien
-- pudo volver a publicar una mientras se borraban las fotos.
create or replace function public.borrar_publicaciones(p_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cantidad integer;
begin
  delete from public.products p
   where p.id = any(p_ids)
     and public.publicacion_limpiable(p);
  get diagnostics v_cantidad = row_count;
  return v_cantidad;
end;
$$;

-- Una vez al dia, de madrugada (8:00 UTC son las 4:00 en Bolivia), la base
-- llama a la Edge Function con la misma clave con que llama a enviar-push.
select cron.schedule(
  'limpiar-publicaciones',
  '0 8 * * *',
  $$
  select net.http_post(
           url     := regexp_replace(c.url_funcion, '[^/]+/?$', 'limpiar-publicaciones'),
           headers := jsonb_build_object(
                        'Content-Type', 'application/json',
                        'Authorization', 'Bearer ' || c.clave_servicio),
           body    := '{}'::jsonb,
           timeout_milliseconds := 60000)
    from public.configuracion_push c;
  $$
);

-- ----------------------------------------------------------------------------
-- 6 · Quien puede llamar que
-- ----------------------------------------------------------------------------
revoke all on function
  public.products_validar_vencimiento(),
  public.vencer_publicaciones(),
  public.volver_a_publicar(uuid, timestamptz, integer),
  public.marcar_vendida(uuid),
  public.retirar_vendidas_del_pedido(),
  public.publicacion_limpiable(public.products),
  public.publicaciones_para_limpiar(integer),
  public.borrar_publicaciones(uuid[])
from public, anon, authenticated;

grant execute on function
  public.volver_a_publicar(uuid, timestamptz, integer),
  public.marcar_vendida(uuid)
to authenticated;
grant execute on function
  public.publicaciones_para_limpiar(integer),
  public.borrar_publicaciones(uuid[])
to service_role;

notify pgrst, 'reload schema';
