-- ============================================================================
-- 59 · Poker entre todos
-- ============================================================================
-- Texas Hold'em de 2 a 6 por mesa, por turnos y con fichas de mentira: nunca
-- dinero. A diferencia del blackjack y la ruleta, que corren enteros en el
-- telefono, el poker necesita un arbitro que no sea ningun jugador. Aqui el
-- servidor baraja, reparte, valida cada jugada y paga: si lo hiciera un
-- telefono, ese telefono podria ver las cartas de todos.
--
--   · Mazo: se baraja con gen_random_uuid() (azar criptografico) y vive en
--     poker_mazos, una tabla que nadie puede leer.
--   · Cartas propias: en poker_cartas; cada uno lee solo las suyas. Si la
--     mano llega a mostrarse, se copian a la vista de todos.
--   · Jugadas: poker_jugar() valida turno, monto y fichas, y avanza la mano.
--     Todo con la sala bloqueada: dos jugadas no se pisan.
--   · Reloj: cada turno vence. Si nadie juega, poker_vencer_turno() pasa o
--     retira al que no jugo; lo llama cualquiera que vea el reloj vencido, y
--     pg_cron cada minuto por si no queda nadie mirando. Dos turnos vencidos
--     seguidos y queda "sentado afuera" hasta que vuelva.
--   · Fichas: cada mesa da las mismas a todos al sentarse. No son las del
--     casino del telefono: esas viven en el telefono y no son de fiar para
--     una mesa compartida. Quien se queda sin fichas recarga entre manos.
--   · Botes aparte cuando alguien va con todo con menos fichas.
--
-- Termina con pruebas dentro de la misma transaccion: si algo no da lo
-- esperado, no se aplica nada.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1 · Las tablas
-- ----------------------------------------------------------------------------
create table public.poker_salas (
  id               uuid primary key default gen_random_uuid(),
  nombre           text not null,
  creador_id       uuid not null references public.profiles(id) on delete cascade,
  ciega_chica      integer not null,
  ciega_grande     integer not null,
  fichas_iniciales integer not null,
  segundos_turno   integer not null default 30,
  creada_en        timestamptz not null default now(),
  actividad_en     timestamptz not null default now(),
  constraint poker_salas_nombre check (length(trim(nombre)) between 3 and 30),
  constraint poker_salas_ciegas
    check (ciega_chica > 0 and ciega_grande = ciega_chica * 2),
  constraint poker_salas_fichas check (fichas_iniciales >= ciega_grande * 20),
  constraint poker_salas_turno check (segundos_turno between 10 and 120)
);

create table public.poker_asientos (
  sala_id    uuid not null references public.poker_salas(id) on delete cascade,
  posicion   smallint not null,
  usuario_id uuid not null references public.profiles(id) on delete cascade,
  fichas     integer not null,
  -- Sentado afuera: no entra en las manos hasta que vuelva.
  afuera     boolean not null default false,
  -- Turnos vencidos seguidos.
  vencidos   smallint not null default 0,
  sentado_en timestamptz not null default now(),
  primary key (sala_id, posicion),
  constraint poker_asientos_posicion check (posicion between 0 and 5),
  constraint poker_asientos_fichas check (fichas >= 0)
);

-- Una mesa a la vez por persona.
create unique index poker_asientos_una_mesa on public.poker_asientos (usuario_id);

create table public.poker_manos (
  id            uuid primary key default gen_random_uuid(),
  sala_id       uuid not null references public.poker_salas(id) on delete cascade,
  numero        integer not null,
  boton         smallint not null,
  fase          text not null default 'preflop',
  comunitarias  text[] not null default '{}',
  -- A quien le toca, y hasta cuando.
  turno         smallint,
  vence_en      timestamptz,
  -- La apuesta mas alta de la ronda, y cuanto tiene que crecer una subida.
  apuesta       integer not null default 0,
  subida_minima integer not null,
  -- Todo lo que hay en el centro.
  bote          integer not null default 0,
  -- Al terminar: [{posicion, monto}] de quienes cobraron.
  resultado     jsonb,
  creada_en     timestamptz not null default now(),
  terminada_en  timestamptz,
  constraint poker_manos_fase
    check (fase in ('preflop', 'flop', 'turn', 'river', 'terminada'))
);

create index poker_manos_por_sala on public.poker_manos (sala_id, numero desc);

-- Una sola mano en juego por mesa.
create unique index poker_manos_una_en_juego
  on public.poker_manos (sala_id) where fase <> 'terminada';

-- Lo que queda del mazo, en orden. Nadie lo puede leer: no tiene politicas.
create table public.poker_mazos (
  mano_id uuid primary key references public.poker_manos(id) on delete cascade,
  cartas  text[] not null
);

-- Quienes juegan cada mano, y lo que se ve de cada uno.
create table public.poker_jugadores (
  mano_id       uuid not null references public.poker_manos(id) on delete cascade,
  sala_id       uuid not null references public.poker_salas(id) on delete cascade,
  posicion      smallint not null,
  usuario_id    uuid not null references public.profiles(id) on delete cascade,
  apuesta_ronda integer not null default 0,
  aportado      integer not null default 0,
  retirado      boolean not null default false,
  -- Fue con todo: ya no apuesta mas en esta mano.
  todo          boolean not null default false,
  -- Ya decidio en esta ronda (una subida completa lo vuelve a false).
  actuo         boolean not null default false,
  ultima_accion text,
  -- Sus cartas y su mejor mano, solo si la mano llega a mostrarse.
  cartas_vistas text[],
  valor         bigint,
  primary key (mano_id, posicion)
);

-- Las cartas de cada uno. Cada quien lee solo las suyas.
create table public.poker_cartas (
  mano_id    uuid not null references public.poker_manos(id) on delete cascade,
  usuario_id uuid not null references public.profiles(id) on delete cascade,
  cartas     text[] not null,
  primary key (mano_id, usuario_id)
);

-- Lo que paso en cada mano, en orden.
create table public.poker_acciones (
  id        bigserial primary key,
  mano_id   uuid not null references public.poker_manos(id) on delete cascade,
  sala_id   uuid not null references public.poker_salas(id) on delete cascade,
  posicion  smallint,
  accion    text not null,
  monto     integer not null default 0,
  creada_en timestamptz not null default now()
);

create index poker_acciones_por_mano on public.poker_acciones (mano_id, id);

-- ----------------------------------------------------------------------------
-- 2 · Quien ve que
-- ----------------------------------------------------------------------------
alter table public.poker_salas     enable row level security;
alter table public.poker_asientos  enable row level security;
alter table public.poker_manos     enable row level security;
alter table public.poker_mazos     enable row level security;
alter table public.poker_jugadores enable row level security;
alter table public.poker_cartas    enable row level security;
alter table public.poker_acciones  enable row level security;

create policy poker_salas_lectura on public.poker_salas
  for select to authenticated using (true);
create policy poker_asientos_lectura on public.poker_asientos
  for select to authenticated using (true);
create policy poker_manos_lectura on public.poker_manos
  for select to authenticated using (true);
create policy poker_jugadores_lectura on public.poker_jugadores
  for select to authenticated using (true);
create policy poker_acciones_lectura on public.poker_acciones
  for select to authenticated using (true);
create policy poker_cartas_propias on public.poker_cartas
  for select to authenticated using (usuario_id = auth.uid());

-- Nadie escribe directo: todo pasa por las funciones de abajo.
revoke all on public.poker_salas, public.poker_asientos, public.poker_manos,
  public.poker_mazos, public.poker_jugadores, public.poker_cartas,
  public.poker_acciones from anon, authenticated;
grant select on public.poker_salas, public.poker_asientos, public.poker_manos,
  public.poker_jugadores, public.poker_cartas, public.poker_acciones
  to authenticated;

-- En vivo: la app se entera al instante de cada jugada.
alter table public.poker_salas    replica identity full;
alter table public.poker_asientos replica identity full;
alter table public.poker_manos    replica identity full;
alter publication supabase_realtime add table public.poker_salas;
alter publication supabase_realtime add table public.poker_asientos;
alter publication supabase_realtime add table public.poker_manos;

-- ----------------------------------------------------------------------------
-- 3 · Las cartas: barajar y valorar una mano
-- ----------------------------------------------------------------------------
-- Una carta es rango + palo: 'As' es el as de picas, 'Td' el diez de
-- diamantes. Palos: s picas, h corazones, d diamantes, c treboles.
create or replace function public.poker_rango(p_carta text)
returns integer
language sql
immutable
as $$
  select position(left(p_carta, 1) in '23456789TJQKA') + 1;
$$;

-- Un numero al azar en [0, p_hasta), de los bits aleatorios de un uuid v4
-- (los primeros 12 hexadecimales: ni la version ni la variante).
create or replace function public.poker_azar(p_hasta integer)
returns integer
language sql
volatile
as $$
  select ((('x' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))
             ::bit(48)::bigint) % p_hasta)::integer;
$$;

-- Las 52, mezcladas con Fisher-Yates.
create or replace function public.poker_barajar()
returns text[]
language plpgsql
volatile
as $$
declare
  v_mazo  text[] := '{}';
  v_palo  text;
  v_rango text;
  v_carta text;
  i       integer;
  j       integer;
begin
  foreach v_palo in array array['s', 'h', 'd', 'c'] loop
    foreach v_rango in array string_to_array('2,3,4,5,6,7,8,9,T,J,Q,K,A', ',') loop
      v_mazo := v_mazo || (v_rango || v_palo);
    end loop;
  end loop;

  for i in reverse 52..2 loop
    j := public.poker_azar(i) + 1;
    v_carta := v_mazo[i];
    v_mazo[i] := v_mazo[j];
    v_mazo[j] := v_carta;
  end loop;

  return v_mazo;
end;
$$;

-- El valor de cinco cartas, como un numero: mas alto, mejor mano. La
-- categoria va arriba (8 escalera de color ... 0 carta alta) y debajo, en
-- cinco grupos de 4 bits, los rangos que desempatan. La app calcula lo mismo
-- (evaluador_poker.dart) para nombrar las manos.
create or replace function public.poker_valor_cinco(p_cartas text[])
returns bigint
language plpgsql
immutable
as $$
declare
  v_rangos    integer[];
  v_orden     integer[] := '{}';
  v_patron    text := '';
  v_grupo     record;
  v_color     boolean;
  v_alta      integer := 0;
  v_categoria integer;
  v_valor     bigint;
  i           integer;
begin
  select array_agg(public.poker_rango(c) order by public.poker_rango(c) desc)
    into v_rangos
    from unnest(p_cartas) c;

  select count(distinct right(c, 1)) = 1 into v_color from unnest(p_cartas) c;

  -- Los rangos agrupados: primero los que mas se repiten, y entre ellos los
  -- mas altos. Eso ya es el orden en que desempatan.
  for v_grupo in
    select r, count(*) as n
      from unnest(v_rangos) r
     group by r
     order by count(*) desc, r desc
  loop
    v_orden := v_orden || v_grupo.r;
    v_patron := v_patron || v_grupo.n;
  end loop;

  -- Escalera: cinco distintos seguidos, o A-2-3-4-5 (que vale como al 5).
  if v_patron = '11111' then
    if v_rangos[1] - v_rangos[5] = 4 then
      v_alta := v_rangos[1];
    elsif v_rangos = array[14, 5, 4, 3, 2] then
      v_alta := 5;
    end if;
  end if;

  v_categoria := case
    when v_alta > 0 and v_color then 8
    when v_patron = '41' then 7
    when v_patron = '32' then 6
    when v_color then 5
    when v_alta > 0 then 4
    when v_patron = '311' then 3
    when v_patron = '221' then 2
    when v_patron = '2111' then 1
    else 0
  end;

  if v_alta > 0 then
    v_orden := array[v_alta];
  end if;

  v_valor := v_categoria;
  for i in 1..5 loop
    v_valor := v_valor * 16 + coalesce(v_orden[i], 0);
  end loop;
  return v_valor;
end;
$$;

-- La mejor de cinco entre las siete (o seis) cartas.
create or replace function public.poker_mejor_valor(p_cartas text[])
returns bigint
language plpgsql
immutable
as $$
declare
  n       integer := coalesce(array_length(p_cartas, 1), 0);
  v_mejor bigint := -1;
  v_valor bigint;
  a       integer;
  b       integer;
begin
  if n <= 5 then
    return public.poker_valor_cinco(p_cartas);
  end if;

  for a in 1..n loop
    for b in a..n loop
      -- Con seis se quita una (a = b); con siete, dos distintas.
      continue when (n = 7 and a = b) or (n = 6 and a <> b);
      select public.poker_valor_cinco(array_agg(p_cartas[i] order by i))
        into v_valor
        from generate_series(1, n) i
       where i <> a and i <> b;
      v_mejor := greatest(v_mejor, v_valor);
    end loop;
  end loop;

  return v_mejor;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4 · El motor de una mano
-- ----------------------------------------------------------------------------
-- El siguiente en el sentido de las agujas del reloj despues de p_desde,
-- entre los que siguen en la mano (y, si p_puede_apostar, no fueron con
-- todo).
create or replace function public.poker_siguiente(
  p_mano          uuid,
  p_desde         smallint,
  p_puede_apostar boolean
)
returns smallint
language sql
stable
as $$
  select j.posicion
    from public.poker_jugadores j
   where j.mano_id = p_mano
     and not j.retirado
     and (not p_puede_apostar or not j.todo)
   order by (j.posicion - p_desde - 1 + 12) % 6
   limit 1;
$$;

-- Paga la mano: al ultimo que queda, o por botes a las mejores manos.
create or replace function public.poker_terminar(p_mano uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mano       public.poker_manos;
  v_en_mano    integer;
  v_unico      public.poker_jugadores;
  v_niveles    integer[];
  v_nivel      integer;
  v_previo     integer := 0;
  v_bote       integer;
  v_mejor      bigint;
  v_ganadores  smallint[];
  v_parte      integer;
  v_resto      integer;
  v_repartido  integer := 0;
  v_pagos      jsonb := '{}';
  v_pago       record;
  i            integer;
begin
  select * into v_mano from public.poker_manos where id = p_mano for update;
  if v_mano.fase = 'terminada' then
    return;
  end if;

  select count(*) into v_en_mano
    from public.poker_jugadores where mano_id = p_mano and not retirado;

  if v_en_mano = 1 then
    -- Todos se retiraron menos uno: se lleva todo, sin mostrar.
    select * into v_unico
      from public.poker_jugadores where mano_id = p_mano and not retirado;
    v_pagos := jsonb_build_object(v_unico.posicion::text, v_mano.bote);
  else
    -- Se muestran las cartas de los que siguen, con su mejor mano.
    update public.poker_jugadores j
       set cartas_vistas = c.cartas,
           valor = public.poker_mejor_valor(c.cartas || v_mano.comunitarias)
      from public.poker_cartas c
     where j.mano_id = p_mano
       and c.mano_id = p_mano
       and c.usuario_id = j.usuario_id
       and not j.retirado;

    -- Un bote por cada nivel de aporte de los que siguen: quien fue con todo
    -- con menos fichas solo pelea lo que pudo cubrir.
    select array_agg(distinct aportado order by aportado) into v_niveles
      from public.poker_jugadores
     where mano_id = p_mano and not retirado and aportado > 0;

    foreach v_nivel in array coalesce(v_niveles, '{}') loop
      select coalesce(sum(least(aportado, v_nivel) - least(aportado, v_previo)), 0)
        into v_bote
        from public.poker_jugadores where mano_id = p_mano;

      if v_bote > 0 then
        select max(valor) into v_mejor
          from public.poker_jugadores
         where mano_id = p_mano and not retirado and aportado >= v_nivel;

        select array_agg(posicion order by (posicion - v_mano.boton - 1 + 12) % 6)
          into v_ganadores
          from public.poker_jugadores
         where mano_id = p_mano and not retirado and aportado >= v_nivel
           and valor = v_mejor;

        -- Empate: se divide, y las fichas que no se dividen van a los
        -- primeros despues del boton.
        v_parte := v_bote / array_length(v_ganadores, 1);
        v_resto := v_bote - v_parte * array_length(v_ganadores, 1);
        for i in 1..array_length(v_ganadores, 1) loop
          v_pagos := jsonb_set(
            v_pagos,
            array[v_ganadores[i]::text],
            to_jsonb(coalesce((v_pagos ->> v_ganadores[i]::text)::integer, 0)
                     + v_parte + case when i <= v_resto then 1 else 0 end)
          );
        end loop;
        v_repartido := v_repartido + v_bote;
      end if;
      v_previo := v_nivel;
    end loop;

    -- Lo que sobra (fichas de alguien que subio mas y despues se fue) va al
    -- primero de los que ganaron el ultimo bote.
    if v_mano.bote > v_repartido and v_ganadores is not null then
      v_pagos := jsonb_set(
        v_pagos,
        array[v_ganadores[1]::text],
        to_jsonb(coalesce((v_pagos ->> v_ganadores[1]::text)::integer, 0)
                 + v_mano.bote - v_repartido)
      );
    end if;
  end if;

  for v_pago in
    select key::smallint as posicion, value::integer as monto
      from jsonb_each_text(v_pagos)
  loop
    update public.poker_asientos a
       set fichas = a.fichas + v_pago.monto
      from public.poker_jugadores j
     where j.mano_id = p_mano
       and j.posicion = v_pago.posicion
       and a.sala_id = v_mano.sala_id
       and a.usuario_id = j.usuario_id;
    insert into public.poker_acciones (mano_id, sala_id, posicion, accion, monto)
    values (p_mano, v_mano.sala_id, v_pago.posicion, 'gana', v_pago.monto);
  end loop;

  update public.poker_manos
     set fase = 'terminada',
         turno = null,
         vence_en = null,
         resultado = (
           select coalesce(jsonb_agg(jsonb_build_object(
                    'posicion', key::integer, 'monto', value::integer)), '[]')
             from jsonb_each_text(v_pagos)
         ),
         terminada_en = now()
   where id = p_mano;

  update public.poker_salas set actividad_en = now() where id = v_mano.sala_id;
end;
$$;

-- Despues de cada jugada: a quien le toca, o la calle siguiente, o el final.
create or replace function public.poker_avanzar(p_mano uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mano      public.poker_manos;
  v_sala      public.poker_salas;
  v_en_mano   integer;
  v_pueden    integer;
  v_siguiente smallint;
  v_cartas    text[];
  v_n         integer;
begin
  select * into v_mano from public.poker_manos where id = p_mano;
  select * into v_sala from public.poker_salas where id = v_mano.sala_id;

  select count(*) filter (where not retirado),
         count(*) filter (where not retirado and not todo)
    into v_en_mano, v_pueden
    from public.poker_jugadores where mano_id = p_mano;

  if v_en_mano <= 1 then
    perform public.poker_terminar(p_mano);
    return;
  end if;

  -- Falta que alguien decida en esta ronda?
  select j.posicion into v_siguiente
    from public.poker_jugadores j
   where j.mano_id = p_mano
     and not j.retirado
     and not j.todo
     and (not j.actuo or j.apuesta_ronda < v_mano.apuesta)
   order by (j.posicion - coalesce(v_mano.turno, v_mano.boton) - 1 + 12) % 6
   limit 1;

  -- Uno solo que puede apostar y ya cubre lo mas alto: no tiene contra quien.
  if v_siguiente is not null and v_pueden = 1 then
    if (select apuesta_ronda >= v_mano.apuesta
          from public.poker_jugadores
         where mano_id = p_mano and posicion = v_siguiente) then
      v_siguiente := null;
    end if;
  end if;

  if v_siguiente is not null then
    update public.poker_manos
       set turno = v_siguiente,
           vence_en = now() + make_interval(secs => v_sala.segundos_turno)
     where id = p_mano;
    return;
  end if;

  -- Se cerro la ronda: la calle siguiente. Si no quedan dos que puedan
  -- apostar, se dan todas las que faltan sin apuestas.
  loop
    if v_mano.fase = 'river' then
      perform public.poker_terminar(p_mano);
      return;
    end if;

    v_n := case v_mano.fase when 'preflop' then 3 else 1 end;
    select cartas into v_cartas
      from public.poker_mazos where mano_id = p_mano for update;
    update public.poker_mazos
       set cartas = v_cartas[v_n + 1:]
     where mano_id = p_mano;

    update public.poker_manos
       set fase = case fase
                    when 'preflop' then 'flop'
                    when 'flop' then 'turn'
                    else 'river'
                  end,
           comunitarias = comunitarias || v_cartas[1:v_n],
           apuesta = 0,
           subida_minima = v_sala.ciega_grande,
           turno = null,
           vence_en = null
     where id = p_mano
    returning * into v_mano;

    update public.poker_jugadores
       set apuesta_ronda = 0,
           actuo = false,
           ultima_accion = case when retirado or todo then ultima_accion end
     where mano_id = p_mano;

    insert into public.poker_acciones (mano_id, sala_id, accion)
    values (p_mano, v_mano.sala_id, v_mano.fase);

    if v_pueden >= 2 then
      update public.poker_manos
         set turno = public.poker_siguiente(p_mano, v_mano.boton, true),
             vence_en = now() + make_interval(secs => v_sala.segundos_turno)
       where id = p_mano;
      return;
    end if;
  end loop;
end;
$$;

-- Aplica una jugada ya autorizada (el turno lo revisa quien llama).
create or replace function public.poker_aplicar(
  p_mano     uuid,
  p_posicion smallint,
  p_accion   text,
  p_monto    integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mano    public.poker_manos;
  v_jugador public.poker_jugadores;
  v_fichas  integer;
  v_falta   integer;
  v_poner   integer := 0;
  v_aumento integer;
begin
  select * into v_mano from public.poker_manos where id = p_mano for update;
  select * into v_jugador
    from public.poker_jugadores
   where mano_id = p_mano and posicion = p_posicion
     for update;
  select fichas into v_fichas
    from public.poker_asientos
   where sala_id = v_mano.sala_id and usuario_id = v_jugador.usuario_id
     for update;
  v_fichas := coalesce(v_fichas, 0);
  v_falta := v_mano.apuesta - v_jugador.apuesta_ronda;

  case p_accion
    when 'retirarse' then
      null;
    when 'pasar' then
      if v_falta > 0 then
        raise exception 'NO_PUEDES_PASAR: hay % para igualar', v_falta
          using errcode = '22023';
      end if;
    when 'igualar' then
      if v_falta <= 0 then
        raise exception 'NADA_QUE_IGUALAR' using errcode = '22023';
      end if;
      v_poner := least(v_falta, v_fichas);
    when 'subir' then
      -- p_monto es a cuanto queda su apuesta en esta ronda.
      v_poner := p_monto - v_jugador.apuesta_ronda;
      if p_monto <= v_mano.apuesta or v_poner > v_fichas then
        raise exception 'SUBIDA_INVALIDA' using errcode = '22023';
      end if;
      if v_poner < v_fichas
         and p_monto - v_mano.apuesta < v_mano.subida_minima then
        raise exception 'SUBIDA_CORTA: el minimo es %',
          v_mano.apuesta + v_mano.subida_minima
          using errcode = '22023';
      end if;
    when 'todo' then
      v_poner := v_fichas;
      if v_poner <= 0 then
        raise exception 'SIN_FICHAS' using errcode = '22023';
      end if;
    else
      raise exception 'JUGADA_INVALIDA: %', p_accion using errcode = '22023';
  end case;

  update public.poker_asientos
     set fichas = fichas - v_poner
   where sala_id = v_mano.sala_id and usuario_id = v_jugador.usuario_id;

  update public.poker_jugadores
     set apuesta_ronda = apuesta_ronda + v_poner,
         aportado = aportado + v_poner,
         retirado = retirado or p_accion = 'retirarse',
         todo = todo or (p_accion <> 'retirarse' and v_poner > 0
                         and v_poner = v_fichas),
         actuo = true
   where mano_id = p_mano and posicion = p_posicion
  returning * into v_jugador;

  update public.poker_jugadores
     set ultima_accion = case
           when v_jugador.todo and p_accion <> 'retirarse' then 'todo'
           when p_accion = 'subir' and v_mano.apuesta = 0 then 'apostar'
           else p_accion
         end
   where mano_id = p_mano and posicion = p_posicion;

  update public.poker_manos set bote = bote + v_poner where id = p_mano;

  if v_jugador.apuesta_ronda > v_mano.apuesta then
    v_aumento := v_jugador.apuesta_ronda - v_mano.apuesta;
    update public.poker_manos
       set apuesta = v_jugador.apuesta_ronda,
           subida_minima = greatest(subida_minima, v_aumento)
     where id = p_mano;
    -- Una subida completa obliga a los demas a volver a decidir.
    if v_aumento >= v_mano.subida_minima then
      update public.poker_jugadores
         set actuo = false
       where mano_id = p_mano
         and posicion <> p_posicion
         and not retirado
         and not todo;
    end if;
  end if;

  insert into public.poker_acciones (mano_id, sala_id, posicion, accion, monto)
  values (p_mano, v_mano.sala_id, p_posicion,
          case when v_jugador.todo and p_accion <> 'retirarse'
               then 'todo' else p_accion end,
          v_poner);

  perform public.poker_avanzar(p_mano);
end;
$$;

-- Pone una ciega, con lo que tenga si no le alcanza.
create or replace function public.poker_poner_ciega(
  p_mano     uuid,
  p_posicion smallint,
  p_monto    integer,
  p_accion   text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_jugador public.poker_jugadores;
  v_sala    uuid;
  v_fichas  integer;
  v_poner   integer;
begin
  select * into v_jugador
    from public.poker_jugadores where mano_id = p_mano and posicion = p_posicion;
  v_sala := v_jugador.sala_id;
  select fichas into v_fichas
    from public.poker_asientos
   where sala_id = v_sala and usuario_id = v_jugador.usuario_id
     for update;
  v_poner := least(p_monto, v_fichas);

  update public.poker_asientos
     set fichas = fichas - v_poner
   where sala_id = v_sala and usuario_id = v_jugador.usuario_id;
  update public.poker_jugadores
     set apuesta_ronda = v_poner,
         aportado = v_poner,
         todo = v_poner = v_fichas,
         ultima_accion = p_accion
   where mano_id = p_mano and posicion = p_posicion;
  update public.poker_manos set bote = bote + v_poner where id = p_mano;
  insert into public.poker_acciones (mano_id, sala_id, posicion, accion, monto)
  values (p_mano, v_sala, p_posicion, p_accion, v_poner);
end;
$$;

-- ----------------------------------------------------------------------------
-- 5 · Lo que llama la app
-- ----------------------------------------------------------------------------
-- Reparte una mano nueva si se puede: dos o mas sentados con fichas, ninguna
-- en juego y unos segundos desde la anterior para ver como termino. La
-- llaman todos los telefonos de la mesa; la sala bloqueada hace que reparta
-- uno solo.
create or replace function public.poker_empezar_mano(p_sala uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sala       public.poker_salas;
  v_ultima     public.poker_manos;
  v_posiciones smallint[];
  v_n          integer;
  v_boton      smallint;
  v_chica      smallint;
  v_grande     smallint;
  v_mano       uuid;
  v_mazo       text[];
  v_pos        smallint;
  v_i          integer := 0;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  select * into v_sala from public.poker_salas where id = p_sala for update;
  if v_sala.id is null then
    raise exception 'SALA_INEXISTENTE' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.poker_asientos
     where sala_id = p_sala and usuario_id = auth.uid()
  ) then
    raise exception 'NO_ESTAS_SENTADO' using errcode = '42501';
  end if;
  if exists (
    select 1 from public.poker_manos where sala_id = p_sala and fase <> 'terminada'
  ) then
    return false;
  end if;

  select * into v_ultima
    from public.poker_manos where sala_id = p_sala order by numero desc limit 1;
  if v_ultima.terminada_en > now() - interval '4 seconds' then
    return false;
  end if;

  select array_agg(posicion order by posicion) into v_posiciones
    from public.poker_asientos
   where sala_id = p_sala and not afuera and fichas > 0;
  v_n := coalesce(array_length(v_posiciones, 1), 0);
  if v_n < 2 then
    return false;
  end if;

  -- El boton pasa al siguiente que juega; las ciegas lo siguen. Mano a
  -- mano, el boton pone la chica.
  select p into v_boton from unnest(v_posiciones) p
   order by (p - coalesce(v_ultima.boton, 5) - 1 + 12) % 6 limit 1;
  if v_n = 2 then
    v_chica := v_boton;
  else
    select p into v_chica from unnest(v_posiciones) p
     order by (p - v_boton - 1 + 12) % 6 limit 1;
  end if;
  select p into v_grande from unnest(v_posiciones) p
   order by (p - v_chica - 1 + 12) % 6 limit 1;

  insert into public.poker_manos (sala_id, numero, boton, subida_minima)
  values (p_sala, coalesce(v_ultima.numero, 0) + 1, v_boton, v_sala.ciega_grande)
  returning id into v_mano;

  insert into public.poker_jugadores (mano_id, sala_id, posicion, usuario_id)
  select v_mano, p_sala, a.posicion, a.usuario_id
    from public.poker_asientos a
   where a.sala_id = p_sala and a.posicion = any(v_posiciones);

  -- Dos a cada uno, empezando a la izquierda del boton.
  v_mazo := public.poker_barajar();
  for v_pos in
    select p from unnest(v_posiciones) p order by (p - v_boton - 1 + 12) % 6
  loop
    v_i := v_i + 1;
    insert into public.poker_cartas (mano_id, usuario_id, cartas)
    select v_mano, a.usuario_id, array[v_mazo[v_i], v_mazo[v_i + v_n]]
      from public.poker_asientos a
     where a.sala_id = p_sala and a.posicion = v_pos;
  end loop;
  insert into public.poker_mazos (mano_id, cartas)
  values (v_mano, v_mazo[2 * v_n + 1:]);

  perform public.poker_poner_ciega(v_mano, v_chica, v_sala.ciega_chica, 'ciega_chica');
  perform public.poker_poner_ciega(v_mano, v_grande, v_sala.ciega_grande, 'ciega_grande');

  -- Se busca al que habla desde la ciega grande: el de su izquierda.
  update public.poker_manos
     set apuesta = (select max(apuesta_ronda)
                      from public.poker_jugadores where mano_id = v_mano),
         turno = v_grande
   where id = v_mano;
  update public.poker_salas set actividad_en = now() where id = p_sala;

  perform public.poker_avanzar(v_mano);
  return true;
end;
$$;

create or replace function public.poker_jugar(
  p_sala   uuid,
  p_accion text,
  p_monto  integer default 0
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mano     public.poker_manos;
  v_posicion smallint;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  perform 1 from public.poker_salas where id = p_sala for update;
  if not found then
    raise exception 'SALA_INEXISTENTE' using errcode = '22023';
  end if;

  select * into v_mano
    from public.poker_manos where sala_id = p_sala and fase <> 'terminada';
  if v_mano.id is null then
    raise exception 'SIN_MANO' using errcode = '22023';
  end if;
  select posicion into v_posicion
    from public.poker_jugadores
   where mano_id = v_mano.id and usuario_id = auth.uid();
  if v_posicion is null or v_posicion is distinct from v_mano.turno then
    raise exception 'NO_ES_TU_TURNO' using errcode = '22023';
  end if;

  perform public.poker_aplicar(v_mano.id, v_posicion, p_accion, coalesce(p_monto, 0));

  update public.poker_asientos
     set vencidos = 0
   where sala_id = p_sala and usuario_id = auth.uid();
  update public.poker_salas set actividad_en = now() where id = p_sala;
end;
$$;

-- Si el turno vencio, pasa (si puede) o se retira por quien no jugo. Lo
-- puede llamar cualquiera: solo actua despues de la hora.
create or replace function public.poker_vencer_turno(p_sala uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mano    public.poker_manos;
  v_jugador public.poker_jugadores;
begin
  perform 1 from public.poker_salas where id = p_sala for update;
  select * into v_mano
    from public.poker_manos where sala_id = p_sala and fase <> 'terminada';
  if v_mano.id is null or v_mano.vence_en is null or v_mano.vence_en > now() then
    return false;
  end if;

  select * into v_jugador
    from public.poker_jugadores where mano_id = v_mano.id and posicion = v_mano.turno;
  perform public.poker_aplicar(
    v_mano.id,
    v_mano.turno,
    case when v_jugador.apuesta_ronda >= v_mano.apuesta then 'pasar' else 'retirarse' end,
    0
  );

  -- Dos turnos vencidos seguidos: sentado afuera hasta que vuelva.
  update public.poker_asientos
     set vencidos = vencidos + 1,
         afuera = afuera or vencidos + 1 >= 2
   where sala_id = p_sala and usuario_id = v_jugador.usuario_id;
  return true;
end;
$$;

-- Se levanta de la mesa: si estaba en una mano, se retira. La mesa que queda
-- vacia se cierra.
create or replace function public.poker_levantarse(p_sala uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mano    public.poker_manos;
  v_jugador public.poker_jugadores;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  perform 1 from public.poker_salas where id = p_sala for update;
  if not exists (
    select 1 from public.poker_asientos
     where sala_id = p_sala and usuario_id = auth.uid()
  ) then
    return;
  end if;

  select * into v_mano
    from public.poker_manos where sala_id = p_sala and fase <> 'terminada';
  if v_mano.id is not null then
    select * into v_jugador
      from public.poker_jugadores
     where mano_id = v_mano.id and usuario_id = auth.uid();
    if v_jugador.posicion is not null and not v_jugador.retirado then
      if v_mano.turno = v_jugador.posicion then
        perform public.poker_aplicar(v_mano.id, v_jugador.posicion, 'retirarse', 0);
      else
        update public.poker_jugadores
           set retirado = true, ultima_accion = 'retirarse'
         where mano_id = v_mano.id and posicion = v_jugador.posicion;
        insert into public.poker_acciones (mano_id, sala_id, posicion, accion)
        values (v_mano.id, p_sala, v_jugador.posicion, 'retirarse');
        if (select count(*) from public.poker_jugadores
             where mano_id = v_mano.id and not retirado) <= 1 then
          perform public.poker_terminar(v_mano.id);
        end if;
      end if;
    end if;
  end if;

  delete from public.poker_asientos
   where sala_id = p_sala and usuario_id = auth.uid();

  if not exists (select 1 from public.poker_asientos where sala_id = p_sala) then
    delete from public.poker_salas where id = p_sala;
  end if;
end;
$$;

-- Se sienta en el primer lugar libre, con las fichas de la mesa. Si estaba
-- en otra mesa, primero se levanta de esa.
create or replace function public.poker_sentarse(p_sala uuid)
returns smallint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sala  public.poker_salas;
  v_otra  uuid;
  v_pos   smallint;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.profiles where id = auth.uid() and onboarding_completed
  ) then
    raise exception 'PERFIL_INCOMPLETO' using errcode = '42501';
  end if;

  select sala_id into v_otra
    from public.poker_asientos where usuario_id = auth.uid();
  if v_otra = p_sala then
    return (select posicion from public.poker_asientos
             where sala_id = p_sala and usuario_id = auth.uid());
  end if;
  if v_otra is not null then
    perform public.poker_levantarse(v_otra);
  end if;

  select * into v_sala from public.poker_salas where id = p_sala for update;
  if v_sala.id is null then
    raise exception 'SALA_INEXISTENTE' using errcode = '22023';
  end if;

  select min(p)::smallint into v_pos
    from generate_series(0, 5) p
   where p not in (select posicion from public.poker_asientos where sala_id = p_sala);
  if v_pos is null then
    raise exception 'MESA_LLENA' using errcode = '22023';
  end if;

  insert into public.poker_asientos (sala_id, posicion, usuario_id, fichas)
  values (p_sala, v_pos, auth.uid(), v_sala.fichas_iniciales);
  update public.poker_salas set actividad_en = now() where id = p_sala;
  return v_pos;
end;
$$;

-- Crea una mesa y sienta a quien la crea. Ciegas: 10/20, 25/50, 50/100 o
-- 100/200; cada uno se sienta con 50 ciegas grandes.
create or replace function public.poker_crear_sala(
  p_nombre       text,
  p_ciega_grande integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre text := trim(coalesce(p_nombre, ''));
  v_sala   uuid;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.profiles where id = auth.uid() and onboarding_completed
  ) then
    raise exception 'PERFIL_INCOMPLETO' using errcode = '42501';
  end if;
  if length(v_nombre) < 3 or length(v_nombre) > 30 then
    raise exception 'NOMBRE_INVALIDO: entre 3 y 30 letras' using errcode = '22023';
  end if;
  if public.termino_ofensivo(v_nombre) is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa el nombre de la mesa'
      using errcode = '22023';
  end if;
  if p_ciega_grande not in (20, 50, 100, 200) then
    raise exception 'CIEGAS_INVALIDAS' using errcode = '22023';
  end if;

  insert into public.poker_salas
    (nombre, creador_id, ciega_chica, ciega_grande, fichas_iniciales)
  values
    (v_nombre, auth.uid(), p_ciega_grande / 2, p_ciega_grande, p_ciega_grande * 50)
  returning id into v_sala;

  perform public.poker_sentarse(v_sala);
  return v_sala;
end;
$$;

-- Vuelve a entrar en las manos despues de quedar sentado afuera.
create or replace function public.poker_volver(p_sala uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.poker_asientos
     set afuera = false, vencidos = 0
   where sala_id = p_sala and usuario_id = auth.uid();
$$;

-- Sin fichas: recarga las de la mesa, siempre que no este en una mano.
create or replace function public.poker_recargar(p_sala uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform 1 from public.poker_salas where id = p_sala for update;
  if exists (
    select 1
      from public.poker_jugadores j
      join public.poker_manos m on m.id = j.mano_id
     where m.sala_id = p_sala and m.fase <> 'terminada'
       and j.usuario_id = auth.uid() and not j.retirado
  ) then
    raise exception 'EN_UNA_MANO: espera a que termine' using errcode = '22023';
  end if;

  update public.poker_asientos a
     set fichas = s.fichas_iniciales, afuera = false, vencidos = 0
    from public.poker_salas s
   where a.sala_id = p_sala and a.usuario_id = auth.uid()
     and s.id = p_sala and a.fichas = 0;
end;
$$;

-- Las mesas abiertas, con cuantos hay sentados.
create or replace function public.poker_salas_abiertas()
returns table (
  sala_id          uuid,
  nombre           text,
  creador          text,
  ciega_chica      integer,
  ciega_grande     integer,
  fichas_iniciales integer,
  jugadores        integer,
  en_juego         boolean,
  mia              boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id,
         s.nombre,
         p.full_name,
         s.ciega_chica,
         s.ciega_grande,
         s.fichas_iniciales,
         (select count(*)::integer from public.poker_asientos a where a.sala_id = s.id),
         exists (select 1 from public.poker_manos m
                  where m.sala_id = s.id and m.fase <> 'terminada'),
         exists (select 1 from public.poker_asientos a
                  where a.sala_id = s.id and a.usuario_id = auth.uid())
    from public.poker_salas s
    join public.profiles p on p.id = s.creador_id
   order by 9 desc, 7 desc, s.creada_en desc;
$$;

-- Todo lo que el que pregunta puede ver de una mesa: los asientos, la ultima
-- mano, lo que se ve de cada jugador y SUS cartas. Las de los demas solo
-- aparecen si la mano llego a mostrarse.
create or replace function public.poker_estado(p_sala uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_mano public.poker_manos;
begin
  select * into v_mano
    from public.poker_manos where sala_id = p_sala order by numero desc limit 1;

  return jsonb_build_object(
    'ahora', now(),
    'sala', (select to_jsonb(s) from public.poker_salas s where s.id = p_sala),
    'yo', (select posicion from public.poker_asientos
            where sala_id = p_sala and usuario_id = auth.uid()),
    'asientos', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'posicion', a.posicion,
               'usuario_id', a.usuario_id,
               'nombre', p.full_name,
               'avatar_path', p.avatar_path,
               'fichas', a.fichas,
               'afuera', a.afuera
             ) order by a.posicion), '[]')
        from public.poker_asientos a
        join public.profiles p on p.id = a.usuario_id
       where a.sala_id = p_sala
    ),
    'mano', case when v_mano.id is null then null else to_jsonb(v_mano) end,
    'jugadores', (
      select coalesce(jsonb_agg(to_jsonb(j) order by j.posicion), '[]')
        from public.poker_jugadores j
       where j.mano_id = v_mano.id
    ),
    'mis_cartas', (
      select to_jsonb(c.cartas)
        from public.poker_cartas c
       where c.mano_id = v_mano.id and c.usuario_id = auth.uid()
    )
  );
end;
$$;

-- Lo que la app llama; lo de adentro, nadie.
revoke all on function
  public.poker_terminar(uuid),
  public.poker_avanzar(uuid),
  public.poker_aplicar(uuid, smallint, text, integer),
  public.poker_poner_ciega(uuid, smallint, integer, text),
  public.poker_empezar_mano(uuid),
  public.poker_jugar(uuid, text, integer),
  public.poker_vencer_turno(uuid),
  public.poker_levantarse(uuid),
  public.poker_sentarse(uuid),
  public.poker_crear_sala(text, integer),
  public.poker_volver(uuid),
  public.poker_recargar(uuid),
  public.poker_salas_abiertas(),
  public.poker_estado(uuid)
from public;

grant execute on function
  public.poker_empezar_mano(uuid),
  public.poker_jugar(uuid, text, integer),
  public.poker_vencer_turno(uuid),
  public.poker_levantarse(uuid),
  public.poker_sentarse(uuid),
  public.poker_crear_sala(text, integer),
  public.poker_volver(uuid),
  public.poker_recargar(uuid),
  public.poker_salas_abiertas(),
  public.poker_estado(uuid)
to authenticated;

-- ----------------------------------------------------------------------------
-- 6 · El reloj de respaldo y la limpieza
-- ----------------------------------------------------------------------------
-- Cada minuto: los turnos vencidos que nadie vencio (no queda nadie mirando),
-- las mesas abandonadas y las manos viejas.
create or replace function public.poker_mantenimiento()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sala uuid;
begin
  for v_sala in
    select sala_id from public.poker_manos
     where fase <> 'terminada' and vence_en < now() - interval '5 seconds'
  loop
    perform public.poker_vencer_turno(v_sala);
  end loop;

  delete from public.poker_salas where actividad_en < now() - interval '3 hours';
  delete from public.poker_manos
   where fase = 'terminada' and terminada_en < now() - interval '6 hours';
end;
$$;

revoke all on function public.poker_mantenimiento() from public;

select cron.schedule(
  'poker-mantenimiento',
  '* * * * *',
  $$select public.poker_mantenimiento();$$
);

-- ----------------------------------------------------------------------------
-- 7 · Pruebas: si algo no da lo esperado, no se aplica nada
-- ----------------------------------------------------------------------------
do $$
declare
  v_a      uuid := gen_random_uuid();
  v_b      uuid := gen_random_uuid();
  v_carrera text;
  v_sala   uuid;
  v_mano   public.poker_manos;
  v_total  integer;
  v_mazo   text[];
  v_vistas integer;
begin
  begin
    -- Las manos, de mayor a menor.
    if not (
      public.poker_mejor_valor(array['As','Ks','Qs','Js','Ts','2d','3c'])
        > public.poker_mejor_valor(array['9h','9d','9s','9c','Kd','2s','3h'])
      and public.poker_mejor_valor(array['9h','9d','9s','9c','Kd','2s','3h'])
        > public.poker_mejor_valor(array['8h','8d','8s','Kc','Kd','2s','3h'])
      and public.poker_mejor_valor(array['8h','8d','8s','Kc','Kd','2s','3h'])
        > public.poker_mejor_valor(array['2h','7h','9h','Jh','Kh','Ad','Ac'])
      and public.poker_mejor_valor(array['2h','7h','9h','Jh','Kh','Ad','Ac'])
        > public.poker_mejor_valor(array['5d','6c','7h','8s','9d','Ac','Ad'])
      -- A-2-3-4-5 es la escalera mas baja.
      and public.poker_mejor_valor(array['6d','2c','3h','4s','5d','Kc','Qd'])
        > public.poker_mejor_valor(array['Ad','2c','3h','4s','5d','Kc','Qd'])
      and public.poker_mejor_valor(array['Ad','2c','3h','4s','5d','Kc','Qd'])
        > public.poker_mejor_valor(array['Ad','Ac','Ah','4s','9d','Kc','Qd'])
      -- El kicker desempata; las mismas cinco empatan.
      and public.poker_mejor_valor(array['Ad','Ac','Kh','4s','9d','2c','3d'])
        > public.poker_mejor_valor(array['Ad','Ac','Qh','4s','9d','2c','3d'])
      and public.poker_mejor_valor(array['Ad','Kd','Qd','Jd','9c','2s','3h'])
        = public.poker_mejor_valor(array['Ac','Kc','Qh','Jh','9s','2d','3c'])
    ) then
      raise exception 'el orden de las manos esta mal';
    end if;

    -- El mazo tiene las 52, sin repetir.
    v_mazo := public.poker_barajar();
    if array_length(v_mazo, 1) <> 52
       or (select count(distinct c) from unnest(v_mazo) c) <> 52 then
      raise exception 'el mazo no tiene las 52 cartas';
    end if;

    -- Una mano de punta a punta entre dos.
    insert into public.institutional_domains (domain, label)
    values ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA')
    on conflict (domain) do nothing;
    select id into v_carrera from public.careers where is_active
     order by sort_order limit 1;
    if v_carrera is null then
      insert into public.careers (id, name, faculty)
      values ('prueba_poker', 'Prueba', 'Prueba')
      returning id into v_carrera;
    end if;
    insert into auth.users (id, email) values
      (v_a, 'a2024119994@estudiantes.upsa.edu.bo'),
      (v_b, 'a2024119993@estudiantes.upsa.edu.bo');
    update public.profiles
       set full_name = case id when v_a then 'Ana Poker' else 'Beto Poker' end,
           career_id = v_carrera, whatsapp = '59170000009',
           onboarding_completed = true
     where id in (v_a, v_b);

    perform set_config('request.jwt.claim.sub', v_a::text, true);
    v_sala := public.poker_crear_sala('Mesa de prueba', 20);
    perform set_config('request.jwt.claim.sub', v_b::text, true);
    perform public.poker_sentarse(v_sala);

    if not public.poker_empezar_mano(v_sala) then
      raise exception 'no se pudo repartir';
    end if;
    select * into v_mano from public.poker_manos where sala_id = v_sala;
    if v_mano.bote <> 30 or v_mano.apuesta <> 20 or v_mano.turno is null then
      raise exception 'las ciegas quedaron mal: %', v_mano;
    end if;

    -- Cada uno ve solo sus cartas.
    if (select count(*) from public.poker_cartas where mano_id = v_mano.id) <> 2 then
      raise exception 'no se repartieron las cartas';
    end if;

    -- Que no le toque a quien no es su turno.
    perform set_config('request.jwt.claim.sub',
      (select usuario_id::text from public.poker_jugadores
        where mano_id = v_mano.id and posicion <> v_mano.turno), true);
    begin
      perform public.poker_jugar(v_sala, 'igualar', 0);
      raise exception 'jugo quien no tenia el turno';
    exception when others then
      if sqlerrm not like 'NO_ES_TU_TURNO%' then raise; end if;
    end;

    -- Los dos van con todo: se reparte entero y alguien cobra.
    perform set_config('request.jwt.claim.sub',
      (select usuario_id::text from public.poker_jugadores
        where mano_id = v_mano.id and posicion = v_mano.turno), true);
    perform public.poker_jugar(v_sala, 'todo', 0);
    select * into v_mano from public.poker_manos where id = v_mano.id;
    perform set_config('request.jwt.claim.sub',
      (select usuario_id::text from public.poker_jugadores
        where mano_id = v_mano.id and posicion = v_mano.turno), true);
    perform public.poker_jugar(v_sala, 'igualar', 0);

    select * into v_mano from public.poker_manos where id = v_mano.id;
    if v_mano.fase <> 'terminada' or array_length(v_mano.comunitarias, 1) <> 5 then
      raise exception 'la mano no termino con las cinco cartas: %', v_mano;
    end if;
    select count(*) into v_vistas
      from public.poker_jugadores where mano_id = v_mano.id and cartas_vistas is not null;
    if v_vistas <> 2 then
      raise exception 'no se mostraron las cartas';
    end if;

    -- Ni una ficha se pierde ni aparece.
    select sum(fichas) into v_total from public.poker_asientos where sala_id = v_sala;
    if v_total <> 2000 then
      raise exception 'las fichas no cierran: %', v_total;
    end if;

    raise exception 'PRUEBAS_OK';
  exception when raise_exception then
    if sqlerrm <> 'PRUEBAS_OK' then
      raise exception 'No se aplico nada. %', sqlerrm;
    end if;
  end;

  if exists (select 1 from auth.users where id in (v_a, v_b)) then
    raise exception 'quedaron datos de prueba';
  end if;

  raise notice 'Poker probado: todo bien.';
end $$;

commit;
