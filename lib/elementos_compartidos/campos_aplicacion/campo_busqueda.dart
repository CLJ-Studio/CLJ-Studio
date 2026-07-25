import 'package:flutter/material.dart';

/// Buscador visual compartido por inicio y locales.
class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({
    required this.alCambiar,
    this.texto = 'Buscar en UPSA Eat',
    super.key,
  });
  final ValueChanged<String> alCambiar;
  final String texto;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: alCambiar,
    decoration: InputDecoration(
      hintText: texto,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: const Icon(Icons.tune_rounded),
    ),
  );
}
