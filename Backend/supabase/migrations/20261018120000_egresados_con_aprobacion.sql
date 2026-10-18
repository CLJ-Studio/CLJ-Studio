-- ============================================================================
-- 56 · Egresados verificados: lo piden y un admin aprueba
-- ============================================================================
-- La 55 dejaba que cada estudiante marcara "ya me gradue" por su cuenta.
-- Cualquiera podia decirlo sin haberse graduado, y la UPSA lo veria en el
-- directorio de proveedores. Ahora:
--
--   - Nadie escribe es_egresado desde la app: se quita el permiso.
--   - El estudiante pide la marca (solicitar_egresado) y queda en revision.
--   - Los admins ven las solicitudes con nombre, carrera y año de ingreso
--     (solicitudes_egresado) y las aprueban o rechazan (resolver_egresado).
--   - El directorio muestra tambien el año de ingreso: sale del numero de
--     registro, que viene del correo institucional, y no se puede inventar.
--   - Las marcas que alguien se haya puesto solo con la 55 se borran: no las
--     verifico nadie.
--
-- Termina con pruebas dentro de la misma transaccion: si algo no da lo
-- esperado, no se aplica nada.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1 · Nadie se marca solo
-- ----------------------------------------------------------------------------
revoke update (es_egresado) on public.profiles from authenticated;

update public.profiles set es_egresado = false where es_egresado;

alter table public.profiles
  add column if not exists egresado_pedido_en    timestamptz,
  add column if not exists egresado_rechazado_en timestamptz;

-- ----------------------------------------------------------------------------
-- 2 · El año de ingreso, del numero de registro
-- ----------------------------------------------------------------------------
create or replace function public.anio_de_ingreso(p_registro text)
returns integer
language sql
immutable
as $$
  select case
           when p_registro ~ '^a\d{10}$'
             then substring(p_registro from 2 for 4)::integer
         end;
$$;

-- ----------------------------------------------------------------------------
-- 3 · Pedir la marca
-- ----------------------------------------------------------------------------
-- Pedirla de nuevo con una ya en revision, o ya siendo egresado, no hace
-- nada. Despues de un rechazo se puede volver a pedir.
create or replace function public.solicitar_egresado()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  update public.profiles
     set egresado_pedido_en    = now(),
         egresado_rechazado_en = null
   where id = auth.uid()
     and tipo_cuenta = 'estudiante'
     and not es_egresado
     and egresado_pedido_en is null;
end;
$$;

revoke all on function public.solicitar_egresado() from public;
grant execute on function public.solicitar_egresado() to authenticated;

-- ----------------------------------------------------------------------------
-- 4 · Lo que ven y deciden los admins
-- ----------------------------------------------------------------------------
create or replace function public.solicitudes_egresado()
returns table (
  usuario_id   uuid,
  nombre       text,
  correo       text,
  registro     text,
  anio_ingreso integer,
  carrera      text,
  pedido_en    timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.administradores where user_id = auth.uid()
  ) then
    raise exception 'SOLO_ADMIN: solo los admins verifican egresados'
      using errcode = '42501';
  end if;

  return query
    select p.id,
           p.full_name,
           p.email,
           p.student_code,
           public.anio_de_ingreso(p.student_code),
           c.name,
           p.egresado_pedido_en
      from public.profiles p
      left join public.careers c on c.id = p.career_id
     where p.egresado_pedido_en is not null
       and not p.es_egresado
     order by p.egresado_pedido_en;
end;
$$;

revoke all on function public.solicitudes_egresado() from public;
grant execute on function public.solicitudes_egresado() to authenticated;

-- Aprobar marca al egresado; rechazar (o quitar una marca ya puesta) lo deja
-- como estudiante y le avisa a la app que no se aprobo.
create or replace function public.resolver_egresado(
  p_usuario uuid,
  p_aprobar boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.administradores where user_id = auth.uid()
  ) then
    raise exception 'SOLO_ADMIN: solo los admins verifican egresados'
      using errcode = '42501';
  end if;

  update public.profiles
     set es_egresado           = coalesce(p_aprobar, false),
         egresado_pedido_en    = null,
         egresado_rechazado_en = case when p_aprobar then null else now() end
   where id = p_usuario
     and tipo_cuenta = 'estudiante';

  if not found then
    raise exception 'SIN_ESTUDIANTE: esa cuenta no es de un estudiante'
      using errcode = '22023';
  end if;
end;
$$;

revoke all on function public.resolver_egresado(uuid, boolean) from public;
grant execute on function public.resolver_egresado(uuid, boolean) to authenticated;

-- ----------------------------------------------------------------------------
-- 5 · El directorio, con el año de ingreso
-- ----------------------------------------------------------------------------
-- Cambia lo que devuelve, y eso no se puede con "create or replace".
drop function if exists public.directorio_proveedores();

create function public.directorio_proveedores()
returns table (
  local_id       uuid,
  nombre         text,
  descripcion    text,
  oferta         text,
  categoria_id   text,
  categoria      text,
  emoji          text,
  logo_path      text,
  color_hex      bigint,
  es_personal    boolean,
  dueno          text,
  carrera        text,
  es_egresado    boolean,
  anio_ingreso   integer,
  whatsapp       text,
  calificacion   numeric,
  calificaciones integer,
  publicaciones  integer,
  desde          timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.puedo_ver_directorio() then
    raise exception 'SOLO_UPSA: el directorio es para cuentas de la UPSA'
      using errcode = '42501';
  end if;

  return query
    select s.id,
           s.name,
           s.description,
           s.oferta_upsa,
           s.category_id,
           c.name,
           s.emoji,
           s.logo_path,
           s.color_hex,
           s.is_personal,
           p.full_name,
           ca.name,
           p.es_egresado,
           public.anio_de_ingreso(p.student_code),
           p.whatsapp,
           s.rating_average,
           s.rating_count,
           (select count(*)::integer
              from public.products pr
             where pr.store_id = s.id and pr.is_available),
           s.created_at
      from public.stores s
      join public.profiles p on p.id = s.owner_id
      left join public.categories c on c.id = s.category_id
      left join public.careers ca on ca.id = p.career_id
     where s.ofrece_a_upsa
       and s.is_active
       and p.onboarding_completed
     order by s.rating_average desc, s.rating_count desc, s.name;
end;
$$;

revoke all on function public.directorio_proveedores() from public;
grant execute on function public.directorio_proveedores() to authenticated;

-- ----------------------------------------------------------------------------
-- 6 · Pruebas: si algo no da lo esperado, no se aplica nada
-- ----------------------------------------------------------------------------
-- Como en la 55: los datos de prueba se crean en un bloque que termina
-- lanzando PRUEBAS_OK, y eso los deshace.
do $$
declare
  v_estudiante uuid := gen_random_uuid();
  v_admin      uuid := gen_random_uuid();
  v_personal   uuid := gen_random_uuid();
  v_carrera    text;
  v_categoria  text;
  v_filas      integer;
  v_fallo      boolean;
  v_perfil     public.profiles;
begin
  begin
    insert into public.institutional_domains (domain, label)
    values ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA')
    on conflict (domain) do nothing;

    select id into v_categoria from public.categories order by sort_order limit 1;
    if v_categoria is null then
      insert into public.categories (id, name, icon_name)
      values ('prueba_egresados', 'Prueba', 'storefront')
      returning id into v_categoria;
    end if;
    select id into v_carrera from public.careers where is_active
     order by sort_order limit 1;
    if v_carrera is null then
      insert into public.careers (id, name, faculty)
      values ('prueba_egresados', 'Prueba', 'Prueba')
      returning id into v_carrera;
    end if;

    if has_column_privilege('authenticated', 'public.profiles', 'es_egresado', 'UPDATE') then
      raise exception 'es_egresado todavia se puede escribir desde la app';
    end if;

    insert into auth.users (id, email) values
      (v_estudiante, 'a2004219998@estudiantes.upsa.edu.bo'),
      (v_admin,      'a2024119998@estudiantes.upsa.edu.bo'),
      (v_personal,   'prueba.egresados@upsa.edu.bo');
    update public.profiles
       set full_name = 'Egresada Prueba', career_id = v_carrera,
           whatsapp = '59170000003', onboarding_completed = true
     where id = v_estudiante;
    insert into public.administradores (user_id) values (v_admin);

    -- El estudiante la pide: queda en revision, todavia no es egresado.
    perform set_config('request.jwt.claim.sub', v_estudiante::text, true);
    perform public.solicitar_egresado();
    select * into v_perfil from public.profiles where id = v_estudiante;
    if v_perfil.egresado_pedido_en is null or v_perfil.es_egresado then
      raise exception 'la solicitud no quedo en revision: %', v_perfil;
    end if;

    -- Y no se la puede aprobar el mismo.
    v_fallo := false;
    begin
      perform public.resolver_egresado(v_estudiante, true);
    exception when others then
      v_fallo := sqlerrm like 'SOLO_ADMIN%';
    end;
    if not v_fallo then
      raise exception 'un estudiante se aprobo solo';
    end if;

    -- El personal no tiene nada que pedir.
    perform set_config('request.jwt.claim.sub', v_personal::text, true);
    perform public.solicitar_egresado();
    if (select egresado_pedido_en from public.profiles where id = v_personal) is not null then
      raise exception 'el personal pudo pedir la marca de egresado';
    end if;

    -- El admin la ve, con el año de ingreso, y la aprueba.
    perform set_config('request.jwt.claim.sub', v_admin::text, true);
    select count(*) into v_filas
      from public.solicitudes_egresado() s
     where s.usuario_id = v_estudiante and s.anio_ingreso = 2004;
    if v_filas <> 1 then
      raise exception 'el admin no vio la solicitud con su año de ingreso';
    end if;
    perform public.resolver_egresado(v_estudiante, true);
    select * into v_perfil from public.profiles where id = v_estudiante;
    if not v_perfil.es_egresado or v_perfil.egresado_pedido_en is not null then
      raise exception 'la aprobacion no quedo: %', v_perfil;
    end if;

    -- En el directorio sale verificado y con su año.
    insert into public.stores (owner_id, name, description, category_id,
                               is_personal, ofrece_a_upsa)
    values (v_estudiante, 'Local de prueba', 'Prueba', v_categoria, true, true);
    select count(*) into v_filas
      from public.directorio_proveedores() d
     where d.dueno = 'Egresada Prueba' and d.es_egresado and d.anio_ingreso = 2004;
    if v_filas <> 1 then
      raise exception 'el directorio no mostro al egresado con su año';
    end if;

    -- Quitarle la marca lo deja como estudiante y con aviso de rechazo.
    perform public.resolver_egresado(v_estudiante, false);
    select * into v_perfil from public.profiles where id = v_estudiante;
    if v_perfil.es_egresado or v_perfil.egresado_rechazado_en is null then
      raise exception 'el rechazo no quedo: %', v_perfil;
    end if;

    raise exception 'PRUEBAS_OK';
  exception when raise_exception then
    if sqlerrm <> 'PRUEBAS_OK' then
      raise exception 'No se aplico nada. %', sqlerrm;
    end if;
  end;

  if exists (select 1 from auth.users where id in (v_estudiante, v_admin, v_personal)) then
    raise exception 'quedaron datos de prueba';
  end if;

  raise notice 'Egresados con aprobacion probados: todo bien.';
end $$;

commit;
