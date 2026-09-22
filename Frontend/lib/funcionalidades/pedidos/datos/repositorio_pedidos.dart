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

  /// Solicitud que todavía espera respuesta del vendedor.
  ///
  /// El carrito la consulta al abrirse para recuperar la pantalla de espera
  /// aunque el comprador haya seguido explorando la aplicación.
  Future<Pedido?> solicitudPendienteComprador() async {
    final filas = await _cliente
        .from('pedidos_detallados')
        .select()
        .eq('buyer_id', _usuarioId)
        .eq('status', 'solicitado')
        .order('created_at', ascending: false)
        .limit(1);

    if (filas.isEmpty) return null;
    return Pedido.desdeMapa(filas.first);
  }

  /// Ventas del usuario (es el vendedor).
  Future<List<Pedido>> misVentas() => _consultar('seller_id');

  Future<List<Pedido>> _consultar(String columna) async {
    final filas = await _cliente
        .from('pedidos_detallados')
        .select()
        .eq(columna, _usuarioId)
        .order('created_at', ascending: false);

    if (filas.isEmpty) return const [];

    final pedidosIds = filas.map((fila) => fila['id'] as String).toList();
    final localesIds = filas
        .map((fila) => fila['store_id'] as String)
        .toSet()
        .toList();

    // La vista histórica conserva nombres y precios, pero no incluía fotos.
    // Se resuelven en dos consultas agrupadas para evitar una petición por
    // cada tarjeta de la lista.
    final (items, locales, eventosCancelacion) = await (
      _cliente
          .from('order_items')
          .select(
            'order_id, product_id, product_name, product_emoji, '
            'variant_name, unit_price, quantity, products(image_path)',
          )
          .inFilter('order_id', pedidosIds),
      _cliente
          .from('stores')
          .select('id, logo_path')
          .inFilter('id', localesIds),
      _cliente
          .from('order_events')
          .select('order_id, actor_id, created_at')
          .inFilter('order_id', pedidosIds)
          .eq('to_status', 'cancelado')
          .order('created_at', ascending: false),
    ).wait;

    final itemsPorPedido = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final pedidoId = item['order_id'] as String;
      itemsPorPedido.putIfAbsent(pedidoId, () => []).add(item);
    }
    final logoPorLocal = <String, String?>{
      for (final local in locales)
        local['id'] as String: local['logo_path'] as String?,
    };
    final canceladorPorPedido = <String, String?>{};
    for (final evento in eventosCancelacion) {
      canceladorPorPedido.putIfAbsent(
        evento['order_id'] as String,
        () => evento['actor_id'] as String?,
      );
    }

    return filas.map((fila) {
      final enriquecida = Map<String, dynamic>.from(fila);
      final pedidoId = fila['id'] as String;
      final localId = fila['store_id'] as String;
      final itemsEnriquecidos = itemsPorPedido[pedidoId];
      if (itemsEnriquecidos != null) enriquecida['items'] = itemsEnriquecidos;
      enriquecida['store_logo_path'] = logoPorLocal[localId];
      enriquecida['cancelled_by'] = canceladorPorPedido[pedidoId];
      return Pedido.desdeMapa(enriquecida);
    }).toList();
  }

  Future<Pedido?> obtener(String pedidoId) async {
    final fila = await _cliente
        .from('pedidos_detallados')
        .select()
        .eq('id', pedidoId)
        .maybeSingle();

    if (fila == null) return null;

    final enriquecida = Map<String, dynamic>.from(fila);
    if (fila['status'] == 'cancelado') {
      final eventos = await _cliente
          .from('order_events')
          .select('actor_id')
          .eq('order_id', pedidoId)
          .eq('to_status', 'cancelado')
          .order('created_at', ascending: false)
          .limit(1);
      if (eventos.isNotEmpty) {
        enriquecida['cancelled_by'] = eventos.first['actor_id'] as String?;
      }
    }

    return Pedido.desdeMapa(enriquecida);
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
