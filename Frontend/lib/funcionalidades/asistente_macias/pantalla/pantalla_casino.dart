import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/animaciones/escala_al_presionar.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/cartas_blackjack.dart';
import '../diseno/crupier_macias.dart';
import '../diseno/fichas_blackjack.dart';
import '../diseno/mesa_casino.dart';
import '../diseno/rueda_ruleta.dart';
import '../logica/almacen_casino.dart';
import '../logica/casino.dart';
import '../logica/frases_casino.dart';
import '../logica/mesa_blackjack.dart';
import '../logica/repositorio_poker.dart';
import '../logica/sonidos_casino.dart';
import '../logica/trayectoria_bola.dart';
import 'pantalla_blackjack.dart';
import 'pantalla_ruleta.dart';
import 'pantalla_salas_poker.dart';

/// La entrada del casino escondido de MacIAs: se llega escribiendole
/// "casino" en el chat.
///
/// MacIAs recibe en la puerta, se ven tus fichas (las mismas para todas las
/// mesas) y se elige a que jugar: ruleta, blackjack o poker.
class PantallaCasino extends StatefulWidget {
  const PantallaCasino({
    this.nombre = '',
    this.almacen,
    this.sonidos,
    this.sonidosDeMesas,
    this.poker,
    super.key,
  });

  final String nombre;

  /// Las fichas y lo de cada mesa. Sin indicarlo, en memoria (pruebas).
  final AlmacenCasino? almacen;

  /// Lo que suena en la entrada. Sin indicarlo, los del sistema.
  final SonidosMesa? sonidos;

  /// Lo que suena en las mesas: para las pruebas, que no suene nada.
  final SonidosMesa? sonidosDeMesas;

  /// Las mesas de poker. Sin indicarlo, las del servidor.
  final RepositorioPoker? poker;

  /// Se entra como a la mesa: las luces se prenden desde el centro.
  static Route<void> ruta({
    String nombre = '',
    AlmacenCasino? almacen,
    SonidosMesa? sonidos,
    SonidosMesa? sonidosDeMesas,
    RepositorioPoker? poker,
  }) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 560),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => PantallaCasino(
      nombre: nombre,
      almacen: almacen,
      sonidos: sonidos,
      sonidosDeMesas: sonidosDeMesas,
      poker: poker,
    ),
    transitionsBuilder: (context, animacion, _, hijo) {
      final curva = CurvedAnimation(
        parent: animacion,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curva,
        child: ScaleTransition(
          scale: Tween(begin: 1.06, end: 1.0).animate(curva),
          child: hijo,
        ),
      );
    },
  );

  @override
  State<PantallaCasino> createState() => _PantallaCasinoState();
}

class _PantallaCasinoState extends State<PantallaCasino>
    with TickerProviderStateMixin {
  static const _fondo = Color(0xFF0C0A09);

  late final AlmacenCasino _almacen =
      widget.almacen ?? AlmacenCasinoEnMemoria();
  late final SonidosMesa _sonidos =
      widget.sonidos ??
      SonidosMesa.delSistema(
        solo: const {
          SonidoMesa.boton,
          SonidoMesa.ficha,
          SonidoMesa.vozCorta,
          SonidoMesa.vozMedia,
          SonidoMesa.vozLarga,
        },
      );
  late final FrasesLobby _frases = FrasesLobby(nombre: widget.nombre);
  bool _conSonido = true;
  int? _fichas;

  // MacIAs.
  String? _dicho;
  int _latido = 0;
  ExpresionCrupier _expresion = ExpresionCrupier.normal;
  bool _hablando = false;
  Timer? _callar;

  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Lo que se mueve solo en las tarjetas: la ruleta gira, las cartas flotan.
  late final AnimationController _vida = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  late final Animation<double> _giroRueda = Tween(
    begin: 0.0,
    end: 2 * math.pi,
  ).animate(_vida);
  final _sinBola = ValueNotifier<PosicionBola?>(null);
  final _llaveFichas = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_sonidos.preparar());
    unawaited(_cargar(saludar: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(precacheImage(const AssetImage(rutaFotoCrupier), context));
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
      _vida.stop();
    } else {
      if (!_entrada.isCompleted && !_entrada.isAnimating) {
        unawaited(_entrada.forward());
      }
      if (!_vida.isAnimating) unawaited(_vida.repeat());
    }
  }

  @override
  void dispose() {
    _callar?.cancel();
    _voz.terminar();
    _entrada.dispose();
    _vida.dispose();
    _sinBola.dispose();
    unawaited(_sonidos.liberar());
    super.dispose();
  }

  Future<void> _cargar({bool saludar = false, int? antes}) async {
    final fichas = await _almacen.fichas();
    final conSonido = await _almacen.conSonido();
    final yaJugo =
        await _almacen.juego('ruleta') != null ||
        await _almacen.juego('blackjack') != null;
    if (!mounted) return;
    final ahora = fichas ?? Casino.fichasIniciales;
    setState(() {
      _fichas = ahora;
      _conSonido = conSonido;
    });
    if (saludar) {
      _momento(
        yaJugo ? MomentoLobby.bienvenidaDeVuelta : MomentoLobby.bienvenida,
        yaJugo ? ExpresionCrupier.guino : ExpresionCrupier.risa,
      );
    } else if (antes != null && ahora != antes) {
      _momento(
        ahora > antes ? MomentoLobby.ganoAlgo : MomentoLobby.perdioAlgo,
        ahora > antes ? ExpresionCrupier.sorprendido : ExpresionCrupier.guino,
      );
    }
  }

  void _momento(MomentoLobby momento, ExpresionCrupier expresion) {
    final texto = _frases.decir(momento);
    _callar?.cancel();
    _voz.terminar();
    setState(() {
      _dicho = texto;
      _latido++;
      _expresion = expresion;
    });
    _callar = Timer(
      Duration(milliseconds: texto.length * 26 + 3600 + texto.length * 24),
      () {
        if (!mounted) return;
        setState(() {
          _dicho = null;
          _hablando = false;
          _expresion = ExpresionCrupier.normal;
        });
      },
    );
  }

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

  Future<void> _jugar(Route<void> mesa) async {
    _sonar(SonidoMesa.ficha);
    RetroalimentacionHaptica.accion();
    final antes = _fichas;
    await Navigator.of(context).push(mesa);
    if (!mounted) return;
    await _cargar(antes: antes);
  }

  /// El poker no usa las fichas del casino: cada mesa da las suyas.
  void _poker() {
    _momento(MomentoLobby.poker, ExpresionCrupier.guino);
    _jugar(
      PantallaSalasPoker.ruta(
        nombre: widget.nombre,
        repositorio: widget.poker ?? const RepositorioPokerSupabase(),
        sonidos: widget.sonidosDeMesas,
        conSonido: _conSonido,
      ),
    );
  }

  /// Cada tarjeta entra un poco despues que la anterior.
  Widget _entra(int orden, Widget hijo) {
    final desde = (.18 + orden * .14).clamp(0.0, .8);
    final curva = CurvedAnimation(
      parent: _entrada,
      curve: Interval(
        desde,
        math.min(1, desde + .5),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curva,
      child: hijo,
      builder: (context, hijo) => Opacity(
        opacity: curva.value,
        child: Transform.translate(
          offset: Offset(0, 34 * (1 - curva.value)),
          child: hijo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fichas = _fichas;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _fondo,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _fondo,
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _PintorSala()),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 58,
                    child: BarraMesa(
                      llaveFichas: _llaveFichas,
                      fichas: fichas ?? 0,
                      titulo: 'Casino MacIAs',
                      subtitulo: 'Fichas de juego · no valen dinero',
                      salir: 'Salir del casino',
                    ),
                  ),
                  Expanded(
                    child: fichas == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: ColoresCarta.oro,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _entra(0, _Letrero(brillo: _vida)),
                                const SizedBox(height: 14),
                                _entra(1, _recepcion()),
                                const SizedBox(height: 18),
                                _entra(
                                  2,
                                  _TarjetaJuego(
                                    titulo: 'Ruleta',
                                    detalle: 'Europea, con un solo cero.',
                                    paga: 'Paga hasta 35 a 1',
                                    colores: const [
                                      Color(0xFF0E6A3C),
                                      Color(0xFF07351F),
                                    ],
                                    ilustracion: SizedBox.square(
                                      dimension: 112,
                                      child: RuedaRuleta(
                                        giro: _giroRueda,
                                        bola: _sinBola,
                                      ),
                                    ),
                                    etiqueta: 'Jugar a la ruleta',
                                    alTocar: () => _jugar(
                                      PantallaRuleta.ruta(
                                        nombre: widget.nombre,
                                        almacen: _almacen,
                                        sonidos: widget.sonidosDeMesas,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _entra(
                                  3,
                                  _TarjetaJuego(
                                    titulo: 'Blackjack',
                                    detalle: 'Llega a 21 sin pasarte.',
                                    paga: 'El blackjack paga 3 a 2',
                                    colores: const [
                                      Color(0xFF136A43),
                                      Color(0xFF0A3A24),
                                    ],
                                    ilustracion: _CartasQueFlotan(vida: _vida),
                                    etiqueta: 'Jugar al blackjack',
                                    alTocar: () => _jugar(
                                      PantallaBlackjack.ruta(
                                        nombre: widget.nombre,
                                        almacen: _almacen,
                                        sonidos: widget.sonidosDeMesas,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _entra(
                                  4,
                                  _TarjetaJuego(
                                    titulo: 'Póker',
                                    detalle:
                                        // Sin cortar "la U." en dos lineas.
                                        'Mesas de hasta 6, con otros de la\u00A0U.',
                                    paga: "Texas Hold'em",
                                    colores: const [
                                      Color(0xFF2C2350),
                                      Color(0xFF15102C),
                                    ],
                                    ilustracion: const _AbanicoDeAses(),
                                    etiqueta: 'Jugar al póker',
                                    alTocar: _poker,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _entra(
                                  5,
                                  Text(
                                    fichas < MesaBlackjack.apuestaMinima
                                        ? 'Sin fichas: MacIAs te presta 1.000 en '
                                              'cualquier mesa.'
                                        : 'Las fichas son de juego: no valen dinero, '
                                              'no se compran ni se cobran.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: ConfiguracionTema.crema.withValues(
                                        alpha: .5,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MacIAs en la puerta, con lo que dice.
  ///
  /// Sin alto fijo: si la letra del telefono esta agrandada, el dialogo
  /// crece hacia abajo en vez de cortarse.
  Widget _recepcion() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 112),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              CrupierMacias(
                tamano: 88,
                expresion: _expresion,
                hablando: _hablando,
                latido: _latido,
              ),
              const Positioned(top: 78, child: PlacaCrupier()),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutBack,
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
                : Align(
                    key: ValueKey(_latido),
                    alignment: Alignment.topLeft,
                    child: DialogoCrupier(
                      texto: _dicho!,
                      alHablar: (hablando) {
                        if (hablando) {
                          _voz.empezar((_dicho?.length ?? 0) * 28);
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
      ],
    ),
  );
}

/// La sala: rayos dorados que salen de arriba, como la entrada de un
/// casino art deco, y una vineta oscura.
class _PintorSala extends CustomPainter {
  const _PintorSala();

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.75),
          radius: 1.2,
          colors: [Color(0xFF3A2414), Color(0xFF16100C), Color(0xFF0C0A09)],
          stops: [0, .5, 1],
        ).createShader(todo),
    );
    final origen = Offset(size.width / 2, size.height * .1);
    final rayo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var k = 0; k < 28; k++) {
      final a = math.pi * (k + .5) / 28;
      final d = Offset(math.cos(a), math.sin(a));
      rayo.shader = LinearGradient(
        colors: [
          ColoresCarta.oro.withValues(alpha: .16),
          ColoresCarta.oro.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromPoints(origen, origen + d * size.height * .7));
      canvas.drawLine(origen, origen + d * size.height * .7, rayo);
    }
  }

  @override
  bool shouldRepaint(_PintorSala viejo) => false;
}

/// "CASINO MacIAs", en dorado, con un brillo que pasa de vez en cuando.
class _Letrero extends StatelessWidget {
  const _Letrero({required this.brillo});

  final Animation<double> brillo;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'Casino MacIAs',
    excludeSemantics: true,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final valor in const [500, 1000, 100])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FichaDibujada(valor: valor, diametro: 20),
              ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: brillo,
          builder: (context, hijo) {
            // El brillo cruza el letrero una vez por vuelta.
            final x = -1.6 + 3.2 * ((brillo.value * 4) % 1);
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment(x - .5, -.3),
                end: Alignment(x + .5, .3),
                colors: const [
                  ColoresCarta.oro,
                  Color(0xFFFFF4C9),
                  ColoresCarta.oro,
                ],
                stops: const [.3, .5, .7],
                tileMode: TileMode.clamp,
              ).createShader(rect),
              child: hijo,
            );
          },
          child: const Text(
            'CASINO MacIAs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 34,
              letterSpacing: 2.5,
              height: 1,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '— MESAS ABIERTAS —',
          style: TextStyle(
            color: ConfiguracionTema.crema.withValues(alpha: .55),
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 3,
          ),
        ),
      ],
    ),
  );
}

/// Una mesa para elegir: su dibujo, su nombre, lo que paga y "Jugar".
class _TarjetaJuego extends StatelessWidget {
  const _TarjetaJuego({
    required this.titulo,
    required this.detalle,
    required this.paga,
    required this.colores,
    required this.ilustracion,
    required this.etiqueta,
    required this.alTocar,
  });

  final String titulo;
  final String detalle;
  final String paga;
  final List<Color> colores;
  final Widget ilustracion;
  final String etiqueta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      child: EscalaAlPresionar(
        escala: .97,
        builder: (context, alResaltar) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radio,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colores,
            ),
            border: Border.all(
              color: ColoresCarta.oro.withValues(alpha: .8),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radio,
              onTap: alTocar,
              onHighlightChanged: alResaltar,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 116,
                          height: 116,
                          child: Center(child: ilustracion),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: ColoresCarta.oroClaro,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                detalle,
                                style: TextStyle(
                                  color: ConfiguracionTema.crema.withValues(
                                    alpha: .85,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                paga,
                                style: TextStyle(
                                  color: ConfiguracionTema.crema.withValues(
                                    alpha: .55,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const _Pildora(texto: 'Jugar', activa: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pildora extends StatelessWidget {
  const _Pildora({required this.texto, required this.activa});

  final String texto;
  final bool activa;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: activa
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ColoresCarta.oroClaro, ColoresCarta.oro],
            )
          : null,
      color: activa ? null : const Color(0x22FFFFFF),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          texto,
          style: TextStyle(
            color: activa
                ? const Color(0xFF2B1E05)
                : ConfiguracionTema.crema.withValues(alpha: .7),
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
        if (activa) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Color(0xFF2B1E05),
          ),
        ],
      ],
    ),
  );
}

/// El as de picas y el rey de corazones: un blackjack, flotando.
class _CartasQueFlotan extends StatelessWidget {
  const _CartasQueFlotan({required this.vida});

  final Animation<double> vida;

  static const _as = Carta(1, Palo.picas, -1);
  static const _rey = Carta(13, Palo.corazones, -2);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: vida,
    builder: (context, _) {
      final t = vida.value * 2 * math.pi * 4;
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-16, 3 * math.sin(t)),
            child: Transform.rotate(
              angle: -.2,
              child: const CartaDibujada(ancho: 58, carta: _as),
            ),
          ),
          Transform.translate(
            offset: Offset(18, -2 + 3 * math.sin(t + 1.4)),
            child: Transform.rotate(
              angle: .16,
              child: const CartaDibujada(ancho: 58, carta: _rey),
            ),
          ),
        ],
      );
    },
  );
}

/// Los cuatro ases en abanico: el poker que viene.
class _AbanicoDeAses extends StatelessWidget {
  const _AbanicoDeAses();

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      for (final (i, palo) in Palo.values.indexed)
        Transform.rotate(
          angle: (i - 1.5) * .26,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset((i - 1.5) * 9, 0),
            child: CartaDibujada(ancho: 50, carta: Carta(1, palo, -10 - i)),
          ),
        ),
    ],
  );
}
