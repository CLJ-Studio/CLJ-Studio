import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../configuracion_aplicacion/version_aplicacion.dart';

/// Los errores que nadie atrapo quedan anotados en la base (tabla
/// `errores_app`), para enterarse de lo que falla sin depender de capturas
/// por WhatsApp.
///
/// Son los que Flutter pinta en rojo y los que se escapan de una tarea. Nunca
/// rompe nada: sin red o sin servidor, el error se pierde en silencio. Y no
/// inunda: el mismo error se manda una vez por sesion, y como mucho
/// [maximoPorSesion] distintos. La base, ademas, junta los repetidos.
class RegistroErrores {
  RegistroErrores(this._enviar);

  /// Lo que manda cada error a la base. En las pruebas, una lista.
  final Future<void> Function(Map<String, Object?> datos) _enviar;

  static const maximoPorSesion = 20;

  final _vistos = <String>{};

  /// Se engancha a Flutter. Es instantaneo: `main` lo llama antes de
  /// `runApp`. En modo debug no hace nada, para no llenar la tabla con lo que
  /// se rompe mientras se programa.
  static void iniciar() {
    if (kDebugMode) return;
    final registro = RegistroErrores(_enviarASupabase);

    final anterior = FlutterError.onError;
    FlutterError.onError = (detalles) {
      anterior?.call(detalles);
      registro.anotar(
        detalles.exception,
        detalles.stack,
        contexto: detalles.context?.toDescription(),
      );
    };

    final anteriorPlataforma = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, pila) {
      registro.anotar(error, pila, contexto: 'sin atrapar');
      return anteriorPlataforma?.call(error, pila) ?? false;
    };
  }

  void anotar(Object error, StackTrace? pila, {String? contexto}) {
    try {
      final mensaje = error.toString();
      final textoPila = pila?.toString() ?? '';
      final firma = '$mensaje\n${textoPila.split('\n').take(3).join('\n')}';
      if (_vistos.length >= maximoPorSesion || !_vistos.add(firma)) return;

      final datos = <String, Object?>{
        'p_mensaje': _recortar(mensaje, 500),
        'p_pila': _recortar(textoPila, 4000),
        'p_contexto': contexto == null ? null : _recortar(contexto, 300),
        'p_version': VersionAplicacion.completa,
        'p_plataforma': kIsWeb ? 'web' : defaultTargetPlatform.name,
      };
      unawaited(
        Future.sync(() => _enviar(datos)).catchError((Object _) {
          // Si no se pudo anotar, se pierde: avisar de un error no puede
          // producir otro.
        }),
      );
    } catch (_) {
      // Lo mismo: el registro nunca es el que rompe.
    }
  }

  static String _recortar(String texto, int largo) =>
      texto.length <= largo ? texto : texto.substring(0, largo);

  static Future<void> _enviarASupabase(Map<String, Object?> datos) async {
    final SupabaseClient cliente;
    try {
      cliente = Supabase.instance.client;
    } catch (_) {
      // Fallo antes de conectar con el servidor: no hay a donde mandarlo.
      return;
    }
    await cliente
        .rpc<void>('registrar_error', params: datos)
        .timeout(const Duration(seconds: 10));
  }
}
