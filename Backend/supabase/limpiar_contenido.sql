-- ============================================================================
-- Vaciar el contenido para empezar de cero
-- ============================================================================
-- NO es una migracion: no se ejecuta sola ni forma parte del esquema. Es un
-- script de una vez, para correr a mano en el SQL Editor cuando haga falta
-- dejar la aplicacion limpia antes de mostrarla.
--
-- ESTO NO SE PUEDE DESHACER. Supabase no guarda una copia previa en el plan
-- gratuito: lo que se borra aqui no vuelve.
--
-- Ejecutar DESPUES de 20260803120000, para que lo que se suba a partir de
-- ahora pase por el filtro nuevo.
--
-- ----------------------------------------------------------------------------
-- Que borra la PARTE 1 (la de abajo, la que casi seguro querias):
--
--   · Todas las publicaciones y sus fotos
--   · Todos los locales y espacios personales
--   · Todos los pedidos, con su historial
--   · Favoritos, vistas y notificaciones
--
-- Que NO borra: las cuentas. Nadie pierde su sesion, su nombre, su carrera ni
-- su foto de perfil. Al entrar se encuentran la aplicacion vacia y pueden
-- volver a publicar. Es lo que se quiere para mostrarla: limpia, no muerta.
--
-- Tampoco borra los catalogos (categorias, carreras, puntos del campus): son
-- configuracion, no contenido de nadie.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PARTE 1 · Contenido
-- ----------------------------------------------------------------------------
-- El orden importa: las claves foraneas van de abajo hacia arriba. Va todo en
-- una transaccion, asi que o se borra entero o no se borra nada.
begin;

  -- Pedidos: primero las hojas, al final la raiz.
  delete from public.order_events;
  delete from public.order_items;
  delete from public.orders;

  -- Senales sobre el contenido.
  delete from public.notifications;
  delete from public.favorites;
  delete from public.product_views;
  delete from public.store_views;

  -- Publicaciones y locales.
  delete from public.product_images;
  delete from public.products;
  delete from public.stores;

  -- Los contadores viven en las filas que ya se fueron, pero la ubicacion del
  -- local y la biografia viven en el perfil y sobreviven. La biografia paso
  -- por el filtro VIEJO, asi que se revisa con el nuevo y se borra solo la
  -- que hoy no pasaria.
  update public.profiles
     set bio = null
   where bio is not null
     and public.termino_ofensivo(bio) is not null;

commit;

-- Comprobacion: las cuatro tienen que dar 0.
select
  (select count(*) from public.products)      as publicaciones,
  (select count(*) from public.stores)        as locales,
  (select count(*) from public.orders)        as pedidos,
  (select count(*) from public.notifications) as avisos;

-- ----------------------------------------------------------------------------
-- PARTE 2 · Las cuentas  ·  NO EJECUTAR salvo que lo quieras de verdad
-- ----------------------------------------------------------------------------
-- Esto borra a las PERSONAS, no a lo que publicaron. Cada una tendria que
-- volver a pedir su codigo al correo y rehacer su perfil desde cero.
--
-- Para mostrar la aplicacion no hace falta: con la Parte 1 el catalogo ya se
-- ve vacio. Se deja escrito por si algun dia se necesita, comentado a
-- proposito para que no se ejecute de un copiar y pegar distraido.
--
-- Si de verdad hace falta, quitar los guiones de estas dos lineas:
--
--   delete from public.push_subscriptions;
--   delete from auth.users;
--
-- `profiles` cuelga de `auth.users` y se va sola por la clave foranea.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Las fotos NO estan aqui
-- ----------------------------------------------------------------------------
-- Viven en Storage, que es otro sistema: borrar las filas deja los archivos
-- huerfanos ocupando espacio, sin que nadie pueda verlos desde la aplicacion.
--
-- Para limpiarlos: Storage -> selecciona el bucket -> seleccionar todo ->
-- Delete. Se hace desde el panel, no desde SQL.
-- ----------------------------------------------------------------------------
