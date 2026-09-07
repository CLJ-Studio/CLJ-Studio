import 'package:flutter/foundation.dart';

import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';

/// Cambia la sección activa sin reconstruir las demás pantallas.
class ControladorNavegacionPrincipal extends ChangeNotifier {
  int indice = 0;

  void seleccionarIndice(int nuevoIndice) {
    if (nuevoIndice == indice) return;
    indice = nuevoIndice;
    // `selectionClick` es el mismo pulso corto y preciso que usa un picker
    // nativo. Al vivir aquí también responde al deslizar, no solo al tocar.
    RetroalimentacionHaptica.seleccion();
    notifyListeners();
  }
}
