import 'package:flutter/material.dart';

import 'campo_codigo_estudiante.dart';

/// Adapta el campo y el dominio entre móvil y escritorio.
class FormularioCorreoUpsa extends StatelessWidget {
  const FormularioCorreoUpsa({
    required this.alCambiar,
    required this.error,
    required this.esValido,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final String? error;
  final bool esValido;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoCodigoEstudiante(alCambiar: alCambiar, esValido: esValido),
        const SizedBox(height: 10),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
