import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mantiene disponible la sesión que usa el Atajo de Apple.
///
/// El atajo corre como una acción nativa en segundo plano. iOS guarda sus
/// credenciales en el llavero y Flutter las actualiza en cada cambio de sesión.
abstract final class ServicioAtajoVentaRapida {
  static const _canal = MethodChannel(
    'com.cljstudio.umarket/atajo_venta_rapida',
  );

  static StreamSubscription<AuthState>? _suscripcion;

  static Future<void> inicializar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    final autenticacion = Supabase.instance.client.auth;
    try {
      // Si el atajo renovó el token mientras Flutter estaba cerrado, adopta
      // primero ese token para no mantener dos sesiones divergentes.
      final nativa = await _canal.invokeMapMethod<String, dynamic>(
        'latestSession',
      );
      final tokenNativo = nativa?['refreshToken'] as String?;
      final tokenFlutter = autenticacion.currentSession?.refreshToken;
      if (tokenNativo != null &&
          tokenNativo.isNotEmpty &&
          tokenNativo != tokenFlutter) {
        await autenticacion.setSession(tokenNativo);
      }

      await _sincronizar(autenticacion.currentSession);
      _suscripcion ??= autenticacion.onAuthStateChange.listen((estado) {
        unawaited(_sincronizar(estado.session));
      });
    } on MissingPluginException {
      // Android y web no incluyen esta integración.
    } on PlatformException {
      // Un fallo del llavero no debe impedir arrancar la app.
    } catch (_) {
      // La sesión normal de Flutter sigue funcionando aunque Atajos no pueda
      // sincronizarse temporalmente.
    }
  }

  static Future<void> _sincronizar(Session? sesion) async {
    try {
      await _canal.invokeMethod<void>('syncSession', {
        'accessToken': sesion?.accessToken,
        'refreshToken': sesion?.refreshToken,
        'userId': sesion?.user.id,
      });
    } on MissingPluginException {
      // La función solo existe en iOS.
    } on PlatformException {
      // Se volverá a intentar en el próximo evento de autenticación.
    }
  }
}
