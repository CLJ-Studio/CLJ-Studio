-- ============================================================================
-- 21 · Filtro de contenido sin falsos positivos
-- ============================================================================
-- El filtro anterior comparaba por subcadena y bloqueaba "Clases de calculo"
-- porque "calculo" contiene "culo". Bloquear publicaciones legitimas es peor
-- que dejar pasar una grosería: el vendedor no entiende por que lo rechazan.
--
-- Ahora hay dos modos por termino:
--
--   palabra completa (por defecto) -> "culo" bloquea "que culo" pero no
--   "calculo"; "puta" no bloquea "diputado".
--
--   estricto -> se busca tambien dentro de otras palabras. Reservado a
--   terminos que no aparecen dentro de palabras legitimas ("marihuana",
--   "conchatumadre", "gilipollas").
--
-- Contra las evasiones se normaliza el texto: sin acentos, sin repeticiones
-- y uniendo letras separadas, de modo que "p.u.t.o" y "puuuto" se detectan.
-- ============================================================================

alter table public.terminos_bloqueados
  add column estricto boolean not null default false;

-- Terminos largos e inequivocos: seguros de buscar dentro de otras palabras.
update public.terminos_bloqueados set estricto = true
 where termino in (
   'conchatumadre','gilipollas','pendejo','pendeja','maricon','marihuana',
   'marijuana','cocaina','cocaine','metanfetamina','prostituta','masturba',
   'onlyfans','culiao','culiado','pelotudo','boludo','chingar','chingada',
   'nigger','nigga','asshole','bitch','fucking','whore','mongolico',
   'subnormal','retrasado','extasis','vergudo','poronga','desnudo','desnuda',
   'negro de mierda','indio de mierda'
 );

-- ----------------------------------------------------------------------------
-- Normaliza conservando la separacion en palabras.
-- ----------------------------------------------------------------------------
create or replace function public.normalizar_para_filtro(p_texto text)
returns text
language sql
immutable
as $$
  select
    -- 3. Une letras sueltas separadas: "p u t o" -> "puto".
    --    Se aplica varias veces porque cada pasada junta un par.
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            -- 2. Colapsa repeticiones: "puuuto" -> "puto".
            regexp_replace(
              -- 1. Sin acentos, en minusculas, separadores a espacio.
              regexp_replace(
                lower(translate(coalesce(p_texto, ''),
                                'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')),
                '[^a-z0-9ñ]+', ' ', 'g'
              ),
              '(.)\1+', '\1', 'g'
            ),
            '(\m[a-z0-9ñ]) +(?=[a-z0-9ñ]\M)', '\1', 'g'
          ),
          '(\m[a-z0-9ñ]) +(?=[a-z0-9ñ]\M)', '\1', 'g'
        ),
        '(\m[a-z0-9ñ]) +(?=[a-z0-9ñ]\M)', '\1', 'g'
      ),
      '^ | $', '', 'g'
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
  with normalizado as (
    select public.normalizar_para_filtro(p_texto) as texto
  )
  select t.termino
    from public.terminos_bloqueados t, normalizado n
   where case
           when t.estricto
             -- Dentro de cualquier palabra.
             then n.texto like '%' || public.normalizar_para_filtro(t.termino) || '%'
           else
             -- Solo como palabra completa: \m y \M son los limites de
             -- palabra de Postgres.
             n.texto ~ ('\m' || public.normalizar_para_filtro(t.termino) || '\M')
         end
   limit 1;
$$;
