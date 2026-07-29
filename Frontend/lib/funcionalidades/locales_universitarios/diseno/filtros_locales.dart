import 'package:flutter/material.dart';

/// Filtros visuales adicionales preparados para lógica futura.
class FiltrosLocales extends StatelessWidget {
  const FiltrosLocales({super.key});

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 8,
    children: [
      Chip(avatar: Icon(Icons.schedule, size: 17), label: Text('Abiertos')),
      Chip(
        avatar: Icon(Icons.visibility_outlined, size: 17),
        label: Text('Más vistos'),
      ),
      Chip(
        avatar: Icon(Icons.delivery_dining, size: 17),
        label: Text('Entrega gratis'),
      ),
    ],
  );
}
