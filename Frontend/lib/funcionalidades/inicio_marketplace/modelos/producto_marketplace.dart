import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import 'local_universitario.dart';
import 'variante_producto.dart';

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
    this.vistas = 0,
    this.categoriaId,
    this.variantes = const [],
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
      vistas: (fila['view_count'] as num?)?.toInt() ?? 0,
      categoriaId: fila['category_id'] as String?,
      imagenes:
          ((fila['product_images'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()
              .map((i) => i['storage_path'] as String)
              .toList()
            ..sort(),
      variantes: _variantesDesde(fila),
    );
  }

  /// Las de `product_variants`, en el orden en que el vendedor las puso.
  ///
  /// La consulta pide `position` justo para esto: sin ordenar, el desplegable
  /// cambia de orden entre una carga y otra y el sabor de siempre nunca esta
  /// donde uno lo dejo.
  static List<VarianteProducto> _variantesDesde(Map<String, dynamic> fila) {
    // Las retiradas se quedan en la base para que los pedidos viejos sigan
    // nombrandolas, pero nadie debe poder elegir hoy el sabor que se acabo.
    final filas = ((fila['product_variants'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .where((variante) => (variante['is_available'] as bool?) ?? true)
        .toList();
    filas.sort((a, b) {
      final posicion = ((a['position'] as num?) ?? 0).compareTo(
        (b['position'] as num?) ?? 0,
      );
      if (posicion != 0) return posicion;
      return ((a['name'] as String?) ?? '').compareTo(
        (b['name'] as String?) ?? '',
      );
    });
    return filas.map(VarianteProducto.desdeMapa).toList(growable: false);
  }

  ProductoMarketplace copiarCon({int? stock, bool? disponible, int? vistas}) =>
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
        vistas: vistas ?? this.vistas,
        categoriaId: categoriaId,
        variantes: variantes,
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
  final int vistas;

  /// Categoria propia de la publicacion. Null en lo publicado antes de que
  /// existiera: entonces manda la del local, que es lo que se usaba.
  final String? categoriaId;

  /// Sabores, tamanos o versiones de esta misma publicacion. Vacio es lo
  /// normal: la mayoria de lo que se publica no tiene variantes.
  final List<VarianteProducto> variantes;

  /// Si hay que elegir algo antes de poder pedirlo.
  bool get exigeVariante => variantes.isNotEmpty;

  /// Todos los precios posibles de esta publicacion: el del producto para las
  /// variantes que no lo cambian, y el propio de las que si.
  Iterable<double> get _preciosPosibles => variantes.isEmpty
      ? [precio]
      : variantes.map((variante) => variante.precioSobre(precio));

  /// El mas barato. Es lo que anuncia la tarjeta cuando los sabores no valen
  /// todos lo mismo: poner el mas caro espanta y poner el del producto seria
  /// mentir si ninguna variante lo cobra.
  double get precioMinimo =>
      _preciosPosibles.reduce((a, b) => a < b ? a : b);

  /// Si hay mas de un precio, la tarjeta tiene que decir "desde".
  bool get preciosVarian => _preciosPosibles.toSet().length > 1;

  /// La que decide en que filtro cae.
  String get categoriaEfectiva => categoriaId ?? local?.categoriaId ?? '';

  String? get imagenUrl => ServicioImagenes.urlPublica(imagePath);

  /// Todas las fotos para el carrusel: la principal encabeza la galeria.
  List<String> get galeriaUrls => [
    if (imagePath != null) ServicioImagenes.urlPublica(imagePath)!,
    for (final ruta in imagenes) ServicioImagenes.urlPublica(ruta)!,
  ];

  /// Los servicios no llevan inventario: siempre se pueden solicitar.
  bool get hayExistencias => esServicio || stock > 0;
}
