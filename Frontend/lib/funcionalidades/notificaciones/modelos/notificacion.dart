import 'package:flutter/material.dart';

/// Notificacion in-app tal como vive en la tabla `notifications`.
class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.creadaEn,
    this.pedidoId,
    this.localId,
    this.productoId,
    this.leidaEn,
  });

  factory Notificacion.desdeMapa(Map<String, dynamic> fila) => Notificacion(
    id: fila['id'] as String,
    tipo: (fila['type'] as String?) ?? '',
    titulo: (fila['title'] as String?) ?? '',
    cuerpo: (fila['body'] as String?) ?? '',
    creadaEn: DateTime.parse(fila['created_at'] as String),
    pedidoId: fila['order_id'] as String?,
    localId: fila['store_id'] as String?,
    productoId: fila['product_id'] as String?,
    leidaEn: fila['read_at'] == null
        ? null
        : DateTime.parse(fila['read_at'] as String),
  );

  final String id;
  final String tipo;
  final String titulo;
  final String cuerpo;
  final DateTime creadaEn;

  /// Los tres destinos posibles. Solo uno viene informado, segun el aviso:
  /// tocarlo tiene que llevar a lo que anuncia y no a la nada.
  final String? pedidoId;
  final String? localId;
  final String? productoId;

  final DateTime? leidaEn;

  /// Si hay algo que abrir al tocarla.
  bool get llevaAAlgunSitio =>
      pedidoId != null || localId != null || productoId != null;

  bool get leida => leidaEn != null;

  IconData get icono => switch (tipo) {
    'pedido_recibido' => Icons.shopping_bag_outlined,
    'pedido_aceptado' => Icons.check_circle_outline_rounded,
    'pedido_rechazado' => Icons.cancel_outlined,
    'pedido_cancelado' => Icons.remove_shopping_cart_outlined,
    'pedido_vencido' => Icons.schedule_rounded,
    'pedido_entregado' => Icons.done_all_rounded,
    'entrega_por_confirmar' => Icons.pending_actions_rounded,
    'nuevo_local' => Icons.storefront_rounded,
    'ubicacion_pendiente' => Icons.location_on_outlined,
    _ => Icons.notifications_none_rounded,
  };
}
