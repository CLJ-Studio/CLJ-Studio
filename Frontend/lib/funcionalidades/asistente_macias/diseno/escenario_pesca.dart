import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// La noche polar detras de la rueda de la pesca.
///
/// Lo quieto (el cielo, la luna, las montañas con la luz de la luna, los
/// pinos nevados, el lago congelado con su reflejo y el campamento de pesca
/// con las ventanas prendidas) se dibuja una sola vez. Encima, en cada
/// cuadro, lo que se mueve: la aurora que ondula, las estrellas que
/// titilan, el humo de las chimeneas, alguna estrella fugaz y la nieve que
/// cae a tres distancias.
class EscenarioPesca extends StatelessWidget {
  const EscenarioPesca({
    required this.reloj,
    required this.horizonte,
    this.quieto = false,
    super.key,
  });

  /// Los segundos de la mesa: mueven la aurora, el humo y la nieve.
  final ValueListenable<double> reloj;

  /// A que altura queda el horizonte, en la pantalla.
  final double horizonte;

  /// Sin animaciones (lo pide el telefono): todo queda quieto.
  final bool quieto;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(
        child: CustomPaint(painter: _PintorNocheQuieta(horizonte)),
      ),
      RepaintBoundary(
        child: CustomPaint(
          painter: _PintorNocheViva(
            reloj: reloj,
            horizonte: horizonte,
            quieto: quieto,
          ),
        ),
      ),
    ],
  );
}

/// Las chimeneas del campamento: de ahi sale el humo.
List<Offset> _chimeneas(Size size, double horizonte) => [
  for (final (x, ancho, _) in _casitas)
    Offset(
      size.width * x + size.width * ancho * .72,
      horizonte - size.width * ancho * .78,
    ),
];

/// Las casitas de pesca sobre el hielo: donde estan, lo anchas que son (en
/// anchos de pantalla) y su color.
const _casitas = [
  (.04, .065, Color(0xFF8E2F2B)),
  (.15, .05, Color(0xFF2E5A8C)),
  (.83, .055, Color(0xFF9A7A2C)),
  (.925, .045, Color(0xFF2F7A5C)),
];

class _PintorNocheQuieta extends CustomPainter {
  const _PintorNocheQuieta(this.horizonte);

  final double horizonte;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hz = horizonte;
    final azar = math.Random(21);

    // El cielo: de la noche cerrada a un azul verdoso sobre el horizonte.
    final cielo = Rect.fromLTRB(0, 0, w, hz + 2);
    canvas.drawRect(
      cielo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF02070F),
            Color(0xFF081A2C),
            Color(0xFF0F3149),
            Color(0xFF1C5368),
          ],
          stops: [0, .4, .78, 1],
        ).createShader(cielo),
    );

    // Las estrellas, mas apagadas cerca del horizonte.
    final estrella = Paint();
    for (var i = 0; i < 110; i++) {
      final p = Offset(azar.nextDouble() * w, azar.nextDouble() * hz * .9);
      final r = .35 + azar.nextDouble() * .9;
      estrella.color = Colors.white.withValues(
        alpha: (.25 + azar.nextDouble() * .6) * (1 - p.dy / hz * .75),
      );
      canvas.drawCircle(p, r, estrella);
    }

    // La luna, con su halo.
    final luna = Offset(w * .9, hz * .43);
    final radio = (w * .04).clamp(11.0, 24.0);
    canvas
      ..drawCircle(
        luna,
        radio * 4.2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF3D6).withValues(alpha: .28),
              const Color(0xFFFFF3D6).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: luna, radius: radio * 4.2)),
      )
      ..drawCircle(
        luna,
        radio,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.35, -.35),
            colors: [Color(0xFFFFFDF2), Color(0xFFF0E6C8), Color(0xFFD9CDA8)],
            stops: [0, .6, 1],
          ).createShader(Rect.fromCircle(center: luna, radius: radio)),
      );
    final crater = Paint()
      ..color = const Color(0xFFB9AC86).withValues(alpha: .35);
    for (final (x, y, r) in const [
      (.3, -.25, .22),
      (-.3, .2, .16),
      (.15, .38, .12),
    ]) {
      canvas.drawCircle(luna + Offset(x, y) * radio, radio * r, crater);
    }

    // Las montañas, en tres capas: las de atras mas claras (hay aire en el
    // medio), con nieve en las puntas y el lado de la luna iluminado.
    for (final (alto, color, nieve, paso, semilla) in const [
      (.3, Color(0xFF1A3D55), .55, .13, 3),
      (.21, Color(0xFF132F45), .42, .1, 5),
      (.12, Color(0xFF0D2335), .28, .075, 8),
    ]) {
      final picos = <Offset>[];
      final r = math.Random(semilla);
      var x = -w * .06;
      var arriba = true;
      while (x <= w * 1.06) {
        final y = arriba
            ? hz - hz * alto * (.55 + r.nextDouble() * .45)
            : hz - hz * alto * (.1 + r.nextDouble() * .3);
        picos.add(Offset(x, y));
        x += w * paso * (.7 + r.nextDouble() * .6);
        arriba = !arriba;
      }
      final cordillera = Path()..moveTo(-w * .06, hz + 1);
      for (final p in picos) {
        cordillera.lineTo(p.dx, p.dy);
      }
      cordillera
        ..lineTo(w * 1.06, hz + 1)
        ..close();
      final caja = cordillera.getBounds();
      canvas.drawPath(
        cordillera,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, .12)!, color],
          ).createShader(caja),
      );
      for (var i = 1; i < picos.length - 1; i++) {
        final pico = picos[i];
        if (pico.dy > picos[i - 1].dy || pico.dy > picos[i + 1].dy) continue;
        final izquierda = picos[i - 1];
        final derecha = picos[i + 1];
        // El lado que mira a la luna (a la derecha), con luz.
        canvas.drawPath(
          Path()
            ..moveTo(pico.dx, pico.dy)
            ..lineTo(derecha.dx, derecha.dy)
            ..lineTo(
              Offset.lerp(pico, derecha, .5)!.dx - (derecha.dx - pico.dx) * .1,
              hz,
            )
            ..close(),
          Paint()..color = const Color(0xFF9CC4DA).withValues(alpha: .07),
        );
        // La nieve de la punta.
        final baja = (math.min(derecha.dy, izquierda.dy) - pico.dy) * .38;
        canvas.drawPath(
          Path()
            ..moveTo(pico.dx, pico.dy)
            ..lineTo(
              Offset.lerp(
                pico,
                derecha,
                baja / (derecha.dy - pico.dy).abs().clamp(1, 1e9),
              )!.dx,
              pico.dy + baja,
            )
            ..lineTo(
              pico.dx + (derecha.dx - pico.dx) * .08,
              pico.dy + baja * .7,
            )
            ..lineTo(
              pico.dx - (pico.dx - izquierda.dx) * .06,
              pico.dy + baja * .85,
            )
            ..lineTo(
              Offset.lerp(
                pico,
                izquierda,
                baja / (izquierda.dy - pico.dy).abs().clamp(1, 1e9),
              )!.dx,
              pico.dy + baja,
            )
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: nieve),
        );
      }
    }

    // Los pinos nevados en las orillas.
    for (var i = 0; i < 22; i++) {
      final izquierda = i < 11;
      final x = izquierda
          ? w * (.0 + i * .022) + azar.nextDouble() * 6
          : w * (.76 + (i - 11) * .023) + azar.nextDouble() * 6;
      final alto = hz * (.05 + azar.nextDouble() * .05);
      _pino(canvas, Offset(x, hz + 2), alto);
    }

    // El lago congelado, con el reflejo de la luna y vetas de brillo.
    final lago = Rect.fromLTRB(0, hz, w, h);
    canvas.drawRect(
      lago,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2F6584),
            Color(0xFF183F57),
            Color(0xFF0A1B28),
            Color(0xFF040B12),
          ],
          stops: [0, .22, .58, 1],
        ).createShader(lago),
    );
    final reflejo = Rect.fromCenter(
      center: Offset(luna.dx, hz + (h - hz) * .16),
      width: radio * 3.4,
      height: (h - hz) * .32,
    );
    canvas.drawOval(
      reflejo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF3D6).withValues(alpha: .2),
            const Color(0xFFFFF3D6).withValues(alpha: 0),
          ],
        ).createShader(reflejo),
    );
    final veta = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final y = hz + 4 + math.pow(azar.nextDouble(), 1.6) * (h - hz) * .45;
      final x = azar.nextDouble() * w;
      final largo = 12 + azar.nextDouble() * 50;
      veta
        ..strokeWidth = .8 + azar.nextDouble() * .8
        ..color = Colors.white.withValues(alpha: .05 + azar.nextDouble() * .1);
      canvas.drawLine(Offset(x, y), Offset(x + largo, y), veta);
    }
    // Las grietas del hielo, con sus ramas.
    final grieta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = Colors.white.withValues(alpha: .1);
    for (var i = 0; i < 9; i++) {
      var p = Offset(
        azar.nextDouble() * w,
        hz + 10 + azar.nextDouble() * (h - hz) * .45,
      );
      final linea = Path()..moveTo(p.dx, p.dy);
      for (var j = 0; j < 5; j++) {
        final siguiente =
            p + Offset((azar.nextDouble() - .5) * 46, azar.nextDouble() * 14);
        linea.lineTo(siguiente.dx, siguiente.dy);
        if (azar.nextDouble() < .4) {
          linea
            ..moveTo(siguiente.dx, siguiente.dy)
            ..lineTo(
              siguiente.dx + (azar.nextDouble() - .5) * 22,
              siguiente.dy + azar.nextDouble() * 9,
            )
            ..moveTo(siguiente.dx, siguiente.dy);
        }
        p = siguiente;
      }
      canvas.drawPath(linea, grieta);
    }

    // El campamento: casitas de colores con la ventana prendida.
    for (final (x, ancho, color) in _casitas) {
      _casita(canvas, Offset(w * x, hz + 3), w * ancho, color);
    }

    // La escarcha en las esquinas de arriba.
  }

  void _pino(Canvas canvas, Offset base, double alto) {
    const verde = Color(0xFF0A1C2A);
    final ancho = alto * .62;
    final tronco = Paint()..color = const Color(0xFF07131D);
    canvas.drawRect(
      Rect.fromCenter(
        center: base - Offset(0, alto * .06),
        width: ancho * .14,
        height: alto * .14,
      ),
      tronco,
    );
    for (var piso = 0; piso < 3; piso++) {
      final abajo = base.dy - alto * (.08 + piso * .27);
      final mitad = ancho / 2 * (1 - piso * .24);
      final punta = abajo - alto * .42;
      canvas
        ..drawPath(
          Path()
            ..moveTo(base.dx - mitad, abajo)
            ..lineTo(base.dx, punta)
            ..lineTo(base.dx + mitad, abajo)
            ..close(),
          Paint()..color = verde,
        )
        // La nieve sobre cada piso.
        ..drawPath(
          Path()
            ..moveTo(base.dx - mitad * .55, abajo - alto * .1)
            ..lineTo(base.dx, punta)
            ..lineTo(base.dx + mitad * .45, abajo - alto * .12)
            ..quadraticBezierTo(
              base.dx,
              abajo - alto * .2,
              base.dx - mitad * .55,
              abajo - alto * .1,
            )
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: .38),
        );
    }
  }

  void _casita(Canvas canvas, Offset piso, double ancho, Color color) {
    final alto = ancho * .62;
    final pared = Rect.fromLTWH(piso.dx, piso.dy - alto, ancho, alto);
    canvas
      ..drawRect(pared, Paint()..color = Color.lerp(color, Colors.black, .35)!)
      ..drawRect(
        Rect.fromLTWH(pared.left, pared.top, ancho * .55, alto),
        Paint()..color = Color.lerp(color, Colors.black, .15)!,
      );
    // La ventana prendida, con su luz sobre la nieve.
    final ventana = Rect.fromLTWH(
      pared.left + ancho * .14,
      pared.top + alto * .3,
      ancho * .26,
      alto * .3,
    );
    canvas
      ..drawCircle(
        ventana.center,
        ancho * .5,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  const Color(0xFFFFC56B).withValues(alpha: .35),
                  const Color(0xFFFFC56B).withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: ventana.center, radius: ancho * .5),
              ),
      )
      ..drawRect(ventana, Paint()..color = const Color(0xFFFFD27F))
      ..drawRect(
        Rect.fromLTWH(
          pared.left + ancho * .62,
          pared.top + alto * .36,
          ancho * .2,
          alto * .64,
        ),
        Paint()..color = const Color(0xFF1E140C),
      );
    // El techo nevado y la chimenea.
    canvas
      ..drawRect(
        Rect.fromLTWH(
          pared.left + ancho * .66,
          pared.top - alto * .5,
          ancho * .12,
          alto * .4,
        ),
        Paint()..color = const Color(0xFF3B2A1E),
      )
      ..drawPath(
        Path()
          ..moveTo(pared.left - ancho * .1, pared.top + alto * .08)
          ..lineTo(pared.left + ancho * .14, pared.top - alto * .36)
          ..lineTo(pared.right - ancho * .14, pared.top - alto * .36)
          ..lineTo(pared.right + ancho * .1, pared.top + alto * .08)
          ..close(),
        Paint()..color = const Color(0xFFE8F2F8),
      );
  }

  @override
  bool shouldRepaint(_PintorNocheQuieta viejo) => viejo.horizonte != horizonte;
}

class _PintorNocheViva extends CustomPainter {
  _PintorNocheViva({
    required this.reloj,
    required this.horizonte,
    required this.quieto,
  }) : super(repaint: quieto ? null : reloj);

  final ValueListenable<double> reloj;
  final double horizonte;
  final bool quieto;

  @override
  void paint(Canvas canvas, Size size) {
    final t = quieto ? 0.0 : reloj.value;
    final w = size.width;
    final h = size.height;
    final hz = horizonte;

    // La aurora: cortinas de luz que ondulan, con el borde de abajo mas
    // brillante y que se apagan hacia arriba.
    for (final (base, alto, color, fase, vel) in [
      (hz * .3, hz * .26, const Color(0xFF3CF2B4), 0.0, .26),
      (hz * .42, hz * .18, const Color(0xFF39C6F2), 2.1, .19),
      (hz * .22, hz * .16, const Color(0xFFA27BFF), 4.3, .15),
    ]) {
      final abajo = <Offset>[];
      final arriba = <Offset>[];
      for (var i = 0; i <= 40; i++) {
        final x = -w * .1 + w * 1.2 * i / 40;
        final u = x / w;
        final y =
            base +
            math.sin(u * 4.1 + t * vel * 2 + fase) * hz * .05 +
            math.sin(u * 9.3 - t * vel * 3.2 + fase * 1.7) * hz * .018;
        final grosor =
            alto * (.45 + .55 * math.sin(u * 3.1 + t * vel * 1.4 + fase).abs());
        abajo.add(Offset(x, y));
        arriba.add(Offset(x, y - grosor));
      }
      final cortina = Path()..addPolygon([...abajo, ...arriba.reversed], true);
      final caja = cortina.getBounds();
      final late = .8 + .2 * math.sin(t * .7 + fase);
      canvas
        ..drawPath(
          cortina,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: .34 * late),
                color.withValues(alpha: .13 * late),
                color.withValues(alpha: 0),
              ],
              stops: const [0, .1, .45, 1],
            ).createShader(caja),
        )
        ..drawPath(
          Path()..addPolygon(abajo, false),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = color.withValues(alpha: .12 * late),
        )
        ..drawPath(
          Path()..addPolygon(abajo, false),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = color.withValues(alpha: .3 * late),
        );
    }

    // Las estrellas que titilan, con su cruz cuando brillan.
    final azar = math.Random(77);
    for (var i = 0; i < 16; i++) {
      final p = Offset(azar.nextDouble() * w, azar.nextDouble() * hz * .7);
      final brilla =
          .5 + .5 * math.sin(t * (1.2 + azar.nextDouble() * 1.8) + i * 1.9);
      final r = .8 + brilla * 1.1;
      final color = Colors.white.withValues(alpha: .25 + .65 * brilla);
      canvas.drawCircle(p, r, Paint()..color = color);
      if (brilla > .75) {
        final cruz = Paint()
          ..strokeWidth = .7
          ..color = Colors.white.withValues(alpha: (brilla - .75) * 2);
        canvas
          ..drawLine(p - Offset(r * 3.5, 0), p + Offset(r * 3.5, 0), cruz)
          ..drawLine(p - Offset(0, r * 3.5), p + Offset(0, r * 3.5), cruz);
      }
    }

    // Una estrella fugaz cada tanto.
    final fugaz = (t % 13) / .9;
    if (fugaz < 1) {
      final desde = Offset(w * .18, hz * .08);
      final cabeza =
          desde + Offset(w * .4, hz * .16) * Curves.easeIn.transform(fugaz);
      final cola = cabeza - Offset(w * .4, hz * .16) * .25;
      canvas.drawLine(
        cola,
        cabeza,
        Paint()
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .9 * (1 - fugaz)),
            ],
          ).createShader(Rect.fromPoints(cola, cabeza)),
      );
    }

    // El humo de las chimeneas, que sube y se deshace con el viento.
    final humo = Paint();
    for (final (j, chimenea) in _chimeneas(size, hz).indexed) {
      for (var k = 0; k < 6; k++) {
        final edad = (t * .28 + k / 6 + j * .17) % 1;
        final p =
            chimenea +
            Offset(
              edad * 16 + math.sin(edad * 6 + k + j) * 3,
              -edad * hz * .17,
            );
        humo.color = const Color(
          0xFFB9C9D3,
        ).withValues(alpha: .22 * (1 - edad) * math.min(1, edad * 6));
        canvas.drawCircle(p, 1.6 + edad * 8, humo);
      }
    }

    // La nieve: lejos (chica, lenta), al medio y cerca (grande y borrosa).
    final copo = Paint();
    for (final (cuantos, radio, velocidad, alfa, semilla) in const [
      (46, .9, 13.0, .45, 3),
      (22, 1.6, 27.0, .65, 5),
      (8, 3.6, 52.0, .28, 7),
    ]) {
      final r = math.Random(semilla);
      for (var i = 0; i < cuantos; i++) {
        final vel = velocidad * (.75 + r.nextDouble() * .5);
        final y = (t * vel + r.nextDouble() * (h + 40)) % (h + 40) - 20;
        final x =
            (r.nextDouble() * w + t * velocidad * .18) % (w + 20) -
            10 +
            math.sin(t * .6 + i * 1.3) * radio * 5;
        final tam = radio * (.7 + r.nextDouble() * .6);
        if (radio > 3) {
          copo.shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: alfa),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: tam));
        } else {
          copo
            ..shader = null
            ..color = Colors.white.withValues(alpha: alfa);
        }
        canvas.drawCircle(Offset(x, y), tam, copo);
      }
    }
  }

  @override
  bool shouldRepaint(_PintorNocheViva viejo) =>
      viejo.horizonte != horizonte || viejo.quieto != quieto;
}
