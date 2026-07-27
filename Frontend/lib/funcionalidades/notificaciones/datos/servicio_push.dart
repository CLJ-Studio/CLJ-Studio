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

@JS('Notification.permission')
external String get _permisoActual;

@JS('Notification.requestPermission')
external JSPromise<JSAny?> _pedirPermiso();

@JS('window.suscribirPush')
external JSPromise<JSAny?> _suscribirPush(String clave);

@JS('window.estadoPush')
external JSPromise<JSAny?> _estadoPush();

@JS('window.desuscribirPush')
external JSPromise<JSAny?> _desuscribirPush();

/// Registra o retira el dispositivo de las notificaciones con la app cerrada.
///
/// Solo aplica a Flutter Web. En iOS, Safari unicamente entrega push si el
/// usuario agrego la PWA a su pantalla de inicio (iOS 16.4+); en Android y
/// escritorio funciona sin instalar.
abstract final class ServicioPush {
  static bool get soportado => kIsWeb;

  /// Permiso concedido en esta u otra visita. No implica estar suscrito:
  /// el usuario pudo apagar el interruptor conservando el permiso.
  static bool get yaConcedido => kIsWeb && _permisoActual == 'granted';

  static bool get denegado => kIsWeb && _permisoActual == 'denied';

  /// Si este dispositivo esta recibiendo push ahora mismo. Es lo que refleja
  /// el interruptor: el permiso por si solo no basta.
  static Future<bool> estaActivo() async {
    if (!kIsWeb || !yaConcedido) return false;
    try {
      final endpoint = ((await _estadoPush().toDart) as JSString?)?.toDart;
      return endpoint != null && endpoint.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Motivo del ultimo fallo, para poder mostrarlo en vez de un generico.
  static String? ultimoError;

  /// Pide permiso (si hace falta), se suscribe y guarda la suscripcion.
  /// Devuelve true si el dispositivo quedo registrado.
  static Future<bool> activar() async {
    if (!kIsWeb) return false;
    ultimoError = null;

    try {
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
    } catch (fallo) {
      // Sin esto, cualquier fallo se veia como "No se pudieron activar" y
      // habia que abrir las herramientas del navegador para saber por que.
      ultimoError = fallo is PostgrestException
          ? '${fallo.code ?? ''} ${fallo.message}'.trim()
          : fallo.toString();
      return false;
    }
  }

  /// Deja de recibir push en este dispositivo.
  ///
  /// El permiso del navegador NO se revoca (ninguna API lo permite), pero sin
  /// suscripcion el servidor no tiene por donde enviar nada. Reactivar luego
  /// es inmediato: al seguir concedido el permiso, no se vuelve a preguntar.
  static Future<bool> desactivar() async {
    if (!kIsWeb) return false;

    try {
      final crudo = await _desuscribirPush().toDart;
      final endpoint = (crudo as JSString?)?.toDart;

      // Se borra la fila aunque el navegador ya no tuviera suscripcion:
      // deja de intentarse el envio contra un endpoint muerto.
      if (endpoint != null && endpoint.isNotEmpty) {
        await Supabase.instance.client
            .from('push_subscriptions')
            .delete()
            .eq('endpoint', endpoint);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
