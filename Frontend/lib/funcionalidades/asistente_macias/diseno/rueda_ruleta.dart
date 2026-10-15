import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logica/mesa_ruleta.dart';
import '../logica/trayectoria_bola.dart';

/// Los colores de la ruleta.
abstract final class ColoresRuleta {
  static const rojo = Color(0xFFB8141F);
  static const negro = Color(0xFF141414);
  static const verde = Color(0xFF0B7D3E);
  static const oro = Color(0xFFD9A21B);
  static const oroClaro = Color(0xFFF2CC5C);
  static const madera = Color(0xFF5A2711);
  static const maderaOscura = Color(0xFF2E1107);
  static const maderaClara = Color(0xFF8C4A22);

  static Color de(int numero) => switch (colorDe(numero)) {
    ColorRuleta.rojo => rojo,
    ColorRuleta.negro => negro,
    ColorRuleta.verde => verde,
  };
}

/// Las medidas de la rueda, en partes de su radio (de afuera hacia adentro).
abstract final class _Medidas {
  static const borde = 1.0;
  static const filete = .955;
  static const carrilAfuera = .94;
  static const carrilAdentro = .8;
  static const rombos = .785;
  static const cilindro = .765;
  static const numerosAfuera = .735;
  static const numerosAdentro = .628;
  static const casillasAdentro = .49;
  static const torreta = .17;
}

/// La ruleta: el cuenco quieto, el cilindro que gira y la bola.
///
/// El cilindro se pinta una vez y solo gira ([giro], en radianes): asi va al
/// ritmo de la pantalla sin volver a dibujar cada numero en cada cuadro. La
/// bola, en cambio, se mueve sola encima ([bola]: null si todavia no se
/// lanzo).
class RuedaRuleta extends StatelessWidget {
  const RuedaRuleta({
    required this.giro,
    required this.bola,
    this.ganadora,
    this.brillo,
    super.key,
  });

  final ValueListenable<double> giro;
  final ValueListenable<PosicionBola?> bola;

  /// La casilla que salio: brilla mientras [brillo] late.
  final int? ganadora;
  final Animation<double>? brillo;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'La ruleta',
    child: AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: _PintorCuenco())),
          AnimatedBuilder(
            animation: giro,
            child: const RepaintBoundary(
              child: CustomPaint(painter: PintorCilindro()),
            ),
            builder: (context, hijo) =>
                Transform.rotate(angle: giro.value, child: hijo),
          ),
          const IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: _PintorLuz())),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _PintorBola(
                bola: bola,
                giro: giro,
                ganadora: ganadora,
                brillo: brillo,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// El cuenco de madera: el borde con su filete dorado, el carril por donde
/// corre la bola y los rombos que la desvian.
class _PintorCuenco extends CustomPainter {
  const _PintorCuenco();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    Rect circulo(double f) => Rect.fromCircle(center: c, radius: r * f);

    // La sombra de la rueda sobre la mesa.
    canvas.drawCircle(
      c + Offset(0, r * .03),
      r * .99,
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
    );
    // El borde: madera lustrada, mas clara arriba a la izquierda.
    canvas.drawCircle(
      c,
      r * _Medidas.borde,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          radius: 1.15,
          colors: [
            ColoresRuleta.maderaClara,
            ColoresRuleta.madera,
            ColoresRuleta.maderaOscura,
          ],
          stops: [0, .55, 1],
        ).createShader(circulo(1)),
    );
    // La veta, apenas: anillos finos mas oscuros.
    final veta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .004
      ..color = const Color(0x22000000);
    for (final f in const [.992, .982, .971, .962]) {
      canvas.drawCircle(c, r * f, veta);
    }
    // El filete dorado.
    canvas.drawCircle(
      c,
      r * _Medidas.filete,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .012
        ..shader = const SweepGradient(
          colors: [
            ColoresRuleta.oroClaro,
            ColoresRuleta.oro,
            Color(0xFF8A6414),
            ColoresRuleta.oro,
            ColoresRuleta.oroClaro,
          ],
        ).createShader(circulo(1)),
    );
    // El carril: madera pulida, con la pared de afuera iluminada y la
    // bajada hacia el cilindro en sombra.
    final carril = Path()
      ..addOval(circulo(_Medidas.carrilAfuera))
      ..addOval(circulo(_Medidas.carrilAdentro))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      carril,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFF3A1709),
            Color(0xFF6E3518),
            Color(0xFFA0582B),
            Color(0xFFC07A45),
            Color(0xFF7A3D1A),
          ],
          stops: [_Medidas.carrilAdentro, .84, .9, .925, _Medidas.carrilAfuera],
        ).createShader(circulo(1)),
    );
    // El brillo del carril, donde rueda la bola.
    canvas.drawCircle(
      c,
      r * RadiosRueda.carril,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .01
        ..color = const Color(0x22FFE9C9),
    );
    // La sombra del cilindro sobre el cuenco.
    canvas.drawCircle(
      c,
      r * (_Medidas.cilindro + .012),
      Paint()
        ..color = const Color(0xAA000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .02),
    );
    // Los ocho rombos de bronce, uno parado y uno acostado.
    for (var k = 0; k < 8; k++) {
      final angulo = -math.pi / 2 + k * math.pi / 4 + math.pi / 8;
      final parado = k.isEven;
      canvas
        ..save()
        ..translate(
          c.dx + r * _Medidas.rombos * math.cos(angulo),
          c.dy + r * _Medidas.rombos * math.sin(angulo),
        )
        ..rotate(angulo + math.pi / 2);
      final largo = r * (parado ? .078 : .044);
      final ancho = r * (parado ? .032 : .064);
      final rombo = Path()
        ..moveTo(0, -largo / 2)
        ..lineTo(ancho / 2, 0)
        ..lineTo(0, largo / 2)
        ..lineTo(-ancho / 2, 0)
        ..close();
      canvas
        ..drawPath(
          rombo.shift(Offset(r * .006, r * .008)),
          Paint()..color = const Color(0x88000000),
        )
        ..drawPath(
          rombo,
          Paint()
            ..shader =
                const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE7A3),
                    ColoresRuleta.oro,
                    Color(0xFF6B4A0E),
                  ],
                ).createShader(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: ancho,
                    height: largo,
                  ),
                ),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_PintorCuenco viejo) => false;
}

/// El cilindro: el aro de metal, los numeros, las casillas con sus
/// separadores, el cono de madera y la torreta. Es lo que gira.
///
/// Publico para que el lobby del casino muestre la rueda en miniatura.
class PintorCilindro extends CustomPainter {
  const PintorCilindro();

  static final _cache = <double, List<TextPainter>>{};

  /// Los numeros, armados una vez por tamaño.
  static List<TextPainter> _numeros(double r) => _cache.putIfAbsent(r, () {
    if (_cache.length > 6) _cache.clear();
    return [
      for (final numero in ordenRueda)
        TextPainter(
          text: TextSpan(
            text: '$numero',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: r * .066,
              height: 1,
              color: Colors.white,
              letterSpacing: -r * .002,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    Rect circulo(double f) => Rect.fromCircle(center: c, radius: r * f);
    const n = 37;
    const paso = 2 * math.pi / n;

    // El aro de metal del cilindro.
    canvas.drawCircle(
      c,
      r * _Medidas.cilindro,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFE2E2E2),
            Color(0xFF7E7E7E),
            Color(0xFFCFCFCF),
            Color(0xFF5F5F5F),
            Color(0xFFE2E2E2),
          ],
        ).createShader(circulo(1)),
    );
    // Los segmentos de los numeros y las casillas.
    for (var k = 0; k < n; k++) {
      final numero = ordenRueda[k];
      final color = ColoresRuleta.de(numero);
      final desde = -math.pi / 2 + (k - .5) * paso;
      final segmento = Path()
        ..arcTo(circulo(_Medidas.numerosAfuera), desde, paso, true)
        ..arcTo(circulo(_Medidas.numerosAdentro), desde + paso, -paso, false)
        ..close();
      canvas.drawPath(segmento, Paint()..color = color);
      // La casilla: el mismo color, mas hondo, con la pared de afuera en
      // sombra.
      final casilla = Path()
        ..arcTo(circulo(_Medidas.numerosAdentro), desde, paso, true)
        ..arcTo(circulo(_Medidas.casillasAdentro), desde + paso, -paso, false)
        ..close();
      canvas.drawPath(
        casilla,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(color, Colors.white, .1)!,
              Color.lerp(color, Colors.black, .25)!,
              Color.lerp(color, Colors.black, .62)!,
            ],
            stops: const [
              _Medidas.casillasAdentro,
              .57,
              _Medidas.numerosAdentro,
            ],
          ).createShader(circulo(1)),
      );
    }
    // Los filetes dorados entre numeros, y los separadores de metal entre
    // casillas (los "trastes" contra los que rebota la bola).
    final filete = Paint()
      ..strokeWidth = r * .006
      ..color = const Color(0xCCE8C46A);
    final traste = Paint()
      ..strokeWidth = r * .012
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFF8D8D8D),
          Color(0xFFE9E9E9),
          Color(0xFF7A7A7A),
          Color(0xFFFFFFFF),
        ],
      ).createShader(circulo(1));
    for (var k = 0; k < n; k++) {
      final a = -math.pi / 2 + (k - .5) * paso;
      final direccion = Offset(math.cos(a), math.sin(a));
      canvas
        ..drawLine(
          c + direccion * (r * _Medidas.numerosAdentro),
          c + direccion * (r * _Medidas.numerosAfuera),
          filete,
        )
        ..drawLine(
          c + direccion * (r * (_Medidas.casillasAdentro + .01)),
          c + direccion * (r * (_Medidas.numerosAdentro - .004)),
          traste,
        );
    }
    // Los bordes del anillo de numeros.
    final borde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .008
      ..color = const Color(0xFFE8C46A);
    canvas
      ..drawCircle(c, r * _Medidas.numerosAfuera, borde)
      ..drawCircle(c, r * _Medidas.numerosAdentro, borde);
    // Los numeros: cada uno de pie, mirando hacia afuera.
    final numeros = _numeros(r);
    final radioTexto =
        r * (_Medidas.numerosAfuera + _Medidas.numerosAdentro) / 2;
    for (var k = 0; k < n; k++) {
      final a = -math.pi / 2 + k * paso;
      final texto = numeros[k];
      canvas
        ..save()
        ..translate(
          c.dx + radioTexto * math.cos(a),
          c.dy + radioTexto * math.sin(a),
        )
        ..rotate(a + math.pi / 2);
      texto.paint(canvas, Offset(-texto.width / 2, -texto.height / 2));
      canvas.restore();
    }
    // El cono de madera, que baja hacia la torreta.
    canvas.drawCircle(
      c,
      r * _Medidas.casillasAdentro,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFF9C5A2C),
            ColoresRuleta.madera,
            ColoresRuleta.maderaOscura,
          ],
          stops: [.25, .7, 1],
        ).createShader(circulo(_Medidas.casillasAdentro)),
    );
    canvas.drawCircle(
      c,
      r * _Medidas.casillasAdentro,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .014
        ..color = const Color(0xFFD9D9D9),
    );
    // Los filetes dorados del cono.
    final adorno = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .006
      ..color = const Color(0x99E8C46A);
    canvas
      ..drawCircle(c, r * .4, adorno)
      ..drawCircle(c, r * .25, adorno);
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r * .25), c + d * (r * .4), adorno);
    }
    _torreta(canvas, c, r);
  }

  /// La torreta de cromo: una base, cuatro brazos con su bolita y la tapa.
  static void _torreta(Canvas canvas, Offset c, double r) {
    final cromo = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.4, -.4),
        colors: [Color(0xFFFFFFFF), Color(0xFFBDBDBD), Color(0xFF5E5E5E)],
        stops: [0, .5, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r * _Medidas.torreta));
    canvas
      ..drawCircle(
        c + Offset(r * .01, r * .015),
        r * _Medidas.torreta,
        Paint()
          ..color = const Color(0x77000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .02),
      )
      ..drawCircle(c, r * _Medidas.torreta, cromo);
    final brazo = Paint()
      ..strokeWidth = r * .045
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFF9E9E9E), Color(0xFFE0E0E0)],
      ).createShader(Rect.fromCircle(center: c, radius: r * .3));
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2 + math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      final punta = c + d * (r * .29);
      canvas
        ..drawLine(c, punta, brazo)
        ..drawCircle(
          punta,
          r * .038,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.4, -.4),
              colors: [Color(0xFFFFFFFF), Color(0xFFB0B0B0), Color(0xFF555555)],
            ).createShader(Rect.fromCircle(center: punta, radius: r * .038)),
        );
    }
    canvas
      ..drawCircle(c, r * .075, cromo)
      ..drawCircle(
        c,
        r * .075,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .006
          ..color = const Color(0x88FFFFFF),
      )
      ..drawCircle(
        c - Offset(r * .02, r * .022),
        r * .022,
        Paint()..color = const Color(0xCCFFFFFF),
      );
  }

  @override
  bool shouldRepaint(PintorCilindro viejo) => false;
}

/// La luz de la sala sobre la rueda: no gira con el cilindro, y por eso se
/// nota que el cilindro gira.
class _PintorLuz extends CustomPainter {
  const _PintorLuz();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    canvas
      ..drawCircle(
        c,
        r * _Medidas.cilindro,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.45, -.55),
            radius: .9,
            colors: [
              Colors.white.withValues(alpha: .16),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      )
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(.35, .4),
            radius: 1.05,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: .22),
            ],
            stops: const [.6, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
  }

  @override
  bool shouldRepaint(_PintorLuz viejo) => false;
}

/// La bola de marfil, con su sombra: cuando salta se agranda y la sombra se
/// separa. Y, cuando ya cayo, la casilla ganadora brilla.
class _PintorBola extends CustomPainter {
  _PintorBola({
    required this.bola,
    required this.giro,
    required this.ganadora,
    required this.brillo,
  }) : super(repaint: Listenable.merge([bola, giro, ?brillo]));

  final ValueListenable<PosicionBola?> bola;
  final ValueListenable<double> giro;
  final int? ganadora;
  final Animation<double>? brillo;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = size.center(Offset.zero);
    final casilla = ganadora;
    if (casilla != null) {
      final latido = brillo?.value ?? 1;
      final a = giro.value + TrayectoriaBola.anguloCasilla(casilla);
      const medio = math.pi / 37;
      canvas.drawArc(
        Rect.fromCircle(
          center: c,
          radius: r * (_Medidas.numerosAfuera + _Medidas.casillasAdentro) / 2,
        ),
        a - medio,
        2 * medio,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              r * (_Medidas.numerosAfuera - _Medidas.casillasAdentro)
          ..color = ColoresRuleta.oroClaro.withValues(alpha: .18 + .3 * latido)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .02),
      );
    }
    final posicion = bola.value;
    if (posicion == null) return;
    final centro =
        c +
        Offset(
          math.cos(posicion.angulo) * r * posicion.radio,
          math.sin(posicion.angulo) * r * posicion.radio,
        );
    final h = posicion.altura;
    final radio = r * RadiosRueda.bola * (1 + .35 * h);
    canvas.drawCircle(
      centro + Offset(radio * (.35 + 1.4 * h), radio * (.45 + 1.8 * h)),
      radio * (1 + .2 * h),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, .45 - .25 * h)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radio * (.5 + h)),
    );
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.4),
          radius: .95,
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFF1EEE6),
            Color(0xFFB9B4A8),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );
  }

  @override
  bool shouldRepaint(_PintorBola viejo) =>
      viejo.ganadora != ganadora ||
      viejo.bola != bola ||
      viejo.giro != giro ||
      viejo.brillo != brillo;
}
