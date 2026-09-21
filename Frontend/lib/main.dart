import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'arbol_aplicacion/arbol_aplicacion.dart';
import 'configuracion_aplicacion/configuracion_tema.dart';
import 'configuracion_aplicacion/modo_local.dart';
import 'configuracion_aplicacion/configuracion_supabase.dart';
import 'elementos_compartidos/animaciones/precargador_animaciones.dart';
import 'funcionalidades/notificaciones/datos/servicio_push.dart';
import 'funcionalidades/venta_rapida/datos/servicio_atajo_venta_rapida.dart';

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

  // ANTES DE TOCAR ESTO: nada que pueda tardar o fallar debe ejecutarse
  // antes de `runApp`. Hasta que `runApp` corre, la pantalla es la del
  // sistema y no hay forma de avisar de nada: una sola llamada que se quede
  // esperando deja el telefono congelado en el logo, sin error ni pista.
  // Aqui solo queda lo imprescindible, y hasta eso con tope de tiempo.
  var iniciado = true;
  if (!ModoLocal.activo) {
    // Supabase si es imprescindible: el porton de autenticacion consulta
    // `Supabase.instance` al construirse, asi que el arbol no puede nacer
    // antes que el.
    try {
      await Supabase.initialize(
        url: ConfiguracionSupabase.url,
        publishableKey: ConfiguracionSupabase.publishableKey,
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      iniciado = false;
    }
  }

  // Siempre se dibuja algo, incluso cuando lo anterior fallo. Una pantalla
  // que explica y ofrece reintentar es mejor que un logo detenido.
  runApp(iniciado ? const ArbolAplicacion() : const _NoArranco());

  if (!iniciado) return;

  PrecargadorAnimaciones.iniciar();
  // El resto arranca con la aplicacion ya en pantalla. Son extras: el atajo
  // de iPhone y las notificaciones. Que tarden o fallen no puede costar el
  // arranque, y los dos hablan con el sistema operativo por un canal que
  // puede no responder nunca.
  if (!ModoLocal.activo) unawaited(_iniciarExtras());
}

Future<void> _iniciarExtras() async {
  // Expone la venta rápida como una acción nativa de Atajos en iPhone.
  // La sesión se comparte con iOS para que el atajo pueda consultar el
  // inventario y descontar stock sin mostrar la interfaz de Flutter.
  //
  // Web conserva su service worker. iPhone se registra directamente con
  // APNs y Android prepara su centro de notificaciones local, sin Firebase.
  for (final arrancar in [
    ServicioAtajoVentaRapida.inicializar,
    ServicioPush.inicializar,
  ]) {
    try {
      await arrancar().timeout(const Duration(seconds: 15));
    } catch (_) {
      // Sin atajo o sin notificaciones se puede vivir; sin aplicacion no.
    }
  }
}

/// Lo que se ve cuando no se pudo contactar al servidor al arrancar.
///
/// Existe para que nunca haya un arranque mudo: sin esto, un servidor caido
/// o un telefono sin datos dejaban la pantalla del sistema para siempre y
/// parecia que la aplicacion estaba rota.
class _NoArranco extends StatelessWidget {
  const _NoArranco();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ConfiguracionTema.temaClaro,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No pudimos conectar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Revisa tu conexión y vuelve a abrir U market.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF848381)),
              ),
              const SizedBox(height: 22),
              FilledButton(onPressed: main, child: const Text('Reintentar')),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Acceso corto al cliente ya inicializado, usado por los repositorios.
SupabaseClient get supabase => Supabase.instance.client;
