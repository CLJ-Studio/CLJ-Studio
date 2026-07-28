import 'package:flutter/material.dart';

/// Encabezado de exploración del catálogo completo.
class EncabezadoLocales extends StatelessWidget {
  const EncabezadoLocales({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Explorar locales',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      Text(
        'Encuentra opciones creadas para la vida universitaria.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}
