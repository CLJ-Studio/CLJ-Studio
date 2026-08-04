import 'package:flutter/material.dart';
import '../modelos/elemento_carrito.dart';
import 'selector_cantidad_producto.dart';

class TarjetaProductoCarrito extends StatelessWidget {
  const TarjetaProductoCarrito({
    required this.elemento,
    required this.vendedor,
    required this.alAumentar,
    required this.alDisminuir,
    required this.alEliminar,
    super.key,
  });
  final ElementoCarrito elemento;
  final String vendedor;
  final VoidCallback alAumentar;
  final VoidCallback alDisminuir;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 108,
          height: 138,
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEAE2DE),
            borderRadius: BorderRadius.circular(22),
          ),
          child: switch (elemento.producto.imagenUrl) {
            final String url => Image.network(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Text(
                elemento.producto.emoji,
                style: const TextStyle(fontSize: 52),
              ),
            ),
            _ => Text(
              elemento.producto.emoji,
              style: const TextStyle(fontSize: 52),
            ),
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                elemento.producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                vendedor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF58A3A3)),
              ),
              const SizedBox(height: 5),
              Text(
                'Bs ${elemento.producto.precio.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 12),
              SelectorCantidadProducto(
                cantidad: elemento.cantidad,
                alDisminuir: alDisminuir,
                alAumentar: alAumentar,
              ),
            ],
          ),
        ),
        PopupMenuButton<void>(
          tooltip: 'Opciones del producto',
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_horiz, color: Color(0xFF777777)),
          itemBuilder: (_) => [
            PopupMenuItem<void>(
              onTap: alEliminar,
              child: const Row(
                children: [
                  Icon(Icons.delete_outline_rounded),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
