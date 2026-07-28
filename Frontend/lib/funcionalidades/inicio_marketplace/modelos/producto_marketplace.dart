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
    this.disponible = true,
    this.imagenes = const [],
  });

  /// Mapea una fila de `products`. Si la consulta unio `stores`, el local
  /// queda incluido: lo necesitan las listas que mezclan varios vendedores
  /// (favoritos), donde no hay un local unico que pasar por fuera.
  /// `local` permite inyectar el vendedor resuelto por fuera: el nombre de
  /// quien publica vive en la vista `locales_publicos`, porque la RLS de
  /// `profiles` impide unirlo desde `stores`.
  factory ProductoMarketplace.desdeMapa(
    Map<String, dynamic> fila, {
    LocalUniversitario? local,
  }) {
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
      local:
          local ??
          (tienda == null ? null : LocalUniversitario.desdeMapa(tienda)),
      imagePath: fila['image_path'] as String?,
      disponible: (fila['is_available'] as bool?) ?? true,
      imagenes:
          ((fila['product_images'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()
              .map((i) => i['storage_path'] as String)
              .toList()
            ..sort(),
    );
  }

  ProductoMarketplace copiarCon({int? stock, bool? disponible}) =>
      ProductoMarketplace(
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
        disponible: disponible ?? this.disponible,
        imagenes: imagenes,
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

  /// Foto principal; si falta, la tarjeta usa el emoji.
  final String? imagePath;

  /// Visible en el catalogo. El vendedor puede ocultarla sin borrarla.
  final bool disponible;

  /// Galeria adicional (hasta 12), en orden.
  final List<String> imagenes;

  String? get imagenUrl => ServicioImagenes.urlPublica(imagePath);

  /// Todas las fotos para el carrusel: la principal encabeza la galeria.
  List<String> get galeriaUrls => [
    if (imagePath != null) ServicioImagenes.urlPublica(imagePath)!,
    for (final ruta in imagenes) ServicioImagenes.urlPublica(ruta)!,
  ];

  /// Los servicios no llevan inventario: siempre se pueden solicitar.
  bool get hayExistencias => esServicio || stock > 0;
}
