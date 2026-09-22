import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/foto_producto.dart';
import '../../../elementos_compartidos/tarjetas_aplicacion/estilo_tarjeta_producto.dart';
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
        // La miniatura era vertical (108 x 138) y las fotos son apaisadas:
        // `cover` se comia los lados y el producto llegaba al carrito
        // irreconocible respecto a como se veia en el catalogo.
        SizedBox(
          width: 112,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: EstiloTarjetaProducto.borde,
              border: Border.all(color: const Color(0xFFE9E9E9)),
            ),
            child: ClipRRect(
              borderRadius: EstiloTarjetaProducto.borde,
              child: FotoProducto(
                url: elemento.producto.imagenUrl,
                anchoVisible: 112,
                alFallar: Center(
                  child: Text(
                    elemento.producto.emoji,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF474646),
                ),
              ),
              // El sabor elegido, porque dos lineas del mismo producto solo se
              // diferencian en esto: sin verlo, el carrito parece repetido.
              if (elemento.variante case final variante?) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6E1D5),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    variante.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF474646),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                vendedor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF848381)),
              ),
              const SizedBox(height: 5),
              Text(
                'Bs ${elemento.precioUnitario.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF474646)),
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
          icon: const Icon(Icons.more_horiz, color: Color(0xFF848381)),
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
