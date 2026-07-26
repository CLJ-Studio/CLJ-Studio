import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'arbol_aplicacion/arbol_aplicacion.dart';
import 'configuracion_aplicacion/configuracion_supabase.dart';

/// Punto de entrada de UPSA Eat.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limita la memoria retenida por fotografías en dispositivos modestos.
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  await Supabase.initialize(
    url: ConfiguracionSupabase.url,
    publishableKey: ConfiguracionSupabase.publishableKey,
  );

  runApp(const ArbolAplicacion());
}

/// Acceso corto al cliente ya inicializado, usado por los repositorios.
SupabaseClient get supabase => Supabase.instance.client;
