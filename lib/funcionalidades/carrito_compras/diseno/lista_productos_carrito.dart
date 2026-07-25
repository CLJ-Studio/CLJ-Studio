import 'package:flutter/material.dart';
import '../logica/controlador_carrito_compras.dart';
import 'tarjeta_producto_carrito.dart';

/// Renderiza el carrito a partir de su controlador tipado.
class ListaProductosCarrito extends StatelessWidget {
  const ListaProductosCarrito({required this.controlador, super.key});
  final ControladorCarritoCompras controlador;
  @override
  Widget build(BuildContext context) {
    if (controlador.elementos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Tu carrito esta vacio.')),
      );
    }
    return Column(
      children: List.generate(
        controlador.elementos.length,
        (indice) => TarjetaProductoCarrito(
          elemento: controlador.elementos[indice],
          alAumentar: () => controlador.aumentar(indice),
          alDisminuir: () => controlador.disminuir(indice),
          alEliminar: () => controlador.eliminar(indice),
        ),
      ),
    );
  }
}
