-- ============================================================================
-- Publicaciones que vencen: lo que encontro la revision
-- ============================================================================
-- 1 · La limpieza solo borra fotos de la carpeta de quien publico. Las rutas
--     de Storage son <uid>/... y la limpieza corre con service role: sin esa
--     condicion, alguien podia apuntar su publicacion a una foto ajena aun
--     sin usar, marcarla vieja y dejar que la limpieza se la borrara.
-- 2 · sold_at lo escribe solo el servidor (la entrega o "Ya lo vendi"): la
--     app no puede inventar una venta vieja para adelantar la limpieza.
-- 3 · La limpieza borra las filas ANTES que las fotos, en una sola funcion.
--     Antes listaba, la Edge Function borraba las fotos y recien despues se
--     borraban las filas: si en el medio alguien volvia a publicar, quedaba
--     publicada sin fotos. Ahora, si Storage falla, a lo sumo quedan fotos
--     huerfanas; nunca una publicacion rota.
-- 4 · No se crea un pedido de algo vencido aunque la limpieza del minuto
--     todavia no lo haya sacado del catalogo.
-- 5 · Una publicacion personal agotada que se oculto antes de la entrega
--     tambien queda como vendida.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2 · sold_at, solo del servidor (y lo que ya validaba el disparador)
-- ----------------------------------------------------------------------------
create or replace function public.products_validar_vencimiento()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- La app corre como authenticated. marcar_vendida y la entrega corren
  -- como el dueno de las funciones (security definer): esas si escriben.
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.sold_at := null;
    elsif new.sold_at is distinct from old.sold_at then
      new.sold_at := old.sold_at;
    end if;
  end if;

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

-- sold_at entra en la lista: un UPDATE que solo tocaba sold_at no disparaba.
drop trigger if exists products_vencimiento on public.products;
create trigger products_vencimiento
  before insert or update of expires_at, is_available, sold_at on public.products
  for each row execute function public.products_validar_vencimiento();

-- ----------------------------------------------------------------------------
-- 4 · Ningun pedido de algo vencido
-- ----------------------------------------------------------------------------
-- crear_pedido revisa is_available, y eso lo apaga la limpieza del minuto.
-- Entre que vence y que pasa la limpieza (o si la limpieza fallara), alguien
-- con la publicacion en el carrito podia pedirla igual. Aceptar un pedido
-- hecho a tiempo si sigue permitido: esto mira solo los pedidos nuevos.
create or replace function public.order_items_sin_vencidas()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if exists (
    select 1 from public.products p
     where p.id = new.product_id
       and p.expires_at <= now()
  ) then
    raise exception 'PRODUCTO_NO_DISPONIBLE: %', new.product_id
      using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists order_items_sin_vencidas on public.order_items;
create trigger order_items_sin_vencidas
  before insert on public.order_items
  for each row execute function public.order_items_sin_vencidas();

-- ----------------------------------------------------------------------------
-- 5 · La personal agotada queda vendida aunque se haya ocultado antes
-- ----------------------------------------------------------------------------
create or replace function public.retirar_vendidas_del_pedido()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.products p
     set is_available = false,
         sold_at      = coalesce(p.sold_at, now())
    from public.stores s
   where s.id = p.store_id
     and s.is_personal
     and p.kind = 'producto'
     and p.stock = 0
     and p.id in (select oi.product_id
                    from public.order_items oi
                   where oi.order_id = new.id);
  return null;
end;
$$;

-- ----------------------------------------------------------------------------
-- 1 y 3 · La limpieza: filas primero, y solo fotos propias
-- ----------------------------------------------------------------------------
drop function if exists public.publicaciones_para_limpiar(integer);
drop function if exists public.borrar_publicaciones(uuid[]);

-- Borra hasta p_limite publicaciones limpiables y devuelve, de cada una, las
-- fotos que hay que sacar de Storage. Todo en una sentencia: la fila que
-- alguien vuelve a publicar en ese momento o queda bloqueada (y se salta) o
-- ya no cumple la condicion al revisarse otra vez; nunca se pierden las fotos
-- de algo que sigue publicado.
create or replace function public.limpiar_publicaciones_vencidas(
  p_limite integer default 100
)
returns table (id uuid, rutas text[])
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  return query
  with candidatas as materialized (
    select p.id, p.image_path, s.owner_id
      from public.products p
      join public.stores s on s.id = p.store_id
     where public.publicacion_limpiable(p)
     order by coalesce(p.sold_at, p.expires_at), p.id
     limit least(greatest(coalesce(p_limite, 100), 1), 500)
     for update of p skip locked
  ),
  fotos as (
    select c.id, f.ruta
      from candidatas c
      cross join lateral (
        select c.image_path as ruta
        union
        select i.storage_path
          from public.product_images i
         where i.product_id = c.id
      ) f
     where f.ruta is not null
       -- Solo de la carpeta de quien publico. Tambien deja afuera los
       -- enlaces de otros sitios, que empiezan por "https:".
       and split_part(f.ruta, '/', 1) = c.owner_id::text
       -- Ni una que use otra publicacion que se queda, un local o un perfil.
       and not exists (select 1 from public.products o
                        where o.image_path = f.ruta
                          and o.id not in (select x.id from candidatas x))
       and not exists (select 1 from public.product_images o
                        where o.storage_path = f.ruta
                          and o.product_id not in (select x.id from candidatas x))
       and not exists (select 1 from public.stores s where s.logo_path = f.ruta)
       and not exists (select 1 from public.profiles u where u.avatar_path = f.ruta)
  ),
  borradas as (
    delete from public.products p
     using candidatas c
     where p.id = c.id
    returning p.id
  )
  select b.id,
         coalesce(
           (select array_agg(distinct f.ruta) from fotos f where f.id = b.id),
           '{}'::text[]
         )
    from borradas b;
end;
$$;

revoke all on function
  public.order_items_sin_vencidas(),
  public.limpiar_publicaciones_vencidas(integer)
from public, anon, authenticated;
grant execute on function public.limpiar_publicaciones_vencidas(integer)
  to service_role;

notify pgrst, 'reload schema';
