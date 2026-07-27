import 'package:flutter/material.dart';

/// Presenta el mensaje principal con la jerarquía minimalista del acceso.
class EncabezadoAccesoUpsa extends StatelessWidget {
  const EncabezadoAccesoUpsa({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Tu campus.\nTodo más cerca.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Compra, vende y encuentra lo que necesitas dentro de la comunidad UPSA.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF858585),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
