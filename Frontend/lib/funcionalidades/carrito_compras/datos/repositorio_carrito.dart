import '../modelos/elemento_carrito.dart';

/// Contrato que sincronizará el carrito con el backend en otra etapa.
class RepositorioCarrito {
  Future<void> guardar(List<ElementoCarrito> elementos) async {}
}
