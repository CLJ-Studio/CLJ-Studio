import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../arbol/arbol_pedidos.dart';

/// Pedidos como pantalla independiente (se abre desde el encabezado del
/// inicio o desde Configuracion; ya no ocupa un lugar en la barra inferior).
class PantallaPedidosCompleta extends StatelessWidget {
  const PantallaPedidosCompleta({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF10091D),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 82,
      title: const Text(
        'Mis pedidos',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      actions: [
        IconButton(
          tooltip: 'Abrir carrito',
          onPressed: () =>
              Navigator.of(context).pushNamed(ConfiguracionRutas.carrito),
          icon: const Icon(Icons.shopping_cart_outlined, size: 28),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: const ArbolPedidos(),
  );
}
