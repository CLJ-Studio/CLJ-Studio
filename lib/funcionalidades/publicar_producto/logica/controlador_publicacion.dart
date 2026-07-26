import 'package:flutter/foundation.dart';

/// Mantiene selecciones temporales del formulario sin publicar datos reales.
class ControladorPublicacion extends ChangeNotifier {
  String tipo = 'Producto';
  String categoria = 'Tecnologia';
  void seleccionarTipo(String valor) {
    tipo = valor;
    notifyListeners();
  }

  void seleccionarCategoria(String valor) {
    categoria = valor;
    notifyListeners();
  }
}
