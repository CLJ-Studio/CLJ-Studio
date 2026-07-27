import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo del código institucional, con el dominio siempre a la vista.
///
/// El dominio va como sufijo dentro del propio campo y no debajo: puesto
/// aparte, en pantallas angostas se encimaba con el texto escrito.
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
        ? const Color(0xFF5C8A63)
        : const Color(0xFFB8BDB8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
            labelText: 'Código de estudiante',
            hintText: '2023115833',
            prefixText: 'a',
            prefixStyle: const TextStyle(
              color: Color(0xFF292A29),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            prefixIcon: const Icon(Icons.badge_outlined),
            suffixIcon: esValido
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF5C8A63),
                  )
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
        ),
        const SizedBox(height: 6),
        // El dominio se muestra como texto tenue alineado al campo: ocupa
        // poco y deja claro que se completa solo.
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            '@estudiantes.upsa.edu.bo',
            style: TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
