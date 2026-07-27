import 'package:flutter/material.dart';

import '../arbol/arbol_pedidos.dart';

/// Pedidos como pantalla independiente (se abre desde el encabezado del
/// inicio o desde Configuracion; ya no ocupa un lugar en la barra inferior).
class PantallaPedidosCompleta extends StatelessWidget {
  const PantallaPedidosCompleta({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFBFA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAFBFA),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Pedidos',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: const ArbolPedidos(),
  );
}
