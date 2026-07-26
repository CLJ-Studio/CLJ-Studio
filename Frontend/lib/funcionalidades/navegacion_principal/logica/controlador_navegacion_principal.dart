import 'package:flutter/foundation.dart';

/// Cambia la sección activa sin reconstruir las demás pantallas.
class ControladorNavegacionPrincipal extends ChangeNotifier {
  int indice = 0;

  void seleccionarIndice(int nuevoIndice) {
    indice = nuevoIndice;
    notifyListeners();
  }
}
