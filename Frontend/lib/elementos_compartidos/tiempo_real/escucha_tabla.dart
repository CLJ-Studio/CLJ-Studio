import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Suscripcion a los cambios de una tabla, con reintento y respaldo.
///
/// Evita repetir en cada controlador el mismo cableado de canal, y sobre
/// todo evita el modo de fallo que teniamos: si el websocket no conecta o se
/// cae, la pantalla se quedaba congelada esperando un evento que no llegaba.
/// Aqui un sondeo corto garantiza que la vista avance igual.
class EscuchaTabla {
  EscuchaTabla({
    required this.tabla,
    required this.alCambiar,
    this.filtro,
    this.respaldo = const Duration(seconds: 3),
  });

  /// Nombre de la tabla en el esquema public.
  final String tabla;

  /// Se invoca ante cualquier alta, cambio o baja relevante.
  final void Function() alCambiar;

  /// Restringe los eventos a una fila o conjunto (p. ej. user_id = X).
  final PostgresChangeFilter? filtro;

  /// Cada cuanto refrescar si el websocket no esta entregando.
  final Duration respaldo;

  RealtimeChannel? _canal;
  Timer? _sondeo;
  bool _recibioEvento = false;

  void iniciar() {
    detener();

    _canal = Supabase.instance.client
        .channel('vivo_$tabla${filtro == null ? '' : '_filtrado'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tabla,
          filter: filtro,
          callback: (_) {
            _recibioEvento = true;
            alCambiar();
          },
        )
        .subscribe();

    // Mientras el canal no de senales de vida, se refresca por sondeo. En
    // cuanto llega el primer evento el sondeo se espacia, para no castigar
    // la base cuando el tiempo real ya funciona.
    _sondeo = Timer.periodic(respaldo, (_) {
      if (!_recibioEvento) alCambiar();
    });
  }

  void detener() {
    _sondeo?.cancel();
    _sondeo = null;
    if (_canal != null) {
      Supabase.instance.client.removeChannel(_canal!);
      _canal = null;
    }
    _recibioEvento = false;
  }
}
