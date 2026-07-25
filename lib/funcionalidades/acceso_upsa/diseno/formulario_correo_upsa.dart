import 'package:flutter/material.dart';

import 'campo_codigo_estudiante.dart';
import 'dominio_correo_upsa.dart';

/// Adapta el campo y el dominio entre móvil y escritorio.
class FormularioCorreoUpsa extends StatelessWidget {
  const FormularioCorreoUpsa({
    required this.alCambiar,
    required this.correo,
    required this.error,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final String correo;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, restricciones) {
            final campo = CampoCodigoEstudiante(alCambiar: alCambiar);
            if (restricciones.maxWidth < 560) {
              return Column(
                children: [
                  campo,
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: DominioCorreoUpsa(),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: campo),
                const SizedBox(width: 10),
                const DominioCorreoUpsa(),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (correo.isNotEmpty)
          Text(
            'Usaremos: $correo',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}
