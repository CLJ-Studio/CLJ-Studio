import 'package:flutter/material.dart';

/// Acceso visible al carrito con un contador simulado.
class BotonCarritoCompras extends StatelessWidget {
  const BotonCarritoCompras({required this.alPresionar, super.key});
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Badge(
    label: const Text('3'),
    child: IconButton.filledTonal(
      tooltip: 'Abrir carrito',
      onPressed: alPresionar,
      icon: const Icon(Icons.shopping_bag_outlined),
    ),
  );
}
