import 'package:flutter/foundation.dart';

import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Mantiene los productos marcados con corazón durante la sesión.
class ControladorFavoritos extends ChangeNotifier {
  ControladorFavoritos._();

  static final ControladorFavoritos instancia = ControladorFavoritos._();

  final Map<String, ProductoMarketplace> _productos = {};

  List<ProductoMarketplace> get productos =>
      List.unmodifiable(_productos.values);

  int get cantidad => _productos.length;

  bool contiene(ProductoMarketplace producto) =>
      _productos.containsKey(producto.id);

  void alternar(ProductoMarketplace producto) {
    if (contiene(producto)) {
      _productos.remove(producto.id);
    } else {
      _productos[producto.id] = producto;
    }
    notifyListeners();
  }
}
