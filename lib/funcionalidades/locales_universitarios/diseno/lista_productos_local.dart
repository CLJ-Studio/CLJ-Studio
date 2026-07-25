import 'package:flutter/material.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Lista los productos tipados del local seleccionado.
class ListaProductosLocal extends StatelessWidget {
  const ListaProductosLocal({required this.productos, super.key});
  final List<ProductoMarketplace> productos;

  @override
  Widget build(BuildContext context) => Column(
    children: productos
        .map(
          (producto) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(producto.emoji),
              ),
              title: Text(
                producto.nombre,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(producto.descripcion),
              trailing: Text(
                'Bs ${producto.precio.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        )
        .toList(),
  );
}
