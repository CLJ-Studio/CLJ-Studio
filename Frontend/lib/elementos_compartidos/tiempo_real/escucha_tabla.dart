import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Suscripcion a los cambios de una tabla, con reintento y respaldo.
///
/// Evita repetir en cada controlador el mismo cableado de canal, y sobre
/// todo evita el modo de fallo que teniamos: si el websocket no conecta o se
/// cae, la pantalla se quedaba congelada esperando un evento que no llegaba.
/// Aqui un sondeo corto garantiza que la vista avance igual.
///
/// EL SONDEO SOLO APURA CUANDO HACE FALTA. Antes corria cada 12 segundos
/// siempre, aunque el canal en vivo funcionara perfecto, y cada sondeo hace
/// que el controlador recargue y reconstruya su pantalla. El inicio tiene tres
/// escuchas: eran una recarga completa del catalogo cada 4 segundos en
/// promedio, con la aplicacion quieta, en el mismo hilo que dibuja. Eso se
/// veia como tirones al desplazarse. Ahora:
///
///   · con el canal vivo, el respaldo pasa cada [respaldoConCanalVivo], y
///     solo si en ese rato no llego ningun aviso;
///   · con el canal caido, cada [respaldo], como antes.
///
/// El respaldo nunca se apaga del todo: se mantuvo justamente porque un aviso
/// perdido dejaba la pantalla congelada hasta recargar el navegador.
class EscuchaTabla {
  EscuchaTabla({
    required this.tabla,
    required this.alCambiar,
    this.filtro,
    this.respaldo = const Duration(seconds: 12),
    this.respaldoConCanalVivo = const Duration(minutes: 2),
    this.minimoEntreAvisos = Duration.zero,
  });

  /// Nombre de la tabla en el esquema public.
  final String tabla;

  /// Se invoca ante cualquier alta, cambio o baja relevante.
  final void Function() alCambiar;

  /// Restringe los eventos a una fila o conjunto (p. ej. user_id = X).
  final PostgresChangeFilter? filtro;

  /// Cada cuanto refrescar si el websocket no esta entregando.
  final Duration respaldo;

  /// Cada cuanto refrescar aunque el canal este vivo, por si se perdio algo.
  final Duration respaldoConCanalVivo;

  /// Si llegan muchos avisos seguidos, se juntan en uno cada este tiempo.
  ///
  /// Hace falta porque hay tablas que cambian sin que nada visible cambie:
  /// `products` suma una visita cada vez que alguien abre un producto, asi
  /// que en un campus con movimiento los avisos llegan uno tras otro. En cero
  /// (lo normal) cada aviso pasa al instante, que es lo que quiere un chat.
  final Duration minimoEntreAvisos;

  RealtimeChannel? _canal;
  Timer? _sondeo;
  Timer? _avisoPendiente;
  bool _canalVivo = false;
  DateTime _ultimoAviso = DateTime.now();
  DateTime? _ultimaEntrega;

  void iniciar() {
    detener();

    _canal = Supabase.instance.client
        .channel('vivo_$tabla${filtro == null ? '' : '_filtrado'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tabla,
          filter: filtro,
          callback: (_) => _avisar(),
        )
        .subscribe((estado, _) {
          _canalVivo = estado == RealtimeSubscribeStatus.subscribed;
        });

    _ultimoAviso = DateTime.now();
    _sondeo = Timer.periodic(respaldo, (_) {
      final reciente =
          DateTime.now().difference(_ultimoAviso) < respaldoConCanalVivo;
      if (_canalVivo && reciente) return;
      _avisar();
    });
  }

  void _avisar() {
    _ultimoAviso = DateTime.now();
    if (minimoEntreAvisos == Duration.zero) {
      alCambiar();
      return;
    }
    // Ya hay uno en camino: este se suma a ese.
    if (_avisoPendiente != null) return;
    final ultima = _ultimaEntrega;
    final espera = ultima == null
        ? Duration.zero
        : minimoEntreAvisos - DateTime.now().difference(ultima);
    _avisoPendiente = Timer(espera.isNegative ? Duration.zero : espera, () {
      _avisoPendiente = null;
      _ultimaEntrega = DateTime.now();
      alCambiar();
    });
  }

  void detener() {
    _sondeo?.cancel();
    _sondeo = null;
    _avisoPendiente?.cancel();
    _avisoPendiente = null;
    _canalVivo = false;
    if (_canal != null) {
      Supabase.instance.client.removeChannel(_canal!);
      _canal = null;
    }
  }
}
