import 'dart:async';

import 'package:lottie/lottie.dart';

/// Prepara las composiciones Lottie antes de que sus pantallas las necesiten.
///
/// `AssetLottie` comparte una caché global por ruta. Al cargar aquí los JSON,
/// los widgets posteriores reciben la composición ya interpretada y pueden
/// dibujar su primer cuadro junto con la pantalla.
abstract final class PrecargadorAnimaciones {
  static const _rutas = [
    'assets/animations/loader.json',
    'assets/animations/owls.json',
    'assets/animations/owls-2.json',
    'assets/animations/contactando-vendedor.json',
  ];

  static void iniciar() {
    for (final ruta in _rutas) {
      unawaited(_precargar(ruta));
    }
  }

  static Future<void> _precargar(String ruta) async {
    try {
      await AssetLottie(ruta, backgroundLoading: true).load();
    } catch (_) {
      // Si falla, Lottie volverá a intentarlo cuando su widget aparezca.
      // La precarga nunca bloquea el inicio de la aplicación.
    }
  }
}
