/// Local tipado, independiente de la fuente que entregue sus datos.
class LocalUniversitario {
  const LocalUniversitario({
    required this.id,
    required this.nombre,
    required this.categoriaId,
    required this.categoria,
    required this.descripcion,
    required this.calificacion,
    required this.tiempoEstimado,
    required this.estaAbierto,
    required this.costoEntrega,
    required this.emoji,
    required this.colorHexadecimal,
  });

  /// Mapea una fila de `stores` con su categoria unida.
  factory LocalUniversitario.desdeMapa(Map<String, dynamic> fila) {
    final categoria = fila['categories'] as Map<String, dynamic>?;
    return LocalUniversitario(
      id: fila['id'] as String,
      nombre: fila['name'] as String,
      categoriaId: (fila['category_id'] as String?) ?? '',
      categoria: (categoria?['name'] as String?) ?? '',
      descripcion: (fila['description'] as String?) ?? '',
      calificacion: (fila['rating_average'] as num?)?.toDouble() ?? 0,
      tiempoEstimado: (fila['estimated_time'] as String?) ?? '',
      estaAbierto: (fila['is_open'] as bool?) ?? false,
      costoEntrega: (fila['delivery_cost'] as num?)?.toDouble() ?? 0,
      emoji: (fila['emoji'] as String?) ?? '🍽️',
      // color_hex es bigint en Postgres: 0xFFFFE8D6 desborda un int32.
      colorHexadecimal: (fila['color_hex'] as num?)?.toInt() ?? 0xFFF1F6F0,
    );
  }

  final String id;
  final String nombre;
  final String categoriaId;
  final String categoria;
  final String descripcion;
  final double calificacion;
  final String tiempoEstimado;
  final bool estaAbierto;
  final double costoEntrega;
  final String emoji;
  final int colorHexadecimal;
}
