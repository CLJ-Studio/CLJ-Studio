import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'almacen_casino.dart';
import 'casino.dart';

/// Lo que dice el servidor de la billetera de alguien.
class SaldoCasino {
  const SaldoCasino({required this.fichas, this.enMesa = 0, this.mesa});

  factory SaldoCasino.desdeMapa(Map<String, dynamic> datos) => SaldoCasino(
    fichas: (datos['fichas'] as num?)?.toInt() ?? 0,
    enMesa: (datos['en_mesa'] as num?)?.toInt() ?? 0,
    mesa: datos['mesa'] as String?,
  );

  /// Las que se pueden usar en cualquier mesa.
  final int fichas;

  /// Las que estan sentadas en una mesa de poker, y en cual.
  final int enMesa;
  final String? mesa;
}

/// A donde va cada cambio de la billetera.
abstract interface class ServidorBilletera {
  /// Manda lo que cambio ([delta]) con su [lote], que el servidor cuenta una
  /// sola vez aunque llegue dos, y devuelve cuantas hay. La primera vez,
  /// [inicial] son las que tenia guardadas el telefono.
  Future<SaldoCasino> sincronizar({
    required String lote,
    required int delta,
    int? inicial,
  });
}

class ServidorBilleteraSupabase implements ServidorBilletera {
  const ServidorBilleteraSupabase();

  @override
  Future<SaldoCasino> sincronizar({
    required String lote,
    required int delta,
    int? inicial,
  }) async {
    final datos = await Supabase.instance.client.rpc(
      'casino_sincronizar',
      params: {'p_lote': lote, 'p_delta': delta, 'p_inicial': inicial},
    );
    return SaldoCasino.desdeMapa((datos as Map).cast<String, dynamic>());
  }
}

/// Las fichas del casino, en la cuenta: las mismas en la ruleta, el
/// blackjack y el poker, y en cualquier telefono.
///
/// La ruleta y el blackjack juegan con una copia en el telefono, asi andan
/// sin red. Cada cambio viaja al servidor como un lote: lo que se gano o
/// perdio desde lo ultimo que vio la mesa, no el total. El total pisaba lo
/// que hubiera pasado mientras tanto en el poker (las fichas que vuelven al
/// levantarse, incluso desde otro telefono). Si se corta la red, el lote
/// queda guardado y sale la proxima vez; si llega dos veces, el servidor lo
/// cuenta una.
class AlmacenCasinoServidor implements AlmacenCasino {
  AlmacenCasinoServidor(
    this.cuenta, {
    this.servidor = const ServidorBilleteraSupabase(),
    this.espera = const Duration(seconds: 3),
  }) : _local = AlmacenCasinoLocal(cuenta);

  final String cuenta;
  final ServidorBilletera servidor;

  /// La copia: sus fichas son las del servidor mas lo que todavia no viajo.
  /// Lo de cada juego y el sonido viven solo aca.
  final AlmacenCasinoLocal _local;

  /// Cuanto se espera al servidor antes de seguir con la copia: sin red, la
  /// entrada al casino no se queda colgada.
  final Duration espera;

  String get _clavePendiente => 'macias.$cuenta.casino.pendiente';
  String get _claveLote => 'macias.$cuenta.casino.lote';
  String get _claveMigrada => 'macias.$cuenta.casino.migrada';

  /// Lo ultimo que vio la mesa que esta jugando: lo que guarde se compara
  /// con esto.
  int? _visto;
  Future<void> _cola = Future.value();
  ({int fichas, String? mesa}) _enPoker = (fichas: 0, mesa: null);

  @override
  ({int fichas, String? mesa}) get enPoker => _enPoker;

  @override
  Future<int?> fichas() async {
    try {
      await _sincronizar().timeout(espera);
    } on TimeoutException {
      // Sigue con la copia; el lote sale igual cuando el servidor conteste.
    }
    final fichas = await _local.fichas();
    _visto = fichas ?? Casino.fichasIniciales;
    return fichas;
  }

  @override
  Future<void> guardarFichas(int fichas) {
    final visto = _visto;
    _visto = fichas;
    final guardado = _encolar(() async {
      final copia = await _local.fichas() ?? Casino.fichasIniciales;
      final delta = fichas - (visto ?? copia);
      if (delta == 0) return;
      final prefs = await SharedPreferences.getInstance();
      await _local.guardarFichas(math.max(0, copia + delta));
      await prefs.setInt(
        _clavePendiente,
        (prefs.getInt(_clavePendiente) ?? 0) + delta,
      );
    });
    // La mesa no espera a la red: guarda en el telefono y sigue.
    unawaited(_sincronizar());
    return guardado;
  }

  /// Manda lo que haya pendiente, de a un lote, y trae lo que hay.
  Future<void> _sincronizar() => _encolar(() async {
    final prefs = await SharedPreferences.getInstance();
    // Un lote que no llego se manda igual, con su mismo nombre; despues,
    // lo que se haya juntado mientras tanto.
    for (var vuelta = 0; vuelta < 3; vuelta++) {
      var lote = _leerLote(prefs);
      if (lote == null) {
        final pendiente = prefs.getInt(_clavePendiente) ?? 0;
        final migrada = prefs.getBool(_claveMigrada) ?? false;
        if (vuelta > 0 && pendiente == 0) return;
        lote = (
          id: nuevoLote(),
          delta: pendiente,
          inicial: migrada ? null : await _local.fichas(),
        );
        await prefs.setString(
          _claveLote,
          jsonEncode({
            'id': lote.id,
            'delta': lote.delta,
            'inicial': lote.inicial,
          }),
        );
        await prefs.setInt(_clavePendiente, 0);
      }
      final saldo = await servidor.sincronizar(
        lote: lote.id,
        delta: lote.delta,
        inicial: lote.inicial,
      );
      final pendiente = prefs.getInt(_clavePendiente) ?? 0;
      await _local.guardarFichas(math.max(0, saldo.fichas + pendiente));
      await prefs.setBool(_claveMigrada, true);
      await prefs.remove(_claveLote);
      _enPoker = (fichas: saldo.enMesa, mesa: saldo.mesa);
    }
  });

  ({String id, int delta, int? inicial})? _leerLote(SharedPreferences prefs) {
    final guardado = prefs.getString(_claveLote);
    if (guardado == null) return null;
    try {
      final json = jsonDecode(guardado) as Map<String, dynamic>;
      return (
        id: json['id'] as String,
        delta: (json['delta'] as num).toInt(),
        inicial: (json['inicial'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Una cosa a la vez: dos lotes que salen juntos se pisarian la cuenta.
  /// Lo que falla (sin red) no frena a lo que sigue.
  Future<void> _encolar(Future<void> Function() tarea) {
    final hecha = _cola.then((_) => tarea()).catchError((Object _) {});
    _cola = hecha;
    return hecha;
  }

  @override
  Future<Map<String, dynamic>?> juego(String nombre) => _local.juego(nombre);

  @override
  Future<void> guardarJuego(String nombre, Map<String, dynamic> datos) =>
      _local.guardarJuego(nombre, datos);

  @override
  Future<bool> conSonido() => _local.conSonido();

  @override
  Future<void> guardarSonido(bool activo) => _local.guardarSonido(activo);
}

final _azar = math.Random.secure();

/// Un uuid v4: el nombre de un lote.
String nuevoLote() {
  final b = List<int>.generate(16, (_) => _azar.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
