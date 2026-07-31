import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/pedido.dart';

/// Contacto de WhatsApp revelado tras aceptar un pedido.
class ContactoPedido {
  const ContactoPedido({
    required this.nombre,
    required this.whatsapp,
    required this.enlace,
  });

  final String nombre;
  final String whatsapp;
  final String enlace;
}

/// Pedidos: lectura por vista y transiciones por funciones del servidor.
///
/// Ningun metodo escribe `orders` directamente. Los clientes no tienen
/// permiso de UPDATE sobre esa tabla: cambiar de estado solo es posible a
/// traves de estas funciones, que validan quien es el actor y descuentan
/// o restituyen stock de forma atomica.
class RepositorioPedidos {
  const RepositorioPedidos();

  SupabaseClient get _cliente => Supabase.instance.client;
  String get _usuarioId => _cliente.auth.currentUser!.id;

  /// Compras del usuario (es el comprador).
  Future<List<Pedido>> misCompras() => _consultar('buyer_id');

  /// Ventas del usuario (es el vendedor).
  Future<List<Pedido>> misVentas() => _consultar('seller_id');

  Future<List<Pedido>> _consultar(String columna) async {
    final filas = await _cliente
        .from('pedidos_detallados')
        .select()
        .eq(columna, _usuarioId)
        .order('created_at', ascending: false);

    return filas.map(Pedido.desdeMapa).toList();
  }

  Future<Pedido?> obtener(String pedidoId) async {
    final fila = await _cliente
        .from('pedidos_detallados')
        .select()
        .eq('id', pedidoId)
        .maybeSingle();

    return fila == null ? null : Pedido.desdeMapa(fila);
  }

  /// Devuelve el id del pedido creado.
  Future<String> crear({
    required List<Map<String, dynamic>> items,
    String? puntoEncuentro,
    String? nota,
  }) async {
    final id = await _cliente.rpc(
      'crear_pedido',
      params: {
        'p_items': items,
        'p_meeting_point_note': puntoEncuentro,
        'p_buyer_note': nota,
      },
    );
    return id as String;
  }

  Future<void> aceptar(String pedidoId) =>
      _cliente.rpc('aceptar_pedido', params: {'p_order_id': pedidoId});

  Future<void> rechazar(String pedidoId, {String? motivo}) => _cliente.rpc(
    'rechazar_pedido',
    params: {'p_order_id': pedidoId, 'p_motivo': motivo},
  );

  Future<void> cancelar(String pedidoId, {String? motivo}) => _cliente.rpc(
    'cancelar_pedido',
    params: {'p_order_id': pedidoId, 'p_motivo': motivo},
  );

  /// Deja el pedido esperando la confirmación de la otra parte.
  ///
  /// Ya no lo cierra: quien entrega lo marca, quien recibe lo confirma. Antes
  /// una sola persona cerraba el pedido por las dos.
  Future<void> marcarEntregado(String pedidoId) =>
      _cliente.rpc('marcar_entregado', params: {'p_order_id': pedidoId});

  /// Cierra el pedido. Solo la acepta quien NO marcó la entrega.
  Future<void> confirmarEntrega(String pedidoId) =>
      _cliente.rpc('confirmar_entrega', params: {'p_order_id': pedidoId});

  /// Solo funciona si el pedido esta aceptado o entregado; en otro caso el
  /// servidor lanza CONTACTO_NO_DISPONIBLE.
  Future<ContactoPedido> obtenerContacto(String pedidoId) async {
    final filas = await _cliente.rpc(
      'get_contacto_pedido',
      params: {'p_order_id': pedidoId},
    );
    final fila = (filas as List).first as Map<String, dynamic>;

    return ContactoPedido(
      nombre: (fila['contraparte_nombre'] as String?) ?? '',
      whatsapp: (fila['contraparte_whatsapp'] as String?) ?? '',
      enlace: (fila['enlace_whatsapp'] as String?) ?? '',
    );
  }

  /// Emite el pedido cada vez que cambia en el servidor. Lo usa la pantalla
  /// de espera para reaccionar en cuanto el vendedor acepta o rechaza.
  ///
  /// Combina Realtime (websocket) con un sondeo periodico de respaldo:
  /// si el websocket falla o se corta (redes de campus, proxies, la pestana
  /// suspendida), la pantalla sigue actualizandose igual en vez de quedarse
  /// esperando un evento que nunca llega. Los errores del canal se tragan
  /// a proposito: el sondeo es la garantia de progreso.
  Stream<Pedido?> escuchar(String pedidoId) {
    late final StreamController<Pedido?> controlador;
    StreamSubscription<dynamic>? tiempoReal;
    Timer? sondeo;

    Future<void> emitir() async {
      if (controlador.isClosed) return;
      try {
        controlador.add(await obtener(pedidoId));
      } catch (_) {
        // Fallo puntual de red: el siguiente sondeo lo reintenta.
      }
    }

    controlador = StreamController<Pedido?>(
      onListen: () {
        emitir();
        // Respaldo corto: es la pantalla donde el usuario esta mirando
        // fijamente, esperando que el vendedor responda.
        sondeo = Timer.periodic(const Duration(seconds: 2), (_) => emitir());
        try {
          tiempoReal = _cliente
              .from('orders')
              .stream(primaryKey: ['id'])
              .eq('id', pedidoId)
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
