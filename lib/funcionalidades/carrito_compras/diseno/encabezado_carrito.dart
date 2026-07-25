import 'package:flutter/material.dart';

class EncabezadoCarrito extends StatelessWidget {
  const EncabezadoCarrito({super.key});
  @override
  Widget build(BuildContext context) => Text(
    'Tu carrito',
    style: Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
  );
}
