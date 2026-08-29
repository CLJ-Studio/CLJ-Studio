// Service worker de notificaciones push.
//
// Va aparte del que genera Flutter (flutter_service_worker.js) a proposito:
// ese lo regenera el build en cada compilacion y sobrescribiria cualquier
// cambio hecho a mano. Este se registra por separado y solo se ocupa de push.

self.addEventListener('push', (evento) => {
  let datos = {
    title: 'U market',
    body: '',
    order_id: null,
    store_id: null,
    product_id: null,
  };
  try {
    if (evento.data) datos = evento.data.json();
  } catch (_) {
    // Contenido no-JSON: se muestra el aviso generico igual.
  }

  evento.waitUntil(
    self.registration.showNotification(datos.title || 'U market', {
      body: datos.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      // Agrupa por lo que anuncia: varios avisos del mismo pedido o local no
      // apilan ruido.
      tag: datos.order_id || datos.store_id || datos.product_id || 'general',
      renotify: true,
      data: {
        order_id: datos.order_id || null,
        store_id: datos.store_id || null,
        product_id: datos.product_id || null,
      },
    }),
  );
});

/*
 * Al tocar la notificacion: antes siempre abria la raiz de la app sin
 * importar de que aviso viniera, asi que tocar "Nuevo pedido" o "Actualiza
 * tu ubicacion" dejaba a la persona en el inicio sin ninguna pista.
 *
 * Ahora arma un enlace con el destino y, si la app ya esta abierta, la
 * NAVEGA hacia ese enlace (no solo la enfoca) para que aterrice en la
 * pantalla correcta. Flutter, al arrancar de nuevo, lee estos parametros de
 * la URL y abre lo que corresponda.
 */
self.addEventListener('notificationclick', (evento) => {
  const datos = evento.notification.data || {};
  evento.notification.close();

  const parametros = new URLSearchParams();
  if (datos.product_id) parametros.set('notif_producto', datos.product_id);
  else if (datos.store_id) parametros.set('notif_local', datos.store_id);
  else if (datos.order_id) parametros.set('notif_pedido', datos.order_id);

  const destino = parametros.toString() ? `/?${parametros.toString()}` : '/';

  evento.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(async (ventanas) => {
        for (const ventana of ventanas) {
          if (!('focus' in ventana)) continue;

          if ('navigate' in ventana) {
            try {
              const navegada = await ventana.navigate(destino);
              return navegada.focus();
            } catch (_) {
              // Algunos navegadores restringen navigate(); enfocar sin mas
              // sigue siendo mejor que no hacer nada.
            }
          }
          return ventana.focus();
        }
        return self.clients.openWindow(destino);
      }),
  );
});
