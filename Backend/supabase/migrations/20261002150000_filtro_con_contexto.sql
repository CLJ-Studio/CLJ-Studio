-- ============================================================================
-- 54 · Las palabras de doble sentido dependen del contexto
-- ============================================================================
-- "Concha de mar decorativa" y "coger el micro" estaban prohibidas, igual que
-- "tocarte la concha". Son la misma palabra con usos opuestos, y la lista solo
-- sabia decir si o no a la palabra entera.
--
-- Ahora un termino puede marcarse como AMBIGUO. Cada vez que aparece se mira
-- lo que tiene alrededor (hasta tres palabras a cada lado):
--
--   1. Si va dirigido a una persona, cae: pronombre pegado ("cogerte"),
--      posesivo ("tu concha"), "de tu madre", "te voy a coger", o un verbo de
--      contacto cerca ("tocarte", "chuparla").
--   2. Si es un derivado despectivo o reforzado, cae: "conchudo", "reconcha".
--      Ya no es la palabra de doble sentido: es el insulto.
--   3. Si hay una palabra inocente cerca, pasa: "mar", "decorativa", "micro".
--      Las palabras inocentes de cada termino viven en una tabla: cuando
--      aparezca un uso inocente que siga bloqueado, se agrega ahi, sin tocar
--      codigo.
--   4. Si no hay ni una cosa ni la otra, cae. Ante la duda, como hasta ahora:
--      "vendo concha" sin mas sigue bloqueado.
--
-- Esto es una regla, no comprension de lectura. Atrapa los usos ofensivos
-- comunes y deja pasar los inocentes comunes, pero alguien que se lo proponga
-- puede encontrar una frase que la engane en un sentido o en el otro.
--
-- Y de paso, una fuga que tenia el filtro con TODOS los verbos de la lista: con
-- el pronombre pegado no reconocia la palabra. "Quiero cogerte", "follarte" o
-- "petearte" pasaban limpios. Ahora el verbo se reconoce con sus pronombres.
--
-- Como el pronombre pegado tambien alcanza a "recogerlo", la excepcion de
-- "recoger" pasa a ser un prefijo: cubre cualquier palabra que empiece con
-- "recog" (recogerlo, recogedor, recogimos...).
--
-- Probado sobre un Postgres 17 local armado con las mismas migraciones que la
-- base real, y calibrado contra ella: 0 diferencias en 1.639 textos antes de
-- cambiar nada. Va en una transaccion que termina con pruebas.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1 · Terminos ambiguos y sus contextos inocentes
-- ----------------------------------------------------------------------------
alter table public.terminos_bloqueados
  add column if not exists ambiguo boolean not null default false;

update public.terminos_bloqueados
   set ambiguo = true
 where termino in ('concha', 'coger', 'cojer');

create table if not exists public.contextos_inocentes (
  termino   text not null
            references public.terminos_bloqueados (termino) on delete cascade,
  contexto  text not null,
  creado_en timestamptz not null default now(),
  primary key (termino, contexto)
);

alter table public.contextos_inocentes enable row level security;
-- Sin policies, igual que las otras dos listas: solo las lee el filtro.

-- Una sola palabra por fila; se busca a tres palabras o menos del termino.
-- "de mar" no hace falta: alcanza con "mar".
insert into public.contextos_inocentes (termino, contexto)
select t.termino, c.contexto
  from (values ('concha'), ('coger'), ('cojer')) as t (termino),
       lateral (
         select unnest(case t.termino
           when 'concha' then array[
             -- La del mar y la de adorno
             'mar', 'marina', 'marino', 'marinas', 'marinos', 'playa',
             'nacar', 'caracol', 'caracola', 'molusco', 'moluscos', 'ostra',
             'almeja', 'abanico', 'acuario', 'pecera', 'arena',
             'decorativa', 'decorativas', 'decorativo', 'decorativos',
             'decoracion', 'adorno', 'adornos', 'artesania', 'artesanal',
             'manualidad', 'manualidades', 'collar', 'pulsera', 'aretes',
             'souvenir', 'recuerdo',
             -- El pan dulce
             'pan', 'panes', 'dulce', 'dulces', 'panaderia', 'vainilla',
             'chocolate'
           ]
           else array[
             -- Tomar un transporte
             'micro', 'micros', 'bus', 'buses', 'trufi', 'trufis', 'minibus',
             'colectivo', 'taxi', 'linea', 'transporte', 'flota', 'avion',
             'vuelo', 'tren', 'ruta', 'camino',
             -- Tomar un lugar o un turno
             'sitio', 'lugar', 'asiento', 'fila', 'turno', 'ficha', 'numero',
             'cupo',
             -- Agarrar una enfermedad o una costumbre
             'frio', 'gripe', 'resfrio', 'fuerza', 'fuerzas', 'aire', 'ritmo',
             'practica', 'experiencia', 'confianza', 'impulso',
             -- Agarrar algo: "cogelo con cuidado"
             'cuidado',
             -- Inscribirse
             'materia', 'materias', 'clase', 'clases', 'curso', 'cursos'
           ]
         end) as contexto
       ) as c
on conflict (termino, contexto) do nothing;

-- ----------------------------------------------------------------------------
-- 2 · Excepciones por prefijo
-- ----------------------------------------------------------------------------
alter table public.terminos_permitidos
  add column if not exists prefijo boolean not null default false;

insert into public.terminos_permitidos (termino, prefijo)
values ('recog', true)
on conflict (termino) do update set prefijo = true;

-- ----------------------------------------------------------------------------
-- 3 · Las formas de un termino, en una sola funcion
-- ----------------------------------------------------------------------------
-- Es la expresion que la migracion 40 armaba dentro de la comparacion, sacada
-- a una funcion para poder usarla tambien al mirar el contexto. Lo unico
-- nuevo es la ultima alternativa: el verbo con el pronombre pegado.
create or replace function public.patron_termino(p_raiz text)
returns text
language sql
immutable
as $$
  select '(re|requete|super|hiper|archi|mega|ultra)?('
      || p_raiz || '(s|es)?'
      || '|' || regexp_replace(p_raiz, '[aoe]$', '')
             || '(it[oa]s?|cit[oa]s?|ecit[oa]s?|il[oa]s?|ot[ea]s?'
             || '|as[oa]s?|on|ona|ones|onas|ud[oa]s?|os[oa]s?'
             || '|er[oa]s?|ist[ao]s?)'
      || '|' || regexp_replace(p_raiz, '(ar|er|ir)$', '')
             || '(a|ar|as|an|ando|ad[oa]s?|e|es|en|eando|ear'
             || '|ead[oa]s?)'
      -- NUEVO: cogerte, follarla, petearte, cogersela.
      || '|' || regexp_replace(p_raiz, '(ar|er|ir)$', '')
             || '(ar|er|ir|a|e|ando|iendo|eando)'
             || '(te|me|nos|la|las|lo|los|sela|selo|selas|selos'
             || '|tela|telo|mela|melo)'
      || ')';
$$;

-- ----------------------------------------------------------------------------
-- 4 · ¿Este uso de una palabra ambigua es ofensivo?
-- ----------------------------------------------------------------------------
-- Recibe el texto ya normalizado. Devuelve verdadero si ALGUNA aparicion del
-- termino no queda limpia: basta una para bloquear.
create or replace function public.uso_ofensivo(
  p_texto   text,
  p_termino text,
  p_raiz    text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with palabras as (
    select p.palabra, p.i
      from regexp_split_to_table(p_texto, ' ') with ordinality as p (palabra, i)
  ),
  forma as (
    select public.patron_termino(p_raiz) as patron,
           -- Las formas "comunes", las que pueden ser inocentes: la palabra,
           -- su plural, sus diminutivos ("conchitas") y, si es verbo, sus
           -- conjugaciones, tambien con pronombre de COSA ("cogerlo").
           '^(' || p_raiz || '(s|es)?'
             || '|' || regexp_replace(p_raiz, '[aoe]$', '')
                    || '(it[oa]s?|cit[oa]s?|ecit[oa]s?)'
             || '|' || regexp_replace(p_raiz, '(ar|er|ir)$', '')
                    || '(a|ar|as|an|ando|e|es|en|er|ir|iendo)(la|las|lo|los)?'
             || ')$' as comun,
           p_raiz ~ '(ar|er|ir)$' as es_verbo
  ),
  apariciones as (
    select w.i, w.palabra
      from palabras w, forma f
     where w.palabra ~ ('^' || f.patron || '$')
  )
  select exists (
    select 1
      from apariciones a, forma f
     where
       -- Derivado despectivo, refuerzo, o pronombre de persona pegado.
       a.palabra !~ f.comun
       -- Un verbo de contacto con pronombre cerca: "tocarte la concha".
       or exists (
         select 1 from palabras v
          where v.i between a.i - 3 and a.i + 3 and v.i <> a.i
            and v.palabra ~ ('^(toc|chup|lam|met|mam|frot|sob|bes|com|agarr'
                             || '|abr|mostr|ensen)[a-z]*'
                             || '(te|me|la|lo|las|los|tela|telo|mela|melo'
                             || '|sela|selo)$')
       )
       -- "tu concha", "su concha".
       or exists (
         select 1 from palabras v
          where v.i = a.i - 1 and v.palabra in ('tu', 'tus', 'su', 'sus')
       )
       -- "la concha de tu madre".
       or exists (
         select 1 from palabras v1
           join palabras v2 on v2.i = v1.i + 1
          where v1.i = a.i + 1 and v1.palabra = 'de'
            and v2.palabra in ('tu', 'tus', 'su', 'sus')
       )
       -- "te voy a coger": el verbo con "te" poco antes.
       or (f.es_verbo and exists (
         select 1 from palabras v
          where v.i between a.i - 3 and a.i - 1 and v.palabra = 'te'
       ))
       -- Y sin nada inocente cerca, ante la duda no pasa.
       or not exists (
         select 1
           from palabras v, public.contextos_inocentes ci
          where ci.termino = p_termino
            and v.i between a.i - 3 and a.i + 3 and v.i <> a.i
            and v.palabra = public.normalizar_para_filtro(ci.contexto)
       )
  );
$$;

-- ----------------------------------------------------------------------------
-- 5 · La comparacion, con prefijos permitidos y terminos ambiguos
-- ----------------------------------------------------------------------------
create or replace function public.termino_ofensivo_base(p_texto text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  with permitidas as (
    select string_agg(
             public.normalizar_para_filtro(p.termino)
               || case when p.prefijo then '[a-z0-9ñ]*' else '' end,
             '|'
           ) as patron
      from public.terminos_permitidos p
  ),
  normalizado as (
    -- Al quitar una palabra permitida queda un hueco: se cierra, porque
    -- mirar el contexto cuenta palabras y un hueco contaria como una.
    select btrim(regexp_replace(
             case
               when pm.patron is null
                 then public.normalizar_para_filtro(p_texto)
               else regexp_replace(
                      public.normalizar_para_filtro(p_texto),
                      '\m(' || pm.patron || ')\M', ' ', 'g'
                    )
             end,
             ' {2,}', ' ', 'g'
           )) as texto
      from permitidas pm
  ),
  raices as (
    select t.termino,
           t.estricto,
           t.ambiguo,
           public.normalizar_para_filtro(t.termino) as raiz
      from public.terminos_bloqueados t
  ),
  coincidencias as (
    select r.*
      from raices r, normalizado n
     where case
             when r.estricto
               then n.texto like '%' || r.raiz || '%'
             else n.texto ~ ('\m' || public.patron_termino(r.raiz) || '\M')
           end
  )
  select c.termino
    from coincidencias c, normalizado n
   where not c.ambiguo
      or public.uso_ofensivo(n.texto, c.termino, c.raiz)
   order by c.ambiguo
   limit 1;
$$;

-- termino_ofensivo (la que llaman todos) no cambia: sigue envolviendo a esta.

-- ----------------------------------------------------------------------------
-- 6 · Pruebas. Si alguna falla, nada de lo anterior queda aplicado.
-- ----------------------------------------------------------------------------
do $$
declare
  v_deben_caer text[] := array[
    -- Los ejemplos que se pidieron
    'cogerte el culo', 'tocarte la concha',
    -- Dirigido a alguien, aunque haya una palabra inocente cerca
    'tocarte la concha de mar', 'la concha de tu madre', 'tu concha',
    'te voy a coger', 'te quiero coger', 'quiero cogerte', 'cogeme',
    -- Derivados y refuerzos
    'conchudo', 'conchuda', 'reconcha',
    -- Sin contexto: ante la duda, como antes
    'vendo concha', 'quiero coger', 'cogerla toda',
    -- La fuga de los pronombres pegados, en cualquier verbo de la lista
    'quiero follarte', 'petearte', 'joderte', 'chingarte',
    -- Lo de antes sigue cayendo
    'Porno', 'p0rn0', 'kulo', 'berga', 'p u t o', 'petecitos', 'hdp',
    'p*rno', 'conchatumadre'
  ];
  v_deben_pasar text[] := array[
    -- Los ejemplos que se pidieron
    'concha decorativa', 'concha de mar', 'coger el micro',
    -- Mas usos inocentes
    'Conchas de mar decorativas', 'Collar de conchitas marinas',
    'Concha de nacar para manualidades', 'Pan concha de vainilla',
    'Hay que coger el trufi en la puerta', 'Coger una materia de verano',
    'Cuidado, vas a coger frio',
    -- Recoger, con y sin pronombre
    'Recoger en la cafeteria', 'Lo recoges a las 10', 'Lo recogeras manana',
    'Puedes recogerlo en el bloque B', 'Recogedor de basura',
    'Escoger el sabor que quieras',
    -- Lo que ya pasaba sigue pasando
    'Computadora portatil', 'Libro de Calculo II', 'Articulo nuevo',
    'Pijama de algodon', 'Galletas crackers', 'Vendo peras', 'Pito de canahua',
    'Salteñas de pollo', 'Majadito de charque', 'Chocolate', 'Almendra',
    'Precio: 20 Bs*', 'Programo en C# y Java', 'Te vendo mi calculadora',
    'Cogelo con cuidado'
  ];
  v_texto  text;
  v_fallos text := '';
begin
  foreach v_texto in array v_deben_caer loop
    if public.termino_ofensivo(v_texto) is null then
      v_fallos := v_fallos || format(E'\n  deberia caer y pasa: %L', v_texto);
    end if;
  end loop;

  foreach v_texto in array v_deben_pasar loop
    if public.termino_ofensivo(v_texto) is not null then
      v_fallos := v_fallos || format(E'\n  deberia pasar y cae: %L (por %L)',
                                     v_texto, public.termino_ofensivo(v_texto));
    end if;
  end loop;

  if v_fallos <> '' then
    raise exception 'El filtro no quedo como se esperaba; no se aplico nada:%',
      v_fallos;
  end if;

  raise notice 'Filtro con contexto probado: % deben caer y % deben pasar, todos bien.',
    array_length(v_deben_caer, 1), array_length(v_deben_pasar, 1);
end $$;

commit;
