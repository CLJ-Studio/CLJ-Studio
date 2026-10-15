import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/interaccion/frecuencia_pantalla.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/cartas_blackjack.dart';
import '../diseno/crupier_macias.dart';
import '../diseno/fichas_blackjack.dart';
import '../diseno/mesa_casino.dart';
import '../diseno/pano_ruleta.dart';
import '../diseno/rueda_ruleta.dart';
import '../logica/almacen_casino.dart';
import '../logica/casino.dart';
import '../logica/frases_casino.dart';
import '../logica/mesa_ruleta.dart';
import '../logica/sonidos_casino.dart';
import '../logica/trayectoria_bola.dart';

/// La ruleta europea del casino de MacIAs.
///
/// Se elige una ficha y se toca el paño: manteniendo el dedo se ve que
/// numeros cubre la apuesta y cuanto paga, y al soltar la ficha vuela a su
/// lugar. Al girar, la rueda pasa al centro: el cilindro gira, la bola corre
/// en contra por el carril, cae, golpea un rombo y rebota hasta quedarse en
/// su casilla. El numero sale del azar del telefono antes de lanzar; la bola
/// solo lo muestra.
class PantallaRuleta extends StatefulWidget {
  const PantallaRuleta({
    this.nombre = '',
    this.almacen,
    this.sonidos,
    this.azar,
    this.numeros,
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

  /// Para las pruebas: los numeros que van a salir, en orden.
  final List<int>? numeros;

  static Route<void> ruta({
    String nombre = '',
    AlmacenCasino? almacen,
    SonidosMesa? sonidos,
  }) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) =>
        PantallaRuleta(nombre: nombre, almacen: almacen, sonidos: sonidos),
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
  State<PantallaRuleta> createState() => _PantallaRuletaState();
}

enum _Fase { apostando, girando, pagando }

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

/// Donde va cada cosa, segun el tamaño de la pantalla.
class _Disposicion {
  _Disposicion(Size s) {
    final w = s.width;
    final h = s.height;
    controles = (h * .2).clamp(150.0, 172.0);
    cabecera = (h * .19).clamp(116.0, 170.0);
    const arriba = altoBarra;
    var lado = cabecera - 8;
    var tamanoRetrato = (cabecera * .47).clamp(54.0, 78.0);
    // El dialogo de MacIAs va entre la ruedita y su retrato, y necesita al
    // menos este ancho para que se lea: en un telefono angosto (320 dp) se
    // achican primero la ruedita y despues el retrato.
    const anchoDialogo = 150.0;
    double sobra() =>
        w - 10 - lado - 10 - 6 - tamanoRetrato - 10 - anchoDialogo;
    if (sobra() < 0) lado = math.max(84.0, lado + sobra());
    if (sobra() < 0) tamanoRetrato = math.max(52.0, tamanoRetrato + sobra());
    ruedaChica = Rect.fromLTWH(10, arriba + 4, lado, lado);
    avatar = tamanoRetrato;
    final derecha = w - 10;
    retrato = Rect.fromLTWH(derecha - avatar, arriba + 4, avatar, avatar);
    dialogo = Rect.fromLTRB(
      ruedaChica.right + 10,
      arriba + 2,
      retrato.left - 6,
      arriba + cabecera - 28,
    );
    historial = Rect.fromLTRB(
      ruedaChica.right + 10,
      arriba + cabecera - 24,
      derecha,
      arriba + cabecera,
    );
    pano = Rect.fromLTRB(6, arriba + cabecera + 4, w - 6, h - controles - 2);
    final diametro = math.min(math.min(w - 32, pano.height - 12), 400.0);
    ruedaGrande = Rect.fromCenter(
      center: pano.center,
      width: diametro,
      height: diametro,
    );
  }

  static const altoBarra = 58.0;
  late final double controles;
  late final double cabecera;
  late final Rect ruedaChica;
  late final double avatar;
  late final Rect retrato;
  late final Rect dialogo;
  late final Rect historial;
  late final Rect pano;
  late final Rect ruedaGrande;

  /// Donde MacIAs junta y paga las fichas.
  Offset get banca => retrato.center;
}

class _PantallaRuletaState extends State<PantallaRuleta>
    with TickerProviderStateMixin {
  static const _fondo = Color(0xFF0C0A09);

  /// Lo que suena en la ruleta: lo demas del casino ni se carga.
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
    SonidoMesa.bolaRueda,
    SonidoMesa.bolaGolpe,
    SonidoMesa.bolaToc,
  };

  /// El numero sale del azar seguro del telefono.
  late final math.Random _azar = widget.azar ?? math.Random.secure();

  /// Para lo que no decide nada (como lanza el crupier, que frase dice).
  final _azarVisual = math.Random();
  late final FrasesRuleta _frases = FrasesRuleta(
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
  int _numerosUsados = 0;

  MesaRuleta? _mesaCargada;
  MesaRuleta get _mesa => _mesaCargada!;
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
  final _giro = ValueNotifier<double>(0);
  final _bola = ValueNotifier<PosicionBola?>(null);
  Duration _ahora = Duration.zero;
  Duration _ultimoCuadro = Duration.zero;
  TrayectoriaBola? _trayectoria;
  Duration _inicioGiro = Duration.zero;
  int _siguienteGolpe = 0;

  /// Entre giros el cilindro sigue girando despacio, como en el casino.
  double _velocidad = 2 * math.pi * .06;

  /// La casilla donde esta la bola cuando no gira.
  int? _casillaBola;
  int? _ganadora;
  bool _mostrarNumero = false;
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  );
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  // El paño.
  Apuesta? _presionada;
  Offset? _dedo;
  String? _aviso;
  int? _numeroMarcado;
  ResultadoRuleta? _ultimo;

  // Las fichas que viajan.
  final _vuelos = <_Vuelo>[];
  int _siguienteVuelo = 0;
  final _enVuelo = <Apuesta, int>{};
  int _porLlegar = 0;
  Map<Apuesta, int>? _pilasPago;

  final _llaveCuerpo = GlobalKey();
  final _llaveFichas = GlobalKey();
  final _llavesRack = {
    for (final valor in [...Casino.valoresFichas, valorTodo])
      valor: GlobalKey(),
  };
  _Disposicion? _d;
  GeometriaPano? _g;

  double get _ritmo => _sinMovimiento ? .05 : (_rapido ? .6 : 1);

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
    _giro.value = _azarVisual.nextDouble() * 2 * math.pi;
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
    final datos = await _almacen.juego('ruleta');
    final conSonido = await _almacen.conSonido();
    if (!mounted) return;
    final mesa = MesaRuleta.desdeJson(datos, fichas: fichas);
    setState(() {
      _conSonido = conSonido;
      _mesaCargada = mesa;
      _ficha = _fichaQueAlcanza(_ficha);
      // La bola queda en el ultimo numero que salio.
      if (mesa.historial.isNotEmpty) {
        _casillaBola = ordenRueda.indexOf(mesa.historial.first);
      }
    });
    _momento(
      mesa.estadisticas.giros > 0
          ? MomentoRuleta.bienvenidaDeVuelta
          : MomentoRuleta.bienvenida,
    );
  }

  @override
  void dispose() {
    _callar?.cancel();
    _voz.terminar();
    _reloj.dispose();
    _zoom.dispose();
    _pulso.dispose();
    _giro.dispose();
    _bola.dispose();
    unawaited(_sonidos.liberar());
    unawaited(FrecuenciaPantalla.pedirAlta(activar: false));
    // Lo que esta en el paño vuelve a tus fichas: si se va a mitad de un
    // giro, el giro no cuenta.
    final mesa = _mesaCargada;
    if (mesa != null) unawaited(_guardarMesa(mesa));
    super.dispose();
  }

  Future<void> _guardarMesa(MesaRuleta mesa) => Future.wait([
    _almacen.guardarFichas(mesa.total),
    _almacen.guardarJuego('ruleta', mesa.aJson()),
  ]);

  // ================================================================== reloj
  void _alTick(Duration ahora) {
    final dt = (ahora - _ultimoCuadro).inMicroseconds / 1e6;
    _ultimoCuadro = ahora;
    _ahora = ahora;
    final trayectoria = _trayectoria;
    if (trayectoria != null) {
      final s = (ahora - _inicioGiro).inMicroseconds / 1e6;
      _giro.value = trayectoria.anguloRueda(s);
      _bola.value = trayectoria.bola(s);
      final golpes = trayectoria.golpes;
      while (_siguienteGolpe < golpes.length &&
          golpes[_siguienteGolpe].segundo <= s) {
        final golpe = golpes[_siguienteGolpe++];
        switch (golpe.tipo) {
          case TipoGolpe.lanzamiento:
            _sonar(SonidoMesa.bolaRueda, volumen: .85);
          case TipoGolpe.rombo:
            if (_conSonido) _sonidos.detener(SonidoMesa.bolaRueda);
            _sonar(SonidoMesa.bolaGolpe, volumen: golpe.fuerza);
          case TipoGolpe.casilla:
            _sonar(SonidoMesa.bolaToc, volumen: .95 * golpe.fuerza);
        }
      }
      return;
    }
    // Entre giros: el cilindro sigue, frenando hasta su paso de siempre.
    const reposo = 2 * math.pi * .06;
    if (dt > 0 && dt < .5) {
      _velocidad = reposo + (_velocidad - reposo) * math.exp(-dt / 6);
      _giro.value += _velocidad * dt;
    }
    final casilla = _casillaBola;
    if (casilla != null) {
      _bola.value = (
        angulo: _giro.value + TrayectoriaBola.anguloCasilla(casilla),
        radio: RadiosRueda.casillas,
        altura: 0.0,
      );
    }
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

  static const _carasDe = <MomentoRuleta, ExpresionCrupier>{
    MomentoRuleta.bienvenida: ExpresionCrupier.risa,
    MomentoRuleta.bienvenidaDeVuelta: ExpresionCrupier.guino,
    MomentoRuleta.hagan: ExpresionCrupier.canchero,
    MomentoRuleta.noVaMas: ExpresionCrupier.canchero,
    MomentoRuleta.apuestaFuerte: ExpresionCrupier.sorprendido,
    MomentoRuleta.todo: ExpresionCrupier.sorprendido,
    MomentoRuleta.ganaste: ExpresionCrupier.triste,
    MomentoRuleta.recuperaste: ExpresionCrupier.normal,
    MomentoRuleta.granPremio: ExpresionCrupier.nervioso,
    MomentoRuleta.pleno: ExpresionCrupier.sorprendido,
    MomentoRuleta.perdiste: ExpresionCrupier.feliz,
    MomentoRuleta.cero: ExpresionCrupier.risa,
    MomentoRuleta.ceroGanado: ExpresionCrupier.sorprendido,
    MomentoRuleta.racha: ExpresionCrupier.nervioso,
    MomentoRuleta.quiebra: ExpresionCrupier.triste,
    MomentoRuleta.rescate: ExpresionCrupier.guino,
  };

  void _momento(MomentoRuleta momento) => _decir(
    _frases.decir(momento),
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

  /// El centro de algo de la pantalla, en las medidas del cuerpo.
  Offset? _centroDe(GlobalKey llave) {
    final caja = llave.currentContext?.findRenderObject() as RenderBox?;
    final cuerpo =
        _llaveCuerpo.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || cuerpo == null || !caja.attached) return null;
    return caja.localToGlobal(caja.size.center(Offset.zero), ancestor: cuerpo);
  }

  Offset get _bolsillo =>
      _centroDe(_llaveFichas) ?? Offset((_d?.pano.right ?? 300) - 60, 28);

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

  /// Lo que se ve sobre el paño: lo apostado, menos lo que todavia vuela.
  ///
  /// Siempre una copia: el pintor compara con la anterior para saber si
  /// redibujar, y si fuera el mismo mapa (cambiado en el lugar) nunca
  /// veria la diferencia.
  Map<Apuesta, int> get _fichasEnPano {
    final pago = _pilasPago;
    if (pago != null) return Map.of(pago);
    return {
      for (final MapEntry(key: apuesta, value: monto) in _mesa.apuestas.entries)
        if (monto - (_enVuelo[apuesta] ?? 0) > 0)
          apuesta: monto - (_enVuelo[apuesta] ?? 0),
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

  void _alApoyar(Offset enPano) {
    if (!_libre) return;
    final g = _g;
    if (g == null) return;
    setState(() {
      _dedo = enPano;
      _presionada = g.apuestaEn(enPano);
      _aviso = null;
    });
  }

  void _alSoltar() {
    final apuesta = _presionada;
    setState(() {
      _presionada = null;
      _dedo = null;
    });
    if (apuesta == null || !_libre) return;
    final todo = _todo && _mesa.puedeIrConTodo;
    _poner(apuesta, todo ? _mesa.todo : _ficha, todo: todo);
  }

  /// Pone [valor] fichas en [apuesta]. Sin tope: con [todo] van todas las
  /// que te quedan, sean las que sean.
  void _poner(Apuesta apuesta, int valor, {bool todo = false}) {
    final g = _g!;
    final mesa = _mesa;
    if (!mesa.puedeApostar(apuesta, valor)) {
      setState(() => _aviso = 'No te alcanzan las fichas');
      RetroalimentacionHaptica.seleccion();
      return;
    }
    final desde =
        _centroDe(_llavesRack[todo ? valorTodo : valor]!) ?? _bolsillo;
    setState(() {
      mesa.apostar(apuesta, valor);
      _numeroMarcado = null;
      _ultimo = null;
      _enVuelo[apuesta] = (_enVuelo[apuesta] ?? 0) + valor;
      _volar(
        desde: desde,
        hasta: g.lugar(apuesta),
        monto: valor,
        duracion: todo ? 460 : 300,
        alLlegar: () {
          // Un all in son muchas fichas juntas: suena como un puñado.
          _sonar(todo ? SonidoMesa.fichas : SonidoMesa.ficha);
          setState(() => _quitarDelVuelo(apuesta, valor));
        },
      );
      _todo = false;
      _ficha = _fichaQueAlcanza(_ficha);
    });
    if (todo) {
      RetroalimentacionHaptica.accion();
      _avisoFuerte = true;
      _momento(MomentoRuleta.todo);
      return;
    }
    RetroalimentacionHaptica.seleccion();
    if (!_avisoFuerte && mesa.enMesa >= 500 && mesa.enMesa >= mesa.total / 2) {
      _avisoFuerte = true;
      _momento(
        mesa.fichas < MesaRuleta.apuestaMinima
            ? MomentoRuleta.todo
            : MomentoRuleta.apuestaFuerte,
      );
    }
  }

  void _quitarDelVuelo(Apuesta apuesta, int monto) {
    final queda = (_enVuelo[apuesta] ?? 0) - monto;
    if (queda > 0) {
      _enVuelo[apuesta] = queda;
    } else {
      _enVuelo.remove(apuesta);
    }
  }

  /// Las fichas que vuelven del paño a tu bolsillo.
  void _devolver(Map<Apuesta, int> fichas) {
    final g = _g!;
    final bolsillo = _bolsillo;
    var i = 0;
    for (final MapEntry(key: apuesta, value: monto) in fichas.entries) {
      _porLlegar += monto;
      final primero = i == 0;
      _volar(
        desde: g.lugar(apuesta),
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
    final (apuesta, monto) = quitada;
    setState(() => _devolver({apuesta: monto}));
    RetroalimentacionHaptica.seleccion();
  }

  void _borrar() {
    if (!_libre || !_mesa.hayApuestas) return;
    setState(() => _devolver(_mesa.borrar()));
    RetroalimentacionHaptica.seleccion();
  }

  /// Repetir la ronda anterior, o doblar lo que hay: las fichas salen de tu
  /// bolsillo hacia el paño.
  void _ponerVarias(List<(Apuesta, int)> Function() cambio) {
    if (!_libre) return;
    final g = _g!;
    final bolsillo = _bolsillo;
    setState(() {
      final puestas = cambio();
      for (final (i, (apuesta, monto)) in puestas.indexed) {
        _enVuelo[apuesta] = (_enVuelo[apuesta] ?? 0) + monto;
        _volar(
          desde: bolsillo,
          hasta: g.lugar(apuesta),
          monto: monto,
          retraso: 35 * i,
          duracion: 420,
          alLlegar: () {
            if (i == 0) _sonar(SonidoMesa.fichas);
            setState(() => _quitarDelVuelo(apuesta, monto));
          },
        );
      }
      _numeroMarcado = null;
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
    _momento(MomentoRuleta.rescate);
    unawaited(_guardarMesa(_mesa));
  }

  // ================================================================== girar
  int _siguienteNumero() {
    final forzados = widget.numeros;
    if (forzados != null && forzados.isNotEmpty) {
      return forzados[_numerosUsados++ % forzados.length];
    }
    return MesaRuleta.sortear(_azar);
  }

  Future<void> _girar() async {
    if (!_libre || !_mesa.hayApuestas || _vuelos.isNotEmpty) return;
    final numero = _siguienteNumero();
    final casilla = ordenRueda.indexOf(numero);
    RetroalimentacionHaptica.accion();
    _sonar(SonidoMesa.boton, volumen: .7);
    setState(() {
      _fase = _Fase.girando;
      _todo = false;
      _numeroMarcado = null;
      _ganadora = null;
      _presionada = null;
      _aviso = null;
      _avisoFuerte = false;
    });
    _momento(MomentoRuleta.noVaMas);
    await _zoom.animateTo(1, duration: _dur(560), curve: Curves.easeInOutCubic);
    if (!mounted) return;
    // El crupier lanza la bola desde arriba, en contra del cilindro.
    final trayectoria = TrayectoriaBola(
      casilla: casilla,
      ruedaInicial: _giro.value,
      bolaInicial: -math.pi / 2 + (_azarVisual.nextDouble() - .5) * .6,
      escala: _sinMovimiento ? .08 : (_rapido ? .62 : 1),
      azar: _azarVisual,
    );
    setState(() {
      _casillaBola = null;
      _trayectoria = trayectoria;
      _inicioGiro = _ahora;
      _siguienteGolpe = 0;
    });
    await Future<void>.delayed(
      Duration(milliseconds: (trayectoria.duracion * 1000).round() + 250),
    );
    if (!mounted) return;
    // Quieta en su casilla: el crupier canta el numero.
    setState(() {
      _ganadora = casilla;
      _mostrarNumero = true;
    });
    unawaited(_pulso.repeat(reverse: true));
    _decir(
      '¡${numeroDicho(numero)[0].toUpperCase()}${numeroDicho(numero).substring(1)}!',
      expresion: ExpresionCrupier.sorprendido,
    );
    await _esperar(1400);
    if (!mounted) return;
    await _zoom.animateBack(
      0,
      duration: _dur(520),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    // La rueda sigue girando sola, con la bola en su casilla.
    final s = (_ahora - _inicioGiro).inMicroseconds / 1e6;
    final antes = trayectoria.anguloRueda(s - .02);
    final despues = trayectoria.anguloRueda(s);
    setState(() {
      _velocidad = math.max(2 * math.pi * .06, (despues - antes) / .02);
      _trayectoria = null;
      _casillaBola = casilla;
      _mostrarNumero = false;
      _numeroMarcado = numero;
    });
    await _pagar(numero);
  }

  // ================================================================== pagar
  Future<void> _pagar(int numero) async {
    final g = _g!;
    final d = _d!;
    final antes = Map.of(_mesa.apuestas);
    final resultado = _mesa.liquidar(numero);
    setState(() {
      _fase = _Fase.pagando;
      _pilasPago = antes;
      _porLlegar += resultado.cobrado;
    });
    // Lo que perdio se lo lleva MacIAs.
    if (resultado.perdedoras.isNotEmpty) {
      setState(() {
        for (final (i, perdida) in resultado.perdedoras.indexed) {
          _pilasPago!.remove(perdida.apuesta);
          _volar(
            desde: g.lugar(perdida.apuesta),
            hasta: d.banca,
            monto: perdida.monto,
            retraso: 25 * i,
            duracion: 520,
            desvanecer: true,
            alLlegar: i == 0
                ? () => _sonar(SonidoMesa.fichas, volumen: .5)
                : null,
          );
        }
      });
      await _esperar(620 + 25 * math.min(resultado.perdedoras.length, 12));
      if (!mounted) return;
    }
    // MacIAs paga cada apuesta ganadora sobre su lugar.
    if (resultado.ganadoras.isNotEmpty) {
      setState(() {
        for (final (i, ganada) in resultado.ganadoras.indexed) {
          _volar(
            desde: d.banca,
            hasta: g.lugar(ganada.apuesta),
            monto: ganada.cobra - ganada.monto,
            retraso: 70 * i,
            duracion: 480,
            alLlegar: () {
              _sonar(SonidoMesa.fichas);
              setState(() => _pilasPago?[ganada.apuesta] = ganada.cobra);
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
          _pilasPago!.remove(ganada.apuesta);
          _volar(
            desde: g.lugar(ganada.apuesta),
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
    _pulso
      ..stop()
      ..value = 1;
    setState(() {
      _pilasPago = null;
      _porLlegar = 0;
      _ultimo = resultado;
      _fase = _Fase.apostando;
      _ficha = _fichaQueAlcanza(_ficha);
    });
    unawaited(_guardarMesa(_mesa));
    if (_mesa.enQuiebra) {
      await _esperar(1600);
      if (mounted && _mesa.enQuiebra) _momento(MomentoRuleta.quiebra);
    }
  }

  void _reaccionar(ResultadoRuleta resultado) {
    final numero = resultado.numero;
    final grande = resultado.neto >= math.max(500, resultado.apostado * 5);
    final MomentoRuleta momento;
    if (resultado.acertoPleno && numero == 0) {
      momento = MomentoRuleta.ceroGanado;
    } else if (resultado.acertoPleno) {
      momento = MomentoRuleta.pleno;
    } else if (grande) {
      momento = MomentoRuleta.granPremio;
    } else if (resultado.neto > 0) {
      momento = _mesa.estadisticas.rachaActual >= 3
          ? MomentoRuleta.racha
          : MomentoRuleta.ganaste;
    } else if (resultado.cobrado > 0) {
      momento = MomentoRuleta.recuperaste;
    } else if (numero == 0) {
      momento = MomentoRuleta.cero;
    } else {
      momento = MomentoRuleta.perdiste;
    }
    _momento(momento);
    if (resultado.acertoPleno || grande) {
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
              SwitchListTile(
                secondary: const Icon(
                  Icons.speed_rounded,
                  color: ColoresCarta.oroClaro,
                ),
                title: const Text(
                  'Giro rápido',
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
    backgroundColor: const Color(0xFF1A1614),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (hoja) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TituloHojaMesa('Cómo se juega'),
            const ReglaMesa(
              'La ruleta europea',
              'Treinta y siete números, del 0 al 36, con un solo cero. Eliges '
                  'una ficha, la pones en el paño y MacIAs lanza la bola.',
            ),
            const ReglaMesa(
              'Dónde apostar',
              'Mantén el dedo sobre el paño: se iluminan los números que '
                  'cubre esa apuesta y lo que paga. Al soltar, va la ficha. En '
                  'el centro de un número, un pleno; sobre la línea entre dos, '
                  'un caballo; en una esquina, un cuadro; en el borde de '
                  'afuera, una calle o una línea.',
            ),
            const TituloHojaMesa('Lo que paga'),
            for (final (nombre, paga) in const [
              ('Pleno (un número)', 35),
              ('Caballo (dos)', 17),
              ('Calle o trío (tres)', 11),
              ('Cuadro o los cuatro primeros', 8),
              ('Línea (seis)', 5),
              ('Docena o columna (doce)', 2),
              ('Rojo, negro, par, impar, 1-18, 19-36', 1),
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
                      '$paga a 1',
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
              'All in',
              'La ficha ALL IN pone todas tus fichas de golpe en el lugar que '
                  'toques. No hay tope: se puede apostar hasta la última.',
            ),
            const ReglaMesa(
              'El cero',
              'Si sale el cero, pierden las apuestas de afuera (rojo, negro, '
                  'par, impar, docenas, columnas). Por eso la casa siempre '
                  'tiene una pequeña ventaja.',
            ),
            const ReglaMesa(
              'El azar',
              'El número sale del azar seguro del teléfono antes de lanzar: '
                  'la bola solo lo muestra. Ni MacIAs sabe dónde va a caer.',
            ),
            const ReglaMesa(
              'Las fichas',
              'Son las del casino: las mismas del blackjack. Son de juego, no '
                  'valen dinero ni se compran. Si te quedas sin ninguna, MacIAs '
                  'te presta.',
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _estadisticas() {
    final e = _mesa.estadisticas;
    final calientes = e.masSalidos(5);
    final datos = [
      ('Giros', conMiles(e.giros)),
      ('Giros ganados', conMiles(e.ganados)),
      ('Victorias', '${e.porcentajeGanados} %'),
      ('Apostado', conMiles(e.apostado)),
      ('Cobrado', conMiles(e.cobrado)),
      ('Balance', conMiles(e.cobrado - e.apostado)),
      ('Mayor premio', conMiles(e.mayorPremio)),
      ('Plenos acertados', conMiles(e.plenos)),
      ('Mejor racha', conMiles(e.mejorRacha)),
      ('Récord de fichas', conMiles(e.fichasMaximas)),
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
              if (calientes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Los que más salieron',
                  style: TextStyle(
                    color: ConfiguracionTema.crema.withValues(alpha: .75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final n in calientes)
                      _NumeroSalido(numero: n, veces: e.veces[n]),
                  ],
                ),
              ],
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.5),
            radius: 1.3,
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
    final d = _d = _Disposicion(cuerpo);
    final g = _g = _g?.area == d.pano ? _g! : GeometriaPano(d.pano);
    final presionada = _presionada;
    return Stack(
      key: _llaveCuerpo,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: PintorPano(g))),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: PintorMarcasPano(
                g: g,
                presionada: presionada,
                ganador: _numeroMarcado,
                latido: _pulso,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: PintorFichasPano(g: g, apuestas: _fichasEnPano),
              ),
            ),
          ),
        ),
        // El dedo sobre el paño.
        Positioned.fromRect(
          rect: d.pano,
          child: Semantics(
            label: 'El paño de la ruleta',
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _alApoyar(e.localPosition + d.pano.topLeft),
              onPointerMove: (e) => _alApoyar(e.localPosition + d.pano.topLeft),
              onPointerUp: (_) => _alSoltar(),
              onPointerCancel: (_) => setState(() {
                _presionada = null;
                _dedo = null;
              }),
            ),
          ),
        ),
        if (presionada != null && _dedo != null)
          _Etiqueta(
            apuesta: presionada,
            dedo: _dedo!,
            limites: d.pano,
            enLaMesa: _mesa.montoEn(presionada),
            todo: _todo && _mesa.puedeIrConTodo ? _mesa.todo : null,
          ),
        if (_aviso != null)
          Positioned(
            left: d.pano.left,
            right: cuerpo.width - d.pano.right,
            top: d.pano.top + 6,
            child: Center(child: _Aviso(texto: _aviso!)),
          ),
        // La sala se oscurece mientras gira la rueda.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _zoom,
              builder: (context, _) => ColoredBox(
                color: Colors.black.withValues(alpha: .62 * _zoom.value),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _zoom,
          builder: (context, hijo) {
            final rect = Rect.lerp(
              d.ruedaChica,
              d.ruedaGrande,
              Curves.easeInOutCubic.transform(_zoom.value),
            )!;
            return Positioned.fromRect(rect: rect, child: hijo!);
          },
          child: RuedaRuleta(
            giro: _giro,
            bola: _bola,
            ganadora: _ganadora,
            brillo: _pulso,
          ),
        ),
        if (_mostrarNumero && _numeroMarcado == null && _ganadora != null)
          Positioned.fromRect(
            rect: Rect.fromCenter(
              center: d.ruedaGrande.center,
              width: 140,
              height: 140,
            ),
            child: _NumeroGrande(numero: ordenRueda[_ganadora!]),
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
                  alignment: Alignment.topRight,
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
        Positioned.fromRect(
          rect: d.historial,
          child: _Historial(numeros: _mesa.historial),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _Disposicion.altoBarra,
          child: BarraMesa(
            llaveFichas: _llaveFichas,
            fichas: _fichasEnPantalla,
            titulo: 'Ruleta de MacIAs',
            subtitulo: 'Europea · un solo cero',
            alMenu: _menu,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: d.controles,
          child: _panelControles(),
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
                        ? 'En el paño: ${conMiles(mesa.enMesa)}'
                        : 'Elige una ficha y toca el paño',
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
                  texto: _fase == _Fase.apostando ? 'Girar' : 'Girando…',
                  icono: Icons.motion_photos_on_rounded,
                  estilo: EstiloBoton.principal,
                  resaltado: libre && mesa.hayApuestas,
                  alPresionar: libre && mesa.hayApuestas ? _girar : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lo que dice la apuesta que esta bajo el dedo, arriba del dedo.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.apuesta,
    required this.dedo,
    required this.limites,
    required this.enLaMesa,
    this.todo,
  });

  final Apuesta apuesta;
  final Offset dedo;
  final Rect limites;
  final int enLaMesa;

  /// Con la ficha ALL IN elegida: cuantas fichas se van a jugar.
  final int? todo;

  @override
  Widget build(BuildContext context) {
    const ancho = 210.0;
    final x = (dedo.dx - ancho / 2).clamp(
      limites.left + 4,
      limites.right - ancho - 4,
    );
    final arriba = dedo.dy - 78 < limites.top;
    final y = arriba ? dedo.dy + 30 : dedo.dy - 78;
    return Positioned(
      left: x,
      top: y,
      width: ancho,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xF0141210),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColoresRuleta.oro.withValues(alpha: .8)),
            boxShadow: const [
              BoxShadow(color: Color(0x88000000), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                apuesta.nombre,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ConfiguracionTema.crema,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              Text(
                todo != null
                    ? 'ALL IN ${conMiles(todo!)} · paga ${apuesta.tipo.paga} a 1'
                    : 'Paga ${apuesta.tipo.paga} a 1'
                          '${enLaMesa > 0 ? ' · tienes ${conMiles(enLaMesa)}' : ''}',
                style: const TextStyle(
                  color: ColoresRuleta.oroClaro,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un aviso corto sobre el paño ("no te alcanzan las fichas").
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

/// El numero que salio, grande, sobre la rueda.
class _NumeroGrande extends StatelessWidget {
  const _NumeroGrande({required this.numero});

  final int numero;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutBack,
    builder: (context, t, hijo) => Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(scale: .5 + .5 * t, child: hijo),
    ),
    child: Semantics(
      liveRegion: true,
      label: 'Salió el ${numeroDicho(numero)}',
      excludeSemantics: true,
      child: Center(
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColoresRuleta.de(numero),
            border: Border.all(color: ColoresRuleta.oroClaro, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0xAA000000), blurRadius: 18),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$numero',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 46,
                  height: 1,
                ),
              ),
              Text(
                detalleNumero(numero).split(' · ').first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Los ultimos numeros que salieron: el mas nuevo primero, mas grande.
class _Historial extends StatelessWidget {
  const _Historial({required this.numeros});

  final List<int> numeros;

  @override
  Widget build(BuildContext context) => Semantics(
    label: numeros.isEmpty
        ? 'Todavía no salió ningún número'
        : 'Últimos números: ${numeros.take(6).join(', ')}',
    excludeSemantics: true,
    child: LayoutBuilder(
      builder: (context, caja) {
        final cuantos = math.max(1, ((caja.maxWidth - 4) / 24).floor());
        return Row(
          children: [
            if (numeros.isEmpty)
              Flexible(
                child: Text(
                  'Los últimos números aparecen acá',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ConfiguracionTema.crema.withValues(alpha: .45),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            for (final (i, n) in numeros.take(cuantos).indexed)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 21,
                  height: 21,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColoresRuleta.de(n),
                    border: Border.all(
                      color: i == 0
                          ? ColoresRuleta.oroClaro
                          : Colors.white.withValues(alpha: .25),
                      width: i == 0 ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '$n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _NumeroSalido extends StatelessWidget {
  const _NumeroSalido({required this.numero, required this.veces});

  final int numero;
  final int veces;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColoresRuleta.de(numero),
          border: Border.all(color: ColoresRuleta.oroClaro),
        ),
        child: Text(
          '$numero',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        '$veces ${veces == 1 ? 'vez' : 'veces'}',
        style: TextStyle(
          color: ConfiguracionTema.crema.withValues(alpha: .6),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
