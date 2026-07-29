import 'package:flutter/foundation.dart';

import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../modelos/elemento_carrito.dart';

/// Carrito de compras compartido por toda la aplicacion.
///
/// Vive solo en memoria a proposito: no existe tabla de carrito porque nada
/// se reserva hasta que el comprador confirma y se llama a `crear_pedido`.
/// El backend recalcula precios y totales en ese momento, asi que lo de aqui
/// es unicamente una seleccion provisional.
class ControladorCarritoCompras extends ChangeNotifier {
  ControladorCarritoCompras._();

  static final ControladorCarritoCompras instancia =
      ControladorCarritoCompras._();

  final List<ElementoCarrito> _elementos = [];

  /// Local al que pertenece el carrito. Un pedido = un local, porque cada
  /// vendedor solo debe ver los items que le corresponden y la entrega se
  /// coordina con una sola persona.
  LocalUniversitario? local;

  List<ElementoCarrito> get elementos => List.unmodifiable(_elementos);
  bool get estaVacio => _elementos.isEmpty;
  int get unidades =>
      _elementos.fold(0, (total, item) => total + item.cantidad);

  double get subtotal => _elementos.fold(
    0,
    (total, item) => total + item.producto.precio * item.cantidad,
  );

  /// El envio lo define cada local; antes estaba fijo en 3 Bs.
  double get costoEntrega =>
      _elementos.isEmpty ? 0 : (local?.costoEntrega ?? 0);
  double get total => _elementos.isEmpty ? 0 : subtotal + costoEntrega;

  /// Indica si agregar este producto obligaria a vaciar el carrito.
  bool esDeOtroLocal(ProductoMarketplace producto) =>
      _elementos.isNotEmpty && producto.localId != local?.id;

  /// Agrega o incrementa. Si el producto es de otro local, reemplaza el
  /// carrito completo: quien llama debe confirmarlo antes con el usuario.
  void agregar(ProductoMarketplace producto, LocalUniversitario localProducto) {
    if (esDeOtroLocal(producto)) _elementos.clear();
    local = localProducto;

    final indice = _elementos.indexWhere((e) => e.producto.id == producto.id);
    if (indice >= 0) {
      _elementos[indice] = _elementos[indice].copiarCon(
        cantidad: _elementos[indice].cantidad + 1,
      );
    } else {
      _elementos.add(ElementoCarrito(producto: producto, cantidad: 1));
    }
    notifyListeners();
  }

  void aumentar(int indice) {
    _elementos[indice] = _elementos[indice].copiarCon(
      cantidad: _elementos[indice].cantidad + 1,
    );
    notifyListeners();
  }

  void disminuir(int indice) {
    if (_elementos[indice].cantidad > 1) {
      _elementos[indice] = _elementos[indice].copiarCon(
        cantidad: _elementos[indice].cantidad - 1,
      );
      notifyListeners();
    }
  }

  void eliminar(int indice) {
    _elementos.removeAt(indice);
    if (_elementos.isEmpty) local = null;
    notifyListeners();
  }

  /// Tras crear el pedido o al cerrar sesion.
  void vaciar() {
    _elementos.clear();
    local = null;
    notifyListeners();
  }

  /// Payload de `crear_pedido`: solo ids y cantidades. Los precios los pone
  /// el servidor, nunca el cliente.
  List<Map<String, dynamic>> aItemsDePedido() => [
    for (final elemento in _elementos)
      {'product_id': elemento.producto.id, 'quantity': elemento.cantidad},
  ];
}
