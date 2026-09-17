import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';

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
    EstadoPedido.solicitado => const Color(0xFFAE7960),
    EstadoPedido.aceptado => const Color(0xFF474646),
    EstadoPedido.porConfirmar => const Color(0xFFAE7960),
    EstadoPedido.entregado => const Color(0xFF848381),
    _ => const Color(0xFF969A82),
  };

  Color get fondo => switch (this) {
    EstadoPedido.solicitado => const Color(0xFFE6E1D5),
    EstadoPedido.aceptado => const Color(0xFFE6E1D5),
    EstadoPedido.porConfirmar => const Color(0xFFE6E1D5),
    EstadoPedido.entregado => const Color(0xFFE6E1D5),
    _ => const Color(0xFFE6E1D5),
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

  /// Si el pedido debe sumar en "Total comprado"/"Total vendido". Incluye lo
  /// que está en el aire pero no se cayó: uno a medio confirmar ya se
  /// entregó, solo falta que alguien lo diga. Un vencido, rechazado o
  /// cancelado nunca se concretó y no debe inflar el total de nadie.
  bool get cuentaParaTotal =>
      this == EstadoPedido.aceptado ||
      this == EstadoPedido.porConfirmar ||
      this == EstadoPedido.entregado;
}

/// Linea de un pedido, con los datos congelados al momento de crearlo.
class ItemPedido {
  const ItemPedido({
    required this.nombre,
    required this.emoji,
    required this.precioUnitario,
    required this.cantidad,
    this.productoId,
    this.imagenPath,
  });

  factory ItemPedido.desdeMapa(Map<String, dynamic> fila) {
    final producto = fila['products'] as Map<String, dynamic>?;
    return ItemPedido(
      nombre: fila['product_name'] as String,
      emoji: (fila['product_emoji'] as String?) ?? '🛍️',
      precioUnitario: (fila['unit_price'] as num?)?.toDouble() ?? 0,
      cantidad: (fila['quantity'] as num?)?.toInt() ?? 0,
      productoId: fila['product_id'] as String?,
      imagenPath:
          (fila['image_path'] as String?) ?? producto?['image_path'] as String?,
    );
  }

  final String nombre;
  final String emoji;
  final double precioUnitario;
  final int cantidad;
  final String? productoId;
  final String? imagenPath;

  double get subtotal => precioUnitario * cantidad;
  String? get imagenUrl => ServicioImagenes.urlPublica(imagenPath);
}

/// Pedido tal como lo entrega la vista `pedidos_detallados`.
class Pedido {
  const Pedido({
    required this.id,
    required this.estado,
    required this.compradorId,
    required this.vendedorId,
    required this.localId,
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
    this.resueltoEn,
    this.localLogoPath,
    this.puntoEncuentro,
    this.notaComprador,
    this.marcadoPorId,
    this.canceladoPorId,
  });

  factory Pedido.desdeMapa(Map<String, dynamic> fila) => Pedido(
    id: fila['id'] as String,
    estado: EstadoPedido.desdeTexto(fila['status'] as String),
    compradorId: fila['buyer_id'] as String,
    vendedorId: fila['seller_id'] as String,
    localId: fila['store_id'] as String,
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
    resueltoEn: fila['resolved_at'] == null
        ? null
        : DateTime.parse(fila['resolved_at'] as String),
    localLogoPath: fila['store_logo_path'] as String?,
    puntoEncuentro:
        (fila['meeting_point_name'] as String?) ??
        (fila['meeting_point_note'] as String?),
    notaComprador: fila['buyer_note'] as String?,
    marcadoPorId: fila['delivered_marked_by'] as String?,
    canceladoPorId: fila['cancelled_by'] as String?,
  );

  final String id;
  final EstadoPedido estado;
  final String compradorId;
  final String vendedorId;
  final String localId;
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
  final DateTime? resueltoEn;
  final String? localLogoPath;
  final String? puntoEncuentro;
  final String? notaComprador;

  /// Quién dio la entrega por hecha, mientras falta la confirmación del otro.
  final String? marcadoPorId;

  /// Parte que canceló el pedido, obtenida del último evento de cancelación.
  ///
  /// `orders.status` solo dice que terminó cancelado; sin el actor la interfaz
  /// no puede diferenciar una cancelación del vendedor de una del comprador.
  final String? canceladoPorId;

  String? get localLogoUrl => ServicioImagenes.urlPublica(localLogoPath);
  String? get imagenPrincipalUrl {
    for (final item in items) {
      if (item.imagenUrl case final url?) return url;
    }
    return null;
  }

  int get unidades => items.fold(0, (total, item) => total + item.cantidad);

  String etiquetaPara({required bool soyVendedor}) {
    if (estado != EstadoPedido.cancelado || canceladoPorId == null) {
      return estado.etiqueta;
    }

    final loCanceloElVendedor = canceladoPorId == vendedorId;
    if (soyVendedor) {
      return loCanceloElVendedor
          ? 'Cancelado por ti'
          : 'Cancelado por el comprador';
    }
    return loCanceloElVendedor
        ? 'Cancelado por el vendedor'
        : 'Cancelado por ti';
  }

  bool fueCanceladoPor(String? usuarioId) =>
      estado == EstadoPedido.cancelado &&
      usuarioId != null &&
      canceladoPorId == usuarioId;

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
