import 'package:flutter/foundation.dart';

import 'estado_acceso_upsa.dart';

/// Controla la construcción y validación visual del correo UPSA.
class ControladorAccesoUpsa extends ChangeNotifier {
  static const String dominio = '@estudiantes.upsa.edu.bo';
  EstadoAccesoUpsa estado = const EstadoAccesoUpsa();

  /// Construye el correo institucional usando solo el código del estudiante.
  String construirCorreoInstitucional(String codigo) {
    return '${codigo.trim().toLowerCase()}$dominio';
  }

  /// Evita vacíos, dominios manuales y formatos ajenos al código esperado.
  void actualizarCodigo(String valor) {
    final codigo = valor.trim().toLowerCase();
    String? error;
    final formatoValido = RegExp(r'^a\d{7,12}$').hasMatch(codigo);
    if (codigo.isEmpty) {
      error = 'Ingresa tu codigo estudiantil.';
    } else if (codigo.contains('@')) {
      error = 'Escribe solo el codigo, sin el dominio.';
    } else if (!formatoValido) {
      error = 'Usa un formato como a2024113311.';
    }
    estado = EstadoAccesoUpsa(
      codigo: codigo,
      correo: construirCorreoInstitucional(codigo),
      error: error,
      esValido: error == null,
    );
    notifyListeners();
  }
}
