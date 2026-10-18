-- ============================================================================
-- 57b · Avisos de egresados: que se entere quien tiene que enterarse
-- ============================================================================
-- Requiere haber corrido antes 20261018130000_tipos_aviso_egresados.
--
-- Con la 56, aprobar a alguien no le llegaba: su app seguia diciendo "en
-- revision" hasta reiniciarla. Y los admins no tenian forma de saber que
-- habia solicitudes sin entrar a mirar. Ahora, como cualquier otro aviso de
-- la app (y con su push):
--
--   - Al pedir la marca, les llega a los demas admins.
--   - Al aprobar o rechazar, le llega al estudiante, y su app recarga el
--     perfil en el momento.
--
-- Termina con pruebas dentro de la misma transaccion: si algo no da lo
-- esperado, no se aplica nada.
-- ============================================================================

begin;

create or replace function public.solicitar_egresado()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre  text;
  v_detalle text;
begin
  if auth.uid() is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  update public.profiles p
     set egresado_pedido_en    = now(),
         egresado_rechazado_en = null
   where p.id = auth.uid()
     and p.tipo_cuenta = 'estudiante'
     and not p.es_egresado
     and p.egresado_pedido_en is null
  returning p.full_name,
            concat_ws(', ',
              (select c.name from public.careers c where c.id = p.career_id),
              'ingresó en ' || public.anio_de_ingreso(p.student_code))
       into v_nombre, v_detalle;

  -- Pedirla de nuevo con una en revision no hace nada, y no avisa dos veces.
  if not found then
    return;
  end if;

  insert into public.notifications (user_id, type, title, body)
  select a.user_id,
         'egresado_por_verificar',
         'Nueva solicitud de egresado',
         v_nombre
           || case when v_detalle <> '' then ' (' || v_detalle || ')' else '' end
           || ' pide que verifiquen que egresó.'
    from public.administradores a
   where a.user_id <> auth.uid();
end;
$$;

revoke all on function public.solicitar_egresado() from public;
grant execute on function public.solicitar_egresado() to authenticated;

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

  insert into public.notifications (user_id, type, title, body)
  values (
    p_usuario,
    'egresado_resuelto',
    case when p_aprobar
      then 'Ya figuras como egresado'
      else 'No pudimos verificar que egresaste'
    end,
    case when p_aprobar
      then 'Un admin verificó que egresaste de la UPSA. Así te verá la UPSA '
           || 'en el directorio de proveedores.'
      else 'Si ya te graduaste, vuelve a pedirlo desde Configuración.'
    end
  );
end;
$$;

revoke all on function public.resolver_egresado(uuid, boolean) from public;
grant execute on function public.resolver_egresado(uuid, boolean) to authenticated;

-- ----------------------------------------------------------------------------
-- Pruebas: si algo no da lo esperado, no se aplica nada
-- ----------------------------------------------------------------------------
-- Los avisos de prueba disparan el push, pero pg_net solo lo manda si la
-- transaccion se confirma: al deshacerse el bloque, no sale nada.
do $$
declare
  v_estudiante uuid := gen_random_uuid();
  v_admin      uuid := gen_random_uuid();
  v_otro_admin uuid := gen_random_uuid();
  v_carrera    text;
  v_aviso      public.notifications;
  v_filas      integer;
begin
  begin
    insert into public.institutional_domains (domain, label)
    values ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA')
    on conflict (domain) do nothing;

    select id into v_carrera from public.careers where is_active
     order by sort_order limit 1;
    if v_carrera is null then
      insert into public.careers (id, name, faculty)
      values ('prueba_avisos', 'Prueba', 'Prueba')
      returning id into v_carrera;
    end if;

    insert into auth.users (id, email) values
      (v_estudiante, 'a2004219997@estudiantes.upsa.edu.bo'),
      (v_admin,      'a2024119997@estudiantes.upsa.edu.bo'),
      (v_otro_admin, 'a2024119996@estudiantes.upsa.edu.bo');
    update public.profiles
       set full_name = 'Egresada Avisos', career_id = v_carrera,
           whatsapp = '59170000004', onboarding_completed = true
     where id = v_estudiante;
    insert into public.administradores (user_id)
    values (v_admin), (v_otro_admin);

    -- Pedir avisa a cada admin, una sola vez aunque se pida dos veces.
    perform set_config('request.jwt.claim.sub', v_estudiante::text, true);
    perform public.solicitar_egresado();
    perform public.solicitar_egresado();
    select count(*) into v_filas
      from public.notifications
     where type = 'egresado_por_verificar'
       and user_id in (v_admin, v_otro_admin)
       and body like 'Egresada Avisos (%ingresó en 2004) pide%';
    if v_filas <> 2 then
      raise exception 'los admins no recibieron un aviso cada uno (%)', v_filas;
    end if;

    -- Aprobar le avisa al estudiante.
    perform set_config('request.jwt.claim.sub', v_admin::text, true);
    perform public.resolver_egresado(v_estudiante, true);
    select * into v_aviso from public.notifications
     where user_id = v_estudiante and type = 'egresado_resuelto';
    if v_aviso.title is distinct from 'Ya figuras como egresado' then
      raise exception 'el estudiante no supo que lo aprobaron: %', v_aviso;
    end if;

    -- Un admin que pide la marca para si no se avisa a si mismo (el aviso
    -- de antes, por la solicitud de la estudiante, ya lo tenia).
    select count(*) into v_filas from public.notifications
     where user_id = v_admin and type = 'egresado_por_verificar';
    perform set_config('request.jwt.claim.sub', v_admin::text, true);
    perform public.solicitar_egresado();
    if (select count(*) from public.notifications
         where user_id = v_admin and type = 'egresado_por_verificar') <> v_filas
    then
      raise exception 'el admin se aviso a si mismo';
    end if;
    if not exists (
      select 1 from public.notifications
       where user_id = v_otro_admin and type = 'egresado_por_verificar'
         and body like 'a2024119997%'
    ) then
      raise exception 'al otro admin no le llego la solicitud del admin';
    end if;

    raise exception 'PRUEBAS_OK';
  exception when raise_exception then
    if sqlerrm <> 'PRUEBAS_OK' then
      raise exception 'No se aplico nada. %', sqlerrm;
    end if;
  end;

  if exists (
    select 1 from auth.users where id in (v_estudiante, v_admin, v_otro_admin)
  ) then
    raise exception 'quedaron datos de prueba';
  end if;

  raise notice 'Avisos de egresados probados: todo bien.';
end $$;

commit;
