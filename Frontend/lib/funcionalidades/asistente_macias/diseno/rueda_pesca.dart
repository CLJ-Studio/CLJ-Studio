import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logica/mesa_pesca.dart';
import 'dibujos_pesca.dart';

/// Lo que hacen las luces del marco.
enum ModoLuces {
  /// Esperando: una ola lenta que recorre el marco.
  reposo,

  /// Girando: corren alrededor, mas rapido cuanto mas rapido gira.
  giro,

  /// Salio algo que gano: titilan todas, alternadas.
  premio,

  /// Salio un pez: corren del color del pez.
  bono,
}

/// Lo que se mueve en la rueda ademas del giro: la aguja que golpea, la
/// casilla que salio (con su cubo de hielo o su brillo), la moneda de oro
/// del centro y las luces del marco. Cambia todo el tiempo mientras gira:
/// la rueda solo se repinta, no se reconstruye.
class EfectosRueda extends ChangeNotifier {
  /// Cuanto se dobla la aguja (0 quieta, 1 lo mas que se dobla).
  double _aguja = 0;
  double get aguja => _aguja;
  set aguja(double valor) {
    if (valor == _aguja) return;
    _aguja = valor;
    notifyListeners();
  }

  /// Lo rapido que gira la rueda, en radianes por segundo: si va muy
  /// rapido, el disco se ve borroso.
  double velocidad = 0;

  /// La casilla que salio, y cuanto se ve su efecto (0 a 1).
  int? _ganadora;
  double _efecto = 0;
  int? get ganadora => _ganadora;
  double get efecto => _efecto;
  void marcar(int? casilla, double efecto) {
    if (casilla == _ganadora && efecto == _efecto) return;
    _ganadora = casilla;
    _efecto = efecto;
    notifyListeners();
  }

  /// La moneda de oro en el centro: cuanto giro (de canto a cara), lo que
  /// dice y cuanto se ve (0 el hielo de siempre, 1 la moneda).
  double _monedaGiro = 0;
  String? _monedaTexto;
  double _moneda = 0;
  double get monedaGiro => _monedaGiro;
  String? get monedaTexto => _monedaTexto;
  double get moneda => _moneda;
  void ponerMoneda({double? giro, String? texto, double? visible}) {
    _monedaGiro = giro ?? _monedaGiro;
    _monedaTexto = texto;
    _moneda = visible ?? _moneda;
    notifyListeners();
  }

  /// El reloj de las luces del marco (y de los brillos), en segundos. Va
  /// aparte: las luces se repintan solas sin repintar la rueda.
  final reloj = ValueNotifier<double>(0);
  ModoLuces modoLuces = ModoLuces.reposo;

  /// El color de las luces en el bono: el del pez que salio.
  Color? colorBono;

  @override
  void dispose() {
    reloj.dispose();
    super.dispose();
  }
}

/// Las medidas de la rueda, en fracciones del radio.
abstract final class MedidasRueda {
  static const centro = .2;
  static const anillo = .86;
  static const borde = .95;
  static const iconos = .79;
  static const etiquetas = .64;

  /// Las lamparitas del marco.
  static const luces = 30;

  /// Lo que ocupa una casilla, en radianes.
  static double get casilla => 2 * math.pi / RuedaPesca.cantidad;

  /// La casilla que queda bajo la aguja con la rueda girada [giro].
  static int bajoLaAguja(double giro) {
    final i = (-giro / casilla).round() % RuedaPesca.cantidad;
    return i < 0 ? i + RuedaPesca.cantidad : i;
  }

  /// El angulo del centro de la casilla [i], con la rueda girada [giro].
  static double anguloDe(int i, double giro) =>
      -math.pi / 2 + i * casilla + giro;
}

/// La rueda de la pesca: 53 casillas que giran bajo una aguja fija, con su
/// marco de luces, la nieve encima y el centro de hielo.
class RuedaPescaVista extends StatefulWidget {
  const RuedaPescaVista({
    required this.giro,
    required this.efectos,
    required this.multiplicadores,
    super.key,
  });

  final ValueListenable<double> giro;
  final EfectosRueda efectos;

  /// Los que ya cayeron sobre la rueda (las bolas de nieve aparecen de a
  /// una).
  final Multiplicadores multiplicadores;

  @override
  State<RuedaPescaVista> createState() => _RuedaPescaVistaState();
}

class _RuedaPescaVistaState extends State<RuedaPescaVista> {
  /// La rueda dibujada una vez y convertida en imagen: girarla en cada
  /// cuadro es solo girar la imagen, a cualquier tasa de la pantalla.
  ui.Image? _disco;
  ui.Image? _marco;
  double _radioGrabado = 0;
  double _escalaGrabada = 0;
  Multiplicadores? _multiplicadoresGrabados;

  @override
  void dispose() {
    _disco?.dispose();
    _marco?.dispose();
    super.dispose();
  }

  void _grabar(double radio, double escala) {
    final mismoTamano = radio == _radioGrabado && escala == _escalaGrabada;
    if (mismoTamano &&
        identical(_multiplicadoresGrabados, widget.multiplicadores)) {
      return;
    }
    if (!mismoTamano || _marco == null) {
      _marco?.dispose();
      final dibujo = _grabarMarco(radio);
      _marco = _enImagen(dibujo, radio, escala);
      dibujo.dispose();
    }
    _disco?.dispose();
    final dibujo = _grabarDisco(radio, widget.multiplicadores);
    _disco = _enImagen(dibujo, radio, escala);
    dibujo.dispose();
    _radioGrabado = radio;
    _escalaGrabada = escala;
    _multiplicadoresGrabados = widget.multiplicadores;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, caja) {
      final lado = caja.biggest.shortestSide;
      // Los pixeles de la pantalla, y un poco mas: la camara se acerca a
      // la aguja y la rueda tiene que seguir nitida.
      final escala = MediaQuery.devicePixelRatioOf(context) * 1.65;
      _grabar(lado / 2, escala);
      return Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(lado),
              painter: _PintorRueda(
                giro: widget.giro,
                efectos: widget.efectos,
                disco: _disco!,
                marco: _marco!,
              ),
            ),
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.square(lado),
                painter: _PintorLuces(widget.efectos, widget.giro),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PintorRueda extends CustomPainter {
  _PintorRueda({
    required this.giro,
    required this.efectos,
    required this.disco,
    required this.marco,
  }) : super(repaint: Listenable.merge([giro, efectos]));

  final ValueListenable<double> giro;
  final EfectosRueda efectos;
  final ui.Image disco;
  final ui.Image marco;

  void _pintarImagen(Canvas canvas, ui.Image imagen, double r, double alfa) {
    canvas.drawImageRect(
      imagen,
      Rect.fromLTWH(0, 0, imagen.width.toDouble(), imagen.height.toDouble()),
      Rect.fromCircle(center: Offset.zero, radius: r * (1 + _margen)),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(255, 255, 255, alfa),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centro = Offset(r, r);
    final angulo = giro.value;

    canvas
      ..save()
      ..translate(r, r);
    _pintarImagen(canvas, marco, r, 1);
    canvas
      ..save()
      ..rotate(angulo);
    _pintarImagen(canvas, disco, r, 1);
    canvas.restore();
    // Muy rapido, el disco se ve borroso: dos copias transparentes que lo
    // siguen (la misma imagen, sin capas aparte).
    final velocidad = efectos.velocidad.abs();
    if (velocidad > 2.5) {
      final paso = math.min(.09, velocidad / 60 * .55);
      final fuerza = ((velocidad - 2.5) / 4).clamp(0.0, 1.0);
      for (final (k, alfa) in [(1, .34), (2, .18)]) {
        canvas
          ..save()
          ..rotate(angulo - paso * k);
        _pintarImagen(canvas, disco, r, alfa * fuerza);
        canvas.restore();
      }
    }
    canvas.restore();

    _pintarVidrio(canvas, centro, r);
    final ganadora = efectos.ganadora;
    if (ganadora != null && efectos.efecto > 0) {
      _pintarGanadora(canvas, centro, r, ganadora, angulo, efectos.efecto);
    }
    _pintarCentro(canvas, centro, r);
    _pintarAguja(canvas, centro, r, ganadora);
  }

  /// La rueda tiene un vidrio encima: el brillo de arriba a la izquierda y
  /// la sombra de abajo no giran con ella.
  void _pintarVidrio(Canvas canvas, Offset centro, double r) {
    final brillo = Rect.fromCenter(
      center: centro + Offset(-r * .3, -r * .42),
      width: r * 1.15,
      height: r * .6,
    );
    final sombra = Rect.fromCircle(
      center: centro,
      radius: r * MedidasRueda.anillo,
    );
    canvas
      ..drawOval(
        brillo,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: .2),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(brillo),
      )
      ..drawCircle(
        centro,
        r * MedidasRueda.anillo,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(.2, .35),
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: .22),
            ],
            stops: const [0, .7, 1],
          ).createShader(sombra),
      );
  }

  void _pintarGanadora(
    Canvas canvas,
    Offset centro,
    double r,
    int casilla,
    double giro,
    double t,
  ) {
    final tipo = RuedaPesca.casillas[casilla];
    final phi = MedidasRueda.anguloDe(casilla, giro);
    final a = MedidasRueda.casilla;
    if (tipo.esHielo) {
      // El hielo se congela: un cubo crece sobre la casilla, con su copo, y
      // una onda de escarcha sale hacia afuera.
      final escala = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
      final donde = centro + Offset(math.cos(phi), math.sin(phi)) * r * .76;
      final onda = (t * 1.4).clamp(0.0, 1.0);
      if (onda < 1) {
        canvas.drawCircle(
          donde,
          r * (.08 + .35 * onda),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .03 * (1 - onda)
            ..color = Colors.white.withValues(alpha: .8 * (1 - onda)),
        );
      }
      canvas
        ..save()
        ..translate(donde.dx, donde.dy)
        ..rotate(phi + math.pi / 2)
        ..scale(escala);
      final caja = Rect.fromCenter(
        center: Offset.zero,
        width: r * .26,
        height: r * .22,
      );
      pintarCuboDeHielo(canvas, caja, opacidad: t.clamp(0.0, 1.0));
      pintarCopo(
        canvas,
        Offset.zero,
        r * .06,
        tipo == Casilla.hieloBlanco
            ? ColoresPesca.hieloAzulOscuro
            : const Color(0xFF3F6B82),
      );
      canvas.restore();
      return;
    }
    // Un pez: la casilla brilla con su color (los rayos y los destellos que
    // laten van en la capa de las luces).
    final (claro, _) = ColoresPesca.deCasilla(tipo);
    final cuna = Path()
      ..moveTo(centro.dx, centro.dy)
      ..arcTo(
        Rect.fromCircle(center: centro, radius: r * MedidasRueda.anillo),
        phi - a / 2,
        a,
        false,
      )
      ..close();
    canvas
      ..drawPath(
        cuna,
        Paint()
          ..color = claro.withValues(alpha: .5 * t)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
      )
      ..drawPath(
        cuna,
        Paint()..color = Colors.white.withValues(alpha: .22 * t),
      );
  }

  void _pintarCentro(Canvas canvas, Offset centro, double r) {
    final radio = r * MedidasRueda.centro;
    final moneda = efectos.moneda;
    final reloj = efectos.reloj.value;
    if (moneda < 1) {
      // El centro: una cupula de hielo en un aro de oro, con el copo
      // grabado, el nombre y un brillo que da la vuelta despacio.
      final aro = Rect.fromCircle(center: centro, radius: radio);
      canvas
        ..drawCircle(
          centro + Offset(0, radio * .1),
          radio * 1.04,
          Paint()..color = Colors.black.withValues(alpha: .3),
        )
        ..drawCircle(
          centro,
          radio,
          Paint()
            ..shader = const SweepGradient(
              colors: [
                ColoresPesca.oroClaro,
                ColoresPesca.oroOscuro,
                ColoresPesca.oro,
                ColoresPesca.oroOscuro,
                ColoresPesca.oroClaro,
              ],
            ).createShader(aro),
        )
        ..drawCircle(
          centro,
          radio * .86,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.3, -.35),
              colors: [Colors.white, Color(0xFFDDEBF3), Color(0xFF9DBFD2)],
              stops: [0, .55, 1],
            ).createShader(aro),
        );
      pintarCopo(
        canvas,
        centro,
        radio * .62,
        Colors.white.withValues(alpha: .55),
      );
      final nombre = TextPainter(
        text: TextSpan(
          text: 'PESCA',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: radio * .42,
            letterSpacing: radio * .02,
            height: 1,
            color: const Color(0xFF3F7491),
            shadows: const [
              Shadow(color: Colors.white, offset: Offset(0, 1.2)),
              Shadow(color: Color(0x553F7491), offset: Offset(0, -.8)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      nombre.paint(
        canvas,
        centro - Offset(nombre.width / 2, nombre.height / 2),
      );
    }
    if (moneda > 0) {
      _pintarMoneda(canvas, centro, radio, moneda, reloj);
    }
  }

  /// La moneda de oro: gira de canto y se le ve el espesor, con el relieve
  /// del borde, el reflejo que se mueve con el giro y, cuando cae de cara,
  /// destellos alrededor.
  void _pintarMoneda(
    Canvas canvas,
    Offset centro,
    double radio,
    double visible,
    double reloj,
  ) {
    final giro = efectos.monedaGiro;
    final coseno = math.cos(giro);
    final ancho = coseno.abs().clamp(.07, 1.0);
    final escala = .7 + .3 * Curves.easeOutBack.transform(visible);
    final grande = radio * 1.08 * escala;
    final espesor = grande * .16 * math.sin(giro).abs();
    final lado = math.sin(giro) >= 0 ? 1.0 : -1.0;
    Color o(Color c) => c.withValues(alpha: c.a * visible);
    canvas
      ..drawCircle(
        centro,
        grande * 1.25,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  o(ColoresPesca.oro.withValues(alpha: .55)),
                  o(ColoresPesca.oro.withValues(alpha: 0)),
                ],
              ).createShader(
                Rect.fromCircle(center: centro, radius: grande * 1.25),
              ),
      )
      // El canto: se ve cuando la moneda esta de costado.
      ..drawOval(
        Rect.fromCenter(
          center: centro + Offset(espesor * lado, 0),
          width: grande * 2 * ancho,
          height: grande * 2,
        ),
        Paint()..color = o(const Color(0xFF8A6206)),
      );
    final cara = Rect.fromCenter(
      center: centro,
      width: grande * 2 * ancho,
      height: grande * 2,
    );
    canvas
      ..drawOval(
        cara,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(-.35 * coseno.sign, -.45),
            colors: [
              o(ColoresPesca.oroClaro),
              o(ColoresPesca.oro),
              o(ColoresPesca.oroOscuro),
            ],
            stops: const [0, .55, 1],
          ).createShader(cara),
      )
      ..drawOval(
        cara.deflate(grande * .13),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = grande * .06
          ..color = o(const Color(0xFFFFF1C2).withValues(alpha: .8)),
      )
      ..drawOval(
        cara.deflate(grande * .2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = grande * .03
          ..color = o(const Color(0xFF9A6E0A).withValues(alpha: .7)),
      );
    // El reflejo: una franja que cruza la cara con el giro.
    canvas
      ..save()
      ..clipPath(Path()..addOval(cara));
    final barrido = cara.left + cara.width * ((giro / math.pi) % 1);
    canvas
      ..drawRect(
        Rect.fromLTWH(
          barrido - grande * .3,
          cara.top,
          grande * .25,
          cara.height,
        ),
        Paint()..color = o(Colors.white.withValues(alpha: .35)),
      )
      ..restore();
    final texto = efectos.monedaTexto;
    if (texto != null && ancho > .3) {
      final letra = TextPainter(
        text: TextSpan(
          text: texto,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: radio * .64,
            height: 1,
            color: o(const Color(0xFF6B4A05)),
            shadows: [
              Shadow(
                color: o(const Color(0xFFFFF1C2)),
                offset: const Offset(0, 1.2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas
        ..save()
        ..translate(centro.dx, centro.dy)
        ..scale(ancho, 1);
      letra.paint(canvas, Offset(-letra.width / 2, -letra.height / 2));
      canvas.restore();
    }
  }

  /// La aguja: un cristal de hielo con borde de oro y una piedra roja,
  /// colgado de un soporte. Se dobla cuando la golpean las clavijas.
  void _pintarAguja(Canvas canvas, Offset centro, double r, int? ganadora) {
    final tipo = ganadora == null ? null : RuedaPesca.casillas[ganadora];
    final brillo = tipo?.pez == null ? 0.0 : efectos.efecto;
    final pivote = centro + Offset(0, -r * .99);
    // El soporte, que no se mueve.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pivote + Offset(0, -r * .015),
          width: r * .13,
          height: r * .06,
        ),
        Radius.circular(r * .02),
      ),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ColoresPesca.oroClaro, ColoresPesca.oroOscuro],
            ).createShader(
              Rect.fromCenter(center: pivote, width: r * .13, height: r * .07),
            ),
    );
    canvas
      ..save()
      ..translate(pivote.dx, pivote.dy)
      ..rotate(-efectos.aguja * .32);
    final cristal = Path()
      ..moveTo(0, -r * .01)
      ..lineTo(r * .07, r * .03)
      ..lineTo(0, r * .2)
      ..lineTo(-r * .07, r * .03)
      ..close();
    if (brillo > 0) {
      final (claro, _) = ColoresPesca.deCasilla(tipo!);
      canvas.drawPath(
        cristal,
        Paint()
          ..color = claro.withValues(alpha: .9 * brillo)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .06),
      );
    }
    canvas
      ..drawPath(
        cristal.shift(Offset(r * .008, r * .016)),
        Paint()..color = Colors.black.withValues(alpha: .35),
      )
      ..drawPath(
        cristal,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4FBFF), Color(0xFFA9D6EE), Color(0xFF4E8FB6)],
            stops: [0, .5, 1],
          ).createShader(Rect.fromLTRB(-r * .07, 0, r * .07, r * .2)),
      )
      // La faceta clara del cristal.
      ..drawPath(
        Path()
          ..moveTo(0, -r * .01)
          ..lineTo(-r * .07, r * .03)
          ..lineTo(0, r * .2)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: .35),
      )
      ..drawPath(
        cristal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .012
          ..strokeJoin = StrokeJoin.round
          ..color = ColoresPesca.oro,
      )
      // La piedra roja, con su brillo.
      ..drawCircle(
        Offset(0, r * .045),
        r * .026,
        Paint()..color = const Color(0xFFB0102A),
      )
      ..drawCircle(
        Offset(0, r * .045),
        r * .018,
        Paint()..color = const Color(0xFFE5394F),
      )
      ..drawCircle(
        Offset(-r * .007, r * .038),
        r * .007,
        Paint()..color = Colors.white.withValues(alpha: .85),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_PintorRueda viejo) =>
      viejo.disco != disco || viejo.marco != marco;
}

/// Las lamparitas del marco, como las de las ruedas de casino: una ola
/// lenta mientras se espera, corren cuando gira, titilan si se gana y se
/// pintan del color del pez en el bono.
class _PintorLuces extends CustomPainter {
  _PintorLuces(this.efectos, this.giro) : super(repaint: efectos.reloj);

  final EfectosRueda efectos;
  final ValueListenable<double> giro;

  /// Lo que late con el reloj encima de la rueda: el brillo que recorre la
  /// cupula, los destellos de la moneda de cara y los rayos del pez que
  /// salio.
  void _brillos(Canvas canvas, Offset centro, double r, double reloj) {
    final radio = r * MedidasRueda.centro;
    if (efectos.moneda < 1) {
      final inicio = reloj * .7;
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio * .72),
        inicio,
        .9,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radio * .08
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: inicio,
            endAngle: inicio + .9,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .7),
            ],
          ).createShader(Rect.fromCircle(center: centro, radius: radio)),
      );
    }
    final moneda = efectos.moneda;
    if (moneda > 0 && math.cos(efectos.monedaGiro).abs() > .9) {
      final grande =
          radio * 1.08 * (.7 + .3 * Curves.easeOutBack.transform(moneda));
      for (var k = 0; k < 6; k++) {
        final angulo = k * math.pi / 3 + reloj * .4;
        final brilla = .5 + .5 * math.sin(reloj * 4 + k * 1.9);
        pintarDestello(
          canvas,
          centro + Offset(math.cos(angulo), math.sin(angulo)) * grande * 1.32,
          grande * .16 * brilla * moneda,
          Colors.white.withValues(alpha: .95),
        );
      }
    }
    final ganadora = efectos.ganadora;
    final t = efectos.efecto;
    if (ganadora == null || t <= 0) return;
    final tipo = RuedaPesca.casillas[ganadora];
    if (tipo.pez == null) return;
    final (claro, _) = ColoresPesca.deCasilla(tipo);
    final phi = MedidasRueda.anguloDe(ganadora, giro.value);
    final a = MedidasRueda.casilla;
    final late = .75 + .25 * math.sin(reloj * 6);
    final rayos = Path();
    for (var k = -2; k <= 2; k++) {
      final b = phi + k * a * .9 + math.sin(reloj * 1.5 + k) * a * .15;
      final punta = centro + Offset(math.cos(b), math.sin(b)) * r * .98;
      final ancho = a * .22;
      final izquierda =
          centro + Offset(math.cos(b - ancho), math.sin(b - ancho)) * r * .3;
      final derecha =
          centro + Offset(math.cos(b + ancho), math.sin(b + ancho)) * r * .3;
      rayos
        ..moveTo(izquierda.dx, izquierda.dy)
        ..lineTo(punta.dx, punta.dy)
        ..lineTo(derecha.dx, derecha.dy)
        ..close();
    }
    canvas.drawPath(
      rayos,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .28 * t * late),
            claro.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: r)),
    );
    for (var k = 0; k < 5; k++) {
      final brilla = .5 + .5 * math.sin(reloj * 5 + k * 1.7);
      final b = phi + (k.isEven ? .6 : -.6) * a;
      pintarDestello(
        canvas,
        centro + Offset(math.cos(b), math.sin(b)) * r * (.32 + k * .12),
        r * .035 * brilla * t,
        Colors.white.withValues(alpha: .95),
        angulo: reloj,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centro = Offset(r, r);
    final t = efectos.reloj.value;
    const n = MedidasRueda.luces;
    final velocidad = efectos.velocidad.abs();
    for (var i = 0; i < n; i++) {
      final angulo = -math.pi / 2 + (i + .5) * 2 * math.pi / n;
      // Arriba esta la aguja: ahi no hay lamparita.
      if ((angulo + math.pi / 2).abs() < .15) continue;
      final double encendida;
      switch (efectos.modoLuces) {
        case ModoLuces.reposo:
          encendida =
              .25 + .75 * math.pow(math.max(0, math.sin(t * 2 - i * .42)), 3);
        case ModoLuces.giro:
          final paso = (t * (4 + velocidad * 1.1)).floor();
          encendida = (i + paso) % 4 == 0
              ? 1
              : ((i + paso) % 4 == 1 ? .45 : .15);
        case ModoLuces.premio:
          encendida = ((t * 7).floor() + i).isEven ? 1 : .15;
        case ModoLuces.bono:
          final paso = (t * 12).floor();
          encendida = (i + paso) % 3 == 0 ? 1 : .25;
      }
      final color =
          efectos.modoLuces == ModoLuces.bono && efectos.colorBono != null
          ? Color.lerp(efectos.colorBono, Colors.white, .35)!
          : i.isEven
          ? const Color(0xFFFFF2C6)
          : const Color(0xFFFFC94D);
      final donde =
          centro + Offset(math.cos(angulo), math.sin(angulo)) * r * .978;
      canvas
        ..drawCircle(
          donde,
          r * .075,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: .75 * encendida),
                color.withValues(alpha: .25 * encendida),
                color.withValues(alpha: 0),
              ],
              stops: const [0, .35, 1],
            ).createShader(Rect.fromCircle(center: donde, radius: r * .075)),
        )
        ..drawCircle(
          donde,
          r * .021,
          Paint()
            ..color = Color.lerp(const Color(0xFF4A3A1E), color, encendida)!,
        )
        ..drawCircle(
          donde,
          r * .021,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .005
            ..color = const Color(0xFF8A6206),
        )
        ..drawCircle(
          donde - Offset(r * .006, r * .006),
          r * .007,
          Paint()..color = Colors.white.withValues(alpha: .35 + .6 * encendida),
        );
    }
    _brillos(canvas, centro, r, t);
  }

  @override
  bool shouldRepaint(_PintorLuces viejo) =>
      viejo.efectos != efectos || viejo.giro != giro;
}

/// Lo que sobra alrededor de la rueda en las imagenes (en radios): la
/// sombra, la nieve de arriba y los carambanos salen del circulo.
const _margen = .15;

/// Convierte el dibujo de la rueda (centrado en el origen, de radio [r]) en
/// una imagen con [escala] pixeles por punto.
ui.Image _enImagen(ui.Picture dibujo, double r, double escala) {
  final lado = math.max(1, (2 * r * (1 + _margen) * escala).ceil());
  final grabadora = ui.PictureRecorder();
  Canvas(grabadora)
    ..scale(escala)
    ..translate(r * (1 + _margen), r * (1 + _margen))
    ..drawPicture(dibujo);
  final cuadro = grabadora.endRecording();
  final imagen = cuadro.toImageSync(lado, lado);
  cuadro.dispose();
  return imagen;
}

/// El marco que no gira: el aro oscuro con el borde de oro, los zocalos de
/// las lamparitas, la nieve que se junto arriba y los carambanos de abajo.
ui.Picture _grabarMarco(double r) {
  final grabadora = ui.PictureRecorder();
  final canvas = Canvas(grabadora);
  final rect = Rect.fromCircle(center: Offset.zero, radius: r);
  canvas
    ..drawCircle(
      const Offset(0, 6),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: .4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
    )
    ..drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF2C5367),
            ColoresPesca.marcoOscuro,
            Color(0xFF2C5367),
            ColoresPesca.marcoOscuro,
            Color(0xFF2C5367),
          ],
        ).createShader(rect),
    )
    // El borde de oro de adentro y el de cromo de afuera.
    ..drawCircle(
      Offset.zero,
      r * .956,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .014
        ..shader = const SweepGradient(
          colors: [
            ColoresPesca.oroClaro,
            ColoresPesca.oroOscuro,
            ColoresPesca.oro,
            ColoresPesca.oroOscuro,
            ColoresPesca.oroClaro,
          ],
        ).createShader(rect),
    )
    ..drawCircle(
      Offset.zero,
      r * .996,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .01
        ..color = Colors.white.withValues(alpha: .4),
    );
  // Los zocalos de las lamparitas.
  const n = MedidasRueda.luces;
  final zocalo = Paint()..color = const Color(0xFF0A1720);
  final aro = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * .005
    ..color = ColoresPesca.oroOscuro;
  for (var i = 0; i < n; i++) {
    final angulo = -math.pi / 2 + (i + .5) * 2 * math.pi / n;
    if ((angulo + math.pi / 2).abs() < .15) continue;
    final donde = Offset(math.cos(angulo), math.sin(angulo)) * r * .978;
    canvas
      ..drawCircle(donde, r * .026, zocalo)
      ..drawCircle(donde, r * .026, aro);
  }
  // La nieve que se junto arriba del marco, a los dos lados de la aguja.
  final azar = math.Random(9);
  final sombra = Paint()..color = const Color(0xFF9CC3DA);
  final nieve = Paint()..color = const Color(0xFFF7FBFE);
  for (var i = 0; i < 26; i++) {
    final lado = i.isEven ? -1 : 1;
    final angulo =
        -math.pi / 2 + lado * (.2 + (i ~/ 2) * .07 + azar.nextDouble() * .03);
    final radio = r * (.035 + azar.nextDouble() * .03) * (1 - (i ~/ 2) * .045);
    if (radio <= 0) continue;
    final donde = Offset(math.cos(angulo), math.sin(angulo)) * r * 1.0;
    canvas
      ..drawCircle(donde + Offset(0, radio * .25), radio, sombra)
      ..drawCircle(donde, radio, nieve);
  }
  // Los carambanos que cuelgan de abajo.
  final hielo = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF2FAFF), Color(0x99A9D6EE)],
    ).createShader(Rect.fromLTRB(-r, r * .8, r, r * 1.2));
  for (var i = 0; i < 9; i++) {
    final angulo = math.pi / 2 + (i - 4) * .17 + (azar.nextDouble() - .5) * .05;
    final base = Offset(math.cos(angulo), math.sin(angulo)) * r * .99;
    final largo = r * (.05 + azar.nextDouble() * .07);
    final ancho = r * .02;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - ancho, base.dy)
        ..lineTo(base.dx + ancho, base.dy)
        ..lineTo(base.dx + ancho * .1, base.dy + largo)
        ..close(),
      hielo,
    );
  }
  return grabadora.endRecording();
}

/// El disco que gira: las 53 casillas con su escarcha, las clavijas de oro
/// que golpea la aguja, el anillo de metal con sus remaches, los iconos,
/// los nombres de los peces y lo que ya cayo encima.
ui.Picture _grabarDisco(double r, Multiplicadores multiplicadores) {
  final grabadora = ui.PictureRecorder();
  final canvas = Canvas(grabadora);
  final a = MedidasRueda.casilla;
  final adentro = r * MedidasRueda.centro;
  final afuera = r * MedidasRueda.anillo;
  final azar = math.Random(53);

  for (var i = 0; i < RuedaPesca.cantidad; i++) {
    final tipo = RuedaPesca.casillas[i];
    final phi = -math.pi / 2 + i * a;
    final cuna = Path()
      ..moveTo(0, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset.zero, radius: afuera),
        phi - a / 2,
        a,
        false,
      )
      ..close();
    final (claro, oscuro) = ColoresPesca.deCasilla(tipo);
    canvas.drawPath(
      cuna,
      Paint()
        ..shader = RadialGradient(
          colors: tipo.esHielo ? [oscuro, claro] : [oscuro, claro, claro],
          stops: tipo.esHielo ? const [.25, .95] : const [.25, .8, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: afuera)),
    );
    if (tipo.esHielo) {
      // La escarcha: puntitos y rayitas claras.
      final escarcha = Paint()
        ..strokeWidth = math.max(.5, r * .004)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(
          alpha: tipo == Casilla.hieloBlanco ? .7 : .35,
        );
      for (var k = 0; k < 7; k++) {
        final radio = r * (.3 + azar.nextDouble() * .5);
        final b = phi + (azar.nextDouble() - .5) * a * .7;
        final p = Offset(math.cos(b), math.sin(b)) * radio;
        if (azar.nextBool()) {
          canvas.drawCircle(p, r * .004, escarcha);
        } else {
          final d = Offset(math.cos(b + 1), math.sin(b + 1)) * r * .012;
          canvas.drawLine(p - d, p + d, escarcha);
        }
      }
    } else {
      // Los peces tienen un borde de oro: son las casillas del bono.
      canvas.drawPath(
        cuna,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .008
          ..color = ColoresPesca.oro.withValues(alpha: .75),
      );
    }
  }

  // La sombra alrededor del centro: el disco se hunde hacia el medio.
  final hundido = Rect.fromCircle(center: Offset.zero, radius: r * .4);
  canvas.drawCircle(
    Offset.zero,
    r * .4,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: .35),
          Colors.black.withValues(alpha: 0),
        ],
        stops: const [.45, 1],
      ).createShader(hundido),
  );

  // Las lineas entre casillas, con la clavija de oro en la punta.
  final linea = Paint()
    ..strokeWidth = math.max(.6, r * .006)
    ..color = Colors.white.withValues(alpha: .55);
  final clavija = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-.4, -.4),
      colors: [ColoresPesca.oroClaro, ColoresPesca.oro, ColoresPesca.oroOscuro],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * .02));
  for (var i = 0; i < RuedaPesca.cantidad; i++) {
    final b = -math.pi / 2 + i * a - a / 2;
    final d = Offset(math.cos(b), math.sin(b));
    canvas.drawLine(d * adentro, d * afuera, linea);
    final punta = d * r * .845;
    canvas
      ..save()
      ..translate(punta.dx, punta.dy)
      ..drawCircle(
        Offset(r * .002, r * .004),
        r * .012,
        Paint()..color = Colors.black.withValues(alpha: .35),
      )
      ..drawCircle(Offset.zero, r * .011, clavija)
      ..restore();
  }

  // Lo de cada casilla: el copo del hielo, o el pez con su nombre.
  for (var i = 0; i < RuedaPesca.cantidad; i++) {
    final tipo = RuedaPesca.casillas[i];
    final phi = -math.pi / 2 + i * a;
    final d = Offset(math.cos(phi), math.sin(phi));
    final pez = tipo.pez;
    if (pez == null) {
      pintarCopo(
        canvas,
        d * r * MedidasRueda.iconos,
        r * .03,
        tipo == Casilla.hieloBlanco
            ? ColoresPesca.hieloAzul
            : Colors.white.withValues(alpha: .9),
      );
    } else {
      // El pez en la punta, mirando hacia el centro.
      canvas
        ..save()
        ..translate(d.dx * r * .78, d.dy * r * .78)
        ..rotate(phi + math.pi);
      pintarPez(
        canvas,
        Rect.fromCenter(center: Offset.zero, width: r * .15, height: r * .085),
        pez,
      );
      canvas.restore();
      // Su nombre a lo largo de la casilla, de la punta hacia el centro.
      final nombre = TextPainter(
        text: TextSpan(
          text: pez.nombre.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: r * .052,
            letterSpacing: r * .004,
            height: 1,
            color: Colors.white,
            shadows: const [Shadow(color: Color(0x99000000), blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final medio = d * r * .46;
      canvas
        ..save()
        ..translate(medio.dx, medio.dy)
        ..rotate(phi + math.pi);
      nombre.paint(canvas, Offset(-nombre.width / 2, -nombre.height / 2));
      canvas.restore();
    }
  }

  // Lo que cayo: las bolas de nieve en el hielo, la moneda en los peces.
  for (final MapEntry(key: i, value: por) in multiplicadores.nieve.entries) {
    final phi = -math.pi / 2 + i * a;
    final d = Offset(math.cos(phi), math.sin(phi));
    // La nieve de la bola que se aplasto debajo de la etiqueta.
    final mancha = Paint()..color = Colors.white.withValues(alpha: .9);
    for (final (dx, dy, rr) in [
      (-.05, .01, .035),
      (.0, -.015, .04),
      (.05, .012, .03),
      (.02, .03, .025),
    ]) {
      final p = d * r * MedidasRueda.etiquetas + Offset(dx, dy) * r;
      canvas.drawCircle(p, r * rr, mancha);
    }
    pintarMultiplicador(
      canvas,
      d * r * MedidasRueda.etiquetas,
      'x$por',
      r * .075,
      angulo: phi + math.pi,
      copo: true,
    );
  }
  final moneda = multiplicadores.moneda;
  if (moneda != null) {
    for (var i = 0; i < RuedaPesca.cantidad; i++) {
      if (RuedaPesca.casillas[i].pez != moneda.pez) continue;
      final phi = -math.pi / 2 + i * a;
      final d = Offset(math.cos(phi), math.sin(phi));
      pintarMultiplicador(
        canvas,
        d * r * .67,
        'x${moneda.por}',
        r * .085,
        angulo: phi + math.pi,
      );
    }
  }

  // El anillo de metal, con un remache entre casilla y casilla.
  final anillo = Rect.fromCircle(
    center: Offset.zero,
    radius: r * MedidasRueda.borde,
  );
  canvas.drawCircle(
    Offset.zero,
    r * (MedidasRueda.anillo + MedidasRueda.borde) / 2,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * (MedidasRueda.borde - MedidasRueda.anillo)
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFDCE3E8),
          ColoresPesca.metalOscuro,
          Color(0xFFDCE3E8),
          ColoresPesca.metalOscuro,
          Color(0xFFDCE3E8),
        ],
      ).createShader(anillo),
  );
  final remache = Paint()..color = const Color(0xFF55626B);
  final brillo = Paint()..color = Colors.white.withValues(alpha: .75);
  for (var i = 0; i < RuedaPesca.cantidad; i++) {
    final b = -math.pi / 2 + i * a - a / 2;
    final d = Offset(math.cos(b), math.sin(b)) * r * .905;
    canvas
      ..drawCircle(d, r * .014, remache)
      ..drawCircle(d - Offset(r * .004, r * .004), r * .005, brillo);
  }
  canvas
    ..drawCircle(
      Offset.zero,
      r * MedidasRueda.anillo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .008
        ..color = const Color(0xFF4C5A63),
    )
    ..drawCircle(
      Offset.zero,
      r * MedidasRueda.borde,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .008
        ..color = const Color(0xFF4C5A63),
    );
  return grabadora.endRecording();
}
