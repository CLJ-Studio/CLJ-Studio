import 'package:flutter/material.dart';

/// Selector táctil para modificar la cantidad.
class SelectorCantidadProducto extends StatelessWidget {
  const SelectorCantidadProducto({
    required this.cantidad,
    required this.alDisminuir,
    required this.alAumentar,
    super.key,
  });
  final int cantidad;
  final VoidCallback alDisminuir;
  final VoidCallback alAumentar;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filledTonal(
        onPressed: alDisminuir,
        icon: const Icon(Icons.remove, size: 18),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '$cantidad',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      IconButton.filledTonal(
        onPressed: alAumentar,
        icon: const Icon(Icons.add, size: 18),
      ),
    ],
  );
}
