// Service worker de notificaciones push.
//
// Va aparte del que genera Flutter (flutter_service_worker.js) a proposito:
// ese lo regenera el build en cada compilacion y sobrescribiria cualquier
// cambio hecho a mano. Este se registra por separado y solo se ocupa de push.

self.addEventListener('push', (evento) => {
  let datos = { title: 'UPSA Net', body: '', order_id: null };
  try {
    if (evento.data) datos = evento.data.json();
  } catch (_) {
    // Contenido no-JSON: se muestra el aviso generico igual.
  }

  evento.waitUntil(
    self.registration.showNotification(datos.title || 'UPSA Net', {
      body: datos.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      // Agrupa por pedido: varios avisos del mismo pedido no apilan ruido.
      tag: datos.order_id || 'general',
      renotify: true,
      data: { order_id: datos.order_id || null },
    }),
  );
});

// Al tocar la notificacion: si la app ya esta abierta se enfoca esa pestana
// en vez de abrir otra; si no, se abre.
self.addEventListener('notificationclick', (evento) => {
  evento.notification.close();

  evento.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((ventanas) => {
        for (const ventana of ventanas) {
          if ('focus' in ventana) return ventana.focus();
        }
        return self.clients.openWindow('/');
      }),
  );
});
