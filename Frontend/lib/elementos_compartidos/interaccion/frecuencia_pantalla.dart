import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// La tasa de refresco de la pantalla del telefono.
///
/// Muchos Android dejan las apps en 60 Hz aunque la pantalla de 90 o 120.
/// Lo que se anima mucho (la mesa de blackjack de MacIAs) pide la mas alta
/// mientras esta abierto, y la devuelve al cerrarse para no gastar bateria
/// en el resto de la app. En la web y en iPhone no hace nada: ahi decide el
/// sistema (y en iPhone ya va a la tasa de la pantalla).
abstract final class FrecuenciaPantalla {
  static const _canal = MethodChannel('com.cljstudio.umarket/pantalla');

  static Future<void> pedirAlta({required bool activar}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _canal.invokeMethod<void>('altaFrecuencia', activar);
    } on Exception {
      // Una version vieja de la app nativa o un telefono que no deja: la
      // mesa funciona igual, a la tasa que elija el sistema.
    }
  }
}
