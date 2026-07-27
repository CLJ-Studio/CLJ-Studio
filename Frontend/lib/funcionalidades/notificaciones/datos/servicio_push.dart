@JS()
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clave publica VAPID del proyecto. Es publica por diseno: identifica al
/// servidor ante el navegador. La privada solo vive en la Edge Function.
const _clavePublicaVapid =
    'BBZ6ZrJPvdu1JDPkk9LSHQZvuYwJDpwdOfkKDNK78Z5trgP1QfqlkO5X03durNEaGxOKuqIM3AvyhVNsPnpgv54';

@JS('navigator.serviceWorker.register')
external JSPromise<JSAny?> _registrarSw(String ruta);

@JS('Notification.permission')
external String get _permisoActual;

@JS('Notification.requestPermission')
external JSPromise<JSAny?> _pedirPermiso();

@JS('window.suscribirPush')
external JSPromise<JSAny?> _suscribirPush(String clave);

/// Registra el dispositivo para recibir notificaciones con la app cerrada.
///
/// Solo aplica a Flutter Web. En iOS, Safari unicamente entrega push si el
/// usuario agrego la PWA a su pantalla de inicio (iOS 16.4+); en Android y
/// escritorio funciona sin instalar.
abstract final class ServicioPush {
  static bool get soportado => kIsWeb;

  /// Ya concedido en una visita anterior: permite resuscribir en silencio,
  /// sin volver a mostrar el dialogo del navegador.
  static bool get yaConcedido => kIsWeb && _permisoActual == 'granted';

  static bool get denegado => kIsWeb && _permisoActual == 'denied';

  /// Pide permiso (si hace falta), se suscribe y guarda la suscripcion.
  /// Devuelve true si el dispositivo quedo registrado.
  static Future<bool> activar() async {
    if (!kIsWeb) return false;

    try {
      await _registrarSw('push_sw.js').toDart;

      if (_permisoActual != 'granted') {
        final respuesta = await _pedirPermiso().toDart;
        if ((respuesta as JSString?)?.toDart != 'granted') return false;
      }

      final crudo = await _suscribirPush(_clavePublicaVapid).toDart;
      final json = (crudo as JSString?)?.toDart;
      if (json == null || json.isEmpty) return false;

      final suscripcion = jsonDecode(json) as Map<String, dynamic>;
      final claves = suscripcion['keys'] as Map<String, dynamic>;

      final cliente = Supabase.instance.client;
      // upsert por endpoint: reabrir la app no duplica el dispositivo.
      await cliente.from('push_subscriptions').upsert({
        'user_id': cliente.auth.currentUser!.id,
        'endpoint': suscripcion['endpoint'],
        'p256dh': claves['p256dh'],
        'auth': claves['auth'],
      }, onConflict: 'endpoint');

      return true;
    } catch (_) {
      return false;
    }
  }
}
