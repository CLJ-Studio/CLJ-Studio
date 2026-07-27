import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'configuracion_tema.dart';

/// Preferencia de tema del usuario, recordada entre sesiones.
///
/// Se guarda en el dispositivo y no en el servidor: es una preferencia de
/// esta pantalla, no un dato de la cuenta, y asi se aplica antes de que
/// termine de cargar el perfil (sin parpadeo de claro a oscuro).
class ControladorTema extends ChangeNotifier {
  ControladorTema._();

  static final ControladorTema instancia = ControladorTema._();

  static const _clave = 'tema_oscuro';

  ThemeMode modo = ThemeMode.light;

  bool get esOscuro => modo == ThemeMode.dark;

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    modo = (prefs.getBool(_clave) ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
    _sincronizarBarraDelSistema();
    notifyListeners();
  }

  Future<void> cambiar({required bool oscuro}) async {
    modo = oscuro ? ThemeMode.dark : ThemeMode.light;
    _sincronizarBarraDelSistema();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, oscuro);
  }

  /// Instalada como PWA, la franja de la barra de estado toma su color de la
  /// etiqueta `theme-color`. Si queda fija, se ve una banda de otro color
  /// arriba y la app parece recortada; aqui se hace seguir al tema activo.
  void _sincronizarBarraDelSistema() {
    if (!kIsWeb) return;

    final color = esOscuro
        ? _aHex(ConfiguracionTema.fondoOscuro)
        : '#FFFFFF';

    // NodeList no es iterable en Dart: se recorre por indice.
    final etiquetas = web.document.querySelectorAll('meta[name="theme-color"]');
    for (var i = 0; i < etiquetas.length; i++) {
      (etiquetas.item(i) as web.Element?)?.setAttribute('content', color);
    }
  }

  static String _aHex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
