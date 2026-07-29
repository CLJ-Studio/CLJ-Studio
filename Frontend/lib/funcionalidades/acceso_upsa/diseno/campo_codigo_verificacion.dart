import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo donde se pega el código que llegó al correo.
///
/// Sigue el mismo trazo que el del número de registro: mismo alto, mismos
/// bordes y el verde de marca cuando ya está completo.
class CampoCodigoVerificacion extends StatelessWidget {
  const CampoCodigoVerificacion({
    required this.alCambiar,
    required this.alEnviar,
    required this.esValido,
    this.hayError = false,
    super.key,
  });

  final ValueChanged<String> alCambiar;
  final VoidCallback alEnviar;
  final bool esValido;
  final bool hayError;

  /// Los códigos de Supabase son de seis dígitos.
  static const largo = 6;

  @override
  Widget build(BuildContext context) {
    final colorBorde = hayError
        ? Theme.of(context).colorScheme.error
        : esValido
        ? const Color(0xFF5C8A63)
        : const Color(0xFFB8BDB8);

    return TextField(
      onChanged: alCambiar,
      onSubmitted: (_) => alEnviar(),
      autofocus: true,
      autocorrect: false,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      // En web y en móvil el gestor de contraseñas puede rellenarlo solo.
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(largo),
      ],
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 10,
      ),
      decoration: InputDecoration(
        hintText: '——————',
        hintStyle: const TextStyle(
          letterSpacing: 6,
          fontWeight: FontWeight.w400,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: colorBorde, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          borderSide: BorderSide(color: colorBorde, width: 2),
        ),
      ),
    );
  }
}
