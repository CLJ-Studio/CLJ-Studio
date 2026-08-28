import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';

/// Una conversación tal como se ve en la bandeja, sin abrirla.
///
/// Existe una por pedido vivo, tenga mensajes o no: la conversación nace
/// cuando el pedido se acepta. Si solo aparecieran las que ya tienen
/// mensajes, el primero en escribir tendría que volver al pedido a buscar la
/// puerta, que es justo lo que la bandeja viene a evitar.
class ResumenChat {
  const ResumenChat({
    required this.pedidoId,
    required this.contraparteId,
    required this.contraparte,
    required this.local,
    required this.emoji,
    required this.estado,
    required this.sinLeer,
    required this.actualizadoEn,
    this.contraparteFotoPath,
    this.ultimoMensaje,
    this.ultimoEn,
    this.ultimoMio = false,
  });

  factory ResumenChat.desdeMapa(Map<String, dynamic> fila) => ResumenChat(
    pedidoId: fila['order_id'] as String,
    contraparteId: fila['contraparte_id'] as String,
    contraparte: (fila['contraparte'] as String?) ?? '',
    contraparteFotoPath: fila['contraparte_foto'] as String?,
    local: (fila['local'] as String?) ?? '',
    emoji: (fila['emoji'] as String?) ?? '🛍️',
    estado: (fila['estado'] as String?) ?? '',
    ultimoMensaje: fila['ultimo_mensaje'] as String?,
    ultimoEn: fila['ultimo_en'] == null
        ? null
        : DateTime.parse(fila['ultimo_en'] as String),
    ultimoMio: (fila['ultimo_mio'] as bool?) ?? false,
    sinLeer: (fila['sin_leer'] as num?)?.toInt() ?? 0,
    actualizadoEn: DateTime.parse(fila['actualizado_en'] as String),
  );

  final String pedidoId;
  final String contraparteId;
  final String contraparte;
  final String? contraparteFotoPath;
  final String local;
  final String emoji;
  final String estado;
  final String? ultimoMensaje;
  final DateTime? ultimoEn;
  final bool ultimoMio;
  final int sinLeer;
  final DateTime actualizadoEn;

  String? get fotoUrl => ServicioImagenes.urlPublica(contraparteFotoPath);

  bool get tieneMensajes => ultimoMensaje != null;

  /// Lo que se lee bajo el nombre.
  ///
  /// Cuando todavía no habló nadie, decirlo es más útil que dejar el hueco:
  /// avisa de que la conversación está abierta y esperando.
  String get vistaPrevia {
    final texto = ultimoMensaje;
    if (texto == null) return 'Ponte de acuerdo para la entrega';
    return ultimoMio ? 'Tú: $texto' : texto;
  }

  /// Hora si es de hoy, día si es de antes. Un chat de un pedido rara vez
  /// pasa de un par de días, así que no hace falta más.
  String get cuando {
    final momento = (ultimoEn ?? actualizadoEn).toLocal();
    final ahora = DateTime.now();
    final esHoy =
        momento.year == ahora.year &&
        momento.month == ahora.month &&
        momento.day == ahora.day;

    if (esHoy) {
      final hh = momento.hour.toString().padLeft(2, '0');
      final mm = momento.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final dias = ahora.difference(momento).inDays;
    if (dias <= 1) return 'Ayer';
    return '${momento.day}/${momento.month}';
  }
}
