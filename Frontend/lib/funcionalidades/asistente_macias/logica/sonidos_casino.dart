import 'sonidos_casino_movil.dart'
    if (dart.library.js_interop) 'sonidos_casino_web.dart'
    as plataforma;

/// Los sonidos del casino de MacIAs: fichas, cartas y la bola de la ruleta,
/// todos grabados de verdad (CC0). Se preparan con
/// `tool/preparar_sonidos_casino.dart`.
enum SonidoMesa {
  ficha(['ficha_1', 'ficha_2', 'ficha_3'], copias: 2, separacionMs: 45),
  fichas(
    ['fichas_1', 'fichas_2', 'fichas_3', 'fichas_4'],
    copias: 1,
    separacionMs: 80,
  ),
  cartaSale(['carta_sale_1', 'carta_sale_2'], copias: 2, separacionMs: 70),
  cartaCae(
    ['carta_cae_1', 'carta_cae_2', 'carta_cae_3'],
    copias: 2,
    separacionMs: 70,
  ),
  voltear(['voltear_1', 'voltear_2'], separacionMs: 150),
  barajar(['barajar']),
  ganar(['ganar']),
  blackjack(['blackjack']),
  perder(['perder']),
  empate(['empate']),
  pasarse(['pasarse']),
  cobrar(['cobrar_1', 'cobrar_2'], separacionMs: 120),
  boton(['boton'], separacionMs: 90),
  pista(['pista'], separacionMs: 200),

  /// La voz de MacIAs, en tres largos: ver [VozCrupier].
  vozCorta(['voz_corta']),
  vozMedia(['voz_media']),
  vozLarga(['voz_larga']),
  bolaRueda(['bola_rueda']),
  bolaGolpe(['bola_golpe']),
  bolaToc([
    'bola_toc_1',
    'bola_toc_2',
    'bola_toc_3',
    'bola_toc_4',
  ], separacionMs: 70);

  const SonidoMesa(this.archivos, {this.copias = 1, this.separacionMs = 0});

  /// Las variantes: cada vez suena una, para que no sea siempre igual.
  final List<String> archivos;

  /// Cuantas veces puede sonar al mismo tiempo cada variante (en el
  /// telefono; en la web no hay limite).
  final int copias;

  /// Lo minimo que pasa entre dos veces que suena. Una rafaga (diez fichas
  /// que caen juntas) suena como una sola tanda, no como diez sonidos
  /// pegados: en Android cada sonido es una pista de audio nueva, y
  /// arrancar muchas de golpe atrasa el mezclador y corta todo.
  final int separacionMs;
}

/// Lo que suena en la mesa.
///
/// En el telefono, con reproductores de baja latencia que no cortan la
/// musica que se este escuchando; en la web, con Web Audio, que en el
/// navegador suena casi al instante. Las pruebas usan [SonidosMesa.mudos].
abstract interface class SonidosMesa {
  /// [solo] los sonidos que usa ese juego: los demas ni se cargan.
  factory SonidosMesa.delSistema({Set<SonidoMesa>? solo}) =>
      plataforma.crearSonidos(solo ?? SonidoMesa.values.toSet());

  const factory SonidosMesa.mudos() = _SonidosMudos;

  /// Carga todo antes de que haga falta: la primera ficha tiene que sonar
  /// justo cuando cae, no despues.
  Future<void> preparar();

  void tocar(SonidoMesa sonido, {double volumen = 1});

  /// Apaga lo que este sonando de [sonido], con un fundido cortito (la bola
  /// que deja de rodar al caer del carril).
  void detener(SonidoMesa sonido);

  Future<void> liberar();
}

class _SonidosMudos implements SonidosMesa {
  const _SonidosMudos();

  @override
  Future<void> preparar() async {}

  @override
  void tocar(SonidoMesa sonido, {double volumen = 1}) {}

  @override
  void detener(SonidoMesa sonido) {}

  @override
  Future<void> liberar() async {}
}

/// Decide si un sonido puede sonar ahora o si acaba de sonar hace tan poco
/// que se descarta (ver [SonidoMesa.separacionMs]).
class LimitadorDeSonidos {
  LimitadorDeSonidos({int Function()? ahoraMs}) : _ahoraMs = ahoraMs ?? _reloj;

  static final _cronometro = Stopwatch()..start();
  static int _reloj() => _cronometro.elapsedMilliseconds;

  final int Function() _ahoraMs;
  final _ultimo = <SonidoMesa, int>{};

  bool dejaPasar(SonidoMesa sonido) {
    final ahora = _ahoraMs();
    final antes = _ultimo[sonido];
    if (antes != null && ahora - antes < sonido.separacionMs) return false;
    _ultimo[sonido] = ahora;
    return true;
  }
}

/// La "voz" de MacIAs mientras escribe una frase: un murmullo suave, uno
/// solo por frase.
///
/// Antes sonaba un tic por cada tres letras (unos 13 por segundo). En un
/// Android, cada sonido corto es una pista de audio nueva: 700 en siete
/// minutos de mesa atrasaron el mezclador del telefono (se midio en el log
/// del A15, y era lo que cortaba y rompia el resto de los sonidos). Ahora es
/// un solo archivo del largo de la frase, que se apaga con un fundido cuando
/// termina de escribirse.
class VozCrupier {
  VozCrupier({required this.tocar, required this.detener});

  /// Cada pantalla pasa su propio "suena si el sonido esta prendido".
  final void Function(SonidoMesa sonido, {double volumen}) tocar;
  final void Function(SonidoMesa sonido) detener;

  SonidoMesa? _sonando;

  /// El murmullo que le toca a una frase que tarda [milisegundos] en
  /// escribirse: el mas corto que le alcance.
  static SonidoMesa paraFrase(int milisegundos) => milisegundos <= 1100
      ? SonidoMesa.vozCorta
      : milisegundos <= 2000
      ? SonidoMesa.vozMedia
      : SonidoMesa.vozLarga;

  /// Empieza a "hablar" una frase que tarda [milisegundos] en escribirse.
  void empezar(int milisegundos) {
    terminar();
    final sonido = _sonando = paraFrase(milisegundos);
    tocar(sonido, volumen: .3);
  }

  /// Termino de escribirse (o se la saco del medio): se apaga.
  void terminar() {
    final sonido = _sonando;
    if (sonido == null) return;
    _sonando = null;
    detener(sonido);
  }
}
