import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../configuracion_aplicacion/modo_local.dart';
import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import '../datos/servicio_push.dart';
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
  EscuchaTabla? _escucha;
  final Set<String> _idsConocidos = {};

  int get noLeidas => notificaciones.where((n) => !n.leida).length;

  Future<void> cargar() async {
    if (ModoLocal.activo) {
      cargando = false;
      error = null;
      notifyListeners();
      return;
    }
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
      _idsConocidos.addAll(notificaciones.map((n) => n.id));
    } catch (_) {
      error = 'No se pudieron cargar tus notificaciones.';
    } finally {
      cargando = false;
      notifyListeners();
    }

    // Una sola escucha por sesion, filtrada a los avisos propios. El sondeo
    // interno del ayudante cubre los cortes del websocket.
    _escucha ??= EscuchaTabla(
      tabla: 'notifications',
      filtro: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: usuario.id,
      ),
      alCambiar: _refrescarEnSilencio,
    )..iniciar();
  }

  /// Refresca sin tocar el indicador de carga: la campana no debe parpadear.
  Future<void> _refrescarEnSilencio() async {
    try {
      final filas = await _cliente
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(60);
      final actualizadas = filas.map(Notificacion.desdeMapa).toList();
      final nuevas = actualizadas
          .where((n) => !_idsConocidos.contains(n.id) && !n.leida)
          .toList();

      notificaciones = actualizadas;
      _idsConocidos.addAll(actualizadas.map((n) => n.id));
      notifyListeners();

      // Android convierte aquí la fila nueva en un aviso local. En iPhone el
      // servidor ya envió esa misma fila directamente mediante APNs.
      for (final notificacion in nuevas.reversed) {
        await ServicioPush.mostrar(notificacion);
      }
    } catch (_) {
      // Se reintenta en el siguiente evento o sondeo.
    }
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
    _idsConocidos.clear();
    _escucha?.detener();
    _escucha = null;
    notifyListeners();
  }
}
