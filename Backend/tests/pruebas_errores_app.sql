-- ============================================================================
-- PRUEBAS · registro de errores de la app (errores_app / registrar_error)
--
-- COMO EJECUTAR: python Backend/tests/correr_pruebas.py (corre todos los
-- pruebas_*.sql). Todo va dentro de una transaccion que se revierte.
-- ============================================================================

begin;

do $$
declare
  v_admin   uuid := gen_random_uuid();
  v_alguien uuid := gen_random_uuid();
  v_filas   integer;
begin
  raise notice '';
  raise notice '=== ERRORES DE LA APP ===';

  insert into auth.users (id, email, raw_user_meta_data, instance_id,
                          aud, role, created_at, updated_at)
  values
    (v_admin, 'a2020000101@estudiantes.upsa.edu.bo', '{"full_name":"Admin"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now()),
    (v_alguien, 'a2020000102@estudiantes.upsa.edu.bo', '{"full_name":"Alguien"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now());
  insert into public.administradores (user_id) values (v_admin);

  -- Sin sesion (un fallo en la pantalla de acceso): tambien se anota.
  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', 'anon', true);
  perform public.registrar_error('Null check operator', E'#0 main.dart:1\n#1 x', 'build', '12.11.0930 beta', 'web');
  perform public.registrar_error('Null check operator', E'#0 main.dart:1\n#1 x', 'build', '12.11.0930 beta', 'web');
  perform public.registrar_error(repeat('x', 2000), null, null, null, 'android');

  perform set_config('role', 'postgres', true);
  if (select count(*) from public.errores_app) <> 2
     or (select veces from public.errores_app where mensaje = 'Null check operator') <> 2 then
    raise exception 'FALLO: el mismo error dos veces debe ser una fila con veces = 2';
  end if;
  raise notice '  OK   El mismo error suma veces en vez de otra fila';

  if (select max(char_length(mensaje)) from public.errores_app) <> 500 then
    raise exception 'FALLO: el mensaje debe recortarse a 500';
  end if;
  raise notice '  OK   Un mensaje enorme se recorta';

  -- Nadie escribe directo.
  perform set_config('role', 'anon', true);
  begin
    insert into public.errores_app (firma, mensaje) values ('x', 'inventado');
    raise exception 'FALLO: anon pudo escribir directo en errores_app';
  exception when insufficient_privilege then
    raise notice '  OK   Nadie escribe directo en la tabla';
  end;

  -- Leer: solo administradores.
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_alguien::text)::text, true);
  perform set_config('role', 'authenticated', true);
  select count(*) into v_filas from public.errores_app;
  if v_filas <> 0 then
    raise exception 'FALLO: una cuenta comun ve % errores', v_filas;
  end if;
  raise notice '  OK   Una cuenta comun no ve los errores';

  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_admin::text)::text, true);
  select count(*) into v_filas from public.errores_app;
  if v_filas <> 2 then
    raise exception 'FALLO: el administrador ve % errores, esperaba 2', v_filas;
  end if;
  raise notice '  OK   Un administrador los ve';
  perform set_config('role', 'postgres', true);
end;
$$;

rollback;
