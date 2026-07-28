import 'package:flutter/material.dart';

/// Marca compacta que encabeza la pantalla principal.
class SaludoEstudiante extends StatelessWidget {
  const SaludoEstudiante({required this.nombre, super.key});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPSA Eat',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorTexto,
            fontFamily: 'Nunito',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        Text(
          '¿Que necesitas hoy en el campus?',
          style: TextStyle(color: colorTexto),
        ),
      ],
    );
  }
}
