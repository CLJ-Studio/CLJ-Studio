import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'mesa_poker.dart';
import 'sonidos_casino.dart';

/// Un lugar de la mesa, sin coordenadas: la geometria de la pantalla lo
/// vuelve un punto. Asi la coreografia no sabe de pixeles y se puede probar.
sealed class LugarMesa {
  const LugarMesa();
}

/// De donde salen las cartas.
class EnMazo extends LugarMesa {
  const EnMazo();
}

/// El centro, donde se juntan las apuestas.
class EnBote extends LugarMesa {
  const EnBote();
}

/// A donde van las cartas de quien se retira.
class EnDescarte extends LugarMesa {
  const EnDescarte();
}

class EnAsiento extends LugarMesa {
  const EnAsiento(this.posicion);

  final int posicion;
}

/// Delante de un asiento, donde queda su apuesta.
class EnApuesta extends LugarMesa {
  const EnApuesta(this.posicion);

  final int posicion;
}

/// La carta [indice] (0 o 1) de quien esta en [posicion].
class EnMano extends LugarMesa {
  const EnMano(this.posicion, this.indice);

  final int posicion;
  final int indice;
}

class EnComunitaria extends LugarMesa {
  const EnComunitaria(this.indice);

  final int indice;
}

/// Algo que cruza la mesa: fichas o una carta.
sealed class VueloPoker {
  VueloPoker({
    required this.id,
    required this.desde,
    required this.hasta,
    required this.duracion,
  });

  final int id;
  final LugarMesa desde;
  final LugarMesa hasta;
  final Duration duracion;
}

class VueloFichas extends VueloPoker {
  VueloFichas({
    required super.id,
    required super.desde,
    required super.hasta,
    required super.duracion,
    required this.monto,
  });

  final int monto;
}

class VueloCarta extends VueloPoker {
  VueloCarta({
    required super.id,
    required super.desde,
    required super.hasta,
    required super.duracion,
    this.codigo,
    this.bocaArriba = false,
    this.desvanecer = false,
  });

  /// Null: se ve el dorso (la de otro, que nadie mas ve).
  final String? codigo;

  /// Se da vuelta en el aire.
  final bool bocaArriba;

  /// Se apaga mientras viaja: las de quien se retira.
  final bool desvanecer;
}

/// Lo que se mueve en la mesa entre un estado del servidor y el siguiente.
///
/// La mesa se dibuja siempre con el ultimo estado. La coreografia solo tapa
/// por un rato lo que todavia "no llego" (la carta que esta volando, la
/// apuesta que va en camino, el bote antes de que caigan las fichas) y
/// lanza los vuelos. Cuando llega otro estado, lo que estaba en el aire se
/// corta y se anima lo nuevo: la mesa nunca queda atras del servidor.
class CoreografiaPoker extends ChangeNotifier {
  CoreografiaPoker({this.sonar, this.alGanar});

  final void Function(SonidoMesa sonido, {double volumen})? sonar;

  /// Cuando llegan a mi asiento las fichas que gane.
  final VoidCallback? alGanar;

  /// Lo que se tapa mientras vuela.
  static String carta(int posicion, int indice) => 'carta:$posicion:$indice';
  static String comunitaria(int indice) => 'comun:$indice';

  /// Las cartas de alguien al final: tapadas hasta que les toca darse vuelta.
  static String vistas(int posicion) => 'vistas:$posicion';

  /// Los numeros que se ven atrasados mientras las fichas viajan.
  static String apuesta(int posicion) => 'apuesta:$posicion';
  static String fichas(int posicion) => 'fichas:$posicion';
  static const bote = 'bote';

  /// Quien gano, con que y cuanto: se ve cuando le llegan las fichas.
  static const resultado = 'resultado';

  final _vuelos = <VueloPoker>[];
  final _ocultos = <String>{};
  final _valores = <String, int>{};
  final _relojes = <Timer>[];
  var _proximo = 0;
  var _cerrada = false;

  List<VueloPoker> get vuelos => List.unmodifiable(_vuelos);
  bool oculto(String clave) => _ocultos.contains(clave);
  int? valor(String clave) => _valores[clave];

  /// Todavia hay algo en camino.
  bool get enMovimiento => _relojes.isNotEmpty;

  /// Llego un estado nuevo: corta lo que se estaba moviendo y anima lo que
  /// cambio desde [antes].
  void cambio(EstadoMesaPoker? antes, EstadoMesaPoker ahora) {
    _cortar();
    final mano = ahora.mano;
    final manoAntes = antes?.mano;
    if (antes != null && mano != null) {
      if (manoAntes == null || manoAntes.id != mano.id) {
        if (mano.enJuego) _repartir(ahora);
      } else {
        _seguir(antes, manoAntes, ahora, mano);
      }
    }
    notifyListeners();
  }

  void _seguir(
    EstadoMesaPoker antes,
    ManoPoker manoAntes,
    EstadoMesaPoker ahora,
    ManoPoker mano,
  ) {
    _retirarse(antes, ahora);
    final cerroRonda =
        mano.comunitarias.length > manoAntes.comunitarias.length ||
        (manoAntes.enJuego && !mano.enJuego);
    if (!cerroRonda) {
      _apostar(antes, ahora, Duration.zero);
      return;
    }
    if (!mano.enJuego) _ocultos.add(resultado);
    var t = _recoger(antes, ahora);
    t = _abrirComunitarias(manoAntes.comunitarias.length, ahora, t);
    if (!mano.enJuego) {
      t = _mostrar(ahora, t);
      _pagar(ahora, t);
    }
  }

  /// Una mano nueva: el mazo se baraja y las cartas salen de a una, dos
  /// vueltas desde la izquierda del boton. Despues, las ciegas.
  void _repartir(EstadoMesaPoker ahora) {
    final yo = ahora.yo;
    sonar?.call(SonidoMesa.barajar, volumen: .7);
    var t = _ms(280);
    for (var vuelta = 0; vuelta < 2; vuelta++) {
      for (final p in ahora.ordenReparto) {
        final mia = p == yo && ahora.misCartas.length == 2;
        final clave = carta(p, vuelta);
        _ocultos.add(clave);
        _volar(
          VueloCarta(
            id: _proximo++,
            desde: const EnMazo(),
            hasta: EnMano(p, vuelta),
            duracion: _ms(mia ? 440 : 340),
            codigo: mia ? ahora.misCartas[vuelta] : null,
            bocaArriba: mia,
          ),
          en: t,
          salida: SonidoMesa.cartaSale,
          volumen: .6,
          // La mia termina de darse vuelta un poco despues de caer.
          margen: _ms(mia ? 300 : 40),
          alTerminar: () => _ocultos.remove(clave),
        );
        t += _ms(110);
      }
    }
    _apostar(null, ahora, t + _ms(160));
    _abrirComunitarias(0, ahora, t + _ms(560));
  }

  /// Las fichas que alguien puso desde la ultima vez van de su asiento a su
  /// lugar de apuesta.
  void _apostar(EstadoMesaPoker? antes, EstadoMesaPoker ahora, Duration en) {
    for (final j in ahora.jugadores) {
      final p = j.posicion;
      final previa = antes?.apuestaVisible(p) ?? 0;
      final nueva = ahora.apuestaVisible(p);
      if (nueva <= previa) continue;
      final clave = apuesta(p);
      _valores[clave] = previa;
      _volar(
        VueloFichas(
          id: _proximo++,
          desde: EnAsiento(p),
          hasta: EnApuesta(p),
          duracion: _ms(380),
          monto: nueva - previa,
        ),
        en: en,
        salida: SonidoMesa.ficha,
        volumen: .8,
        alTerminar: () => _valores.remove(clave),
      );
    }
  }

  /// Quien se retiro tira sus cartas al centro.
  void _retirarse(EstadoMesaPoker antes, EstadoMesaPoker ahora) {
    for (final j in ahora.jugadores) {
      final previo = antes.jugador(j.posicion);
      if (!j.retirado || previo == null || previo.retirado) continue;
      if (j.posicion == ahora.yo) continue; // las mias se quedan, apagadas
      for (var i = 0; i < 2; i++) {
        _volar(
          VueloCarta(
            id: _proximo++,
            desde: EnMano(j.posicion, i),
            hasta: const EnDescarte(),
            duracion: _ms(420),
            desvanecer: true,
          ),
          en: _ms(i * 60),
          salida: i == 0 ? SonidoMesa.cartaSale : null,
          volumen: .45,
        );
      }
    }
  }

  /// Se cerro la ronda: lo de cada uno va al bote. Devuelve cuando llego.
  Duration _recoger(EstadoMesaPoker antes, EstadoMesaPoker ahora) {
    var hubo = false;
    for (final j in ahora.jugadores) {
      final p = j.posicion;
      final delante = antes.apuestaVisible(p);
      final puso = j.aportado - (antes.jugador(p)?.aportado ?? j.aportado);
      final total = delante + math.max<int>(0, puso);
      if (total <= 0) continue;
      hubo = true;
      _volar(
        VueloFichas(
          id: _proximo++,
          desde: delante == 0 ? EnAsiento(p) : EnApuesta(p),
          hasta: const EnBote(),
          duracion: _ms(420),
          monto: total,
        ),
        en: Duration.zero,
      );
    }
    final mano = ahora.mano!;
    if (!hubo) {
      if (!mano.enJuego) _valores[bote] = mano.bote;
      return Duration.zero;
    }
    sonar?.call(SonidoMesa.fichas, volumen: .7);
    _valores[bote] = antes.boteVisible;
    final llega = _ms(460);
    _en(llega, () {
      // Terminada, el bote espera entero hasta que se lo lleve el que gano.
      if (mano.enJuego) {
        _valores.remove(bote);
      } else {
        _valores[bote] = mano.bote;
      }
    });
    return llega + _ms(120);
  }

  /// Las cartas nuevas de la mesa. Despues del flop, cada calle se hace
  /// esperar: cuando todos fueron con todo se dan de corrido, y asi se ven.
  Duration _abrirComunitarias(int desde, EstadoMesaPoker ahora, Duration t) {
    final cartas = ahora.mano?.comunitarias ?? const <String>[];
    if (cartas.length <= desde) return t;
    for (var i = desde; i < cartas.length; i++) {
      if (i >= 3 && i > desde) t += _ms(700);
      final clave = comunitaria(i);
      _ocultos.add(clave);
      _volar(
        VueloCarta(
          id: _proximo++,
          desde: const EnMazo(),
          hasta: EnComunitaria(i),
          duracion: _ms(420),
          codigo: cartas[i],
          bocaArriba: true,
        ),
        en: t,
        salida: SonidoMesa.cartaSale,
        volumen: .6,
        margen: _ms(320),
        alTerminar: () => _ocultos.remove(clave),
      );
      _en(t + _ms(190), () => sonar?.call(SonidoMesa.voltear, volumen: .8));
      t += _ms(170);
    }
    return t + _ms(560);
  }

  /// Al final se dan vuelta las cartas de los que llegaron, de a una.
  Duration _mostrar(EstadoMesaPoker ahora, Duration t) {
    var hubo = false;
    for (final j in ahora.jugadores) {
      if (j.cartasVistas == null || j.retirado || j.posicion == ahora.yo) {
        continue;
      }
      final clave = vistas(j.posicion);
      _ocultos.add(clave);
      _en(t, () {
        _ocultos.remove(clave);
        sonar?.call(SonidoMesa.voltear);
      });
      t += _ms(240);
      hubo = true;
    }
    return hubo ? t + _ms(700) : t;
  }

  /// El bote va a quien gano. Hasta que le llega, su pila muestra lo de
  /// antes; cuando cae, se ve con que gano y cuanto.
  void _pagar(EstadoMesaPoker ahora, Duration t) {
    final pagos = ahora.mano!.resultado;
    for (final MapEntry(key: p, value: monto) in pagos.entries) {
      final clave = fichas(p);
      final pila = ahora.asiento(p)?.fichas ?? 0;
      _valores[clave] = math.max(0, pila - monto);
      _volar(
        VueloFichas(
          id: _proximo++,
          desde: const EnBote(),
          hasta: EnAsiento(p),
          duracion: _ms(720),
          monto: monto,
        ),
        en: t,
        alTerminar: () {
          _valores.remove(clave);
          sonar?.call(SonidoMesa.cobrar, volumen: .9);
          if (p == ahora.yo) {
            sonar?.call(SonidoMesa.ganar);
            alGanar?.call();
          }
        },
      );
    }
    if (pagos.isNotEmpty) _en(t, () => _valores[bote] = 0);
    _en(t + _ms(760), () {
      _ocultos.remove(resultado);
      _valores.remove(bote);
    });
  }

  void _volar(
    VueloPoker vuelo, {
    required Duration en,
    SonidoMesa? salida,
    double volumen = 1,
    Duration margen = const Duration(milliseconds: 40),
    VoidCallback? alTerminar,
  }) {
    _en(en, () {
      _vuelos.add(vuelo);
      if (salida != null) sonar?.call(salida, volumen: volumen);
    });
    _en(en + vuelo.duracion + margen, () {
      _vuelos.remove(vuelo);
      alTerminar?.call();
    });
  }

  void _en(Duration cuando, VoidCallback que) {
    late final Timer reloj;
    reloj = Timer(cuando, () {
      _relojes.remove(reloj);
      if (_cerrada) return;
      que();
      notifyListeners();
    });
    _relojes.add(reloj);
  }

  void _cortar() {
    for (final reloj in _relojes) {
      reloj.cancel();
    }
    _relojes.clear();
    _vuelos.clear();
    _ocultos.clear();
    _valores.clear();
  }

  @override
  void dispose() {
    _cerrada = true;
    _cortar();
    super.dispose();
  }

  static Duration _ms(int milisegundos) => Duration(milliseconds: milisegundos);
}
