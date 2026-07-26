import 'package:flutter/foundation.dart';

/// Controla preferencias locales que en el futuro persistirá el backend.
class ControladorConfiguracion extends ChangeNotifier {
  bool notificaciones = true;
  bool temaOscuro = false;
  void cambiarNotificaciones(bool valor) {
    notificaciones = valor;
    notifyListeners();
  }

  void cambiarTema(bool valor) {
    temaOscuro = valor;
    notifyListeners();
  }
}
