-- ============================================================================
-- 58 · Lista de egresados verificados, para poder quitar una marca
-- ============================================================================
-- Los admins veian solo las solicitudes pendientes: una marca ya aprobada no
-- se podia quitar desde la app. Esta lista la muestra, y quitarla usa
-- resolver_egresado(id, false), que ya existe y le avisa al estudiante.
--
-- Termina con pruebas dentro de la misma transaccion: si algo no da lo
-- esperado, no se aplica nada.
-- ============================================================================

begin;

create or replace function public.egresados_verificados()
returns table (
  usuario_id   uuid,
  nombre       text,
  correo       text,
  registro     text,
  anio_ingreso integer,
  carrera      text
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
           c.name
      from public.profiles p
      left join public.careers c on c.id = p.career_id
     where p.es_egresado
     order by p.full_name;
end;
$$;

revoke all on function public.egresados_verificados() from public;
grant execute on function public.egresados_verificados() to authenticated;

do $$
declare
  v_egresado uuid := gen_random_uuid();
  v_admin    uuid := gen_random_uuid();
  v_fallo    boolean;
begin
  begin
    insert into public.institutional_domains (domain, label)
    values ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA')
    on conflict (domain) do nothing;

    insert into auth.users (id, email) values
      (v_egresado, 'a2004219995@estudiantes.upsa.edu.bo'),
      (v_admin,    'a2024119995@estudiantes.upsa.edu.bo');
    update public.profiles set es_egresado = true where id = v_egresado;
    insert into public.administradores (user_id) values (v_admin);

    -- Un estudiante no la ve.
    perform set_config('request.jwt.claim.sub', v_egresado::text, true);
    v_fallo := false;
    begin
      perform * from public.egresados_verificados();
    exception when others then
      v_fallo := sqlerrm like 'SOLO_ADMIN%';
    end;
    if not v_fallo then
      raise exception 'un estudiante vio la lista de egresados';
    end if;

    -- El admin lo ve con su año, le quita la marca y deja de estar.
    perform set_config('request.jwt.claim.sub', v_admin::text, true);
    if not exists (
      select 1 from public.egresados_verificados()
       where usuario_id = v_egresado and anio_ingreso = 2004
    ) then
      raise exception 'el admin no vio al egresado verificado';
    end if;
    perform public.resolver_egresado(v_egresado, false);
    if exists (
      select 1 from public.egresados_verificados() where usuario_id = v_egresado
    ) then
      raise exception 'la marca no se quito';
    end if;

    raise exception 'PRUEBAS_OK';
  exception when raise_exception then
    if sqlerrm <> 'PRUEBAS_OK' then
      raise exception 'No se aplico nada. %', sqlerrm;
    end if;
  end;

  if exists (select 1 from auth.users where id in (v_egresado, v_admin)) then
    raise exception 'quedaron datos de prueba';
  end if;

  raise notice 'Lista de egresados verificados probada: todo bien.';
end $$;

commit;
