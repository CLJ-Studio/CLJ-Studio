import 'package:flutter/foundation.dart';

/// Selecciones del formulario de publicación.
class ControladorPublicacion extends ChangeNotifier {
  /// 'Producto' lleva inventario; 'Servicio' no (se puede pedir siempre).
  String tipo = 'Producto';
  String emoji = '🛍️';

  bool get esServicio => tipo == 'Servicio';

  void seleccionarTipo(String valor) {
    tipo = valor;
    notifyListeners();
  }

  void seleccionarEmoji(String valor) {
    emoji = valor;
    notifyListeners();
  }
}
