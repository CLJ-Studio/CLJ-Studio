import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Correo del personal de la UPSA: lo que va antes de la arroba, con el
/// dominio fijo al lado.
///
/// Docentes y unidades tienen correos libres ("josebenavente", "DABE"), no
/// un numero. El dominio es mas corto que el de estudiantes y entra junto
/// al nombre sin desplazar el texto.
class CampoCorreoPersonal extends StatelessWidget {
  const CampoCorreoPersonal({
    required this.alCambiar,
    required this.esValido,
    this.controlador,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final bool esValido;
  final TextEditingController? controlador;

  static const dominio = '@upsa.edu.bo';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorBorde = esValido
        ? const Color(0xFF474646)
        : const Color(0xFFBBBCA7);

    return TextField(
      controller: controlador,
      onChanged: alCambiar,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.emailAddress,
      inputFormatters: [
        // Si se pega el correo entero, se queda con lo de antes de la
        // arroba: el dominio ya esta al lado.
        FilteringTextInputFormatter.deny(RegExp(r'@.*|\s')),
        LengthLimitingTextInputFormatter(64),
      ],
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: 'Tu correo de la UPSA',
        hintText: 'nombreapellido',
        prefixIcon: const Icon(Icons.alternate_email_rounded),
        suffixText: dominio,
        suffixStyle: TextStyle(
          color: tema.textTheme.bodyMedium?.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: esValido
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF474646))
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: esValido ? colorBorde : Colors.transparent,
            width: esValido ? 2 : 0,
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
