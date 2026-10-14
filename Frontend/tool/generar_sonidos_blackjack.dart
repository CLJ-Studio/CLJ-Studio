// Genera los sonidos de la mesa de blackjack de MacIAs:
//
//   dart run tool/generar_sonidos_blackjack.dart
//
// Se sintetizan aca, muestra por muestra, en vez de bajarlos de internet: asi
// no hay licencias de por medio, y cada sonido dura justo lo que su
// animacion. Una ficha es un "clac" de arcilla (ruido filtrado y tres
// resonancias que se apagan rapido); una carta, un soplido de ruido que barre
// de grave a agudo y un golpecito sordo al caer sobre el paño; los premios,
// campanitas en acordes mayores. Salen en WAV de 24 kHz, mono, 16 bits: lo
// lee cualquier telefono y cualquier navegador.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _frecuencia = 24000;
const _carpeta = 'assets/audio/blackjack';

void main() {
  Directory(_carpeta).createSync(recursive: true);
  final azar = Random(21);
  final sonidos = <String, List<double>>{
    'ficha_1': _ficha(azar, 1),
    'ficha_2': _ficha(azar, 1.07),
    'fichas': _fichas(azar),
    'carta_sale_1': _cartaSale(azar, 1),
    'carta_sale_2': _cartaSale(azar, 1.12),
    'carta_cae': _cartaCae(azar),
    'voltear': _voltear(azar),
    'barajar': _barajar(azar),
    'ganar': _ganar(),
    'blackjack': _blackjack(azar),
    'perder': _perder(),
    'empate': _empate(),
    'pasarse': _pasarse(azar),
    'cobrar': _cobrar(azar),
    'boton': _boton(azar),
    'pista': _pista(azar),
    'voz_1': _voz(300),
    'voz_2': _voz(336),
    'voz_3': _voz(372),
  };
  for (final MapEntry(key: nombre, value: muestras) in sonidos.entries) {
    final archivo = File('$_carpeta/$nombre.wav')
      ..writeAsBytesSync(_wav(muestras));
    stdout.writeln('${archivo.path}: ${archivo.lengthSync()} bytes');
  }
}

// ------------------------------------------------------------------ piezas
List<double> _vacio(double segundos) =>
    List.filled((segundos * _frecuencia).round(), 0);

/// Suma [sonido] en [base] desde [segundo], con [ganancia].
void _sumar(
  List<double> base,
  List<double> sonido,
  double segundo, [
  double ganancia = 1,
]) {
  final desde = (segundo * _frecuencia).round();
  for (var i = 0; i < sonido.length && desde + i < base.length; i++) {
    if (desde + i >= 0) base[desde + i] += sonido[i] * ganancia;
  }
}

/// Lleva el pico a [pico], para que todos suenen parejo y nada sature.
List<double> _normalizar(List<double> muestras, double pico) {
  final maximo = muestras.fold(0.0, (m, v) => max(m, v.abs()));
  if (maximo == 0) return muestras;
  return [for (final v in muestras) v / maximo * pico];
}

/// Un filtro de segundo orden (las recetas de Robert Bristow-Johnson).
class _Filtro {
  _Filtro._(double f, double q, int tipo) {
    final w0 = 2 * pi * f / _frecuencia;
    final alfa = sin(w0) / (2 * q);
    final c = cos(w0);
    final (n0, n1, n2) = switch (tipo) {
      0 => (alfa, 0.0, -alfa), // pasabanda
      1 => ((1 - c) / 2, 1 - c, (1 - c) / 2), // pasabajos
      _ => ((1 + c) / 2, -(1 + c), (1 + c) / 2), // pasaaltos
    };
    final a0 = 1 + alfa;
    _b0 = n0 / a0;
    _b1 = n1 / a0;
    _b2 = n2 / a0;
    _a1 = -2 * c / a0;
    _a2 = (1 - alfa) / a0;
  }

  factory _Filtro.banda(double f, double q) => _Filtro._(f, q, 0);
  factory _Filtro.bajos(double f, [double q = .707]) => _Filtro._(f, q, 1);
  factory _Filtro.altos(double f, [double q = .707]) => _Filtro._(f, q, 2);

  late final double _b0, _b1, _b2, _a1, _a2;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  double pasar(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}

double _ruido(Random azar) => azar.nextDouble() * 2 - 1;

/// Una nota de campana: la fundamental y dos parciales que se apagan antes.
List<double> _campana(
  double f,
  double duracion, {
  double caida = .25,
  double inarmonico = 2.0,
}) {
  final n = (duracion * _frecuencia).round();
  return [
    for (var i = 0; i < n; i++)
      () {
        final t = i / _frecuencia;
        final ataque = min(1.0, t / .004);
        return ataque *
            (sin(2 * pi * f * t) * exp(-t / caida) +
                .35 *
                    sin(2 * pi * f * inarmonico * t) *
                    exp(-t / (caida * .6)) +
                .12 * sin(2 * pi * f * 3 * t) * exp(-t / (caida * .4)));
      }(),
  ];
}

/// Un eco suave, como el de un salon.
List<double> _eco(List<double> seca, double retardo, double cuanto) {
  final salida = [...seca, ..._vacio(retardo * 2)];
  final d = (retardo * _frecuencia).round();
  for (var i = d; i < salida.length; i++) {
    salida[i] += salida[i - d] * cuanto;
  }
  return salida;
}

// ----------------------------------------------------------------- fichas
/// Un "clac" de dos fichas de arcilla que chocan.
List<double> _clac(Random azar, double brillo, double fuerza) {
  final n = (.07 * _frecuencia).round();
  final filtro = _Filtro.banda(3900 * brillo, 1.3);
  final modos = [
    (2950 * brillo * (1 + (azar.nextDouble() - .5) * .04), .55, .012),
    (4380 * brillo * (1 + (azar.nextDouble() - .5) * .04), .38, .009),
    (6150 * brillo * (1 + (azar.nextDouble() - .5) * .04), .22, .006),
    (1650 * brillo, .2, .014),
  ];
  return [
    for (var i = 0; i < n; i++)
      () {
        final t = i / _frecuencia;
        var v = filtro.pasar(_ruido(azar)) * exp(-t / .0022) * 1.4;
        for (final (f, a, caida) in modos) {
          v += a * sin(2 * pi * f * t) * exp(-t / caida);
        }
        return v * fuerza;
      }(),
  ];
}

List<double> _ficha(Random azar, double brillo) {
  final salida = _vacio(.17);
  _sumar(salida, _clac(azar, brillo, 1), 0);
  _sumar(salida, _clac(azar, brillo * 1.05, .5), .041);
  return _normalizar(salida, .85);
}

/// Varias fichas que se apilan.
List<double> _fichas(Random azar) {
  final salida = _vacio(.42);
  var t = 0.0;
  for (var i = 0; i < 6; i++) {
    _sumar(
      salida,
      _clac(azar, .94 + azar.nextDouble() * .14, .45 + azar.nextDouble() * .5),
      t,
    );
    t += .028 + azar.nextDouble() * .03;
  }
  return _normalizar(salida, .8);
}

// ------------------------------------------------------------------ cartas
/// La carta que sale del sabot: un soplido que barre de grave a agudo.
List<double> _cartaSale(Random azar, double tono) {
  const duracion = .2;
  final n = (duracion * _frecuencia).round();
  final altos = _Filtro.altos(500);
  final salida = <double>[];
  var filtro = _Filtro.banda(1400 * tono, .9);
  for (var i = 0; i < n; i++) {
    final t = i / _frecuencia;
    if (i % 48 == 0) {
      // El barrido: se recalcula el filtro cada dos milisegundos.
      final avance = t / duracion;
      filtro = _Filtro.banda((1400 + 2600 * avance) * tono, .9)
        .._x1 = filtro._x1
        .._x2 = filtro._x2
        .._y1 = filtro._y1
        .._y2 = filtro._y2;
    }
    final subida = sin(min(1.0, t / .035) * pi / 2);
    final bajada = pow(1 - t / duracion, 1.6).toDouble();
    salida.add(altos.pasar(filtro.pasar(_ruido(azar))) * subida * bajada);
  }
  return _normalizar(salida, .5);
}

/// La carta que cae sobre el paño: un golpecito sordo.
List<double> _cartaCae(Random azar) {
  final n = (.1 * _frecuencia).round();
  final bajos = _Filtro.bajos(1800);
  final papel = _Filtro.banda(5200, 1.5);
  return _normalizar([
    for (var i = 0; i < n; i++)
      () {
        final t = i / _frecuencia;
        return .5 * sin(2 * pi * 160 * t) * exp(-t / .018) +
            .55 * bajos.pasar(_ruido(azar)) * exp(-t / .006) +
            .15 * papel.pasar(_ruido(azar)) * exp(-t / .0015);
      }(),
  ], .6);
}

/// El volteo de la carta tapada del crupier.
List<double> _voltear(Random azar) {
  final salida = _vacio(.17);
  final filtro = _Filtro.banda(4500, 1.4);
  final golpe = [
    for (var i = 0; i < (.05 * _frecuencia).round(); i++)
      () {
        final t = i / _frecuencia;
        return .7 *
                filtro.pasar(_ruido(azar)) *
                min(1.0, t / .002) *
                exp(-t / .008) +
            .3 * sin(2 * pi * 2600 * t) * exp(-t / .003);
      }(),
  ];
  _sumar(salida, golpe, 0);
  _sumar(salida, _cartaCae(azar), .045, .45);
  return _normalizar(salida, .65);
}

/// La barajada: el repiqueteo de dos mitades que se intercalan y el puente.
List<double> _barajar(Random azar) {
  final salida = _vacio(1.45);
  final filtro = _Filtro.banda(3500, 1.2);
  // El repiqueteo: rapido en el medio, mas lento al empezar y al terminar.
  var t = .05;
  while (t < .95) {
    final avance = (t - .05) / .9;
    final envolvente = sin(avance * pi);
    final golpe = [
      for (var i = 0; i < (.004 * _frecuencia).round(); i++)
        filtro.pasar(_ruido(azar)) * exp(-i / _frecuencia / .0012),
    ];
    _sumar(
      salida,
      golpe,
      t,
      (.4 + azar.nextDouble() * .5) * (.35 + .65 * envolvente),
    );
    t += .022 - .013 * envolvente + azar.nextDouble() * .004;
  }
  // El roce de fondo.
  final fondo = _Filtro.banda(2200, .6);
  for (var i = 0; i < (.95 * _frecuencia).round(); i++) {
    final s = i / _frecuencia;
    salida[i] += .12 * fondo.pasar(_ruido(azar)) * sin(min(1.0, s / .95) * pi);
  }
  // El puente: las cartas caen en cascada.
  final puente = _Filtro.banda(2500, .8);
  for (var i = 0; i < (.32 * _frecuencia).round(); i++) {
    final s = i / _frecuencia;
    final j = (1.0 * _frecuencia).round() + i;
    if (j < salida.length) {
      salida[j] += .4 * puente.pasar(_ruido(azar)) * sin(s / .32 * pi);
    }
  }
  _sumar(salida, _cartaCae(azar), 1.33, .6);
  return _normalizar(salida, .8);
}

// ---------------------------------------------------------------- premios
const _do5 = 523.25, _mi5 = 659.25, _sol5 = 783.99, _do6 = 1046.5;

List<double> _ganar() {
  final salida = _vacio(.95);
  for (final (i, f) in [_do5, _mi5, _sol5, _do6].indexed) {
    _sumar(salida, _campana(f, .7, caida: i == 3 ? .45 : .22), i * .085, .8);
  }
  return _normalizar(_eco(salida, .11, .28), .62);
}

List<double> _blackjack(Random azar) {
  final salida = _vacio(1.6);
  for (final (i, f) in [392.0, _do5, _mi5, _sol5, _do6, 1318.5].indexed) {
    _sumar(salida, _campana(f, .8, caida: .35), i * .045, .7);
  }
  // El acorde final, con un temblor de alegria.
  final acorde = _vacio(1.2);
  for (var i = 0; i < acorde.length; i++) {
    final t = i / _frecuencia;
    final temblor = 1 + .15 * sin(2 * pi * 6 * t);
    var v = 0.0;
    for (final f in [_do5, _mi5, _sol5, _do6]) {
      v += sin(2 * pi * f * t) + .25 * sin(4 * pi * f * t);
    }
    acorde[i] = v * temblor * min(1.0, t / .01) * exp(-t / .7) * .3;
  }
  _sumar(salida, acorde, .28);
  // Los brillitos.
  for (var k = 0; k < 14; k++) {
    final f = 2500 + azar.nextDouble() * 2700;
    _sumar(
      salida,
      [
        for (var i = 0; i < (.12 * _frecuencia).round(); i++)
          sin(2 * pi * f * i / _frecuencia) * exp(-i / _frecuencia / .05),
      ],
      .3 + azar.nextDouble(),
      .12 + azar.nextDouble() * .1,
    );
  }
  return _normalizar(_eco(salida, .12, .25), .7);
}

/// Perder: dos notas que bajan, sin dramatismo.
List<double> _perder() {
  final salida = _vacio(.8);
  final bajos = _Filtro.bajos(1800);
  final notas = [
    (329.63, 0.0, .22, .18, 329.63),
    (261.63, .22, .5, .32, 238.0),
  ];
  for (final (desde, inicio, duracion, caida, hasta) in notas) {
    var fase = 0.0;
    final nota = <double>[];
    for (var i = 0; i < (duracion * _frecuencia).round(); i++) {
      final t = i / _frecuencia;
      final f = desde + (hasta - desde) * (t / duracion);
      fase += 2 * pi * f / _frecuencia;
      nota.add(
        (sin(fase) + .25 * sin(3 * fase)) * min(1.0, t / .01) * exp(-t / caida),
      );
    }
    _sumar(salida, nota, inicio);
  }
  return _normalizar([for (final v in salida) bajos.pasar(v)], .45);
}

List<double> _empate() {
  final salida = _vacio(.6);
  _sumar(salida, _campana(880, .45, caida: .25, inarmonico: 2.76), 0);
  _sumar(salida, _campana(880, .45, caida: .25, inarmonico: 2.76), .12, .8);
  return _normalizar(salida, .45);
}

/// Pasarse: un golpe sordo y un tono que se cae.
List<double> _pasarse(Random azar) {
  final salida = _vacio(.7);
  final bajos = _Filtro.bajos(900);
  _sumar(salida, [
    for (var i = 0; i < (.2 * _frecuencia).round(); i++)
      () {
        final t = i / _frecuencia;
        return .6 * sin(2 * pi * 120 * t) * exp(-t / .07) +
            .4 * bajos.pasar(_ruido(azar)) * exp(-t / .015);
      }(),
  ], 0);
  var fase = 0.0;
  final caida = <double>[];
  for (var i = 0; i < (.5 * _frecuencia).round(); i++) {
    final t = i / _frecuencia;
    fase += 2 * pi * (420 - 250 * (t / .5)) / _frecuencia;
    caida.add(
      (sin(fase) + .2 * sin(3 * fase)) * min(1.0, t / .01) * exp(-t / .25),
    );
  }
  _sumar(salida, caida, .06, .7);
  return _normalizar(salida, .5);
}

/// Las fichas que vuelven a tu bolsillo: clac, clac y una campanita.
List<double> _cobrar(Random azar) {
  final salida = _vacio(.75);
  for (final (i, t) in [0.0, .05, .09, .14, .17].indexed) {
    _sumar(
      salida,
      _clac(azar, .95 + azar.nextDouble() * .12, 1),
      t,
      .5 + .1 * i,
    );
  }
  _sumar(salida, _campana(1318.5, .5, caida: .3), .2, .35);
  _sumar(salida, _campana(1975.5, .5, caida: .3), .2, .25);
  _sumar(salida, _campana(1568, .45, caida: .28), .3, .3);
  return _normalizar(salida, .7);
}

List<double> _boton(Random azar) {
  final altos = _Filtro.altos(3000);
  return _normalizar([
    for (var i = 0; i < (.05 * _frecuencia).round(); i++)
      () {
        final t = i / _frecuencia;
        return .5 * sin(2 * pi * 1200 * t) * exp(-t / .006) +
            .2 * altos.pasar(_ruido(azar)) * exp(-t / .001);
      }(),
  ], .35);
}

/// La pista de MacIAs: una escalita magica.
List<double> _pista(Random azar) {
  final salida = _vacio(.7);
  for (final (i, f) in [1318.5, 1760.0, 2349.3].indexed) {
    _sumar(salida, _campana(f, .5, caida: .2), i * .07, .6);
  }
  for (var k = 0; k < 6; k++) {
    final f = 3000 + azar.nextDouble() * 2000;
    _sumar(
      salida,
      [
        for (var i = 0; i < (.08 * _frecuencia).round(); i++)
          sin(2 * pi * f * i / _frecuencia) * exp(-i / _frecuencia / .03),
      ],
      .12 + azar.nextDouble() * .3,
      .15,
    );
  }
  return _normalizar(salida, .4);
}

/// La voz de MacIAs en la caja de dialogo: un "bip" cortito por letra.
List<double> _voz(double tono) {
  final bajos = _Filtro.bajos(1600);
  var fase = 0.0;
  return _normalizar([
    for (var i = 0; i < (.065 * _frecuencia).round(); i++)
      () {
        final t = i / _frecuencia;
        fase += 2 * pi * tono * (1 - .12 * min(1.0, t / .05)) / _frecuencia;
        final v = sin(fase) + .3 * sin(2 * fase) + .1 * sin(3 * fase);
        return bajos.pasar(v * min(1.0, t / .004) * exp(-t / .022));
      }(),
  ], .3);
}

// -------------------------------------------------------------------- WAV
Uint8List _wav(List<double> muestras) {
  final datos = ByteData(44 + muestras.length * 2);
  void texto(int desde, String s) {
    for (var i = 0; i < s.length; i++) {
      datos.setUint8(desde + i, s.codeUnitAt(i));
    }
  }

  texto(0, 'RIFF');
  datos.setUint32(4, 36 + muestras.length * 2, Endian.little);
  texto(8, 'WAVE');
  texto(12, 'fmt ');
  datos
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, _frecuencia, Endian.little)
    ..setUint32(28, _frecuencia * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  texto(36, 'data');
  datos.setUint32(40, muestras.length * 2, Endian.little);
  for (final (i, v) in muestras.indexed) {
    datos.setInt16(
      44 + i * 2,
      (v.clamp(-1.0, 1.0) * 32767).round(),
      Endian.little,
    );
  }
  return datos.buffer.asUint8List();
}
