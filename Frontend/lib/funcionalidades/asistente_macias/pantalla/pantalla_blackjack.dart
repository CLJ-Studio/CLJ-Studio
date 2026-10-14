import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/animaciones/escala_al_presionar.dart';
import '../../../elementos_compartidos/interaccion/frecuencia_pantalla.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/cartas_blackjack.dart';
import '../diseno/crupier_macias.dart';
import '../diseno/fichas_blackjack.dart';
import '../diseno/pano_blackjack.dart';
import '../logica/almacen_blackjack.dart';
import '../logica/estrategia_blackjack.dart';
import '../logica/frases_crupier.dart';
import '../logica/mesa_blackjack.dart';
import '../logica/sonidos_blackjack.dart';

/// La mesa secreta de blackjack de MacIAs.
///
/// Se llega escribiendole "blackjack" en el chat. MacIAs reparte con chaleco
/// y moño, y cambia de cara como el personaje de una novela visual; las
/// fichas son de juego (no valen dinero) y quedan guardadas en el telefono.
///
/// Todo lo que se mueve (cartas, fichas, confeti) se pinta una vez y despues
/// solo se desplaza, gira o se apaga. Asi la mesa va al ritmo de la pantalla,
/// sea de 60, 90 o 120 Hz, sin trabarse. Cada movimiento tiene su sonido, y
/// suena cuando pasa: la ficha al caer, la carta al tocar el paño.
class PantallaBlackjack extends StatefulWidget {
  const PantallaBlackjack({
    this.nombre = '',
    this.almacen,
    this.sonidos,
    this.sabot,
    this.azar,
    super.key,
  });

  /// Como llamar a quien juega.
  final String nombre;

  /// Donde se guardan las fichas. Sin indicarlo, en memoria (pruebas).
  final AlmacenBlackjack? almacen;

  /// Lo que suena. Sin indicarlo, los sonidos del telefono o del navegador.
  final SonidosMesa? sonidos;

  /// Un sabot ya armado: para las pruebas.
  final Sabot? sabot;
  final math.Random? azar;

  /// La entrada a la mesa: aparece desde el centro, como cuando se prenden
  /// las luces del casino.
  static Route<void> ruta({
    String nombre = '',
    AlmacenBlackjack? almacen,
    SonidosMesa? sonidos,
  }) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) =>
        PantallaBlackjack(nombre: nombre, almacen: almacen, sonidos: sonidos),
    transitionsBuilder: (context, animacion, _, hijo) {
      final curva = CurvedAnimation(
        parent: animacion,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curva,
        child: ScaleTransition(
          scale: Tween(begin: .93, end: 1.0).animate(curva),
          child: hijo,
        ),
      );
    },
  );

  @override
  State<PantallaBlackjack> createState() => _PantallaBlackjackState();
}

/// Una carta que esta en la mesa, con su lugar: para mandarla al descarte.
typedef _CartaQuieta = ({
  Carta carta,
  Offset centro,
  double giro,
  double escala,
});

/// Fichas en el aire.
class _Vuelo {
  _Vuelo({
    required this.id,
    required this.desde,
    required this.hasta,
    required this.monto,
    required this.retraso,
    required this.duracion,
    required this.diametro,
    this.lugar,
    this.desvanecer = false,
    this.alLlegar,
  });

  final int id;
  final Offset desde;
  final Offset hasta;
  final int monto;
  final Duration retraso;
  final Duration duracion;
  final double diametro;

  /// A que lugar de apuesta van (-1 el seguro): mientras vuelan, ese lugar
  /// todavia no las muestra.
  final int? lugar;
  final bool desvanecer;
  final VoidCallback? alLlegar;
}

/// Donde va cada cosa en la mesa, segun el tamano de la pantalla.
class _Geometria {
  _Geometria(this.mesa) {
    final w = mesa.width;
    final h = mesa.height;
    carta = math.min(w * .2, h * .16).clamp(46.0, 92.0);
    altoCarta = carta * 1.4;
    // El retrato de MacIAs, grande como el de una novela visual: se tienen
    // que ver sus caras.
    avatar = (h * .19).clamp(64.0, 124.0);
    final arriba = mesa.top + 16;
    avatarCentro = Offset(mesa.left + 20 + avatar / 2, arriba + avatar / 2);
    placaY = arriba + avatar - 9;
    globo = Rect.fromLTRB(
      avatarCentro.dx + avatar / 2 + 10,
      arriba - 2,
      mesa.right - 14,
      arriba + avatar + 12,
    );
    manoCrupierY = arriba + avatar + 24;
    banca = avatarCentro + Offset(0, avatar * .18);
    final anchoSabot = carta * .86;
    sabot = Rect.fromLTWH(
      mesa.right - anchoSabot - 18,
      manoCrupierY + 4,
      anchoSabot,
      anchoSabot * 1.18,
    );
    descarte = Rect.fromLTWH(
      mesa.left + 20,
      manoCrupierY + 10,
      carta * .74,
      carta * .74 * 1.4,
    );
    apuestaY = mesa.bottom - 50;
    manoJugadorCentroY = apuestaY - 40 - altoCarta / 2;
    final libreArriba = manoCrupierY + altoCarta + 30;
    final libreAbajo = manoJugadorCentroY - altoCarta / 2 - 30;
    leyendas = libreAbajo - libreArriba >= 80;
    arcoY = libreArriba + 18;
    seguro = leyendas
        ? Offset(mesa.center.dx, arcoY + 46)
        : Offset(mesa.center.dx, (libreArriba + libreAbajo) / 2);
    totalCrupier = leyendas
        ? Offset(_centroManoCrupier, manoCrupierY + altoCarta + 13)
        : Offset(_centroManoCrupier, manoCrupierY - 13);
  }

  final Rect mesa;
  late final double carta;
  late final double altoCarta;
  late final double avatar;
  late final Offset avatarCentro;
  late final double placaY;
  late final Rect globo;
  late final double manoCrupierY;
  late final Offset banca;
  late final Rect sabot;
  late final Rect descarte;
  late final double apuestaY;
  late final double manoJugadorCentroY;
  late final bool leyendas;
  late final double arcoY;
  late final Offset seguro;
  late final Offset totalCrupier;

  double get _centroManoCrupier => (descarte.right + sabot.left) / 2;

  double escala(int manos) => switch (manos) {
    <= 1 => 1,
    2 => .8,
    _ => .64,
  };

  double anclaX(int mano, int manos) =>
      mesa.left + mesa.width * (2 * mano + 1) / (2 * manos);

  Offset lugarApuesta(int mano, int manos) =>
      Offset(anclaX(mano, manos), apuestaY);

  double diametroLugar(int manos) => switch (manos) {
    <= 1 => 62,
    2 => 54,
    _ => 46,
  };

  Offset cartaCrupier(int i, int n) {
    final disponible = sabot.left - descarte.right - 16;
    final paso = n <= 1
        ? 0.0
        : math.min(carta * .62, (disponible - carta) / (n - 1));
    final total = carta + paso * (n - 1);
    return Offset(
      _centroManoCrupier - total / 2 + carta / 2 + paso * i,
      manoCrupierY + altoCarta / 2,
    );
  }

  ({Offset centro, double giro}) cartaJugador(
    int mano,
    int manos,
    int i,
    int n, {
    bool activa = false,
    bool doblada = false,
  }) {
    final s = escala(manos);
    final ancho = carta * s;
    final disponible = mesa.width / manos - 12;
    final paso = n <= 1
        ? 0.0
        : math.min(
            ancho * (manos == 1 ? .4 : .32),
            (disponible - ancho) / (n - 1),
          );
    final total = ancho + paso * (n - 1);
    final medio = (n - 1) / 2;
    final x = anclaX(mano, manos) - total / 2 + ancho / 2 + paso * i;
    final y =
        manoJugadorCentroY +
        (i - medio) * (i - medio) * 1.6 * s -
        (activa && manos > 1 ? 10 : 0);
    return (
      centro: Offset(x, y),
      // La carta de doblar va de costado, como en un casino.
      giro: doblada && i == 2 ? math.pi / 2 : (i - medio) * .05,
    );
  }

  /// Arriba de la mano del jugador, para su total y su resultado.
  double topeMano(int manos) =>
      manoJugadorCentroY - altoCarta * escala(manos) / 2;
}

class _PantallaBlackjackState extends State<PantallaBlackjack> {
  static const _fondo = Color(0xFF0C0A09);
  static const _altoBarra = 58.0;
  static const _altoControles = 168.0;

  late final math.Random _azar = widget.azar ?? math.Random();
  late final FrasesCrupier _frases = FrasesCrupier(
    azar: _azar,
    nombre: widget.nombre,
  );
  late final AlmacenBlackjack _almacen =
      widget.almacen ?? AlmacenBlackjackEnMemoria();
  late final SonidosMesa _sonidos = widget.sonidos ?? SonidosMesa.delSistema();
  bool _conSonido = true;

  MesaBlackjack? _mesaCargada;
  MesaBlackjack get _mesa => _mesaCargada!;

  /// Mientras corre una animacion de la mesa: los botones esperan.
  bool _ocupado = false;
  bool _barajando = false;
  bool _rapido = false;
  bool _sinMovimiento = false;

  /// Lo que esta diciendo MacIAs, con que cara, y si todavia lo esta
  /// "escribiendo" (la boca se mueve).
  String? _dicho;
  int _latido = 0;
  ExpresionCrupier _expresion = ExpresionCrupier.normal;
  bool _hablando = false;
  Timer? _callar;

  ConsejoBlackjack? _consejo;
  bool _consejoSeguro = false;
  bool _seguroPerdido = false;

  List<_CartaQuieta> _descartando = const [];
  int _cuantasDescartadas = 0;

  final _vuelos = <_Vuelo>[];
  int _siguienteVuelo = 0;

  /// Mientras se paga, lo que hay sobre cada lugar: las fichas van y vienen.
  bool _pagando = false;
  Map<int, int> _pilasPago = {};
  int _pilaSeguroPago = 0;

  /// Fichas que ya son tuyas pero todavia estan viajando a tu bolsillo.
  int _porLlegar = 0;
  bool _carteles = false;

  int _confeti = 0;
  Offset _origenConfeti = Offset.zero;

  final _llaveCuerpo = GlobalKey();
  final _llaveFichas = GlobalKey();
  final _llavesRack = {
    for (final valor in MesaBlackjack.valoresFichas) valor: GlobalKey(),
  };
  _Geometria? _g;

  double get _ritmo => _sinMovimiento ? .05 : (_rapido ? .55 : 1);

  Duration _dur(int milisegundos) =>
      Duration(milliseconds: math.max(1, (milisegundos * _ritmo).round()));

  Future<void> _esperar(int milisegundos) =>
      Future<void>.delayed(_dur(milisegundos));

  // ============================================================ ciclo de vida
  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
    unawaited(_sonidos.preparar());
    unawaited(FrecuenciaPantalla.pedirAlta(activar: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.disableAnimationsOf(context);
    // La foto de MacIAs, lista antes de que la mesa termine de entrar.
    unawaited(precacheImage(const AssetImage(rutaFotoCrupier), context));
  }

  Future<void> _cargar() async {
    final guardado = await _almacen.cargar();
    final conSonido = await _almacen.conSonido();
    if (!mounted) return;
    setState(() {
      _conSonido = conSonido;
      _mesaCargada = MesaBlackjack(
        fichas: guardado?.fichas ?? MesaBlackjack.fichasIniciales,
        sabot: widget.sabot,
        estadisticas: guardado?.estadisticas,
      );
    });
    final volvio = (guardado?.estadisticas.manos ?? 0) > 0;
    _momento(
      volvio ? MomentoCrupier.bienvenidaDeVuelta : MomentoCrupier.bienvenida,
    );
  }

  @override
  void dispose() {
    _callar?.cancel();
    unawaited(_sonidos.liberar());
    unawaited(FrecuenciaPantalla.pedirAlta(activar: false));
    final mesa = _mesaCargada;
    // A mitad de una mano no se guarda: la apuesta vuelve, como si no se
    // hubiera jugado.
    if (mesa != null &&
        (mesa.fase == FaseMesa.apostando || mesa.fase == FaseMesa.resultado)) {
      unawaited(_almacen.guardar(mesa.fichas, mesa.estadisticas));
    }
    super.dispose();
  }

  Future<void> _guardar() => _almacen.guardar(_mesa.fichas, _mesa.estadisticas);

  // ================================================================ ayudas
  /// Cuanto tarda cada letra en aparecer en la caja de dialogo.
  int get _msPorLetra => (28 * _ritmo).round().clamp(1, 40);

  void _decir(
    String texto, {
    ExpresionCrupier expresion = ExpresionCrupier.normal,
  }) {
    if (!mounted) return;
    _callar?.cancel();
    setState(() {
      _dicho = texto;
      _latido++;
      _expresion = expresion;
    });
    // Lo que tarda en escribirse, y un rato para leerlo.
    final dura = texto.length * _msPorLetra + 2400 + texto.length * 26;
    _callar = Timer(Duration(milliseconds: dura), () {
      if (!mounted) return;
      setState(() {
        _dicho = null;
        _hablando = false;
        _expresion = ExpresionCrupier.normal;
      });
    });
  }

  /// La cara que pone MacIAs en cada momento de la mesa.
  static const _carasDe = <MomentoCrupier, ExpresionCrupier>{
    MomentoCrupier.bienvenida: ExpresionCrupier.risa,
    MomentoCrupier.bienvenidaDeVuelta: ExpresionCrupier.guino,
    MomentoCrupier.apuestaFuerte: ExpresionCrupier.sorprendido,
    MomentoCrupier.todo: ExpresionCrupier.sorprendido,
    MomentoCrupier.reparto: ExpresionCrupier.canchero,
    MomentoCrupier.seguroOfrecido: ExpresionCrupier.canchero,
    MomentoCrupier.seguroTomado: ExpresionCrupier.normal,
    MomentoCrupier.seguroGanado: ExpresionCrupier.nervioso,
    MomentoCrupier.seguroPerdido: ExpresionCrupier.canchero,
    MomentoCrupier.blackjack: ExpresionCrupier.sorprendido,
    MomentoCrupier.blackjackCrupier: ExpresionCrupier.risa,
    MomentoCrupier.veintiuno: ExpresionCrupier.sorprendido,
    MomentoCrupier.tePasaste: ExpresionCrupier.canchero,
    MomentoCrupier.mePase: ExpresionCrupier.nervioso,
    MomentoCrupier.ganaste: ExpresionCrupier.triste,
    MomentoCrupier.ganasteDoblando: ExpresionCrupier.sorprendido,
    MomentoCrupier.perdiste: ExpresionCrupier.feliz,
    MomentoCrupier.empate: ExpresionCrupier.normal,
    MomentoCrupier.rendido: ExpresionCrupier.normal,
    MomentoCrupier.doblar: ExpresionCrupier.canchero,
    MomentoCrupier.dividir: ExpresionCrupier.feliz,
    MomentoCrupier.racha: ExpresionCrupier.nervioso,
    MomentoCrupier.rachaLarga: ExpresionCrupier.enojado,
    MomentoCrupier.barajar: ExpresionCrupier.guino,
    MomentoCrupier.quiebra: ExpresionCrupier.triste,
    MomentoCrupier.rescate: ExpresionCrupier.guino,
    MomentoCrupier.pidesConMucho: ExpresionCrupier.sorprendido,
    MomentoCrupier.cincoCartas: ExpresionCrupier.sorprendido,
  };

  void _momento(MomentoCrupier momento) => _decir(
    _frases.decir(momento),
    expresion: _carasDe[momento] ?? ExpresionCrupier.normal,
  );

  void _sonar(SonidoMesa sonido, {double volumen = 1}) {
    if (_conSonido) _sonidos.tocar(sonido, volumen: volumen * .9);
  }

  /// El centro de algo de la pantalla, en las medidas de la mesa.
  Offset? _centroDe(GlobalKey llave) {
    final caja = llave.currentContext?.findRenderObject() as RenderBox?;
    final cuerpo =
        _llaveCuerpo.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || cuerpo == null || !caja.attached) return null;
    return caja.localToGlobal(caja.size.center(Offset.zero), ancestor: cuerpo);
  }

  Offset get _bolsillo =>
      _centroDe(_llaveFichas) ?? Offset((_g?.mesa.right ?? 300) - 60, 28);

  void _volar({
    required Offset desde,
    required Offset hasta,
    required int monto,
    int? lugar,
    bool desvanecer = false,
    int retraso = 0,
    int duracion = 460,
    double diametro = 30,
    VoidCallback? alLlegar,
  }) {
    if (monto <= 0) {
      alLlegar?.call();
      return;
    }
    _vuelos.add(
      _Vuelo(
        id: _siguienteVuelo++,
        desde: desde,
        hasta: hasta,
        monto: monto,
        lugar: lugar,
        desvanecer: desvanecer,
        retraso: _dur(retraso),
        duracion: _dur(duracion),
        diametro: diametro,
        alLlegar: alLlegar,
      ),
    );
  }

  int _enVueloHacia(int lugar) => _vuelos
      .where((vuelo) => vuelo.lugar == lugar)
      .fold(0, (suma, vuelo) => suma + vuelo.monto);

  /// Lo que muestra la pildora de arriba.
  int get _fichasEnPantalla {
    final mesa = _mesa;
    final base = mesa.fase == FaseMesa.apostando
        ? mesa.fichas - mesa.apuesta
        : mesa.fichas;
    return base - _porLlegar;
  }

  /// Todo lo que se hace con la mesa pasa por aca: mientras dura, los botones
  /// no responden, y si algo falla igual se liberan.
  Future<void> _secuencia(Future<void> Function() pasos) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await pasos();
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      } else {
        _ocupado = false;
      }
    }
  }

  // =============================================================== apostar
  void _apostar(int valor) {
    if (_ocupado || !_mesa.puedeSumar(valor)) return;
    RetroalimentacionHaptica.seleccion();
    final desde = _centroDe(_llavesRack[valor]!);
    final g = _g!;
    setState(() {
      _mesa.sumar(valor);
      _consejo = null;
      if (desde != null) {
        _volar(
          desde: desde,
          hasta: g.lugarApuesta(0, 1),
          monto: valor,
          lugar: 0,
          duracion: 360,
          // Suena cuando cae sobre la pila, no cuando se toca.
          alLlegar: () => _sonar(SonidoMesa.ficha),
        );
      }
    });
  }

  /// Borrar, repetir, x2, todo: la diferencia vuela entre tus fichas y la
  /// mesa.
  void _ajustarApuesta(void Function() cambio) {
    if (_ocupado) return;
    final antes = _mesa.apuesta;
    final g = _g!;
    final lugar = g.lugarApuesta(0, 1);
    final bolsillo = _bolsillo;
    setState(() {
      cambio();
      final diferencia = _mesa.apuesta - antes;
      if (diferencia > 0) {
        _volar(
          desde: bolsillo,
          hasta: lugar,
          monto: diferencia,
          lugar: 0,
          duracion: 420,
          alLlegar: () => _sonar(SonidoMesa.fichas),
        );
      } else if (diferencia < 0) {
        _porLlegar += -diferencia;
        _volar(
          desde: lugar,
          hasta: bolsillo,
          monto: -diferencia,
          duracion: 420,
          alLlegar: () {
            _sonar(SonidoMesa.fichas, volumen: .7);
            setState(() => _porLlegar = math.max(0, _porLlegar + diferencia));
          },
        );
      }
    });
    RetroalimentacionHaptica.seleccion();
  }

  void _rescatar() {
    if (!_mesa.enQuiebra) return;
    final g = _g!;
    final bolsillo = _bolsillo;
    const monto = MesaBlackjack.fichasIniciales;
    setState(() {
      _mesa.rescatar();
      _porLlegar += monto;
      _volar(
        desde: g.banca,
        hasta: bolsillo,
        monto: monto,
        duracion: 720,
        diametro: 34,
        alLlegar: () {
          _sonar(SonidoMesa.cobrar);
          setState(() => _porLlegar = math.max(0, _porLlegar - monto));
        },
      );
    });
    _momento(MomentoCrupier.rescate);
    unawaited(_guardar());
  }

  // ============================================================== repartir
  Future<void> _repartir() => _secuencia(() async {
    final mesa = _mesa;
    if (!mesa.puedeRepartir) return;
    _consejo = null;
    if (mesa.sabot.tocaBarajar) await _barajar();
    if (!mounted) return;
    final apuesta = mesa.apuesta;
    final fichas = mesa.fichas;
    setState(mesa.empezar);
    if (apuesta >= fichas && fichas >= 100) {
      _momento(MomentoCrupier.todo);
    } else if (apuesta >= fichas * .4 && apuesta >= 200) {
      _momento(MomentoCrupier.apuestaFuerte);
    } else if (_azar.nextDouble() < .4) {
      _momento(MomentoCrupier.reparto);
    }
    // Cada carta suena sola al salir y al caer (ver _cartas).
    for (var paso = 0; paso < 4; paso++) {
      if (!mounted) return;
      setState(() {
        if (paso.isEven) {
          mesa.darAJugador();
        } else {
          mesa.darACrupier();
        }
      });
      RetroalimentacionHaptica.seleccion();
      await _esperar(paso == 3 ? 430 : 280);
    }
    if (!mounted) return;
    setState(mesa.trasRepartir);
    await _seguir();
  });

  Future<void> _barajar() async {
    _momento(MomentoCrupier.barajar);
    _sonar(SonidoMesa.barajar);
    setState(() => _barajando = true);
    await _esperar(1500);
    if (!mounted) return;
    _mesa.sabot.barajar();
    setState(() {
      _barajando = false;
      _cuantasDescartadas = 0;
    });
    await _esperar(160);
  }

  /// Despues de cada movimiento: las manos divididas que esperan carta, el
  /// turno del crupier o los pagos.
  Future<void> _seguir() async {
    while (mounted) {
      final mesa = _mesa;
      switch (mesa.fase) {
        case FaseMesa.seguro:
          _momento(MomentoCrupier.seguroOfrecido);
          return;
        case FaseMesa.jugando:
          if (!mesa.manoNecesitaCarta) return;
          await _esperar(260);
          if (!mounted) return;
          setState(() {
            mesa
              ..darAJugador()
              ..completarDivision();
          });
          await _esperar(430);
        case FaseMesa.crupier:
          await _turnoCrupier();
        case FaseMesa.resultado:
          await _pagar();
          return;
        case FaseMesa.apostando || FaseMesa.repartiendo:
          return;
      }
    }
  }

  Future<void> _turnoCrupier() async {
    await _esperar(300);
    if (!mounted) return;
    // La carta tapada suena sola al darse vuelta (ver _cartas).
    setState(_mesa.revelar);
    await _esperar(640);
    while (mounted && _mesa.crupierDebePedir) {
      setState(_mesa.crupierPide);
      RetroalimentacionHaptica.seleccion();
      await _esperar(660);
    }
    if (!mounted) return;
    setState(_mesa.terminarCrupier);
  }

  // ================================================================ jugar
  Future<void> _accion(Jugada jugada) => _secuencia(() async {
    final mesa = _mesa;
    if (!mesa.puede(jugada)) return;
    final g = _g!;
    final indice = mesa.manoActual;
    final mano = mesa.mano;
    setState(() => _consejo = null);
    switch (jugada) {
      case Jugada.pedir:
        if (!mano.blanda && mano.total >= 17) {
          _momento(MomentoCrupier.pidesConMucho);
        }
        setState(() => mesa.pedir());
        await _esperar(440);
        if (mano.cartas.length == 5 && !mano.sePaso) {
          _momento(MomentoCrupier.cincoCartas);
        } else if (mano.total == 21) {
          _momento(MomentoCrupier.veintiuno);
        } else if (mano.sePaso && mesa.manos.length > 1) {
          _sonar(SonidoMesa.pasarse, volumen: .7);
          _momento(MomentoCrupier.tePasaste);
        }
      case Jugada.plantarse:
        _sonar(SonidoMesa.boton, volumen: .7);
        setState(mesa.plantarse);
        await _esperar(220);
      case Jugada.doblar:
        final monto = mano.apuesta;
        _momento(MomentoCrupier.doblar);
        setState(() {
          _volar(
            desde: _bolsillo,
            hasta: g.lugarApuesta(indice, mesa.manos.length),
            monto: monto,
            lugar: indice,
            diametro: _diametroPila(mesa.manos.length),
            alLlegar: () => _sonar(SonidoMesa.fichas),
          );
          mesa.doblar();
        });
        await _esperar(600);
      case Jugada.dividir:
        final monto = mano.apuesta;
        _momento(MomentoCrupier.dividir);
        // Las dos cartas se separan: un soplido de cartas.
        _sonar(SonidoMesa.cartaSale, volumen: .7);
        setState(() {
          mesa.dividir();
          _volar(
            desde: _bolsillo,
            hasta: g.lugarApuesta(indice + 1, mesa.manos.length),
            monto: monto,
            lugar: indice + 1,
            diametro: _diametroPila(mesa.manos.length),
            alLlegar: () => _sonar(SonidoMesa.fichas),
          );
        });
        await _esperar(480);
      case Jugada.rendirse:
        setState(mesa.rendirse);
        await _esperar(260);
    }
    if (!mounted) return;
    await _seguir();
  });

  Future<void> _seguro({required bool tomar}) => _secuencia(() async {
    final mesa = _mesa;
    if (mesa.fase != FaseMesa.seguro) return;
    final g = _g!;
    setState(() {
      _consejoSeguro = false;
      if (tomar && mesa.puedeAsegurar) {
        final costo = mesa.costoSeguro;
        mesa.decidirSeguro(tomar: true);
        _volar(
          desde: _bolsillo,
          hasta: g.seguro,
          monto: costo,
          lugar: -1,
          alLlegar: () => _sonar(SonidoMesa.ficha),
        );
      } else {
        mesa.decidirSeguro(tomar: false);
      }
    });
    if (mesa.seguro > 0) _momento(MomentoCrupier.seguroTomado);
    // MacIAs espia su carta tapada.
    await _esperar(760);
    if (!mounted) return;
    if (mesa.fase == FaseMesa.jugando && mesa.seguro > 0) {
      setState(() {
        _seguroPerdido = true;
        _volar(
          desde: g.seguro,
          hasta: g.banca,
          monto: mesa.seguro,
          desvanecer: true,
          alLlegar: () => _sonar(SonidoMesa.fichas, volumen: .55),
        );
      });
      _momento(MomentoCrupier.seguroPerdido);
    }
    await _seguir();
  });

  void _pista() {
    final mesa = _mesa;
    _sonar(SonidoMesa.pista);
    if (mesa.fase == FaseMesa.seguro) {
      setState(() => _consejoSeguro = true);
      _decir(
        EstrategiaBlackjack.sobreElSeguro,
        expresion: ExpresionCrupier.canchero,
      );
      return;
    }
    final consejo = EstrategiaBlackjack.para(mesa);
    if (consejo == null) return;
    setState(() => _consejo = consejo);
    _decir(consejo.porque, expresion: ExpresionCrupier.canchero);
  }

  // ================================================================ pagar
  /// Lo que dice MacIAs al terminar la mano, y el sonido del resultado.
  ({MomentoCrupier momento, SonidoMesa sonido}) _cierre() {
    final mesa = _mesa;
    final resultados = mesa.resultados;
    final racha = mesa.estadisticas.rachaActual;
    final neto = mesa.netoRonda;
    final sonido = switch (neto) {
      _ when resultados.any((r) => r.desenlace == Desenlace.blackjack) =>
        SonidoMesa.blackjack,
      > 0 => SonidoMesa.ganar,
      _ when resultados.every((r) => r.desenlace == Desenlace.sePaso) =>
        SonidoMesa.pasarse,
      < 0 => SonidoMesa.perder,
      _ => SonidoMesa.empate,
    };
    final MomentoCrupier momento;
    if (resultados.any((r) => r.desenlace == Desenlace.blackjack)) {
      momento = MomentoCrupier.blackjack;
    } else if (mesa.crupier.esBlackjack) {
      momento = mesa.pagoSeguro > 0
          ? MomentoCrupier.seguroGanado
          : MomentoCrupier.blackjackCrupier;
    } else if (resultados.every((r) => r.desenlace == Desenlace.sePaso)) {
      momento = MomentoCrupier.tePasaste;
    } else if (resultados.every((r) => r.desenlace == Desenlace.rendida)) {
      momento = MomentoCrupier.rendido;
    } else if (mesa.crupier.sePaso && neto > 0) {
      momento = MomentoCrupier.mePase;
    } else if (neto > 0) {
      final doblo =
          mesa.manos.any((m) => m.doblada) &&
          resultados.any((r) => r.desenlace == Desenlace.gana);
      momento = racha >= 5
          ? MomentoCrupier.rachaLarga
          : racha >= 3
          ? MomentoCrupier.racha
          : doblo
          ? MomentoCrupier.ganasteDoblando
          : MomentoCrupier.ganaste;
    } else if (neto == 0 &&
        resultados.every((r) => r.desenlace == Desenlace.empata)) {
      momento = MomentoCrupier.empate;
    } else {
      momento = MomentoCrupier.perdiste;
    }
    return (momento: momento, sonido: sonido);
  }

  Future<void> _pagar() async {
    final mesa = _mesa;
    final g = _g!;
    final k = mesa.manos.length;
    // Que se vea la carta tapada antes de pagar.
    await _esperar(mesa.crupier.cartas.length > 2 ? 380 : 560);
    if (!mounted) return;
    final resultados = mesa.resultados;
    final cierre = _cierre();
    final seguroEnMesa = mesa.seguro > 0 && !_seguroPerdido;
    setState(() {
      _carteles = true;
      _pagando = true;
      _pilasPago = {
        for (final (i, resultado) in resultados.indexed) i: resultado.apuesta,
      };
      _pilaSeguroPago = seguroEnMesa ? mesa.seguro : 0;
      _porLlegar =
          resultados.fold(0, (suma, r) => suma + r.pago) + mesa.pagoSeguro;
    });
    // El sonido del resultado entra junto con los carteles.
    _sonar(cierre.sonido);
    _momento(cierre.momento);

    final neto = mesa.netoRonda;
    final hayBlackjack = resultados.any(
      (r) => r.desenlace == Desenlace.blackjack,
    );
    if (neto > 0) {
      RetroalimentacionHaptica.exito();
      if (!_sinMovimiento &&
          (hayBlackjack || neto >= 500 || mesa.estadisticas.rachaActual >= 5)) {
        setState(() {
          _confeti++;
          _origenConfeti = Offset(g.mesa.center.dx, g.manoJugadorCentroY);
        });
      }
    }

    // Lo que se gana lo trae MacIAs; lo que se pierde se lo lleva.
    final diametro = _diametroPila(k);
    setState(() {
      for (final (i, r) in resultados.indexed) {
        final lugar = g.lugarApuesta(i, k);
        switch (r.desenlace) {
          case Desenlace.blackjack || Desenlace.gana:
            _volar(
              desde: g.banca,
              hasta: lugar,
              monto: r.neto,
              retraso: 260 + i * 120,
              diametro: diametro,
              alLlegar: () {
                _sonar(SonidoMesa.fichas);
                setState(() => _pilasPago[i] = (_pilasPago[i] ?? 0) + r.neto);
              },
            );
          case Desenlace.pierde || Desenlace.sePaso:
            _pilasPago[i] = 0;
            _volar(
              desde: lugar,
              hasta: g.banca,
              monto: r.apuesta,
              desvanecer: true,
              retraso: 260 + i * 120,
              diametro: diametro,
              alLlegar: () => _sonar(SonidoMesa.fichas, volumen: .5),
            );
          case Desenlace.rendida:
            _pilasPago[i] = r.pago;
            _volar(
              desde: lugar,
              hasta: g.banca,
              monto: r.apuesta - r.pago,
              desvanecer: true,
              retraso: 260,
              diametro: diametro,
              alLlegar: () => _sonar(SonidoMesa.fichas, volumen: .5),
            );
          case Desenlace.empata:
            break;
        }
      }
      if (seguroEnMesa) {
        if (mesa.pagoSeguro > 0) {
          final premio = mesa.pagoSeguro - mesa.seguro;
          _volar(
            desde: g.banca,
            hasta: g.seguro,
            monto: premio,
            retraso: 260,
            alLlegar: () {
              _sonar(SonidoMesa.ficha);
              setState(() => _pilaSeguroPago += premio);
            },
          );
        } else {
          _pilaSeguroPago = 0;
          _volar(
            desde: g.seguro,
            hasta: g.banca,
            monto: mesa.seguro,
            desvanecer: true,
            retraso: 260,
          );
        }
      }
    });
    await _esperar(1300);
    if (!mounted) return;

    // Lo que quedo en la mesa vuelve a tus fichas, con su "cha-ching" al
    // llegar la primera pila.
    final bolsillo = _bolsillo;
    var sonoCobro = false;
    void cobrar(int monto) {
      if (!sonoCobro) {
        sonoCobro = true;
        _sonar(SonidoMesa.cobrar);
      }
      setState(() => _porLlegar = math.max(0, _porLlegar - monto));
    }

    setState(() {
      for (final MapEntry(key: i, value: monto)
          in _pilasPago.entries.toList()) {
        if (monto <= 0) continue;
        _pilasPago[i] = 0;
        _volar(
          desde: g.lugarApuesta(i, k),
          hasta: bolsillo,
          monto: monto,
          retraso: i * 90,
          duracion: 580,
          diametro: diametro,
          alLlegar: () => cobrar(monto),
        );
      }
      if (_pilaSeguroPago > 0) {
        final monto = _pilaSeguroPago;
        _pilaSeguroPago = 0;
        _volar(
          desde: g.seguro,
          hasta: bolsillo,
          monto: monto,
          duracion: 580,
          alLlegar: () => cobrar(monto),
        );
      }
    });
    await _esperar(900);
    if (!mounted) return;
    setState(() => _porLlegar = 0);
    unawaited(_guardar());
  }

  // ============================================================ nueva mano
  List<_CartaQuieta> _cartasQuietas(_Geometria g) {
    final mesa = _mesa;
    final k = mesa.manos.length;
    return [
      for (final (i, carta) in mesa.crupier.cartas.indexed)
        (
          carta: carta,
          centro: g.cartaCrupier(i, mesa.crupier.cartas.length),
          giro: 0.0,
          escala: 1.0,
        ),
      for (final (m, mano) in mesa.manos.indexed)
        for (final (i, carta) in mano.cartas.indexed)
          (
            carta: carta,
            centro: g.cartaJugador(m, k, i, mano.cartas.length).centro,
            giro: 0.0,
            escala: g.escala(k),
          ),
    ];
  }

  Future<void> _nuevaMano({bool repetir = false}) async {
    if (_ocupado || _mesa.fase != FaseMesa.resultado) return;
    await _secuencia(() async {
      final g = _g!;
      final quietas = _cartasQuietas(g);
      // MacIAs recoge las cartas: un soplido largo.
      _sonar(SonidoMesa.cartaSale);
      setState(() {
        _descartando = quietas;
        _cuantasDescartadas += quietas.length;
        _mesa.nuevaRonda();
        _carteles = false;
        _pagando = false;
        _pilasPago = {};
        _pilaSeguroPago = 0;
        _porLlegar = 0;
        _consejo = null;
        _consejoSeguro = false;
        _seguroPerdido = false;
      });
      await _esperar(480);
      if (!mounted) return;
      setState(() => _descartando = const []);
    });
    if (!mounted) return;
    if (_mesa.enQuiebra) {
      _momento(MomentoCrupier.quiebra);
      return;
    }
    if (repetir && _mesa.puedeRepetir) {
      _ajustarApuesta(_mesa.repetir);
      await _esperar(460);
      if (mounted) await _repartir();
    }
  }

  // ================================================================= menu
  Future<void> _menu() {
    _sonar(SonidoMesa.boton, volumen: .7);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1614),
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: StatefulBuilder(
          builder: (hoja, actualizar) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                secondary: Icon(
                  _conSonido
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: ColoresCarta.oroClaro,
                ),
                title: const Text(
                  'Sonido',
                  style: TextStyle(
                    color: ConfiguracionTema.crema,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                value: _conSonido,
                onChanged: (valor) {
                  setState(() => _conSonido = valor);
                  actualizar(() {});
                  unawaited(_almacen.guardarSonido(valor));
                  _sonar(SonidoMesa.ficha);
                },
              ),
              _OpcionMenu(
                icono: Icons.menu_book_rounded,
                titulo: 'Cómo se juega',
                alTocar: () {
                  Navigator.of(hoja).pop();
                  _reglas();
                },
              ),
              _OpcionMenu(
                icono: Icons.insights_rounded,
                titulo: 'Tus estadísticas',
                alTocar: () {
                  Navigator.of(hoja).pop();
                  _estadisticas();
                },
              ),
              SwitchListTile(
                secondary: const Icon(
                  Icons.speed_rounded,
                  color: ColoresCarta.oroClaro,
                ),
                title: const Text(
                  'Reparto rápido',
                  style: TextStyle(
                    color: ConfiguracionTema.crema,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                value: _rapido,
                onChanged: (valor) {
                  setState(() => _rapido = valor);
                  actualizar(() {});
                },
              ),
              _OpcionMenu(
                icono: Icons.restart_alt_rounded,
                titulo: 'Empezar de cero',
                detalle: 'Fichas a 1.000 y estadísticas nuevas',
                alTocar: () {
                  Navigator.of(hoja).pop();
                  _empezarDeCero();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _empezarDeCero() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Empezar de cero?'),
        content: const Text(
          'Vuelves a tener 1.000 fichas y se borran tus estadísticas de la '
          'mesa.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text('Empezar de cero'),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted || _ocupado) return;
    if (_mesa.fase != FaseMesa.apostando && _mesa.fase != FaseMesa.resultado) {
      return;
    }
    setState(() {
      _mesaCargada = MesaBlackjack(sabot: widget.sabot);
      _descartando = const [];
      _carteles = false;
      _pagando = false;
      _pilasPago = {};
      _porLlegar = 0;
      _vuelos.clear();
    });
    _momento(MomentoCrupier.bienvenida);
    unawaited(_guardar());
  }

  Future<void> _reglas() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1614),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (hoja) => const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TituloHoja('Cómo se juega'),
            _Regla(
              'El objetivo',
              'Sumar más que MacIAs sin pasarte de 21. Las figuras valen 10 y '
                  'el As, 1 u 11.',
            ),
            _Regla(
              'Blackjack',
              'Un As y un 10 o una figura en tus dos primeras cartas. Paga 3 a '
                  '2.',
            ),
            _Regla(
              'El crupier',
              'MacIAs pide hasta 16 y se planta en todos los 17. Si muestra un '
                  'As o un 10, espía su carta tapada por si tiene blackjack.',
            ),
            _Regla(
              'Doblar',
              'Duplicas tu apuesta y recibes una sola carta más. También '
                  'después de dividir.',
            ),
            _Regla(
              'Dividir',
              'Si tus dos cartas valen lo mismo, las separas en dos manos, '
                  'hasta cuatro. Los ases divididos reciben una sola carta.',
            ),
            _Regla(
              'Rendirse',
              'Con tus dos primeras cartas, abandonas la mano y recuperas la '
                  'mitad de la apuesta.',
            ),
            _Regla(
              'Seguro',
              'Si MacIAs muestra un As, puedes asegurarte por la mitad de tu '
                  'apuesta. Paga 2 a 1 si tiene blackjack.',
            ),
            _Regla(
              'El sabot',
              'Seis mazos, mezclados con el azar del teléfono. Se vuelve a '
                  'barajar al salir la carta de corte.',
            ),
            _Regla(
              'Las fichas',
              'Son de juego: no valen dinero ni se compran. Si te quedas sin '
                  'ninguna, MacIAs te presta.',
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _estadisticas() {
    final e = _mesa.estadisticas;
    final datos = [
      ('Manos jugadas', conMiles(e.manos)),
      ('Ganadas', conMiles(e.ganadas)),
      ('Perdidas', conMiles(e.perdidas)),
      ('Empates', conMiles(e.empatadas)),
      ('Blackjacks', conMiles(e.blackjacks)),
      ('Victorias', '${e.porcentajeGanadas} %'),
      ('Racha actual', conMiles(e.rachaActual)),
      ('Mejor racha', conMiles(e.mejorRacha)),
      ('Récord de fichas', conMiles(e.fichasMaximas)),
      ('Mayor premio', conMiles(e.mayorPremio)),
      ('Préstamos de MacIAs', conMiles(e.rescates)),
    ];
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1614),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (hoja) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TituloHoja('Tus estadísticas'),
              for (final (titulo, valor) in datos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            color: ConfiguracionTema.crema.withValues(
                              alpha: .75,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        valor,
                        style: const TextStyle(
                          color: ColoresCarta.oroClaro,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================ dibujo
  double _diametroPila(int manos) => manos <= 1 ? 32 : 26;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: _fondo,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: _fondo,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.35),
            radius: 1.25,
            colors: [Color(0xFF2A1F19), _fondo],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, caja) => _mesaCargada == null
                ? const Center(
                    child: CircularProgressIndicator(color: ColoresCarta.oro),
                  )
                : _mesaEn(caja.biggest),
          ),
        ),
      ),
    ),
  );

  Widget _mesaEn(Size cuerpo) {
    final anchoMesa = math.min(cuerpo.width - 16, 560.0);
    final rectMesa = Rect.fromLTWH(
      (cuerpo.width - anchoMesa) / 2,
      _altoBarra,
      anchoMesa,
      math.max(240.0, cuerpo.height - _altoBarra - _altoControles),
    );
    final g = _g = _Geometria(rectMesa);
    return Stack(
      key: _llaveCuerpo,
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: rectMesa,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: PintorPano(
                arcoY: g.arcoY - rectMesa.top,
                leyendas: g.leyendas,
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: g.descarte,
          child: _Descarte(cuantas: _cuantasDescartadas),
        ),
        Positioned.fromRect(
          rect: g.sabot,
          child: _SabotEnMesa(
            quedan: _mesa.sabot.quedan,
            barajando: _barajando,
          ),
        ),
        ..._lugares(g),
        ..._pilas(g),
        ..._cartas(g),
        ..._totales(g),
        if (_carteles) ..._cartelesResultado(g),
        Positioned(
          left: g.avatarCentro.dx - g.avatar / 2,
          top: g.avatarCentro.dy - g.avatar / 2,
          child: CrupierMacias(
            tamano: g.avatar,
            expresion: _expresion,
            hablando: _hablando,
            latido: _latido,
          ),
        ),
        Positioned(
          left: g.avatarCentro.dx - 70,
          width: 140,
          top: g.placaY,
          child: const Center(child: PlacaCrupier()),
        ),
        Positioned(
          left: g.globo.left,
          top: g.globo.top,
          width: g.globo.width,
          child: Align(
            alignment: Alignment.topLeft,
            child: AnimatedSwitcher(
              duration: _dur(240),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (hijo, animacion) => FadeTransition(
                opacity: animacion,
                child: ScaleTransition(
                  scale: Tween(begin: .92, end: 1.0).animate(animacion),
                  alignment: Alignment.topLeft,
                  child: hijo,
                ),
              ),
              child: _dicho == null
                  ? const SizedBox.shrink(key: ValueKey('callado'))
                  : DialogoCrupier(
                      key: ValueKey(_latido),
                      texto: _dicho!,
                      msPorLetra: _msPorLetra,
                      alHablar: (hablando) {
                        if (mounted && _hablando != hablando) {
                          setState(() => _hablando = hablando);
                        }
                      },
                      alSonar: () => _sonar(SonidoMesa.voz, volumen: .3),
                    ),
            ),
          ),
        ),
        if (_barajando) _Barajada(g: g, duracion: _dur(1500)),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _altoBarra,
          child: _BarraMesa(
            llaveFichas: _llaveFichas,
            fichas: _fichasEnPantalla,
            alMenu: _menu,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _altoControles,
          child: _panelControles(),
        ),
        for (final vuelo in _vuelos)
          FichasEnVuelo(
            key: ValueKey('vuelo${vuelo.id}'),
            desde: vuelo.desde,
            hasta: vuelo.hasta,
            monto: vuelo.monto,
            diametro: vuelo.diametro,
            retraso: vuelo.retraso,
            duracion: vuelo.duracion,
            desvanecer: vuelo.desvanecer,
            alLlegar: () {
              if (!mounted) return;
              setState(() => _vuelos.remove(vuelo));
              vuelo.alLlegar?.call();
            },
          ),
        Positioned.fill(
          child: Confeti(disparo: _confeti, origen: _origenConfeti),
        ),
      ],
    );
  }

  List<Widget> _lugares(_Geometria g) {
    final mesa = _mesa;
    if (mesa.fase == FaseMesa.apostando || mesa.manos.isEmpty) {
      return [
        _centrado(
          g.lugarApuesta(0, 1),
          LugarApuesta(
            diametro: g.diametroLugar(1),
            activo: mesa.apuesta == 0 && !_ocupado,
          ),
          lado: 80,
        ),
      ];
    }
    final k = mesa.manos.length;
    return [
      for (var i = 0; i < k; i++)
        _centrado(
          g.lugarApuesta(i, k),
          LugarApuesta(
            diametro: g.diametroLugar(k),
            activo:
                k > 1 && i == mesa.manoActual && mesa.fase == FaseMesa.jugando,
          ),
          lado: 80,
        ),
    ];
  }

  List<Widget> _pilas(_Geometria g) {
    final mesa = _mesa;
    final piezas = <Widget>[];
    void pila(Offset lugar, int monto, double diametro, {Key? llave}) {
      final medida = PilaFichas.medida(diametro);
      piezas.add(
        AnimatedPositioned(
          key: llave,
          duration: _dur(320),
          curve: Curves.easeOutCubic,
          left: lugar.dx - medida.width / 2,
          top: lugar.dy - (medida.height - 22 - diametro / 2),
          width: medida.width,
          height: medida.height,
          child: IgnorePointer(
            child: PilaFichas(monto: monto, diametro: diametro),
          ),
        ),
      );
    }

    if (mesa.fase == FaseMesa.apostando) {
      pila(
        g.lugarApuesta(0, 1),
        mesa.apuesta - _enVueloHacia(0),
        _diametroPila(1),
        llave: const ValueKey('pila0'),
      );
    } else {
      final k = mesa.manos.length;
      for (final (i, mano) in mesa.manos.indexed) {
        final monto = _pagando
            ? _pilasPago[i] ?? 0
            : mano.apuesta - _enVueloHacia(i);
        pila(
          g.lugarApuesta(i, k),
          monto,
          _diametroPila(k),
          llave: ValueKey('pila$i'),
        );
      }
    }
    final seguro = _pagando
        ? _pilaSeguroPago
        : (_seguroPerdido ? 0 : mesa.seguro - _enVueloHacia(-1));
    if (seguro > 0) {
      pila(g.seguro, seguro, 24, llave: const ValueKey('pilaSeguro'));
    }
    return piezas;
  }

  List<Widget> _cartas(_Geometria g) {
    final mesa = _mesa;
    final origen = g.sabot.center;
    final duracion = _dur(390);
    if (_descartando.isNotEmpty) {
      return [
        for (final quieta in _descartando)
          CartaEnVuelo(
            key: ValueKey(quieta.carta.id),
            carta: quieta.carta,
            ancho: g.carta,
            origen: origen,
            centro: g.descarte.center,
            giro: (quieta.carta.id % 7 - 3) * .06,
            escala: .74,
            bocaArriba: false,
            desvanecer: true,
            duracion: _dur(460),
          ),
      ];
    }
    final dealer = mesa.crupier.cartas;
    final k = mesa.manos.length;
    // Cada carta nueva suena al salir del sabot y otra vez al caer; la
    // tapada del crupier, al darse vuelta.
    void sale() => _sonar(SonidoMesa.cartaSale, volumen: .75);
    void cae() => _sonar(SonidoMesa.cartaCae);
    void voltea() => _sonar(SonidoMesa.voltear);
    return [
      for (final (i, carta) in dealer.indexed)
        CartaEnVuelo(
          key: ValueKey(carta.id),
          carta: carta,
          ancho: g.carta,
          origen: origen,
          centro: g.cartaCrupier(i, dealer.length),
          giro: (i - (dealer.length - 1) / 2) * .02,
          bocaArriba: i != 1 || mesa.ocultaRevelada,
          duracion: duracion,
          alSalir: sale,
          alAterrizar: cae,
          alVoltear: voltea,
        ),
      for (final (m, mano) in mesa.manos.indexed)
        for (final (i, carta) in mano.cartas.indexed)
          () {
            final lugar = g.cartaJugador(
              m,
              k,
              i,
              mano.cartas.length,
              activa: m == mesa.manoActual && mesa.fase == FaseMesa.jugando,
              doblada: mano.doblada,
            );
            return CartaEnVuelo(
              key: ValueKey(carta.id),
              carta: carta,
              ancho: g.carta,
              origen: origen,
              centro: lugar.centro,
              giro: lugar.giro,
              escala: g.escala(k),
              duracion: duracion,
              alSalir: sale,
              alAterrizar: cae,
            );
          }(),
    ];
  }

  List<Widget> _totales(_Geometria g) {
    final mesa = _mesa;
    if (_descartando.isNotEmpty) return const [];
    final piezas = <Widget>[];
    final visible = mesa.cartaVisible;
    if (visible != null && mesa.crupier.cartas.length >= 2) {
      final revelada = mesa.ocultaRevelada;
      piezas.add(
        _centrado(
          g.totalCrupier,
          _InsigniaTotal(
            texto: revelada
                ? mesa.crupier.totalDicho
                : (visible.esAs ? '1 / 11' : '${visible.valor}'),
            tono: revelada ? _tonoDe(mesa.crupier) : _Tono.normal,
          ),
        ),
      );
    }
    final k = mesa.manos.length;
    for (final (i, mano) in mesa.manos.indexed) {
      if (mano.cartas.isEmpty) continue;
      piezas.add(
        _centrado(
          Offset(g.anclaX(i, k), g.topeMano(k) - 16),
          _InsigniaTotal(texto: mano.totalDicho, tono: _tonoDe(mano)),
        ),
      );
    }
    return piezas;
  }

  _Tono _tonoDe(Mano mano) {
    if (mano.sePaso) return _Tono.mal;
    if (mano.total == 21) return _Tono.oro;
    return _Tono.normal;
  }

  List<Widget> _cartelesResultado(_Geometria g) {
    final mesa = _mesa;
    final k = mesa.manos.length;
    return [
      for (final (i, resultado) in mesa.resultados.indexed)
        _centrado(
          Offset(g.anclaX(i, k), g.manoJugadorCentroY - 4),
          _CartelResultado(resultado: resultado, chico: k > 2),
          lado: 170,
        ),
    ];
  }

  /// Un widget centrado en un punto de la mesa.
  static Widget _centrado(Offset centro, Widget hijo, {double lado = 130}) =>
      Positioned(
        left: centro.dx - lado / 2,
        top: centro.dy - lado / 2,
        width: lado,
        height: lado,
        child: IgnorePointer(child: Center(child: hijo)),
      );

  // ============================================================== controles
  Widget _panelControles() {
    final mesa = _mesa;
    final (clave, contenido) = switch (mesa.fase) {
      FaseMesa.apostando when mesa.enQuiebra && _vuelos.isEmpty => (
        'quiebra',
        _panelQuiebra(),
      ),
      FaseMesa.apostando => ('apuesta', _panelApuesta()),
      FaseMesa.seguro => ('seguro', _panelSeguro()),
      FaseMesa.jugando => ('juego', _panelJuego()),
      FaseMesa.resultado => ('resultado', _panelResultado()),
      FaseMesa.repartiendo => ('espera', _panelEspera('Repartiendo…')),
      FaseMesa.crupier => ('espera', _panelEspera('MacIAs juega su mano…')),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF0141110),
        border: Border(
          top: BorderSide(color: ColoresCarta.oro.withValues(alpha: .35)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: AnimatedSwitcher(
              duration: _dur(240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (hijo, animacion) => FadeTransition(
                opacity: animacion,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, .14),
                    end: Offset.zero,
                  ).animate(animacion),
                  child: hijo,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(clave), child: contenido),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panelApuesta() {
    final mesa = _mesa;
    final libre = !_ocupado;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final valor in MesaBlackjack.valoresFichas)
              _FichaRack(
                llave: _llavesRack[valor]!,
                valor: valor,
                habilitada: libre && mesa.puedeSumar(valor),
                alTocar: () => _apostar(valor),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _BotonMesa(
              texto: 'Borrar',
              icono: Icons.delete_outline_rounded,
              chico: true,
              alPresionar: libre && mesa.apuesta > 0
                  ? () => _ajustarApuesta(mesa.borrarApuesta)
                  : null,
            ),
            const SizedBox(width: 8),
            if (mesa.apuesta == 0)
              _BotonMesa(
                texto: 'Repetir',
                icono: Icons.replay_rounded,
                chico: true,
                alPresionar: libre && mesa.puedeRepetir
                    ? () => _ajustarApuesta(mesa.repetir)
                    : null,
              )
            else
              _BotonMesa(
                texto: 'x2',
                chico: true,
                alPresionar: libre && mesa.puedeDoblarApuesta
                    ? () => _ajustarApuesta(mesa.doblarApuesta)
                    : null,
              ),
            const SizedBox(width: 8),
            _BotonMesa(
              texto: 'Todo',
              icono: Icons.all_inclusive_rounded,
              chico: true,
              alPresionar: libre && mesa.puedeIrConTodo
                  ? () => _ajustarApuesta(mesa.irConTodo)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BotonMesa(
                texto: 'Repartir',
                icono: Icons.style_rounded,
                estilo: _Estilo.principal,
                alPresionar: libre && mesa.puedeRepartir ? _repartir : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _panelQuiebra() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Te quedaste sin fichas',
        style: TextStyle(
          color: ConfiguracionTema.crema,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        'MacIAs te presta 1.000 para seguir. Sin intereses.',
        style: TextStyle(
          color: ConfiguracionTema.crema.withValues(alpha: .65),
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
      const SizedBox(height: 12),
      _BotonMesa(
        texto: 'Aceptar 1.000 fichas',
        icono: Icons.volunteer_activism_rounded,
        estilo: _Estilo.principal,
        alPresionar: _rescatar,
      ),
    ],
  );

  Widget _panelSeguro() {
    final mesa = _mesa;
    final libre = !_ocupado;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          mesa.puedeAsegurar
              ? 'MacIAs muestra un As. ¿Te aseguras por ${conMiles(mesa.costoSeguro)}?'
              : 'MacIAs muestra un As. No te alcanzan las fichas para el seguro.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ConfiguracionTema.crema,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Si tiene blackjack, el seguro paga 2 a 1.',
          style: TextStyle(
            color: ConfiguracionTema.crema.withValues(alpha: .6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BotonMesa(
                texto: 'No, gracias',
                estilo: _Estilo.secundario,
                resaltado: _consejoSeguro,
                alPresionar: libre ? () => _seguro(tomar: false) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BotonMesa(
                texto: 'Seguro',
                icono: Icons.shield_rounded,
                estilo: _Estilo.principal,
                alPresionar: libre && mesa.puedeAsegurar
                    ? () => _seguro(tomar: true)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            _BotonPista(alPresionar: libre ? _pista : null),
          ],
        ),
      ],
    );
  }

  Widget _panelJuego() {
    final mesa = _mesa;
    final libre = !_ocupado;
    final sugerida = _consejo?.jugada;
    VoidCallback? si(Jugada jugada) =>
        libre && mesa.puede(jugada) ? () => _accion(jugada) : null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _BotonMesa(
                texto: 'Pedir',
                icono: Icons.add_rounded,
                estilo: _Estilo.principal,
                alto: 50,
                resaltado: sugerida == Jugada.pedir,
                alPresionar: si(Jugada.pedir),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BotonMesa(
                texto: 'Plantarse',
                icono: Icons.front_hand_rounded,
                estilo: _Estilo.secundario,
                alto: 50,
                resaltado: sugerida == Jugada.plantarse,
                alPresionar: si(Jugada.plantarse),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _BotonMesa(
                texto: 'Doblar',
                icono: Icons.keyboard_double_arrow_up_rounded,
                chico: true,
                resaltado: sugerida == Jugada.doblar,
                alPresionar: si(Jugada.doblar),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _BotonMesa(
                texto: 'Dividir',
                icono: Icons.call_split_rounded,
                chico: true,
                resaltado: sugerida == Jugada.dividir,
                alPresionar: si(Jugada.dividir),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _BotonMesa(
                texto: 'Rendirse',
                icono: Icons.flag_rounded,
                chico: true,
                resaltado: sugerida == Jugada.rendirse,
                alPresionar: si(Jugada.rendirse),
              ),
            ),
            const SizedBox(width: 7),
            _BotonPista(alPresionar: libre ? _pista : null),
          ],
        ),
      ],
    );
  }

  Widget _panelEspera(String texto) => Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColoresCarta.oro,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          texto,
          style: TextStyle(
            color: ConfiguracionTema.crema.withValues(alpha: .75),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );

  Widget _panelResultado() {
    final mesa = _mesa;
    final neto = mesa.netoRonda;
    final (resumen, color) = switch (neto) {
      > 0 => ('Ganaste ${conMiles(neto)} fichas', ColoresCarta.oroClaro),
      < 0 => ('Perdiste ${conMiles(-neto)} fichas', const Color(0xFFF08A80)),
      _ => ('Quedaste igual', ConfiguracionTema.crema),
    };
    final libre = !_ocupado && _vuelos.isEmpty;
    final puedeRepetir =
        mesa.ultimaApuesta >= MesaBlackjack.apuestaMinima &&
        mesa.ultimaApuesta <=
            math.min(mesa.fichas, MesaBlackjack.apuestaMaxima);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          resumen,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BotonMesa(
                texto: 'Nueva mano',
                icono: Icons.refresh_rounded,
                estilo: _Estilo.secundario,
                alPresionar: libre ? _nuevaMano : null,
              ),
            ),
            if (puedeRepetir) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _BotonMesa(
                  texto: 'Repetir ${conMiles(mesa.ultimaApuesta)}',
                  icono: Icons.replay_rounded,
                  estilo: _Estilo.principal,
                  alPresionar: libre ? () => _nuevaMano(repetir: true) : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Piezas de la mesa
// ---------------------------------------------------------------------------
class _BarraMesa extends StatelessWidget {
  const _BarraMesa({
    required this.llaveFichas,
    required this.fichas,
    required this.alMenu,
  });

  final GlobalKey llaveFichas;
  final int fichas;
  final VoidCallback alMenu;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Salir de la mesa',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded, color: ConfiguracionTema.crema),
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mesa de MacIAs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ConfiguracionTema.crema,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                'Blackjack · 6 mazos',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0x99E6E1D5),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        _PildoraFichas(key: llaveFichas, fichas: fichas),
        IconButton(
          tooltip: 'Más opciones',
          onPressed: alMenu,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: ConfiguracionTema.crema,
          ),
        ),
      ],
    ),
  );
}

/// Tus fichas: el numero corre hasta el nuevo valor.
class _PildoraFichas extends StatelessWidget {
  const _PildoraFichas({required this.fichas, super.key});

  final int fichas;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tus fichas: $fichas',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1714),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresCarta.oro.withValues(alpha: .75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FichaDibujada(valor: 1000, diametro: 22),
          const SizedBox(width: 7),
          TweenAnimationBuilder<double>(
            tween: Tween(end: fichas.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, valor, _) => Text(
              conMiles(valor.round()),
              style: const TextStyle(
                color: ColoresCarta.oroClaro,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// El sabot, con lo que queda.
class _SabotEnMesa extends StatelessWidget {
  const _SabotEnMesa({required this.quedan, required this.barajando});

  final int quedan;
  final bool barajando;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Sabot: quedan $quedan cartas',
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (barajando)
            const BoxShadow(
              color: Color(0x99F2CC5C),
              blurRadius: 22,
              spreadRadius: 2,
            ),
        ],
      ),
      child: const RepaintBoundary(
        child: CustomPaint(painter: PintorSabot(), size: Size.infinite),
      ),
    ),
  );
}

/// Las cartas ya jugadas, boca abajo.
class _Descarte extends StatelessWidget {
  const _Descarte({required this.cuantas});

  final int cuantas;

  @override
  Widget build(BuildContext context) {
    final capas = cuantas == 0 ? 0 : math.min(6, 1 + cuantas ~/ 10);
    return LayoutBuilder(
      builder: (context, caja) => Stack(
        clipBehavior: Clip.none,
        children: [
          if (capas == 0)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ConfiguracionTema.crema.withValues(alpha: .18),
                ),
              ),
            ),
          for (var i = 0; i < capas; i++)
            Positioned(
              left: 0,
              top: -i * 1.6,
              child: Transform.rotate(
                angle: (i.isEven ? -1 : 1) * .03 * i,
                child: CartaDibujada(ancho: caja.maxWidth),
              ),
            ),
        ],
      ),
    );
  }
}

/// La barajada: las cartas salen del sabot, se mezclan y vuelven.
class _Barajada extends StatefulWidget {
  const _Barajada({required this.g, required this.duracion});

  final _Geometria g;
  final Duration duracion;

  @override
  State<_Barajada> createState() => _BarajadaState();
}

class _BarajadaState extends State<_Barajada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _mezcla = AnimationController(
    vsync: this,
    duration: widget.duracion,
  )..forward();

  static const _cuantas = 10;

  @override
  void dispose() {
    _mezcla.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    final ancho = g.carta * .7;
    final alto = ancho * 1.4;
    final sabot = g.sabot.center;
    final centro = Offset(g.mesa.center.dx, g.manoCrupierY + g.altoCarta / 2);
    final dorso = CartaDibujada(ancho: ancho);
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _mezcla,
          builder: (context, _) {
            final t = _mezcla.value;
            return Stack(
              children: [
                for (var i = 0; i < _cuantas; i++)
                  () {
                    final lado = i.isEven ? -1.0 : 1.0;
                    final pila = centro + Offset(lado * g.carta * .75, 0);
                    final retraso = i * .025;
                    final ida = Curves.easeOutCubic.transform(
                      ((t - retraso) / .3).clamp(0.0, 1.0),
                    );
                    final mezcla = Curves.easeInOutCubic.transform(
                      ((t - .35 - i * .02) / .25).clamp(0.0, 1.0),
                    );
                    final vuelta = Curves.easeInCubic.transform(
                      ((t - .72) / .26).clamp(0.0, 1.0),
                    );
                    var p = Offset.lerp(sabot, pila, ida)!;
                    p = Offset.lerp(p, centro + Offset(0, -i * 1.5), mezcla)!;
                    p = Offset.lerp(p, sabot, vuelta)!;
                    final giro = lado * .25 * ida * (1 - mezcla);
                    return Positioned(
                      left: 0,
                      top: 0,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.translationValues(
                          p.dx - ancho / 2,
                          p.dy - alto / 2,
                          0,
                        )..rotateZ(giro),
                        child: Opacity(
                          opacity: t < .02 || vuelta > .97 ? 0 : 1,
                          child: dorso,
                        ),
                      ),
                    );
                  }(),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _Tono { normal, oro, mal }

/// El total de una mano, en una pildora que salta cuando cambia.
class _InsigniaTotal extends StatelessWidget {
  const _InsigniaTotal({required this.texto, required this.tono});

  final String texto;
  final _Tono tono;

  @override
  Widget build(BuildContext context) {
    final (fondo, color) = switch (tono) {
      _Tono.oro => (ColoresCarta.oroClaro, const Color(0xFF2B1E05)),
      _Tono.mal => (const Color(0xFFB3261E), Colors.white),
      _Tono.normal => (const Color(0xE6141210), const Color(0xFFF7E7B5)),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (hijo, animacion) =>
          ScaleTransition(scale: animacion, child: hijo),
      child: Container(
        key: ValueKey('$texto$tono'),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColoresCarta.oro.withValues(alpha: .7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

/// "BLACKJACK", "GANASTE", "TE PASASTE": entra con un rebote.
class _CartelResultado extends StatelessWidget {
  const _CartelResultado({required this.resultado, this.chico = false});

  final ResultadoMano resultado;
  final bool chico;

  @override
  Widget build(BuildContext context) {
    final (texto, colores, letra) = switch (resultado.desenlace) {
      Desenlace.blackjack => (
        'BLACKJACK',
        const [ColoresCarta.oroClaro, ColoresCarta.oro],
        const Color(0xFF2B1E05),
      ),
      Desenlace.gana => (
        'GANASTE',
        const [Color(0xFF43A047), Color(0xFF1B5E20)],
        Colors.white,
      ),
      Desenlace.empata => (
        'EMPATE',
        const [Color(0xFFF3EBDD), Color(0xFFCFC6B6)],
        const Color(0xFF2E2A26),
      ),
      Desenlace.pierde => (
        'PIERDES',
        const [Color(0xFFC62828), Color(0xFF7F1416)],
        Colors.white,
      ),
      Desenlace.sePaso => (
        'TE PASASTE',
        const [Color(0xFFC62828), Color(0xFF7F1416)],
        Colors.white,
      ),
      Desenlace.rendida => (
        'RENDIDO',
        const [Color(0xFF8D8A85), Color(0xFF55524E)],
        Colors.white,
      ),
    };
    final neto = resultado.neto;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, t, hijo) => Transform.scale(scale: t, child: hijo),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: chico ? 9 : 14,
          vertical: chico ? 4 : 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colores,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .55)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              style: TextStyle(
                color: letra,
                fontWeight: FontWeight.w900,
                fontSize: chico ? 11.5 : 15,
                letterSpacing: 1.2,
                height: 1.1,
              ),
            ),
            if (neto != 0)
              Text(
                '${neto > 0 ? '+' : '-'}${conMiles(neto.abs())}',
                style: TextStyle(
                  color: letra.withValues(alpha: .85),
                  fontWeight: FontWeight.w900,
                  fontSize: chico ? 10.5 : 12.5,
                  height: 1.15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Una ficha del estante: se toca y vuela a la apuesta.
class _FichaRack extends StatelessWidget {
  const _FichaRack({
    required this.llave,
    required this.valor,
    required this.habilitada,
    required this.alTocar,
  });

  final GlobalKey llave;
  final int valor;
  final bool habilitada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: habilitada,
    label: 'Apostar ${conMiles(valor)}',
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: habilitada ? 1 : .3,
      child: EscalaAlPresionar(
        escala: .88,
        builder: (context, alResaltar) => Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: habilitada ? alTocar : null,
            onHighlightChanged: alResaltar,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: SizedBox.square(
                key: llave,
                dimension: 50,
                child: FichaDibujada(valor: valor, diametro: 50),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

enum _Estilo { principal, secundario, terciario }

class _BotonMesa extends StatelessWidget {
  const _BotonMesa({
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.estilo = _Estilo.terciario,
    this.resaltado = false,
    this.chico = false,
    this.alto,
    this.etiqueta,
  });

  final String texto;
  final IconData? icono;
  final VoidCallback? alPresionar;
  final _Estilo estilo;

  /// MacIAs lo recomienda: brilla.
  final bool resaltado;
  final bool chico;
  final double? alto;

  /// Lo que lee el lector de pantalla, si el boton es solo un icono.
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final habilitado = alPresionar != null;
    final altura = alto ?? (chico ? 40.0 : 46.0);
    final color = switch (estilo) {
      _Estilo.principal => const Color(0xFF2B1E05),
      _Estilo.secundario => const Color(0xFF2E2A26),
      _Estilo.terciario => ConfiguracionTema.crema,
    };
    final radio = BorderRadius.circular(altura / 2);
    Widget boton = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: habilitado ? 1 : .35,
      child: EscalaAlPresionar(
        escala: .95,
        builder: (context, alResaltar) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: estilo == _Estilo.principal
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ColoresCarta.oroClaro, ColoresCarta.oro],
                  )
                : null,
            color: switch (estilo) {
              _Estilo.principal => null,
              _Estilo.secundario => const Color(0xFFF3EBDD),
              _Estilo.terciario => const Color(0x14FFFFFF),
            },
            borderRadius: radio,
            border: estilo == _Estilo.terciario
                ? Border.all(
                    color: ConfiguracionTema.crema.withValues(alpha: .4),
                  )
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radio,
              onTap: habilitado
                  ? () {
                      RetroalimentacionHaptica.accion();
                      alPresionar!();
                    }
                  : null,
              onHighlightChanged: alResaltar,
              child: SizedBox(
                height: altura,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: chico ? 11 : 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icono != null)
                        Icon(icono, size: chico ? 16 : 19, color: color),
                      if (icono != null && texto.isNotEmpty)
                        SizedBox(width: chico ? 4 : 7),
                      if (texto.isNotEmpty)
                        Flexible(
                          child: Text(
                            texto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: chico ? 13 : 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (resaltado && habilitado) {
      boton = _Brillo(radio: radio, child: boton);
    }
    final nombre = etiqueta ?? texto;
    return Semantics(
      button: true,
      enabled: habilitado,
      label: resaltado ? '$nombre (lo que haría MacIAs)' : nombre,
      excludeSemantics: true,
      child: boton,
    );
  }
}

/// El boton de la pista: "¿qué haría MacIAs?".
class _BotonPista extends StatelessWidget {
  const _BotonPista({required this.alPresionar});

  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '¿Qué haría MacIAs?',
    child: _BotonMesa(
      texto: '',
      etiqueta: '¿Qué haría MacIAs?',
      icono: Icons.lightbulb_rounded,
      chico: true,
      alPresionar: alPresionar,
    ),
  );
}

/// Un brillo dorado que late alrededor de lo que MacIAs recomienda.
class _Brillo extends StatefulWidget {
  const _Brillo({required this.radio, required this.child});

  final BorderRadius radio;
  final Widget child;

  @override
  State<_Brillo> createState() => _BrilloState();
}

class _BrilloState extends State<_Brillo> with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _latido,
    child: widget.child,
    builder: (context, hijo) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.radio,
        boxShadow: [
          BoxShadow(
            color: ColoresCarta.oroClaro.withValues(
              alpha: .35 + .45 * _latido.value,
            ),
            blurRadius: 8 + 10 * _latido.value,
            spreadRadius: 1 + 2 * _latido.value,
          ),
        ],
      ),
      child: hijo,
    ),
  );
}

class _OpcionMenu extends StatelessWidget {
  const _OpcionMenu({
    required this.icono,
    required this.titulo,
    required this.alTocar,
    this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icono, color: ColoresCarta.oroClaro),
    title: Text(
      titulo,
      style: const TextStyle(
        color: ConfiguracionTema.crema,
        fontWeight: FontWeight.w800,
      ),
    ),
    subtitle: detalle == null
        ? null
        : Text(
            detalle!,
            style: TextStyle(
              color: ConfiguracionTema.crema.withValues(alpha: .6),
            ),
          ),
    onTap: alTocar,
  );
}

class _TituloHoja extends StatelessWidget {
  const _TituloHoja(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      texto,
      style: const TextStyle(
        color: ColoresCarta.oroClaro,
        fontWeight: FontWeight.w900,
        fontSize: 20,
      ),
    ),
  );
}

class _Regla extends StatelessWidget {
  const _Regla(this.titulo, this.detalle);

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: ConfiguracionTema.crema,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detalle,
          style: TextStyle(
            color: ConfiguracionTema.crema.withValues(alpha: .72),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}
