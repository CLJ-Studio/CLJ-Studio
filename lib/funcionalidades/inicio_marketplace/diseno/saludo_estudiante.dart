import 'package:flutter/material.dart';

/// Saludo compacto del estudiante simulado.
class SaludoEstudiante extends StatelessWidget {
  const SaludoEstudiante({required this.nombre, super.key});
  final String nombre;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Hola, $nombre 👋',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const Text(
        '¿Que necesitas hoy en el campus?',
        style: TextStyle(color: Colors.black54),
      ),
    ],
  );
}
