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
