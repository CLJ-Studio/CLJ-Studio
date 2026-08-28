import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/mensaje_pedido.dart';

/// Mensajes de un pedido.
///
/// Nada escribe la tabla directamente: enviar pasa por `enviar_mensaje()`,
/// que aplica el mismo filtro de contenido que el resto de la aplicación. Un
/// insert directo se lo saltaría, y un chat privado es justo el mejor sitio
/// para acosar a alguien sin que nadie mire.
class RepositorioChatPedido {
  const RepositorioChatPedido();

  SupabaseClient get _cliente => Supabase.instance.client;

  Future<List<MensajePedido>> leer(String pedidoId) async {
    final filas = await _cliente.rpc(
      'leer_chat',
      params: {'p_order_id': pedidoId},
    );
    return (filas as List)
        .cast<Map<String, dynamic>>()
        .map(MensajePedido.desdeMapa)
        .toList();
  }

  Future<void> enviar(String pedidoId, String texto) => _cliente.rpc(
    'enviar_mensaje',
    params: {'p_order_id': pedidoId, 'p_cuerpo': texto},
  );

  Future<void> marcarLeidos(String pedidoId) =>
      _cliente.rpc('marcar_mensajes_leidos', params: {'p_order_id': pedidoId});

  /// Cuántos mensajes sin leer hay por pedido, para pintar el distintivo sin
  /// traerse los hilos enteros.
  Future<Map<String, int>> sinLeerPorPedido() async {
    final filas = await _cliente.rpc('mensajes_sin_leer');
    return {
      for (final fila in (filas as List).cast<Map<String, dynamic>>())
        fila['order_id'] as String: (fila['sin_leer'] as num).toInt(),
    };
  }

  /// Emite el hilo entero cada vez que cambia.
  ///
  /// Igual que la pantalla de espera del pedido: Realtime como camino normal y
  /// un sondeo corto de respaldo. En un chat la espera se nota más que en
  /// ningún otro sitio, así que si el websocket no conecta —red del campus,
  /// proxy, pestaña suspendida— la conversación tiene que avanzar igual en vez
  /// de parecer que la otra persona dejó de contestar.
  Stream<List<MensajePedido>> escuchar(String pedidoId) {
    late final StreamController<List<MensajePedido>> controlador;
    StreamSubscription<dynamic>? tiempoReal;
    Timer? sondeo;

    Future<void> emitir() async {
      if (controlador.isClosed) return;
      try {
        controlador.add(await leer(pedidoId));
      } catch (error) {
        // El chat cerrado no es un fallo de red: el pedido se entregó
        // mientras la pantalla estaba abierta y ya no hay hilo que leer.
        if (error.toString().contains('CHAT_CERRADO')) {
          if (!controlador.isClosed) controlador.addError(error);
          return;
        }
        // Cualquier otro fallo es puntual: lo reintenta el siguiente sondeo.
      }
    }

    controlador = StreamController<List<MensajePedido>>(
      onListen: () {
        emitir();
        sondeo = Timer.periodic(const Duration(seconds: 4), (_) => emitir());
        try {
          tiempoReal = _cliente
              .from('mensajes_pedido')
              .stream(primaryKey: ['id'])
              .eq('order_id', pedidoId)
              .listen((_) => emitir(), onError: (_) {});
        } catch (_) {
          // Sin websocket queda el sondeo.
        }
      },
      onCancel: () {
        sondeo?.cancel();
        tiempoReal?.cancel();
      },
    );

    return controlador.stream;
  }
}
