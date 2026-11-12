-- ============================================================================
-- Buscar en TODO el catalogo
--
-- El inicio baja las publicaciones por tandas, las mas recientes primero, y
-- el buscador miraba solo lo ya bajado: con mas de una tanda publicada, lo
-- anterior no se podia encontrar. Esta funcion busca en todas.
--
-- Encuentra lo mismo que el buscador de la app: el texto dentro del nombre o
-- la descripcion de la publicacion, o del nombre, la descripcion o la
-- categoria del local, o del nombre de quien vende. Sin distinguir
-- mayusculas ni acentos, con la misma tabla de acentos que la app
-- (`_normalizar` en pantalla_inicio_marketplace.dart). El panel vuelve a
-- filtrar lo que llega: lo que la base traiga de mas no se ve, pero lo que no
-- traiga no aparece. Por eso la tabla tiene que ser la misma.
--
-- Devuelve filas de `products`: la app pide con `select` las mismas columnas,
-- imagenes y variantes que en el inicio, y ordena y corta por su cuenta.
--
-- Invoker y no definer: la RLS de `products` sigue mandando. Solo para
-- cuentas con sesion, como todo el catalogo (`locales_publicos` tambien).
-- ============================================================================

create or replace function public.texto_buscable(p_texto text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  -- Las mayusculas acentuadas van tambien en la tabla: con una base en
  -- locale C, lower() solo baja las letras ASCII.
  select translate(
    lower(coalesce(p_texto, '')),
    'áàäâéèëêíìïîóòöôúùüûÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ',
    'aaaaeeeeiiiioooouuuuaaaaeeeeiiiioooouuuuñ'
  );
$$;

create or replace function public.buscar_publicaciones(p_texto text)
returns setof public.products
language sql
stable
security invoker
set search_path = ''
as $$
  with consulta as (
    select public.texto_buscable(btrim(p_texto)) as texto
  )
  select p.*
    from public.products p
    join public.locales_publicos l on l.id = p.store_id
    cross join consulta c
   where p.is_available
     -- Una letra sola encuentra casi todo; para eso alcanza lo ya bajado.
     and char_length(c.texto) >= 2
     and (
          strpos(public.texto_buscable(p.name), c.texto) > 0
       or strpos(public.texto_buscable(p.description), c.texto) > 0
       or strpos(public.texto_buscable(l.name), c.texto) > 0
       or strpos(public.texto_buscable(l.description), c.texto) > 0
       or strpos(public.texto_buscable(l.categoria_nombre), c.texto) > 0
       or strpos(public.texto_buscable(l.vendedor_nombre), c.texto) > 0
     );
$$;

revoke execute on function public.buscar_publicaciones(text) from public, anon;
grant execute on function public.buscar_publicaciones(text) to authenticated;

-- Que la API vea la funcion nueva sin esperar.
notify pgrst, 'reload schema';
