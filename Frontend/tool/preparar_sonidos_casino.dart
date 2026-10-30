import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Prepara los sonidos del casino de MacIAs (el blackjack, la ruleta y la
/// pesca en el hielo), todos grabaciones CC0 (dominio publico):
///
/// - Casino Audio, de Kenney: fichas y cartas.
///   https://kenney.nl/assets/casino-audio
/// - Interface Sounds, de Kenney: el boton, la pista, la "voz" del dialogo y
///   la aguja de la rueda de la pesca. https://kenney.nl/assets/interface-sounds
/// - Music Jingles (los de saxo), de Kenney: ganar, perder, empatar,
///   pasarse. https://kenney.nl/assets/music-jingles
/// - Impact Sounds, de Kenney: la bola de nieve que cae (pisadas en nieve).
///   https://kenney.nl/assets/impact-sounds
/// - De Freesound (la vista previa "hq" de cada uno, con el nombre que va
///   entre parentesis):
///   - La bola de la ruleta: una canica girando en un bowl de ceramica, de
///     Anthousai (freesound.org/s/448345, canica_gira.mp3), y canicas
///     cayendo sobre madera, de KaleidacousticsAudio (freesound.org/s/628994,
///     canicas_madera.mp3).
///   - La pesca: hielo que se quiebra, de thatonecode (freesound.org/s/755506,
///     hielo_quiebra.mp3); una moneda que gira hasta caer, de jon.k.clancy
///     (freesound.org/s/402934, moneda_gira.mp3); la matraca de un carrete
///     de mosca, de paulprit (freesound.org/s/507078, carrete.mp3); un pez
///     que se suelta salpicando, de paulprit (freesound.org/s/507094,
///     pez_salta.mp3), y burbujas en el agua, de ristooooo1
///     (freesound.org/s/539823, burbujas.mp3).
///   - Los equipos del bono de la pesca: un camion que acelera, de
///     jodybruchon (freesound.org/s/433866, camion.mp3); un helicoptero, de
///     Wonko_7 (freesound.org/s/723158, helicoptero.mp3); los pasos de un
///     robot gigante, de Breviceps (freesound.org/s/557594,
///     robot_pasos.mp3), y un trago fuerte, de magnuswaker
///     (freesound.org/s/531755, trago.mp3).
///
/// Uso (con ffmpeg en el PATH), desde Frontend:
///
///     dart run tool/preparar_sonidos_casino.dart \
///       <casino-audio>/Audio <interface-sounds>/Audio \
///       "<music-jingles>/Audio/Sax jingles" <impact-sounds>/Audio \
///       <carpeta de Freesound>
///
/// Cada sonido se recorta para que el golpe (la ficha que cae, la carta que
/// toca la mesa) quede al principio del archivo: asi suena justo cuando la
/// animacion llega, sin el silencio que traen las grabaciones. Despues se
/// nivela el volumen y se guarda como WAV mono de 16 bits, que cualquier
/// navegador y cualquier telefono reproducen sin decodificador aparte.
///
/// La "voz" de MacIAs (el murmullo mientras escribe) se arma con los mismos
/// tics de Interface Sounds, pero todos juntos en un solo archivo por frase.
/// Antes sonaba un tic suelto por cada tres letras (unos 13 por segundo): en
/// Android cada sonido corto es una pista de audio nueva, y el mezclador del
/// telefono no daba abasto y cortaba todo lo demas.
Future<void> main(List<String> args) async {
  if (args.length != 5) {
    stderr.writeln(
      'Uso: dart run tool/preparar_sonidos_casino.dart '
      '<casino>/Audio <interface>/Audio "<jingles>/Audio/Sax jingles" '
      '<impact>/Audio <freesound>',
    );
    exit(64);
  }
  final (casino, interfaz, saxo, impacto, freesound) = (
    args[0],
    args[1],
    args[2],
    args[3],
    args[4],
  );
  final salida = Directory('assets/audio/casino');
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
    _Sonido(
      'ganar',
      '$saxo/jingles_SAX10.ogg',
      _Corte.musica,
      -20,
      techoDb: -10,
    ),
    _Sonido(
      'blackjack',
      '$saxo/jingles_SAX02.ogg',
      _Corte.musica,
      -19,
      techoDb: -10,
    ),
    _Sonido(
      'perder',
      '$saxo/jingles_SAX09.ogg',
      _Corte.musica,
      -22,
      techoDb: -10,
    ),
    _Sonido(
      'pasarse',
      '$saxo/jingles_SAX07.ogg',
      _Corte.musica,
      -22,
      techoDb: -10,
    ),
    _Sonido(
      'empate',
      '$saxo/jingles_SAX00.ogg',
      _Corte.musica,
      -22,
      techoDb: -10,
    ),
    _Sonido('boton', '$interfaz/select_002.ogg', _Corte.golpe, -24),
    _Sonido('pista', '$interfaz/glass_002.ogg', _Corte.golpe, -24),
    // La bola de la ruleta rodando por el carril: se apaga despacio, como
    // la bola que pierde velocidad.
    _Sonido(
      'bola_rueda',
      '$freesound/canica_gira.mp3',
      _Corte.tramo,
      -25,
      desde: 0,
      hasta: 5.6,
      salidaMs: 1400,
    ),
    // El golpe contra un rombo del cilindro, al caer del carril.
    _Sonido(
      'bola_golpe',
      '$freesound/canicas_madera.mp3',
      _Corte.tramo,
      -18,
      desde: 2.182,
      hasta: 2.34,
    ),
    // Cada rebote entre las casillas: uno por salto de la animacion.
    for (final (i, (desde, hasta)) in const [
      (1.607, 1.70),
      (2.867, 2.99),
      (3.602, 3.74),
      (4.343, 4.47),
    ].indexed)
      _Sonido(
        'bola_toc_${i + 1}',
        '$freesound/canicas_madera.mp3',
        _Corte.tramo,
        -20,
        desde: desde,
        hasta: hasta,
      ),
    // La aguja de la rueda de la pesca contra cada clavija, cuando ya va
    // despacio: los dos chasquidos de una tecla (al bajar y al subir).
    for (final (i, (desde, hasta)) in const [(0.0, .075), (.1, .175)].indexed)
      _Sonido(
        'aguja_${i + 1}',
        '$interfaz/switch_004.ogg',
        _Corte.tramo,
        -20,
        desde: desde,
        hasta: hasta,
      ),
    // La bola de nieve que cae sobre la rueda.
    for (final (i, n) in [0, 1, 4].indexed)
      _Sonido(
        'nieve_${i + 1}',
        '$impacto/footstep_snow_00$n.ogg',
        _Corte.golpe,
        -19,
      ),
    // El hielo que se congela en un cubo: la seguidilla de crujidos.
    _Sonido(
      'hielo',
      '$freesound/hielo_quiebra.mp3',
      _Corte.tramo,
      -21,
      desde: .28,
      hasta: 1.02,
    ),
    // La moneda de oro: el final del giro, hasta que cae de cara.
    _Sonido(
      'moneda',
      '$freesound/moneda_gira.mp3',
      _Corte.tramo,
      -22,
      desde: 4.92,
      hasta: 6.8,
    ),
    // El carrete recoge un tramo por cada paso del medidor del bono: unos
    // seis golpes de la matraca.
    for (final (i, (desde, hasta)) in const [(1.0, 1.38), (2.4, 2.78)].indexed)
      _Sonido(
        'carrete_${i + 1}',
        '$freesound/carrete.mp3',
        _Corte.tramo,
        -22,
        desde: desde,
        hasta: hasta,
      ),
    // El pez que sale del agua (y la casilla que se hunde en el hoyo).
    _Sonido(
      'chapuzon',
      '$freesound/pez_salta.mp3',
      _Corte.tramo,
      -18,
      desde: 1.12,
      hasta: 1.86,
    ),
    // La grua que llega: el camion que acelera.
    _Sonido(
      'grua',
      '$freesound/camion.mp3',
      _Corte.tramo,
      -22,
      desde: 2.08,
      hasta: 3.7,
      salidaMs: 400,
    ),
    // El helicoptero (y el de carga) que llega volando.
    _Sonido(
      'helicoptero',
      '$freesound/helicoptero.mp3',
      _Corte.tramo,
      -22,
      desde: .15,
      hasta: 1.85,
      salidaMs: 500,
    ),
    // El robot que sale del hielo: un paso pesado y sus motores.
    _Sonido(
      'robot',
      '$freesound/robot_pasos.mp3',
      _Corte.tramo,
      -19,
      desde: .05,
      hasta: 1.33,
      salidaMs: 150,
    ),
    // El gigante que se traga al chico.
    _Sonido('trago', '$freesound/trago.mp3', _Corte.golpe, -17),
    // Bajo el hielo, cuando aparece el cardumen.
    _Sonido(
      'burbujas',
      '$freesound/burbujas.mp3',
      _Corte.tramo,
      -24,
      desde: 1.22,
      hasta: 2.92,
    ),
  ];

  var total = 0;
  void anotar(String nombre, int muestras, int bytes) {
    total += bytes;
    stdout.writeln(
      '${nombre.padRight(14)} '
      '${(muestras / _tasa * 1000).round().toString().padLeft(5)} ms  '
      '${(bytes / 1024).toStringAsFixed(1).padLeft(6)} KB',
    );
  }

  for (final sonido in sonidos) {
    final muestras = await _decodificar(sonido.fuente);
    final listo = sonido.preparar(muestras);
    final archivo = File('${salida.path}/${sonido.nombre}.wav')
      ..writeAsBytesSync(_wav(listo));
    anotar(sonido.nombre, listo.length, archivo.lengthSync());
  }

  // La voz de MacIAs: un murmullo por frase, de tres largos (ver
  // VozCrupier). Salen de los tics de siempre, a 16 kHz: son suaves y no
  // necesitan mas.
  final tics = <Float64List>[];
  for (final nombre in ['tick_001', 'tick_002', 'tick_004']) {
    final tic = _Sonido(
      nombre,
      '$interfaz/$nombre.ogg',
      _Corte.golpe,
      -26,
    ).preparar(await _decodificar('$interfaz/$nombre.ogg'));
    var pico = 0.0;
    for (final v in tic) {
      pico = math.max(pico, v.abs());
    }
    tics.add(Float64List.fromList([for (final v in tic) v / pico]));
  }
  for (final (nombre, segundos, semilla) in const [
    ('voz_corta', 1.1, 11),
    ('voz_media', 2.0, 22),
    ('voz_larga', 3.2, 33),
  ]) {
    final murmullo = _murmullo(tics, segundos, semilla);
    final temporal = File('${salida.path}/$nombre.32k.wav')
      ..writeAsBytesSync(_wav(murmullo));
    final destino = '${salida.path}/$nombre.wav';
    final conversion = await Process.run('ffmpeg', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-i',
      temporal.path,
      '-ar',
      '16000',
      '-ac',
      '1',
      '-c:a',
      'pcm_s16le',
      destino,
    ]);
    temporal.deleteSync();
    if (conversion.exitCode != 0) {
      throw Exception('ffmpeg no pudo convertir $nombre: ${conversion.stderr}');
    }
    anotar(nombre, murmullo.length, File(destino).lengthSync());
  }
  // La rueda de la pesca arrancando: los mismos chasquidos de la aguja,
  // tan seguidos que suenan como una tanda.
  final clics = [
    for (final (desde, hasta) in const [(0.0, .075), (.1, .175)])
      _Sonido(
        'clic',
        '$interfaz/switch_004.ogg',
        _Corte.tramo,
        -20,
        desde: desde,
        hasta: hasta,
      ).preparar(await _decodificar('$interfaz/switch_004.ogg')),
  ];
  final tanda = _repiqueteo(clics);
  final temporal = File('${salida.path}/rueda_gira.32k.wav')
    ..writeAsBytesSync(_wav(tanda));
  final destino = '${salida.path}/rueda_gira.wav';
  final conversion = await Process.run('ffmpeg', [
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-i',
    temporal.path,
    '-ar',
    '16000',
    '-ac',
    '1',
    '-c:a',
    'pcm_s16le',
    destino,
  ]);
  temporal.deleteSync();
  if (conversion.exitCode != 0) {
    throw Exception(
      'ffmpeg no pudo convertir rueda_gira: ${conversion.stderr}',
    );
  }
  anotar('rueda_gira', tanda.length, File(destino).lengthSync());
  stdout.writeln('Total: ${(total / 1024).toStringAsFixed(0)} KB');
}

/// La aguja de la pesca golpeando cada clavija mientras la rueda frena,
/// con el mismo frenado de la pantalla (ver _Giro en pantalla_pesca.dart):
/// unas tres vueltas (159 casillas) en 7,4 segundos, hasta los 5,3
/// segundos, cuando ya pasan menos de 7 casillas por segundo y cada golpe
/// suena aparte. Al principio la aguja casi no llega a volver y golpea mas
/// suave; cada golpe con su tono y su fuerza, como el murmullo.
Float64List _repiqueteo(List<Float64List> clics) {
  const dura = 7.4;
  const casillas = 159;
  const hasta = 5.3;
  final azar = math.Random(53);
  final salida = Float64List(((hasta + .15) * _tasa).round());
  for (var k = 1; k < casillas; k++) {
    final t = (1 - math.pow(1 - k / casillas, 1 / 3).toDouble()) * dura;
    if (t > hasta) break;
    final clic = clics[k % clics.length];
    final tono = .94 + .12 * azar.nextDouble();
    final fuerza = (.4 + .6 * t / hasta) * (.85 + .15 * azar.nextDouble());
    final desde = (t * _tasa).round();
    for (var j = 0; desde + j < salida.length; j++) {
      final pos = j * tono;
      final i0 = pos.floor();
      if (i0 + 1 >= clic.length) break;
      final f = pos - i0;
      salida[desde + j] += fuerza * (clic[i0] * (1 - f) + clic[i0 + 1] * f);
    }
  }
  var pico = 0.0;
  for (final v in salida) {
    pico = math.max(pico, v.abs());
  }
  final ganancia = math.pow(10, -10 / 20) / pico;
  final entrada = _tasa * 3 ~/ 1000;
  final fin = _tasa * 120 ~/ 1000;
  for (var i = 0; i < salida.length; i++) {
    var g = ganancia.toDouble();
    if (i < entrada) g *= i / entrada;
    final restante = salida.length - 1 - i;
    if (restante < fin) g *= restante / fin;
    salida[i] *= g;
  }
  return salida;
}

/// Un murmullo de [segundos]: tics de [tics] cada ~84 ms (como una letra de
/// cada tres, a 28 ms por letra), cada uno con su tono y su fuerza, y alguno
/// que falta, como los espacios. El pico queda en -18 dB: al volumen de la
/// voz es apenas un cuchicheo de fondo.
Float64List _murmullo(List<Float64List> tics, double segundos, int semilla) {
  final azar = math.Random(semilla);
  final salida = Float64List((segundos * _tasa).round());
  var t = .03;
  while (t < segundos - .12) {
    if (azar.nextDouble() < .86) {
      final tic = tics[azar.nextInt(tics.length)];
      // El tono se cambia remuestreando: entre un poco mas grave y un poco
      // mas agudo.
      final tono = .88 + .26 * azar.nextDouble();
      final fuerza = .6 + .4 * azar.nextDouble();
      final desde = (t * _tasa).round();
      for (var j = 0; desde + j < salida.length; j++) {
        final pos = j * tono;
        final i0 = pos.floor();
        if (i0 + 1 >= tic.length) break;
        final f = pos - i0;
        salida[desde + j] += fuerza * (tic[i0] * (1 - f) + tic[i0 + 1] * f);
      }
    }
    t += .084 + (azar.nextDouble() - .5) * .03;
  }
  var pico = 0.0;
  for (final v in salida) {
    pico = math.max(pico, v.abs());
  }
  final ganancia = math.pow(10, -18 / 20) / pico;
  final entrada = _tasa * 4 ~/ 1000;
  final fin = _tasa * 80 ~/ 1000;
  for (var i = 0; i < salida.length; i++) {
    var g = ganancia.toDouble();
    if (i < entrada) g *= i / entrada;
    final restante = salida.length - 1 - i;
    if (restante < fin) g *= restante / fin;
    salida[i] *= g;
  }
  return salida;
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
    this.salidaMs,
    this.techoDb = -8,
  });

  final String nombre;
  final String fuente;
  final _Corte corte;

  /// El volumen de la parte que suena (RMS), en dB.
  final double volumenDb;
  final double desde;
  final double hasta;

  /// Cuanto dura el final que se apaga, si no es el de siempre.
  final int? salidaMs;

  /// El pico mas alto que se deja, en dB. Varios sonidos suenan a la vez
  /// (fichas, cartas, voz) y se suman: si cada uno llegara casi a 0 dB, el
  /// telefono saturaria y sonaria roto.
  final double techoDb;

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
    final salida = salidaMs != null
        ? math.min(y.length, _tasa * salidaMs! ~/ 1000)
        : math.min(
            y.length ~/ 3,
            _tasa * (corte == _Corte.tramo ? 90 : 20) ~/ 1000,
          );
    for (var i = 0; i < entrada && i < y.length; i++) {
      y[i] *= i / entrada;
    }
    // Una salida larga baja como una curva (la de la bola que frena); una
    // corta, en linea recta.
    for (var i = 0; i < salida; i++) {
      final t = i / salida;
      y[y.length - 1 - i] *= salidaMs != null ? t * t : t;
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
    final techo = math.pow(10, techoDb / 20) / picoY;
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
