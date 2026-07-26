import 'package:flutter/material.dart';

import 'campo_codigo_estudiante.dart';
import 'dominio_correo_upsa.dart';

/// Muestra el codigo del estudiante junto al dominio institucional fijo.
///
/// El codigo es OPCIONAL: no autentica por si solo (de eso se encarga Google),
/// solo sirve para preseleccionar la cuenta en el selector de Google y evitar
/// que el estudiante elija por error su cuenta personal.
class FormularioCorreoUpsa extends StatelessWidget {
  const FormularioCorreoUpsa({
    required this.alCambiar,
    required this.esValido,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final bool esValido;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoCodigoEstudiante(alCambiar: alCambiar, esValido: esValido),
        const SizedBox(height: 10),
        const DominioCorreoUpsa(),
        const SizedBox(height: 8),
        Text(
          esValido
              ? 'Te llevaremos directo a esta cuenta.'
              : 'Opcional: escribe tu código para entrar más rápido.',
          style: TextStyle(
            color: esValido ? const Color(0xFF5C8A63) : const Color(0xFF9A9A9A),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
