-- ============================================================================
-- 07 · GRANTs explicitos sobre las tablas
-- ============================================================================
-- El proyecto se creo con "Automatically expose new tables" DESACTIVADO, que
-- es lo correcto para no exponer tablas por accidente, pero implica que hay
-- que otorgar los permisos a mano.
--
-- Sin esto, PostgREST responde 403 Forbidden a todo: las politicas RLS filtran
-- FILAS, pero primero hace falta el permiso de TABLA. Son dos capas distintas:
--   GRANT  -> "puedes tocar esta tabla"
--   RLS    -> "solo estas filas dentro de ella"
--
-- Solo se otorga a `authenticated`: la app exige sesion para todo, y `anon`
-- no debe poder leer nada.
-- ============================================================================

grant usage on schema public to authenticated;

-- ----------------------------------------------------------------------------
-- Catalogo de referencia · solo lectura
-- ----------------------------------------------------------------------------
grant select on public.categories       to authenticated;
grant select on public.campus_locations to authenticated;

-- institutional_domains NO recibe grants a proposito: solo lo consulta el
-- trigger de validacion, que al ser SECURITY DEFINER corre como owner.

-- ----------------------------------------------------------------------------
-- profiles · el usuario lee y edita su propia fila (RLS lo restringe)
-- ----------------------------------------------------------------------------
grant select, update on public.profiles to authenticated;

-- ----------------------------------------------------------------------------
-- Locales e inventario · el dueno administra los suyos (RLS lo restringe)
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on public.stores         to authenticated;
grant select, insert, update, delete on public.products       to authenticated;
grant select, insert, update, delete on public.product_images to authenticated;

-- ----------------------------------------------------------------------------
-- favorites · alta y baja con el corazon
-- ----------------------------------------------------------------------------
grant select, insert, delete on public.favorites to authenticated;

-- ----------------------------------------------------------------------------
-- Pedidos · SOLO LECTURA desde el cliente.
-- Crear y cambiar de estado pasa por las funciones SECURITY DEFINER
-- (crear_pedido, aceptar_pedido, ...), que validan quien es el actor.
-- Por eso aqui NO se otorga insert/update/delete: es la barrera que impide
-- que alguien escriba orders.status = 'aceptado' por su cuenta.
-- ----------------------------------------------------------------------------
grant select on public.orders      to authenticated;
grant select on public.order_items to authenticated;
grant select on public.order_events to authenticated;

-- ----------------------------------------------------------------------------
-- notifications · leer las propias y marcarlas como leidas
-- ----------------------------------------------------------------------------
grant select, update on public.notifications to authenticated;
