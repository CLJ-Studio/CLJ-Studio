-- ============================================================================
-- 55 · Cuentas de la UPSA y directorio de proveedores
-- ============================================================================
-- La incubadora de empresas de la UPSA pidio ver que proveedores hay entre
-- los emprendedores de la app, estudiantes y egresados. Para eso:
--
--   1. Cuentas de la UPSA. El personal entra con su correo @upsa.edu.bo
--      (docentes, y unidades como DABE). El tipo de cuenta sale del dominio
--      al crear el perfil y nadie puede cambiarselo: la columna no tiene
--      permiso de UPDATE para los usuarios.
--   2. El registro inicial del personal pide nombre, area o unidad y
--      WhatsApp. No tienen carrera.
--   3. Egresados. Conservan su correo de estudiante, asi que entran como
--      siempre; cada uno marca en su perfil que ya se graduo.
--   4. Cada local elige si aparece en el directorio y que le ofrece a la
--      UPSA. Al aparecer, la UPSA ve el WhatsApp del dueño para contactarlo.
--   5. El directorio solo lo ven las cuentas de la UPSA y los admins.
--
-- Y de paso, el numero de registro: el perfil solo lo guardaba con 11 o 12
-- despues del año. En 2004 tambien habia 21, y los egresados de antes
-- entraban sin numero. Ahora vale cualquier "a" + diez digitos, y los que
-- quedaron sin numero lo recuperan de su correo.
--
-- Termina con pruebas dentro de la misma transaccion: si algo no da lo
-- esperado, no se aplica nada.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1 · Que tipo de cuenta da cada dominio
-- ----------------------------------------------------------------------------
alter table public.institutional_domains
  add column if not exists tipo_cuenta text not null default 'estudiante';

alter table public.institutional_domains
  drop constraint if exists institutional_domains_tipo_cuenta;
alter table public.institutional_domains
  add constraint institutional_domains_tipo_cuenta
  check (tipo_cuenta in ('estudiante', 'upsa'));

insert into public.institutional_domains (domain, label, is_active, tipo_cuenta)
values ('upsa.edu.bo', 'Docentes y personal UPSA', true, 'upsa')
on conflict (domain) do update
  set is_active   = true,
      tipo_cuenta = 'upsa';

-- ----------------------------------------------------------------------------
-- 2 · El perfil: tipo de cuenta, area del personal y egresados
-- ----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists tipo_cuenta text not null default 'estudiante',
  add column if not exists area_upsa   text,
  add column if not exists es_egresado boolean not null default false;

alter table public.profiles drop constraint if exists profiles_tipo_cuenta;
alter table public.profiles add constraint profiles_tipo_cuenta
  check (tipo_cuenta in ('estudiante', 'upsa'));

alter table public.profiles drop constraint if exists profiles_area_upsa;
alter table public.profiles add constraint profiles_area_upsa
  check (area_upsa is null or length(trim(area_upsa)) between 2 and 60);

-- Graduarse es cosa de estudiantes.
alter table public.profiles drop constraint if exists profiles_egresado_estudiante;
alter table public.profiles add constraint profiles_egresado_estudiante
  check (not es_egresado or tipo_cuenta = 'estudiante');

-- Las cuentas que ya existan con un correo del personal.
update public.profiles p
   set tipo_cuenta = d.tipo_cuenta
  from public.institutional_domains d
 where d.domain = lower(split_part(p.email, '@', 2))
   and p.tipo_cuenta <> d.tipo_cuenta;

-- Que ya se graduo lo marca cada uno. El tipo de cuenta no: sin permiso de
-- UPDATE sobre esa columna, nadie se puede volver "UPSA" para ver el
-- directorio.
grant update (es_egresado) on public.profiles to authenticated;

-- El numero de registro: cualquier "a" + diez digitos.
alter table public.profiles drop constraint if exists profiles_student_code_formato;
alter table public.profiles add constraint profiles_student_code_formato
  check (student_code is null or student_code ~ '^a\d{10}$');

update public.profiles
   set student_code = split_part(lower(email), '@', 1)
 where student_code is null
   and lower(email) ~ '^a\d{10}@estudiantes\.upsa\.edu\.bo$';

-- Alguien del personal que ya hubiera completado el registro de
-- estudiante (con carrera y sin area) lo vuelve a completar, ahora con su
-- area. Sin esto la regla de abajo no se podria agregar.
update public.profiles
   set onboarding_completed = false
 where tipo_cuenta = 'upsa'
   and onboarding_completed
   and area_upsa is null;

-- El registro inicial completo pide carrera a los estudiantes y area al
-- personal de la UPSA.
alter table public.profiles drop constraint if exists profiles_onboarding_completo;
alter table public.profiles add constraint profiles_onboarding_completo
  check (
    not onboarding_completed
    or (
      length(trim(full_name)) > 0
      and whatsapp is not null
      and case tipo_cuenta
            when 'upsa' then area_upsa is not null
            else career_id is not null
          end
    )
  );

-- ----------------------------------------------------------------------------
-- 3 · El alta: el tipo de cuenta sale del dominio
-- ----------------------------------------------------------------------------
create or replace function public.crear_perfil_de_usuario_nuevo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_local  text;
  v_tipo   text;
  v_codigo text;
begin
  v_local := split_part(new.email, '@', 1);

  select d.tipo_cuenta into v_tipo
    from public.institutional_domains d
   where d.domain = lower(split_part(coalesce(new.email, ''), '@', 2));
  v_tipo := coalesce(v_tipo, 'estudiante');

  -- Solo los estudiantes tienen numero de registro.
  v_codigo := case
                when v_tipo = 'estudiante' and lower(v_local) ~ '^a\d{10}$'
                  then lower(v_local)
                else null
              end;

  insert into public.profiles
    (id, email, student_code, full_name, avatar_emoji, tipo_cuenta)
  values (
    new.id,
    new.email,
    v_codigo,
    public.normalizar_nombre(
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        nullif(trim(new.raw_user_meta_data->>'name'), ''),
        v_local
      )
    ),
    '🎓',
    v_tipo
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4 · El registro inicial del personal
-- ----------------------------------------------------------------------------
-- Deja solo digitos y antepone 591 a un celular boliviano de 8: wa.me exige
-- el codigo de pais. Es la misma regla de completar_onboarding().
create or replace function public.normalizar_whatsapp(p_numero text)
returns text
language plpgsql
immutable
as $$
declare
  v_numero text := regexp_replace(coalesce(p_numero, ''), '\D', '', 'g');
begin
  if length(v_numero) = 8 then
    v_numero := '591' || v_numero;
  end if;
  if length(v_numero) < 11 or length(v_numero) > 15 then
    return null;
  end if;
  return v_numero;
end;
$$;

create or replace function public.completar_onboarding_upsa(
  p_full_name text,
  p_area      text,
  p_whatsapp  text
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre   text;
  v_area     text;
  v_whatsapp text;
  v_perfil   public.profiles;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.profiles
     where id = auth.uid() and tipo_cuenta = 'upsa'
  ) then
    raise exception 'SOLO_PERSONAL_UPSA: esta cuenta no es del personal'
      using errcode = '42501';
  end if;

  -- Al personal siempre se le pide el nombre: lo que hay en el perfil es la
  -- parte del correo ("josebenavente"), que no es un nombre. Una unidad
  -- tambien pasa la regla si va con dos palabras ("DABE UPSA").
  v_nombre := public.normalizar_nombre(coalesce(p_full_name, ''));
  if not public.nombre_parece_persona(v_nombre) or length(v_nombre) > 60 then
    raise exception 'NOMBRE_INVALIDO: escribe tu nombre y tu apellido'
      using errcode = '22023';
  end if;

  v_area := trim(coalesce(p_area, ''));
  if length(v_area) < 2 or length(v_area) > 60 then
    raise exception 'AREA_INVALIDA: escribe tu area o unidad'
      using errcode = '22023';
  end if;

  if public.termino_ofensivo(v_nombre || ' ' || v_area) is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa tu nombre o tu area'
      using errcode = '22023';
  end if;

  v_whatsapp := public.normalizar_whatsapp(p_whatsapp);
  if v_whatsapp is null then
    raise exception 'WHATSAPP_INVALIDO: revisa el numero' using errcode = '22023';
  end if;

  update public.profiles
     set full_name            = v_nombre,
         area_upsa            = v_area,
         whatsapp             = v_whatsapp,
         onboarding_completed = true
   where id = auth.uid()
  returning * into v_perfil;

  return v_perfil;
end;
$$;

revoke all on function public.completar_onboarding_upsa(text, text, text) from public;
grant execute on function public.completar_onboarding_upsa(text, text, text)
  to authenticated;

-- ----------------------------------------------------------------------------
-- 5 · Cada local elige si aparece en el directorio
-- ----------------------------------------------------------------------------
alter table public.stores
  add column if not exists ofrece_a_upsa boolean not null default false,
  add column if not exists oferta_upsa   text;

alter table public.stores drop constraint if exists stores_oferta_upsa;
alter table public.stores add constraint stores_oferta_upsa
  check (oferta_upsa is null or length(oferta_upsa) <= 280);

-- El texto para la UPSA pasa por el mismo filtro que el nombre y la
-- descripcion. El aviso de esos dos queda igual: la app lo reconoce.
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

  if public.termino_ofensivo(coalesce(new.oferta_upsa, '')) is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa lo que le ofreces a la UPSA'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

drop trigger if exists validar_contenido_antes_de_abrir_local on public.stores;
create trigger validar_contenido_antes_de_abrir_local
  before insert or update of name, description, oferta_upsa on public.stores
  for each row execute function public.validar_contenido_local();

-- ----------------------------------------------------------------------------
-- 6 · El directorio
-- ----------------------------------------------------------------------------
create or replace function public.puedo_ver_directorio()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
           select 1 from public.profiles
            where id = auth.uid() and tipo_cuenta = 'upsa'
         )
      or exists (
           select 1 from public.administradores where user_id = auth.uid()
         );
$$;

revoke all on function public.puedo_ver_directorio() from public;
grant execute on function public.puedo_ver_directorio() to authenticated;

create or replace function public.directorio_proveedores()
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
-- 7 · Pruebas: si algo no da lo esperado, no se aplica nada
-- ----------------------------------------------------------------------------
-- Los datos de prueba se crean dentro de un bloque que termina lanzando
-- PRUEBAS_OK: eso deshace todo lo que crearon. Cualquier otro error sube y
-- tumba la transaccion entera.
do $$
declare
  v_personal   uuid := gen_random_uuid();
  v_estudiante uuid := gen_random_uuid();
  v_egresado   uuid := gen_random_uuid();
  v_local      uuid;
  v_categoria  text;
  v_carrera    text;
  v_perfil     public.profiles;
  v_filas      integer;
  v_fallo      boolean;
begin
  begin
    -- En una base recien armada (supabase db reset) el seed corre despues de
    -- las migraciones: lo que la prueba necesita se crea aqui, y se deshace
    -- con ella.
    insert into public.institutional_domains (domain, label)
    values ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA')
    on conflict (domain) do nothing;

    select id into v_categoria from public.categories order by sort_order limit 1;
    if v_categoria is null then
      insert into public.categories (id, name, icon_name)
      values ('prueba_directorio', 'Prueba', 'storefront')
      returning id into v_categoria;
    end if;

    select id into v_carrera from public.careers where is_active
     order by sort_order limit 1;
    if v_carrera is null then
      insert into public.careers (id, name, faculty)
      values ('prueba_directorio', 'Prueba', 'Prueba')
      returning id into v_carrera;
    end if;

    -- Nadie puede volverse UPSA editando su perfil.
    if has_column_privilege('authenticated', 'public.profiles', 'tipo_cuenta', 'UPDATE') then
      raise exception 'tipo_cuenta no deberia poder editarse';
    end if;
    if not has_column_privilege('authenticated', 'public.profiles', 'es_egresado', 'UPDATE') then
      raise exception 'es_egresado deberia poder editarse';
    end if;

    -- El alta reparte el tipo por dominio y guarda los registros de antes.
    insert into auth.users (id, email) values
      (v_personal,   'prueba.directorio@upsa.edu.bo'),
      (v_estudiante, 'a2024119999@estudiantes.upsa.edu.bo'),
      (v_egresado,   'a2004219999@estudiantes.upsa.edu.bo');

    select * into v_perfil from public.profiles where id = v_personal;
    if v_perfil.tipo_cuenta <> 'upsa' or v_perfil.student_code is not null then
      raise exception 'el personal no quedo como cuenta UPSA: %', v_perfil;
    end if;
    select * into v_perfil from public.profiles where id = v_egresado;
    if v_perfil.tipo_cuenta <> 'estudiante'
       or v_perfil.student_code is distinct from 'a2004219999' then
      raise exception 'el registro de 2004 quedo mal: %', v_perfil;
    end if;

    -- Un estudiante no puede usar el registro del personal.
    perform set_config('request.jwt.claim.sub', v_estudiante::text, true);
    v_fallo := false;
    begin
      perform public.completar_onboarding_upsa('Ana Perez', 'Compras', '70012345');
    exception when others then
      v_fallo := sqlerrm like 'SOLO_PERSONAL_UPSA%';
    end;
    if not v_fallo then
      raise exception 'un estudiante completo el registro del personal';
    end if;

    -- El personal completa el suyo sin carrera.
    perform set_config('request.jwt.claim.sub', v_personal::text, true);
    v_perfil := public.completar_onboarding_upsa(
      'Prueba Directorio', 'Incubadora de Empresas', '+591 700 12345'
    );
    if not v_perfil.onboarding_completed
       or v_perfil.whatsapp <> '59170012345'
       or v_perfil.area_upsa <> 'Incubadora de Empresas'
       or v_perfil.career_id is not null then
      raise exception 'el registro del personal quedo mal: %', v_perfil;
    end if;

    -- Un egresado con su local en el directorio, y un estudiante sin. Van
    -- como locales personales: uno que no lo es avisa a todos los usuarios
    -- al abrir (notificar_nuevo_local), y aqui no hay nada que avisar.
    update public.profiles
       set full_name = 'Egresado Prueba', career_id = v_carrera,
           whatsapp = '59170000001', onboarding_completed = true,
           es_egresado = true
     where id = v_egresado;
    update public.profiles
       set full_name = 'Estudiante Prueba', career_id = v_carrera,
           whatsapp = '59170000002', onboarding_completed = true
     where id = v_estudiante;

    insert into public.stores (owner_id, name, description, category_id,
                               is_personal, ofrece_a_upsa, oferta_upsa)
    values (v_egresado, 'Catering de prueba', 'Bocaditos', v_categoria,
            true, true, 'Bocaditos para eventos de la universidad')
    returning id into v_local;
    insert into public.stores (owner_id, name, description, category_id,
                               is_personal)
    values (v_estudiante, 'Local sin directorio', 'Nada', v_categoria, true);

    -- El personal ve el local que se ofrecio, y solo ese.
    select count(*) into v_filas
      from public.directorio_proveedores() d
     where d.local_id = v_local and d.es_egresado and d.whatsapp = '59170000001';
    if v_filas <> 1 then
      raise exception 'el directorio no mostro el local ofrecido';
    end if;
    select count(*) into v_filas
      from public.directorio_proveedores() d
     where d.nombre = 'Local sin directorio';
    if v_filas <> 0 then
      raise exception 'el directorio mostro un local que no se ofrecio';
    end if;

    -- Ningun aviso salio por los locales de prueba.
    if exists (select 1 from public.notifications where store_id = v_local) then
      raise exception 'el local de prueba aviso a los usuarios';
    end if;

    -- Un estudiante no ve el directorio.
    perform set_config('request.jwt.claim.sub', v_estudiante::text, true);
    if public.puedo_ver_directorio() then
      raise exception 'un estudiante puede ver el directorio';
    end if;
    v_fallo := false;
    begin
      perform * from public.directorio_proveedores();
    exception when others then
      v_fallo := sqlerrm like 'SOLO_UPSA%';
    end;
    if not v_fallo then
      raise exception 'un estudiante leyo el directorio';
    end if;

    -- Lo que se le ofrece a la UPSA pasa por el filtro de contenido (con
    -- uno de los ejemplos que ya prueba 20261002150000_filtro_con_contexto).
    v_fallo := false;
    begin
      update public.stores set oferta_upsa = 'la concha de tu madre'
       where id = v_local;
    exception when others then
      v_fallo := sqlerrm like 'CONTENIDO_NO_PERMITIDO%';
    end;
    if not v_fallo then
      raise exception 'el filtro dejo pasar la oferta ofensiva';
    end if;

    raise exception 'PRUEBAS_OK';
  exception when raise_exception then
    if sqlerrm <> 'PRUEBAS_OK' then
      raise exception 'No se aplico nada. %', sqlerrm;
    end if;
  end;

  -- Y lo de prueba no quedo.
  if exists (select 1 from auth.users where id in (v_personal, v_estudiante, v_egresado)) then
    raise exception 'quedaron datos de prueba';
  end if;

  raise notice 'Cuentas UPSA y directorio probados: todo bien.';
end $$;

commit;
