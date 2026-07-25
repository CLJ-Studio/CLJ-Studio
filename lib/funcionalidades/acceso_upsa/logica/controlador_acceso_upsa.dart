import 'package:flutter/foundation.dart';

import 'estado_acceso_upsa.dart';

/// Controla la construcción y validación visual del correo UPSA.
class ControladorAccesoUpsa extends ChangeNotifier {
  static const String dominio = '@estudiantes.upsa.edu.bo';
  EstadoAccesoUpsa estado = const EstadoAccesoUpsa();

  /// Añade la `a` institucional que ya se muestra fija dentro del campo.
  String construirCodigoInstitucional(String digitos) {
    return 'a${digitos.trim()}';
  }

  String construirCorreoInstitucional(String codigo) {
    return '$codigo$dominio';
  }

  /// Acepta exactamente once dígitos; el campo impide letras y exceso de texto.
  void actualizarCodigo(String valor) {
    final digitos = valor.replaceAll(RegExp(r'\D'), '');
    final codigo = construirCodigoInstitucional(digitos);
    String? error;
    final formatoValido = RegExp(r'^\d{11}$').hasMatch(digitos);
    if (digitos.isEmpty) {
      error = 'Ingresa los 11 dígitos de tu código.';
    } else if (!formatoValido) {
      error = 'El código debe tener exactamente 11 dígitos.';
    }
    estado = EstadoAccesoUpsa(
      codigo: formatoValido ? codigo : '',
      correo: formatoValido ? construirCorreoInstitucional(codigo) : '',
      error: error,
      esValido: formatoValido,
    );
    notifyListeners();
  }
}
