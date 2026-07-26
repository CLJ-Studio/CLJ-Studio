-- ============================================================================
-- PRUEBAS · logica critica de pedidos
-- ============================================================================
-- Verifica los riesgos reales del sistema, no el "camino feliz":
--   1. Sobreventa bajo concurrencia (dos compradores, un solo item en stock)
--   2. Solo el vendedor acepta/rechaza
--   3. Solo el comprador cancela
--   4. El WhatsApp NO se filtra antes de aceptar
--   5. El precio lo pone el servidor, no el cliente
--   6. Restitucion de stock al cancelar
--   7. Vencimiento automatico
--
-- COMO EJECUTAR (contra el proyecto de Supabase ya migrado):
--   psql "$DATABASE_URL" -f tests/pruebas_logica_pedidos.sql
-- Todo corre dentro de una transaccion que se revierte al final:
-- no deja basura en la base.
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
  v_pedido_a  uuid;
  v_pedido_b  uuid;
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
     set full_name = 'Usuario Demo', career = 'Ingenieria de Sistemas',
         whatsapp = '59170000000', onboarding_completed = true
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
  raise notice '=== 7 · CANCELAR Y RESTITUIR STOCK ===';

  -- El vendedor no puede cancelar (solo el comprador).
  perform pg_temp.actuar_como(v_vendedor);
  perform pg_temp.afirmar_error(
    format('select public.cancelar_pedido(%L)', v_pedido_a),
    'SOLO_EL_COMPRADOR_PUEDE_CANCELAR',
    'El vendedor no puede cancelar el pedido del comprador');

  perform pg_temp.actuar_como(v_comp_a);
  perform public.cancelar_pedido(v_pedido_a, 'Ya no lo necesito');

  select stock into v_stock from public.products where id = v_producto;
  perform pg_temp.afirmar(v_stock = 1,
    'Cancelar un pedido ACEPTADO devuelve el stock');

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
  raise notice '########################################';
  raise notice '#  TODAS LAS PRUEBAS PASARON           #';
  raise notice '########################################';
end;
$$;

-- No persiste nada: la base queda como estaba.
rollback;
