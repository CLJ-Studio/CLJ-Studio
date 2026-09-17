import 'package:flutter/material.dart';

import '../../mi_local/logica/controlador_mi_local.dart';
import '../pantalla/pantalla_publicar_producto.dart';

/// Ensambla el flujo de publicación sobre el local del estudiante.
class ArbolPublicarProducto extends StatelessWidget {
  const ArbolPublicarProducto({
    required this.miLocal,
    required this.imagenesIniciales,
    required this.loteImagenes,
    super.key,
  });

  final ControladorMiLocal miLocal;
  final List<String> imagenesIniciales;
  final int loteImagenes;

  @override
  Widget build(BuildContext context) => PantallaPublicarProducto(
    miLocal: miLocal,
    imagenesIniciales: imagenesIniciales,
    loteImagenes: loteImagenes,
  );
}
