import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/notificacion.dart';

/// Notificaciones del usuario y su contador de no leidas.
///
/// Singleton porque lo comparten la campana del encabezado (contador) y la
/// pantalla de la lista. Escucha Realtime para reaccionar al instante y,
/// como respaldo ante cortes del websocket, refresca al abrir la pantalla.
class ControladorNotificaciones extends ChangeNotifier {
  ControladorNotificaciones._();

  static final ControladorNotificaciones instancia =
      ControladorNotificaciones._();

  SupabaseClient get _cliente => Supabase.instance.client;

  List<Notificacion> notificaciones = const [];
  bool cargando = false;
  String? error;
  StreamSubscription<dynamic>? _tiempoReal;

  int get noLeidas => notificaciones.where((n) => !n.leida).length;

  Future<void> cargar() async {
    final usuario = _cliente.auth.currentUser;
    if (usuario == null) return;

    cargando = true;
    error = null;
    notifyListeners();
    try {
      final filas = await _cliente
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(60);
      notificaciones = filas.map(Notificacion.desdeMapa).toList();
    } catch (_) {
      error = 'No se pudieron cargar tus notificaciones.';
    } finally {
      cargando = false;
      notifyListeners();
    }

    // Una sola suscripcion por sesion; los errores del canal se ignoran
    // porque el refresco al abrir la pantalla es el respaldo.
    _tiempoReal ??= _cliente
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', usuario.id)
        .listen((_) => cargar(), onError: (_) {});
  }

  Future<void> marcarLeida(Notificacion notificacion) async {
    if (notificacion.leida) return;
    try {
      await _cliente
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', notificacion.id);
      await cargar();
    } catch (_) {
      // Sin drama: seguira apareciendo como no leida.
    }
  }

  Future<void> marcarTodasLeidas() async {
    try {
      await _cliente
          .from('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .filter('read_at', 'is', null);
      await cargar();
    } catch (_) {}
  }

  /// Al cerrar sesion: sin esto, el siguiente usuario veria avisos ajenos.
  void limpiar() {
    notificaciones = const [];
    _tiempoReal?.cancel();
    _tiempoReal = null;
    notifyListeners();
  }
}
