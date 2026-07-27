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
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 76,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: alAumentar,
          child: SizedBox(
            width: 38,
            height: 20,
            child: Icon(
              Icons.add_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Text(
          '$cantidad',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        InkWell(
          onTap: alDisminuir,
          child: SizedBox(
            width: 38,
            height: 20,
            child: Icon(
              Icons.remove_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}
