import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'arbol_aplicacion/arbol_aplicacion.dart';
import 'configuracion_aplicacion/modo_local.dart';
import 'configuracion_aplicacion/configuracion_supabase.dart';

/// Punto de entrada de UPSA Eat.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();

  // La app dibuja detras de la barra de estado y la de navegacion, como
  // cualquier app nativa. Sin esto quedaba una franja del color del sistema
  // arriba y la pantalla se veia recortada.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Limita la memoria retenida por fotografías en dispositivos modestos.
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  if (!ModoLocal.activo) {
    await Supabase.initialize(
      url: ConfiguracionSupabase.url,
      publishableKey: ConfiguracionSupabase.publishableKey,
    );
  }

  runApp(
    LiquidGlassWidgets.wrap(
      child: const ArbolAplicacion(),
      adaptiveQuality: true,
    ),
  );
}

/// Acceso corto al cliente ya inicializado, usado por los repositorios.
SupabaseClient get supabase => Supabase.instance.client;
