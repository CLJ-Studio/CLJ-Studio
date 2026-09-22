import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../inicio_marketplace/modelos/variante_producto.dart';

/// Relaciona un producto con su cantidad dentro del carrito.
class ElementoCarrito {
  const ElementoCarrito({
    required this.producto,
    required this.cantidad,
    this.variante,
  });

  final ProductoMarketplace producto;
  final int cantidad;

  /// El sabor elegido, si la publicacion ofrecia varios.
  ///
  /// Dos sabores del mismo producto son dos lineas distintas del carrito:
  /// sumarlos en una sola dejaria al vendedor sin saber cuantas de cada una
  /// tiene que preparar, que es justo lo que las variantes vienen a resolver.
  final VarianteProducto? variante;

  /// Lo que hace unica a una linea. El producto no basta.
  String get clave => '${producto.id}|${variante?.id ?? ''}';

  ElementoCarrito copiarCon({int? cantidad}) => ElementoCarrito(
    producto: producto,
    cantidad: cantidad ?? this.cantidad,
    variante: variante,
  );
}
