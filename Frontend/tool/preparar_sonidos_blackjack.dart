import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Prepara los sonidos de la mesa de blackjack de MacIAs a partir de tres
/// paquetes de Kenney (kenney.nl), todos CC0 (dominio publico):
///
/// - Casino Audio: fichas y cartas grabadas de verdad.
///   https://kenney.nl/assets/casino-audio
/// - Interface Sounds: el boton, la pista y la "voz" del dialogo.
///   https://kenney.nl/assets/interface-sounds
/// - Music Jingles (los de saxo): ganar, perder, empatar, pasarse.
///   https://kenney.nl/assets/music-jingles
///
/// Uso (con ffmpeg en el PATH), desde Frontend:
///
///     dart run tool/preparar_sonidos_blackjack.dart \
///       <casino-audio>/Audio <interface-sounds>/Audio \
///       "<music-jingles>/Audio/Sax jingles"
///
/// Cada sonido se recorta para que el golpe (la ficha que cae, la carta que
/// toca la mesa) quede al principio del archivo: asi suena justo cuando la
/// animacion llega, sin el silencio que traen las grabaciones. Despues se
/// nivela el volumen y se guarda como WAV mono de 16 bits, que cualquier
/// navegador y cualquier telefono reproducen sin decodificador aparte.
Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Uso: dart run tool/preparar_sonidos_blackjack.dart '
      '<casino>/Audio <interface>/Audio "<jingles>/Audio/Sax jingles"',
    );
    exit(64);
  }
  final (casino, interfaz, saxo) = (args[0], args[1], args[2]);
  final salida = Directory('assets/audio/blackjack');
  if (salida.existsSync()) {
    for (final viejo in salida.listSync().whereType<File>()) {
      if (viejo.path.endsWith('.wav')) viejo.deleteSync();
    }
  } else {
    salida.createSync(recursive: true);
  }

  final sonidos = <_Sonido>[
    // Una ficha que cae sobre la pila.
    for (final (i, n) in [1, 2, 3].indexed)
      _Sonido('ficha_${i + 1}', '$casino/chip-lay-$n.ogg', _Corte.golpe, -17),
    // Varias fichas: un pago, doblar, dividir.
    for (final (i, n) in [1, 3, 4, 6].indexed)
      _Sonido(
        'fichas_${i + 1}',
        '$casino/chips-stack-$n.ogg',
        _Corte.golpe,
        -17,
      ),
    // Las ganancias que se juntan en tu bolsillo.
    for (final (i, n) in [1, 6].indexed)
      _Sonido(
        'cobrar_${i + 1}',
        '$casino/chips-handle-$n.ogg',
        _Corte.golpe,
        -19,
      ),
    // La carta que sale del sabot y se desliza por el paño.
    for (final (i, n) in [1, 3].indexed)
      _Sonido(
        'carta_sale_${i + 1}',
        '$casino/card-shove-$n.ogg',
        _Corte.golpe,
        -22,
      ),
    // La carta que toca la mesa.
    for (final (i, n) in [1, 2, 4].indexed)
      _Sonido(
        'carta_cae_${i + 1}',
        '$casino/card-place-$n.ogg',
        _Corte.golpe,
        -19,
      ),
    // La carta tapada que se da vuelta.
    for (final (i, n) in [2, 3].indexed)
      _Sonido(
        'voltear_${i + 1}',
        '$casino/card-slide-$n.ogg',
        _Corte.golpe,
        -19,
      ),
    // Barajar: el tramo con cuatro "riffles", lo que dura la animacion.
    _Sonido(
      'barajar',
      '$casino/card-shuffle.ogg',
      _Corte.tramo,
      -22,
      desde: .10,
      hasta: 1.55,
    ),
    _Sonido('ganar', '$saxo/jingles_SAX10.ogg', _Corte.musica, -24),
    _Sonido('blackjack', '$saxo/jingles_SAX02.ogg', _Corte.musica, -23),
    _Sonido('perder', '$saxo/jingles_SAX09.ogg', _Corte.musica, -26),
    _Sonido('pasarse', '$saxo/jingles_SAX07.ogg', _Corte.musica, -26),
    _Sonido('empate', '$saxo/jingles_SAX00.ogg', _Corte.musica, -26),
    _Sonido('boton', '$interfaz/select_002.ogg', _Corte.golpe, -24),
    _Sonido('pista', '$interfaz/glass_002.ogg', _Corte.golpe, -24),
    _Sonido('voz_1', '$interfaz/tick_001.ogg', _Corte.golpe, -26),
    _Sonido('voz_2', '$interfaz/tick_002.ogg', _Corte.golpe, -26),
  ];

  var total = 0;
  for (final sonido in sonidos) {
    final muestras = await _decodificar(sonido.fuente);
    final listo = sonido.preparar(muestras);
    final archivo = File('${salida.path}/${sonido.nombre}.wav')
      ..writeAsBytesSync(_wav(listo));
    total += archivo.lengthSync();
    stdout.writeln(
      '${sonido.nombre.padRight(14)} '
      '${(listo.length / _tasa * 1000).round().toString().padLeft(5)} ms  '
      '${(archivo.lengthSync() / 1024).toStringAsFixed(1).padLeft(6)} KB',
    );
  }
  stdout.writeln('Total: ${(total / 1024).toStringAsFixed(0)} KB');
}

/// 32 kHz: llega hasta los 16 kHz, de sobra para el clic de una ficha.
const _tasa = 32000;

enum _Corte {
  /// Empieza justo antes del golpe principal.
  golpe,

  /// Empieza donde empieza la musica.
  musica,

  /// Un tramo fijo, en segundos.
  tramo,
}

class _Sonido {
  _Sonido(
    this.nombre,
    this.fuente,
    this.corte,
    this.volumenDb, {
    this.desde = 0,
    this.hasta = 0,
  });

  final String nombre;
  final String fuente;
  final _Corte corte;

  /// El volumen de la parte que suena (RMS), en dB.
  final double volumenDb;
  final double desde;
  final double hasta;

  Float64List preparar(Float64List x) {
    var pico = 0.0;
    for (final v in x) {
      pico = math.max(pico, v.abs());
    }
    if (pico == 0) return x;
    int primeroSobre(double umbral) {
      for (var i = 0; i < x.length; i++) {
        if (x[i].abs() >= umbral) return i;
      }
      return 0;
    }

    int ultimoSobre(double umbral) {
      for (var i = x.length - 1; i >= 0; i--) {
        if (x[i].abs() >= umbral) return i;
      }
      return x.length - 1;
    }

    final int inicio;
    final int fin;
    switch (corte) {
      case _Corte.golpe:
        // El golpe es lo primero que pasa del 30 % del pico; se dejan 8 ms
        // antes para no cortarle el ataque.
        inicio = math.max(0, primeroSobre(pico * .3) - _tasa * 8 ~/ 1000);
        fin = math.min(x.length, ultimoSobre(pico * .006) + _tasa * 25 ~/ 1000);
      case _Corte.musica:
        inicio = math.max(0, primeroSobre(pico * .02) - _tasa * 3 ~/ 1000);
        fin = math.min(x.length, ultimoSobre(pico * .004) + _tasa * 40 ~/ 1000);
      case _Corte.tramo:
        inicio = (desde * _tasa).round();
        fin = math.min(x.length, (hasta * _tasa).round());
    }
    final y = Float64List.fromList(x.sublist(inicio, fin));
    // Entradas y salidas suaves: sin el "clic" de cortar una onda a la mitad.
    final entrada = _tasa * 2 ~/ 1000;
    final salida = math.min(
      y.length ~/ 3,
      _tasa * (corte == _Corte.tramo ? 90 : 20) ~/ 1000,
    );
    for (var i = 0; i < entrada && i < y.length; i++) {
      y[i] *= i / entrada;
    }
    for (var i = 0; i < salida; i++) {
      y[y.length - 1 - i] *= i / salida;
    }
    // Se nivela por lo que suena (las muestras de mas del 10 % del pico),
    // sin pasarse de -1 dB de pico.
    var suma = 0.0;
    var cuantas = 0;
    var picoY = 0.0;
    for (final v in y) {
      picoY = math.max(picoY, v.abs());
    }
    for (final v in y) {
      if (v.abs() >= picoY * .1) {
        suma += v * v;
        cuantas++;
      }
    }
    final rms = math.sqrt(suma / math.max(1, cuantas));
    final objetivo = math.pow(10, volumenDb / 20);
    final techo = math.pow(10, -1 / 20) / picoY;
    final ganancia = math.min(objetivo / rms, techo);
    for (var i = 0; i < y.length; i++) {
      y[i] *= ganancia;
    }
    return y;
  }
}

/// ffmpeg decodifica el OGG a muestras mono en coma flotante.
Future<Float64List> _decodificar(String ruta) async {
  final resultado = await Process.run('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-i',
    ruta,
    '-ac',
    '1',
    '-ar',
    '$_tasa',
    '-f',
    'f32le',
    '-',
  ], stdoutEncoding: null);
  if (resultado.exitCode != 0) {
    throw Exception('ffmpeg no pudo leer $ruta: ${resultado.stderr}');
  }
  final bytes = Uint8List.fromList(resultado.stdout as List<int>);
  final datos = ByteData.sublistView(bytes);
  final n = bytes.length ~/ 4;
  return Float64List.fromList([
    for (var i = 0; i < n; i++) datos.getFloat32(i * 4, Endian.little),
  ]);
}

Uint8List _wav(Float64List muestras) {
  final datos = ByteData(44 + muestras.length * 2);
  void texto(int en, String s) {
    for (var i = 0; i < s.length; i++) {
      datos.setUint8(en + i, s.codeUnitAt(i));
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
    ..setUint32(24, _tasa, Endian.little)
    ..setUint32(28, _tasa * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  texto(36, 'data');
  datos.setUint32(40, muestras.length * 2, Endian.little);
  for (var i = 0; i < muestras.length; i++) {
    final v = (muestras[i] * 32767).round().clamp(-32768, 32767);
    datos.setInt16(44 + i * 2, v, Endian.little);
  }
  return datos.buffer.asUint8List();
}
