import 'package:flutter/material.dart';

/// Campo limitado al código que antecede al dominio institucional.
class CampoCodigoEstudiante extends StatelessWidget {
  const CampoCodigoEstudiante({required this.alCambiar, super.key});
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: alCambiar,
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      decoration: const InputDecoration(
        labelText: 'Codigo de estudiante',
        hintText: 'a2024113311',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
    );
  }
}
