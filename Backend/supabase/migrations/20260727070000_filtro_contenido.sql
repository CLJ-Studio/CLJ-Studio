-- ============================================================================
-- 20 · Filtro de contenido ofensivo
-- ============================================================================
-- Va en el servidor y no en la app: la clave publica de Supabase permite
-- llamar a la API sin pasar por Flutter, asi que un filtro solo en el cliente
-- seria decorativo.
--
-- Se compara sobre el texto NORMALIZADO (sin acentos, minusculas, sin
-- caracteres repetidos ni separadores) para que no baste escribir "p-u-t-o"
-- o "puuuto" para colarse.
--
-- El listado es una tabla, no codigo: moderar no deberia exigir una
-- migracion cada vez que aparece una palabra nueva.
-- ============================================================================

create table public.terminos_bloqueados (
  termino    text primary key,
  creado_en  timestamptz not null default now()
);

alter table public.terminos_bloqueados enable row level security;
-- Sin policies: solo la funcion de validacion la consulta, y corre como
-- owner. Nadie puede leer la lista desde el cliente.

insert into public.terminos_bloqueados (termino) values
  -- Insultos y vulgaridades de uso comun en la region
  ('puta'), ('puto'), ('pendejo'), ('pendeja'), ('conchatumadre'),
  ('concha'), ('verga'), ('vergon'), ('pija'), ('pito'), ('poronga'),
  ('culiao'), ('culiado'), ('culero'), ('cabron'), ('cabrona'),
  ('mierda'), ('carajo'), ('joder'), ('coger'), ('cojer'),
  ('chinga'), ('chingar'), ('chingada'), ('cachar'),
  ('pelotudo'), ('boludo'), ('gil'), ('gilipollas'),
  ('marica'), ('maricon'), ('trolo'), ('puton'), ('zorra'),
  ('perra'), ('golfa'), ('ramera'), ('prostituta'),
  ('teta'), ('tetas'), ('culo'), ('nalgas'), ('pezon'),
  ('pene'), ('vagina'), ('vergudo'), ('semen'), ('masturba'),
  ('porno'), ('xxx'), ('sexo'), ('sexual'), ('desnudo'), ('desnuda'),
  ('nude'), ('nudes'), ('onlyfans'),
  -- Insultos en ingles
  ('fuck'), ('fucking'), ('shit'), ('bitch'), ('asshole'), ('dick'),
  ('pussy'), ('cunt'), ('whore'), ('slut'), ('nigga'), ('nigger'),
  -- Sustancias y actividades prohibidas dentro del campus
  ('cocaina'), ('marihuana'), ('marijuana'), ('cocaine'), ('weed'),
  ('lsd'), ('extasis'), ('metanfetamina'), ('crack'),
  ('droga'), ('drogas'),
  -- Discriminacion
  ('negro de mierda'), ('indio de mierda'), ('retrasado'), ('mongolico'),
  ('subnormal')
on conflict (termino) do nothing;

-- ----------------------------------------------------------------------------
-- Normaliza para que las variantes evidentes no burlen el filtro.
-- ----------------------------------------------------------------------------
create or replace function public.normalizar_para_filtro(p_texto text)
returns text
language sql
immutable
as $$
  select regexp_replace(
           regexp_replace(
             -- Sin acentos y en minusculas.
             lower(translate(coalesce(p_texto, ''),
                             'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')),
             -- Fuera separadores usados para partir palabras: p.u.t.o, p-u-t-o
             '[^a-z0-9ñ]', '', 'g'
           ),
           -- Colapsa repeticiones: puuuuto -> puto
           '(.)\1+', '\1', 'g'
         );
$$;

-- ----------------------------------------------------------------------------
-- Devuelve el termino encontrado, o null si el texto esta limpio.
-- ----------------------------------------------------------------------------
create or replace function public.termino_ofensivo(p_texto text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select t.termino
    from public.terminos_bloqueados t
   where public.normalizar_para_filtro(p_texto)
         like '%' || public.normalizar_para_filtro(t.termino) || '%'
   limit 1;
$$;

-- ----------------------------------------------------------------------------
-- Rechaza el alta o la edicion cuando el texto contiene algo ofensivo.
-- ----------------------------------------------------------------------------
create or replace function public.validar_contenido_producto()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_termino text;
begin
  v_termino := public.termino_ofensivo(
    coalesce(new.name, '') || ' ' || coalesce(new.description, '')
  );

  if v_termino is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa el texto de tu publicacion'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

create or replace function public.validar_contenido_local()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_termino text;
begin
  v_termino := public.termino_ofensivo(
    coalesce(new.name, '') || ' ' || coalesce(new.description, '')
  );

  if v_termino is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa el nombre o la descripcion'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

create trigger validar_contenido_antes_de_publicar
  before insert or update of name, description on public.products
  for each row execute function public.validar_contenido_producto();

create trigger validar_contenido_antes_de_abrir_local
  before insert or update of name, description on public.stores
  for each row execute function public.validar_contenido_local();
