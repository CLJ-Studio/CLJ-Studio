-- ============================================================================
-- 53 · El filtro en todos lados, y sin trampas
-- ============================================================================
-- Aparecio un sabor llamado "Porno" en una publicacion de galletas. El filtro
-- lo habria atrapado: el problema es que los sabores nunca pasaban por el. Al
-- revisar todo lo que escribe la gente salieron tres huecos mas, cuatro
-- trampas que el filtro no veia, y un falso positivo que seguia activo.
--
-- HUECOS (texto que llegaba a otros sin pasar por el filtro):
--   1. El nombre de cada sabor o tamano (product_variants.name).
--   2. El motivo al rechazar o cancelar un pedido, que le llega a la otra
--      persona como notificacion.
--   3. El chat. El permiso de update cubria TODAS las columnas, asi que
--      quien recibia un mensaje podia cambiar, desde la API, lo que la otra
--      persona habia escrito. No es solo un hueco del filtro: es poder
--      ponerle palabras en la boca a otro. Marcar "leido" va por una funcion
--      del servidor, asi que el permiso directo ni siquiera hacia falta.
--
-- TRAMPAS (probadas contra la base real antes de escribir esto; hoy pasan):
--   · letras de otro alfabeto que se ven iguales: la "o" rusa en "pоrnо"
--   · letras anchas o de estilo: "ｐｏｒｎｏ", "𝐩𝐨𝐫𝐧𝐨"
--   · caracteres invisibles en medio: un espacio de ancho cero, un guion
--     invisible. En pantalla se lee "porno"; para el filtro eran dos palabras
--   · letras tapadas: "p*rno", "p#rno"
--
-- FALSO POSITIVO: "Recoger en la cafeteria" estaba prohibido. La regla que
-- acepta refuerzos delante ("reputo") leia "re" + "coger". Se arregla con una
-- lista de palabras permitidas, tabla como la de bloqueadas, para que el
-- proximo caso no exija tocar codigo.
--
-- Fuera de alcance a proposito: "concha" y "coger" siguen bloqueadas, tambien
-- en "concha de mar" o "coger el micro". Estan en la lista por decision, y
-- quitarlas es otra decision.
--
-- VA EN UNA TRANSACCION y termina con pruebas. Si al aplicarla cualquier caso
-- no da lo esperado, se deshace entera y el error dice cual fallo: nada queda
-- a medio cambiar en la base de verdad.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1 · Pasos previos en el normalizador
-- ----------------------------------------------------------------------------
-- Es el mismo de la migracion 40, linea por linea. Lo unico nuevo es lo que
-- le pasa al texto ANTES de entrar, en el lugar donde antes decia solo
-- coalesce(p_texto, ''):
--
--   a. NFKC: las letras anchas, las de estilo matematico, los superindices y
--      las ligaduras pasan a su letra comun.
--   b. Fuera los caracteres invisibles y las marcas sueltas. Se BORRAN, no se
--      cambian por espacio: el que esta en medio de una palabra no la parte.
--   c. Letras griegas y cirilicas que se ven como latinas pasan a latinas.
--
-- Para texto comun (letras, acentos, numeros) los tres pasos no cambian nada,
-- y por eso lo que hoy pasa sigue pasando.
create or replace function public.normalizar_para_filtro(p_texto text)
returns text
language sql
immutable
as $$
  select
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              regexp_replace(
                regexp_replace(
                  translate(
                    lower(translate(
                      -- Pasos previos (a, b, c)
                      translate(
                        regexp_replace(
                          normalize(coalesce(p_texto, ''), NFKC),
                          '[\u00AD\u034F\u061C\u115F\u1160\u17B4\u17B5\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2064\u206A-\u206F\u3164\uFE00-\uFE0F\uFEFF\uFFA0\u0300-\u036F\u1AB0-\u1AFF\u1DC0-\u1DFF\u20D0-\u20FF\uFE20-\uFE2F]',
                          '', 'g'
                        ),
                        'авеёкмнорстухіїјѕԁԛԝһАВЕКМНОРСТХУІЈЅαβεικνορτυχΑΒΕΖΗΙΚΜΝΟΡΤΥΧ',
                        'abeekmhopctyxiijsdqwhabekmhopctxyijsabeikvoptuxabezhikmnoptyx'
                      ),
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
-- 2 · Palabras permitidas
-- ----------------------------------------------------------------------------
-- Excepciones exactas: si una palabra del texto es una de estas, no cuenta
-- para el filtro. Es para los choques entre la regla de prefijos y palabras
-- normales, no para habilitar terminos de la lista.
create table if not exists public.terminos_permitidos (
  termino   text primary key,
  creado_en timestamptz not null default now()
);

alter table public.terminos_permitidos enable row level security;
-- Sin policies, igual que terminos_bloqueados: solo la lee el filtro.

-- Las formas de "recoger" que la regla de prefijos confundia, sin acentos
-- porque el filtro los quita: recogera = recogera, recogeras = recogeras.
insert into public.terminos_permitidos (termino) values
  ('recoger'), ('recoge'), ('recoges'), ('recogen'),
  ('recoga'), ('recogas'), ('recogan'),
  ('recogera'), ('recogeras'), ('recogero')
on conflict (termino) do nothing;

-- ----------------------------------------------------------------------------
-- 3 · La comparacion de siempre, sin las palabras permitidas
-- ----------------------------------------------------------------------------
-- Cuerpo identico al de la migracion 40; lo unico nuevo es que el texto
-- normalizado pierde primero las palabras permitidas.
create or replace function public.termino_ofensivo_base(p_texto text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  with permitidas as (
    select string_agg(public.normalizar_para_filtro(p.termino), '|') as patron
      from public.terminos_permitidos p
  ),
  normalizado as (
    select case
             when pm.patron is null
               then public.normalizar_para_filtro(p_texto)
             else regexp_replace(
                    public.normalizar_para_filtro(p_texto),
                    '\m(' || pm.patron || ')\M', ' ', 'g'
                  )
           end as texto
      from permitidas pm
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

-- ----------------------------------------------------------------------------
-- 4 · termino_ofensivo: la misma firma, mas las letras tapadas
-- ----------------------------------------------------------------------------
-- Todo lo que ya llama a termino_ofensivo (productos, locales, notas de
-- pedido, biografia, nombre, reportes, chat) recibe las mejoras sin tocarlo.
--
-- "p*rno": el asterisco esta en lugar de una letra que no se sabe cual es.
-- Solo cuando hay un * o # ENTRE dos letras se prueba el texto con cada vocal
-- en ese lugar, y sin nada. Un asterisco al costado de una palabra ("*oferta*",
-- "20 Bs*") no lo activa, y "C#" tampoco: no tiene letra del otro lado.
create or replace function public.termino_ofensivo(p_texto text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    public.termino_ofensivo_base(p_texto),
    case
      when p_texto ~ '[[:alpha:]][*#]+[[:alpha:]]' then
        coalesce(
          public.termino_ofensivo_base(regexp_replace(p_texto, '[*#]', 'a', 'g')),
          public.termino_ofensivo_base(regexp_replace(p_texto, '[*#]', 'e', 'g')),
          public.termino_ofensivo_base(regexp_replace(p_texto, '[*#]', 'i', 'g')),
          public.termino_ofensivo_base(regexp_replace(p_texto, '[*#]', 'o', 'g')),
          public.termino_ofensivo_base(regexp_replace(p_texto, '[*#]', 'u', 'g')),
          public.termino_ofensivo_base(regexp_replace(p_texto, '[*#]', '', 'g'))
        )
    end
  );
$$;

-- ----------------------------------------------------------------------------
-- 5 · Hueco 1: los sabores pasan por el filtro
-- ----------------------------------------------------------------------------
create or replace function public.validar_contenido_variante()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.termino_ofensivo(new.name) is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa el nombre de las opciones'
      using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists validar_contenido_variante on public.product_variants;
create trigger validar_contenido_variante
  before insert or update of name on public.product_variants
  for each row execute function public.validar_contenido_variante();

-- Los que ya se colaron se RETIRAN (no se borran): asi los pedidos viejos
-- siguen nombrandolos, y en el catalogo dejan de poder elegirse. El trigger
-- es solo sobre el nombre, asi que esto no lo dispara.
do $$
declare
  v_retirados integer;
begin
  update public.product_variants
     set is_available = false
   where is_available
     and public.termino_ofensivo(name) is not null;
  get diagnostics v_retirados = row_count;
  raise notice 'Sabores con palabras no permitidas retirados: %', v_retirados;
end $$;

-- ----------------------------------------------------------------------------
-- 6 · Hueco 2: el motivo de rechazar o cancelar un pedido
-- ----------------------------------------------------------------------------
-- Las dos funciones son las de siempre (rechazar: migracion 3, cancelar:
-- migracion de la bandeja de chats), con el control agregado justo antes de
-- cambiar nada.
create or replace function public.rechazar_pedido(
  p_order_id uuid,
  p_motivo   text default null
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor  uuid := auth.uid();
  v_pedido public.orders%rowtype;
begin
  select * into v_pedido from public.orders where id = p_order_id for update;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_pedido.seller_id <> v_actor then
    raise exception 'SOLO_EL_VENDEDOR_PUEDE_RECHAZAR' using errcode = '42501';
  end if;
  if v_pedido.status <> 'solicitado' then
    raise exception 'ESTADO_INVALIDO' using errcode = '22023';
  end if;

  -- El motivo le llega al comprador como notificacion.
  if p_motivo is not null and public.termino_ofensivo(p_motivo) is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa el motivo'
      using errcode = '22023';
  end if;

  update public.orders
     set status = 'rechazado', resolved_at = now()
   where id = p_order_id
  returning * into v_pedido;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, 'solicitado', 'rechazado', v_pedido.buyer_id,
    'pedido_rechazado', 'Pedido rechazado',
    coalesce(p_motivo, 'El vendedor no pudo atender tu pedido.')
  );

  return v_pedido;
end;
$$;

create or replace function public.cancelar_pedido(
  p_order_id uuid,
  p_motivo   text default null
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor       uuid := auth.uid();
  v_pedido      public.orders%rowtype;
  v_previo      public.estado_pedido;
  v_otro        uuid;
  v_soy_vendedor boolean;
begin
  select * into v_pedido from public.orders where id = p_order_id for update;

  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_actor not in (v_pedido.buyer_id, v_pedido.seller_id) then
    raise exception 'NO_PARTICIPAS_EN_ESTE_PEDIDO' using errcode = '42501';
  end if;
  if v_pedido.status not in ('solicitado', 'aceptado') then
    raise exception 'ESTADO_INVALIDO: no se puede cancelar un pedido %',
      v_pedido.status using errcode = '22023';
  end if;

  -- El motivo le llega a la otra parte como notificacion.
  if p_motivo is not null and public.termino_ofensivo(p_motivo) is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa el motivo'
      using errcode = '22023';
  end if;

  v_previo       := v_pedido.status;
  v_soy_vendedor := v_actor = v_pedido.seller_id;
  v_otro := case when v_soy_vendedor then v_pedido.buyer_id
                 else v_pedido.seller_id end;

  -- Solo se devuelve stock si ya se habia descontado (es decir, si estaba
  -- aceptado). Vale igual cancele quien cancele.
  if v_previo = 'aceptado' then
    perform public.restituir_stock(p_order_id);
  end if;

  update public.orders
     set status = 'cancelado', resolved_at = now()
   where id = p_order_id
  returning * into v_pedido;

  perform public.registrar_evento_pedido(
    p_order_id, v_actor, v_previo, 'cancelado', v_otro,
    'pedido_cancelado', 'Pedido cancelado',
    coalesce(
      p_motivo,
      case when v_soy_vendedor
           then 'El vendedor cancelo el pedido.'
           else 'El comprador cancelo el pedido.' end
    )
  );

  return v_pedido;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7 · Hueco 3: nadie puede reescribir el mensaje de otro
-- ----------------------------------------------------------------------------
-- Antes: grant update en TODA la tabla, y una policy que deja tocar los
-- mensajes ajenos (para marcarlos leidos). Juntos permitian cambiar el
-- texto de lo que escribio la otra persona. Ahora solo se puede tocar la
-- marca de leido; el texto ya no se puede cambiar por ningun camino directo.
revoke update on public.mensajes_pedido from anon, authenticated;
grant update (leido_en) on public.mensajes_pedido to authenticated;

-- ----------------------------------------------------------------------------
-- 8 · Pruebas. Si alguna falla, nada de lo anterior queda aplicado.
-- ----------------------------------------------------------------------------
do $$
declare
  v_deben_caer text[] := array[
    'Porno', 'p0rn0', 'PoRnO', 'pornografia', 'P0RN0GR4F14',
    'kulo', 'berga', 'p u t o', 'p.0.r.n.0', 'petecitos', 'hdp',
    -- Trampas nuevas. Se escriben con codigos para que se vean en el
    -- archivo: varias son invisibles.
    E'p\u043Ern\u043E',                                   -- "o" rusa
    E'\uFF50\uFF4F\uFF52\uFF4E\uFF4F',                    -- letras anchas
    E'\U0001D429\U0001D428\U0001D42B\U0001D427\U0001D428', -- negrita matematica
    E'por\u200Bno',                                       -- espacio invisible
    E'pu\u00ADta',                                        -- guion invisible
    E'\u03C1\u03BFrn\u03BF',                              -- griego
    E'po\u0301rno',                                       -- acento suelto
    'p*rno', 'p#rno'
  ];
  v_deben_pasar text[] := array[
    'Recoger en la cafeteria', 'Lo recoges a las 10', 'Lo recogeras manana',
    'Puedes recogerlo en el bloque B', 'Escoger el sabor que quieras',
    'Computadora portatil', 'Libro de Calculo II', 'Articulo nuevo',
    'Pijama de algodon', 'Galletas crackers', 'Vendo peras', 'Pito de canahua',
    'Salteñas de pollo', 'Cuñape caliente', 'Majadito de charque',
    'Precio: 20 Bs*', '*Oferta* solo hoy', 'Programo en C# y Java',
    'Nota 5*5 = 25', E'Envio 1\u00BA piso', E'Libro 2\u00AA edicion',
    E'\uFF35\uFF30\uFF33\uFF21 campus', 'Ñandu de peluche', 'Chocolate', 'Almendra'
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

  raise notice 'Filtro probado: % casos que deben caer y % que deben pasar, todos bien.',
    array_length(v_deben_caer, 1), array_length(v_deben_pasar, 1);
end $$;

commit;
