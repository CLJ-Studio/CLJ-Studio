import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'arbol_aplicacion/arbol_aplicacion.dart';
import 'configuracion_aplicacion/modo_local.dart';
import 'configuracion_aplicacion/configuracion_supabase.dart';
import 'elementos_compartidos/animaciones/precargador_animaciones.dart';
import 'funcionalidades/notificaciones/datos/servicio_push.dart';

/// Punto de entrada de U market.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // Web conserva su service worker. iPhone se registra directamente con
    // APNs y Android prepara su centro de notificaciones local, sin Firebase.
    await ServicioPush.inicializar();
  }

  runApp(const ArbolAplicacion());
  PrecargadorAnimaciones.iniciar();
}

/// Acceso corto al cliente ya inicializado, usado por los repositorios.
SupabaseClient get supabase => Supabase.instance.client;
