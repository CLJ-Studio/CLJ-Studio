/// Alguien que dice que ya se graduo y espera que un admin lo verifique,
/// tal como lo devuelve `solicitudes_egresado()`.
class SolicitudEgresado {
  const SolicitudEgresado({
    required this.usuarioId,
    required this.nombre,
    required this.correo,
    this.registro,
    this.anioIngreso,
    this.carrera,
    this.pedidoEn,
  });

  factory SolicitudEgresado.desdeMapa(Map<String, dynamic> fila) =>
      SolicitudEgresado(
        usuarioId: fila['usuario_id'] as String,
        nombre: (fila['nombre'] as String?)?.trim() ?? '',
        correo: (fila['correo'] as String?) ?? '',
        registro: fila['registro'] as String?,
        anioIngreso: (fila['anio_ingreso'] as num?)?.toInt(),
        carrera: fila['carrera'] as String?,
        pedidoEn: DateTime.tryParse(
          (fila['pedido_en'] as String?) ?? '',
        )?.toLocal(),
      );

  final String usuarioId;
  final String nombre;
  final String correo;

  /// "a2004210000": de ahi sale el año de ingreso, que no se puede inventar.
  final String? registro;
  final int? anioIngreso;
  final String? carrera;
  final DateTime? pedidoEn;
}
