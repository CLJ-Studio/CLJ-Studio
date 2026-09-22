import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import 'destino_notificacion_sistema.dart';
import '../modelos/notificacion.dart';

/// Vista tipada de las claves que entrega `PushSubscription.toJSON()`.
///
/// Se declara asi en vez de hurgar el objeto con getProperty: el interop
/// tipado falla en compilacion si el nombre no calza, en vez de devolver
/// null en tiempo de ejecucion.
extension type _SuscripcionJson(JSObject _) implements JSObject {
  external String? get endpoint;
  external _ClavesJson? get keys;
}

extension type _ClavesJson(JSObject _) implements JSObject {
  external String? get p256dh;
  external String? get auth;
}

/// Clave publica VAPID del proyecto. Es publica por diseno: identifica al
/// servidor ante el navegador. La privada solo vive en la Edge Function.
const _clavePublicaVapid =
    'BBZ6ZrJPvdu1JDPkk9LSHQZvuYwJDpwdOfkKDNK78Z5trgP1QfqlkO5X03durNEaGxOKuqIM3AvyhVNsPnpgv54';

/// Ambito propio del service worker de push.
///
/// Registrarlo en la raiz desplazaria al que genera Flutter, del que depende
/// el modo sin conexion: dos service workers no pueden controlar el mismo
/// ambito. Para recibir push no hace falta controlar la pagina.
const _ambitoPush = 'push/';

/// Registra o retira el dispositivo de las notificaciones con la app cerrada.
///
/// Todo se hace desde Dart con las APIs del navegador. Antes dependia de
/// funciones declaradas en index.html, y bastaba con que el navegador
/// sirviera una copia cacheada de ese archivo para que dejara de existir
/// ("suscribirPush is not a function").
abstract final class ServicioPush {
  static bool get soportado => kIsWeb;

  /// Permiso concedido en esta u otra visita. No implica estar suscrito:
  /// el usuario pudo apagar el interruptor conservando el permiso.
  static bool get yaConcedido =>
      kIsWeb && web.Notification.permission == 'granted';

  static bool get denegado => kIsWeb && web.Notification.permission == 'denied';

  /// Motivo del ultimo fallo, para poder mostrarlo en vez de un generico.
  static String? ultimoError;

  static Stream<DestinoNotificacionSistema> get destinosAbiertos =>
      const Stream.empty();

  static Future<void> inicializar() async {}

  /// En Web el aviso ya lo muestra el service worker para evitar duplicados.
  static Future<void> mostrar(Notificacion notificacion) async {}

  /// El service worker abre la PWA con el destino en la URL. Se consume una
  /// sola vez y se limpia para que recargar no repita la navegación.
  static Future<DestinoNotificacionSistema?> consumirDestinoInicial() async {
    final destino = DestinoNotificacionSistema.desdeMapa(
      Uri.base.queryParameters,
    );
    if (!destino.tieneDestino) return null;
    web.window.history.replaceState(null, '', web.window.location.pathname);
    return destino;
  }

  /// Convierte la clave VAPID de base64url a los bytes que espera el
  /// navegador; `subscribe` no acepta la cadena directamente.
  static JSUint8Array _clavePorBytes() {
    final relleno = '=' * ((4 - _clavePublicaVapid.length % 4) % 4);
    final normalizada = (_clavePublicaVapid + relleno)
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    return Uint8List.fromList(base64Decode(normalizada)).toJS;
  }

  static Future<web.ServiceWorkerRegistration?> _registro({
    bool crear = false,
  }) async {
    final trabajadores = web.window.navigator.serviceWorker;
    if (crear) {
      // La ruta va como JSString: la API tambien acepta TrustedScriptURL.
      return await trabajadores
          .register(
            'push_sw.js'.toJS,
            web.RegistrationOptions(scope: _ambitoPush),
          )
          .toDart;
    }

    return trabajadores.getRegistration(_ambitoPush).toDart;
  }

  /// Espera a que el service worker recien registrado este ACTIVO.
  ///
  /// POR QUE: `register()` devuelve la inscripcion en cuanto existe, NO
  /// cuando el trabajador arranca. Entre una cosa y otra hay un hueco en el
  /// que `pushManager.subscribe()` falla con "Subscription failed - no active
  /// Service Worker", que es un error que no dice nada a quien lo lee y que
  /// aparece justo la primera vez que alguien activa las notificaciones, o
  /// despues de borrar los datos del sitio.
  ///
  /// Se consulta en bucle en vez de escuchar `statechange` porque `active` es
  /// un getter vivo de la propia inscripcion: preguntarle es mas corto y no
  /// deja escuchas colgadas si el trabajador nunca arranca.
  static Future<bool> _esperarActivo(
    web.ServiceWorkerRegistration registro, {
    Duration tope = const Duration(seconds: 10),
  }) async {
    final limite = DateTime.now().add(tope);
    while (registro.active == null && DateTime.now().isBefore(limite)) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return registro.active != null;
  }

  /// Si este dispositivo esta recibiendo push ahora mismo. Es lo que refleja
  /// el interruptor: el permiso por si solo no basta.
  static Future<bool> estaActivo() async {
    if (!kIsWeb || !yaConcedido) return false;
    try {
      final registro = await _registro();
      if (registro == null) return false;
      final suscripcion = await registro.pushManager.getSubscription().toDart;
      return suscripcion != null;
    } catch (_) {
      return false;
    }
  }

  /// Pide permiso (si hace falta), se suscribe y guarda la suscripcion.
  static Future<bool> activar() async {
    if (!kIsWeb) return false;
    ultimoError = null;

    try {
      if (web.Notification.permission != 'granted') {
        final respuesta = await web.Notification.requestPermission().toDart;
        if (respuesta.toDart != 'granted') return false;
      }

      final registro = await _registro(crear: true);
      if (registro == null) {
        ultimoError = 'No se pudo registrar el service worker.';
        return false;
      }

      if (!await _esperarActivo(registro)) {
        ultimoError =
            'El navegador todavía está preparando las notificaciones. '
            'Vuelve a intentarlo en unos segundos.';
        return false;
      }

      // Si ya existe una suscripcion se reutiliza: volver a suscribir
      // generaria un endpoint nuevo y duplicaria el dispositivo.
      final suscripcion =
          await registro.pushManager.getSubscription().toDart ??
          await registro.pushManager
              .subscribe(
                web.PushSubscriptionOptionsInit(
                  // Obligatorio en Chrome: prohibe push silenciosos.
                  userVisibleOnly: true,
                  applicationServerKey: _clavePorBytes(),
                ),
              )
              .toDart;

      final datos = _SuscripcionJson(suscripcion.toJSON());
      final claves = datos.keys;
      if (claves?.p256dh == null || claves?.auth == null) {
        ultimoError = 'El navegador no entregó las claves de cifrado.';
        return false;
      }

      final cliente = Supabase.instance.client;
      await cliente.from('push_subscriptions').upsert({
        'user_id': cliente.auth.currentUser!.id,
        'endpoint': suscripcion.endpoint,
        'p256dh': claves!.p256dh,
        'auth': claves.auth,
      }, onConflict: 'endpoint');

      return true;
    } catch (fallo) {
      ultimoError = _explicar(fallo);
      return false;
    }
  }

  /// Traduce el fallo a algo que se pueda leer y sobre lo que se pueda actuar.
  ///
  /// Lo que llegaba antes era el texto crudo del navegador, en ingles y
  /// hablando de service workers: nadie puede hacer nada con eso.
  static String _explicar(Object fallo) {
    if (fallo is PostgrestException) {
      return '${fallo.code ?? ''} ${fallo.message}'.trim();
    }
    final texto = fallo.toString();
    if (texto.contains('no active Service Worker')) {
      return 'El navegador todavía está preparando las notificaciones. '
          'Vuelve a intentarlo en unos segundos.';
    }
    if (texto.contains('permission') || texto.contains('NotAllowedError')) {
      return 'El navegador bloqueó las notificaciones para este sitio. '
          'Se activan desde los ajustes del navegador.';
    }
    return texto;
  }

  /// Deja de recibir push en este dispositivo.
  ///
  /// El permiso del navegador NO se revoca (ninguna API lo permite), pero sin
  /// suscripcion el servidor no tiene por donde enviar nada.
  static Future<bool> desactivar() async {
    if (!kIsWeb) return false;

    try {
      final registro = await _registro();
      final suscripcion = await registro?.pushManager.getSubscription().toDart;
      if (suscripcion == null) return true;

      final endpoint = suscripcion.endpoint;
      await suscripcion.unsubscribe().toDart;

      await Supabase.instance.client
          .from('push_subscriptions')
          .delete()
          .eq('endpoint', endpoint);
      return true;
    } catch (_) {
      return false;
    }
  }
}
