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
        'UPSA Net',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: const Color(0xFF181818),
          fontFamily: 'Nunito',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      const Text(
        '¿Que necesitas hoy en el campus?',
        style: TextStyle(color: Colors.black54),
      ),
    ],
  );
}
