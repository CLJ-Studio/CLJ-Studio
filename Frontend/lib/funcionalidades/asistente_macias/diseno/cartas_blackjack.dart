import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logica/mesa_blackjack.dart';

/// Los colores de la baraja de MacIAs.
abstract final class ColoresCarta {
  static const papel = Color(0xFFFFFDF8);
  static const papelSombra = Color(0xFFF0EBDF);
  static const borde = Color(0xFFD9D2C3);
  static const rojo = Color(0xFFC4242C);
  static const negro = Color(0xFF1B1A1F);
  static const oro = Color(0xFFD9A21B);
  static const oroClaro = Color(0xFFF2CC5C);

  /// El dorso va en el azul noche de la cabecera de la app.
  static const dorso = Color(0xFF262C68);
  static const dorsoOscuro = Color(0xFF151938);
}

/// Los cuatro palos, dibujados a mano.
///
/// No se escriben con los simbolos de una fuente: Nunito no los trae, y en la
/// web Flutter los buscaba en otra fuente descargada (o salian cuadraditos).
/// Dibujados son nitidos en cualquier tamano y en cualquier telefono.
abstract final class FormasPalo {
  /// El palo dentro de [caja].
  static Path de(Palo palo, Rect caja) {
    final unidad = switch (palo) {
      Palo.picas => _pica,
      Palo.corazones => _corazon,
      Palo.diamantes => _diamante,
      Palo.treboles => _trebol,
    };
    final matriz = Matrix4.identity()
      ..translateByDouble(caja.left, caja.top, 0, 1)
      ..scaleByDouble(caja.width, caja.height, 1, 1);
    return unidad.transform(matriz.storage);
  }

  static final _corazon = Path()
    ..moveTo(.5, .27)
    ..cubicTo(.5, .1, .38, 0, .25, 0)
    ..cubicTo(.09, 0, 0, .13, 0, .3)
    ..cubicTo(0, .54, .24, .72, .5, .99)
    ..cubicTo(.76, .72, 1, .54, 1, .3)
    ..cubicTo(1, .13, .91, 0, .75, 0)
    ..cubicTo(.62, 0, .5, .1, .5, .27)
    ..close();

  static final _diamante = Path()
    ..moveTo(.5, 0)
    ..quadraticBezierTo(.68, .3, .93, .5)
    ..quadraticBezierTo(.68, .7, .5, 1)
    ..quadraticBezierTo(.32, .7, .07, .5)
    ..quadraticBezierTo(.32, .3, .5, 0)
    ..close();

  static final _pica = Path()
    ..moveTo(.5, 0)
    ..cubicTo(.6, .17, 1, .34, 1, .58)
    ..cubicTo(1, .75, .87, .84, .73, .84)
    ..cubicTo(.63, .84, .56, .79, .53, .73)
    ..quadraticBezierTo(.55, .93, .68, 1)
    ..lineTo(.32, 1)
    ..quadraticBezierTo(.45, .93, .47, .73)
    ..cubicTo(.44, .79, .37, .84, .27, .84)
    ..cubicTo(.13, .84, 0, .75, 0, .58)
    ..cubicTo(0, .34, .4, .17, .5, 0)
    ..close();

  static final _trebol = Path()
    ..addOval(Rect.fromCircle(center: const Offset(.5, .26), radius: .235))
    ..addOval(Rect.fromCircle(center: const Offset(.255, .58), radius: .235))
    ..addOval(Rect.fromCircle(center: const Offset(.745, .58), radius: .235))
    ..addOval(Rect.fromCircle(center: const Offset(.5, .52), radius: .14))
    ..moveTo(.465, .58)
    ..quadraticBezierTo(.45, .9, .32, 1)
    ..lineTo(.68, 1)
    ..quadraticBezierTo(.55, .9, .535, .58)
    ..close();
}

/// Dibuja un palo centrado en [centro], de [ancho] de lado. Con [invertido],
/// cabeza abajo, como los pips de la mitad de abajo de una carta real.
void _pintarPalo(
  Canvas canvas,
  Palo palo,
  Offset centro,
  double ancho,
  Paint pintura, {
  bool invertido = false,
}) {
  final caja = Rect.fromCenter(
    center: centro,
    width: ancho,
    height: ancho * 1.08,
  );
  if (!invertido) {
    canvas.drawPath(FormasPalo.de(palo, caja), pintura);
    return;
  }
  canvas
    ..save()
    ..translate(centro.dx, centro.dy)
    ..rotate(math.pi)
    ..translate(-centro.dx, -centro.dy)
    ..drawPath(FormasPalo.de(palo, caja), pintura)
    ..restore();
}

TextPainter _texto(
  String texto,
  double tamano,
  Color color, {
  double espaciado = 0,
}) => TextPainter(
  text: TextSpan(
    text: texto,
    style: TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w900,
      fontSize: tamano,
      height: 1,
      letterSpacing: espaciado,
      color: color,
    ),
  ),
  textDirection: TextDirection.ltr,
)..layout();

void _sombraCarta(Canvas canvas, RRect forma, double ancho) => canvas.drawRRect(
  forma.shift(Offset(0, ancho * .03)),
  Paint()
    ..color = const Color(0x59000000)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, ancho * .035),
);

/// Donde van los pips de cada numero, como en una baraja de verdad: en
/// fracciones del ancho (x) y del alto (y) de la carta.
const _izq = .335;
const _der = .665;
const _centro = .5;
const _pips = <int, List<(double, double)>>{
  2: [(_centro, .21), (_centro, .79)],
  3: [(_centro, .21), (_centro, .5), (_centro, .79)],
  4: [(_izq, .21), (_der, .21), (_izq, .79), (_der, .79)],
  5: [(_izq, .21), (_der, .21), (_centro, .5), (_izq, .79), (_der, .79)],
  6: [
    (_izq, .21),
    (_der, .21),
    (_izq, .5),
    (_der, .5),
    (_izq, .79),
    (_der, .79),
  ],
  7: [
    (_izq, .21), (_der, .21), (_centro, .355), (_izq, .5), (_der, .5), //
    (_izq, .79), (_der, .79),
  ],
  8: [
    (_izq, .21), (_der, .21), (_centro, .355), (_izq, .5), (_der, .5), //
    (_centro, .645), (_izq, .79), (_der, .79),
  ],
  9: [
    (_izq, .21), (_der, .21), (_izq, .403), (_der, .403), (_centro, .5), //
    (_izq, .597), (_der, .597), (_izq, .79), (_der, .79),
  ],
  10: [
    (_izq, .21), (_der, .21), (_centro, .307), (_izq, .403), (_der, .403), //
    (_izq, .597), (_der, .597), (_centro, .693), (_izq, .79), (_der, .79),
  ],
};

/// La cara de una carta.
class PintorCaraCarta extends CustomPainter {
  const PintorCaraCarta(this.carta);

  final Carta carta;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final forma = RRect.fromRectAndRadius(rect, Radius.circular(w * .09));
    _sombraCarta(canvas, forma, w);
    canvas
      ..drawRRect(
        forma,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColoresCarta.papel, ColoresCarta.papelSombra],
          ).createShader(rect),
      )
      ..drawRRect(
        forma.deflate(.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = ColoresCarta.borde,
      );

    final color = carta.esRoja ? ColoresCarta.rojo : ColoresCarta.negro;
    final tinta = Paint()..color = color;
    _indice(canvas, w, h, color, tinta);
    canvas
      ..save()
      ..translate(w, h)
      ..rotate(math.pi);
    _indice(canvas, w, h, color, tinta);
    canvas.restore();

    if (carta.esAs) {
      _as(canvas, w, h, tinta);
    } else if (carta.rango > 10) {
      _figura(canvas, w, h, color, tinta);
    } else {
      final tamano = switch (carta.rango) {
        <= 3 => w * .22,
        <= 8 => w * .2,
        _ => w * .175,
      };
      for (final (x, y) in _pips[carta.rango]!) {
        _pintarPalo(
          canvas,
          carta.palo,
          Offset(w * x, h * y),
          tamano,
          tinta,
          invertido: y > .5,
        );
      }
    }
  }

  /// El numero y el palo de la esquina.
  void _indice(Canvas canvas, double w, double h, Color color, Paint tinta) {
    final diez = carta.rango == 10;
    final numero = _texto(
      carta.nombre,
      w * (diez ? .2 : .235),
      color,
      espaciado: diez ? -w * .025 : 0,
    );
    final columna = w * .145;
    numero.paint(canvas, Offset(columna - numero.width / 2, h * .035));
    _pintarPalo(
      canvas,
      carta.palo,
      Offset(columna, h * .035 + numero.height + w * .075),
      w * .135,
      tinta,
    );
  }

  void _as(Canvas canvas, double w, double h, Paint tinta) {
    final centro = Offset(w / 2, h / 2);
    if (carta.palo == Palo.picas) {
      // El As de picas, como en toda baraja que se respete, va de gala.
      canvas
        ..drawCircle(
          centro,
          w * .335,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .016
            ..color = ColoresCarta.oro,
        )
        ..drawCircle(
          centro,
          w * .3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .006
            ..color = ColoresCarta.oro.withValues(alpha: .6),
        );
      _pintarPalo(canvas, carta.palo, centro, w * .44, tinta);
      return;
    }
    _pintarPalo(canvas, carta.palo, centro, w * .42, tinta);
  }

  /// J, Q y K: un marco dorado, su emblema y la letra.
  void _figura(Canvas canvas, double w, double h, Color color, Paint tinta) {
    final marco = Rect.fromLTRB(w * .23, h * .135, w * .77, h * .865);
    final rr = RRect.fromRectAndRadius(marco, Radius.circular(w * .05));
    canvas
      ..drawRRect(rr, Paint()..color = color.withValues(alpha: .07))
      ..drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .02
          ..color = ColoresCarta.oro,
      )
      ..drawRRect(
        rr.deflate(w * .035),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .008
          ..color = color.withValues(alpha: .5),
      );

    final caja = Rect.fromCenter(
      center: Offset(w * .5, h * .4),
      width: w * .36,
      height: w * .27,
    );
    final emblema = switch (carta.rango) {
      13 => _corona(caja),
      12 => _tiara(caja),
      _ => _gorro(caja),
    };
    canvas
      ..drawPath(
        emblema,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColoresCarta.oroClaro, ColoresCarta.oro],
          ).createShader(caja),
      )
      ..drawPath(
        emblema,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .014
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    // Las joyas, en el color del palo.
    for (final joya in _joyas(carta.rango, caja)) {
      canvas.drawCircle(joya, w * .026, tinta);
    }

    final letra = _texto(carta.nombre, w * .34, color);
    letra.paint(
      canvas,
      Offset(w * .5 - letra.width / 2, h * .66 - letra.height / 2),
    );
    _pintarPalo(canvas, carta.palo, Offset(w * .325, h * .215), w * .1, tinta);
    _pintarPalo(
      canvas,
      carta.palo,
      Offset(w * .675, h * .785),
      w * .1,
      tinta,
      invertido: true,
    );
  }

  static Path _en(Rect caja, List<(double, double)> puntos) {
    final camino = Path()
      ..moveTo(
        caja.left + caja.width * puntos.first.$1,
        caja.top + caja.height * puntos.first.$2,
      );
    for (final (x, y) in puntos.skip(1)) {
      camino.lineTo(caja.left + caja.width * x, caja.top + caja.height * y);
    }
    return camino..close();
  }

  /// La corona del rey: tres puntas y una banda.
  static Path _corona(Rect caja) => _en(caja, const [
    (0, 1),
    (0, .3),
    (.25, .62),
    (.5, .04),
    (.75, .62),
    (1, .3),
    (1, 1),
  ]);

  /// La tiara de la reina: arcos suaves.
  static Path _tiara(Rect caja) {
    Offset p(double x, double y) =>
        Offset(caja.left + caja.width * x, caja.top + caja.height * y);
    return Path()
      ..moveTo(p(0, 1).dx, p(0, 1).dy)
      ..lineTo(p(0, .5).dx, p(0, .5).dy)
      ..quadraticBezierTo(
        p(.18, .16).dx,
        p(.18, .16).dy,
        p(.32, .52).dx,
        p(.32, .52).dy,
      )
      ..quadraticBezierTo(
        p(.5, -.06).dx,
        p(.5, -.06).dy,
        p(.68, .52).dx,
        p(.68, .52).dy,
      )
      ..quadraticBezierTo(
        p(.82, .16).dx,
        p(.82, .16).dy,
        p(1, .5).dx,
        p(1, .5).dy,
      )
      ..lineTo(p(1, 1).dx, p(1, 1).dy)
      ..close();
  }

  /// El gorro con pluma de la sota.
  static Path _gorro(Rect caja) {
    Offset p(double x, double y) =>
        Offset(caja.left + caja.width * x, caja.top + caja.height * y);
    return Path()
      ..moveTo(p(.04, 1).dx, p(.04, 1).dy)
      ..quadraticBezierTo(
        p(.08, .42).dx,
        p(.08, .42).dy,
        p(.5, .4).dx,
        p(.5, .4).dy,
      )
      ..quadraticBezierTo(
        p(.92, .42).dx,
        p(.92, .42).dy,
        p(.96, 1).dx,
        p(.96, 1).dy,
      )
      ..close()
      // La pluma.
      ..moveTo(p(.56, .44).dx, p(.56, .44).dy)
      ..quadraticBezierTo(
        p(.66, .02).dx,
        p(.66, .02).dy,
        p(1.02, -.04).dx,
        p(1.02, -.04).dy,
      )
      ..quadraticBezierTo(
        p(.84, .22).dx,
        p(.84, .22).dy,
        p(.66, .48).dx,
        p(.66, .48).dy,
      )
      ..close();
  }

  static List<Offset> _joyas(int rango, Rect caja) {
    Offset p(double x, double y) =>
        Offset(caja.left + caja.width * x, caja.top + caja.height * y);
    return switch (rango) {
      13 => [p(0, .3), p(.5, .04), p(1, .3), p(.5, .82)],
      12 => [p(.5, .22), p(.25, .8), p(.75, .8)],
      _ => [p(.5, .74)],
    };
  }

  @override
  bool shouldRepaint(PintorCaraCarta viejo) =>
      viejo.carta.rango != carta.rango || viejo.carta.palo != carta.palo;
}

/// El dorso: azul noche con un enrejado dorado y la "M" de MacIAs.
class PintorDorsoCarta extends CustomPainter {
  const PintorDorsoCarta({this.sombra = true});

  final bool sombra;

  @override
  void paint(Canvas canvas, Size size) => pintar(canvas, size, sombra: sombra);

  static void pintar(Canvas canvas, Size size, {bool sombra = true}) {
    final w = size.width;
    final rect = Offset.zero & size;
    final forma = RRect.fromRectAndRadius(rect, Radius.circular(w * .09));
    if (sombra) _sombraCarta(canvas, forma, w);
    canvas.drawRRect(forma, Paint()..color = ColoresCarta.papel);
    final dentro = RRect.fromRectAndRadius(
      rect.deflate(w * .06),
      Radius.circular(w * .06),
    );
    canvas
      ..drawRRect(
        dentro,
        Paint()
          ..shader = const RadialGradient(
            radius: .9,
            colors: [ColoresCarta.dorso, ColoresCarta.dorsoOscuro],
          ).createShader(dentro.outerRect),
      )
      ..save()
      ..clipRRect(dentro);
    final reja = Paint()
      ..strokeWidth = w * .012
      ..color = ColoresCarta.oro.withValues(alpha: .3);
    final paso = w * .13;
    final alto = size.height;
    for (var d = -alto; d < w + alto; d += paso) {
      canvas
        ..drawLine(Offset(d, 0), Offset(d + alto, alto), reja)
        ..drawLine(Offset(d + alto, 0), Offset(d, alto), reja);
    }
    canvas
      ..restore()
      ..drawRRect(
        dentro.deflate(w * .03),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .012
          ..color = ColoresCarta.oro.withValues(alpha: .85),
      );
    final centro = rect.center;
    canvas
      ..drawCircle(centro, w * .2, Paint()..color = ColoresCarta.dorsoOscuro)
      ..drawCircle(
        centro,
        w * .2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .022
          ..color = ColoresCarta.oro,
      );
    final m = _texto('M', w * .23, ColoresCarta.oroClaro);
    m.paint(canvas, centro - Offset(m.width / 2, m.height / 2));
  }

  @override
  bool shouldRepaint(PintorDorsoCarta viejo) => viejo.sombra != sombra;
}

/// Una carta quieta: la cara o el dorso.
class CartaDibujada extends StatelessWidget {
  const CartaDibujada({
    required this.ancho,
    this.carta,
    this.bocaArriba = true,
    super.key,
  });

  final double ancho;

  /// Sin carta, se ve el dorso.
  final Carta? carta;
  final bool bocaArriba;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size(ancho, ancho * 1.4),
      painter: bocaArriba && carta != null
          ? PintorCaraCarta(carta!)
          : const PintorDorsoCarta(),
    ),
  );
}

/// Una carta que vuela por la mesa: sale del sabot, se acomoda en la mano,
/// se da vuelta, se va al descarte.
///
/// Se pinta una sola vez (cara y dorso, cada uno en su capa) y despues solo
/// se mueve: correrla, girarla, achicarla o voltearla no la vuelve a dibujar,
/// asi que la animacion va al ritmo de la pantalla, sea de 60 o de 120 Hz.
class CartaEnVuelo extends StatefulWidget {
  const CartaEnVuelo({
    required this.carta,
    required this.centro,
    required this.ancho,
    required this.origen,
    this.escala = 1,
    this.giro = 0,
    this.bocaArriba = true,
    this.desvanecer = false,
    this.duracion = const Duration(milliseconds: 380),
    this.alSalir,
    this.alAterrizar,
    this.alVoltear,
    super.key,
  });

  /// Cuando sale del sabot (para el sonido del deslizamiento).
  final VoidCallback? alSalir;

  /// Cuando toca el paño: al 62 % del viaje, que es cuando la curva de
  /// frenado la deja practicamente quieta.
  final VoidCallback? alAterrizar;

  /// Cuando se da vuelta boca arriba ya en la mesa (la carta tapada del
  /// crupier).
  final VoidCallback? alVoltear;

  final Carta carta;

  /// Donde termina el centro de la carta.
  final Offset centro;

  /// El ancho al que se pinta. [escala] la achica sin volver a pintarla.
  final double ancho;

  /// De donde sale la primera vez (el sabot).
  final Offset origen;
  final double escala;

  /// Cuanto gira, en radianes.
  final double giro;
  final bool bocaArriba;

  /// Se apaga mientras viaja: para irse al descarte.
  final bool desvanecer;
  final Duration duracion;

  @override
  State<CartaEnVuelo> createState() => _CartaEnVueloState();
}

class _CartaEnVueloState extends State<CartaEnVuelo>
    with TickerProviderStateMixin {
  late final AnimationController _viaje = AnimationController(
    vsync: this,
    duration: widget.duracion,
  );
  late final AnimationController _volteo = AnimationController(
    vsync: this,
    duration: widget.duracion * .8,
  );

  late Offset _desde = widget.origen;
  late Offset _hasta = widget.centro;
  late double _giroDesde = -.55;
  late double _giroHasta = widget.giro;
  late double _escalaDesde = widget.escala * .72;
  late double _escalaHasta = widget.escala;
  double _opacidadDesde = 1;
  bool _enArco = true;
  late bool _volteoPendiente = widget.bocaArriba;

  late final Widget _cara = CartaDibujada(
    ancho: widget.ancho,
    carta: widget.carta,
  );
  late final Widget _dorso = CartaDibujada(ancho: widget.ancho);

  @override
  void initState() {
    super.initState();
    _viaje
      ..addListener(_alViajar)
      ..forward();
    widget.alSalir?.call();
    final aterrizar = widget.alAterrizar;
    if (aterrizar != null) {
      Future<void>.delayed(widget.duracion * .62, () {
        if (mounted) aterrizar();
      });
    }
  }

  void _alViajar() {
    // La carta que sale boca arriba se da vuelta en el aire.
    if (_volteoPendiente && _viaje.value >= .34) {
      _volteoPendiente = false;
      _volteo.forward();
    }
  }

  @override
  void didUpdateWidget(CartaEnVuelo viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.duracion != widget.duracion) {
      _viaje.duration = widget.duracion;
      _volteo.duration = widget.duracion * .8;
    }
    final seMueve =
        viejo.centro != widget.centro ||
        viejo.giro != widget.giro ||
        viejo.escala != widget.escala ||
        viejo.desvanecer != widget.desvanecer;
    if (seMueve) {
      final t = _curva(_viaje.value);
      _desde = _posicion(t);
      _giroDesde = _lerp(_giroDesde, _giroHasta, t);
      _escalaDesde = _lerp(_escalaDesde, _escalaHasta, t);
      _opacidadDesde = _opacidad(t);
      _hasta = widget.centro;
      _giroHasta = widget.giro;
      _escalaHasta = widget.escala;
      // Al descarte vuela en arco; reacomodarse en la mano, derecho.
      _enArco = widget.desvanecer;
      _viaje.forward(from: 0);
    }
    if (viejo.bocaArriba != widget.bocaArriba) {
      _volteoPendiente = false;
      if (widget.bocaArriba) {
        widget.alVoltear?.call();
        _volteo.forward();
      } else {
        _volteo.reverse();
      }
    }
  }

  @override
  void dispose() {
    _viaje.dispose();
    _volteo.dispose();
    super.dispose();
  }

  static double _curva(double t) => Curves.easeOutCubic.transform(t);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  Offset _posicion(double t) {
    if (!_enArco) return Offset.lerp(_desde, _hasta, t)!;
    // Una curva suave hacia arriba, como una carta que se lanza.
    final distancia = (_hasta - _desde).distance;
    final control =
        Offset.lerp(_desde, _hasta, .5)! +
        Offset(0, -math.min(70.0, distancia * .22));
    final u = 1 - t;
    return _desde * (u * u) + control * (2 * u * t) + _hasta * (t * t);
  }

  double _opacidad(double t) {
    if (!widget.desvanecer) return _opacidadDesde;
    final apagado = Curves.easeIn.transform(((t - .35) / .65).clamp(0.0, 1.0));
    return _opacidadDesde * (1 - apagado);
  }

  @override
  Widget build(BuildContext context) {
    final ancho = widget.ancho;
    final alto = ancho * 1.4;
    return Positioned(
      left: 0,
      top: 0,
      width: ancho,
      height: alto,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_viaje, _volteo]),
          builder: (context, _) {
            final t = _curva(_viaje.value);
            final p = _posicion(t);
            final giro = _lerp(_giroDesde, _giroHasta, t);
            final escala = _lerp(_escalaDesde, _escalaHasta, t);
            final volteo = Curves.easeInOutCubic.transform(_volteo.value);
            final angulo = (1 - volteo) * math.pi;
            final caraVisible = angulo <= math.pi / 2;
            final opacidad = _opacidad(t);
            Widget carta = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0013)
                ..rotateY(angulo),
              child: caraVisible
                  ? _cara
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: _dorso,
                    ),
            );
            if (opacidad < 1) {
              carta = Opacity(opacity: opacidad.clamp(0.0, 1.0), child: carta);
            }
            return Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.translationValues(
                      p.dx - ancho / 2,
                      p.dy - alto / 2,
                      0,
                    )
                    ..rotateZ(giro)
                    ..scaleByDouble(escala, escala, 1, 1),
              child: carta,
            );
          },
        ),
      ),
    );
  }
}

/// El sabot: la caja de donde salen las cartas, con la de arriba asomando.
class PintorSabot extends CustomPainter {
  const PintorSabot();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cuerpo = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, h * .12, w, h * .88),
      topLeft: Radius.circular(w * .1),
      topRight: Radius.circular(w * .18),
      bottomLeft: Radius.circular(w * .1),
      bottomRight: Radius.circular(w * .1),
    );
    canvas.drawRRect(
      cuerpo.shift(Offset(0, w * .04)),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .05),
    );
    // La carta de arriba, saliendo por la ranura.
    canvas
      ..save()
      ..translate(w * .1, h * .02)
      ..rotate(-.18);
    PintorDorsoCarta.pintar(
      canvas,
      Size(w * .78, w * .78 * 1.4),
      sombra: false,
    );
    canvas
      ..restore()
      ..drawRRect(
        cuerpo,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B3533), Color(0xFF151313)],
          ).createShader(cuerpo.outerRect),
      )
      ..drawRRect(
        cuerpo.deflate(w * .05),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .025
          ..color = ColoresCarta.oro.withValues(alpha: .7),
      );
    // La ranura.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .12, h * .2, w * .76, h * .07),
        Radius.circular(h * .035),
      ),
      Paint()..color = const Color(0xFF0A0909),
    );
  }

  @override
  bool shouldRepaint(PintorSabot viejo) => false;
}
