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
/// Cada especie con su dibujo: los azulitos con pintas claras en el lomo,
/// los naranjotes con franjas como un koi, los rojazos con motas doradas.
/// Cuerpo con luz de borde arriba y sombra en la panza, escamas, aletas
/// translucidas con sus rayos, la agalla y un ojo con iris y dos brillos.
/// [cola] mueve la cola (y un poco las aletas) en radianes: asi nada.
/// [parpadeo] cierra el ojo (0 abierto, 1 cerrado). [boca] la abre (cuando
/// sale del agua).
void pintarPez(
  Canvas canvas,
  Rect caja,
  Pez pez, {
  double opacidad = 1,
  bool boca = false,
  double cola = 0,
  double parpadeo = 0,
  bool conDetalle = true,
}) {
  final (lomo, flanco, panza) = ColoresPesca.dePez(pez);
  final w = caja.width;
  final h = caja.height;
  Offset p(double x, double y) => caja.topLeft + Offset(w * x, h * y);
  Color a(Color c, [double alfa = 1]) =>
      c.withValues(alpha: c.a * alfa * opacidad);
  final contorno = Color.lerp(lomo, Colors.black, .4)!;
  final grueso = math.max(.7, h * .03);
  final borde = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = grueso
    ..strokeJoin = StrokeJoin.round
    ..color = a(contorno);
  final rayo = Paint()
    ..strokeWidth = math.max(.5, h * .014)
    ..strokeCap = StrokeCap.round
    ..color = a(Colors.white, .3);
  // Las escamas y los rayos de las aletas no se ven en un pez chico (ni en
  // los de lejos): sin ellos se dibuja mucho mas rapido.
  final detalle = conDetalle && h >= 16;

  // La cola, de horquilla, que se mueve desde donde nace.
  final nace = p(.27, .5);
  canvas.save();
  if (cola != 0) {
    canvas
      ..translate(nace.dx, nace.dy)
      ..rotate(cola)
      ..translate(-nace.dx, -nace.dy);
  }
  final colaPath = Path()
    ..moveTo(nace.dx, nace.dy)
    ..quadraticBezierTo(
      p(.13, .3).dx,
      p(.13, .3).dy,
      p(0, .04).dx,
      p(0, .04).dy,
    )
    ..quadraticBezierTo(
      p(.1, .3).dx,
      p(.1, .3).dy,
      p(.11, .5).dx,
      p(.11, .5).dy,
    )
    ..quadraticBezierTo(p(.1, .7).dx, p(.1, .7).dy, p(0, .96).dx, p(0, .96).dy)
    ..quadraticBezierTo(p(.13, .7).dx, p(.13, .7).dy, nace.dx, nace.dy)
    ..close();
  canvas.drawPath(
    colaPath,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [a(lomo, .85), a(flanco, .95)],
      ).createShader(caja),
  );
  if (detalle) {
    for (final y in [.14, .32, .68, .86]) {
      canvas.drawLine(nace, p(.04, y), rayo);
    }
  }
  canvas
    ..drawPath(colaPath, borde)
    ..restore();

  // Las aletas de arriba y de abajo: translucidas, con sus rayos.
  final ondea = cola * .35;
  final dorsal = Path()
    ..moveTo(p(.64, .2).dx, p(.64, .2).dy)
    ..quadraticBezierTo(
      p(.52, -.06 - ondea).dx,
      p(.52, -.06 - ondea).dy,
      p(.33, .03).dx,
      p(.33, .03).dy,
    )
    ..quadraticBezierTo(
      p(.4, .2).dx,
      p(.4, .2).dy,
      p(.36, .3).dx,
      p(.36, .3).dy,
    )
    ..close();
  final ventral = Path()
    ..moveTo(p(.57, .82).dx, p(.57, .82).dy)
    ..quadraticBezierTo(
      p(.48, 1.04 + ondea).dx,
      p(.48, 1.04 + ondea).dy,
      p(.37, .99).dx,
      p(.37, .99).dy,
    )
    ..quadraticBezierTo(
      p(.42, .86).dx,
      p(.42, .86).dy,
      p(.4, .76).dx,
      p(.4, .76).dy,
    )
    ..close();
  final aleta = Paint()..color = a(lomo, .82);
  canvas
    ..drawPath(dorsal, aleta)
    ..drawPath(ventral, aleta);
  if (detalle) {
    for (final f in [.3, .55, .8]) {
      canvas
        ..drawLine(p(.5, .2), Offset.lerp(p(.36, .06), p(.6, .04), f)!, rayo)
        ..drawLine(p(.48, .8), Offset.lerp(p(.38, .96), p(.54, .94), f)!, rayo);
    }
  }
  canvas
    ..drawPath(dorsal, borde)
    ..drawPath(ventral, borde);

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
          stops: const [.06, .38, .58, .94],
        ).createShader(caja),
    );

  // El dibujo de cada especie.
  final marca = Paint();
  switch (pez) {
    case Pez.azulitos:
      marca.color = a(Colors.white, .42);
      for (final (x, y, r) in const [
        (.42, .22, .03),
        (.5, .17, .024),
        (.58, .2, .03),
        (.66, .16, .022),
        (.47, .3, .02),
        (.62, .28, .02),
        (.36, .3, .022),
        (.72, .24, .018),
      ]) {
        canvas.drawCircle(p(x, y), h * r * 1.6, marca);
      }
    case Pez.naranjotes:
      marca.color = a(Color.lerp(lomo, Colors.black, .2)!, .5);
      for (final x in [.38, .52, .66]) {
        canvas.drawPath(
          Path()
            ..moveTo(p(x, .05).dx, p(x, .05).dy)
            ..quadraticBezierTo(
              p(x + .05, .3).dx,
              p(x + .05, .3).dy,
              p(x - .01, .62).dx,
              p(x - .01, .62).dy,
            )
            ..lineTo(p(x - .06, .62).dx, p(x - .06, .62).dy)
            ..quadraticBezierTo(
              p(x, .3).dx,
              p(x, .3).dy,
              p(x - .05, .05).dx,
              p(x - .05, .05).dy,
            )
            ..close(),
          marca,
        );
      }
    case Pez.rojazos:
      marca.color = a(const Color(0xFFFFD86B), .7);
      for (final (x, y) in const [
        (.4, .28),
        (.46, .2),
        (.53, .3),
        (.6, .18),
        (.66, .3),
        (.72, .22),
        (.48, .4),
        (.58, .42),
        (.36, .4),
        (.78, .32),
      ]) {
        canvas.drawCircle(p(x, y), h * .028, marca);
      }
  }

  // Las escamas: arcos claros en filas (no en los peces chiquitos).
  if (detalle) {
    final escama = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, h * .016)
      ..color = Colors.white.withValues(alpha: .2 * opacidad);
    final paso = h * .13;
    for (var fila = 0; fila < 8; fila++) {
      final y = caja.top + h * .18 + fila * paso * .9;
      for (var col = 0; col < 9; col++) {
        final x =
            caja.left +
            w * .3 +
            col * paso * 1.05 +
            (fila.isOdd ? paso * .5 : 0);
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
  }
  // La sombra de la panza y la luz del lomo: le dan volumen.
  canvas
    ..drawRect(
      Rect.fromLTRB(caja.left, caja.top + h * .66, caja.right, caja.bottom),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: .2 * opacidad),
              ],
            ).createShader(
              Rect.fromLTRB(
                caja.left,
                caja.top + h * .66,
                caja.right,
                caja.bottom,
              ),
            ),
    )
    ..drawPath(
      cuerpo.shift(Offset(0, h * .05)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .07
        ..color = Colors.white.withValues(alpha: .16 * opacidad),
    )
    // La linea del costado, de la agalla a la cola.
    ..drawPath(
      Path()
        ..moveTo(p(.7, .47).dx, p(.7, .47).dy)
        ..quadraticBezierTo(
          p(.5, .42).dx,
          p(.5, .42).dy,
          p(.28, .5).dx,
          p(.28, .5).dy,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, h * .018)
        ..color = Colors.white.withValues(alpha: .28 * opacidad),
    )
    // El brillo del lomo.
    ..drawOval(
      Rect.fromLTWH(caja.left + w * .42, caja.top + h * .17, w * .36, h * .12),
      Paint()..color = Colors.white.withValues(alpha: .3 * opacidad),
    )
    ..restore();

  // El borde, la agalla y la aleta del costado (que se mueve al nadar).
  canvas
    ..drawPath(cuerpo, borde)
    ..drawArc(
      Rect.fromCenter(center: p(.72, .52), width: w * .12, height: h * .52),
      -math.pi / 2.4,
      math.pi / 1.2,
      false,
      borde,
    );
  final raiz = p(.66, .56);
  canvas
    ..save()
    ..translate(raiz.dx, raiz.dy)
    ..rotate(-cola * .8)
    ..translate(-raiz.dx, -raiz.dy);
  final costado = Path()
    ..moveTo(raiz.dx, raiz.dy)
    ..quadraticBezierTo(
      p(.55, .6).dx,
      p(.55, .6).dy,
      p(.5, .76).dx,
      p(.5, .76).dy,
    )
    ..quadraticBezierTo(p(.62, .72).dx, p(.62, .72).dy, raiz.dx, raiz.dy)
    ..close();
  canvas
    ..drawPath(costado, Paint()..color = a(lomo, .6))
    ..drawPath(costado, borde..strokeWidth = grueso * .7)
    ..restore();

  // El ojo: blanco, el iris del color del pez, la pupila y dos brillos.
  final ojo = p(.84, .4);
  final radioOjo = h * .095;
  canvas
    ..drawCircle(ojo, radioOjo * 1.12, Paint()..color = a(contorno, .5))
    ..drawCircle(ojo, radioOjo, Paint()..color = a(Colors.white))
    ..drawCircle(
      ojo + Offset(radioOjo * .16, radioOjo * .04),
      radioOjo * .66,
      Paint()..color = a(Color.lerp(lomo, Colors.black, .2)!),
    )
    ..drawCircle(
      ojo + Offset(radioOjo * .22, radioOjo * .06),
      radioOjo * .4,
      Paint()..color = a(const Color(0xFF0B141B)),
    )
    ..drawCircle(
      ojo + Offset(radioOjo * .36, -radioOjo * .3),
      radioOjo * .24,
      Paint()..color = a(Colors.white),
    )
    ..drawCircle(
      ojo + Offset(-radioOjo * .02, radioOjo * .36),
      radioOjo * .11,
      Paint()..color = a(Colors.white, .8),
    );
  if (parpadeo > 0) {
    // El parpado baja desde arriba.
    final caja = Rect.fromCircle(center: ojo, radius: radioOjo * 1.05);
    canvas
      ..save()
      ..clipRect(
        Rect.fromLTRB(
          caja.left,
          caja.top,
          caja.right,
          caja.top + caja.height * parpadeo.clamp(0, 1),
        ),
      )
      ..drawCircle(ojo, radioOjo * 1.05, Paint()..color = a(flanco))
      ..restore();
  }

  // La boca.
  if (boca) {
    canvas
      ..drawOval(
        Rect.fromCenter(center: p(.955, .58), width: w * .065, height: h * .11),
        Paint()..color = a(const Color(0xFF3A0A10)),
      )
      ..drawOval(
        Rect.fromCenter(center: p(.955, .58), width: w * .065, height: h * .11),
        borde..strokeWidth = grueso * .8,
      );
  } else {
    canvas.drawLine(
      p(.99, .54),
      p(.91, .59),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = grueso
        ..color = a(contorno),
    );
  }
}

/// Una moneda de oro chica que gira en el aire: se le ve el canto cuando
/// esta de costado, el borde en relieve y un brillo.
void pintarMonedita(
  Canvas canvas,
  Offset centro,
  double radio,
  double giro, {
  double opacidad = 1,
}) {
  Color a(Color c) => c.withValues(alpha: c.a * opacidad);
  final ancho = math.cos(giro).abs().clamp(.12, 1.0);
  final canto = radio * .22 * math.sin(giro).abs();
  final lado = math.sin(giro) >= 0 ? 1.0 : -1.0;
  final cara = Rect.fromCenter(
    center: centro,
    width: radio * 2 * ancho,
    height: radio * 2,
  );
  canvas
    ..drawOval(
      cara.shift(Offset(canto * lado, 0)),
      Paint()..color = a(const Color(0xFF8A6206)),
    )
    ..drawOval(
      cara,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: [
            a(ColoresPesca.oroClaro),
            a(ColoresPesca.oro),
            a(ColoresPesca.oroOscuro),
          ],
          stops: const [0, .55, 1],
        ).createShader(cara),
    )
    ..drawOval(
      cara.deflate(radio * .22),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * .12
        ..color = a(const Color(0xFFFFF1C2).withValues(alpha: .7)),
    );
  if (ancho > .5) {
    canvas.drawCircle(
      centro + Offset(-radio * .3 * ancho, -radio * .35),
      radio * .18,
      Paint()..color = a(Colors.white.withValues(alpha: .8)),
    );
  }
}

/// La lluvia de monedas de un premio grande: saltan desde [origen] (en
/// fracciones del lugar que ocupa), giran en el aire y caen. Se ve una vez
/// y avisa al terminar. Con el telefono sin animaciones, no se ve.
class LluviaDeMonedas extends StatefulWidget {
  const LluviaDeMonedas({
    this.origen = const Offset(.5, .45),
    this.cuantas = 34,
    this.alTerminar,
    super.key,
  });

  final Offset origen;
  final int cuantas;
  final VoidCallback? alTerminar;

  @override
  State<LluviaDeMonedas> createState() => _LluviaDeMonedasState();
}

class _LluviaDeMonedasState extends State<LluviaDeMonedas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vuelo =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..addStatusListener((estado) {
        if (estado == AnimationStatus.completed) widget.alTerminar?.call();
      });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _vuelo.value = 1;
    } else if (!_vuelo.isAnimating && _vuelo.value == 0) {
      _vuelo.forward();
    }
  }

  @override
  void dispose() {
    _vuelo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _PintorLluvia(_vuelo, widget.origen, widget.cuantas),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _PintorLluvia extends CustomPainter {
  _PintorLluvia(this.vuelo, this.origen, this.cuantas) : super(repaint: vuelo);

  final Animation<double> vuelo;
  final Offset origen;
  final int cuantas;

  @override
  void paint(Canvas canvas, Size size) {
    final segundos = vuelo.value * 2.6;
    if (segundos <= 0 || segundos >= 2.6) return;
    final azar = math.Random(17);
    final desde = Offset(size.width * origen.dx, size.height * origen.dy);
    final gravedad = size.height * 2.1;
    for (var i = 0; i < cuantas; i++) {
      final angulo = -math.pi / 2 + (azar.nextDouble() - .5) * 2.2;
      final velocidad = size.height * (.7 + azar.nextDouble() * .7);
      final espera = azar.nextDouble() * .3;
      final gira = (azar.nextDouble() * 10 + 6) * (azar.nextBool() ? 1 : -1);
      final radio = 7 + azar.nextDouble() * 8;
      final t = segundos - espera;
      if (t <= 0) continue;
      final p =
          desde +
          Offset(
            math.cos(angulo) * velocidad * t * .55,
            math.sin(angulo) * velocidad * t + gravedad * t * t / 2,
          );
      if (p.dy > size.height + 20) continue;
      final opacidad = (2.6 - segundos).clamp(0.0, .5) * 2;
      pintarMonedita(canvas, p, radio, gira * t, opacidad: opacidad);
    }
  }

  @override
  bool shouldRepaint(_PintorLluvia viejo) =>
      viejo.origen != origen || viejo.cuantas != cuantas;
}

/// Un destello de cuatro puntas: el brillo del hielo y del oro.
void pintarDestello(
  Canvas canvas,
  Offset centro,
  double radio,
  Color color, {
  double angulo = 0,
}) {
  if (radio <= .2) return;
  final punta = Path();
  for (var i = 0; i < 4; i++) {
    final a = angulo + i * math.pi / 2;
    final afuera = centro + Offset(math.cos(a), math.sin(a)) * radio;
    final b = a + math.pi / 4;
    final costado = centro + Offset(math.cos(b), math.sin(b)) * radio * .22;
    if (i == 0) {
      punta.moveTo(afuera.dx, afuera.dy);
    } else {
      punta.lineTo(afuera.dx, afuera.dy);
    }
    punta.lineTo(costado.dx, costado.dy);
  }
  punta.close();
  canvas
    ..drawCircle(
      centro,
      radio * .9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: color.a * .5),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio * .9)),
    )
    ..drawPath(punta, Paint()..color = color);
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

/// Un pez vivo: nada en el lugar (la cola y las aletas van y vienen), sube
/// y baja un poco y cada tanto parpadea. Con el telefono sin animaciones,
/// queda quieto.
class PezVivo extends StatefulWidget {
  const PezVivo({
    required this.pez,
    required this.ancho,
    this.ritmo = 1,
    this.fase = 0,
    super.key,
  });

  final Pez pez;
  final double ancho;

  /// Mas alto, nada mas rapido.
  final double ritmo;

  /// Para que dos peces juntos no se muevan igual.
  final double fase;

  @override
  State<PezVivo> createState() => _PezVivoState();
}

class _PezVivoState extends State<PezVivo> with SingleTickerProviderStateMixin {
  late final AnimationController _vida = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _vida.stop();
    } else if (!_vida.isAnimating) {
      _vida.repeat();
    }
  }

  @override
  void dispose() {
    _vida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size(widget.ancho, widget.ancho * .56),
      painter: _PintorPezVivo(widget.pez, _vida, widget.ritmo, widget.fase),
    ),
  );
}

class _PintorPezVivo extends CustomPainter {
  _PintorPezVivo(this.pez, this.vida, this.ritmo, this.fase)
    : super(repaint: vida);

  final Pez pez;
  final Animation<double> vida;
  final double ritmo;
  final double fase;

  @override
  void paint(Canvas canvas, Size size) {
    final t = (vida.value + fase) * 2 * math.pi;
    final sube = math.sin(t * 2) * size.height * .06;
    // Parpadea una vez por vuelta, rapido.
    final ciclo = (vida.value + fase) % 1;
    final parpadeo = ciclo > .9 && ciclo < .96
        ? 1 - ((ciclo - .93).abs() / .03)
        : 0.0;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2 + sube)
      ..rotate(math.sin(t * 2 + .6) * .05)
      ..translate(-size.width / 2, -size.height / 2);
    pintarPez(
      canvas,
      Offset.zero & size,
      pez,
      cola: math.sin(t * 6 * ritmo) * .28,
      parpadeo: parpadeo,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorPezVivo viejo) =>
      viejo.pez != pez || viejo.ritmo != ritmo || viejo.fase != fase;
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

/// La etiqueta de un multiplicador ("x5"), centrada en [centro] y girada
/// [angulo]. Con [copo] es la de una bola de nieve: blanca como la nieve,
/// con el numero azul y nieve encima. Sin [copo], la de la moneda: de oro.
void pintarMultiplicador(
  Canvas canvas,
  Offset centro,
  String texto,
  double alto, {
  double angulo = 0,
  bool copo = false,
  double opacidad = 1,
}) {
  Color a(Color c) => c.withValues(alpha: c.a * opacidad);
  final tinta = copo ? Colors.white : const Color(0xFF5A3A04);
  final letra = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w900,
        fontSize: alto * .78,
        height: 1,
        color: a(tinta),
        shadows: [
          Shadow(
            color: a(
              copo
                  ? const Color(0xFF0D3355).withValues(alpha: .8)
                  : Colors.white.withValues(alpha: .7),
            ),
            offset: Offset(0, alto * .05),
          ),
        ],
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
  final colores = copo
      ? [
          const Color(0xFF62B4EE),
          const Color(0xFF2B7BC6),
          const Color(0xFF17508F),
        ]
      : [ColoresPesca.oroClaro, ColoresPesca.oro, ColoresPesca.oroOscuro];
  canvas
    ..drawRRect(
      pildora.shift(Offset(0, alto * .1)),
      Paint()..color = Colors.black.withValues(alpha: .32 * opacidad),
    )
    ..drawRRect(
      pildora,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [for (final c in colores) a(c)],
        ).createShader(pildora.outerRect),
    )
    // El brillo de arriba, como de cosa redonda.
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -ancho / 2 + alto * .22,
          -alto * .4,
          ancho - alto * .44,
          alto * .3,
        ),
        Radius.circular(alto * .15),
      ),
      Paint()..color = Colors.white.withValues(alpha: .45 * opacidad),
    )
    ..drawRRect(
      pildora,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, alto * .07)
        ..color = a(copo ? Colors.white : const Color(0xFF8A6206)),
    );
  if (copo) {
    // La nieve que quedo pegada arriba.
    final nieve = Paint()..color = a(Colors.white);
    for (final (x, r) in [(-.32, .2), (-.1, .26), (.16, .22), (.34, .17)]) {
      canvas.drawCircle(Offset(ancho * x, -alto * .42), alto * r, nieve);
    }
  }
  final inicio = -ancho / 2 + alto * .35;
  if (copo) {
    pintarCopo(
      canvas,
      Offset(inicio + alto * .38, 0),
      alto * .32,
      a(Colors.white),
    );
  }
  letra.paint(canvas, Offset(inicio + extra, -letra.height / 2));
  canvas.restore();
}

/// Un cubo de hielo con volumen: la cara de arriba clara, la de adelante
/// transparente con reflejos, una grieta y escarcha en los bordes. Es lo
/// que congela la casilla de hielo que salio.
void pintarCuboDeHielo(Canvas canvas, Rect caja, {double opacidad = 1}) {
  final w = caja.width;
  final h = caja.height;
  Color a(Color c, double alfa) => c.withValues(alpha: alfa * opacidad);
  final r = RRect.fromRectAndRadius(
    caja,
    Radius.circular(caja.shortestSide * .16),
  );
  canvas
    // El frio que se escapa alrededor.
    ..drawRRect(
      r.inflate(caja.shortestSide * .12),
      Paint()
        ..shader = RadialGradient(
          colors: [a(Colors.white, .5), a(Colors.white, 0)],
        ).createShader(caja.inflate(caja.shortestSide * .12)),
    )
    ..drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            a(const Color(0xFFFFFFFF), .92),
            a(const Color(0xFFD8ECF6), .8),
            a(const Color(0xFF9FC9DF), .85),
          ],
        ).createShader(caja),
    );
  // La cara de arriba, mas clara: el cubo tiene profundidad.
  final arriba = Path()
    ..moveTo(caja.left + w * .08, caja.top + h * .3)
    ..lineTo(caja.left + w * .26, caja.top + h * .08)
    ..lineTo(caja.right - w * .08, caja.top + h * .08)
    ..lineTo(caja.right - w * .24, caja.top + h * .3)
    ..close();
  canvas
    ..drawPath(arriba, Paint()..color = a(Colors.white, .65))
    // El costado derecho, mas oscuro.
    ..drawPath(
      Path()
        ..moveTo(caja.right - w * .24, caja.top + h * .3)
        ..lineTo(caja.right - w * .08, caja.top + h * .08)
        ..lineTo(caja.right - w * .08, caja.bottom - h * .2)
        ..lineTo(caja.right - w * .24, caja.bottom - h * .06)
        ..close(),
      Paint()..color = a(const Color(0xFF7FB0CC), .45),
    )
    // Reflejos en diagonal.
    ..drawLine(
      caja.topLeft + Offset(w * .2, h * .52),
      caja.topLeft + Offset(w * .42, h * .36),
      Paint()
        ..strokeWidth = math.max(1, h * .07)
        ..strokeCap = StrokeCap.round
        ..color = a(Colors.white, .85),
    )
    ..drawLine(
      caja.topLeft + Offset(w * .22, h * .7),
      caja.topLeft + Offset(w * .3, h * .64),
      Paint()
        ..strokeWidth = math.max(1, h * .05)
        ..strokeCap = StrokeCap.round
        ..color = a(Colors.white, .7),
    )
    // Una grieta.
    ..drawPath(
      Path()
        ..moveTo(caja.left + w * .62, caja.top + h * .36)
        ..lineTo(caja.left + w * .5, caja.top + h * .55)
        ..lineTo(caja.left + w * .6, caja.top + h * .62)
        ..lineTo(caja.left + w * .46, caja.top + h * .88),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, h * .025)
        ..color = a(const Color(0xFF5B8FB0), .7),
    )
    ..drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, caja.shortestSide * .05)
        ..color = a(Colors.white, .95),
    );
  pintarDestello(
    canvas,
    caja.topLeft + Offset(w * .3, h * .14),
    caja.shortestSide * .22,
    a(Colors.white, 1),
  );
}
