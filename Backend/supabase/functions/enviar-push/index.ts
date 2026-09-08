// Envia el mismo aviso a cada dispositivo registrado por el usuario.
//
// Los navegadores siguen usando Web Push. Los iPhone instalados se registran
// directamente con Apple Push Notification service (APNs), sin Firebase.
// Ambas rutas nacen de la misma fila de `notifications` y reutilizan la tabla
// `push_subscriptions`; no se cambia el modelo de datos ni la logica de
// negocio. Lo que distingue una de otra es el propio endpoint: el cliente de
// iOS lo guarda como 'apns:<token>' (ver servicio_push_mobile.dart).
//
// Una suscripcion vencida (el navegador se desinstalo, el usuario limpio
// datos, Apple dice que el token ya no vale) se borra: no tiene sentido
// reintentar por siempre contra un dispositivo que ya no existe.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3.6.7';

type Suscripcion = {
  id: string;
  endpoint: string;
  p256dh: string;
  auth: string;
};

type ContenidoPush = {
  title: string;
  body: string;
  order_id: string | null;
  store_id: string | null;
  product_id: string | null;
};

const claveVapidPublica = Deno.env.get('VAPID_PUBLIC_KEY')!;
const claveVapidPrivada = Deno.env.get('VAPID_PRIVATE_KEY')!;
const contactoVapid = Deno.env.get('VAPID_SUBJECT') ??
  'mailto:soporte@upsa.edu.bo';

webpush.setVapidDetails(contactoVapid, claveVapidPublica, claveVapidPrivada);

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const apnsKeyId = Deno.env.get('APNS_KEY_ID');
const apnsTeamId = Deno.env.get('APNS_TEAM_ID');
const apnsPrivateKey = Deno.env.get('APNS_PRIVATE_KEY');
const apnsBundleId = Deno.env.get('APNS_BUNDLE_ID') ?? 'com.cljstudio.umarket';

let jwtApnsEnCache: { valor: string; creadoEn: number } | null = null;

function base64Url(datos: string | Uint8Array): string {
  const bytes = typeof datos === 'string'
    ? new TextEncoder().encode(datos)
    : datos;
  let binario = '';
  for (const byte of bytes) binario += String.fromCharCode(byte);
  return btoa(binario)
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}

function clavePkcs8DesdePem(pem: string): Uint8Array {
  const base64 = pem
    .replaceAll('\\n', '\n')
    .replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');
  const binario = atob(base64);
  return Uint8Array.from(binario, (caracter) => caracter.charCodeAt(0));
}

// APNs acepta el mismo JWT hasta una hora y rechaza que se renueve mas de una
// vez cada veinte minutos: cuarenta y cinco cae comodo entre ambos limites.
async function obtenerJwtApns(): Promise<string> {
  if (!apnsKeyId || !apnsTeamId || !apnsPrivateKey) {
    throw new Error(
      'Faltan APNS_KEY_ID, APNS_TEAM_ID o APNS_PRIVATE_KEY en los secretos',
    );
  }

  const ahora = Math.floor(Date.now() / 1000);
  if (jwtApnsEnCache && ahora - jwtApnsEnCache.creadoEn < 45 * 60) {
    return jwtApnsEnCache.valor;
  }

  const clave = await crypto.subtle.importKey(
    'pkcs8',
    clavePkcs8DesdePem(apnsPrivateKey),
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  );
  const cabecera = base64Url(JSON.stringify({ alg: 'ES256', kid: apnsKeyId }));
  const cuerpo = base64Url(JSON.stringify({ iss: apnsTeamId, iat: ahora }));
  const contenidoFirmado = `${cabecera}.${cuerpo}`;
  const firma = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    clave,
    new TextEncoder().encode(contenidoFirmado),
  );
  const valor = `${contenidoFirmado}.${base64Url(new Uint8Array(firma))}`;
  jwtApnsEnCache = { valor, creadoEn: ahora };
  return valor;
}

async function borrarSuscripcion(id: string): Promise<void> {
  await supabase.from('push_subscriptions').delete().eq('id', id);
}

async function enviarWebPush(
  suscripcion: Suscripcion,
  contenido: ContenidoPush,
): Promise<void> {
  await webpush.sendNotification(
    {
      endpoint: suscripcion.endpoint,
      keys: { p256dh: suscripcion.p256dh, auth: suscripcion.auth },
    },
    JSON.stringify(contenido),
  ).catch(async (fallo: { statusCode?: number }) => {
    if (fallo.statusCode === 404 || fallo.statusCode === 410) {
      await borrarSuscripcion(suscripcion.id);
    }
    throw fallo;
  });
}

async function enviarApns(
  suscripcion: Suscripcion,
  contenido: ContenidoPush,
): Promise<void> {
  const tokenDispositivo = suscripcion.endpoint.slice('apns:'.length);
  if (!tokenDispositivo) throw new Error('Token APNs vacío');

  // El cliente guarda en `auth` de que entorno salio el token. Un token de
  // desarrollo contra el servidor de produccion responde DeviceTokenNotForTopic
  // aunque todo lo demas este bien.
  const produccion = suscripcion.auth === 'ios_production';
  const servidor = produccion
    ? 'https://api.push.apple.com'
    : 'https://api.sandbox.push.apple.com';
  const respuesta = await fetch(`${servidor}/3/device/${tokenDispositivo}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${await obtenerJwtApns()}`,
      'apns-topic': apnsBundleId,
      'apns-push-type': 'alert',
      'apns-priority': '10',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      aps: {
        alert: { title: contenido.title, body: contenido.body },
        sound: 'default',
      },
      order_id: contenido.order_id,
      store_id: contenido.store_id,
      product_id: contenido.product_id,
    }),
  });

  if (respuesta.ok) return;

  const detalle = await respuesta.json().catch(() => ({})) as {
    reason?: string;
  };
  if (
    respuesta.status === 410 ||
    ['BadDeviceToken', 'Unregistered', 'DeviceTokenNotForTopic'].includes(
      detalle.reason ?? '',
    )
  ) {
    await borrarSuscripcion(suscripcion.id);
  }
  throw new Error(
    `APNs ${respuesta.status}: ${detalle.reason ?? 'respuesta rechazada'}`,
  );
}

Deno.serve(async (peticion) => {
  try {
    const { user_id, title, body, order_id, store_id, product_id } =
      await peticion.json();
    if (!user_id) {
      return new Response('falta user_id', { status: 400 });
    }

    const { data, error } = await supabase
      .from('push_subscriptions')
      .select('id, endpoint, p256dh, auth')
      .eq('user_id', user_id);

    if (error) throw error;
    const suscripciones = (data ?? []) as Suscripcion[];
    if (!suscripciones.length) {
      // Sin dispositivos registrados no hay nada que enviar; no es un fallo.
      return new Response(JSON.stringify({ enviados: 0 }), { status: 200 });
    }

    const contenido: ContenidoPush = {
      title: title ?? 'U market',
      body: body ?? '',
      order_id: order_id ?? null,
      store_id: store_id ?? null,
      product_id: product_id ?? null,
    };

    const resultados = await Promise.allSettled(
      suscripciones.map((suscripcion) =>
        suscripcion.endpoint.startsWith('apns:')
          ? enviarApns(suscripcion, contenido)
          : enviarWebPush(suscripcion, contenido)
      ),
    );

    // Sin esto un envio rechazado se pierde dentro de allSettled y desde
    // fuera solo se ve un contador: en los registros de la funcion queda el
    // motivo que devolvio Apple, que es lo unico que dice por que no llego.
    resultados.forEach((resultado, indice) => {
      if (resultado.status === 'rejected') {
        const destino = suscripciones[indice].endpoint.startsWith('apns:')
          ? 'APNs'
          : 'Web Push';
        console.error(`${destino} rechazado:`, resultado.reason);
      }
    });

    const enviados = resultados.filter((resultado) =>
      resultado.status === 'fulfilled'
    ).length;
    const fallidos = resultados.length - enviados;
    return new Response(JSON.stringify({ enviados, fallidos }), {
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
