import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo del código institucional, con el dominio siempre a la vista.
///
/// El dominio va como sufijo dentro del propio campo cuando entra junto al
/// numero completo; si no, va justo debajo. En un telefono de 360 a 412 dp
/// no entran los dos: el campo se desplazaba al escribir y dejaba ver solo
/// los ultimos digitos ("a11234"), como si la app se comiera los primeros.
class CampoCodigoEstudiante extends StatelessWidget {
  const CampoCodigoEstudiante({
    required this.alCambiar,
    required this.esValido,
    this.hayError = false,
    this.controlador,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final bool esValido;
  final bool hayError;

  /// Lo tiene la pantalla y no el campo: el campo se vuelve a crear cada vez
  /// que se regresa al primer paso, y sin esto aparecia vacio aunque la
  /// pantalla todavia tenia el numero.
  final TextEditingController? controlador;

  static const dominio = '@estudiantes.upsa.edu.bo';

  static const _estiloNumero = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: .5,
  );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colorBorde = hayError
        ? tema.colorScheme.error
        : esValido
        ? const Color(0xFF474646)
        : const Color(0xFFBBBCA7);
    final estiloPrefijo = TextStyle(
      color: tema.colorScheme.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    );
    final estiloDominio = TextStyle(
      color: tema.textTheme.bodyMedium?.color,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, restricciones) {
        final dominioAdentro =
            restricciones.maxWidth >=
            _anchoConTodo(context, estiloPrefijo, estiloDominio);

        return TextField(
          controller: controlador,
          onChanged: alCambiar,
          autocorrect: false,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: _estiloNumero,
          decoration: InputDecoration(
            labelText: 'Número de registro',
            prefixText: 'a',
            prefixStyle: estiloPrefijo,
            prefixIcon: const Icon(Icons.badge_outlined),
            suffixText: dominioAdentro ? dominio : null,
            suffixStyle: estiloDominio,
            helperText: dominioAdentro ? null : dominio,
            helperStyle: estiloDominio,
            suffixIcon: esValido
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF474646),
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
        );
      },
    );
  }

  /// Lo que ocupa el campo con los diez digitos, el dominio y los dos
  /// iconos, medido con la letra de verdad y el tamaño de texto del telefono.
  static double _anchoConTodo(
    BuildContext context,
    TextStyle prefijo,
    TextStyle estiloDominio,
  ) {
    final base = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final escala = MediaQuery.textScalerOf(context);
    double medir(String texto, TextStyle estilo) {
      final pintor = TextPainter(
        text: TextSpan(text: texto, style: base.merge(estilo)),
        textDirection: TextDirection.ltr,
        textScaler: escala,
        maxLines: 1,
      )..layout();
      final ancho = pintor.width;
      pintor.dispose();
      return ancho;
    }

    // Los dos iconos de 48, el relleno interior a cada lado y un respiro.
    const iconosYRelleno = 48.0 + 48 + 2 * 12 + 8;
    return iconosYRelleno +
        medir('a', prefijo) +
        medir('0000000000', _estiloNumero) +
        medir(dominio, estiloDominio);
  }
}
