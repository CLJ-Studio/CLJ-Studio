import 'package:flutter/material.dart';
import '../modelos/elemento_carrito.dart';
import 'selector_cantidad_producto.dart';

/// Producto del carrito con acciones locales.
class TarjetaProductoCarrito extends StatelessWidget {
  const TarjetaProductoCarrito({
    required this.elemento,
    required this.alAumentar,
    required this.alDisminuir,
    required this.alEliminar,
    super.key,
  });
  final ElementoCarrito elemento;
  final VoidCallback alAumentar;
  final VoidCallback alDisminuir;
  final VoidCallback alEliminar;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                elemento.producto.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  elemento.producto.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text('Bs ${elemento.producto.precio.toStringAsFixed(0)}'),
                SelectorCantidadProducto(
                  cantidad: elemento.cantidad,
                  alDisminuir: alDisminuir,
                  alAumentar: alAumentar,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: alEliminar,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    ),
  );
}
