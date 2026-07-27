import 'package:flutter/material.dart';

/// Marca compacta que encabeza la pantalla principal.
class SaludoEstudiante extends StatelessWidget {
  const SaludoEstudiante({required this.nombre, super.key});
  final String nombre;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'UPSA Eat',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          // Iba en negro fijo: en oscuro el titulo desaparecia del todo.
          color: Theme.of(context).colorScheme.onSurface,
          fontFamily: 'Nunito',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      Text(
        '¿Que necesitas hoy en el campus?',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    ],
  );
}
