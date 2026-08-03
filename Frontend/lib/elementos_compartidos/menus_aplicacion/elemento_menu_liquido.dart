import 'package:flutter/widgets.dart';

/// Opción configurable de un menú líquido.
class ElementoMenuLiquido {
  const ElementoMenuLiquido({
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
