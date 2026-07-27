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
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 44,
                color: Color(0xFFA5AAA7),
              ),
              SizedBox(height: 12),
              Text(
                'Tu carrito está vacío',
                style: TextStyle(
                  color: Color(0xFF777C79),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: List.generate(
        controlador.elementos.length,
        (indice) => Column(
          children: [
            TarjetaProductoCarrito(
              elemento: controlador.elementos[indice],
              alAumentar: () => controlador.aumentar(indice),
              alDisminuir: () => controlador.disminuir(indice),
              alEliminar: () => controlador.eliminar(indice),
            ),
            if (indice < controlador.elementos.length - 1)
              Divider(height: 18, color: Theme.of(context).dividerColor),
          ],
        ),
      ),
    );
  }
}
