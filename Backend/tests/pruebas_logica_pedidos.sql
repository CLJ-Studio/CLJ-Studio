-- ============================================================================
-- PRUEBAS · logica critica de pedidos
-- ============================================================================
-- Verifica los riesgos reales del sistema, no el "camino feliz":
--   1. Solo correos institucionales
--   2. El precio lo pone el servidor, no el cliente
--   3. El WhatsApp NO se filtra antes de aceptar
--   4. Solo el vendedor acepta
--   5. Sobreventa: dos compradores, un solo item en stock
--   6. El WhatsApp se libera tras aceptar, y solo a quien participa
--   7. Cancelan las dos partes (nadie mas), y se devuelve el stock
--   8. Vencimiento automatico
--   9. Auditoria
--  10. El comprador cancela antes de que acepten (sin tocar el stock)
--  11. La entrega la cierran las dos partes: una marca, la OTRA confirma
--  12. Sabores: precio por sabor, sabor obligatorio y de ese producto, y el
--      stock compartido entre sabores al aceptar y al devolver
--
-- La sobreventa con dos aceptaciones A LA VEZ no se puede probar aqui (una
-- sola conexion es secuencial): la prueba correr_pruebas.py, con dos.
--
-- COMO EJECUTAR:
--   python Backend/tests/correr_pruebas.py
-- Arma una base local con todas las migraciones y corre esto y las pruebas
-- de concurrencia. No toca Supabase.
--
-- Tambien corre contra un proyecto ya migrado:
--   psql "$DATABASE_URL" -f tests/pruebas_logica_pedidos.sql
-- Todo va dentro de una transaccion que se revierte al final: no deja basura.
-- ============================================================================

begin;

\set ON_ERROR_STOP on

-- ----------------------------------------------------------------------------
-- Utilidad: simula ser un usuario concreto (lo que hace el JWT en produccion).
-- ----------------------------------------------------------------------------
create or replace function pg_temp.actuar_como(p_user uuid)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', p_user::text)::text, true);
  -- 'role' es un GUC: esto equivale a SET LOCAL ROLE authenticated,
  -- que es lo que hace PostgREST al recibir el JWT. Sin esto las RLS
  -- no se evaluarian (el dueno de la tabla las ignora).
  perform set_config('role', 'authenticated', true);
end;
$$;

-- Vuelve al rol privilegiado para tareas de montaje (insertar en auth.users,
-- forzar fechas, invocar el barrido de cron) que ningun usuario final ejecuta.
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

-- Ejecuta una expresion y confirma que revienta con el error esperado.
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
  raise exception 'FALLO: % -> NO fue rechazado (fuga de seguridad)', p_mensaje;
end;
$$;

-- ============================================================================
-- Montaje: 3 usuarios (vendedor, comprador A, comprador B) + 1 local
-- ============================================================================
do $$
declare
  v_vendedor  uuid := gen_random_uuid();
  v_comp_a    uuid := gen_random_uuid();
  v_comp_b    uuid := gen_random_uuid();
  v_local     uuid;
  v_producto  uuid;
  v_empanada  uuid;
  v_jugo      uuid;
  v_queso     uuid;
  v_carne     uuid;
  v_pollo     uuid;
  v_naranja   uuid;
  v_pedido_a  uuid;
  v_pedido_b  uuid;
  v_pedido_c  uuid;
  v_pedido_d  uuid;
  v_pedido_e  uuid;
  v_pedido_f  uuid;
  v_stock     integer;
  v_estado    public.estado_pedido;
  v_total     numeric;
  v_vencidos  integer;
  v_filas     integer;
begin
  raise notice '';
  raise notice '=== MONTAJE ===';

  -- Se insertan directo en auth.users para no depender de Google OAuth.
  insert into auth.users (id, email, raw_user_meta_data, instance_id,
                          aud, role, created_at, updated_at)
  values
    (v_vendedor, 'a2020000001@estudiantes.upsa.edu.bo', '{"full_name":"Vendedor Demo"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now()),
    (v_comp_a,   'a2020000002@estudiantes.upsa.edu.bo', '{"full_name":"Compradora A"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now()),
    (v_comp_b,   'a2020000003@estudiantes.upsa.edu.bo', '{"full_name":"Comprador B"}',
     '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now());

  perform pg_temp.afirmar(
    (select count(*) from public.profiles
      where id in (v_vendedor, v_comp_a, v_comp_b)) = 3,
    'El trigger creo los 3 perfiles automaticamente');

  perform pg_temp.afirmar(
    (select student_code from public.profiles where id = v_vendedor) = 'a2020000001',
    'El codigo de estudiante se extrajo del correo');

  -- Onboarding de los tres.
  update public.profiles
     set full_name = 'Usuario Demo', whatsapp = '59170000000',
         career_id = (select id from public.careers order by id limit 1),
         onboarding_completed = true
   where id in (v_vendedor, v_comp_a, v_comp_b);

  insert into public.stores (owner_id, name, description, category_id,
                             emoji, delivery_cost, is_open, is_active)
  values (v_vendedor, 'Local de Prueba', 'Local para pruebas automatizadas',
          'comida', '🍽️', 3.00, true, true)
  returning id into v_local;

  -- Stock deliberadamente 1: es el escenario donde se rompe la sobreventa.
  insert into public.products (store_id, name, description, price, emoji, stock, kind)
  values (v_local, 'Ultimo sandwich', 'Solo queda uno', 22.00, '🥪', 1, 'producto')
  returning id into v_producto;

  raise notice '';
  raise notice '=== 1 · DOMINIO INSTITUCIONAL ===';

  perform pg_temp.afirmar_error(
    format($f$
      insert into auth.users (id, email, instance_id, aud, role, created_at, updated_at)
      values (%L, 'intruso@gmail.com',
              '00000000-0000-0000-0000-000000000000',
              'authenticated', 'authenticated', now(), now())
    $f$, gen_random_uuid()),
    'DOMINIO_NO_INSTITUCIONAL',
    'Un correo @gmail.com no puede registrarse');

  raise notice '';
  raise notice '=== 2 · PRECIO CALCULADO EN SERVIDOR ===';

  perform pg_temp.actuar_como(v_comp_a);

  -- Se manda un precio falso a proposito: la funcion debe ignorarlo.
  v_pedido_a := public.crear_pedido(
    jsonb_build_array(
      jsonb_build_object('product_id', v_producto, 'quantity', 1, 'unit_price', 1)
    ),
    null, 'Patio central', 'Pruebas'
  );

  select total into v_total from public.orders where id = v_pedido_a;
  perform pg_temp.afirmar(v_total = 25.00,
    'Total = 22 (precio real) + 3 (envio) = 25, ignorando el precio del cliente');

  raise notice '';
  raise notice '=== 3 · WHATSAPP PROTEGIDO ANTES DE ACEPTAR ===';

  perform pg_temp.afirmar_error(
    format('select * from public.get_contacto_pedido(%L)', v_pedido_a),
    'CONTACTO_NO_DISPONIBLE',
    'El comprador NO ve el WhatsApp de un pedido apenas solicitado');

  perform pg_temp.afirmar(
    (select count(*) from public.profiles where id = v_vendedor) = 0,
    'RLS impide leer el perfil del vendedor (y por tanto su WhatsApp)');

  raise notice '';
  raise notice '=== 4 · SOLO EL VENDEDOR ACEPTA ===';

  perform pg_temp.afirmar_error(
    format('select public.aceptar_pedido(%L)', v_pedido_a),
    'SOLO_EL_VENDEDOR_PUEDE_ACEPTAR',
    'El comprador no puede auto-aceptar su pedido');

  -- OJO: orders no tiene policy de UPDATE, y una RLS ausente no lanza error:
  -- simplemente no afecta ninguna fila. Por eso aqui se cuentan las filas
  -- en vez de esperar una excepcion.
  update public.orders set status = 'aceptado' where id = v_pedido_a;
  get diagnostics v_filas = row_count;
  perform pg_temp.afirmar(v_filas = 0,
    'El cliente no puede escribir orders.status directamente (0 filas)');

  perform pg_temp.afirmar(
    (select status from public.orders where id = v_pedido_a) = 'solicitado',
    'El estado sigue siendo solicitado tras el intento de escritura directa');

  raise notice '';
  raise notice '=== 5 · ANTI-SOBREVENTA (el riesgo mas caro) ===';

  -- Segundo comprador pide el MISMO ultimo item.
  perform pg_temp.actuar_como(v_comp_b);
  v_pedido_b := public.crear_pedido(
    jsonb_build_array(jsonb_build_object('product_id', v_producto, 'quantity', 1))
  );
  perform pg_temp.afirmar(v_pedido_b is not null,
    'Dos compradores pueden solicitar el mismo ultimo item (no se reserva al pedir)');

  -- El vendedor acepta el primero: descuenta stock.
  perform pg_temp.actuar_como(v_vendedor);
  perform public.aceptar_pedido(v_pedido_a);

  select stock into v_stock from public.products where id = v_producto;
  perform pg_temp.afirmar(v_stock = 0, 'Stock quedo en 0 tras aceptar el primero');

  -- Aceptar el segundo debe fallar: aqui es donde se evita vender dos veces.
  perform pg_temp.afirmar_error(
    format('select public.aceptar_pedido(%L)', v_pedido_b),
    'STOCK_INSUFICIENTE_AL_ACEPTAR',
    'El segundo pedido NO puede aceptarse: no hay sobreventa');

  raise notice '';
  raise notice '=== 6 · WHATSAPP LIBERADO TRAS ACEPTAR ===';

  perform pg_temp.actuar_como(v_comp_a);
  perform pg_temp.afirmar(
    (select contraparte_whatsapp from public.get_contacto_pedido(v_pedido_a)) = '59170000000',
    'Ya aceptado, el comprador SI obtiene el WhatsApp del vendedor');

  perform pg_temp.afirmar(
    (select enlace_whatsapp from public.get_contacto_pedido(v_pedido_a))
      = 'https://wa.me/59170000000',
    'El enlace wa.me se arma en el servidor');

  -- Un tercero ajeno al pedido no debe poder espiarlo.
  perform pg_temp.actuar_como(v_comp_b);
  perform pg_temp.afirmar_error(
    format('select * from public.get_contacto_pedido(%L)', v_pedido_a),
    'NO_PARTICIPAS_EN_ESTE_PEDIDO',
    'Un tercero no puede leer el contacto de un pedido ajeno');

  raise notice '';
  raise notice '=== 7 · CANCELAN LAS DOS PARTES, Y SE DEVUELVE EL STOCK ===';

  -- Desde agosto cancela cualquiera de las dos partes; un tercero no.
  perform pg_temp.afirmar_error(
    format('select public.cancelar_pedido(%L)', v_pedido_a),
    'NO_PARTICIPAS_EN_ESTE_PEDIDO',
    'Un tercero no puede cancelar un pedido ajeno');

  perform pg_temp.actuar_como(v_vendedor);
  perform public.cancelar_pedido(v_pedido_a, 'Se me acabo el pan');

  select stock into v_stock from public.products where id = v_producto;
  perform pg_temp.afirmar(v_stock = 1,
    'El vendedor cancela un pedido ACEPTADO y el stock vuelve');

  -- Las notificaciones ajenas no se ven por RLS: se cuentan como admin.
  perform pg_temp.actuar_como_admin();
  perform pg_temp.afirmar(
    (select count(*) from public.notifications
      where order_id = v_pedido_a and type = 'pedido_cancelado'
        and user_id = v_comp_a) = 1,
    'Al comprador le llega el aviso de que el vendedor cancelo');

  raise notice '';
  raise notice '=== 8 · VENCIMIENTO AUTOMATICO ===';

  -- Montaje: forzar la fecha y correr el barrido son tareas del servidor,
  -- no de un usuario final. Se hacen con el rol privilegiado.
  perform pg_temp.actuar_como_admin();

  update public.orders set expires_at = now() - interval '1 minute'
   where id = v_pedido_b;

  v_vencidos := public.vencer_pedidos_pendientes();
  perform pg_temp.afirmar(v_vencidos >= 1, 'El barrido marco al menos 1 pedido vencido');

  select status into v_estado from public.orders where id = v_pedido_b;
  perform pg_temp.afirmar(v_estado = 'vencido', 'El pedido sin respuesta quedo vencido');

  perform pg_temp.afirmar(
    (select count(*) from public.notifications
      where order_id = v_pedido_b and type = 'pedido_vencido') = 1,
    'Se notifico al comprador del vencimiento');

  raise notice '';
  raise notice '=== 9 · AUDITORIA ===';

  perform pg_temp.afirmar(
    (select count(*) from public.order_events where order_id = v_pedido_a) >= 3,
    'order_events registro solicitado -> aceptado -> cancelado');

  raise notice '';
  raise notice '=== 10 · EL COMPRADOR CANCELA ANTES DE QUE ACEPTEN ===';

  perform pg_temp.actuar_como(v_comp_a);
  v_pedido_c := public.crear_pedido(
    jsonb_build_array(jsonb_build_object('product_id', v_producto, 'quantity', 1))
  );
  perform public.cancelar_pedido(v_pedido_c);

  perform pg_temp.afirmar(
    (select status from public.orders where id = v_pedido_c) = 'cancelado',
    'El comprador cancela su pedido solicitado');

  select stock into v_stock from public.products where id = v_producto;
  perform pg_temp.afirmar(v_stock = 1,
    'Cancelar un pedido que nadie acepto no toca el stock (nunca se desconto)');

  raise notice '';
  raise notice '=== 11 · LA ENTREGA LA CIERRAN LAS DOS PARTES ===';

  perform pg_temp.actuar_como(v_comp_a);
  v_pedido_d := public.crear_pedido(
    jsonb_build_array(jsonb_build_object('product_id', v_producto, 'quantity', 1))
  );
  perform pg_temp.actuar_como(v_vendedor);
  perform public.aceptar_pedido(v_pedido_d);

  perform pg_temp.actuar_como(v_comp_b);
  perform pg_temp.afirmar_error(
    format('select public.marcar_entregado(%L)', v_pedido_d),
    'NO_PARTICIPAS_EN_ESTE_PEDIDO',
    'Un tercero no puede marcar entregado un pedido ajeno');

  perform pg_temp.actuar_como(v_vendedor);
  perform public.marcar_entregado(v_pedido_d);
  perform pg_temp.afirmar(
    (select status from public.orders where id = v_pedido_d) = 'por_confirmar',
    'Marcar entregado NO cierra: queda esperando a la otra parte');

  perform pg_temp.afirmar_error(
    format('select public.confirmar_entrega(%L)', v_pedido_d),
    'YA_LO_MARCASTE',
    'Quien marco no puede confirmarse a si mismo');

  perform pg_temp.actuar_como(v_comp_b);
  perform pg_temp.afirmar_error(
    format('select public.confirmar_entrega(%L)', v_pedido_d),
    'NO_PARTICIPAS_EN_ESTE_PEDIDO',
    'Un tercero no puede confirmar la entrega');

  perform pg_temp.actuar_como(v_comp_a);
  perform pg_temp.afirmar(
    (select contraparte_whatsapp from public.get_contacto_pedido(v_pedido_d)) = '59170000000',
    'Mientras se confirma, el WhatsApp sigue disponible');

  perform public.confirmar_entrega(v_pedido_d);
  perform pg_temp.afirmar(
    (select status = 'entregado' and confirmed_by = v_comp_a
       and delivered_marked_by = v_vendedor
       from public.orders where id = v_pedido_d),
    'La otra parte confirma: entregado, y consta quien marco y quien confirmo');

  perform pg_temp.afirmar_error(
    format('select public.cancelar_pedido(%L)', v_pedido_d),
    'ESTADO_INVALIDO',
    'Un pedido entregado ya no se puede cancelar');

  raise notice '';
  raise notice '=== 12 · SABORES ===';

  perform pg_temp.actuar_como_admin();
  -- Empanada a 8: queso sin precio propio (vale 8), carne a 10, pollo agotado.
  insert into public.products (store_id, name, description, price, emoji, stock, kind)
  values (v_local, 'Empanada', 'De horno', 8.00, '🥟', 6, 'producto')
  returning id into v_empanada;
  insert into public.product_variants (product_id, name, price, position, is_available)
  values (v_empanada, 'queso', null, 0, true) returning id into v_queso;
  insert into public.product_variants (product_id, name, price, position, is_available)
  values (v_empanada, 'carne', 10.00, 1, true) returning id into v_carne;
  insert into public.product_variants (product_id, name, price, position, is_available)
  values (v_empanada, 'pollo', null, 2, false) returning id into v_pollo;
  -- Otra publicacion con su propio sabor, para intentar colarlo.
  insert into public.products (store_id, name, description, price, emoji, stock, kind)
  values (v_local, 'Jugo', 'Natural', 5.00, '🧃', 10, 'producto')
  returning id into v_jugo;
  insert into public.product_variants (product_id, name, price, position, is_available)
  values (v_jugo, 'naranja', 50.00, 0, true) returning id into v_naranja;

  perform pg_temp.actuar_como(v_comp_a);
  perform pg_temp.afirmar_error(
    format('select public.crear_pedido(%L::jsonb)',
      jsonb_build_array(jsonb_build_object('product_id', v_empanada, 'quantity', 1))),
    'VARIANTE_REQUERIDA',
    'Un producto con sabores no se pide sin elegir uno');

  perform pg_temp.afirmar_error(
    format('select public.crear_pedido(%L::jsonb)',
      jsonb_build_array(jsonb_build_object(
        'product_id', v_empanada, 'variant_id', v_naranja, 'quantity', 1))),
    'VARIANTE_NO_DISPONIBLE',
    'No se puede colar el sabor (y el precio) de otra publicacion');

  perform pg_temp.afirmar_error(
    format('select public.crear_pedido(%L::jsonb)',
      jsonb_build_array(jsonb_build_object(
        'product_id', v_empanada, 'variant_id', v_pollo, 'quantity', 1))),
    'VARIANTE_NO_DISPONIBLE',
    'Un sabor agotado no se puede pedir');

  -- 2 de queso (con un precio falso) y 3 de carne.
  v_pedido_e := public.crear_pedido(
    jsonb_build_array(
      jsonb_build_object('product_id', v_empanada, 'variant_id', v_queso,
                         'quantity', 2, 'unit_price', 1),
      jsonb_build_object('product_id', v_empanada, 'variant_id', v_carne,
                         'quantity', 3)
    )
  );
  select total into v_total from public.orders where id = v_pedido_e;
  perform pg_temp.afirmar(v_total = 49.00,
    'Total = 2 x 8 (queso, precio del producto) + 3 x 10 (carne) + 3 de envio = 49');

  perform pg_temp.afirmar(
    (select count(*) from public.order_items
      where order_id = v_pedido_e
        and ((variant_name = 'queso' and unit_price = 8.00)
          or (variant_name = 'carne' and unit_price = 10.00))) = 2,
    'Cada linea guarda su sabor y su precio');

  perform pg_temp.actuar_como(v_vendedor);
  perform public.aceptar_pedido(v_pedido_e);
  select stock into v_stock from public.products where id = v_empanada;
  perform pg_temp.afirmar(v_stock = 1,
    'Aceptar descuenta los dos sabores del mismo stock (6 - 5 = 1)');

  -- Las dos lineas son del MISMO producto: hay que devolver las dos.
  perform pg_temp.actuar_como(v_comp_a);
  perform public.cancelar_pedido(v_pedido_e);
  select stock into v_stock from public.products where id = v_empanada;
  perform pg_temp.afirmar(v_stock = 6,
    'Cancelar devuelve los dos sabores al stock (vuelve a 6)');

  -- 4 + 4 de un stock de 6: cada linea cabe sola, juntas no.
  perform pg_temp.actuar_como(v_comp_b);
  v_pedido_f := public.crear_pedido(
    jsonb_build_array(
      jsonb_build_object('product_id', v_empanada, 'variant_id', v_queso, 'quantity', 4),
      jsonb_build_object('product_id', v_empanada, 'variant_id', v_carne, 'quantity', 4)
    )
  );
  perform pg_temp.actuar_como(v_vendedor);
  perform pg_temp.afirmar_error(
    format('select public.aceptar_pedido(%L)', v_pedido_f),
    'STOCK_INSUFICIENTE_AL_ACEPTAR',
    'Dos sabores que juntos pasan el stock no se aceptan');

  select stock into v_stock from public.products where id = v_empanada;
  perform pg_temp.afirmar(v_stock = 6,
    'Y no queda descontado a medias: el stock sigue en 6');

  raise notice '';
  raise notice '########################################';
  raise notice '#  TODAS LAS PRUEBAS PASARON           #';
  raise notice '########################################';
end;
$$;

-- No persiste nada: la base queda como estaba.
rollback;
