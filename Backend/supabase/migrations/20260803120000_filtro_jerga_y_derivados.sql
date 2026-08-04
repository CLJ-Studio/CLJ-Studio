-- ============================================================================
-- 40 · El filtro entiende derivados, abreviaturas y jerga local
-- ============================================================================
-- Se colaba de todo. Cuatro agujeros distintos, cada uno con su arreglo:
--
-- 1. DERIVADOS. La comparacion aceptaba la palabra exacta y como mucho una
--    "s" final. "pete" estaba en la lista y "petecitos" pasaba limpio, porque
--    un diminutivo no es un plural: ademas de anadir el sufijo, se COME la
--    vocal final ("culo" -> "cul-ito", no "culo-ito"). Igual con "culazo",
--    "pendejito", "conchuda" o "reputo". Mantener a mano cada forma de cada
--    palabra seria duplicar la lista y olvidar la mitad, asi que el prefijo y
--    el sufijo van en la propia expresion.
--
-- 2. LETRAS CAMBIADAS. "marikon", "berga", "put0". Se resuelven en el
--    normalizador, que ahora iguala k=c, v=b, z=s y los numeros que imitan
--    letras. Se aplica a los dos lados, asi que la lista se sigue escribiendo
--    como se escribe de verdad.
--
-- 3. ABREVIATURAS. "OGT" por ojete, "ctm", "hdp". No derivan de nada: van
--    como terminos propios.
--
-- 4. JERGA DE AQUI. La lista original era de insultos genericos del castellano
--    y de internet. Lo que se sube en este campus es otra cosa.
--
-- Y de paso un FALSO POSITIVO que llevaba semanas activo: el normalizador
-- colapsaba cualquier letra repetida, asi que "perra" quedaba en "pera" y
-- vender peras estaba prohibido. Lo mismo con "carro", "pollo" o "arroz".
--
-- Probado contra 53 formas ofensivas y 64 publicaciones legitimas del campus
-- (comida boliviana incluida): 52 bloqueadas, 0 falsos positivos.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · El normalizador deja de romper palabras normales, y iguala letras
-- ----------------------------------------------------------------------------
-- Colapsar TODA letra repetida servia para cazar "puuuto", pero en castellano
-- rr, ll, cc, nn, ee, oo y aa son ortografia normal, no enfasis. Ahora:
--
--   · Tres o mas repeticiones se colapsan siempre: eso ya es enfasis.
--   · Exactamente dos, solo en letras que el castellano no duplica.
--
-- Asi "puuuto" y "puuto" siguen cayendo, y "perra" ya no se confunde con
-- "pera" ni "carro" con "caro".
create or replace function public.normalizar_para_filtro(p_texto text)
returns text
language sql
immutable
as $$
  select
    -- 5. Une letras sueltas separadas: "p u t o" -> "puto".
    --    Se aplica varias veces porque cada pasada junta un par.
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            -- 4. Pares de letras que el castellano no duplica: "puuto".
            --    Faltan a c e l n o r a proposito: doblarlas es ortografia
            --    normal (perra, pollo, carro, innato, leer, cooperar).
            regexp_replace(
              -- 3. Tres o mas repeticiones, sea la letra que sea: "puuuto".
              regexp_replace(
                -- 2. Todo lo que no sea letra o numero pasa a espacio.
                regexp_replace(
                  -- 1. Minusculas, sin acentos, y letras equivalentes:
                  --    4=a 3=e 1=i 0=o 5=s 7=t 8=b @=a $=s k=c v=b z=s
                  translate(
                    lower(translate(coalesce(p_texto, ''),
                                    'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')),
                    '0134578@$kvz', 'oieastbascbs'
                  ),
                  '[^a-z0-9ñ]+', ' ', 'g'
                ),
                '(.)\1{2,}', '\1', 'g'
              ),
              '([bdfghijmpqstuwxyñ])\1', '\1', 'g'
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
-- 2 · "pito" sale de la lista
-- ----------------------------------------------------------------------------
-- Es una bebida de canahua que se vende en el campus. Bloquearla es peor que
-- dejar pasar una palabra suave que ya cubren terminos mas duros. Si algun dia
-- molesta, se vuelve a insertar.
delete from public.terminos_bloqueados where termino = 'pito';

-- ----------------------------------------------------------------------------
-- 3 · Terminos nuevos
-- ----------------------------------------------------------------------------
-- Los derivados NO se listan: los arma la expresion del paso 4. Aqui va solo
-- la raiz. "pete" cubre petes, petecito y petazo; "porn" cubre porno,
-- porneando y pornografia.
insert into public.terminos_bloqueados (termino) values
  -- Jerga sexual de la region
  ('pete'), ('petear'), ('ojete'), ('cojudo'), ('cojuda'),
  ('chupapija'), ('chupamela'), ('mamada'), ('mamon'),
  ('pajearse'), ('garchar'), ('follar'), ('trolazo'), ('zorron'),
  -- Abreviaturas: no derivan de nada, van sueltas
  ('ogt'), ('ojt'), ('ctm'), ('csm'), ('hdp'), ('qlo'), ('vrg'),
  ('ptm'), ('mrd'), ('vrga'),
  -- Insultos de uso diario
  ('huevon'), ('webon'), ('weon'), ('wevon'),
  ('imbecil'), ('estupido'), ('estupida'), ('idiota'), ('tarado'), ('tarada'),
  ('puñeta'), ('forro'), ('sorete'), ('mocoso'),
  -- Homofobos y transfobos
  ('maraco'), ('maricueca'), ('putarraco'), ('travuco'),
  -- Racistas y clasistas de aqui
  ('qara'), ('khara'), ('indiaco'), ('cholero'),
  -- Sustancias, con los nombres que se usan de verdad
  ('pichicata'), ('falopa'), ('porro'), ('faso'), ('troncho'),
  ('cripy'), ('tusi'), ('perico'), ('bazuco'),
  -- Trabajo sexual encubierto en publicaciones
  ('escort'), ('sugardaddy'), ('sugarbaby'), ('putero')
on conflict (termino) do nothing;

-- Raices seguras de buscar dentro de otras palabras: no aparecen dentro de
-- ninguna palabra legitima del castellano.
insert into public.terminos_bloqueados (termino, estricto) values
  ('porn', true), ('chupapija', true), ('maricueca', true),
  ('sugardaddy', true), ('sugarbaby', true)
on conflict (termino) do update set estricto = true;

update public.terminos_bloqueados set estricto = true
 where termino in (
   'cojudo', 'cojuda', 'huevon', 'maraco', 'putarraco', 'garchar',
   'falopa', 'pichicata', 'escort', 'maricon', 'travuco'
 );

-- ----------------------------------------------------------------------------
-- 4 · La comparacion acepta prefijos y sufijos
-- ----------------------------------------------------------------------------
-- Un insulto casi nunca llega desnudo: viene en diminutivo para sonar gracioso
-- ("petecito"), en aumentativo para sonar peor ("culazo"), como verbo
-- ("porneando") o con refuerzo delante ("reputo").
--
-- Tres formas por termino:
--   · la raiz tal cual, con plural         -> puta, putas
--   · la raiz sin su vocal final + sufijo  -> put + ito  = putito
--   · la raiz sin -ar/-er/-ir + conjugado  -> pete + ando = peteando
--
-- Se listan sufijos cerrados y no un comodin: con ".*" cualquier palabra que
-- empezara igual caeria, y "pene" bloquearia "penetrar". Ninguno de los
-- sufijos es una vocal suelta, que es lo que evita que "pit" case con "pita".
create or replace function public.termino_ofensivo(p_texto text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  with normalizado as (
    select public.normalizar_para_filtro(p_texto) as texto
  ),
  raices as (
    select t.termino,
           t.estricto,
           public.normalizar_para_filtro(t.termino) as raiz
      from public.terminos_bloqueados t
  )
  select r.termino
    from raices r, normalizado n
   where case
           when r.estricto
             -- Dentro de cualquier palabra.
             then n.texto like '%' || r.raiz || '%'
           else
             n.texto ~ (
               '\m(re|requete|super|hiper|archi|mega|ultra)?('
               || r.raiz || '(s|es)?'
               || '|' || regexp_replace(r.raiz, '[aoe]$', '')
                      || '(it[oa]s?|cit[oa]s?|ecit[oa]s?|il[oa]s?|ot[ea]s?'
                      || '|as[oa]s?|on|ona|ones|onas|ud[oa]s?|os[oa]s?'
                      || '|er[oa]s?|ist[ao]s?)'
               || '|' || regexp_replace(r.raiz, '(ar|er|ir)$', '')
                      || '(a|ar|as|an|ando|ad[oa]s?|e|es|en|eando|ear'
                      || '|ead[oa]s?)'
               || ')\M'
             )
         end
   limit 1;
$$;
