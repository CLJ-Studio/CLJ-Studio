import '../funcionalidades/carrito_compras/modelos/elemento_carrito.dart';
import 'productos_prueba.dart';

/// Carrito inicial de demostración, separado de cualquier elemento visual.
abstract final class CarritoPrueba {
  static List<ElementoCarrito> crear() => [
    ElementoCarrito(producto: ProductosPrueba.todos[0], cantidad: 2),
    ElementoCarrito(producto: ProductosPrueba.todos[1], cantidad: 1),
  ];
}
