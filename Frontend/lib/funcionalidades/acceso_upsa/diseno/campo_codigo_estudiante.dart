import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo limitado al código que antecede al dominio institucional.
class CampoCodigoEstudiante extends StatelessWidget {
  const CampoCodigoEstudiante({
    required this.alCambiar,
    required this.esValido,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final bool esValido;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: alCambiar,
      autocorrect: false,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: 'Código de estudiante',
        prefixText: 'a',
        prefixStyle: const TextStyle(
          color: Color(0xFF292A29),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        prefixIcon: const Icon(Icons.badge_outlined),
        suffixIcon: esValido
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF5C8A63))
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: esValido ? const Color(0xFF79A780) : Colors.transparent,
            width: esValido ? 2 : 0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: esValido ? const Color(0xFF5C8A63) : const Color(0xFFB8BDB8),
            width: 2,
          ),
        ),
      ),
    );
  }
}
