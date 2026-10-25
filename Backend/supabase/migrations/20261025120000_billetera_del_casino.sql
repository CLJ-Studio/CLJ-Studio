-- ============================================================================
-- 61 · Una sola billetera para todo el casino, y el poker al instante
-- ============================================================================
-- Hasta ahora el casino tenia dos bolsillos que no se tocaban: las fichas de
-- la ruleta y el blackjack vivian en el telefono, y el poker daba las suyas en
-- cada mesa y se las quedaba al levantarse. Lo que se ganaba en el poker se
-- perdia. Ahora hay una sola billetera por cuenta, en el servidor:
--
--   · casino_billeteras: las fichas de cada uno. El telefono guarda una copia
--     para jugar sin red y le manda al servidor lo que cambio.
--   · casino_movimientos: cada cambio, con su motivo. Su id es el "lote" que
--     manda el telefono: si llega dos veces (se corto la red y reintento),
--     cuenta una sola.
--   · Poker: sentarse cuesta fichas de la billetera (de 20 a 100 ciegas
--     grandes) y al levantarse vuelven todas las que quedan. Pasa siempre, se
--     levante uno, lo levante la limpieza o se cierre la mesa: lo hace un
--     disparador del asiento, no cada funcion.
--
-- Y para que la mesa se vea al instante en todos los telefonos:
--
--   · poker_salas.version sube con cada cambio. La app escucha solo esa fila
--     (un aviso por jugada, no varios) y descarta los estados viejos que
--     lleguen tarde: antes uno viejo podia pisar a uno nuevo y la mesa
--     saltaba para atras.
--   · poker_jugar() devuelve como quedo la mesa: quien juega no espera otra
--     vuelta para ver su jugada.
--   · Quien queda sentado afuera mas de 20 minutos se levanta solo, y sus
--     fichas vuelven a su billetera.
--
-- Termina con pruebas dentro de la misma transaccion: si algo no da lo
-- esperado, no se aplica nada.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1 · La billetera
-- ----------------------------------------------------------------------------
create table public.casino_billeteras (
  usuario_id     uuid primary key references public.profiles(id) on delete cascade,
  -- Las de regalo, si la billetera nace en el servidor (sentandose al poker).
  fichas         bigint not null default 1000,
  -- Si ya trajo las fichas que tenia guardadas en el telefono.
  migrada        boolean not null default false,
  creada_en      timestamptz not null default now(),
  actualizada_en timestamptz not null default now(),
  constraint casino_billeteras_fichas check (fichas >= 0)
);

create table public.casino_movimientos (
  -- El lote del telefono, o uno nuevo si el cambio lo hace el servidor.
  id         uuid primary key,
  usuario_id uuid not null references public.profiles(id) on delete cascade,
  monto      bigint not null,
  motivo     text not null,
  saldo      bigint not null,
  creado_en  timestamptz not null default now()
);

create index casino_movimientos_por_usuario
  on public.casino_movimientos (usuario_id, creado_en desc);

alter table public.casino_billeteras  enable row level security;
alter table public.casino_movimientos enable row level security;

create policy casino_billeteras_propia on public.casino_billeteras
  for select to authenticated using (usuario_id = auth.uid());
create policy casino_movimientos_propios on public.casino_movimientos
  for select to authenticated using (usuario_id = auth.uid());

-- Nadie escribe directo: todo pasa por las funciones de abajo.
revoke all on public.casino_billeteras, public.casino_movimientos
  from anon, authenticated;
grant select on public.casino_billeteras, public.casino_movimientos
  to authenticated;

-- ----------------------------------------------------------------------------
-- 2 · Mover fichas
-- ----------------------------------------------------------------------------
-- Mueve fichas de una billetera; si no existe, nace con las de regalo. Con
-- p_estricto no deja quedar en negativo: avisa que no alcanzan (sentarse al
-- poker). Sin el, lo que falte se pierde en cero: una mano del telefono que
-- llega tarde, cuando otro telefono ya gasto esas fichas. Un lote repetido
-- no se aplica dos veces.
create or replace function public.casino_mover(
  p_usuario  uuid,
  p_monto    bigint,
  p_motivo   text,
  p_lote     uuid default null,
  p_estricto boolean default false
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lote   uuid := coalesce(p_lote, gen_random_uuid());
  v_fichas bigint;
  v_nuevas bigint;
begin
  -- Una cuenta que se esta borrando ya no tiene donde cobrar.
  if not exists (select 1 from public.profiles where id = p_usuario) then
    return 0;
  end if;

  insert into public.casino_billeteras (usuario_id) values (p_usuario)
  on conflict (usuario_id) do nothing;
  select fichas into v_fichas
    from public.casino_billeteras where usuario_id = p_usuario for update;

  -- El mismo lote otra vez (el telefono reintento): ya se aplico.
  if exists (select 1 from public.casino_movimientos where id = v_lote) then
    return v_fichas;
  end if;

  v_nuevas := v_fichas + p_monto;
  if v_nuevas < 0 then
    if p_estricto then
      raise exception 'FICHAS_INSUFICIENTES: tienes %', v_fichas
        using errcode = '22023';
    end if;
    v_nuevas := 0;
  end if;

  update public.casino_billeteras
     set fichas = v_nuevas, actualizada_en = now()
   where usuario_id = p_usuario;
  insert into public.casino_movimientos (id, usuario_id, monto, motivo, saldo)
  values (v_lote, p_usuario, v_nuevas - v_fichas, p_motivo, v_nuevas);
  return v_nuevas;
end;
$$;

-- Lo que llama el telefono: manda lo que cambio desde la ultima vez (p_delta,
-- con su lote) y recibe cuantas tiene, y cuantas tiene sentado al poker. La
-- primera vez manda ademas las que tenia guardadas (p_inicial): reemplazan a
-- las de regalo con que nacio la billetera, y lo que paso en el poker
-- mientras tanto se respeta.
create or replace function public.casino_sincronizar(
  p_lote    uuid,
  p_delta   bigint default 0,
  p_inicial bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  -- Un numero sano: uno roto en el telefono no puede desbordar la cuenta.
  c_tope    constant bigint := 1000000000000;
  v_yo      uuid := auth.uid();
  v_migrada boolean;
  v_delta   bigint := least(greatest(coalesce(p_delta, 0), -c_tope), c_tope);
  v_mesa    record;
begin
  if v_yo is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  if p_lote is null then
    raise exception 'LOTE_INVALIDO' using errcode = '22023';
  end if;

  insert into public.casino_billeteras (usuario_id) values (v_yo)
  on conflict (usuario_id) do nothing;
  select migrada into v_migrada
    from public.casino_billeteras where usuario_id = v_yo for update;

  if not v_migrada then
    update public.casino_billeteras set migrada = true where usuario_id = v_yo;
    if p_inicial is not null then
      v_delta := least(greatest(p_inicial, 0), c_tope) - 1000;
    end if;
  end if;

  if v_delta <> 0 or not v_migrada then
    perform public.casino_mover(v_yo, v_delta, 'telefono', p_lote);
  end if;

  select s.nombre, a.fichas into v_mesa
    from public.poker_asientos a
    join public.poker_salas s on s.id = a.sala_id
   where a.usuario_id = v_yo;

  return jsonb_build_object(
    'fichas', (select fichas from public.casino_billeteras where usuario_id = v_yo),
    'en_mesa', coalesce(v_mesa.fichas, 0),
    'mesa', v_mesa.nombre
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 3 · El poker, con las fichas de la billetera
-- ----------------------------------------------------------------------------
alter table public.poker_salas add column version bigint not null default 0;
alter table public.poker_asientos add column afuera_desde timestamptz;
update public.poker_asientos set afuera_desde = now() where afuera;

-- Algo cambio en la mesa: la app que la mira se entera por esta fila.
create or replace function public.poker_tocar(p_sala uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.poker_salas
     set version = version + 1, actividad_en = now()
   where id = p_sala;
$$;

-- Las fichas de un asiento vuelven a la billetera cuando el asiento se va.
create or replace function public.poker_asiento_cobrar()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.fichas > 0 then
    perform public.casino_mover(old.usuario_id, old.fichas, 'poker_salida');
  end if;
  return old;
end;
$$;

create trigger poker_asientos_cobrar
  before delete on public.poker_asientos
  for each row execute function public.poker_asiento_cobrar();

-- Con cuantas fichas se sienta: las pedidas, o las de la mesa (o todas las
-- que tenga, si no le alcanzan). Entre 20 y 100 ciegas grandes, y sacadas de
-- la billetera.
create or replace function public.poker_cobrar_entrada(
  p_sala   public.poker_salas,
  p_fichas integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_yo     uuid := auth.uid();
  v_minima integer := p_sala.ciega_grande * 20;
  v_maxima integer := p_sala.ciega_grande * 100;
  v_tengo  bigint;
  v_compra integer;
begin
  insert into public.casino_billeteras (usuario_id) values (v_yo)
  on conflict (usuario_id) do nothing;
  select fichas into v_tengo
    from public.casino_billeteras where usuario_id = v_yo for update;

  v_compra := coalesce(p_fichas, least(p_sala.fichas_iniciales, v_tengo)::integer);
  if p_fichas is null and v_compra < v_minima then
    raise exception 'FICHAS_INSUFICIENTES: tienes %, la mesa pide %',
      v_tengo, v_minima
      using errcode = '22023';
  end if;
  if v_compra < v_minima or v_compra > v_maxima then
    raise exception 'COMPRA_INVALIDA: entre % y %', v_minima, v_maxima
      using errcode = '22023';
  end if;

  perform public.casino_mover(v_yo, -v_compra, 'poker_entrada', null, true);
  return v_compra;
end;
$$;

-- Se sienta en el primer lugar libre con fichas de su billetera. Si estaba en
-- otra mesa, primero se levanta de esa (y esas fichas vuelven a la billetera).
drop function public.poker_sentarse(uuid);
create function public.poker_sentarse(
  p_sala   uuid,
  p_fichas integer default null
)
returns smallint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sala   public.poker_salas;
  v_otra   uuid;
  v_pos    smallint;
  v_compra integer;
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

  v_compra := public.poker_cobrar_entrada(v_sala, p_fichas);
  insert into public.poker_asientos (sala_id, posicion, usuario_id, fichas)
  values (p_sala, v_pos, auth.uid(), v_compra);
  perform public.poker_tocar(p_sala);
  return v_pos;
end;
$$;

-- Crea una mesa y sienta a quien la crea. Ciegas: 5/10, 10/20, 25/50, 50/100
-- o 100/200; la entrada sugerida es de 50 ciegas grandes.
drop function public.poker_crear_sala(text, integer);
create function public.poker_crear_sala(
  p_nombre       text,
  p_ciega_grande integer,
  p_fichas       integer default null
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
  if p_ciega_grande not in (10, 20, 50, 100, 200) then
    raise exception 'CIEGAS_INVALIDAS' using errcode = '22023';
  end if;

  insert into public.poker_salas
    (nombre, creador_id, ciega_chica, ciega_grande, fichas_iniciales)
  values
    (v_nombre, auth.uid(), p_ciega_grande / 2, p_ciega_grande, p_ciega_grande * 50)
  returning id into v_sala;

  perform public.poker_sentarse(v_sala, p_fichas);
  return v_sala;
end;
$$;

-- Se levanta de la mesa: si estaba en una mano, se retira. Sus fichas
-- vuelven a su billetera (el disparador del asiento). La mesa que queda
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
  else
    perform public.poker_tocar(p_sala);
  end if;
end;
$$;

-- Sin fichas en la mesa: compra de nuevo con las de su billetera, siempre
-- que no este en una mano.
drop function public.poker_recargar(uuid);
create function public.poker_recargar(
  p_sala   uuid,
  p_fichas integer default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sala   public.poker_salas;
  v_fichas integer;
  v_compra integer;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  select * into v_sala from public.poker_salas where id = p_sala for update;
  if v_sala.id is null then
    raise exception 'SALA_INEXISTENTE' using errcode = '22023';
  end if;
  if exists (
    select 1
      from public.poker_jugadores j
      join public.poker_manos m on m.id = j.mano_id
     where m.sala_id = p_sala and m.fase <> 'terminada'
       and j.usuario_id = auth.uid() and not j.retirado
  ) then
    raise exception 'EN_UNA_MANO: espera a que termine' using errcode = '22023';
  end if;

  select fichas into v_fichas
    from public.poker_asientos
   where sala_id = p_sala and usuario_id = auth.uid()
     for update;
  if v_fichas is null then
    raise exception 'NO_ESTAS_SENTADO' using errcode = '42501';
  end if;
  if v_fichas > 0 then
    return;
  end if;

  v_compra := public.poker_cobrar_entrada(v_sala, p_fichas);
  update public.poker_asientos
     set fichas = v_compra, afuera = false, vencidos = 0, afuera_desde = null
   where sala_id = p_sala and usuario_id = auth.uid();
  perform public.poker_tocar(p_sala);
end;
$$;

-- Vuelve a entrar en las manos despues de quedar sentado afuera.
create or replace function public.poker_volver(p_sala uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.poker_asientos
     set afuera = false, vencidos = 0, afuera_desde = null
   where sala_id = p_sala and usuario_id = auth.uid();
  if found then
    perform public.poker_tocar(p_sala);
  end if;
end;
$$;

-- Reparte una mano nueva si se puede (igual que en la 59, y ahora avisa).
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

  update public.poker_manos
     set apuesta = (select max(apuesta_ronda)
                      from public.poker_jugadores where mano_id = v_mano),
         turno = v_grande
   where id = v_mano;

  perform public.poker_avanzar(v_mano);
  perform public.poker_tocar(p_sala);
  return true;
end;
$$;

-- Una jugada. Devuelve como quedo la mesa, para quien jugo.
drop function public.poker_jugar(uuid, text, integer);
create function public.poker_jugar(
  p_sala   uuid,
  p_accion text,
  p_monto  integer default 0
)
returns jsonb
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
  perform public.poker_tocar(p_sala);
  return public.poker_estado(p_sala);
end;
$$;

-- Si el turno vencio, pasa (si puede) o se retira por quien no jugo. Dos
-- turnos vencidos seguidos y queda sentado afuera, desde ahora.
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

  update public.poker_asientos
     set vencidos = vencidos + 1,
         afuera_desde = case
           when not afuera and vencidos + 1 >= 2 then now()
           else afuera_desde
         end,
         afuera = afuera or vencidos + 1 >= 2
   where sala_id = p_sala and usuario_id = v_jugador.usuario_id;
  perform public.poker_tocar(p_sala);
  return true;
end;
$$;

-- Todo lo que el que pregunta puede ver de una mesa (como en la 60), y
-- ademas su billetera y entre cuantas fichas puede sentarse.
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
    'sala', (
      select to_jsonb(s) || jsonb_build_object(
               'compra_minima', s.ciega_grande * 20,
               'compra_maxima', s.ciega_grande * 100)
        from public.poker_salas s where s.id = p_sala
    ),
    'yo', (select posicion from public.poker_asientos
            where sala_id = p_sala and usuario_id = auth.uid()),
    'billetera', (select fichas from public.casino_billeteras
                   where usuario_id = auth.uid()),
    'asientos', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'posicion', a.posicion,
               'usuario_id', a.usuario_id,
               'nombre', p.full_name,
               'avatar_path', p.avatar_path,
               'fichas', a.fichas,
               'afuera', a.afuera,
               'egresado', p.es_egresado
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

-- Cada minuto: los turnos vencidos que nadie vencio, quienes quedaron
-- sentados afuera hace rato y las mesas abandonadas. Ninguna ficha se pierde:
-- la mano que quedo a medias le devuelve a cada uno lo que puso, y los
-- asientos que se van le devuelven sus fichas a su billetera.
create or replace function public.poker_mantenimiento()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sala    uuid;
  v_asiento record;
  v_mano    public.poker_manos;
begin
  for v_sala in
    select sala_id from public.poker_manos
     where fase <> 'terminada' and vence_en < now() - interval '5 seconds'
  loop
    perform public.poker_vencer_turno(v_sala);
  end loop;

  -- Sentado afuera mas de 20 minutos (y fuera de una mano): se levanta solo.
  for v_asiento in
    select a.sala_id, a.usuario_id
      from public.poker_asientos a
     where a.afuera
       and a.afuera_desde < now() - interval '20 minutes'
       and not exists (
         select 1
           from public.poker_jugadores j
           join public.poker_manos m on m.id = j.mano_id
          where m.sala_id = a.sala_id and m.fase <> 'terminada'
            and j.usuario_id = a.usuario_id and not j.retirado
       )
  loop
    delete from public.poker_asientos
     where sala_id = v_asiento.sala_id and usuario_id = v_asiento.usuario_id;
    if exists (select 1 from public.poker_asientos where sala_id = v_asiento.sala_id) then
      perform public.poker_tocar(v_asiento.sala_id);
    else
      delete from public.poker_salas where id = v_asiento.sala_id;
    end if;
  end loop;

  -- Mesas abandonadas: la mano a medias le devuelve a cada uno lo suyo, y
  -- al cerrarse la mesa los asientos vuelven a las billeteras.
  for v_mano in
    select m.*
      from public.poker_manos m
      join public.poker_salas s on s.id = m.sala_id
     where m.fase <> 'terminada'
       and s.actividad_en < now() - interval '3 hours'
  loop
    update public.poker_asientos a
       set fichas = a.fichas + j.aportado
      from public.poker_jugadores j
     where j.mano_id = v_mano.id
       and a.sala_id = v_mano.sala_id
       and a.usuario_id = j.usuario_id;
    update public.poker_manos
       set fase = 'terminada', turno = null, vence_en = null,
           resultado = '[]', terminada_en = now()
     where id = v_mano.id;
  end loop;
  delete from public.poker_salas where actividad_en < now() - interval '3 hours';

  delete from public.poker_manos
   where fase = 'terminada' and terminada_en < now() - interval '6 hours';
  delete from public.casino_movimientos
   where creado_en < now() - interval '90 days';
end;
$$;

-- ----------------------------------------------------------------------------
-- 4 · Quien puede llamar que
-- ----------------------------------------------------------------------------
revoke all on function
  public.casino_mover(uuid, bigint, text, uuid, boolean),
  public.casino_sincronizar(uuid, bigint, bigint),
  public.poker_tocar(uuid),
  public.poker_asiento_cobrar(),
  public.poker_cobrar_entrada(public.poker_salas, integer),
  public.poker_sentarse(uuid, integer),
  public.poker_crear_sala(text, integer, integer),
  public.poker_recargar(uuid, integer),
  public.poker_jugar(uuid, text, integer)
from public, anon, authenticated;

grant execute on function
  public.casino_sincronizar(uuid, bigint, bigint),
  public.poker_sentarse(uuid, integer),
  public.poker_crear_sala(text, integer, integer),
  public.poker_recargar(uuid, integer),
  public.poker_jugar(uuid, text, integer)
to authenticated;

-- ----------------------------------------------------------------------------
-- 5 · Pruebas: si algo no da lo esperado, no se aplica nada
-- ----------------------------------------------------------------------------
do $$
declare
  v_a       uuid := gen_random_uuid();
  v_b       uuid := gen_random_uuid();
  v_c       uuid := gen_random_uuid();
  v_lote    uuid := gen_random_uuid();
  v_carrera text;
  v_sala    uuid;
  v_otra    uuid;
  v_mano    public.poker_manos;
  v_r       jsonb;
  v_n       bigint;
  v_version bigint;
  v_total   bigint;

  -- Todas las fichas de los tres: billeteras, asientos y lo que esta en un
  -- bote en juego. Nunca cambia por jugar: solo por el telefono.
  c_suma constant text := $q$
    select coalesce((select sum(fichas) from public.casino_billeteras
                      where usuario_id = any($1)), 0)
         + coalesce((select sum(fichas) from public.poker_asientos
                      where usuario_id = any($1)), 0)
         + coalesce((select sum(j.aportado)
                       from public.poker_jugadores j
                       join public.poker_manos m on m.id = j.mano_id
                      where m.fase <> 'terminada' and j.usuario_id = any($1)), 0)
  $q$;
begin
  begin
    insert into public.institutional_domains (domain, label)
    values ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA')
    on conflict (domain) do nothing;
    select id into v_carrera from public.careers where is_active
     order by sort_order limit 1;
    if v_carrera is null then
      insert into public.careers (id, name, faculty)
      values ('prueba_billetera', 'Prueba', 'Prueba')
      returning id into v_carrera;
    end if;
    insert into auth.users (id, email) values
      (v_a, 'a2024119981@estudiantes.upsa.edu.bo'),
      (v_b, 'a2024119982@estudiantes.upsa.edu.bo'),
      (v_c, 'a2024119983@estudiantes.upsa.edu.bo');
    update public.profiles
       set full_name = case id when v_a then 'Ana Billetera'
                               when v_b then 'Beto Billetera'
                               else 'Caro Billetera' end,
           career_id = v_carrera, whatsapp = '59170000010',
           onboarding_completed = true
     where id in (v_a, v_b, v_c);

    -- La primera vez el telefono trae las suyas; un lote repetido no suma.
    perform set_config('request.jwt.claim.sub', v_a::text, true);
    v_r := public.casino_sincronizar(v_lote, 0, 5000);
    if (v_r ->> 'fichas')::bigint <> 5000 then
      raise exception 'no se trajeron las fichas del telefono: %', v_r;
    end if;
    v_r := public.casino_sincronizar(v_lote, 0, 5000);
    v_lote := gen_random_uuid();
    v_r := public.casino_sincronizar(v_lote, -300, 99999);
    v_r := public.casino_sincronizar(v_lote, -300, 99999);
    if (v_r ->> 'fichas')::bigint <> 4700 then
      raise exception 'un lote repetido conto dos veces (o no conto): %', v_r;
    end if;
    -- Lo que falte se queda en cero, sin romper.
    v_r := public.casino_sincronizar(gen_random_uuid(), -999999);
    if (v_r ->> 'fichas')::bigint <> 0 then
      raise exception 'la billetera quedo en %, no en cero', v_r;
    end if;
    v_r := public.casino_sincronizar(gen_random_uuid(), 5000);

    -- Beto nunca abrio el casino: su billetera nace al sentarse, con las de
    -- regalo, y se sienta con todas (1.000, lo que pide una mesa de 10/20).
    perform set_config('request.jwt.claim.sub', v_b::text, true);
    v_sala := public.poker_crear_sala('Mesa billetera', 20);
    if (select fichas from public.casino_billeteras where usuario_id = v_b) <> 0
       or (select fichas from public.poker_asientos where usuario_id = v_b) <> 1000 then
      raise exception 'la entrada no salio de la billetera';
    end if;
    -- Despues abre el casino con 3.000 en su telefono: esas reemplazan a las
    -- de regalo y las de la mesa siguen siendo suyas.
    v_r := public.casino_sincronizar(gen_random_uuid(), 0, 3000);
    if (v_r ->> 'fichas')::bigint <> 2000 or (v_r ->> 'en_mesa')::bigint <> 1000
       or v_r ->> 'mesa' <> 'Mesa billetera' then
      raise exception 'no se juntaron las del telefono con las de la mesa: %', v_r;
    end if;

    -- Entre 20 y 100 ciegas grandes, y con lo que se tiene.
    perform set_config('request.jwt.claim.sub', v_a::text, true);
    begin
      perform public.poker_sentarse(v_sala, 300);
      raise exception 'se sento con menos de 20 ciegas';
    exception when others then
      if sqlerrm not like 'COMPRA_INVALIDA%' then raise; end if;
    end;
    begin
      perform public.poker_sentarse(v_sala, 2001);
      raise exception 'se sento con mas de 100 ciegas';
    exception when others then
      if sqlerrm not like 'COMPRA_INVALIDA%' then raise; end if;
    end;
    perform set_config('request.jwt.claim.sub', v_c::text, true);
    v_r := public.casino_sincronizar(gen_random_uuid(), 0, 100);
    begin
      perform public.poker_sentarse(v_sala);
      raise exception 'se sento sin fichas suficientes';
    exception when others then
      if sqlerrm not like 'FICHAS_INSUFICIENTES%' then raise; end if;
    end;
    begin
      perform public.poker_sentarse(v_sala, 500);
      raise exception 'se sento con fichas que no tiene';
    exception when others then
      if sqlerrm not like 'FICHAS_INSUFICIENTES%' then raise; end if;
    end;
    if (select fichas from public.casino_billeteras where usuario_id = v_c) <> 100 then
      raise exception 'un intento fallido le cobro igual';
    end if;

    perform set_config('request.jwt.claim.sub', v_a::text, true);
    perform public.poker_sentarse(v_sala, 1500);
    if (select fichas from public.casino_billeteras where usuario_id = v_a) <> 3500 then
      raise exception 'la entrada de Ana no salio de su billetera';
    end if;
    execute c_suma into v_total using array[v_a, v_b, v_c];
    if v_total <> 8100 then
      raise exception 'antes de jugar ya no cierran las fichas: %', v_total;
    end if;

    -- Una mano entera: cada cosa sube la version, y la jugada devuelve la mesa.
    select version into v_version from public.poker_salas where id = v_sala;
    if not public.poker_empezar_mano(v_sala) then
      raise exception 'no se pudo repartir';
    end if;
    if (select version from public.poker_salas where id = v_sala) <= v_version then
      raise exception 'repartir no subio la version';
    end if;
    select * into v_mano from public.poker_manos
     where sala_id = v_sala and fase <> 'terminada';
    perform set_config('request.jwt.claim.sub',
      (select usuario_id::text from public.poker_jugadores
        where mano_id = v_mano.id and posicion = v_mano.turno), true);
    v_r := public.poker_jugar(v_sala, 'todo', 0);
    if (v_r -> 'sala' ->> 'version')::bigint
       <> (select version from public.poker_salas where id = v_sala) then
      raise exception 'la jugada no devolvio la mesa como quedo: %', v_r -> 'sala';
    end if;
    if v_r ->> 'billetera' is null or (v_r -> 'sala' ->> 'compra_minima')::int <> 400 then
      raise exception 'el estado no trae la billetera ni la entrada: %', v_r;
    end if;
    select * into v_mano from public.poker_manos where id = v_mano.id;
    perform set_config('request.jwt.claim.sub',
      (select usuario_id::text from public.poker_jugadores
        where mano_id = v_mano.id and posicion = v_mano.turno), true);
    perform public.poker_jugar(v_sala, 'igualar', 0);
    if (select fase from public.poker_manos where id = v_mano.id) <> 'terminada' then
      raise exception 'la mano no termino';
    end if;
    execute c_suma into v_total using array[v_a, v_b, v_c];
    if v_total <> 8100 then
      raise exception 'jugando aparecieron o se perdieron fichas: %', v_total;
    end if;

    -- Al levantarse, todo lo que queda en la mesa vuelve a la billetera.
    perform set_config('request.jwt.claim.sub', v_a::text, true);
    v_n := (select fichas from public.casino_billeteras where usuario_id = v_a)
         + (select fichas from public.poker_asientos where usuario_id = v_a);
    perform public.poker_levantarse(v_sala);
    if (select fichas from public.casino_billeteras where usuario_id = v_a) <> v_n then
      raise exception 'Ana no recupero sus fichas al levantarse';
    end if;
    -- Beto se queda solo; si quedo en cero, recarga de su billetera.
    perform set_config('request.jwt.claim.sub', v_b::text, true);
    if (select fichas from public.poker_asientos where usuario_id = v_b) = 0 then
      perform public.poker_recargar(v_sala, 400);
      if (select fichas from public.poker_asientos where usuario_id = v_b) <> 400 then
        raise exception 'la recarga no tomo de la billetera';
      end if;
    end if;
    perform public.poker_levantarse(v_sala);
    if exists (select 1 from public.poker_salas where id = v_sala) then
      raise exception 'la mesa vacia no se cerro';
    end if;
    execute c_suma into v_total using array[v_a, v_b, v_c];
    if v_total <> 8100 then
      raise exception 'al levantarse aparecieron o se perdieron fichas: %', v_total;
    end if;

    -- Irse a mitad de una mano: se retira, el bote es de quien queda y lo
    -- que no aposto vuelve a su billetera.
    perform set_config('request.jwt.claim.sub', v_a::text, true);
    v_sala := public.poker_crear_sala('Mesa a medias', 20, 1000);
    perform set_config('request.jwt.claim.sub', v_b::text, true);
    perform public.poker_sentarse(v_sala, 1000);
    if not public.poker_empezar_mano(v_sala) then
      raise exception 'no se pudo repartir la segunda';
    end if;
    perform public.poker_levantarse(v_sala);
    select * into v_mano from public.poker_manos where sala_id = v_sala;
    if v_mano.fase <> 'terminada' or (v_mano.resultado -> 0 ->> 'monto')::int <> v_mano.bote then
      raise exception 'el bote no quedo para quien se quedo: %', v_mano;
    end if;
    execute c_suma into v_total using array[v_a, v_b, v_c];
    if v_total <> 8100 then
      raise exception 'irse a mitad de mano cambio el total: %', v_total;
    end if;

    -- Una mesa abandonada con una mano a medias: cada uno recupera lo suyo.
    perform set_config('request.jwt.claim.sub', v_b::text, true);
    perform public.poker_sentarse(v_sala, 1000);
    update public.poker_manos set terminada_en = now() - interval '1 minute'
     where sala_id = v_sala;
    if not public.poker_empezar_mano(v_sala) then
      raise exception 'no se pudo repartir la tercera';
    end if;
    update public.poker_salas set actividad_en = now() - interval '4 hours'
     where id = v_sala;
    perform public.poker_mantenimiento();
    if exists (select 1 from public.poker_salas where id = v_sala) then
      raise exception 'la limpieza no cerro la mesa abandonada';
    end if;
    execute c_suma into v_total using array[v_a, v_b, v_c];
    if v_total <> 8100 then
      raise exception 'cerrar la mesa abandonada cambio el total: %', v_total;
    end if;

    -- Quien queda sentado afuera mas de 20 minutos se levanta solo.
    perform set_config('request.jwt.claim.sub', v_a::text, true);
    v_otra := public.poker_crear_sala('Mesa de los ausentes', 20, 400);
    perform set_config('request.jwt.claim.sub', v_b::text, true);
    perform public.poker_sentarse(v_otra, 400);
    update public.poker_asientos
       set afuera = true, afuera_desde = now() - interval '21 minutes'
     where usuario_id = v_a;
    select version into v_version from public.poker_salas where id = v_otra;
    perform public.poker_mantenimiento();
    if exists (select 1 from public.poker_asientos where usuario_id = v_a)
       or not exists (select 1 from public.poker_asientos where usuario_id = v_b)
       or (select version from public.poker_salas where id = v_otra) <= v_version then
      raise exception 'no se levanto a quien estaba afuera';
    end if;
    execute c_suma into v_total using array[v_a, v_b, v_c];
    if v_total <> 8100 then
      raise exception 'levantar al ausente cambio el total: %', v_total;
    end if;

    -- Lo de adentro no lo llama nadie de afuera.
    if has_function_privilege('authenticated',
         'public.casino_mover(uuid, bigint, text, uuid, boolean)', 'execute')
       or has_function_privilege('authenticated',
         'public.poker_cobrar_entrada(public.poker_salas, integer)', 'execute')
       or has_function_privilege('anon',
         'public.casino_sincronizar(uuid, bigint, bigint)', 'execute')
       or not has_function_privilege('authenticated',
         'public.casino_sincronizar(uuid, bigint, bigint)', 'execute')
       or not has_function_privilege('authenticated',
         'public.poker_jugar(uuid, text, integer)', 'execute') then
      raise exception 'los permisos de las funciones quedaron mal';
    end if;

    raise exception 'PRUEBAS_OK';
  exception when raise_exception then
    if sqlerrm <> 'PRUEBAS_OK' then
      raise exception 'No se aplico nada. %', sqlerrm;
    end if;
  end;

  if exists (select 1 from auth.users where id in (v_a, v_b, v_c)) then
    raise exception 'quedaron datos de prueba';
  end if;

  raise notice 'Billetera del casino probada: todo bien.';
end $$;

commit;
