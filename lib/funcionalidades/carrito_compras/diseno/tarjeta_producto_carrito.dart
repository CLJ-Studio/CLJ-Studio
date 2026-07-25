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
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              elemento.producto.emoji,
              style: const TextStyle(fontSize: 38),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      elemento.producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202221),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: alEliminar,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF929793),
                      size: 20,
                    ),
                  ),
                ],
              ),
              Text(
                'Bs ${elemento.producto.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF3D6F4A),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  SelectorCantidadProducto(
                    cantidad: elemento.cantidad,
                    alDisminuir: alDisminuir,
                    alAumentar: alAumentar,
                  ),
                  const Spacer(),
                  Text(
                    'Bs ${(elemento.producto.precio * elemento.cantidad).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF747A76),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
