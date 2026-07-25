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
      IconButton(
        onPressed: alDisminuir,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF0F3F0),
          foregroundColor: const Color(0xFF5C8A63),
        ),
        icon: const Icon(Icons.remove, size: 18),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          '$cantidad',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        onPressed: alAumentar,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF5C8A63),
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.add, size: 18),
      ),
    ],
  );
}
