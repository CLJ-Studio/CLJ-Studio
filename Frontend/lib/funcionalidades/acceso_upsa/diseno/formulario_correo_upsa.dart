import 'package:flutter/material.dart';

import 'campo_codigo_estudiante.dart';

/// Codigo institucional del estudiante.
///
/// Es OPCIONAL: no autentica por si solo (de eso se encarga Google), solo
/// preselecciona la cuenta en el selector para que nadie entre por error
/// con su correo personal.
class FormularioCorreoUpsa extends StatelessWidget {
  const FormularioCorreoUpsa({
    required this.alCambiar,
    required this.esValido,
    required this.digitos,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final bool esValido;
  final String digitos;

  /// Explica el formato solo cuando lo escrito ya no puede cumplirlo, para
  /// no regañar mientras el estudiante todavia esta tecleando.
  String? get _pista {
    if (digitos.isEmpty) return null;

    if (digitos.length >= 4) {
      final anio = int.tryParse(digitos.substring(0, 4)) ?? 0;
      if (anio < 2000 || anio > DateTime.now().year) {
        return 'El código empieza con tu año de ingreso.';
      }
    }
    if (digitos.length >= 6) {
      final periodo = digitos.substring(4, 6);
      if (periodo != '11' && periodo != '12') {
        return 'Después del año va 11 (primer semestre) o 12 (segundo).';
      }
    }
    if (digitos.length == 10 && !esValido) {
      return 'Ese código no tiene el formato de la UPSA.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pista = _pista;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoCodigoEstudiante(
          alCambiar: alCambiar,
          esValido: esValido,
          hayError: pista != null,
        ),
        const SizedBox(height: 8),
        Text(
          pista ??
              (esValido
                  ? 'Te llevaremos directo a esta cuenta.'
                  : 'Opcional: escribe tu registro para entrar más rápido.'),
          style: TextStyle(
            color: pista != null
                ? Theme.of(context).colorScheme.error
                : esValido
                ? const Color(0xFF5C8A63)
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
