import 'package:flutter/material.dart';

/// Estado reusable cuando una búsqueda no produce resultados.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({required this.mensaje, super.key});
  final String mensaje;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 50),
        const SizedBox(height: 12),
        Text(mensaje),
      ],
    ),
  );
}
