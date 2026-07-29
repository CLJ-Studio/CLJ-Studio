// Envia notificaciones Web Push a todos los dispositivos de un usuario.
//
// La llama el trigger `enviar_push_al_notificar` cada vez que nace una fila
// en `notifications`. Se hace aqui y no en SQL porque Web Push exige firmar
// un JWT ES256 y cifrar el contenido (AES128GCM), que Postgres no hace.
//
// Una suscripcion vencida (el navegador se desinstalo, el usuario limpio
// datos) devuelve 404/410: en ese caso se borra, para no reintentar por
// siempre contra un dispositivo que ya no existe.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3.6.7';

const claveVapidPublica = Deno.env.get('VAPID_PUBLIC_KEY')!;
const claveVapidPrivada = Deno.env.get('VAPID_PRIVATE_KEY')!;
const contactoVapid = Deno.env.get('VAPID_SUBJECT') ?? 'mailto:soporte@upsa.edu.bo';

webpush.setVapidDetails(contactoVapid, claveVapidPublica, claveVapidPrivada);

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

Deno.serve(async (peticion) => {
  try {
    const { user_id, title, body, order_id, store_id, product_id } =
      await peticion.json();
    if (!user_id) {
      return new Response('falta user_id', { status: 400 });
    }

    const { data: suscripciones, error } = await supabase
      .from('push_subscriptions')
      .select('id, endpoint, p256dh, auth')
      .eq('user_id', user_id);

    if (error) throw error;
    if (!suscripciones?.length) {
      // Sin dispositivos registrados no hay nada que enviar; no es un fallo.
      return new Response(JSON.stringify({ enviados: 0 }), { status: 200 });
    }

    // El service worker construye el enlace de destino a partir de estos
    // tres campos: sin ellos, tocar el aviso solo abre la app en la raiz.
    const contenido = JSON.stringify({
      title: title ?? 'UPSA Eat',
      body: body ?? '',
      order_id: order_id ?? null,
      store_id: store_id ?? null,
      product_id: product_id ?? null,
    });

    const resultados = await Promise.allSettled(
      suscripciones.map((s) =>
        webpush.sendNotification(
          {
            endpoint: s.endpoint,
            keys: { p256dh: s.p256dh, auth: s.auth },
          },
          contenido,
        ).catch(async (fallo: { statusCode?: number }) => {
          if (fallo.statusCode === 404 || fallo.statusCode === 410) {
            await supabase.from('push_subscriptions').delete().eq('id', s.id);
          }
          throw fallo;
        })
      ),
    );

    const enviados = resultados.filter((r) => r.status === 'fulfilled').length;
    return new Response(JSON.stringify({ enviados }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (fallo) {
    // Los errores de PostgREST y de web-push son objetos planos: String()
    // los convierte en "[object Object]" y oculta la causa.
    const detalle = fallo instanceof Error
      ? `${fallo.name}: ${fallo.message}`
      : JSON.stringify(fallo, Object.getOwnPropertyNames(fallo ?? {}));

    return new Response(JSON.stringify({ error: detalle }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
