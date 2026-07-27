import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import 'local_universitario.dart';

/// Producto ofrecido por un local universitario.
class ProductoMarketplace {
  const ProductoMarketplace({
    required this.id,
    required this.localId,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.emoji,
    this.stock = 0,
    this.esServicio = false,
    this.local,
    this.imagePath,
  });

  /// Mapea una fila de `products`. Si la consulta unio `stores`, el local
  /// queda incluido: lo necesitan las listas que mezclan varios vendedores
  /// (favoritos), donde no hay un local unico que pasar por fuera.
  factory ProductoMarketplace.desdeMapa(Map<String, dynamic> fila) {
    final tienda = fila['stores'] as Map<String, dynamic>?;
    return ProductoMarketplace(
      id: fila['id'] as String,
      localId: fila['store_id'] as String,
      nombre: fila['name'] as String,
      descripcion: (fila['description'] as String?) ?? '',
      precio: (fila['price'] as num?)?.toDouble() ?? 0,
      emoji: (fila['emoji'] as String?) ?? '🛍️',
      stock: (fila['stock'] as num?)?.toInt() ?? 0,
      esServicio: (fila['kind'] as String?) == 'servicio',
      local: tienda == null ? null : LocalUniversitario.desdeMapa(tienda),
      imagePath: fila['image_path'] as String?,
    );
  }

  ProductoMarketplace copiarCon({int? stock}) => ProductoMarketplace(
    id: id,
    localId: localId,
    nombre: nombre,
    descripcion: descripcion,
    precio: precio,
    emoji: emoji,
    stock: stock ?? this.stock,
    esServicio: esServicio,
    local: local,
    imagePath: imagePath,
  );

  final String id;
  final String localId;
  final String nombre;
  final String descripcion;
  final double precio;
  final String emoji;
  final int stock;
  final bool esServicio;

  /// Presente solo si la consulta unio `stores`.
  final LocalUniversitario? local;

  /// Foto real subida por el vendedor; si falta, la tarjeta usa el emoji.
  final String? imagePath;

  String? get imagenUrl => ServicioImagenes.urlPublica(imagePath);

  /// Los servicios no llevan inventario: siempre se pueden solicitar.
  bool get hayExistencias => esServicio || stock > 0;
}
