import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../elementos_compartidos/marca/marca_u_market.dart';

/// Primera escena visible al abrir U market.
///
/// Replica la composición de marca de la pantalla de acceso sin depender de
/// ella. De este modo sus curvas y efectos podrán evolucionar después sin
/// alterar el formulario de inicio de sesión.
class PantallaApertura extends StatefulWidget {
  const PantallaApertura({super.key});

  // ================================================================
  // POSICIÓN DE "U MARKET"
  // ================================================================
  // Cero significa el centro exacto de la pantalla.
  // Horizontal: negativo mueve a la izquierda; positivo, a la derecha.
  static const double moverMarcaHorizontal = 0;

  // Vertical: negativo mueve hacia arriba; positivo, hacia abajo.
  static const double moverMarcaVertical = 0;

  @override
  State<PantallaApertura> createState() => _PantallaAperturaState();
}

class _PantallaAperturaState extends State<PantallaApertura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controladorEntrada;
  late final Animation<double> _progresoEntrada;
  late final Animation<double> _escalaMarca;
  late final Animation<Color?> _colorMarca;

  @override
  void initState() {
    super.initState();
    _controladorEntrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
    _progresoEntrada = CurvedAnimation(
      parent: _controladorEntrada,
      // La marca termina antes que el controlador para dejar sitio a las
      // entradas escalonadas de los tres rectángulos.
      curve: const Interval(0, .70, curve: Curves.easeInOutCubic),
    );
    _escalaMarca = Tween<double>(begin: .52, end: 1).animate(_progresoEntrada);
    _colorMarca = ColorTween(
      // La marca comienza clara, no transparente.
      begin: const Color(0xFFB7B7B7),
      end: Colors.black,
    ).animate(_progresoEntrada);

    // Primera escena: durante este instante solo se ve el fondo.
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _controladorEntrada.forward();
    });
  }

  @override
  void dispose() {
    _controladorEntrada.dispose();
    super.dispose();
  }

  /// Conserva una U tipográfica invisible para que `market` permanezca en la
  /// misma coordenada. El símbolo se dibuja encima de ese espacio y puede ser
  /// un poco más grande sin desplazar el resto de la marca.
  Widget _marca(Color color, double progreso) {
    final aclarado = 1 - progreso.clamp(0.0, 1.0);
    final escalaColor = 1 - aclarado;
    final desplazamientoColor = 183 * aclarado;

    return Semantics(
      label: MarcaUMarket.nombre,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: color,
                  fontFamily: 'Nunito',
                  fontSize: 40,
                  letterSpacing: -1.4,
                ),
                children: [
                  // Reserva exactamente el ancho de la U anterior.
                  const TextSpan(
                    text: 'U',
                    style: TextStyle(
                      color: Colors.transparent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' market',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Positioned(
              left: -22,
              top: -12,
              bottom: -4,
              width: 64,
              child: ColorFiltered(
                // Empieza gris junto con la palabra y recupera gradualmente
                // el negro y morado originales sin variar su transparencia.
                colorFilter: ColorFilter.matrix([
                  escalaColor,
                  0,
                  0,
                  0,
                  desplazamientoColor,
                  0,
                  escalaColor,
                  0,
                  0,
                  desplazamientoColor,
                  0,
                  0,
                  escalaColor,
                  0,
                  desplazamientoColor,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: Image.asset(
                  'assets/images/marca/u-market-simbolo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final escritorio = restricciones.maxWidth >= 900;
          return Stack(
            children: [
              _FormasDecorativasApertura(progreso: _controladorEntrada),
              if (escritorio) ...[
                Positioned(
                  top: 25,
                  left: 0,
                  right: 0,
                  child: _BuhosApertura(ancho: restricciones.maxWidth),
                ),
              ] else
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: restricciones.maxHeight,
                      maxWidth: double.infinity,
                    ),
                    // En el acceso original, el formulario hace que la
                    // columna sea más alta que la pantalla y por eso empieza
                    // arriba. Aquí no existe ese formulario: usar `Center`
                    // centraría el bloque corto y bajaría logo y búhos.
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 430,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 25,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: const [],
                              ),
                            ),
                            _BuhosApertura(ancho: restricciones.maxWidth),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // La marca se posiciona aparte para que siempre quede en el
              // centro real, independientemente del tamaño de los búhos.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controladorEntrada,
                  builder: (context, _) {
                    // Desde el centro, este desplazamiento inicial coloca la
                    // marca completamente debajo del límite de la pantalla.
                    final desplazamientoVertical = Tween<double>(
                      begin: restricciones.maxHeight * .68,
                      end: PantallaApertura.moverMarcaVertical,
                    ).transform(_progresoEntrada.value);

                    return Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: Offset(
                          PantallaApertura.moverMarcaHorizontal,
                          desplazamientoVertical,
                        ),
                        child: Transform.scale(
                          scale: _escalaMarca.value,
                          child: _marca(
                            _colorMarca.value ?? Colors.black,
                            _progresoEntrada.value,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Copia los mismos valores de tamaño y posición de los búhos del acceso.
/// Este bloque queda aislado para poder pulir después su entrada y sus curvas.
class _BuhosApertura extends StatelessWidget {
  const _BuhosApertura({required this.ancho});

  final double ancho;

  static const double _tamanoBuhos = .7;
  static const double _compensacionBordeDerecho = .15;
  static const double _posicionVerticalBuhos = 0;
  static const double _proporcionAlto = .38;

  @override
  Widget build(BuildContext context) {
    final alto = ancho * _proporcionAlto;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            height: alto,
            child: OverflowBox(
              alignment: Alignment.center,
              minWidth: ancho,
              maxWidth: ancho,
              minHeight: alto,
              maxHeight: alto,
              child: SizedBox(
                width: ancho,
                height: alto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right:
                          -(ancho * _compensacionBordeDerecho * _tamanoBuhos),
                      top: _posicionVerticalBuhos,
                      width: ancho,
                      height: alto,
                      child: Transform.scale(
                        scale: _tamanoBuhos,
                        alignment: Alignment.centerRight,
                        // Los búhos siguen montados y conservan su espacio,
                        // pero no se pintan. Cambiar a 1 los vuelve visibles
                        // sin alterar ninguna posición.
                        child: Opacity(
                          opacity: 0,
                          child: Lottie.asset(
                            'assets/animations/owls.json',
                            fit: BoxFit.cover,
                            repeat: true,
                            frameRate: const FrameRate(24),
                            filterQuality: FilterQuality.low,
                            backgroundLoading: true,
                          ),
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
    );
  }
}

/// Mantiene las manchas en las posiciones exactas de la pantalla de acceso.
class _FormasDecorativasApertura extends StatelessWidget {
  const _FormasDecorativasApertura({required this.progreso});

  final Animation<double> progreso;

  /// Lleva cada forma desde fuera de su borde hasta cero, que es exactamente
  /// la posición que ya tenía antes de agregar esta animación.
  double _desplazamiento({
    required double inicio,
    required double desde,
    required double hasta,
  }) {
    final avance = Interval(
      desde,
      hasta,
      curve: Curves.easeOutCubic,
    ).transform(progreso.value);
    return Tween<double>(begin: inicio, end: 0).transform(avance);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progreso,
    builder: (context, _) => IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 150,
            right: -28,
            child: Transform.translate(
              // Primero: entra desde el borde derecho.
              offset: Offset(
                _desplazamiento(inicio: 150, desde: .12, hasta: .32),
                0,
              ),
              child: Transform.rotate(
                angle: .24,
                child: _forma(context, 105, 92),
              ),
            ),
          ),
          Positioned(
            top: 290,
            left: -36,
            child: Transform.translate(
              // Segundo: entra desde el borde izquierdo.
              offset: Offset(
                _desplazamiento(inicio: -155, desde: .31, hasta: .51),
                0,
              ),
              child: Transform.rotate(
                angle: -.22,
                child: _forma(context, 112, 94),
              ),
            ),
          ),
          Positioned(
            top: 355,
            right: -20,
            child: Transform.translate(
              // Tercero: entra desde el borde derecho.
              offset: Offset(
                _desplazamiento(inicio: 140, desde: .50, hasta: .70),
                0,
              ),
              child: Transform.rotate(
                angle: .3,
                child: _forma(context, 92, 82),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _forma(BuildContext context, double ancho, double alto) => Container(
    width: ancho,
    height: alto,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(24),
    ),
  );
}
