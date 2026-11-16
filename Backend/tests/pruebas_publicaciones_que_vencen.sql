-- ============================================================================
-- PRUEBAS · publicaciones que vencen (expires_at, sold_at y la limpieza)
--
-- COMO EJECUTAR: python Backend/tests/correr_pruebas.py (corre todos los
-- pruebas_*.sql). Todo va dentro de una transaccion que se revierte.
--
-- Dentro de una transaccion now() no avanza: para simular que paso el tiempo
-- se mueve la fecha con el disparador de validacion apagado
-- (pg_temp.vencio_hace).
-- ============================================================================

begin;

create or replace function pg_temp.actuar_como(p_user uuid)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', p_user::text)::text, true);
  perform set_config('role', 'authenticated', true);
end;
$$;

create or replace function pg_temp.actuar_como_admin()
returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end;
$$;

create or replace function pg_temp.afirmar(p_condicion boolean, p_mensaje text)
returns void language plpgsql as $$
begin
  if p_condicion then
    raise notice '  OK   %', p_mensaje;
  else
    raise exception 'FALLO: %', p_mensaje;
  end if;
end;
$$;

create or replace function pg_temp.afirmar_error(p_sql text, p_fragmento text, p_mensaje text)
returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if position(p_fragmento in sqlerrm) > 0 then
      raise notice '  OK   % (rechazado: %)', p_mensaje, p_fragmento;
      return;
    end if;
    raise exception 'FALLO: % -> error inesperado: %', p_mensaje, sqlerrm;
  end;
  raise exception 'FALLO: % -> NO fue rechazado', p_mensaje;
end;
$$;

-- Por el codigo del error y no por el texto, que depende del idioma del
-- servidor.
create or replace function pg_temp.afirmar_sin_permiso(p_sql text, p_mensaje text)
returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when insufficient_privilege then
    raise notice '  OK   % (rechazado: sin permiso)', p_mensaje;
    return;
  end;
  raise exception 'FALLO: % -> NO fue rechazado', p_mensaje;
end;
$$;

create or replace function pg_temp.vencio_hace(p_producto uuid, p_hace interval)
returns void language plpgsql as $$
begin
  alter table public.products disable trigger products_vencimiento;
  update public.products set expires_at = now() - p_hace where id = p_producto;
  alter table public.products enable trigger products_vencimiento;
end;
$$;

do $$
declare
  v_vendedora   uuid := gen_random_uuid();
  v_duena_local uuid := gen_random_uuid();
  v_comprador   uuid := gen_random_uuid();
  v_otro        uuid := gen_random_uuid();
  v_personal    uuid;
  v_local       uuid;
  v_entrada     uuid;
  v_calculadora uuid;
  v_empanada    uuid;
  v_jugo        uuid;
  v_libro       uuid;
  v_vieja       uuid;
  v_reciente    uuid;
  v_con_pedido  uuid;
  v_pedido      uuid;
  v_n           integer;
  v_ids         uuid[];
begin
  raise notice '';
  raise notice '=== PUBLICACIONES QUE VENCEN ===';

  insert into auth.users (id, email, raw_user_meta_data, instance_id,
                          aud, role, created_at, updated_at)
  values
    (v_vendedora,   'a2020000301@estudiantes.upsa.edu.bo', '{"full_name":"Vendedora"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now()),
    (v_duena_local, 'a2020000302@estudiantes.upsa.edu.bo', '{"full_name":"Duena Local"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now()),
    (v_comprador,   'a2020000303@estudiantes.upsa.edu.bo', '{"full_name":"Comprador"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now()),
    (v_otro,        'a2020000304@estudiantes.upsa.edu.bo', '{"full_name":"Otro"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now());
  update public.profiles
     set full_name = 'Usuario Demo', whatsapp = '59170000300',
         career_id = (select id from public.careers order by id limit 1),
         onboarding_completed = true
   where id in (v_vendedora, v_duena_local, v_comprador, v_otro);

  insert into public.stores (owner_id, name, description, category_id, emoji,
                             delivery_cost, is_open, is_active, is_personal)
  values (v_vendedora, 'Lo de Vendedora', '', null, '🎓', 0, true, true, true)
  returning id into v_personal;
  insert into public.stores (owner_id, name, description, category_id, emoji,
                             delivery_cost, is_open, is_active, is_personal)
  values (v_duena_local, 'Local que Repone', 'Local de pruebas', 'comida', '🍽️',
          0, true, true, false)
  returning id into v_local;

  -- --------------------------------------------------------------------------
  raise notice '--- La fecha';
  perform pg_temp.actuar_como(v_vendedora);
  perform pg_temp.afirmar_error(
    format($f$insert into public.products (store_id, name, price, stock, expires_at)
              values (%L, 'Entrada vieja', 50, 1, now() - interval '1 hour')$f$,
           v_personal),
    'VENCIMIENTO_INVALIDO',
    'No se publica con una fecha que ya paso');

  insert into public.products (store_id, name, price, stock, expires_at)
  values (v_personal, 'Entrada fiesta', 50, 1, now() + interval '2 days')
  returning id into v_entrada;
  insert into public.products (store_id, name, price, stock, image_path)
  values (v_personal, 'Calculadora', 120, 1, 'u/compartida.jpg')
  returning id into v_calculadora;
  perform pg_temp.afirmar(
    (select expires_at from public.products where id = v_calculadora) is null,
    'Sin fecha tambien se puede: es la de siempre');

  -- --------------------------------------------------------------------------
  raise notice '--- Vence';
  perform pg_temp.actuar_como_admin();
  perform pg_temp.vencio_hace(v_entrada, interval '1 minute');
  v_n := public.vencer_publicaciones();
  perform pg_temp.afirmar(
    v_n = 1
    and not (select is_available from public.products where id = v_entrada)
    and (select is_available from public.products where id = v_calculadora),
    'Al vencer sale del catalogo; la que no tiene fecha sigue');
  perform pg_temp.afirmar(
    exists (select 1 from public.notifications
             where user_id = v_vendedora and type = 'publicacion_vencida'
               and product_id = v_entrada),
    'A quien la publico le llega el aviso, y abre la publicacion');
  perform pg_temp.afirmar(public.vencer_publicaciones() = 0,
    'No avisa dos veces de la misma');

  perform pg_temp.actuar_como(v_comprador);
  perform pg_temp.afirmar_error(
    format('select public.crear_pedido(%L::jsonb)',
           jsonb_build_array(jsonb_build_object('product_id', v_entrada, 'quantity', 1))),
    'PRODUCTO_NO_DISPONIBLE',
    'Una vencida no se puede pedir');

  -- --------------------------------------------------------------------------
  raise notice '--- No vuelve sin una fecha nueva';
  perform pg_temp.actuar_como(v_vendedora);
  perform pg_temp.afirmar_error(
    format('select public.relanzar_producto(%L)', v_entrada),
    'PUBLICACION_VENCIDA',
    'Relanzar una vencida pide una fecha nueva');
  perform pg_temp.afirmar_error(
    format('update public.products set is_available = true where id = %L', v_entrada),
    'PUBLICACION_VENCIDA',
    'Mostrarla a mano tampoco');
  perform pg_temp.afirmar_error(
    format($f$update public.products set expires_at = now() - interval '1 day'
              where id = %L$f$, v_calculadora),
    'VENCIMIENTO_INVALIDO',
    'Editar una publicacion con una fecha pasada no');

  update public.products
     set name = 'Entrada fiesta del sabado', expires_at = expires_at
   where id = v_entrada;
  perform pg_temp.afirmar(
    (select name from public.products where id = v_entrada) = 'Entrada fiesta del sabado',
    'Editar una vencida sin cambiarle la fecha si se puede');

  perform pg_temp.afirmar_error(
    format($f$select public.volver_a_publicar(%L, now() - interval '1 day')$f$, v_entrada),
    'VENCIMIENTO_INVALIDO',
    'Volver a publicar con una fecha que ya paso no');
  perform pg_temp.actuar_como(v_otro);
  perform pg_temp.afirmar_error(
    format($f$select public.volver_a_publicar(%L, now() + interval '1 day')$f$, v_entrada),
    'PRODUCTO_AJENO_O_INEXISTENTE',
    'Nadie vuelve a publicar lo ajeno');

  perform pg_temp.actuar_como(v_vendedora);
  perform public.volver_a_publicar(v_entrada, now() + interval '3 days');
  perform pg_temp.afirmar(
    (select is_available and expires_at = now() + interval '3 days' and bumped_at = now()
       from public.products where id = v_entrada),
    'Volver a publicar: se ve de nuevo, arriba, hasta la fecha nueva');
  perform public.volver_a_publicar(v_entrada, null);
  perform pg_temp.afirmar(
    (select is_available and expires_at is null from public.products where id = v_entrada),
    'Volver a publicar sin fecha');

  -- --------------------------------------------------------------------------
  raise notice '--- Un pedido de algo que vencio hace segundos';
  perform pg_temp.actuar_como(v_duena_local);
  insert into public.products (store_id, name, price, stock, expires_at)
  values (v_local, 'Empanada', 5, 5, now() + interval '1 hour')
  returning id into v_empanada;
  perform pg_temp.actuar_como(v_comprador);
  v_pedido := public.crear_pedido(
    jsonb_build_array(jsonb_build_object('product_id', v_empanada, 'quantity', 2)));
  perform pg_temp.actuar_como_admin();
  perform pg_temp.vencio_hace(v_empanada, interval '10 seconds');
  perform pg_temp.actuar_como(v_duena_local);
  perform public.aceptar_pedido(v_pedido);
  perform pg_temp.afirmar(
    (select stock from public.products where id = v_empanada) = 3,
    'Aceptarlo antes de que pase la limpieza del minuto no falla');

  -- --------------------------------------------------------------------------
  raise notice '--- Vendida';
  perform pg_temp.actuar_como(v_vendedora);
  insert into public.products (store_id, name, price, stock)
  values (v_personal, 'Libro de Calculo', 80, 1)
  returning id into v_libro;
  perform pg_temp.actuar_como(v_comprador);
  v_pedido := public.crear_pedido(
    jsonb_build_array(jsonb_build_object('product_id', v_libro, 'quantity', 1)));
  perform pg_temp.actuar_como(v_vendedora);
  perform public.aceptar_pedido(v_pedido);
  perform pg_temp.afirmar(
    (select is_available and stock = 0 from public.products where id = v_libro),
    'Aceptada se agota pero sigue: si se cancela, el stock vuelve');
  perform public.marcar_entregado(v_pedido);
  perform pg_temp.actuar_como(v_comprador);
  perform public.confirmar_entrega(v_pedido);
  perform pg_temp.afirmar(
    (select not is_available and sold_at = now() from public.products where id = v_libro),
    'Personal, agotada y entregada: sale sola como vendida');

  perform pg_temp.actuar_como(v_duena_local);
  insert into public.products (store_id, name, price, stock)
  values (v_local, 'Jugo', 7, 1)
  returning id into v_jugo;
  perform pg_temp.actuar_como(v_comprador);
  v_pedido := public.crear_pedido(
    jsonb_build_array(jsonb_build_object('product_id', v_jugo, 'quantity', 1)));
  perform pg_temp.actuar_como(v_duena_local);
  perform public.aceptar_pedido(v_pedido);
  perform public.marcar_entregado(v_pedido);
  perform pg_temp.actuar_como(v_comprador);
  perform public.confirmar_entrega(v_pedido);
  perform pg_temp.afirmar(
    (select is_available and sold_at is null from public.products where id = v_jugo),
    'La de un local agotada sigue: el local repone');

  -- Vendida por fuera de la app: el stock nunca llego a cero.
  perform pg_temp.actuar_como(v_otro);
  perform pg_temp.afirmar_error(
    format('select public.marcar_vendida(%L)', v_calculadora),
    'PRODUCTO_AJENO_O_INEXISTENTE',
    'Nadie marca como vendido lo ajeno');
  perform pg_temp.actuar_como(v_vendedora);
  perform public.marcar_vendida(v_calculadora);
  perform pg_temp.afirmar(
    (select not is_available and sold_at = now() and stock = 1
       from public.products where id = v_calculadora),
    '"Ya lo vendi" la saca del catalogo aunque tenga stock');
  perform pg_temp.afirmar_error(
    format('select public.volver_a_publicar(%L, null, 0)', v_calculadora),
    'STOCK_INVALIDO',
    'Reponer con cero no');

  -- --------------------------------------------------------------------------
  raise notice '--- La limpieza';
  perform pg_temp.actuar_como(v_vendedora);
  insert into public.products (store_id, name, price, stock, image_path)
  values (v_personal, 'Vieja', 10, 1, 'u/vieja.jpg')
  returning id into v_vieja;
  insert into public.product_images (product_id, storage_path, position)
  values (v_vieja, 'u/vieja-2.jpg', 1),
         (v_vieja, 'u/compartida.jpg', 2),
         (v_vieja, 'https://afuera.com/foto.jpg', 3);
  insert into public.products (store_id, name, price, stock)
  values (v_personal, 'Reciente', 10, 1)
  returning id into v_reciente;
  insert into public.products (store_id, name, price, stock)
  values (v_personal, 'Con pedido', 10, 1)
  returning id into v_con_pedido;
  perform pg_temp.actuar_como(v_comprador);
  perform public.crear_pedido(
    jsonb_build_array(jsonb_build_object('product_id', v_con_pedido, 'quantity', 1)));

  perform pg_temp.actuar_como_admin();
  perform pg_temp.vencio_hace(v_vieja, interval '8 days');
  perform pg_temp.vencio_hace(v_reciente, interval '3 days');
  perform pg_temp.vencio_hace(v_con_pedido, interval '8 days');
  perform public.vencer_publicaciones();
  update public.products set sold_at = now() - interval '8 days' where id = v_libro;

  select array_agg(id order by id) into v_ids
    from public.publicaciones_para_limpiar(100);
  perform pg_temp.afirmar(
    v_ids = (select array_agg(x order by x) from unnest(array[v_vieja, v_libro]) x),
    'Lista solo lo vencido o vendido hace mas de 7 dias y sin pedido en curso');
  perform pg_temp.afirmar(
    (select array(select unnest(rutas) order by 1)
       from public.publicaciones_para_limpiar(100) where id = v_vieja)
      = array['u/vieja-2.jpg', 'u/vieja.jpg'],
    'Se lleva sus fotos, pero no la que usa otra publicacion ni un enlace de afuera');
  perform pg_temp.afirmar(
    (select rutas from public.publicaciones_para_limpiar(100) where id = v_libro) = '{}',
    'Sin fotos, la lista de rutas viene vacia y no nula');

  -- Mientras la funcion borraba las fotos, la vendedora volvio a publicar el libro.
  perform pg_temp.actuar_como(v_vendedora);
  perform public.volver_a_publicar(v_libro, null, 2);
  perform pg_temp.afirmar(
    (select is_available and sold_at is null and stock = 2
       from public.products where id = v_libro),
    'Reponer y volver a publicar una vendida: vuelve con el stock nuevo y sin la marca');

  perform pg_temp.actuar_como_admin();
  v_n := public.borrar_publicaciones(array[v_vieja, v_libro, v_reciente, v_con_pedido]);
  perform pg_temp.afirmar(
    v_n = 1
    and not exists (select 1 from public.products where id = v_vieja)
    and not exists (select 1 from public.product_images where product_id = v_vieja)
    and exists (select 1 from public.products where id = v_libro)
    and exists (select 1 from public.products where id = v_reciente)
    and exists (select 1 from public.products where id = v_con_pedido),
    'Borra solo las que siguen cumpliendo, con sus fotos en la tabla');

  -- --------------------------------------------------------------------------
  raise notice '--- Quien puede';
  perform pg_temp.actuar_como(v_comprador);
  perform pg_temp.afirmar_sin_permiso('select public.publicaciones_para_limpiar(10)',
    'Una cuenta comun no lista lo que se borra');
  perform pg_temp.afirmar_sin_permiso(
    format('select public.borrar_publicaciones(array[%L]::uuid[])', v_calculadora),
    'Ni lo borra');
  perform pg_temp.afirmar_sin_permiso('select public.vencer_publicaciones()',
    'Ni corre la limpieza del minuto');

  perform set_config('role', 'service_role', true);
  perform public.publicaciones_para_limpiar(1);
  perform pg_temp.afirmar(true, 'La Edge Function (service_role) si puede');

  perform pg_temp.actuar_como_admin();
  perform pg_temp.afirmar(
    (select count(*) from cron.job
      where jobname in ('vencer-publicaciones', 'limpiar-publicaciones')) = 2,
    'Quedan programadas la del minuto y la diaria');
end;
$$;

rollback;
