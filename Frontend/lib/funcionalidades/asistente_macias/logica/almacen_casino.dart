import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lo que el casino guarda entre una visita y otra: las fichas (las mismas
/// para todas las mesas), lo de cada juego (sus estadisticas) y si suena.
abstract class AlmacenCasino {
  /// Null la primera vez: se empieza con las fichas de regalo.
  Future<int?> fichas();

  Future<void> guardarFichas(int fichas);

  /// Lo que guarda un juego ("blackjack", "ruleta"), o null si nunca jugo.
  Future<Map<String, dynamic>?> juego(String nombre);

  Future<void> guardarJuego(String nombre, Map<String, dynamic> datos);

  /// Si el casino suena. Por defecto, si.
  Future<bool> conSonido();

  Future<void> guardarSonido(bool activo);
}

/// En el telefono, separado por cuenta, como la conversacion con MacIAs.
class AlmacenCasinoLocal implements AlmacenCasino {
  AlmacenCasinoLocal(this.cuenta);

  final String cuenta;

  String get _claveFichas => 'macias.$cuenta.casino.fichas';

  String _claveJuego(String nombre) => 'macias.$cuenta.casino.$nombre';

  /// Del telefono, no de la cuenta: el que lo silencia, lo silencia para
  /// todos los que juegan ahi.
  static const _claveSonido = 'macias.casino.sonido';

  /// Antes del casino, el blackjack guardaba sus fichas y su sonido aparte.
  String get _claveBlackjackVieja => 'macias.$cuenta.blackjack';
  static const _claveSonidoViejo = 'macias.blackjack.sonido';

  Future<SharedPreferences> _preferencias() async {
    final prefs = await SharedPreferences.getInstance();
    await _mudarBlackjack(prefs);
    return prefs;
  }

  /// Las fichas que ya se tenian en el blackjack pasan a ser las del casino,
  /// y sus estadisticas siguen siendo suyas.
  Future<void> _mudarBlackjack(SharedPreferences prefs) async {
    final vieja = prefs.getString(_claveBlackjackVieja);
    if (vieja == null) return;
    try {
      final json = jsonDecode(vieja) as Map<String, dynamic>;
      if (!prefs.containsKey(_claveFichas)) {
        await prefs.setInt(_claveFichas, json['fichas'] as int);
      }
      if (!prefs.containsKey(_claveJuego('blackjack'))) {
        await prefs.setString(
          _claveJuego('blackjack'),
          jsonEncode(json['estadisticas']),
        );
      }
    } catch (_) {
      // Algo que ya no se entiende: se empieza de cero.
    }
    await prefs.remove(_claveBlackjackVieja);
  }

  @override
  Future<int?> fichas() async {
    try {
      return (await _preferencias()).getInt(_claveFichas);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> guardarFichas(int fichas) async {
    try {
      await (await _preferencias()).setInt(_claveFichas, fichas);
    } catch (_) {
      // Si no se pudo guardar, la partida sigue igual.
    }
  }

  @override
  Future<Map<String, dynamic>?> juego(String nombre) async {
    try {
      final guardado = (await _preferencias()).getString(_claveJuego(nombre));
      if (guardado == null) return null;
      return jsonDecode(guardado) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> guardarJuego(String nombre, Map<String, dynamic> datos) async {
    try {
      await (await _preferencias()).setString(
        _claveJuego(nombre),
        jsonEncode(datos),
      );
    } catch (_) {}
  }

  @override
  Future<bool> conSonido() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_claveSonido) ??
          prefs.getBool(_claveSonidoViejo) ??
          true;
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

/// Sin guardar nada en el telefono: para las pruebas.
class AlmacenCasinoEnMemoria implements AlmacenCasino {
  int? _fichas;
  final _juegos = <String, String>{};
  bool _sonido = true;

  @override
  Future<int?> fichas() async => _fichas;

  @override
  Future<void> guardarFichas(int fichas) async => _fichas = fichas;

  @override
  Future<Map<String, dynamic>?> juego(String nombre) async {
    final guardado = _juegos[nombre];
    return guardado == null
        ? null
        : jsonDecode(guardado) as Map<String, dynamic>;
  }

  @override
  Future<void> guardarJuego(String nombre, Map<String, dynamic> datos) async =>
      _juegos[nombre] = jsonEncode(datos);

  @override
  Future<bool> conSonido() async => _sonido;

  @override
  Future<void> guardarSonido(bool activo) async => _sonido = activo;
}
