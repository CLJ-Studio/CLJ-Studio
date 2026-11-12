"""Corre las pruebas de la logica de pedidos en un Postgres local, sin tocar
Supabase.

Arma una base nueva con TODAS las migraciones en orden (y seed.sql, como
`supabase db reset`), y sobre ella corre:

  1. Cada pruebas_*.sql de esta carpeta (pedidos, errores de la app), cada
     uno dentro de una transaccion que se revierte.
  2. Las pruebas de concurrencia, que un .sql no puede hacer: dos conexiones
     aceptando A LA VEZ. Una sola conexion es secuencial por definicion, asi
     que ahi la sobreventa nunca se ve aunque exista.

Uso, antes de subir cambios de SQL:

    python Backend/tests/correr_pruebas.py

Necesita Python 3.11+ y psycopg (`pip install "psycopg[binary]"`). La primera
vez baja Postgres 17 portatil de Maven Central (unos 22 MB, verificado por
sha1) a Backend/tests/.postgres/, que git ignora. La base vive en una carpeta
temporal y se borra al terminar.

Supabase trae cosas que un Postgres pelado no tiene (auth, storage, pg_cron,
pg_net, los roles, la publicacion de realtime): aqui van imitaciones minimas,
lo justo para que las migraciones corran. Lo que se prueba es la logica de
pedidos, no esas piezas.
"""

from __future__ import annotations

import contextlib
import hashlib
import io
import json
import platform
import re
import shutil
import socket
import subprocess
import sys
import tarfile
import tempfile
import threading
import time
import urllib.request
import uuid
import zipfile
from pathlib import Path

import psycopg

AQUI = Path(__file__).resolve().parent
MIGRACIONES = AQUI.parent / 'supabase' / 'migrations'
SEED = AQUI.parent / 'supabase' / 'seed.sql'
CACHE = AQUI / '.postgres'
VERSION = '17.6.0'

# ----------------------------------------------------------------------------
# Lo que Supabase trae y un Postgres pelado no
# ----------------------------------------------------------------------------
IMITACION_SUPABASE = r"""
create role anon nologin noinherit;
create role authenticated nologin noinherit;
create role service_role nologin noinherit bypassrls;
create role supabase_auth_admin nologin noinherit;
create role authenticator login noinherit;
grant anon, authenticated, service_role to authenticator;

-- Como en Supabase: las tablas nuevas de public quedan abiertas a los roles
-- de la API y la RLS es la que decide. Sin esto, una tabla sin politica de
-- UPDATE daria "permiso denegado" en vez de 0 filas.
--
-- Las FUNCIONES no: en este proyecto se ejecutan por el permiso de PUBLIC,
-- y un `revoke ... from public` las cierra. Comprobado el 2026-11-11 contra
-- produccion: sin sesion, restituir_stock responde "permission denied". Con
-- el permiso explicito que trae un Supabase recien creado, esta base diria
-- que media API esta abierta cuando no lo esta.
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;

create schema extensions;
grant usage on schema extensions to anon, authenticated, service_role;
create extension pgcrypto with schema extensions;

-- auth -----------------------------------------------------------------------
create schema auth;
grant usage on schema auth to anon, authenticated, service_role;
create table auth.users (
  instance_id uuid, id uuid primary key, aud varchar(255), role varchar(255),
  email varchar(255), encrypted_password varchar(255),
  email_confirmed_at timestamptz, invited_at timestamptz,
  confirmation_token varchar(255), confirmation_sent_at timestamptz,
  recovery_token varchar(255), recovery_sent_at timestamptz,
  email_change_token_new varchar(255), email_change varchar(255),
  email_change_sent_at timestamptz, last_sign_in_at timestamptz,
  raw_app_meta_data jsonb, raw_user_meta_data jsonb, is_super_admin boolean,
  created_at timestamptz, updated_at timestamptz, phone text,
  phone_confirmed_at timestamptz, banned_until timestamptz,
  deleted_at timestamptz, is_anonymous boolean not null default false
);
create table auth.identities (
  id uuid primary key default gen_random_uuid(), user_id uuid not null,
  provider text, provider_id text, identity_data jsonb, email text,
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create function auth.uid() returns uuid language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
  )::uuid
$$;
create function auth.role() returns text language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'
  )
$$;
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb
$$;
create function auth.email() returns text language sql stable as $$
  select auth.jwt() ->> 'email'
$$;
grant execute on all functions in schema auth to anon, authenticated, service_role;

-- storage --------------------------------------------------------------------
create schema storage;
grant usage on schema storage to anon, authenticated, service_role;
create table storage.buckets (
  id text primary key, name text not null, owner uuid,
  public boolean default false, avif_autodetection boolean default false,
  file_size_limit bigint, allowed_mime_types text[],
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id), name text, owner uuid,
  owner_id text, metadata jsonb, version text,
  created_at timestamptz default now(), updated_at timestamptz default now(),
  last_accessed_at timestamptz default now(),
  path_tokens text[] generated always as (string_to_array(name, '/')) stored
);
alter table storage.objects enable row level security;
grant all on storage.buckets, storage.objects to anon, authenticated, service_role;
create function storage.foldername(name text) returns text[]
language sql immutable as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
$$;
create function storage.filename(name text) returns text
language sql immutable as $$
  select (string_to_array(name, '/'))[array_length(string_to_array(name, '/'), 1)]
$$;
create function storage.extension(name text) returns text
language sql immutable as $$
  select reverse(split_part(reverse(storage.filename(name)), '.', 1))
$$;

-- pg_cron: se anota, no se corre ---------------------------------------------
create schema cron;
create table cron.job (
  jobid bigserial primary key, schedule text, command text,
  nodename text default 'localhost', nodeport integer default 5432,
  database text default current_database(), username text default current_user,
  active boolean default true, jobname text
);
create function cron.schedule(job_name text, schedule text, command text)
returns bigint language sql as $$
  insert into cron.job (jobname, schedule, command)
  values (job_name, schedule, command) returning jobid
$$;
create function cron.schedule(schedule text, command text)
returns bigint language sql as $$
  insert into cron.job (schedule, command) values (schedule, command)
  returning jobid
$$;
create function cron.unschedule(job_name text) returns boolean
language sql as $$
  with borrados as (delete from cron.job where jobname = job_name returning 1)
  select exists (select 1 from borrados)
$$;
create function cron.unschedule(job_id bigint) returns boolean
language sql as $$
  with borrados as (delete from cron.job where jobid = job_id returning 1)
  select exists (select 1 from borrados)
$$;

-- pg_net: no sale nada a la red ------------------------------------------------
create schema net;
create function net.http_post(
  url text, body jsonb default '{}'::jsonb, params jsonb default '{}'::jsonb,
  headers jsonb default '{"Content-Type": "application/json"}'::jsonb,
  timeout_milliseconds integer default 5000
) returns bigint language sql as $$ select 0::bigint $$;
create function net.http_get(
  url text, params jsonb default '{}'::jsonb,
  headers jsonb default '{}'::jsonb, timeout_milliseconds integer default 5000
) returns bigint language sql as $$ select 0::bigint $$;
grant usage on schema net to anon, authenticated, service_role;

create publication supabase_realtime;
"""

# Las extensiones que Supabase trae y aqui se imitan arriba.
_EXTENSIONES_IMITADAS = re.compile(
    r'create\s+extension\s+if\s+not\s+exists\s+"?(pg_cron|pg_net)"?[^;]*;',
    re.IGNORECASE,
)


def _binarios() -> Path:
    """La carpeta bin/ de Postgres; la baja la primera vez."""
    maquina = platform.machine().lower()
    if sys.platform == 'win32':
        sistema = 'windows-amd64'
    elif sys.platform == 'darwin':
        sistema = 'darwin-arm64v8' if maquina == 'arm64' else 'darwin-amd64'
    else:
        sistema = 'linux-arm64v8' if maquina in ('aarch64', 'arm64') else 'linux-amd64'
    destino = CACHE / f'{VERSION}-{sistema}'
    ejecutable = 'initdb.exe' if sys.platform == 'win32' else 'initdb'
    encontrados = list(destino.rglob(ejecutable)) if destino.exists() else []
    if encontrados:
        return encontrados[0].parent

    artefacto = f'embedded-postgres-binaries-{sistema}'
    url = (f'https://repo1.maven.org/maven2/io/zonky/test/postgres/'
           f'{artefacto}/{VERSION}/{artefacto}-{VERSION}.jar')
    print(f'Bajando Postgres {VERSION} ({sistema})...')
    with urllib.request.urlopen(url) as respuesta:
        jar = respuesta.read()
    with urllib.request.urlopen(url + '.sha1') as respuesta:
        esperado = respuesta.read().decode().split()[0]
    real = hashlib.sha1(jar).hexdigest()
    if real != esperado:
        sys.exit(f'El sha1 de Postgres no coincide ({real} != {esperado})')
    with zipfile.ZipFile(io.BytesIO(jar)) as z:
        nombre = next(n for n in z.namelist() if n.endswith('.txz'))
        comprimido = z.read(nombre)
    destino.mkdir(parents=True, exist_ok=True)
    with tarfile.open(fileobj=io.BytesIO(comprimido), mode='r:xz') as t:
        t.extractall(destino, filter='data')
    return next(destino.rglob(ejecutable)).parent


def _puerto_libre() -> int:
    with socket.socket() as s:
        s.bind(('localhost', 0))
        return s.getsockname()[1]


class Fallo(Exception):
    pass


def afirmar(condicion: bool, mensaje: str) -> None:
    if not condicion:
        raise Fallo(mensaje)
    print(f'  OK   {mensaje}')


# ----------------------------------------------------------------------------
# Montaje de la base
# ----------------------------------------------------------------------------
def armar_base(con: psycopg.Connection) -> None:
    con.execute(IMITACION_SUPABASE)
    archivos = sorted(MIGRACIONES.glob('*.sql'))
    for archivo in archivos:
        sql = _EXTENSIONES_IMITADAS.sub('', archivo.read_text(encoding='utf-8'))
        try:
            con.execute(sql)
        except psycopg.Error as error:
            raise Fallo(f'La migracion {archivo.name} no corre: {error}') from error
    print(f'  OK   {len(archivos)} migraciones aplicadas en orden')
    if SEED.exists():
        con.execute(SEED.read_text(encoding='utf-8'))
        print('  OK   seed.sql')


def correr_pruebas_sql(con: psycopg.Connection) -> None:
    """Cada pruebas_*.sql de esta carpeta, en orden."""
    for archivo in sorted(AQUI.glob('pruebas_*.sql')):
        # Las lineas de psql (\set ...) no son SQL.
        sql = '\n'.join(
            linea for linea in archivo.read_text(encoding='utf-8').splitlines()
            if not linea.lstrip().startswith('\\')
        )
        try:
            con.execute(sql)
        except psycopg.Error as error:
            raise Fallo(f'{archivo.name}: {error}') from error


# ----------------------------------------------------------------------------
# Concurrencia: dos conexiones a la vez
# ----------------------------------------------------------------------------
def _como(con: psycopg.Connection, usuario: uuid.UUID) -> None:
    """Lo que hace el JWT en produccion, dentro de la transaccion abierta."""
    con.execute(
        "select set_config('request.jwt.claims', %s, true),"
        " set_config('role', 'authenticated', true)",
        (json.dumps({'sub': str(usuario)}),),
    )


def _como_en_transaccion(con, usuario, sql, parametros=()):
    with con.transaction():
        _como(con, usuario)
        return con.execute(sql, parametros).fetchone()


def _usuario(admin: psycopg.Connection, numero: int) -> uuid.UUID:
    id_ = uuid.uuid4()
    admin.execute(
        """insert into auth.users (id, email, raw_user_meta_data, instance_id,
                                   aud, role, created_at, updated_at)
           values (%s, %s, %s, '00000000-0000-0000-0000-000000000000',
                   'authenticated', 'authenticated', now(), now())""",
        (id_, f'a20209{numero:05d}@estudiantes.upsa.edu.bo',
         json.dumps({'full_name': f'Persona {numero}'})),
    )
    admin.execute(
        """update public.profiles
              set full_name = 'Persona de prueba', whatsapp = '59170000000',
                  career_id = (select id from public.careers order by id limit 1),
                  onboarding_completed = true
            where id = %s""",
        (id_,),
    )
    return id_


def _a_la_vez(dsn: str, admin, vendedor, pedido_1, pedido_2) -> str | None:
    """El vendedor acepta [pedido_1] y, sin que esa transaccion termine,
    [pedido_2] desde otra conexion. Devuelve el error del segundo (o None)."""
    primera = psycopg.connect(dsn)
    segunda = psycopg.connect(dsn)
    try:
        _como(primera, vendedor)
        primera.execute('select public.aceptar_pedido(%s)', (pedido_1,))

        pid = segunda.info.backend_pid
        resultado: dict[str, str | None] = {}

        def aceptar_la_segunda():
            try:
                _como(segunda, vendedor)
                segunda.execute('select public.aceptar_pedido(%s)', (pedido_2,))
                segunda.commit()
                resultado['error'] = None
            except psycopg.Error as error:
                segunda.rollback()
                resultado['error'] = str(error)

        hilo = threading.Thread(target=aceptar_la_segunda)
        hilo.start()
        # Que la segunda de verdad este esperando a la primera: si llegara
        # despues de que la primera termine, la prueba seria secuencial.
        esperando = False
        for _ in range(200):
            fila = admin.execute(
                'select wait_event_type from pg_stat_activity where pid = %s',
                (pid,),
            ).fetchone()
            if fila and fila[0] == 'Lock':
                esperando = True
                break
            time.sleep(0.025)
        afirmar(esperando, 'la segunda aceptacion quedo esperando a la primera')
        primera.commit()
        hilo.join(15)
        afirmar(not hilo.is_alive(), 'la segunda aceptacion termino')
        return resultado['error']
    finally:
        primera.close()
        segunda.close()


def correr_pruebas_concurrencia(dsn: str, admin: psycopg.Connection) -> None:
    vendedor = _usuario(admin, 1)
    compradora = _usuario(admin, 2)
    comprador = _usuario(admin, 3)
    local = admin.execute(
        """insert into public.stores (owner_id, name, description, category_id,
                                      emoji, delivery_cost, is_open, is_active)
           values (%s, 'Local concurrente', 'Pruebas', 'comida', '🍽️', 0, true, true)
           returning id""",
        (vendedor,),
    ).fetchone()[0]

    def producto(stock):
        return admin.execute(
            """insert into public.products (store_id, name, description, price,
                                            emoji, stock, kind)
               values (%s, 'Sandwich', 'Pruebas', 10, '🥪', %s, 'producto')
               returning id""",
            (local, stock),
        ).fetchone()[0]

    def pedido(comprador_id, producto_id, cantidad):
        items = json.dumps([{'product_id': str(producto_id), 'quantity': cantidad}])
        return _como_en_transaccion(
            admin, comprador_id, 'select public.crear_pedido(%s::jsonb)', (items,)
        )[0]

    def stock(producto_id):
        return admin.execute(
            'select stock from public.products where id = %s', (producto_id,)
        ).fetchone()[0]

    def estado(pedido_id):
        return admin.execute(
            'select status::text from public.orders where id = %s', (pedido_id,)
        ).fetchone()[0]

    print()
    print('=== C1 · DOS PEDIDOS DEL ULTIMO ITEM, ACEPTADOS A LA VEZ ===')
    ultimo = producto(1)
    pedido_a = pedido(compradora, ultimo, 1)
    pedido_b = pedido(comprador, ultimo, 1)
    error = _a_la_vez(dsn, admin, vendedor, pedido_a, pedido_b)
    afirmar(error is not None and 'STOCK_INSUFICIENTE_AL_ACEPTAR' in error,
            'la segunda NO se acepta: no hay sobreventa')
    afirmar(stock(ultimo) == 0, 'el stock quedo en 0, no en -1')
    afirmar(estado(pedido_b) == 'solicitado', 'el segundo pedido sigue solicitado')

    print()
    print('=== C2 · EL MISMO PEDIDO ACEPTADO DOS VECES A LA VEZ (doble toque) ===')
    cinco = producto(5)
    pedido_c = pedido(compradora, cinco, 2)
    error = _a_la_vez(dsn, admin, vendedor, pedido_c, pedido_c)
    afirmar(error is not None and 'ESTADO_INVALIDO' in error,
            'la segunda aceptacion del mismo pedido se rechaza')
    afirmar(stock(cinco) == 3, 'el stock se desconto una sola vez (5 - 2 = 3)')


# ----------------------------------------------------------------------------
@contextlib.contextmanager
def base_local():
    """Una base nueva con todas las migraciones; se borra al salir.
    Entrega (dsn, conexion de admin)."""
    bin_ = _binarios()
    exe = '.exe' if sys.platform == 'win32' else ''
    datos = Path(tempfile.mkdtemp(prefix='pruebas_pg_'))
    puerto = _puerto_libre()
    dsn = f'host=localhost port={puerto} user=postgres dbname=postgres'
    subprocess.run(
        [str(bin_ / f'initdb{exe}'), '-D', str(datos / 'base'), '-U', 'postgres',
         '-E', 'UTF8', '--locale-provider=builtin', '--builtin-locale=C.UTF-8',
         '--auth=trust'],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    opciones = f'-p {puerto} -c listen_addresses=localhost'
    if sys.platform != 'win32':
        # El socket va en la carpeta temporal: el lugar de fabrica
        # (/var/run/postgresql) puede no existir o no ser escribible.
        opciones += f' -k {datos}'
    # Sin tuberias: el servidor hereda la salida, y con una tuberia abierta
    # quien lo lanzo se quedaria esperando a que termine.
    arranque = subprocess.run(
        [str(bin_ / f'pg_ctl{exe}'), '-D', str(datos / 'base'), '-l',
         str(datos / 'servidor.log'), '-o', opciones, '-w', 'start'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    if arranque.returncode != 0:
        registro = datos / 'servidor.log'
        print(registro.read_text(errors='replace') if registro.exists() else '')
        shutil.rmtree(datos, ignore_errors=True)
        raise Fallo('Postgres no arranco (arriba, su registro)')
    try:
        with psycopg.connect(dsn, autocommit=True) as admin:
            admin.add_notice_handler(
                lambda aviso: print(aviso.message_primary)
                if aviso.message_primary else None
            )
            print('=== BASE LOCAL ===')
            armar_base(admin)
            yield dsn, admin
    finally:
        subprocess.run(
            [str(bin_ / f'pg_ctl{exe}'), '-D', str(datos / 'base'), 'stop', '-m', 'fast'],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        shutil.rmtree(datos, ignore_errors=True)


def main() -> int:
    try:
        with base_local() as (dsn, admin):
            correr_pruebas_sql(admin)
            correr_pruebas_concurrencia(dsn, admin)
        print()
        print('TODAS LAS PRUEBAS PASARON')
        return 0
    except Fallo as fallo:
        print()
        print(f'FALLO: {fallo}')
        return 1


if __name__ == '__main__':
    sys.exit(main())
