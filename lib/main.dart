import 'package:flutter/material.dart';

import 'arbol_aplicacion/arbol_aplicacion.dart';

/// Punto de entrada de UPSA Eat.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Limita la memoria retenida por fotografías en dispositivos modestos.
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  runApp(const ArbolAplicacion());
}
