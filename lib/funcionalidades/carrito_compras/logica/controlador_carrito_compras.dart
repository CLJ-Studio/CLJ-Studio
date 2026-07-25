import 'package:flutter/foundation.dart';
import '../../../datos_prueba/carrito_prueba.dart';
import '../modelos/elemento_carrito.dart';

/// Administra cantidades y totales sin depender de una API.
class ControladorCarritoCompras extends ChangeNotifier {
  List<ElementoCarrito> elementos = CarritoPrueba.crear();
  static const double costoEntrega = 3;

  double get subtotal => elementos.fold(
    0,
    (total, item) => total + item.producto.precio * item.cantidad,
  );
  double get total => elementos.isEmpty ? 0 : subtotal + costoEntrega;

  void aumentar(int indice) {
    elementos[indice] = elementos[indice].copiarCon(
      cantidad: elementos[indice].cantidad + 1,
    );
    notifyListeners();
  }

  void disminuir(int indice) {
    if (elementos[indice].cantidad > 1) {
      elementos[indice] = elementos[indice].copiarCon(
        cantidad: elementos[indice].cantidad - 1,
      );
      notifyListeners();
    }
  }

  void eliminar(int indice) {
    elementos.removeAt(indice);
    notifyListeners();
  }
}
