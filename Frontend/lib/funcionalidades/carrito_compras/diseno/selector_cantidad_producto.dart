import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Container(
    width: 132,
    height: 48,
    decoration: BoxDecoration(
      color: Color(0xFFE6E1D5),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE6E1D5)),
    ),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: alDisminuir,
            borderRadius: BorderRadius.circular(24),
            child: const Icon(Icons.remove_rounded, color: Color(0xFF474646)),
          ),
        ),
        Text(
          '$cantidad',
          style: const TextStyle(
            color: Color(0xFF474646),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Material(
              color: const Color(0xFF474646),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: alAumentar,
                customBorder: const CircleBorder(),
                child: const Icon(Icons.add_rounded, color: Color(0xFFE6E1D5)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
