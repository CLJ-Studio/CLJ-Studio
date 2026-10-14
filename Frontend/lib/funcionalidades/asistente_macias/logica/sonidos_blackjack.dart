import 'sonidos_blackjack_movil.dart'
    if (dart.library.js_interop) 'sonidos_blackjack_web.dart'
    as plataforma;

/// Los sonidos de la mesa de blackjack. Salen de
/// `tool/generar_sonidos_blackjack.dart`.
enum SonidoMesa {
  ficha(['ficha_1', 'ficha_2'], copias: 3),
  fichas(['fichas'], copias: 2),
  cartaSale(['carta_sale_1', 'carta_sale_2'], copias: 3),
  cartaCae(['carta_cae'], copias: 4),
  voltear(['voltear']),
  barajar(['barajar']),
  ganar(['ganar']),
  blackjack(['blackjack']),
  perder(['perder']),
  empate(['empate']),
  pasarse(['pasarse']),
  cobrar(['cobrar'], copias: 2),
  boton(['boton'], copias: 2),
  pista(['pista']),
  voz(['voz_1', 'voz_2', 'voz_3'], copias: 2);

  const SonidoMesa(this.archivos, {this.copias = 1});

  /// Las variantes: cada vez suena una, para que no sea siempre igual.
  final List<String> archivos;

  /// Cuantas veces puede sonar al mismo tiempo (en el telefono; en la web no
  /// hay limite).
  final int copias;
}

/// Lo que suena en la mesa.
///
/// En el telefono, con reproductores de baja latencia que no cortan la
/// musica que se este escuchando; en la web, con Web Audio, que en el
/// navegador suena casi al instante. Las pruebas usan [SonidosMesa.mudos].
abstract interface class SonidosMesa {
  factory SonidosMesa.delSistema() => plataforma.crearSonidos();

  const factory SonidosMesa.mudos() = _SonidosMudos;

  /// Carga todo antes de que haga falta: la primera ficha tiene que sonar
  /// justo cuando cae, no despues.
  Future<void> preparar();

  void tocar(SonidoMesa sonido, {double volumen = 1});

  Future<void> liberar();
}

class _SonidosMudos implements SonidosMesa {
  const _SonidosMudos();

  @override
  Future<void> preparar() async {}

  @override
  void tocar(SonidoMesa sonido, {double volumen = 1}) {}

  @override
  Future<void> liberar() async {}
}
