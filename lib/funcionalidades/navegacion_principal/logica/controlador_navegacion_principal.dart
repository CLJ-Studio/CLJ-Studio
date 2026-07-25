import 'package:flutter/foundation.dart';
import 'estado_navegacion_principal.dart';

/// Cambia la sección activa sin reconstruir las demás pantallas.
class ControladorNavegacionPrincipal extends ChangeNotifier {
  SeccionNavegacion seccion = SeccionNavegacion.inicio;
  int get indice => seccion.index;
  void seleccionar(SeccionNavegacion nuevaSeccion) {
    seccion = nuevaSeccion;
    notifyListeners();
  }

  void seleccionarIndice(int indice) =>
      seleccionar(SeccionNavegacion.values[indice]);
}
