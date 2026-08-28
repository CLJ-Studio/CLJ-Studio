import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';

/// Un mensaje del hilo de un pedido.
///
/// El chat no vive en las personas sino en el pedido: no hay bandeja de
/// entrada ni conversaciones sueltas. Cada hilo dura lo que dura su venta.
class MensajePedido {
  const MensajePedido({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.mio,
    required this.cuerpo,
    required this.creadoEn,
    this.autorAvatarPath,
    this.leidoEn,
  });

  /// Mapea una fila de `leer_chat()`.
  ///
  /// `mio` lo decide el servidor y no el cliente: comparar contra la sesión
  /// aquí funcionaría igual, pero dejaría dos sitios donde equivocarse.
  factory MensajePedido.desdeMapa(Map<String, dynamic> fila) => MensajePedido(
    id: fila['id'] as String,
    autorId: fila['autor_id'] as String,
    autorNombre: (fila['autor_nombre'] as String?) ?? '',
    autorAvatarPath: fila['autor_avatar'] as String?,
    mio: (fila['mio'] as bool?) ?? false,
    cuerpo: (fila['cuerpo'] as String?) ?? '',
    creadoEn: DateTime.parse(fila['creado_en'] as String),
    leidoEn: fila['leido_en'] == null
        ? null
        : DateTime.parse(fila['leido_en'] as String),
  );

  final String id;
  final String autorId;
  final String autorNombre;
  final String? autorAvatarPath;
  final bool mio;
  final String cuerpo;
  final DateTime creadoEn;
  final DateTime? leidoEn;

  String? get avatarUrl => ServicioImagenes.urlPublica(autorAvatarPath);

  bool get leido => leidoEn != null;

  /// Solo la hora: el hilo dura lo que dura un pedido, así que la fecha
  /// completa sería ruido en cada burbuja.
  String get hora {
    final local = creadoEn.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Si dos mensajes seguidos son de la misma persona y del mismo minuto, el
  /// segundo no repite el nombre ni la hora.
  bool continuaA(MensajePedido? anterior) =>
      anterior != null &&
      anterior.autorId == autorId &&
      creadoEn.difference(anterior.creadoEn).inMinutes < 2;
}
