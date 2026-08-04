import 'package:flutter/material.dart';

import 'visor_imagen_producto_pantalla.dart';

/// Entrada única al visor inmersivo de fotografías de productos.
abstract final class VisorImagenProducto {
  static Future<int?> abrir({
    required BuildContext context,
    required List<String> imagenes,
    required int indiceInicial,
    required String prefijoHero,
    String? etiquetaSemantica,
  }) {
    final urls = imagenes
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (urls.isEmpty) return Future<int?>.value();

    final indice = indiceInicial.clamp(0, urls.length - 1);
    final reducirMovimiento = MediaQuery.disableAnimationsOf(context);

    return Navigator.of(context).push<int>(
      PageRouteBuilder<int>(
        opaque: true,
        transitionDuration: reducirMovimiento
            ? Duration.zero
            : const Duration(milliseconds: 280),
        reverseTransitionDuration: reducirMovimiento
            ? Duration.zero
            : const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => VisorImagenProductoPantalla(
          urlsImagenes: urls,
          indiceInicial: indice,
          prefijoHero: prefijoHero,
          etiquetaSemantica: etiquetaSemantica,
        ),
        transitionsBuilder: (_, animacion, _, child) =>
            FadeTransition(opacity: animacion, child: child),
      ),
    );
  }
}
