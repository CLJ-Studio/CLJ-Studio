/// Producto ofrecido por un local universitario ficticio.
class ProductoMarketplace {
  const ProductoMarketplace({
    required this.id,
    required this.localId,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.emoji,
  });

  final String id;
  final String localId;
  final String nombre;
  final String descripcion;
  final double precio;
  final String emoji;
}
