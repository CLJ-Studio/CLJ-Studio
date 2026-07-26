import 'package:flutter/material.dart';

/// Indicador sutil de la sección seleccionada.
class IndicadorSeccionActiva extends StatelessWidget {
  const IndicadorSeccionActiva({required this.activo, super.key});
  final bool activo;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: activo ? 22 : 0,
    height: 3,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
