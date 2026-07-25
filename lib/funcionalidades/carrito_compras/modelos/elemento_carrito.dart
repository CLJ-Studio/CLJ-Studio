import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Relaciona un producto con su cantidad dentro del carrito.
class ElementoCarrito {
  const ElementoCarrito({required this.producto, required this.cantidad});

  final ProductoMarketplace producto;
  final int cantidad;

  ElementoCarrito copiarCon({int? cantidad}) =>
      ElementoCarrito(producto: producto, cantidad: cantidad ?? this.cantidad);
}
