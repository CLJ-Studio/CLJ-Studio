import 'package:flutter/services.dart';

/// Vibraciones breves del sistema. En Web se ignoran de forma segura.
abstract final class RetroalimentacionHaptica {
  static void seleccion() => HapticFeedback.selectionClick();
  static void accion() => HapticFeedback.lightImpact();
  static void exito() => HapticFeedback.mediumImpact();
  static void advertencia() => HapticFeedback.heavyImpact();
}
