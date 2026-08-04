import 'package:flutter/widgets.dart';

/// Opción inmutable y configurable de un menú desplegable de la aplicación.
class ElementoMenuDesplegable {
  const ElementoMenuDesplegable({
    required this.icono,
    required this.etiqueta,
    required this.alPresionar,
    this.seleccionado = false,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback alPresionar;
  final bool seleccionado;
}
