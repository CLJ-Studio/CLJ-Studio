import 'package:flutter/material.dart';
import '../logica/controlador_carrito_compras.dart';
import 'tarjeta_producto_carrito.dart';

class ListaProductosCarrito extends StatelessWidget {
  const ListaProductosCarrito({required this.controlador, super.key});
  final ControladorCarritoCompras controlador;

  @override
  Widget build(BuildContext context) {
    if (controlador.elementos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Color(0xFF777777),
              ),
              SizedBox(height: 12),
              Text(
                'Tu carrito está vacío',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: List.generate(
          controlador.elementos.length,
          (indice) => TarjetaProductoCarrito(
            elemento: controlador.elementos[indice],
            vendedor: controlador.local?.nombreVisible ?? '',
            alAumentar: () => controlador.aumentar(indice),
            alDisminuir: () => controlador.disminuir(indice),
            alEliminar: () => controlador.eliminar(indice),
          ),
        ),
      ),
    );
  }
}
