import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo del código institucional, con el dominio siempre a la vista.
///
/// El dominio va como sufijo fijo dentro del propio campo.
class CampoCodigoEstudiante extends StatelessWidget {
  const CampoCodigoEstudiante({
    required this.alCambiar,
    required this.esValido,
    this.hayError = false,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final bool esValido;
  final bool hayError;

  @override
  Widget build(BuildContext context) {
    final colorBorde = hayError
        ? Theme.of(context).colorScheme.error
        : esValido
        ? const Color(0xFF474646)
        : const Color(0xFFBBBCA7);

    return TextField(
      onChanged: alCambiar,
      autocorrect: false,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
      decoration: InputDecoration(
        labelText: 'Número de registro',
        prefixText: 'a',
        prefixStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        prefixIcon: const Icon(Icons.badge_outlined),
        suffixText: '@estudiantes.upsa.edu.bo',
        suffixStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: esValido
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF474646))
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: esValido || hayError ? colorBorde : Colors.transparent,
            width: esValido || hayError ? 2 : 0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorBorde, width: 2),
        ),
      ),
    );
  }
}
