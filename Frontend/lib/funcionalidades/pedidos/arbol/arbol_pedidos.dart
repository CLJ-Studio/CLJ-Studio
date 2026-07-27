import 'package:flutter/material.dart';

import '../datos/repositorio_pedidos.dart';
import '../logica/controlador_pedidos.dart';
import '../pantalla/pantalla_pedidos.dart';

/// Une pantalla, controlador y repositorio de pedidos.
class ArbolPedidos extends StatefulWidget {
  const ArbolPedidos({super.key});

  @override
  State<ArbolPedidos> createState() => _ArbolPedidosState();
}

class _ArbolPedidosState extends State<ArbolPedidos> {
  final controlador = ControladorPedidos(const RepositorioPedidos());

  @override
  void initState() {
    super.initState();
    controlador.cargar();
    controlador.iniciarTiempoReal();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PantallaPedidos(controlador: controlador);
}
