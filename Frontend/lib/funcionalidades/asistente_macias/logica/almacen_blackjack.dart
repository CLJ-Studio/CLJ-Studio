import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mesa_blackjack.dart';

/// Las fichas y las estadisticas de la mesa, entre una visita y otra.
abstract class AlmacenBlackjack {
  /// Null la primera vez: se empieza con las fichas de regalo.
  Future<({int fichas, EstadisticasBlackjack estadisticas})?> cargar();

  Future<void> guardar(int fichas, EstadisticasBlackjack estadisticas);

  /// Si la mesa suena. Por defecto, si.
  Future<bool> conSonido();

  Future<void> guardarSonido(bool activo);
}

/// En el telefono, separado por cuenta, como la conversacion con MacIAs.
class AlmacenBlackjackLocal implements AlmacenBlackjack {
  AlmacenBlackjackLocal(this.cuenta);

  final String cuenta;

  String get _clave => 'macias.$cuenta.blackjack';

  @override
  Future<({int fichas, EstadisticasBlackjack estadisticas})?> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      if (guardado == null) return null;
      final json = jsonDecode(guardado) as Map<String, dynamic>;
      return (
        fichas: json['fichas'] as int,
        estadisticas: EstadisticasBlackjack.desdeJson(
          json['estadisticas'] as Map<String, dynamic>,
        ),
      );
    } catch (_) {
      // Algo de otra version que ya no se entiende: fichas nuevas.
      return null;
    }
  }

  @override
  Future<void> guardar(int fichas, EstadisticasBlackjack estadisticas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clave,
        jsonEncode({'fichas': fichas, 'estadisticas': estadisticas.aJson()}),
      );
    } catch (_) {
      // Si no se pudo guardar, la partida sigue igual.
    }
  }

  /// Del telefono, no de la cuenta: el que la silencia, la silencia para
  /// todos los que juegan ahi.
  static const _claveSonido = 'macias.blackjack.sonido';

  @override
  Future<bool> conSonido() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_claveSonido) ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> guardarSonido(bool activo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveSonido, activo);
    } catch (_) {}
  }
}

/// Sin guardar nada: para las pruebas.
class AlmacenBlackjackEnMemoria implements AlmacenBlackjack {
  ({int fichas, EstadisticasBlackjack estadisticas})? _guardado;
  bool _sonido = true;

  @override
  Future<bool> conSonido() async => _sonido;

  @override
  Future<void> guardarSonido(bool activo) async => _sonido = activo;

  @override
  Future<({int fichas, EstadisticasBlackjack estadisticas})?> cargar() async =>
      _guardado;

  @override
  Future<void> guardar(int fichas, EstadisticasBlackjack estadisticas) async {
    _guardado = (
      fichas: fichas,
      estadisticas: EstadisticasBlackjack.desdeJson(estadisticas.aJson()),
    );
  }
}
