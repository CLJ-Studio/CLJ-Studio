import 'package:flutter/material.dart';

/// Estados posibles de un pedido (enum `estado_pedido` en Postgres).
enum EstadoPedido {
  solicitado,
  aceptado,
  porConfirmar,
  rechazado,
  cancelado,
  vencido,
  entregado;

  static EstadoPedido desdeTexto(String valor) => switch (valor) {
    'aceptado' => EstadoPedido.aceptado,
    'por_confirmar' => EstadoPedido.porConfirmar,
    'rechazado' => EstadoPedido.rechazado,
    'cancelado' => EstadoPedido.cancelado,
    'vencido' => EstadoPedido.vencido,
    'entregado' => EstadoPedido.entregado,
    _ => EstadoPedido.solicitado,
  };

  /// La de `solicitado` decía "Por confirmar", que ahora es justo el nombre
  /// del otro estado. Dos etiquetas iguales para dos momentos distintos del
  /// pedido no las distingue nadie.
  String get etiqueta => switch (this) {
    EstadoPedido.solicitado => 'Pendiente',
    EstadoPedido.aceptado => 'Aceptado',
    EstadoPedido.porConfirmar => 'Falta confirmar',
    EstadoPedido.rechazado => 'Rechazado',
    EstadoPedido.cancelado => 'Cancelado',
    EstadoPedido.vencido => 'Vencido',
    EstadoPedido.entregado => 'Entregado',
  };

  Color get color => switch (this) {
    EstadoPedido.solicitado => const Color(0xFFC98A2B),
    EstadoPedido.aceptado => const Color(0xFF5C8A63),
    EstadoPedido.porConfirmar => const Color(0xFFC98A2B),
    EstadoPedido.entregado => const Color(0xFF4A7C93),
    _ => const Color(0xFF9A9A9A),
  };

  Color get fondo => switch (this) {
    EstadoPedido.solicitado => const Color(0xFFFDF3E2),
    EstadoPedido.aceptado => const Color(0xFFE7F0E7),
    EstadoPedido.porConfirmar => const Color(0xFFFDF3E2),
    EstadoPedido.entregado => const Color(0xFFE6F0F5),
    _ => const Color(0xFFF0F1F0),
  };

  /// El contacto sigue abierto mientras se confirma: entre que uno marca la
  /// entrega y el otro responde es justo cuando se están escribiendo.
  bool get permiteContacto =>
      this == EstadoPedido.aceptado ||
      this == EstadoPedido.porConfirmar ||
      this == EstadoPedido.entregado;

  bool get estaCerrado =>
      this != EstadoPedido.solicitado &&
      this != EstadoPedido.aceptado &&
      this != EstadoPedido.porConfirmar;
}

/// Linea de un pedido, con los datos congelados al momento de crearlo.
class ItemPedido {
  const ItemPedido({
    required this.nombre,
    required this.emoji,
    required this.precioUnitario,
    required this.cantidad,
  });

  factory ItemPedido.desdeMapa(Map<String, dynamic> fila) => ItemPedido(
    nombre: fila['product_name'] as String,
    emoji: (fila['product_emoji'] as String?) ?? '🛍️',
    precioUnitario: (fila['unit_price'] as num?)?.toDouble() ?? 0,
    cantidad: (fila['quantity'] as num?)?.toInt() ?? 0,
  );

  final String nombre;
  final String emoji;
  final double precioUnitario;
  final int cantidad;

  double get subtotal => precioUnitario * cantidad;
}

/// Pedido tal como lo entrega la vista `pedidos_detallados`.
class Pedido {
  const Pedido({
    required this.id,
    required this.estado,
    required this.compradorId,
    required this.vendedorId,
    required this.nombreLocal,
    required this.emojiLocal,
    required this.nombreComprador,
    required this.nombreVendedor,
    required this.subtotal,
    required this.costoEntrega,
    required this.total,
    required this.items,
    required this.creadoEn,
    required this.venceEn,
    this.puntoEncuentro,
    this.notaComprador,
    this.marcadoPorId,
  });

  factory Pedido.desdeMapa(Map<String, dynamic> fila) => Pedido(
    id: fila['id'] as String,
    estado: EstadoPedido.desdeTexto(fila['status'] as String),
    compradorId: fila['buyer_id'] as String,
    vendedorId: fila['seller_id'] as String,
    nombreLocal: (fila['store_name'] as String?) ?? '',
    emojiLocal: (fila['store_emoji'] as String?) ?? '🍽️',
    nombreComprador: (fila['buyer_name'] as String?) ?? '',
    nombreVendedor: (fila['seller_name'] as String?) ?? '',
    subtotal: (fila['subtotal'] as num?)?.toDouble() ?? 0,
    costoEntrega: (fila['delivery_cost'] as num?)?.toDouble() ?? 0,
    total: (fila['total'] as num?)?.toDouble() ?? 0,
    items: ((fila['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ItemPedido.desdeMapa)
        .toList(),
    creadoEn: DateTime.parse(fila['created_at'] as String),
    venceEn: DateTime.parse(fila['expires_at'] as String),
    puntoEncuentro:
        (fila['meeting_point_name'] as String?) ??
        (fila['meeting_point_note'] as String?),
    notaComprador: fila['buyer_note'] as String?,
    marcadoPorId: fila['delivered_marked_by'] as String?,
  );

  final String id;
  final EstadoPedido estado;
  final String compradorId;
  final String vendedorId;
  final String nombreLocal;
  final String emojiLocal;
  final String nombreComprador;
  final String nombreVendedor;
  final double subtotal;
  final double costoEntrega;
  final double total;
  final List<ItemPedido> items;
  final DateTime creadoEn;
  final DateTime venceEn;
  final String? puntoEncuentro;
  final String? notaComprador;

  /// Quién dio la entrega por hecha, mientras falta la confirmación del otro.
  final String? marcadoPorId;

  int get unidades => items.fold(0, (total, item) => total + item.cantidad);

  /// Si a quien mira le toca confirmar.
  ///
  /// Confirmar lo que uno mismo marcó no confirmaría nada, así que el botón
  /// solo aparece del lado que todavía no habló.
  bool meTocaConfirmar(String? miId) =>
      estado == EstadoPedido.porConfirmar &&
      miId != null &&
      marcadoPorId != null &&
      marcadoPorId != miId;

  /// Si ya marqué yo y espero al otro.
  bool esperandoAlOtro(String? miId) =>
      estado == EstadoPedido.porConfirmar &&
      miId != null &&
      marcadoPorId == miId;
}
