/// Publicación creada por el estudiante y visible en su perfil.
class PublicacionUsuario {
  const PublicacionUsuario({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.precio,
  });

  final String id;
  final String tipo;
  final String nombre;
  final String descripcion;
  final String categoria;
  final double precio;
}
