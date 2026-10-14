import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import 'cartas_blackjack.dart';

/// El paño de la mesa: el riel de cuero, el fieltro verde iluminado desde
/// donde esta MacIAs y las leyendas en arco, como en un casino.
///
/// Es quieto: se pinta una vez por tamano de pantalla y queda en su propia
/// capa, debajo de todo lo que se mueve.
class PintorPano extends CustomPainter {
  const PintorPano({required this.arcoY, required this.leyendas});

  /// La altura (desde arriba del paño) donde apoya la leyenda principal.
  final double arcoY;

  /// En una pantalla muy baja no entran: el paño va liso.
  final bool leyendas;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final riel = RRect.fromRectAndRadius(rect, const Radius.circular(30));
    canvas
      ..drawRRect(
        riel,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A3D2E), Color(0xFF2E1F17), Color(0xFF1B120D)],
          ).createShader(rect),
      )
      ..drawRRect(
        riel.deflate(1.2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0x40FFFFFF),
      );

    final pano = RRect.fromRectAndRadius(
      rect.deflate(11),
      const Radius.circular(21),
    );
    canvas
      ..drawRRect(
        pano,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.35, -.75),
            radius: 1.25,
            colors: [
              Color(0xFF1F9461),
              Color(0xFF137449),
              Color(0xFF0B5235),
              Color(0xFF063623),
            ],
            stops: [0, .35, .72, 1],
          ).createShader(pano.outerRect),
      )
      ..save()
      ..clipRRect(pano);

    // La trama del fieltro: puntitos claros y oscuros, siempre los mismos.
    final azar = math.Random(7);
    final claro = Paint()..color = const Color(0x0AFFFFFF);
    final oscuro = Paint()..color = const Color(0x0D000000);
    final area = pano.outerRect;
    for (var i = 0; i < 1400; i++) {
      final x = area.left + azar.nextDouble() * area.width;
      final y = area.top + azar.nextDouble() * area.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), i.isEven ? claro : oscuro);
    }
    // La sombra del riel sobre el fieltro.
    canvas
      ..drawRRect(
        pano.inflate(4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = const Color(0x80000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..restore()
      ..drawRRect(
        pano.inflate(3.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ColoresCarta.oro.withValues(alpha: .8),
      );

    if (leyendas) _leyendas(canvas, size);
  }

  void _leyendas(Canvas canvas, Size size) {
    final radio = size.width * .82;
    final centro = Offset(size.width / 2, arcoY - radio);
    _textoEnArco(
      canvas,
      'BLACKJACK PAGA 3 A 2',
      centro,
      radio,
      const TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w900,
        fontSize: 15,
        letterSpacing: 2.4,
        height: 1,
        color: ColoresCarta.oroClaro,
      ),
    );
    _textoEnArco(
      canvas,
      'EL CRUPIER PIDE HASTA 16 Y SE PLANTA EN 17',
      centro,
      radio + 19,
      TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w800,
        fontSize: 9.5,
        letterSpacing: 1.5,
        height: 1,
        color: ConfiguracionTema.crema.withValues(alpha: .55),
      ),
    );
    // La franja del seguro.
    final seguro = Rect.fromCircle(center: centro, radius: radio + 44);
    const desde = math.pi / 2 - .3;
    canvas
      ..drawArc(
        seguro,
        desde,
        .6,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..color = ColoresCarta.oro.withValues(alpha: .1),
      )
      ..drawArc(
        seguro.inflate(11),
        desde,
        .6,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = ColoresCarta.oro.withValues(alpha: .45),
      )
      ..drawArc(
        seguro.deflate(11),
        desde,
        .6,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = ColoresCarta.oro.withValues(alpha: .45),
      );
    _textoEnArco(
      canvas,
      'SEGURO PAGA 2 A 1',
      centro,
      radio + 49,
      TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w900,
        fontSize: 9.5,
        letterSpacing: 2,
        height: 1,
        color: ColoresCarta.oroClaro.withValues(alpha: .7),
      ),
    );
  }

  /// Escribe [texto] sobre la parte de abajo de un circulo, letra por letra,
  /// cada una parada sobre la curva.
  static void _textoEnArco(
    Canvas canvas,
    String texto,
    Offset centro,
    double radio,
    TextStyle estilo,
  ) {
    final letras = [
      for (final letra in texto.split(''))
        TextPainter(
          text: TextSpan(text: letra, style: estilo),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final largo = letras.fold(0.0, (suma, letra) => suma + letra.width);
    // De izquierda a derecha por abajo del circulo es de angulo mayor a menor.
    var angulo = math.pi / 2 + largo / radio / 2;
    for (final letra in letras) {
      final medio = angulo - letra.width / 2 / radio;
      final punto = centro + Offset(math.cos(medio), math.sin(medio)) * radio;
      canvas
        ..save()
        ..translate(punto.dx, punto.dy)
        ..rotate(medio - math.pi / 2);
      letra.paint(canvas, Offset(-letra.width / 2, -letra.height));
      canvas.restore();
      angulo -= letra.width / radio;
    }
  }

  @override
  bool shouldRepaint(PintorPano viejo) =>
      viejo.arcoY != arcoY || viejo.leyendas != leyendas;
}

/// El circulo donde se apuesta.
class LugarApuesta extends StatelessWidget {
  const LugarApuesta({this.diametro = 64, this.activo = false, super.key});

  final double diametro;

  /// La mano que se esta jugando: el circulo se ilumina.
  final bool activo;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
    width: diametro,
    height: diametro,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: activo ? const Color(0x22F2CC5C) : const Color(0x14000000),
      border: Border.all(
        color: activo
            ? ColoresCarta.oroClaro.withValues(alpha: .9)
            : ConfiguracionTema.crema.withValues(alpha: .32),
        width: activo ? 2 : 1.5,
      ),
    ),
  );
}

/// Papelitos de colores: para el blackjack y los premios grandes.
///
/// Cada vez que cambia [disparo], estalla desde [origen]. Se pinta solo
/// mientras caen; el resto del tiempo no cuesta nada.
class Confeti extends StatefulWidget {
  const Confeti({required this.disparo, required this.origen, super.key});

  final int disparo;
  final Offset origen;

  @override
  State<Confeti> createState() => _ConfetiState();
}

class _Papel {
  _Papel(math.Random azar, this.origen)
    : angulo = -math.pi / 2 + (azar.nextDouble() - .5) * 2.3,
      rapidez = 380 + azar.nextDouble() * 520,
      giro = (azar.nextDouble() - .5) * 16,
      ancho = 5 + azar.nextDouble() * 6,
      alto = 3 + azar.nextDouble() * 4,
      redondo = azar.nextDouble() < .25,
      color = _colores[azar.nextInt(_colores.length)];

  static const _colores = [
    ColoresCarta.oroClaro,
    ColoresCarta.oro,
    ConfiguracionTema.crema,
    ConfiguracionTema.naranjaCoral,
    ConfiguracionTema.salviaClara,
    Color(0xFF8E5CF7),
    Colors.white,
  ];

  final Offset origen;
  final double angulo;
  final double rapidez;
  final double giro;
  final double ancho;
  final double alto;
  final bool redondo;
  final Color color;
}

class _ConfetiState extends State<Confeti> with SingleTickerProviderStateMixin {
  late final AnimationController _caida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  final _azar = math.Random();
  List<_Papel> _papeles = const [];

  @override
  void didUpdateWidget(Confeti viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.disparo != widget.disparo && widget.disparo > 0) {
      _papeles = [for (var i = 0; i < 110; i++) _Papel(_azar, widget.origen)];
      _caida.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _caida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _PintorConfeti(_caida, _papeles),
        size: Size.infinite,
      ),
    ),
  );
}

class _PintorConfeti extends CustomPainter {
  _PintorConfeti(this.caida, this.papeles) : super(repaint: caida);

  final AnimationController caida;
  final List<_Papel> papeles;

  @override
  void paint(Canvas canvas, Size size) {
    if (!caida.isAnimating) return;
    final t = caida.value * 1.9;
    final apagado = ((caida.value - .7) / .3).clamp(0.0, 1.0);
    final pintura = Paint();
    for (final papel in papeles) {
      // Sale disparado, el aire lo frena y la gravedad lo baja.
      final frenado = (1 - math.exp(-2.2 * t)) / 2.2;
      final x =
          papel.origen.dx + math.cos(papel.angulo) * papel.rapidez * frenado;
      final y =
          papel.origen.dy +
          math.sin(papel.angulo) * papel.rapidez * frenado +
          420 * t * t;
      pintura.color = papel.color.withValues(alpha: 1 - apagado);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(papel.giro * t);
      if (papel.redondo) {
        canvas.drawCircle(Offset.zero, papel.alto * .7, pintura);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: papel.ancho,
            height: papel.alto * (.35 + .65 * math.cos(papel.giro * t).abs()),
          ),
          pintura,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorConfeti viejo) => viejo.papeles != papeles;
}
