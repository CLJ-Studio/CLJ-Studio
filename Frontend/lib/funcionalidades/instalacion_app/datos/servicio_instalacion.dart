import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Vista tipada de `BeforeInstallPromptEvent`.
///
/// No esta en package:web porque no es estandar: solo existe en los
/// navegadores derivados de Chromium. Se declara asi en vez de hurgar el
/// objeto a mano para que el interop falle en compilacion y no en tiempo de
/// ejecucion, igual que en el servicio de push.
extension type _EventoInstalacion(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prompt();
  external JSPromise<_Eleccion> get userChoice;
}

extension type _Eleccion(JSObject _) implements JSObject {
  /// 'accepted' o 'dismissed'.
  external String get outcome;
}

/// Instalacion de la PWA en la pantalla de inicio.
///
/// Hay dos mundos distintos y no se pueden tratar igual:
///
/// - Chromium (Android, escritorio) avisa con `beforeinstallprompt` y deja
///   abrir el dialogo del sistema cuando queramos. Sin capturarlo, instalar
///   queda escondido en el menu del navegador y casi nadie lo encuentra.
/// - Safari en iOS no implementa nada de eso y jamas ofrece instalar. Lo
///   unico posible es explicar el gesto manual. Importa mas de lo que
///   parece: en iOS las notificaciones push solo llegan si la app esta en la
///   pantalla de inicio, asi que quien se quede en el navegador no recibe
///   aviso de sus pedidos y no tiene forma de saber por que.
abstract final class ServicioInstalacion {
  static _EventoInstalacion? _evento;
  static bool _escuchando = false;

  /// Recoge el evento que index.html pudo haber guardado antes de que
  /// Flutter arrancara y deja un listener propio para los que lleguen luego.
  static void iniciar() {
    if (!kIsWeb || _escuchando) return;
    _escuchando = true;

    final guardado = web.window.getProperty('eventoInstalacion'.toJS);
    if (guardado != null) _evento = _EventoInstalacion(guardado as JSObject);

    web.window.addEventListener(
      'beforeinstallprompt',
      (web.Event evento) {
        // Sin esto Chrome muestra su propia barrita ademas de la nuestra.
        evento.preventDefault();
        _evento = _EventoInstalacion(evento as JSObject);
      }.toJS,
    );

    // Tras instalar, el evento ya no sirve: no debe quedar un boton que abra
    // un dialogo muerto.
    web.window.addEventListener(
      'appinstalled',
      (web.Event _) {
        _evento = null;
      }.toJS,
    );
  }

  /// Ya se abrio desde la pantalla de inicio, no desde el navegador.
  static bool get yaInstalada {
    if (!kIsWeb) return false;
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
    // Safari en iOS no soporta esa media query; usa su propia bandera.
    final propia = web.window.navigator.getProperty('standalone'.toJS);
    return propia != null && (propia as JSBoolean).toDart;
  }

  /// El navegador acepta instalar ahora mismo (Android y escritorio).
  static bool get puedeInstalar => kIsWeb && _evento != null && !yaInstalada;

  static bool get esIOS {
    if (!kIsWeb) return false;
    final navegador = web.window.navigator;
    final agente = navegador.userAgent;
    if (RegExp('iPhone|iPad|iPod').hasMatch(agente)) return true;
    // El iPad moderno se anuncia como Mac: se distingue por ser tactil.
    return agente.contains('Macintosh') && navegador.maxTouchPoints > 1;
  }

  /// En iOS no hay dialogo posible: toca explicar Compartir y "Añadir a
  /// pantalla de inicio".
  static bool get requiereGestoManual => esIOS && !yaInstalada;

  /// Abre el dialogo del sistema. Devuelve si la persona acepto.
  ///
  /// El evento es de un solo uso: una vez consumido el navegador no lo
  /// vuelve a entregar hasta la siguiente visita.
  static Future<bool> instalar() async {
    final evento = _evento;
    if (evento == null) return false;

    try {
      await evento.prompt().toDart;
      final eleccion = await evento.userChoice.toDart;
      final acepto = eleccion.outcome == 'accepted';
      if (acepto) _evento = null;
      return acepto;
    } catch (_) {
      return false;
    }
  }
}
