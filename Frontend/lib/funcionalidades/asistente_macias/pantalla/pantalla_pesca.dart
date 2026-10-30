import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/interaccion/frecuencia_pantalla.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/bono_pesca.dart';
import '../diseno/cartas_blackjack.dart';
import '../diseno/crupier_macias.dart';
import '../diseno/dibujos_pesca.dart';
import '../diseno/fichas_blackjack.dart';
import '../diseno/mesa_casino.dart';
import '../diseno/rueda_pesca.dart';
import '../diseno/tablero_pesca.dart';
import '../logica/almacen_casino.dart';
import '../logica/casino.dart';
import '../logica/frases_casino.dart';
import '../logica/mesa_pesca.dart';
import '../logica/sonidos_casino.dart';

/// La pesca en el hielo del casino de MacIAs.
///
/// Se apuesta al hielo (blanco o azul, paga 1 a 1) o a los peces. Antes de
/// girar caen bolas de nieve sobre algunos hielos, que multiplican lo que
/// pagan, y en algunas rondas una moneda de oro, que multiplica un pez. La
/// rueda gira, la aguja golpea en cada casilla y, si para en un pez, MacIAs
/// sale a pescarlo: lo que vale el pez es lo que paga. La ronda entera sale
/// del azar del telefono antes de empezar; la rueda y la caña solo la
/// muestran.
class PantallaPesca extends StatefulWidget {
  const PantallaPesca({
    this.nombre = '',
    this.almacen,
    this.sonidos,
    this.azar,
    this.tiradas,
    super.key,
  });

  /// Como llamar a quien juega.
  final String nombre;

  /// Donde se guardan las fichas (las del casino). Sin indicarlo, en
  /// memoria (pruebas).
  final AlmacenCasino? almacen;

  /// Lo que suena. Sin indicarlo, los sonidos del telefono o del navegador.
  final SonidosMesa? sonidos;
  final math.Random? azar;

  /// Para las pruebas: las rondas que van a salir, en orden.
  final List<TiradaPesca>? tiradas;

  static Route<void> ruta({
    String nombre = '',
    AlmacenCasino? almacen,
    SonidosMesa? sonidos,
  }) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) =>
        PantallaPesca(nombre: nombre, almacen: almacen, sonidos: sonidos),
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
  State<PantallaPesca> createState() => _PantallaPescaState();
}

enum _Fase { apostando, sorteando, girando, pescando, pagando }

/// Fichas en el aire.
class _Vuelo {
  _Vuelo({
    required this.id,
    required this.desde,
    required this.hasta,
    required this.monto,
    required this.retraso,
    required this.duracion,
    this.desvanecer = false,
    this.alLlegar,
  });

  final int id;
  final Offset desde;
  final Offset hasta;
  final int monto;
  final Duration retraso;
  final Duration duracion;
  final bool desvanecer;
  final VoidCallback? alLlegar;
}

/// Una bola de nieve que vuela del centro de la rueda a su hielo. Los
/// tiempos van en segundos del reloj de la pantalla.
class _Bola {
  _Bola({
    required this.casilla,
    required this.por,
    required this.desde,
    required this.hasta,
    required this.inicio,
    required this.dura,
    required this.diametro,
  });

  final int casilla;
  final int por;
  final Offset desde;
  final Offset hasta;
  final double inicio;
  final double dura;
  final double diametro;
  bool llego = false;
}

/// La nieve que salta donde cae una bola.
class _Salpicon {
  _Salpicon({
    required this.donde,
    required this.inicio,
    required this.dura,
    required this.radio,
    required this.giro,
  });

  final Offset donde;
  final double inicio;
  final double dura;
  final double radio;
  final double giro;
}

/// La rueda girando hacia donde tiene que parar.
class _Giro {
  _Giro({
    required this.desde,
    required this.hasta,
    required this.inicio,
    required this.dura,
  });

  final double desde;
  final double hasta;
  final double inicio;
  final double dura;
  final fin = Completer<void>();

  /// Frena desde el primer momento, cada vez mas despacio: al final se
  /// arrastra por las ultimas casillas.
  double angulo(double s) =>
      desde + (hasta - desde) * (1 - math.pow(1 - s, 3).toDouble());

  /// Cuantas casillas por segundo pasan bajo la aguja.
  double casillasPorSegundo(double s) =>
      (hasta - desde) * 3 * (1 - s) * (1 - s) / dura / MedidasRueda.casilla;
}

/// El bono que se esta mostrando.
typedef _Bono = ({Pez pez, double pesca, int moneda, int apostado, int premio});

/// Donde va cada cosa, segun el tamaño de la pantalla.
class _Disposicion {
  _Disposicion(Size s) {
    final w = s.width;
    final h = s.height;
    controles = (h * .2).clamp(150.0, 172.0);
    cabecera = (h * .135).clamp(92.0, 124.0);
    const arriba = altoBarra;
    avatar = (cabecera - 34).clamp(56.0, 80.0);
    retrato = Rect.fromLTWH(12, arriba + 4, avatar, avatar);
    dialogo = Rect.fromLTRB(
      retrato.right + 10,
      arriba + 2,
      w - 10,
      arriba + cabecera - 28,
    );
    historial = Rect.fromLTRB(
      retrato.right + 10,
      arriba + cabecera - 24,
      w - 10,
      arriba + cabecera,
    );
    tablero = Rect.fromLTRB(
      8,
      h - controles - altoTablero - 4,
      w - 8,
      h - controles - 4,
    );
    escena = Rect.fromLTRB(0, arriba + cabecera + 2, w, tablero.top - 6);
    final diametro = math.max(
      120.0,
      math.min(math.min(w - 20, escena.height - 14), 470.0),
    );
    rueda = Rect.fromCenter(
      center: escena.center,
      width: diametro,
      height: diametro,
    );
  }

  static const altoBarra = 58.0;
  static const altoTablero = 92.0;
  late final double controles;
  late final double cabecera;
  late final double avatar;
  late final Rect retrato;
  late final Rect dialogo;
  late final Rect historial;
  late final Rect tablero;
  late final Rect escena;
  late final Rect rueda;

  /// Donde MacIAs junta y paga las fichas.
  Offset get banca => retrato.center;
}

class _PantallaPescaState extends State<PantallaPesca>
    with TickerProviderStateMixin {
  static const _fondo = Color(0xFF06111A);

  /// Lo que suena en la pesca: lo demas del casino ni se carga.
  static const _sonidosDeLaMesa = {
    SonidoMesa.ficha,
    SonidoMesa.fichas,
    SonidoMesa.cobrar,
    SonidoMesa.boton,
    SonidoMesa.vozCorta,
    SonidoMesa.vozMedia,
    SonidoMesa.vozLarga,
    SonidoMesa.ganar,
    SonidoMesa.blackjack,
    SonidoMesa.perder,
    SonidoMesa.ruedaGira,
    SonidoMesa.aguja,
    SonidoMesa.nieve,
    SonidoMesa.hielo,
    SonidoMesa.moneda,
    SonidoMesa.carrete,
    SonidoMesa.chapuzon,
    SonidoMesa.burbujas,
    SonidoMesa.grua,
    SonidoMesa.helicoptero,
    SonidoMesa.robot,
    SonidoMesa.trago,
  };

  /// La ronda sale del azar seguro del telefono.
  late final math.Random _azar = widget.azar ?? math.Random.secure();

  /// Para lo que no decide nada (por donde para dentro de la casilla, que
  /// frase dice).
  final _azarVisual = math.Random();
  late final FrasesPesca _frases = FrasesPesca(
    azar: _azarVisual,
    nombre: widget.nombre,
  );
  late final AlmacenCasino _almacen =
      widget.almacen ?? AlmacenCasinoEnMemoria();
  late final SonidosMesa _sonidos =
      widget.sonidos ?? SonidosMesa.delSistema(solo: _sonidosDeLaMesa);
  bool _conSonido = true;
  bool _rapido = false;
  bool _sinMovimiento = false;
  int _tiradasUsadas = 0;

  MesaPesca? _mesaCargada;
  MesaPesca get _mesa => _mesaCargada!;
  var _fase = _Fase.apostando;

  /// La ficha elegida en el estante.
  int _ficha = 10;

  /// Esta elegida la ficha ALL IN: la proxima apuesta lleva todas tus fichas.
  bool _todo = false;

  // MacIAs.
  String? _dicho;
  int _latido = 0;
  ExpresionCrupier _expresion = ExpresionCrupier.normal;
  bool _hablando = false;
  Timer? _callar;
  bool _avisoFuerte = false;

  // La rueda.
  late final Ticker _reloj = createTicker(_alTick);

  /// Los segundos desde que se abrio la mesa: mueven la nieve, las bolas y
  /// el giro.
  final _segundos = ValueNotifier<double>(0);
  final _giro = ValueNotifier<double>(0);
  final _efectos = EfectosRueda();
  _Giro? _giroEnCurso;
  int _ultimoCruce = 0;
  double _velocidadAguja = 0;
  bool _ruedaSonando = false;

  /// Las bolas de nieve y la moneda que ya cayeron sobre la rueda.
  Multiplicadores _visibles = Multiplicadores.ninguno;
  final _bolas = <_Bola>[];
  final _salpicones = <_Salpicon>[];
  String? _textoMoneda;
  late final AnimationController _moneda = AnimationController(vsync: this)
    ..addListener(_moverMoneda);

  /// La casilla que salio: su cubo de hielo o su brillo.
  int? _salio;
  late final AnimationController _marca = AnimationController(vsync: this)
    ..addListener(() => _efectos.marcar(_salio, _marca.value));
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // El bono.
  _Bono? _bono;
  int _bonos = 0;
  Completer<void>? _finDelBono;
  late final AnimationController _velo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// Lo que salio, grande, mientras MacIAs lo canta.
  ({Casilla casilla, double? paga})? _cartel;

  // El tablero.
  Casilla? _ganadoraTablero;
  String? _aviso;
  Timer? _borrarAviso;
  ResultadoPesca? _ultimo;

  // Las fichas que viajan.
  final _vuelos = <_Vuelo>[];
  int _siguienteVuelo = 0;
  final _enVuelo = <Casilla, int>{};
  int _porLlegar = 0;
  Map<Casilla, int>? _pilasPago;

  final _llaveCuerpo = GlobalKey();
  final _llaveFichas = GlobalKey();
  final _llavesRack = {
    for (final valor in [...Casino.valoresFichas, valorTodo])
      valor: GlobalKey(),
  };
  final _llavesCasillas = {for (final c in Casilla.values) c: GlobalKey()};
  _Disposicion? _d;

  double get _ritmo => _sinMovimiento ? .05 : (_rapido ? .6 : 1);

  /// [segundos] al ritmo de la mesa.
  double _s(double segundos) => segundos * _ritmo;

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
    // La rueda espera quieta, cada vez en otro lugar.
    _giro.value =
        _azarVisual.nextInt(RuedaPesca.cantidad) * MedidasRueda.casilla;
    unawaited(_reloj.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.disableAnimationsOf(context);
    unawaited(precacheImage(const AssetImage(rutaFotoCrupier), context));
  }

  Future<void> _cargar() async {
    final fichas = await _almacen.fichas();
    final datos = await _almacen.juego('pesca');
    final conSonido = await _almacen.conSonido();
    if (!mounted) return;
    final mesa = MesaPesca.desdeJson(datos, fichas: fichas);
    setState(() {
      _conSonido = conSonido;
      _mesaCargada = mesa;
      _ficha = _fichaQueAlcanza(_ficha);
    });
    _momento(
      mesa.estadisticas.giros > 0
          ? MomentoPesca.bienvenidaDeVuelta
          : MomentoPesca.bienvenida,
    );
  }

  @override
  void dispose() {
    _callar?.cancel();
    _borrarAviso?.cancel();
    _voz.terminar();
    _reloj.dispose();
    _moneda.dispose();
    _marca.dispose();
    _zoom.dispose();
    _velo.dispose();
    _segundos.dispose();
    _giro.dispose();
    _efectos.dispose();
    unawaited(_sonidos.liberar());
    unawaited(FrecuenciaPantalla.pedirAlta(activar: false));
    // Lo que esta en el tablero vuelve a tus fichas: si se va a mitad de una
    // ronda, la ronda no cuenta.
    final mesa = _mesaCargada;
    if (mesa != null) unawaited(_guardarMesa(mesa));
    super.dispose();
  }

  Future<void> _guardarMesa(MesaPesca mesa) => Future.wait([
    _almacen.guardarFichas(mesa.total),
    _almacen.guardarJuego('pesca', mesa.aJson()),
  ]);

  // ================================================================== reloj
  void _alTick(Duration transcurrido) {
    final ahora = transcurrido.inMicroseconds / 1e6;
    final dt = ahora - _segundos.value;
    _segundos.value = ahora;
    final giro = _giroEnCurso;
    if (giro != null) {
      final s = ((ahora - giro.inicio) / giro.dura).clamp(0.0, 1.0);
      _giro.value = giro.angulo(s);
      _moverAguja(dt, giro.casillasPorSegundo(s));
      if (s >= 1) {
        _giroEnCurso = null;
        _callarRueda();
        giro.fin.complete();
      }
    } else if (_efectos.aguja != 0 || _velocidadAguja != 0) {
      // La aguja termina de vibrar sola.
      _moverAguja(dt, 0);
    }
    if (_bolas.isNotEmpty) {
      for (final bola in _bolas) {
        if (!bola.llego && ahora >= bola.inicio + bola.dura) {
          bola.llego = true;
          _alCaerBola(bola);
        }
      }
      _bolas.removeWhere((b) => b.llego);
    }
    _salpicones.removeWhere((s) => ahora > s.inicio + s.dura);
  }

  /// La aguja es de goma: cada clavija la empuja al pasar y, al soltarla,
  /// vuelve como un resorte (se pasa un poco y vibra). Cada clavija suena;
  /// las primeras van tan rapido que suenan como una sola tanda (ver
  /// [SonidoMesa.ruedaGira]).
  void _moverAguja(double dt, double casillasPorSegundo) {
    final a = MedidasRueda.casilla;
    final posicion = _giro.value / a + .5;
    final cruce = posicion.floor();
    final enLaCasilla = posicion - cruce;
    var x = _efectos.aguja;
    var v = _velocidadAguja;
    if (dt > 0 && dt < .25) {
      const rigidez = 2600.0;
      const freno = 26.0;
      final pasos = math.max(1, (dt * 240).ceil());
      final h = dt / pasos;
      for (var i = 0; i < pasos; i++) {
        v += (-rigidez * x - freno * v) * h;
        x += v * h;
      }
    }
    // La clavija que viene empuja la punta.
    final empuje = casillasPorSegundo > 0 && enLaCasilla > .68
        ? (enLaCasilla - .68) / .32
        : 0.0;
    if (x < empuje) {
      x = empuje;
      v = 0;
    }
    if (x.abs() < .002 && v.abs() < .01) {
      x = 0;
      v = 0;
    }
    _velocidadAguja = v;
    _efectos.aguja = x.clamp(-.6, 1.0);
    if (cruce != _ultimoCruce) {
      _ultimoCruce = cruce;
      if (_giroEnCurso != null && casillasPorSegundo < 9) {
        _callarRueda();
        _sonar(SonidoMesa.aguja, volumen: .85);
        if (casillasPorSegundo < 3.5) RetroalimentacionHaptica.seleccion();
      }
    }
  }

  void _callarRueda() {
    if (!_ruedaSonando) return;
    _ruedaSonando = false;
    if (_conSonido) _sonidos.detener(SonidoMesa.ruedaGira);
  }

  void _moverMoneda() {
    final t = _moneda.value;
    _efectos.ponerMoneda(
      // Termina de cara: siete medias vueltas.
      giro: Curves.easeOutCubic.transform(t) * 7 * math.pi,
      texto: _textoMoneda,
      visible: (t / .12).clamp(0.0, 1.0),
    );
  }

  // ================================================================ ayudas
  int get _msPorLetra => (26 * _ritmo).round().clamp(1, 40);

  void _decir(
    String texto, {
    ExpresionCrupier expresion = ExpresionCrupier.normal,
  }) {
    if (!mounted) return;
    _callar?.cancel();
    _voz.terminar();
    setState(() {
      _dicho = texto;
      _latido++;
      _expresion = expresion;
    });
    final dura = texto.length * _msPorLetra + 2600 + texto.length * 24;
    _callar = Timer(Duration(milliseconds: dura), () {
      if (!mounted) return;
      setState(() {
        _dicho = null;
        _hablando = false;
        _expresion = ExpresionCrupier.normal;
      });
    });
  }

  static const _carasDe = <MomentoPesca, ExpresionCrupier>{
    MomentoPesca.bienvenida: ExpresionCrupier.risa,
    MomentoPesca.bienvenidaDeVuelta: ExpresionCrupier.guino,
    MomentoPesca.noVaMas: ExpresionCrupier.canchero,
    MomentoPesca.apuestaFuerte: ExpresionCrupier.sorprendido,
    MomentoPesca.todo: ExpresionCrupier.sorprendido,
    MomentoPesca.nieve: ExpresionCrupier.feliz,
    MomentoPesca.sinNada: ExpresionCrupier.canchero,
    MomentoPesca.moneda: ExpresionCrupier.sorprendido,
    MomentoPesca.bono: ExpresionCrupier.risa,
    MomentoPesca.pescaChica: ExpresionCrupier.guino,
    MomentoPesca.pescaGrande: ExpresionCrupier.sorprendido,
    MomentoPesca.noLeApostaste: ExpresionCrupier.guino,
    MomentoPesca.ganaste: ExpresionCrupier.triste,
    MomentoPesca.recuperaste: ExpresionCrupier.normal,
    MomentoPesca.conBola: ExpresionCrupier.sorprendido,
    MomentoPesca.granPremio: ExpresionCrupier.nervioso,
    MomentoPesca.perdiste: ExpresionCrupier.feliz,
    MomentoPesca.racha: ExpresionCrupier.nervioso,
    MomentoPesca.quiebra: ExpresionCrupier.triste,
    MomentoPesca.rescate: ExpresionCrupier.guino,
  };

  /// [pez] y [por] completan las frases que los nombran.
  void _momento(MomentoPesca momento, {String pez = '', String por = ''}) =>
      _decir(
        _frases.decir(momento).replaceAll('{p}', pez).replaceAll('{x}', por),
        expresion: _carasDe[momento] ?? ExpresionCrupier.normal,
      );

  void _sonar(SonidoMesa sonido, {double volumen = 1}) {
    if (_conSonido) _sonidos.tocar(sonido, volumen: volumen * .9);
  }

  /// La voz: un murmullo por frase (ver VozCrupier).
  late final VozCrupier _voz = VozCrupier(
    tocar: _sonar,
    detener: (sonido) {
      if (_conSonido) _sonidos.detener(sonido);
    },
  );

  void _avisar(String texto) {
    _borrarAviso?.cancel();
    setState(() => _aviso = texto);
    _borrarAviso = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _aviso = null);
    });
  }

  /// El centro de algo de la pantalla, en las medidas del cuerpo.
  Offset? _centroDe(GlobalKey llave) {
    final caja = llave.currentContext?.findRenderObject() as RenderBox?;
    final cuerpo =
        _llaveCuerpo.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || cuerpo == null || !caja.attached) return null;
    return caja.localToGlobal(caja.size.center(Offset.zero), ancestor: cuerpo);
  }

  Offset get _bolsillo =>
      _centroDe(_llaveFichas) ?? Offset((_d?.escena.right ?? 300) - 60, 28);

  Offset _lugar(Casilla casilla) =>
      _centroDe(_llavesCasillas[casilla]!) ?? _d!.tablero.center;

  /// Un punto sobre la casilla [casilla] de la rueda, a [radio] (fraccion
  /// del radio) del centro.
  Offset _puntoDe(int casilla, double radio) {
    final rueda = _d!.rueda;
    final phi = MedidasRueda.anguloDe(casilla, _giro.value);
    return rueda.center +
        Offset(math.cos(phi), math.sin(phi)) * rueda.width / 2 * radio;
  }

  int get _fichasEnPantalla => (_mesaCargada?.fichas ?? 0) - _porLlegar;

  /// La ficha elegida, o la mas grande que alcance si ya no alcanza.
  int _fichaQueAlcanza(int ficha) {
    final fichas = _mesaCargada?.fichas ?? 0;
    if (ficha <= fichas) return ficha;
    return Casino.valoresFichas.lastWhere(
      (v) => v <= fichas,
      orElse: () => Casino.valoresFichas.first,
    );
  }

  void _volar({
    required Offset desde,
    required Offset hasta,
    required int monto,
    int retraso = 0,
    int duracion = 420,
    bool desvanecer = false,
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
        retraso: _dur(retraso),
        duracion: _dur(duracion),
        desvanecer: desvanecer,
        alLlegar: alLlegar,
      ),
    );
  }

  /// Lo que se ve en el tablero: lo apostado, menos lo que todavia vuela.
  Map<Casilla, int> get _montosEnTablero {
    final pago = _pilasPago;
    if (pago != null) return Map.of(pago);
    return {
      for (final MapEntry(key: casilla, value: monto) in _mesa.apuestas.entries)
        if (monto - (_enVuelo[casilla] ?? 0) > 0)
          casilla: monto - (_enVuelo[casilla] ?? 0),
    };
  }

  // ================================================================ apostar
  bool get _libre => _fase == _Fase.apostando && _mesaCargada != null;

  void _elegirFicha(int valor) {
    if (!_libre) return;
    if (valor == valorTodo) {
      // Se prende y se apaga: el "all in" es de una sola apuesta.
      if (!_mesa.puedeIrConTodo) return;
      _sonar(SonidoMesa.boton, volumen: .6);
      setState(() => _todo = !_todo);
      return;
    }
    if (valor > _mesa.fichas) return;
    _sonar(SonidoMesa.boton, volumen: .6);
    setState(() {
      _todo = false;
      _ficha = valor;
    });
  }

  /// Lo que quedo de la ronda anterior (el cubo o el brillo de lo que
  /// salio) se va cuando empieza la siguiente.
  void _limpiarRonda() {
    if (_salio == null) return;
    _salio = null;
    _marca.value = 0;
    _efectos.marcar(null, 0);
  }

  void _poner(Casilla casilla) {
    if (!_libre) return;
    final mesa = _mesa;
    final todo = _todo && mesa.puedeIrConTodo;
    final valor = todo ? mesa.todo : _ficha;
    if (!mesa.puedeApostar(valor)) {
      _avisar('No te alcanzan las fichas');
      RetroalimentacionHaptica.seleccion();
      return;
    }
    final desde =
        _centroDe(_llavesRack[todo ? valorTodo : valor]!) ?? _bolsillo;
    final hasta = _lugar(casilla);
    setState(() {
      _limpiarRonda();
      mesa.apostar(casilla, valor);
      _ultimo = null;
      _enVuelo[casilla] = (_enVuelo[casilla] ?? 0) + valor;
      _volar(
        desde: desde,
        hasta: hasta,
        monto: valor,
        duracion: todo ? 460 : 300,
        alLlegar: () {
          // Un all in son muchas fichas juntas: suena como un puñado.
          _sonar(todo ? SonidoMesa.fichas : SonidoMesa.ficha);
          setState(() => _quitarDelVuelo(casilla, valor));
        },
      );
      _todo = false;
      _ficha = _fichaQueAlcanza(_ficha);
    });
    _despuesDeApostar(todo: todo);
  }

  /// "Todos": la misma ficha en los tres peces. Con ALL IN, todas tus
  /// fichas repartidas entre los tres.
  void _ponerEnLosPeces() {
    if (!_libre) return;
    final mesa = _mesa;
    final todo = _todo && mesa.fichas >= MesaPesca.apuestaMinima * 3;
    final valor = todo ? mesa.fichas ~/ 3 : _ficha;
    final desde =
        _centroDe(_llavesRack[todo ? valorTodo : _ficha]!) ?? _bolsillo;
    final lugares = {for (final pez in Pez.values) pez: _lugar(pez.casilla)};
    final puestas = mesa.apostarALosPeces(valor);
    if (puestas.isEmpty) {
      _avisar('No te alcanzan las fichas para los tres');
      RetroalimentacionHaptica.seleccion();
      return;
    }
    setState(() {
      _limpiarRonda();
      _ultimo = null;
      for (final (i, (casilla, monto)) in puestas.indexed) {
        _enVuelo[casilla] = (_enVuelo[casilla] ?? 0) + monto;
        _volar(
          desde: desde,
          hasta: lugares[casilla.pez]!,
          monto: monto,
          retraso: 70 * i,
          duracion: 340,
          alLlegar: () {
            _sonar(todo ? SonidoMesa.fichas : SonidoMesa.ficha);
            setState(() => _quitarDelVuelo(casilla, monto));
          },
        );
      }
      _todo = false;
      _ficha = _fichaQueAlcanza(_ficha);
    });
    _despuesDeApostar(todo: todo);
  }

  void _despuesDeApostar({required bool todo}) {
    final mesa = _mesa;
    if (todo) {
      RetroalimentacionHaptica.accion();
      _avisoFuerte = true;
      _momento(MomentoPesca.todo);
      return;
    }
    RetroalimentacionHaptica.seleccion();
    if (!_avisoFuerte && mesa.enMesa >= 500 && mesa.enMesa >= mesa.total / 2) {
      _avisoFuerte = true;
      _momento(
        mesa.fichas < MesaPesca.apuestaMinima
            ? MomentoPesca.todo
            : MomentoPesca.apuestaFuerte,
      );
    }
  }

  void _quitarDelVuelo(Casilla casilla, int monto) {
    final queda = (_enVuelo[casilla] ?? 0) - monto;
    if (queda > 0) {
      _enVuelo[casilla] = queda;
    } else {
      _enVuelo.remove(casilla);
    }
  }

  /// Las fichas que vuelven del tablero a tu bolsillo.
  void _devolver(Map<Casilla, int> fichas) {
    final bolsillo = _bolsillo;
    var i = 0;
    for (final MapEntry(key: casilla, value: monto) in fichas.entries) {
      _porLlegar += monto;
      final primero = i == 0;
      _volar(
        desde: _lugar(casilla),
        hasta: bolsillo,
        monto: monto,
        retraso: 30 * i++,
        duracion: 380,
        alLlegar: () {
          if (primero) _sonar(SonidoMesa.fichas, volumen: .6);
          setState(() => _porLlegar = math.max(0, _porLlegar - monto));
        },
      );
    }
  }

  void _deshacer() {
    if (!_libre) return;
    final quitada = _mesa.deshacer();
    if (quitada == null) return;
    final (casilla, monto) = quitada;
    setState(() => _devolver({casilla: monto}));
    RetroalimentacionHaptica.seleccion();
  }

  void _borrar() {
    if (!_libre || !_mesa.hayApuestas) return;
    setState(() => _devolver(_mesa.borrar()));
    RetroalimentacionHaptica.seleccion();
  }

  /// Repetir la ronda anterior, o doblar lo que hay: las fichas salen de tu
  /// bolsillo hacia el tablero.
  void _ponerVarias(List<(Casilla, int)> Function() cambio) {
    if (!_libre) return;
    final bolsillo = _bolsillo;
    setState(() {
      _limpiarRonda();
      final puestas = cambio();
      for (final (i, (casilla, monto)) in puestas.indexed) {
        _enVuelo[casilla] = (_enVuelo[casilla] ?? 0) + monto;
        _volar(
          desde: bolsillo,
          hasta: _lugar(casilla),
          monto: monto,
          retraso: 35 * i,
          duracion: 420,
          alLlegar: () {
            if (i == 0) _sonar(SonidoMesa.fichas);
            setState(() => _quitarDelVuelo(casilla, monto));
          },
        );
      }
      _ultimo = null;
      _ficha = _fichaQueAlcanza(_ficha);
    });
    RetroalimentacionHaptica.seleccion();
  }

  void _rescatar() {
    if (!_libre || !_mesa.enQuiebra) return;
    final monto = Casino.fichasIniciales;
    setState(() {
      _mesa.rescatar();
      _porLlegar += monto;
      _volar(
        desde: _d!.banca,
        hasta: _bolsillo,
        monto: monto,
        duracion: 720,
        alLlegar: () {
          _sonar(SonidoMesa.cobrar);
          setState(() => _porLlegar = math.max(0, _porLlegar - monto));
        },
      );
      _ficha = 10;
      _todo = false;
    });
    _momento(MomentoPesca.rescate);
    unawaited(_guardarMesa(_mesa));
  }

  // ================================================================== ronda
  TiradaPesca _siguienteTirada() {
    final forzadas = widget.tiradas;
    if (forzadas != null && forzadas.isNotEmpty) {
      return forzadas[_tiradasUsadas++ % forzadas.length];
    }
    return SorteoPesca.tirada(_azar);
  }

  Future<void> _jugar() async {
    if (!_libre || !_mesa.hayApuestas || _vuelos.isNotEmpty) return;
    final tirada = _siguienteTirada();
    RetroalimentacionHaptica.accion();
    _sonar(SonidoMesa.boton, volumen: .7);
    setState(() {
      _fase = _Fase.sorteando;
      _todo = false;
      _aviso = null;
      _avisoFuerte = false;
      _limpiarRonda();
    });
    _momento(MomentoPesca.noVaMas);
    await _esperar(650);
    if (!mounted) return;
    final multiplicadores = tirada.multiplicadores;
    await _tirarBolas(multiplicadores);
    if (!mounted) return;
    await _tirarMoneda(multiplicadores);
    if (!mounted) return;
    if (!multiplicadores.hayAlguno) {
      _momento(MomentoPesca.sinNada);
      await _esperar(900);
      if (!mounted) return;
    }
    setState(() => _fase = _Fase.girando);
    await _girarRueda(tirada);
    if (!mounted) return;
    await _mostrarSalida(tirada);
    if (!mounted) return;
    if (tirada.tipo.pez != null) {
      await _pescar(tirada);
      if (!mounted) return;
    }
    await _pagar(tirada);
  }

  /// Las bolas de nieve salen del centro de la rueda, de a una, y caen
  /// sobre su hielo.
  Future<void> _tirarBolas(Multiplicadores multiplicadores) async {
    if (multiplicadores.nieve.isEmpty) return;
    if (multiplicadores.moneda == null) _momento(MomentoPesca.nieve);
    final rueda = _d!.rueda;
    final entradas = multiplicadores.nieve.entries.toList()
      ..shuffle(_azarVisual);
    final ahora = _segundos.value;
    for (final (i, MapEntry(key: casilla, value: por)) in entradas.indexed) {
      _bolas.add(
        _Bola(
          casilla: casilla,
          por: por,
          desde: rueda.center,
          hasta: _puntoDe(casilla, MedidasRueda.etiquetas),
          inicio: ahora + _s(.4 * i),
          dura: _s(.56),
          diametro: rueda.width * .095,
        ),
      );
    }
    await _esperar(400 * entradas.length + 560 + 450);
  }

  void _alCaerBola(_Bola bola) {
    _sonar(SonidoMesa.nieve, volumen: .9);
    RetroalimentacionHaptica.seleccion();
    _salpicones.add(
      _Salpicon(
        donde: bola.hasta,
        inicio: _segundos.value,
        dura: math.max(.05, _s(.5)),
        radio: bola.diametro * .7,
        giro: _azarVisual.nextDouble() * math.pi,
      ),
    );
    setState(() {
      _visibles = Multiplicadores(
        nieve: {..._visibles.nieve, bola.casilla: bola.por},
        moneda: _visibles.moneda,
      );
    });
  }

  /// La moneda de oro aparece en el centro, gira y cae de cara: dice que
  /// pez multiplica y cuanto.
  Future<void> _tirarMoneda(Multiplicadores multiplicadores) async {
    final moneda = multiplicadores.moneda;
    if (moneda == null) return;
    _textoMoneda = 'x${moneda.por}';
    _sonar(SonidoMesa.moneda, volumen: .9);
    _moneda.duration = _dur(1700);
    await _moneda.forward(from: 0);
    if (!mounted) return;
    _sonar(SonidoMesa.cobrar, volumen: .8);
    RetroalimentacionHaptica.accion();
    setState(() {
      _visibles = Multiplicadores(nieve: _visibles.nieve, moneda: moneda);
    });
    _momento(
      MomentoPesca.moneda,
      pez: moneda.pez.nombre,
      por: 'x${moneda.por}',
    );
    await _esperar(1400);
  }

  Future<void> _girarRueda(TiradaPesca tirada) async {
    final a = MedidasRueda.casilla;
    final desde = _giro.value;
    // Para en cualquier lugar de su casilla, no siempre en el medio.
    final corrido = (_azarVisual.nextDouble() - .5) * .62 * a;
    final destino = -tirada.casilla * a + corrido;
    final vueltas = _sinMovimiento ? 0 : 2 + _azarVisual.nextInt(2);
    final hasta =
        desde + (destino - desde) % (2 * math.pi) + vueltas * 2 * math.pi;
    final dura = _sinMovimiento ? .4 : (_rapido ? 4.6 : 7.4);
    final giro = _Giro(
      desde: desde,
      hasta: hasta,
      inicio: _segundos.value,
      dura: dura,
    );
    _ultimoCruce = (desde / a + .5).floor();
    _giroEnCurso = giro;
    _ruedaSonando = true;
    _sonar(SonidoMesa.ruedaGira, volumen: .8);
    // Cuando frena, la camara se acerca a la aguja.
    if (!_sinMovimiento) {
      unawaited(
        Future<void>.delayed(Duration(milliseconds: (dura * 560).round()), () {
          if (!mounted || _giroEnCurso != giro) return;
          _zoom.animateTo(
            1,
            duration: Duration(milliseconds: (dura * 220).round()),
            curve: Curves.easeInOutCubic,
          );
        }),
      );
    }
    await giro.fin.future;
  }

  /// Lo que salio: el hielo se congela en un cubo; un pez brilla y abre el
  /// bono.
  Future<void> _mostrarSalida(TiradaPesca tirada) async {
    final tipo = tirada.tipo;
    final por = tirada.multiplicadores.enHielo(tirada.casilla);
    setState(() {
      _salio = tirada.casilla;
      _ganadoraTablero = tipo;
      _cartel = (casilla: tipo, paga: tipo.esHielo ? por.toDouble() : null);
    });
    _marca.duration = _dur(560);
    unawaited(_marca.forward(from: 0));
    RetroalimentacionHaptica.accion();
    if (tipo.esHielo) {
      _sonar(SonidoMesa.hielo);
      _decir(
        por > 1
            ? '¡${tipo.nombre}, con ${textoPor(por.toDouble())}!'
            : '¡${tipo.nombre}!',
        expresion: por > 1
            ? ExpresionCrupier.sorprendido
            : ExpresionCrupier.canchero,
      );
      await _esperar(1150);
    } else {
      _sonar(SonidoMesa.chapuzon);
      _momento(MomentoPesca.bono, pez: tipo.nombre);
      await _esperar(1500);
    }
    if (!mounted) return;
    setState(() => _cartel = null);
    await _zoom.animateBack(
      0,
      duration: _dur(520),
      curve: Curves.easeInOutCubic,
    );
  }

  /// MacIAs sale a pescar: el bono tapa la mesa hasta que termina.
  Future<void> _pescar(TiradaPesca tirada) async {
    final pez = tirada.tipo.pez!;
    final apostado = _mesa.montoEn(pez.casilla);
    final fin = _finDelBono = Completer<void>();
    setState(() {
      _fase = _Fase.pescando;
      _bonos++;
      _bono = (
        pez: pez,
        pesca: tirada.pesca ?? .1,
        moneda: tirada.multiplicadores.enPez(pez),
        apostado: apostado,
        premio: (apostado * tirada.pagaA1 + 1e-9).floor(),
      );
    });
    _velo.duration = _dur(380);
    await _velo.forward(from: 0);
    await fin.future;
    if (!mounted) return;
    await _velo.reverse();
    if (!mounted) return;
    setState(() => _bono = null);
  }

  // ================================================================== pagar
  Future<void> _pagar(TiradaPesca tirada) async {
    final d = _d!;
    final antes = Map.of(_mesa.apuestas);
    final lugares = {for (final c in antes.keys) c: _lugar(c)};
    final resultado = _mesa.liquidar(tirada);
    setState(() {
      _fase = _Fase.pagando;
      _pilasPago = antes;
      _porLlegar += resultado.cobrado;
    });
    // Lo que perdio se lo lleva MacIAs.
    if (resultado.perdedoras.isNotEmpty) {
      setState(() {
        for (final (i, perdida) in resultado.perdedoras.indexed) {
          _pilasPago!.remove(perdida.casilla);
          _volar(
            desde: lugares[perdida.casilla]!,
            hasta: d.banca,
            monto: perdida.monto,
            retraso: 40 * i,
            duracion: 520,
            desvanecer: true,
            alLlegar: i == 0
                ? () => _sonar(SonidoMesa.fichas, volumen: .5)
                : null,
          );
        }
      });
      await _esperar(620 + 40 * resultado.perdedoras.length);
      if (!mounted) return;
    }
    // MacIAs paga cada apuesta ganadora sobre su casilla.
    if (resultado.ganadoras.isNotEmpty) {
      setState(() {
        for (final (i, ganada) in resultado.ganadoras.indexed) {
          _volar(
            desde: d.banca,
            hasta: lugares[ganada.casilla]!,
            monto: ganada.cobra - ganada.monto,
            retraso: 70 * i,
            duracion: 480,
            alLlegar: () {
              _sonar(SonidoMesa.fichas);
              setState(() => _pilasPago?[ganada.casilla] = ganada.cobra);
            },
          );
        }
      });
      await _esperar(560 + 70 * resultado.ganadoras.length);
      if (!mounted) return;
    }
    _reaccionar(resultado);
    if (resultado.ganadoras.isNotEmpty) {
      await _esperar(650);
      if (!mounted) return;
      final bolsillo = _bolsillo;
      setState(() {
        for (final (i, ganada) in resultado.ganadoras.indexed) {
          _pilasPago!.remove(ganada.casilla);
          _volar(
            desde: lugares[ganada.casilla]!,
            hasta: bolsillo,
            monto: ganada.cobra,
            retraso: 45 * i,
            duracion: 560,
            alLlegar: () {
              if (i == 0) _sonar(SonidoMesa.cobrar);
              setState(
                () => _porLlegar = math.max(0, _porLlegar - ganada.cobra),
              );
            },
          );
        }
      });
      await _esperar(640 + 45 * resultado.ganadoras.length);
      if (!mounted) return;
    }
    // Las bolas de nieve y la moneda eran de esta ronda: se van. El cubo o
    // el brillo de lo que salio queda hasta la proxima apuesta.
    _efectos.ponerMoneda(visible: 0);
    _moneda.value = 0;
    setState(() {
      _visibles = Multiplicadores.ninguno;
      _ganadoraTablero = null;
      _pilasPago = null;
      _porLlegar = 0;
      _ultimo = resultado;
      _fase = _Fase.apostando;
      _ficha = _fichaQueAlcanza(_ficha);
    });
    unawaited(_guardarMesa(_mesa));
    if (_mesa.enQuiebra) {
      await _esperar(1600);
      if (mounted && _mesa.enQuiebra) _momento(MomentoPesca.quiebra);
    }
  }

  void _reaccionar(ResultadoPesca resultado) {
    final tirada = resultado.tirada;
    final pez = tirada.tipo.pez;
    final paga = tirada.pagaA1;
    final acerto = resultado.ganadoras.isNotEmpty;
    final grande = resultado.neto >= math.max(500, resultado.apostado * 5);
    if (grande) {
      _momento(MomentoPesca.granPremio);
    } else if (pez != null && !acerto) {
      _momento(paga >= 5 ? MomentoPesca.noLeApostaste : MomentoPesca.perdiste);
    } else if (pez != null && paga >= 20) {
      _momento(MomentoPesca.pescaGrande);
    } else if (pez != null && paga < 1) {
      _momento(MomentoPesca.pescaChica);
    } else if (pez == null && acerto && paga > 1) {
      _momento(MomentoPesca.conBola, por: textoPor(paga));
    } else if (resultado.neto > 0) {
      _momento(
        _mesa.estadisticas.rachaActual >= 3
            ? MomentoPesca.racha
            : MomentoPesca.ganaste,
      );
    } else if (resultado.cobrado > 0) {
      _momento(MomentoPesca.recuperaste);
    } else {
      _momento(MomentoPesca.perdiste);
    }
    if (grande || (pez != null && acerto && paga >= 20)) {
      _sonar(SonidoMesa.blackjack, volumen: .9);
    } else if (resultado.neto > 0) {
      _sonar(SonidoMesa.ganar, volumen: .85);
    } else if (resultado.cobrado == 0) {
      _sonar(SonidoMesa.perder, volumen: .7);
    }
  }

  // =================================================================== menu
  Future<void> _menu() {
    _sonar(SonidoMesa.boton, volumen: .7);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F1D27),
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
              SwitchListTile(
                secondary: const Icon(
                  Icons.speed_rounded,
                  color: ColoresCarta.oroClaro,
                ),
                title: const Text(
                  'Ronda rápida',
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
              OpcionMenuMesa(
                icono: Icons.menu_book_rounded,
                titulo: 'Cómo se juega',
                alTocar: () {
                  Navigator.of(hoja).pop();
                  _reglas();
                },
              ),
              OpcionMenuMesa(
                icono: Icons.insights_rounded,
                titulo: 'Tus estadísticas',
                alTocar: () {
                  Navigator.of(hoja).pop();
                  _estadisticas();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reglas() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0F1D27),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (hoja) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TituloHojaMesa('Cómo se juega'),
            ReglaMesa(
              'La rueda',
              '${RuedaPesca.cantidad} casillas: '
                  '${RuedaPesca.cuantas(Casilla.hieloBlanco)} de hielo blanco, '
                  '${RuedaPesca.cuantas(Casilla.hieloAzul)} de hielo azul y '
                  'los peces: ${RuedaPesca.cuantas(Casilla.azulitos)} de '
                  'Azulitos, ${RuedaPesca.cuantas(Casilla.naranjotes)} de '
                  'Naranjotes y un solo Rojazos. Pones tus fichas en el '
                  'tablero, giras y donde para la aguja, eso sale.',
            ),
            const ReglaMesa(
              'El hielo',
              'Si para en el hielo al que le apostaste, te devuelve tu apuesta '
                  'y otro tanto: paga 1 a 1.',
            ),
            const ReglaMesa(
              'Los peces',
              'Si para en un pez, MacIAs sale a pescar. El pez que saca vale '
                  'lo que dice su medidor, y eso paga a quien le apostó a ese '
                  'pez: tu apuesta vuelve, y encima lo que valga el pez. '
                  '"Todos" pone la misma ficha en los tres.',
            ),
            const TituloHojaMesa('Lo que paga'),
            for (final (nombre, paga) in const [
              ('Hielo blanco o azul', '1 a 1'),
              ('Con bola de nieve', 'x2 a x10'),
              ('Azulitos', 'x0,1 a x30'),
              ('Naranjotes', 'x0,1 a x80'),
              ('Rojazos', 'x0,1 a x150'),
              ('Con la moneda de oro', 'x2 a x10 más'),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: TextStyle(
                          color: ConfiguracionTema.crema.withValues(alpha: .8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      paga,
                      style: const TextStyle(
                        color: ColoresCarta.oroClaro,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const ReglaMesa(
              'Las bolas de nieve',
              'Antes de girar, en casi todas las rondas caen de 2 a 6 bolas de '
                  'nieve sobre casillas de hielo. Si la rueda para en una, ese '
                  'hielo paga lo que dice la bola (de x2 a x10) en vez de 1 a '
                  '1. Hay rondas sin ninguna.',
            ),
            const ReglaMesa(
              'La moneda de oro',
              'En algunas rondas cae una moneda en el centro: multiplica lo que '
                  'pague el pez que dice. Un Rojazos de x50 con moneda de x3 '
                  'paga x150.',
            ),
            const ReglaMesa(
              'All in',
              'La ficha ALL IN pone todas tus fichas de golpe donde toques. En '
                  '"Todos", se reparten entre los tres peces.',
            ),
            ReglaMesa(
              'El azar',
              'Toda la ronda (la nieve, la moneda, donde para la rueda y el pez '
                  'que se pesca) sale del azar seguro del teléfono antes de '
                  'girar: la rueda y la caña solo la muestran. En promedio, '
                  'cada apuesta devuelve unas '
                  '${(SorteoPesca.devolucion(Casilla.hieloBlanco) * 100).round()}'
                  ' de cada 100 fichas: la casa siempre tiene una pequeña '
                  'ventaja.',
            ),
            const ReglaMesa(
              'Las fichas',
              'Son las del casino: las mismas de las otras mesas. Son de '
                  'juego, no valen dinero ni se compran. Si te quedas sin '
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
      ('Rondas', conMiles(e.giros)),
      ('Rondas ganadas', conMiles(e.ganados)),
      ('Victorias', '${e.porcentajeGanados} %'),
      ('Apostado', conMiles(e.apostado)),
      ('Cobrado', conMiles(e.cobrado)),
      ('Balance', conMiles(e.cobrado - e.apostado)),
      ('Mayor premio', conMiles(e.mayorPremio)),
      ('Peces que salieron', conMiles(e.bonos)),
      ('El pez más grande', e.bonos == 0 ? '—' : textoPor(e.mayorPesca)),
      ('Mejor racha', conMiles(e.mejorRacha)),
      ('Récord de fichas', conMiles(e.fichasMaximas)),
      ('Préstamos de MacIAs', conMiles(e.rescates)),
    ];
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F1D27),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (hoja) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloHojaMesa('Tus estadísticas'),
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
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: _fondo,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, caja) => _mesaCargada == null
              ? const Center(
                  child: CircularProgressIndicator(color: ColoresCarta.oro),
                )
              : _mesaEn(caja.biggest),
        ),
      ),
    ),
  );

  Widget _mesaEn(Size cuerpo) {
    final d = _d = _Disposicion(cuerpo);
    final bono = _bono;
    final enRonda = _fase != _Fase.apostando;
    // La aguja, vista desde la escena: la camara se acerca ahi.
    final foco =
        (d.rueda.top + d.rueda.height * .005 - d.escena.top) / d.escena.height;
    return Stack(
      key: _llaveCuerpo,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PintorPaisaje(horizonte: d.rueda.center.dy),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PintorNevada(
                  reloj: _segundos,
                  quieta: _sinMovimiento,
                ),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: d.escena,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _zoom,
              builder: (context, hijo) {
                final z = Curves.easeInOutCubic.transform(_zoom.value);
                return Transform.scale(
                  scale: 1 + .62 * z,
                  alignment: Alignment(0, -1 + 2 * foco),
                  child: hijo,
                );
              },
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: d.rueda.shift(-d.escena.topLeft),
                    child: Semantics(
                      label: 'La rueda de la pesca',
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x5587CDEB),
                              blurRadius: 46,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 22,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: RuedaPescaVista(
                          giro: _giro,
                          efectos: _efectos,
                          multiplicadores: _visibles,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PintorNieveQueVuela(
                  reloj: _segundos,
                  bolas: _bolas,
                  salpicones: _salpicones,
                ),
              ),
            ),
          ),
        ),
        if (_cartel case final cartel?)
          Positioned.fromRect(
            rect: Rect.fromCenter(
              center: d.escena.center + Offset(0, d.escena.height * .14),
              width: 260,
              height: 220,
            ),
            child: IgnorePointer(
              child: Center(
                child: _CartelSalida(
                  casilla: cartel.casilla,
                  paga: cartel.paga,
                ),
              ),
            ),
          ),
        Positioned.fromRect(
          rect: d.tablero,
          child: TableroPesca(
            montos: _montosEnTablero,
            llaves: _llavesCasillas,
            alTocar: _poner,
            alTocarTodos: _ponerEnLosPeces,
            moneda: enRonda ? _visibles.moneda : null,
            ganadora: _ganadoraTablero,
            habilitado: _libre,
          ),
        ),
        // La mesa se apaga mientras gira: los ojos, en la rueda.
        Positioned(
          left: 0,
          right: 0,
          top: d.tablero.top - 4,
          bottom: 0,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _zoom,
              builder: (context, _) => ColoredBox(
                color: Colors.black.withValues(alpha: .45 * _zoom.value),
              ),
            ),
          ),
        ),
        if (_aviso != null)
          Positioned(
            left: 0,
            right: 0,
            top: d.tablero.top - 44,
            child: Center(child: _Aviso(texto: _aviso!)),
          ),
        Positioned.fromRect(
          rect: d.retrato,
          child: CrupierMacias(
            tamano: d.avatar,
            expresion: _expresion,
            hablando: _hablando,
            latido: _latido,
          ),
        ),
        Positioned(
          left: d.retrato.center.dx - 60,
          width: 120,
          top: d.retrato.bottom - 8,
          child: const Center(child: PlacaCrupier()),
        ),
        Positioned.fromRect(
          rect: d.historial,
          child: _Historial(salidas: _mesa.historial),
        ),
        Positioned(
          left: d.dialogo.left,
          top: d.dialogo.top,
          width: d.dialogo.width,
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
                        if (hablando) {
                          _voz.empezar((_dicho?.length ?? 0) * _msPorLetra);
                        } else {
                          _voz.terminar();
                        }
                        if (mounted && _hablando != hablando) {
                          setState(() => _hablando = hablando);
                        }
                      },
                    ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: d.controles,
          child: _panelControles(),
        ),
        if (bono != null)
          Positioned(
            left: 0,
            right: 0,
            top: _Disposicion.altoBarra,
            bottom: 0,
            child: FadeTransition(
              opacity: _velo,
              child: ClipRect(
                child: BonoPesca(
                  key: ValueKey('bono$_bonos'),
                  pez: bono.pez,
                  pesca: bono.pesca,
                  moneda: bono.moneda,
                  apostado: bono.apostado,
                  premio: bono.premio,
                  sonar: _sonar,
                  ritmo: _ritmo,
                  alTerminar: () {
                    final fin = _finDelBono;
                    if (fin != null && !fin.isCompleted) fin.complete();
                  },
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _Disposicion.altoBarra,
          child: BarraMesa(
            llaveFichas: _llaveFichas,
            fichas: _fichasEnPantalla,
            titulo: 'Pesca en el hielo',
            subtitulo: 'Hielo 1 a 1 · peces hasta x150',
            alMenu: _menu,
          ),
        ),
        for (final vuelo in _vuelos)
          FichasEnVuelo(
            key: ValueKey('vuelo${vuelo.id}'),
            desde: vuelo.desde,
            hasta: vuelo.hasta,
            monto: vuelo.monto,
            diametro: 24,
            retraso: vuelo.retraso,
            duracion: vuelo.duracion,
            desvanecer: vuelo.desvanecer,
            alLlegar: () {
              if (!mounted) return;
              setState(() => _vuelos.remove(vuelo));
              vuelo.alLlegar?.call();
            },
          ),
      ],
    );
  }

  Widget _panelControles() {
    final mesa = _mesa;
    final libre = _libre && _vuelos.isEmpty;
    if (_fase == _Fase.apostando && mesa.enQuiebra && !mesa.hayApuestas) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Te quedaste sin fichas',
              style: TextStyle(
                color: ConfiguracionTema.crema.withValues(alpha: .85),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            BotonMesa(
              texto: 'Aceptar 1.000 fichas',
              icono: Icons.volunteer_activism_rounded,
              estilo: EstiloBoton.principal,
              alPresionar: _libre ? _rescatar : null,
            ),
          ],
        ),
      );
    }
    final ultimo = _ultimo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 22,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _todo
                        ? 'ALL IN · ${conMiles(mesa.todo)} fichas: toca dónde van'
                        : mesa.hayApuestas
                        ? 'En juego: ${conMiles(mesa.enMesa)}'
                        : 'Elige una ficha y toca el hielo o un pez',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ConfiguracionTema.crema.withValues(alpha: .7),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (ultimo != null && !mesa.hayApuestas)
                  Text(
                    ultimo.neto > 0
                        ? 'Ganaste ${conMiles(ultimo.neto)}'
                        : ultimo.cobrado > 0
                        ? 'Recuperaste ${conMiles(ultimo.cobrado)}'
                        : 'Perdiste ${conMiles(ultimo.apostado)}',
                    style: TextStyle(
                      color: ultimo.neto > 0
                          ? ColoresCarta.oroClaro
                          : ConfiguracionTema.crema.withValues(alpha: .7),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final valor in [...Casino.valoresFichas, valorTodo])
                FichaRack(
                  llave: _llavesRack[valor]!,
                  valor: valor,
                  diametro: 42,
                  seleccionada: valor == valorTodo
                      ? _todo
                      : !_todo && _ficha == valor,
                  habilitada:
                      _libre &&
                      (valor == valorTodo
                          ? mesa.puedeIrConTodo
                          : valor <= mesa.fichas),
                  alTocar: () => _elegirFicha(valor),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Tooltip(
                message: 'Deshacer',
                child: BotonMesa(
                  texto: '',
                  etiqueta: 'Deshacer',
                  icono: Icons.undo_rounded,
                  chico: true,
                  alPresionar: libre && mesa.hayApuestas ? _deshacer : null,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Borrar todo',
                child: BotonMesa(
                  texto: '',
                  etiqueta: 'Borrar todo',
                  icono: Icons.delete_outline_rounded,
                  chico: true,
                  alPresionar: libre && mesa.hayApuestas ? _borrar : null,
                ),
              ),
              const SizedBox(width: 8),
              if (mesa.hayApuestas)
                BotonMesa(
                  texto: 'x2',
                  chico: true,
                  alPresionar: libre && mesa.puedeDoblar
                      ? () => _ponerVarias(mesa.doblar)
                      : null,
                )
              else
                BotonMesa(
                  texto: 'Repetir',
                  icono: Icons.replay_rounded,
                  chico: true,
                  alPresionar: libre && mesa.puedeRepetir
                      ? () => _ponerVarias(mesa.repetir)
                      : null,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: BotonMesa(
                  texto: switch (_fase) {
                    _Fase.apostando => 'Girar',
                    _Fase.pescando => 'Pescando…',
                    _Fase.pagando => 'Pagando…',
                    _ => 'Girando…',
                  },
                  icono: Icons.motion_photos_on_rounded,
                  estilo: EstiloBoton.principal,
                  resaltado: libre && mesa.hayApuestas,
                  alPresionar: libre && mesa.hayApuestas ? _jugar : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lo que salio, grande sobre la rueda: el hielo con lo que paga, o el pez
/// que abre el bono.
class _CartelSalida extends StatelessWidget {
  const _CartelSalida({required this.casilla, required this.paga});

  final Casilla casilla;

  /// Lo que paga a 1 el hielo (con su bola de nieve); nada si es un pez.
  final double? paga;

  @override
  Widget build(BuildContext context) {
    final (claro, oscuro) = ColoresPesca.deCasilla(casilla);
    final tinta = casilla == Casilla.hieloBlanco
        ? ColoresPesca.texto
        : Colors.white;
    final pez = casilla.pez;
    final paga = this.paga ?? 1;
    final grande = pez != null
        ? '¡A pescar!'
        : paga > 1
        ? textoPor(paga)
        : '1 a 1';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, hijo) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: .5 + .5 * t, child: hijo),
      ),
      child: Semantics(
        liveRegion: true,
        label: pez != null
            ? 'Salió ${casilla.nombre}: bono de pesca'
            : 'Salió ${casilla.nombre}: paga ${paga > 1 ? textoPor(paga) : '1 a 1'}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [claro, oscuro],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              const BoxShadow(color: Color(0x99000000), blurRadius: 18),
              BoxShadow(color: claro.withValues(alpha: .7), blurRadius: 26),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pez != null)
                PezDibujado(pez: pez, ancho: 86, boca: true)
              else
                SizedBox.square(
                  dimension: 30,
                  child: CustomPaint(painter: _PintorCopito(tinta)),
                ),
              const SizedBox(height: 4),
              Text(
                casilla.nombre.toUpperCase(),
                style: TextStyle(
                  color: tinta,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                grande,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: tinta,
                  fontWeight: FontWeight.w900,
                  fontSize: pez != null ? 26 : 40,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un aviso corto sobre el tablero ("no te alcanzan las fichas").
class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xF02A1210),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE57373)),
    ),
    child: Text(
      texto,
      style: const TextStyle(
        color: ConfiguracionTema.crema,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    ),
  );
}

/// Lo ultimo que salio, lo mas nuevo primero: el hielo con su color (y su
/// bola de nieve, si tenia) y los peces con lo que pagaron.
class _Historial extends StatelessWidget {
  const _Historial({required this.salidas});

  final List<SalidaPesca> salidas;

  static String _dicho(SalidaPesca salida) => salida.casilla.esHielo
      ? salida.paga > 1
            ? '${salida.casilla.nombre} ${textoPor(salida.paga)}'
            : salida.casilla.nombre
      : '${salida.casilla.nombre} ${textoPor(salida.paga)}';

  @override
  Widget build(BuildContext context) => Semantics(
    label: salidas.isEmpty
        ? 'Todavía no salió nada'
        : 'Lo último que salió: ${salidas.take(5).map(_dicho).join(', ')}',
    excludeSemantics: true,
    child: LayoutBuilder(
      builder: (context, caja) {
        final cuantas = math.max(1, ((caja.maxWidth + 3) / 37).floor());
        return Row(
          children: [
            if (salidas.isEmpty)
              Flexible(
                child: Text(
                  'Lo que sale aparece acá',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ConfiguracionTema.crema.withValues(alpha: .45),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            for (final (i, salida) in salidas.take(cuantas).indexed)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: _Salida(salida: salida, ultima: i == 0),
              ),
          ],
        );
      },
    ),
  );
}

class _Salida extends StatelessWidget {
  const _Salida({required this.salida, required this.ultima});

  final SalidaPesca salida;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final casilla = salida.casilla;
    final (claro, oscuro) = ColoresPesca.deCasilla(casilla);
    final blanco = casilla == Casilla.hieloBlanco;
    final tinta = blanco ? ColoresPesca.texto : Colors.white;
    return Container(
      width: 34,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [claro, oscuro],
        ),
        border: Border.all(
          color: ultima
              ? ColoresPesca.oro
              : Colors.white.withValues(alpha: casilla.esHielo ? .5 : .3),
          width: ultima ? 2 : 1,
        ),
      ),
      child: casilla.esHielo && salida.paga <= 1
          ? SizedBox.square(
              dimension: 11,
              child: CustomPaint(painter: _PintorCopito(tinta)),
            )
          : FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  textoPor(salida.paga),
                  style: TextStyle(
                    color: tinta,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    height: 1,
                  ),
                ),
              ),
            ),
    );
  }
}

class _PintorCopito extends CustomPainter {
  const _PintorCopito(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarCopo(canvas, size.center(Offset.zero), size.width / 2, color);

  @override
  bool shouldRepaint(_PintorCopito viejo) => viejo.color != color;
}

/// La noche sobre el lago congelado: el cielo con su aurora y sus estrellas,
/// las montañas de hielo y el lago, que brilla un poco detras de la rueda.
class _PintorPaisaje extends CustomPainter {
  const _PintorPaisaje({required this.horizonte});

  /// A que altura queda el horizonte (el centro de la rueda).
  final double horizonte;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final todo = Offset.zero & size;
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF040B12),
            Color(0xFF0B2233),
            Color(0xFF173F57),
            Color(0xFF0B1F2C),
            Color(0xFF06111A),
          ],
          stops: [0, .3, .5, .72, 1],
        ).createShader(todo),
    );
    // La aurora: dos cintas que se mecen, borrosas.
    for (final (y, color, alto) in [
      (h * .11, const Color(0x4434E0B0), h * .045),
      (h * .17, const Color(0x3338A6E8), h * .035),
      (h * .07, const Color(0x2296E8A8), h * .03),
    ]) {
      final cinta = Path()..moveTo(-30, y);
      for (var x = -30.0; x <= w + 30; x += w / 10) {
        cinta.lineTo(x, y + math.sin(x / w * 5.2 + y * .01) * h * .025);
      }
      canvas.drawPath(
        cinta,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = alto
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, alto * .7),
      );
    }
    // Las estrellas.
    final azar = math.Random(11);
    for (var i = 0; i < 60; i++) {
      final p = Offset(azar.nextDouble() * w, azar.nextDouble() * horizonte);
      canvas.drawCircle(
        p,
        .5 + azar.nextDouble() * .9,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (.2 + azar.nextDouble() * .55) * (1 - p.dy / horizonte),
          ),
      );
    }
    // Las montañas de hielo, a los costados de la rueda.
    for (final (alto, color, paso, corrido) in [
      (.15, const Color(0xFF214A62), .16, 0.0),
      (.09, const Color(0xFF2C5D78), .11, .4),
    ]) {
      final montes = Path()..moveTo(0, horizonte);
      var x = -w * paso * corrido;
      var i = 0;
      while (x <= w + w * paso) {
        final pico = (i.isEven ? 1.0 : .5 + (i % 3) * .1) * h * alto;
        montes.lineTo(x, horizonte - pico);
        x += w * paso;
        i++;
      }
      montes
        ..lineTo(w, horizonte)
        ..close();
      canvas.drawPath(montes, Paint()..color = color);
      // La nieve de las puntas.
      canvas.drawPath(
        montes,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .35),
                  Colors.white.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromLTRB(
                  0,
                  horizonte - h * alto,
                  w,
                  horizonte - h * alto * .5,
                ),
              ),
      );
    }
    // El lago: hielo azul que se pierde hacia abajo, con un brillo detras
    // de la rueda.
    final lago = Rect.fromLTRB(0, horizonte, w, h);
    canvas
      ..drawRect(
        lago,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B7896), Color(0xFF173A4F), Color(0xFF06111A)],
            stops: [0, .45, 1],
          ).createShader(lago),
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, horizonte),
          width: w * 1.3,
          height: h * .22,
        ),
        Paint()
          ..color = const Color(0x4487CDEB)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .05),
      );
    // Las grietas del hielo.
    final grieta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = Colors.white.withValues(alpha: .12);
    for (var i = 0; i < 9; i++) {
      final desde = Offset(
        azar.nextDouble() * w,
        horizonte + 8 + azar.nextDouble() * (h - horizonte) * .5,
      );
      final linea = Path()..moveTo(desde.dx, desde.dy);
      var p = desde;
      for (var j = 0; j < 4; j++) {
        p += Offset((azar.nextDouble() - .5) * 46, azar.nextDouble() * 12);
        linea.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(linea, grieta);
    }
  }

  @override
  bool shouldRepaint(_PintorPaisaje viejo) => viejo.horizonte != horizonte;
}

/// La nieve que cae despacio sobre todo.
class _PintorNevada extends CustomPainter {
  _PintorNevada({required this.reloj, required this.quieta})
    : super(repaint: quieta ? null : reloj);

  final ValueListenable<double> reloj;

  /// Sin animaciones (lo pide el telefono): la nieve queda quieta.
  final bool quieta;

  @override
  void paint(Canvas canvas, Size size) {
    final t = quieta ? 0.0 : reloj.value;
    final copo = Paint();
    for (var i = 0; i < 46; i++) {
      final cerca = (i % 5) / 4;
      final velocidad = 14 + cerca * 26;
      final y = (t * velocidad + i * 83.0) % (size.height + 20) - 10;
      final x = (i * 97.0 + 13) % size.width + math.sin(t * .7 + i * 1.7) * 12;
      copo.color = Colors.white.withValues(alpha: .25 + .45 * cerca);
      canvas.drawCircle(Offset(x, y), .9 + 1.5 * cerca, copo);
    }
  }

  @override
  bool shouldRepaint(_PintorNevada viejo) => viejo.quieta != quieta;
}

/// Las bolas de nieve en el aire y la nieve que salta donde caen.
class _PintorNieveQueVuela extends CustomPainter {
  _PintorNieveQueVuela({
    required this.reloj,
    required this.bolas,
    required this.salpicones,
  }) : super(repaint: reloj);

  final ValueListenable<double> reloj;
  final List<_Bola> bolas;
  final List<_Salpicon> salpicones;

  @override
  void paint(Canvas canvas, Size size) {
    final ahora = reloj.value;
    for (final s in salpicones) {
      final t = ((ahora - s.inicio) / s.dura).clamp(0.0, 1.0);
      if (t >= 1) continue;
      final abre = Curves.easeOutCubic.transform(t);
      canvas.drawCircle(
        s.donde,
        s.radio * (.5 + 1.3 * abre),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.radio * .22 * (1 - t)
          ..color = Colors.white.withValues(alpha: .85 * (1 - t)),
      );
      final grumo = Paint()..color = Colors.white.withValues(alpha: 1 - t);
      for (var i = 0; i < 10; i++) {
        final angulo = s.giro + i / 10 * 2 * math.pi;
        final lejos = s.radio * (.4 + (1.2 + (i % 3) * .3) * abre);
        canvas.drawCircle(
          s.donde +
              Offset(math.cos(angulo), math.sin(angulo)) * lejos +
              Offset(0, s.radio * .9 * t * t),
          s.radio * (.2 - .05 * (i % 3)) * (1 - t * .7),
          grumo,
        );
      }
    }
    for (final bola in bolas) {
      final t = (ahora - bola.inicio) / bola.dura;
      if (t < 0 || t > 1) continue;
      final avance = Curves.easeInOutSine.transform(t);
      final arco = math.sin(t * math.pi);
      final suelo = Offset.lerp(bola.desde, bola.hasta, avance)!;
      final r = bola.diametro / 2 * (1 + .9 * arco);
      // Su sombra sobre la rueda: mas chica y clara cuanto mas alto va.
      canvas.drawOval(
        Rect.fromCenter(
          center: suelo + Offset(r * .15, r * .35),
          width: bola.diametro * (1.1 - .3 * arco),
          height: bola.diametro * (.5 - .15 * arco),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: .28 * (1 - .6 * arco))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .2),
      );
      _pintarBola(
        canvas,
        suelo - Offset(0, arco * bola.diametro * 1.8),
        r,
        t * 5,
      );
    }
  }

  void _pintarBola(Canvas canvas, Offset centro, double r, double vuelta) {
    final caja = Rect.fromCircle(center: centro, radius: r);
    canvas.drawCircle(
      centro,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.4),
          colors: [Colors.white, Color(0xFFE8F2F8), Color(0xFFAFCBDC)],
          stops: [0, .55, 1],
        ).createShader(caja),
    );
    // Los grumos de la nieve apretada, que giran con la bola.
    final grumo = Paint()..color = const Color(0xFFCADDE9);
    for (var i = 0; i < 5; i++) {
      final a = vuelta + i * 1.26;
      canvas.drawCircle(
        centro + Offset(math.cos(a), math.sin(a)) * r * .52,
        r * .17,
        grumo,
      );
    }
    canvas.drawCircle(
      centro + Offset(-r * .34, -r * .38),
      r * .22,
      Paint()..color = Colors.white.withValues(alpha: .9),
    );
  }

  @override
  bool shouldRepaint(_PintorNieveQueVuela viejo) => true;
}
