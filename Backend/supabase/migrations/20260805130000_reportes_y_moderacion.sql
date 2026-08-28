-- ============================================================================
-- 43 · Reportar una publicacion, y alguien que lo lea
-- ============================================================================
-- El filtro de texto atrapa lo que se escribe mal a proposito, y nada mas. No
-- ve una foto ofensiva, ni un producto que dice ser una cosa y es otra, ni a
-- alguien vendiendo algo prohibido con un nombre inocente. Para todo eso hace
-- falta que lo diga una persona.
--
-- Reportar NO oculta la publicacion. Si bastara con reportar, tumbar a un
-- competidor costaria tres toques. Lo que hace es ponerla en una cola que un
-- administrador revisa.
--
-- POR QUE EL ROL VA EN SU PROPIA TABLA Y NO EN `profiles`:
-- la politica `perfil_propio_escritura` deja a cada quien actualizar SU fila
-- entera, sin distinguir columnas. Un `is_admin` ahi dentro se lo podria
-- conceder cualquiera con un update de una linea. `administradores` tiene RLS
-- activada y CERO politicas: desde la aplicacion no se puede ni leer ni
-- escribir. Solo se toca desde el editor SQL, a mano.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1 · Quien modera
-- ----------------------------------------------------------------------------
create table if not exists public.administradores (
  user_id   uuid primary key references public.profiles(id) on delete cascade,
  creado_en timestamptz not null default now(),
  nota      text
);

alter table public.administradores enable row level security;
-- Sin policies a proposito. Ver la cabecera.

revoke all on public.administradores from anon, authenticated;

-- Se consulta desde las funciones, que corren como owner. Devuelve booleano y
-- no la fila: la aplicacion no tiene por que saber quien mas es administrador.
create or replace function public.soy_administrador()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.administradores a where a.user_id = auth.uid()
  );
$$;

revoke all on function public.soy_administrador() from public;
grant execute on function public.soy_administrador() to authenticated;

-- ----------------------------------------------------------------------------
-- 2 · Los reportes
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'motivo_reporte') then
    create type public.motivo_reporte as enum (
      'ofensivo',   -- lenguaje o imagen que no deberia estar
      'enganoso',   -- no es lo que dice ser
      'prohibido',  -- droga, alcohol, armas
      'spam',       -- repetido o publicidad
      'otro'
    );
  end if;
  if not exists (select 1 from pg_type where typname = 'estado_reporte') then
    create type public.estado_reporte as enum (
      'pendiente', 'atendido', 'descartado'
    );
  end if;
end;
$$;

create table if not exists public.reportes_publicacion (
  id          uuid primary key default gen_random_uuid(),
  -- `set null` y no `cascade`: si el administrador borra la publicacion, el
  -- reporte tiene que sobrevivir. Si no, la unica prueba de lo que paso se va
  -- justo con el acto de moderar, y nadie puede ver que alguien reincide.
  product_id  uuid references public.products(id) on delete set null,
  owner_id    uuid not null references public.profiles(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,

  -- Copia de lo reportado, para que el reporte se entienda solo aunque la
  -- publicacion ya no exista.
  titulo      text not null,
  descripcion text not null default '',

  motivo      public.motivo_reporte not null,
  detalle     text,
  estado      public.estado_reporte not null default 'pendiente',
  creado_en   timestamptz not null default now(),
  resuelto_por uuid references public.profiles(id),
  resuelto_en  timestamptz,

  -- Una persona reporta una publicacion una vez. Sin esto, cinco toques del
  -- mismo dedo pareceria un escandalo.
  unique (product_id, reporter_id),
  constraint reportes_detalle_corto
    check (detalle is null or length(detalle) <= 300)
);

create index if not exists reportes_pendientes_idx
  on public.reportes_publicacion (creado_en desc) where estado = 'pendiente';
create index if not exists reportes_por_dueno_idx
  on public.reportes_publicacion (owner_id);

alter table public.reportes_publicacion enable row level security;
-- Sin policies: todo pasa por las funciones de abajo. Quien reporta no puede
-- leer los reportes de nadie, ni siquiera los propios: saber si algo ya fue
-- reportado ya es informacion sobre la moderacion.
revoke all on public.reportes_publicacion from anon, authenticated;

-- ----------------------------------------------------------------------------
-- 3 · Reportar
-- ----------------------------------------------------------------------------
create or replace function public.reportar_publicacion(
  p_product_id uuid,
  p_motivo     public.motivo_reporte,
  p_detalle    text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor    uuid := auth.uid();
  v_producto public.products%rowtype;
  v_dueno    uuid;
  v_termino  text;
begin
  if v_actor is null then
    raise exception 'SESION_REQUERIDA' using errcode = '42501';
  end if;

  select * into v_producto from public.products where id = p_product_id;
  if not found then
    raise exception 'PUBLICACION_INEXISTENTE' using errcode = '22023';
  end if;

  select s.owner_id into v_dueno
    from public.stores s where s.id = v_producto.store_id;

  if v_dueno = v_actor then
    raise exception 'NO_TE_REPORTES_A_TI_MISMO' using errcode = '42501';
  end if;

  -- El detalle es texto libre que escribe una persona: sin esto, el formulario
  -- de reportar seria el unico sitio de la aplicacion donde se puede insultar
  -- sin que nada lo mire.
  if p_detalle is not null and length(trim(p_detalle)) > 0 then
    v_termino := public.termino_ofensivo(p_detalle);
    if v_termino is not null then
      raise exception 'CONTENIDO_NO_PERMITIDO' using errcode = '22023';
    end if;
  end if;

  insert into public.reportes_publicacion (
    product_id, owner_id, reporter_id, titulo, descripcion, motivo, detalle
  )
  values (
    p_product_id, v_dueno, v_actor,
    v_producto.name, v_producto.description,
    p_motivo, nullif(trim(p_detalle), '')
  )
  -- Reportar dos veces no es un error que haya que explicarle a nadie: se
  -- responde lo mismo que la primera vez.
  on conflict (product_id, reporter_id) do nothing;
end;
$$;

revoke all on function
  public.reportar_publicacion(uuid, public.motivo_reporte, text) from public;
grant execute on function
  public.reportar_publicacion(uuid, public.motivo_reporte, text) to authenticated;

-- ----------------------------------------------------------------------------
-- 4 · Revisar  ·  solo administradores
-- ----------------------------------------------------------------------------
-- Agrupa por publicacion: lo que importa al moderar no es cada reporte suelto
-- sino cuanta gente distinta señalo lo mismo.
create or replace function public.listar_reportes(p_pendientes boolean default true)
returns table (
  product_id    uuid,
  titulo        text,
  descripcion   text,
  owner_id      uuid,
  vendedor      text,
  cuantos       bigint,
  motivos       text[],
  ultimo_en     timestamptz,
  sigue_visible boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.soy_administrador() then
    raise exception 'SOLO_ADMINISTRADORES' using errcode = '42501';
  end if;

  return query
    select r.product_id,
           max(r.titulo)      as titulo,
           max(r.descripcion) as descripcion,
           r.owner_id,
           max(p.full_name)   as vendedor,
           count(*)           as cuantos,
           array_agg(distinct r.motivo::text) as motivos,
           max(r.creado_en)   as ultimo_en,
           coalesce(bool_or(pr.is_available), false) as sigue_visible
      from public.reportes_publicacion r
      join public.profiles p on p.id = r.owner_id
      left join public.products pr on pr.id = r.product_id
     where (not p_pendientes or r.estado = 'pendiente')
     group by r.product_id, r.owner_id
     order by count(*) desc, max(r.creado_en) desc;
end;
$$;

revoke all on function public.listar_reportes(boolean) from public;
grant execute on function public.listar_reportes(boolean) to authenticated;

create or replace function public.contar_reportes_pendientes()
returns integer
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.soy_administrador() then
    return 0;
  end if;
  return (
    select count(distinct product_id)::integer
      from public.reportes_publicacion where estado = 'pendiente'
  );
end;
$$;

revoke all on function public.contar_reportes_pendientes() from public;
grant execute on function public.contar_reportes_pendientes() to authenticated;

-- ----------------------------------------------------------------------------
-- 5 · Resolver
-- ----------------------------------------------------------------------------
-- 'ocultar'   -> deja de verse, no se borra. Reversible, y el vendedor
--                conserva su publicacion por si fue un error.
-- 'eliminar'  -> se borra de verdad. Para lo que no deberia existir.
-- 'descartar' -> el reporte no tenia razon; la publicacion queda como estaba.
create or replace function public.resolver_reporte(
  p_product_id uuid,
  p_accion     text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
begin
  if not public.soy_administrador() then
    raise exception 'SOLO_ADMINISTRADORES' using errcode = '42501';
  end if;
  if p_accion not in ('ocultar', 'eliminar', 'descartar') then
    raise exception 'ACCION_INVALIDA' using errcode = '22023';
  end if;

  if p_accion = 'ocultar' then
    update public.products set is_available = false where id = p_product_id;
  elsif p_accion = 'eliminar' then
    -- El reporte sobrevive: product_id queda en null por la clave foranea.
    delete from public.products where id = p_product_id;
  end if;

  update public.reportes_publicacion
     set estado = case when p_accion = 'descartar'
                       then 'descartado'::public.estado_reporte
                       else 'atendido'::public.estado_reporte end,
         resuelto_por = v_actor,
         resuelto_en  = now()
   where product_id = p_product_id
     and estado = 'pendiente';
end;
$$;

revoke all on function public.resolver_reporte(uuid, text) from public;
grant execute on function public.resolver_reporte(uuid, text) to authenticated;

-- ----------------------------------------------------------------------------
-- 6 · Darse de alta como administrador
-- ----------------------------------------------------------------------------
-- A mano, desde el editor SQL, y solo asi. Reemplaza el correo por el tuyo:
--
--   insert into public.administradores (user_id, nota)
--   select id, 'fundador' from public.profiles
--    where email = 'a2023110000@estudiantes.upsa.edu.bo'
--   on conflict (user_id) do nothing;
--
-- Para comprobar quien lo es:
--
--   select p.full_name, p.email, a.nota
--     from public.administradores a
--     join public.profiles p on p.id = a.user_id;
-- ----------------------------------------------------------------------------
