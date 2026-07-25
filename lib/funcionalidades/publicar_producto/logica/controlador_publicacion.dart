import 'package:flutter/foundation.dart';

/// Mantiene selecciones temporales del formulario sin publicar datos reales.
class ControladorPublicacion extends ChangeNotifier {
  String tipo = 'Producto';
  String categoria = 'Comida';
  void seleccionarTipo(String valor) {
    tipo = valor;
    notifyListeners();
  }

  void seleccionarCategoria(String valor) {
    categoria = valor;
    notifyListeners();
  }
}
