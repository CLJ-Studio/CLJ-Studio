-- ============================================================================
-- 42 · Nadie puede inundar el catalogo
-- ============================================================================
-- Hoy no hay ningun tope: una cuenta puede crear publicaciones tan rapido como
-- la red aguante. Con la aplicacion en una tienda eso deja de ser teorico —
-- basta una cuenta comprometida, o alguien con ganas de molestar, para tapar
-- el catalogo entero de un campus.
--
-- El limite mira las DOS ventanas a proposito:
--
--   · Por hora, para frenar la rafaga.
--   · Por dia, para que no baste esperar sesenta minutos y repetir. Sin esta,
--     el tope por hora solo obliga a tener paciencia.
--
-- Los numeros salen de lo que hace alguien de verdad: quien abre un local
-- carga su catalogo entero de una sentada, y son cinco o quince cosas, no
-- cuarenta. Se prefiere que sobre margen antes que trabar a un vendedor real
-- en su primer dia, que es cuando peor sienta.
--
-- Cuenta lo CREADO, no lo que existe. Borrar y volver a subir no devuelve
-- cupo: si no, el limite se saltaria con un borrado en medio.
-- ============================================================================

create or replace function public.limitar_ritmo_publicaciones()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dueno      uuid;
  v_ultima_hora integer;
  v_ultimo_dia  integer;
begin
  select s.owner_id into v_dueno
    from public.stores s
   where s.id = new.store_id;

  -- Sin dueno no hay a quien contarle: lo rechaza la RLS, no esto.
  if v_dueno is null then
    return new;
  end if;

  select
    count(*) filter (where p.created_at > now() - interval '1 hour'),
    count(*) filter (where p.created_at > now() - interval '1 day')
    into v_ultima_hora, v_ultimo_dia
    from public.products p
    join public.stores  s on s.id = p.store_id
   where s.owner_id = v_dueno;

  if v_ultima_hora >= 20 then
    raise exception 'LIMITE_PUBLICACIONES_HORA'
      using errcode = '22023',
            hint    = 'Espera un rato antes de publicar mas.';
  end if;

  if v_ultimo_dia >= 40 then
    raise exception 'LIMITE_PUBLICACIONES_DIA'
      using errcode = '22023',
            hint    = 'Llegaste al maximo de publicaciones por hoy.';
  end if;

  return new;
end;
$$;

drop trigger if exists limitar_ritmo_publicaciones on public.products;
create trigger limitar_ritmo_publicaciones
  before insert on public.products
  for each row execute function public.limitar_ritmo_publicaciones();

-- El conteo filtra por dueno a traves de stores y por fecha: sin este indice
-- cada alta recorreria la tabla entera de productos.
create index if not exists products_creado_idx
  on public.products (store_id, created_at desc);
