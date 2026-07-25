import 'package:flutter/material.dart';

import 'boton_carrito_compras.dart';
import 'saludo_estudiante.dart';

/// Une saludo y carrito en el encabezado principal.
class EncabezadoInicioMarketplace extends StatelessWidget {
  const EncabezadoInicioMarketplace({
    required this.nombre,
    required this.alAbrirCarrito,
    super.key,
  });
  final String nombre;
  final VoidCallback alAbrirCarrito;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: SaludoEstudiante(nombre: nombre)),
      BotonCarritoCompras(alPresionar: alAbrirCarrito),
    ],
  );
}
