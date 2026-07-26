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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 82,
          height: 100,
          child: Center(
            child: Container(
              width: 72,
              height: 82,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                elemento.producto.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bs ${elemento.producto.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF202321),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                elemento.producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF343835),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                elemento.producto.descripcion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFA0A5A1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            SelectorCantidadProducto(
              cantidad: elemento.cantidad,
              alDisminuir: alDisminuir,
              alAumentar: alAumentar,
            ),
            IconButton(
              tooltip: 'Eliminar producto',
              onPressed: alEliminar,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Color(0xFFA0A5A1),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
