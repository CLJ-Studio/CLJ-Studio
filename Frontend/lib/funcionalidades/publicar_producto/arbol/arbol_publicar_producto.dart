import 'package:flutter/material.dart';

import '../../mi_local/logica/controlador_mi_local.dart';
import '../pantalla/pantalla_publicar_producto.dart';

/// Ensambla el flujo de publicación sobre el local del estudiante.
class ArbolPublicarProducto extends StatelessWidget {
  const ArbolPublicarProducto({
    required this.miLocal,
    required this.alCrearLocal,
    super.key,
  });

  final ControladorMiLocal miLocal;
  final VoidCallback alCrearLocal;

  @override
  Widget build(BuildContext context) => PantallaPublicarProducto(
    miLocal: miLocal,
    alCrearLocal: alCrearLocal,
  );
}
