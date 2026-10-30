import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logica/mesa_pesca.dart';

/// Los colores de la pesca: hielo, agua y el oro de los multiplicadores.
abstract final class ColoresPesca {
  static const hieloClaro = Color(0xFFF3F8FB);
  static const hieloSombra = Color(0xFFD5E3EC);
  static const hieloAzul = Color(0xFF7FA6BC);
  static const hieloAzulOscuro = Color(0xFF5B8399);
  static const marco = Color(0xFF1F3B4D);
  static const marcoOscuro = Color(0xFF10222E);
  static const metal = Color(0xFFB9C4CC);
  static const metalOscuro = Color(0xFF6D7A84);
  static const oro = Color(0xFFF5C542);
  static const oroOscuro = Color(0xFFB8860B);
  static const oroClaro = Color(0xFFFFE9A6);
  static const texto = Color(0xFF14303F);
  static const fondoArriba = Color(0xFFDCEBF3);
  static const fondoAbajo = Color(0xFF8FB4C9);

  /// El color de cada casilla: el del pez, o el del hielo.
  static (Color claro, Color oscuro) deCasilla(Casilla casilla) =>
      switch (casilla) {
        Casilla.hieloBlanco => (hieloClaro, hieloSombra),
        Casilla.hieloAzul => (hieloAzul, hieloAzulOscuro),
        Casilla.azulitos => (const Color(0xFF2F86E8), const Color(0xFF15489A)),
        Casilla.naranjotes => (
          const Color(0xFFF59A2B),
          const Color(0xFFB9560A),
        ),
        Casilla.rojazos => (const Color(0xFFE23A4B), const Color(0xFF8F1222)),
      };

  /// Lomo, flanco y panza de cada pez.
  static (Color lomo, Color flanco, Color panza) dePez(Pez pez) =>
      switch (pez) {
        Pez.azulitos => (
          const Color(0xFF16408A),
          const Color(0xFF2F8BEA),
          const Color(0xFFB5DCFF),
        ),
        Pez.naranjotes => (
          const Color(0xFFA9480A),
          const Color(0xFFF2952A),
          const Color(0xFFFFE2AE),
        ),
        Pez.rojazos => (
          const Color(0xFF7D0C1B),
          const Color(0xFFDD3243),
          const Color(0xFFFFB9BE),
        ),
      };
}

/// Un pez de perfil, mirando a la derecha, en el rectangulo [caja].
///
/// Cuerpo con el lomo oscuro y la panza clara, escamas, aletas, la
/// agalla y el ojo con su brillo. [boca] lo abre un poco (cuando sale del
/// agua).
void pintarPez(
  Canvas canvas,
  Rect caja,
  Pez pez, {
  double opacidad = 1,
  bool boca = false,
}) {
  final (lomo, flanco, panza) = ColoresPesca.dePez(pez);
  final w = caja.width;
  final h = caja.height;
  Offset p(double x, double y) => caja.topLeft + Offset(w * x, h * y);
  Color a(Color c) => c.withValues(alpha: c.a * opacidad);

  // La cola, de horquilla.
  final cola = Path()
    ..moveTo(p(.27, .5).dx, p(.27, .5).dy)
    ..quadraticBezierTo(
      p(.13, .3).dx,
      p(.13, .3).dy,
      p(0, .06).dx,
      p(0, .06).dy,
    )
    ..quadraticBezierTo(
      p(.09, .3).dx,
      p(.09, .3).dy,
      p(.1, .5).dx,
      p(.1, .5).dy,
    )
    ..quadraticBezierTo(
      p(.09, .7).dx,
      p(.09, .7).dy,
      p(0, .94).dx,
      p(0, .94).dy,
    )
    ..quadraticBezierTo(
      p(.13, .7).dx,
      p(.13, .7).dy,
      p(.27, .5).dx,
      p(.27, .5).dy,
    )
    ..close();
  canvas.drawPath(
    cola,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [a(lomo), a(flanco)],
      ).createShader(caja),
  );

  // La aleta de arriba y la de abajo.
  final dorsal = Path()
    ..moveTo(p(.62, .2).dx, p(.62, .2).dy)
    ..quadraticBezierTo(
      p(.5, -.04).dx,
      p(.5, -.04).dy,
      p(.34, .04).dx,
      p(.34, .04).dy,
    )
    ..quadraticBezierTo(
      p(.4, .2).dx,
      p(.4, .2).dy,
      p(.36, .3).dx,
      p(.36, .3).dy,
    )
    ..close();
  final ventral = Path()
    ..moveTo(p(.56, .82).dx, p(.56, .82).dy)
    ..quadraticBezierTo(
      p(.48, 1.02).dx,
      p(.48, 1.02).dy,
      p(.38, .98).dx,
      p(.38, .98).dy,
    )
    ..quadraticBezierTo(
      p(.42, .86).dx,
      p(.42, .86).dy,
      p(.4, .76).dx,
      p(.4, .76).dy,
    )
    ..close();
  final aleta = Paint()..color = a(lomo.withValues(alpha: .92));
  canvas
    ..drawPath(dorsal, aleta)
    ..drawPath(ventral, aleta);

  // El cuerpo.
  final cuerpo = Path()
    ..moveTo(p(.99, .52).dx, p(.99, .52).dy)
    ..cubicTo(
      p(.92, .1).dx,
      p(.92, .1).dy,
      p(.5, .08).dx,
      p(.5, .08).dy,
      p(.24, .38).dx,
      p(.24, .38).dy,
    )
    ..quadraticBezierTo(
      p(.2, .5).dx,
      p(.2, .5).dy,
      p(.24, .62).dx,
      p(.24, .62).dy,
    )
    ..cubicTo(
      p(.5, .95).dx,
      p(.5, .95).dy,
      p(.9, .92).dx,
      p(.9, .92).dy,
      p(.99, .52).dx,
      p(.99, .52).dy,
    )
    ..close();
  canvas
    ..save()
    ..clipPath(cuerpo)
    ..drawRect(
      caja,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a(lomo), a(flanco), a(flanco), a(panza)],
          stops: const [.05, .4, .6, .95],
        ).createShader(caja),
    );

  // Las escamas: arcos claros en filas.
  final escama = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(.6, h * .018)
    ..color = Colors.white.withValues(alpha: .22 * opacidad);
  final paso = h * .13;
  for (var fila = 0; fila < 8; fila++) {
    final y = caja.top + h * .18 + fila * paso * .9;
    for (var col = 0; col < 9; col++) {
      final x =
          caja.left + w * .3 + col * paso * 1.05 + (fila.isOdd ? paso * .5 : 0);
      if (x > caja.left + w * .78) break;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: paso * .55),
        -math.pi / 2,
        math.pi,
        false,
        escama,
      );
    }
  }
  // El brillo del lomo.
  canvas
    ..drawOval(
      Rect.fromLTWH(caja.left + w * .4, caja.top + h * .2, w * .42, h * .14),
      Paint()
        ..color = Colors.white.withValues(alpha: .28 * opacidad)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .04),
    )
    ..restore();

  // El borde, la agalla y la aleta del costado.
  final borde = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(.8, h * .028)
    ..color = a(lomo.withValues(alpha: .9));
  canvas
    ..drawPath(cuerpo, borde)
    ..drawArc(
      Rect.fromCenter(center: p(.72, .52), width: w * .12, height: h * .52),
      -math.pi / 2.4,
      math.pi / 1.2,
      false,
      borde,
    );
  final costado = Path()
    ..moveTo(p(.66, .56).dx, p(.66, .56).dy)
    ..quadraticBezierTo(
      p(.56, .6).dx,
      p(.56, .6).dy,
      p(.52, .74).dx,
      p(.52, .74).dy,
    )
    ..quadraticBezierTo(
      p(.62, .7).dx,
      p(.62, .7).dy,
      p(.66, .56).dx,
      p(.66, .56).dy,
    )
    ..close();
  canvas.drawPath(costado, Paint()..color = a(lomo.withValues(alpha: .55)));

  // El ojo.
  final ojo = p(.84, .4);
  final radioOjo = h * .085;
  canvas
    ..drawCircle(ojo, radioOjo, Paint()..color = a(Colors.white))
    ..drawCircle(
      ojo + Offset(radioOjo * .18, 0),
      radioOjo * .6,
      Paint()..color = a(const Color(0xFF0E1A22)),
    )
    ..drawCircle(
      ojo + Offset(radioOjo * .38, -radioOjo * .3),
      radioOjo * .22,
      Paint()..color = a(Colors.white),
    );

  // La boca.
  final labio = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(.8, h * .025)
    ..color = a(lomo);
  if (boca) {
    canvas.drawOval(
      Rect.fromCenter(center: p(.955, .58), width: w * .06, height: h * .1),
      Paint()..color = a(const Color(0xFF3A0A10)),
    );
  } else {
    canvas.drawLine(p(.99, .54), p(.92, .58), labio);
  }
}

/// Un pez quieto.
class PezDibujado extends StatelessWidget {
  const PezDibujado({
    required this.pez,
    required this.ancho,
    this.mirandoIzquierda = false,
    this.boca = false,
    super.key,
  });

  final Pez pez;
  final double ancho;
  final bool mirandoIzquierda;
  final bool boca;

  @override
  Widget build(BuildContext context) {
    Widget pez = RepaintBoundary(
      child: CustomPaint(
        size: Size(ancho, ancho * .56),
        painter: _PintorPez(this.pez, boca),
      ),
    );
    if (mirandoIzquierda) {
      pez = Transform.flip(flipX: true, child: pez);
    }
    return pez;
  }
}

class _PintorPez extends CustomPainter {
  const _PintorPez(this.pez, this.boca);

  final Pez pez;
  final bool boca;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarPez(canvas, Offset.zero & size, pez, boca: boca);

  @override
  bool shouldRepaint(_PintorPez viejo) =>
      viejo.pez != pez || viejo.boca != boca;
}

/// Un copo de nieve de seis brazos, centrado en [centro].
void pintarCopo(Canvas canvas, Offset centro, double radio, Color color) {
  final trazo = Paint()
    ..color = color
    ..strokeWidth = math.max(1, radio * .2)
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 6; i++) {
    final angulo = i * math.pi / 3 - math.pi / 2;
    final d = Offset(math.cos(angulo), math.sin(angulo));
    final punta = centro + d * radio;
    canvas.drawLine(centro, punta, trazo);
    // Las ramitas de cada brazo.
    final medio = centro + d * radio * .58;
    for (final lado in [-1, 1]) {
      final rama = angulo + lado * math.pi / 4;
      canvas.drawLine(
        medio,
        medio + Offset(math.cos(rama), math.sin(rama)) * radio * .34,
        trazo,
      );
    }
  }
}

/// La etiqueta dorada de un multiplicador ("x5"), centrada en [centro] y
/// girada [angulo]. Con [copo], lleva un copito al lado (las bolas de
/// nieve del hielo).
void pintarMultiplicador(
  Canvas canvas,
  Offset centro,
  String texto,
  double alto, {
  double angulo = 0,
  bool copo = false,
  double opacidad = 1,
}) {
  final letra = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w900,
        fontSize: alto * .78,
        height: 1,
        color: ColoresPesca.texto.withValues(alpha: opacidad),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final extra = copo ? alto * .9 : 0.0;
  final ancho = letra.width + alto * .7 + extra;
  canvas
    ..save()
    ..translate(centro.dx, centro.dy)
    ..rotate(angulo);
  final pildora = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: ancho, height: alto),
    Radius.circular(alto / 2),
  );
  canvas
    ..drawRRect(
      pildora.shift(Offset(0, alto * .08)),
      Paint()..color = Colors.black.withValues(alpha: .28 * opacidad),
    )
    ..drawRRect(
      pildora,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColoresPesca.oroClaro.withValues(alpha: opacidad),
            ColoresPesca.oro.withValues(alpha: opacidad),
            ColoresPesca.oroOscuro.withValues(alpha: opacidad),
          ],
        ).createShader(pildora.outerRect),
    )
    ..drawRRect(
      pildora,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, alto * .06)
        ..color = Colors.white.withValues(alpha: .6 * opacidad),
    );
  final inicio = -ancho / 2 + alto * .35;
  if (copo) {
    pintarCopo(
      canvas,
      Offset(inicio + alto * .38, 0),
      alto * .32,
      Colors.white.withValues(alpha: opacidad),
    );
  }
  letra.paint(canvas, Offset(inicio + extra, -letra.height / 2));
  canvas.restore();
}

/// Un cubo de hielo, transparente, con sus brillos y una grieta: lo que
/// congela la casilla de hielo que salio.
void pintarCuboDeHielo(Canvas canvas, Rect caja, {double opacidad = 1}) {
  final r = RRect.fromRectAndRadius(
    caja,
    Radius.circular(caja.shortestSide * .18),
  );
  canvas
    ..drawRRect(
      r.inflate(caja.shortestSide * .06),
      Paint()
        ..color = Colors.white.withValues(alpha: .35 * opacidad)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          caja.shortestSide * .12,
        ),
    )
    ..drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xF2FFFFFF).withValues(alpha: .9 * opacidad),
            const Color(0xB3D8ECF6).withValues(alpha: .75 * opacidad),
            const Color(0xCCAFD3E6).withValues(alpha: .8 * opacidad),
          ],
        ).createShader(caja),
    )
    ..drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, caja.shortestSide * .05)
        ..color = Colors.white.withValues(alpha: .95 * opacidad),
    );
  // Brillo de arriba y una grieta.
  final w = caja.width;
  final h = caja.height;
  canvas
    ..drawLine(
      caja.topLeft + Offset(w * .2, h * .18),
      caja.topLeft + Offset(w * .62, h * .18),
      Paint()
        ..strokeWidth = math.max(1, h * .06)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .9 * opacidad),
    )
    ..drawPath(
      Path()
        ..moveTo(caja.left + w * .7, caja.top + h * .35)
        ..lineTo(caja.left + w * .55, caja.top + h * .55)
        ..lineTo(caja.left + w * .66, caja.top + h * .62)
        ..lineTo(caja.left + w * .48, caja.top + h * .86),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, h * .025)
        ..color = const Color(0xFF7FA6BC).withValues(alpha: .7 * opacidad),
    );
}
