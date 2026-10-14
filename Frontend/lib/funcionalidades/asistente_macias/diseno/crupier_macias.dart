import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cartas_blackjack.dart';

/// MacIAs de crupier: chaleco, camisa y moño, en su pixel art de siempre.
const rutaFotoCrupier = 'assets/images/marca/macias_crupier.jpg';

/// Las caras de MacIAs en la mesa, como los personajes de una novela
/// visual: cambian con lo que pasa y con lo que dice.
enum ExpresionCrupier {
  normal,
  feliz,
  risa,
  canchero,
  guino,
  sorprendido,
  triste,
  nervioso,
  enojado,
}

enum _Ojos { foto, felices, entrecerrados, guino, sorprendidos, tristes }

enum _Cejas { foto, relajadas, arriba, tristes, enojadas, una }

enum _Boca { foto, sonrisa, risa, o, triste, ondulada, canchera, abierta }

enum _Efecto { rubor, gota, brillos, vena, exclamacion, lagrima }

/// Una cara: como van los ojos, las cejas y la boca (quieta y hablando), y
/// los efectos de anime que la acompañan.
typedef _Cara = ({
  _Ojos ojos,
  _Cejas cejas,
  _Boca boca,
  _Boca hablando,
  Set<_Efecto> efectos,
});

const _caras = <ExpresionCrupier, _Cara>{
  ExpresionCrupier.normal: (
    ojos: _Ojos.foto,
    cejas: _Cejas.foto,
    boca: _Boca.foto,
    hablando: _Boca.abierta,
    efectos: <_Efecto>{},
  ),
  ExpresionCrupier.feliz: (
    ojos: _Ojos.felices,
    cejas: _Cejas.relajadas,
    boca: _Boca.sonrisa,
    hablando: _Boca.risa,
    efectos: {_Efecto.rubor},
  ),
  ExpresionCrupier.risa: (
    ojos: _Ojos.felices,
    cejas: _Cejas.relajadas,
    boca: _Boca.risa,
    hablando: _Boca.sonrisa,
    efectos: {_Efecto.rubor, _Efecto.brillos},
  ),
  ExpresionCrupier.canchero: (
    ojos: _Ojos.entrecerrados,
    cejas: _Cejas.una,
    boca: _Boca.canchera,
    hablando: _Boca.abierta,
    efectos: <_Efecto>{},
  ),
  ExpresionCrupier.guino: (
    ojos: _Ojos.guino,
    cejas: _Cejas.relajadas,
    boca: _Boca.sonrisa,
    hablando: _Boca.risa,
    efectos: {_Efecto.brillos},
  ),
  ExpresionCrupier.sorprendido: (
    ojos: _Ojos.sorprendidos,
    cejas: _Cejas.arriba,
    boca: _Boca.o,
    hablando: _Boca.abierta,
    efectos: {_Efecto.exclamacion},
  ),
  ExpresionCrupier.triste: (
    ojos: _Ojos.tristes,
    cejas: _Cejas.tristes,
    boca: _Boca.triste,
    hablando: _Boca.abierta,
    efectos: {_Efecto.lagrima},
  ),
  ExpresionCrupier.nervioso: (
    ojos: _Ojos.foto,
    cejas: _Cejas.tristes,
    boca: _Boca.ondulada,
    hablando: _Boca.abierta,
    efectos: {_Efecto.gota, _Efecto.rubor},
  ),
  ExpresionCrupier.enojado: (
    ojos: _Ojos.entrecerrados,
    cejas: _Cejas.enojadas,
    boca: _Boca.triste,
    hablando: _Boca.abierta,
    efectos: {_Efecto.vena},
  ),
};

/// Dibuja la cara de MacIAs sobre su foto.
///
/// Las medidas son las de la foto (512 x 512): los ojos en x = 186 y 322
/// (y = 210), las cejas en y = 158 a 176, la boca en (250, 317). Para cambiar
/// un gesto se tapa la parte de la foto con el color de la piel, con el
/// borde difuminado para que no se note el parche, y se dibuja encima el
/// gesto nuevo, en el mismo trazo oscuro del pixel art.
class PintorCaraCrupier extends CustomPainter {
  PintorCaraCrupier({
    required this.expresion,
    required this.parpadeo,
    required this.bocaAbierta,
    required this.efectos,
  }) : super(repaint: efectos);

  final ExpresionCrupier expresion;

  /// Los ojos cerrados un instante.
  final bool parpadeo;

  /// Mientras habla, la boca se abre y se cierra.
  final bool bocaAbierta;

  /// Va de 0 a 1 una y otra vez: para la gota, los brillos y la lagrima.
  final Animation<double> efectos;

  static const _piel = Color(0xFFE8966A);
  static const _pielBoca = Color(0xFFE38962);
  static const _pielCejas = Color(0xFFE48B64);
  static const _tinta = Color(0xFF1A0F0A);
  static const _labio = Color(0xFFB95640);
  static const _labioOscuro = Color(0xFF8C3324);
  static const _adentro = Color(0xFF4A1712);
  static const _ojos = [Offset(186, 210), Offset(322, 210)];

  static Paint _trazo(double ancho, [Color color = _tinta]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = ancho
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    final cara = _caras[expresion]!;
    final t = efectos.value;
    canvas
      ..save()
      ..scale(size.width / 512, size.height / 512);
    if (cara.efectos.contains(_Efecto.rubor)) _rubor(canvas);
    _pintarCejas(canvas, cara.cejas);
    final ojos = parpadeo && cara.ojos != _Ojos.felices ? null : cara.ojos;
    _pintarOjos(canvas, ojos);
    _pintarBoca(canvas, bocaAbierta ? cara.hablando : cara.boca);
    if (cara.efectos.contains(_Efecto.lagrima)) _lagrima(canvas, t);
    if (cara.efectos.contains(_Efecto.gota)) _gota(canvas, t);
    if (cara.efectos.contains(_Efecto.vena)) _vena(canvas, t);
    if (cara.efectos.contains(_Efecto.exclamacion)) _exclamacion(canvas, t);
    if (cara.efectos.contains(_Efecto.brillos)) _brillos(canvas, t);
    canvas.restore();
  }

  /// Tapa una parte de la foto con piel: firme al centro, difuminada al
  /// borde.
  static void _tapar(Canvas canvas, Rect zona, Color piel) {
    final forma = RRect.fromRectAndRadius(
      zona,
      Radius.circular(zona.shortestSide * .45),
    );
    canvas
      ..drawRRect(
        forma.inflate(3),
        Paint()
          ..color = piel
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawRRect(forma, Paint()..color = piel);
  }

  // ------------------------------------------------------------------ ojos
  void _pintarOjos(Canvas canvas, _Ojos? ojos) {
    switch (ojos) {
      case null:
        for (final ojo in _ojos) {
          _cerrado(canvas, ojo);
        }
      case _Ojos.foto:
        break;
      case _Ojos.felices:
        for (final ojo in _ojos) {
          _feliz(canvas, ojo);
        }
      case _Ojos.guino:
        _feliz(canvas, _ojos[0]);
      case _Ojos.entrecerrados:
        for (final ojo in _ojos) {
          _entrecerrado(canvas, ojo);
        }
      case _Ojos.sorprendidos:
        for (final ojo in _ojos) {
          _sorprendido(canvas, ojo);
        }
      case _Ojos.tristes:
        _triste(canvas, _ojos[0], -1);
        _triste(canvas, _ojos[1], 1);
    }
  }

  static Rect _cajaOjo(Offset ojo) =>
      Rect.fromCenter(center: ojo, width: 76, height: 70);

  /// El parpadeo: el ojo cerrado, una linea apenas curvada.
  static void _cerrado(Canvas canvas, Offset o) {
    _tapar(canvas, _cajaOjo(o), _piel);
    canvas.drawPath(
      Path()
        ..moveTo(o.dx - 30, o.dy + 3)
        ..quadraticBezierTo(o.dx, o.dy + 13, o.dx + 30, o.dy + 3),
      _trazo(6),
    );
  }

  /// "^ ^": los ojos que se cierran de contento.
  static void _feliz(Canvas canvas, Offset o) {
    _tapar(canvas, _cajaOjo(o), _piel);
    canvas.drawPath(
      Path()
        ..moveTo(o.dx - 28, o.dy + 12)
        ..quadraticBezierTo(o.dx, o.dy - 20, o.dx + 28, o.dy + 12),
      _trazo(7.5),
    );
  }

  /// El parpado a media asta: mirada de "ya sé lo que va a pasar".
  static void _entrecerrado(Canvas canvas, Offset o) {
    final parpado = Rect.fromLTRB(o.dx - 39, o.dy - 40, o.dx + 39, o.dy - 1);
    canvas
      ..drawRect(
        parpado.inflate(2),
        Paint()
          ..color = _piel
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRect(parpado, Paint()..color = _piel)
      ..drawPath(
        Path()
          ..moveTo(o.dx - 32, o.dy + 1)
          ..quadraticBezierTo(o.dx, o.dy - 7, o.dx + 32, o.dy + 1),
        _trazo(6.5),
      );
  }

  /// "O_O": ojos bien abiertos con la pupila chiquita.
  static void _sorprendido(Canvas canvas, Offset o) {
    _tapar(canvas, _cajaOjo(o), _piel);
    final blanco = Rect.fromCenter(
      center: o.translate(0, 2),
      width: 58,
      height: 64,
    );
    canvas
      ..drawOval(blanco, Paint()..color = const Color(0xFFF8F2EA))
      ..drawOval(blanco, _trazo(5))
      ..drawCircle(
        o.translate(0, 5),
        8.5,
        Paint()..color = const Color(0xFF2A160C),
      )
      ..drawCircle(o.translate(-3, 2), 2.8, Paint()..color = Colors.white);
  }

  /// El parpado caido hacia afuera. [lado] es -1 para el ojo de la
  /// izquierda (su lado de afuera queda a la izquierda) y 1 para el otro.
  static void _triste(Canvas canvas, Offset o, double lado) {
    final cuna = Path()
      ..moveTo(o.dx + lado * 42, o.dy - 42)
      ..lineTo(o.dx - lado * 14, o.dy - 42)
      ..lineTo(o.dx + lado * 42, o.dy + 6)
      ..close();
    canvas
      ..drawPath(
        cuna,
        Paint()
          ..color = _piel
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      )
      ..drawPath(cuna, Paint()..color = _piel)
      ..drawLine(
        Offset(o.dx - lado * 12, o.dy - 34),
        Offset(o.dx + lado * 34, o.dy + 2),
        _trazo(6),
      );
  }

  // ---------------------------------------------------------------- cejas
  void _pintarCejas(Canvas canvas, _Cejas cejas) {
    if (cejas == _Cejas.foto) return;
    _tapar(canvas, const Rect.fromLTRB(154, 144, 240, 178), _pielCejas);
    _tapar(canvas, const Rect.fromLTRB(272, 144, 358, 178), _pielCejas);
    // Cada ceja: desde afuera, el punto de control y hasta adentro.
    final (izquierda, derecha) = switch (cejas) {
      _Cejas.relajadas => (
        (
          const Offset(166, 166),
          const Offset(196, 154),
          const Offset(228, 164),
        ),
        (
          const Offset(346, 166),
          const Offset(316, 154),
          const Offset(284, 164),
        ),
      ),
      _Cejas.arriba => (
        (
          const Offset(166, 154),
          const Offset(196, 138),
          const Offset(228, 152),
        ),
        (
          const Offset(346, 154),
          const Offset(316, 138),
          const Offset(284, 152),
        ),
      ),
      _Cejas.tristes => (
        (
          const Offset(166, 172),
          const Offset(198, 168),
          const Offset(228, 152),
        ),
        (
          const Offset(346, 172),
          const Offset(314, 168),
          const Offset(284, 152),
        ),
      ),
      _Cejas.enojadas => (
        (
          const Offset(166, 152),
          const Offset(200, 158),
          const Offset(231, 176),
        ),
        (
          const Offset(346, 152),
          const Offset(312, 158),
          const Offset(281, 176),
        ),
      ),
      _Cejas.una || _Cejas.foto => (
        (
          const Offset(166, 154),
          const Offset(196, 136),
          const Offset(228, 152),
        ),
        (
          const Offset(346, 168),
          const Offset(316, 164),
          const Offset(284, 171),
        ),
      ),
    };
    for (final (desde, control, hasta) in [izquierda, derecha]) {
      canvas.drawPath(
        Path()
          ..moveTo(desde.dx, desde.dy)
          ..quadraticBezierTo(control.dx, control.dy, hasta.dx, hasta.dy),
        _trazo(10),
      );
    }
  }

  // ----------------------------------------------------------------- boca
  void _pintarBoca(Canvas canvas, _Boca boca) {
    if (boca == _Boca.foto) return;
    _tapar(canvas, const Rect.fromLTRB(198, 300, 302, 338), _pielBoca);
    switch (boca) {
      case _Boca.foto:
        break;
      case _Boca.sonrisa:
        canvas
          ..drawPath(
            Path()
              ..moveTo(212, 312)
              ..quadraticBezierTo(250, 338, 288, 312)
              ..quadraticBezierTo(250, 327, 212, 312)
              ..close(),
            Paint()..color = _labio,
          )
          ..drawPath(
            Path()
              ..moveTo(212, 312)
              ..quadraticBezierTo(250, 336, 288, 312),
            _trazo(5, _labioOscuro),
          );
      case _Boca.risa:
        final forma = Path()
          ..moveTo(210, 308)
          ..lineTo(290, 308)
          ..quadraticBezierTo(288, 344, 250, 348)
          ..quadraticBezierTo(212, 344, 210, 308)
          ..close();
        _bocaAbierta(
          canvas,
          forma,
          dientes: const Rect.fromLTRB(208, 306, 292, 317),
          lengua: const Rect.fromLTRB(230, 334, 270, 350),
        );
      case _Boca.abierta:
        _bocaAbierta(
          canvas,
          Path()..addOval(
            Rect.fromCenter(
              center: const Offset(250, 318),
              width: 46,
              height: 20,
            ),
          ),
          dientes: const Rect.fromLTRB(226, 307, 274, 313),
          lengua: const Rect.fromLTRB(238, 322, 262, 330),
        );
      case _Boca.o:
        _bocaAbierta(
          canvas,
          Path()..addOval(
            Rect.fromCenter(
              center: const Offset(250, 321),
              width: 28,
              height: 32,
            ),
          ),
          lengua: const Rect.fromLTRB(240, 328, 260, 338),
        );
      case _Boca.triste:
        canvas.drawPath(
          Path()
            ..moveTo(216, 328)
            ..quadraticBezierTo(250, 306, 284, 328),
          _trazo(6, _labioOscuro),
        );
      case _Boca.ondulada:
        canvas.drawPath(
          Path()
            ..moveTo(212, 318)
            ..quadraticBezierTo(221, 309, 230, 318)
            ..quadraticBezierTo(239, 327, 248, 318)
            ..quadraticBezierTo(257, 309, 266, 318)
            ..quadraticBezierTo(275, 327, 286, 316),
          _trazo(5.5, _labioOscuro),
        );
      case _Boca.canchera:
        canvas.drawPath(
          Path()
            ..moveTo(214, 320)
            ..quadraticBezierTo(244, 328, 268, 318)
            ..quadraticBezierTo(282, 312, 290, 302),
          _trazo(6, _labioOscuro),
        );
    }
  }

  static void _bocaAbierta(
    Canvas canvas,
    Path forma, {
    Rect? dientes,
    Rect? lengua,
  }) {
    canvas
      ..drawPath(forma, Paint()..color = _adentro)
      ..save()
      ..clipPath(forma);
    if (dientes != null) {
      canvas.drawRect(dientes, Paint()..color = const Color(0xFFFFF8EE));
    }
    if (lengua != null) {
      canvas.drawOval(lengua, Paint()..color = const Color(0xFFE5737A));
    }
    canvas
      ..restore()
      ..drawPath(forma, _trazo(4, _labioOscuro));
  }

  // --------------------------------------------------------------- efectos
  /// "///": el sonrojo de anime en las mejillas.
  static void _rubor(Canvas canvas) {
    for (final mejilla in const [Offset(172, 266), Offset(334, 266)]) {
      canvas.drawOval(
        Rect.fromCenter(center: mejilla, width: 56, height: 22),
        Paint()
          ..color = const Color(0x66FF5C7A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          mejilla.translate(-15 + i * 12, 7),
          mejilla.translate(-9 + i * 12, -7),
          _trazo(3, const Color(0xCCFF8FA3)),
        );
      }
    }
  }

  /// Una gota con la punta para arriba, centrada en el origen.
  static Path _forma(double ancho, double alto) => Path()
    ..moveTo(0, -alto / 2)
    ..quadraticBezierTo(ancho * .55, alto * .05, ancho * .45, alto * .25)
    ..arcToPoint(
      Offset(-ancho * .45, alto * .25),
      radius: Radius.circular(ancho * .46),
    )
    ..quadraticBezierTo(-ancho * .55, alto * .05, 0, -alto / 2)
    ..close();

  static void _gotaEn(
    Canvas canvas,
    Offset centro,
    double ancho,
    double alto,
    double opacidad,
  ) {
    final forma = _forma(ancho, alto);
    canvas
      ..save()
      ..translate(centro.dx, centro.dy)
      ..drawPath(
        forma,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFD6F1FF).withValues(alpha: opacidad),
                  const Color(0xFF6EC1FF).withValues(alpha: opacidad),
                ],
              ).createShader(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: ancho,
                  height: alto,
                ),
              ),
      )
      ..drawPath(
        forma,
        _trazo(3, const Color(0xFF2E6FA8).withValues(alpha: opacidad)),
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(-ancho * .14, alto * .08),
          width: ancho * .18,
          height: alto * .2,
        ),
        Paint()..color = Colors.white.withValues(alpha: .85 * opacidad),
      )
      ..restore();
  }

  /// La gota de sudor de los nervios, que se resbala un poquito.
  static void _gota(Canvas canvas, double t) =>
      _gotaEn(canvas, Offset(396, 152 + 7 * math.sin(t * math.pi)), 32, 46, 1);

  /// Una lagrimita que cae por la mejilla.
  static void _lagrima(Canvas canvas, double t) => _gotaEn(
    canvas,
    Offset(204 + 3 * t, 246 + 26 * t),
    15,
    22,
    t < .75 ? 1 : (1 - t) / .25,
  );

  /// La venita de enojo de los animes, latiendo.
  static void _vena(Canvas canvas, double t) {
    final latido = 1 + .1 * math.sin(t * math.pi * 4);
    canvas
      ..save()
      ..translate(362, 104)
      ..scale(latido);
    for (var cuarto = 0; cuarto < 4; cuarto++) {
      canvas
        ..save()
        ..rotate(cuarto * math.pi / 2)
        ..drawPath(
          Path()
            ..moveTo(6, -20)
            ..quadraticBezierTo(6, -6, 20, -6),
          _trazo(7, const Color(0xFFE53935)),
        )
        ..restore();
    }
    canvas.restore();
  }

  /// "!": de golpe, con un saltito.
  static void _exclamacion(Canvas canvas, double t) {
    final salto = -5 * math.sin(t * math.pi * 2).abs();
    final relleno = Paint()..color = const Color(0xFFFFD54F);
    final borde = _trazo(4, const Color(0xFF3A2A00));
    final barra = RRect.fromRectAndRadius(
      Rect.fromLTRB(432, 38 + salto, 450, 98 + salto),
      const Radius.circular(9),
    );
    final punto = Offset(441, 117 + salto);
    canvas
      ..drawRRect(barra, relleno)
      ..drawRRect(barra, borde)
      ..drawCircle(punto, 9.5, relleno)
      ..drawCircle(punto, 9.5, borde);
  }

  /// Brillitos que titilan alrededor de la cara.
  static void _brillos(Canvas canvas, double t) {
    for (final (centro, radio, desfase) in const [
      (Offset(74, 118), 30.0, 0.0),
      (Offset(446, 96), 24.0, .33),
      (Offset(454, 236), 19.0, .66),
    ]) {
      final escala = .5 + .5 * math.sin((t + desfase) * math.pi * 2).abs();
      final r = radio * escala;
      final estrella = Path()
        ..moveTo(0, -r)
        ..lineTo(r * .26, -r * .26)
        ..lineTo(r, 0)
        ..lineTo(r * .26, r * .26)
        ..lineTo(0, r)
        ..lineTo(-r * .26, r * .26)
        ..lineTo(-r, 0)
        ..lineTo(-r * .26, -r * .26)
        ..close();
      canvas
        ..save()
        ..translate(centro.dx, centro.dy)
        ..drawPath(estrella, Paint()..color = const Color(0xFFFFC94A))
        ..scale(.5)
        ..drawPath(estrella, Paint()..color = Colors.white)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(PintorCaraCrupier viejo) =>
      viejo.expresion != expresion ||
      viejo.parpadeo != parpadeo ||
      viejo.bocaAbierta != bocaAbierta;
}

/// Como se mueve MacIAs con cada cara.
enum _Salto { habla, festeja, lamenta, sorpresa }

/// MacIAs, el crupier: su retrato con marco dorado, que parpadea, habla y
/// cambia de cara.
///
/// Cuando cambia [latido] da un saltito (o niega con la cabeza, o se asusta,
/// segun la cara). Mientras [hablando], la boca se mueve.
class CrupierMacias extends StatefulWidget {
  const CrupierMacias({
    required this.tamano,
    this.expresion = ExpresionCrupier.normal,
    this.hablando = false,
    this.latido = 0,
    super.key,
  });

  final double tamano;
  final ExpresionCrupier expresion;
  final bool hablando;
  final int latido;

  @override
  State<CrupierMacias> createState() => _CrupierMaciasState();
}

class _CrupierMaciasState extends State<CrupierMacias>
    with TickerProviderStateMixin {
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final AnimationController _efectos = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final _azar = math.Random();
  Timer? _proximoParpadeo;
  Timer? _abrirOjos;
  Timer? _boca;
  bool _parpadeo = false;
  bool _bocaAbierta = false;

  @override
  void initState() {
    super.initState();
    _programarParpadeo();
    _animarEfectos();
    if (widget.hablando) _hablar();
  }

  @override
  void didUpdateWidget(CrupierMacias viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.latido != widget.latido) _salto.forward(from: 0);
    if (viejo.expresion != widget.expresion) _animarEfectos();
    if (viejo.hablando != widget.hablando) {
      if (widget.hablando) {
        _hablar();
      } else {
        _boca?.cancel();
        _bocaAbierta = false;
      }
    }
  }

  @override
  void dispose() {
    _proximoParpadeo?.cancel();
    _abrirOjos?.cancel();
    _boca?.cancel();
    _salto.dispose();
    _efectos.dispose();
    super.dispose();
  }

  /// Parpadea cada dos a cinco segundos, y a veces dos veces seguidas, como
  /// una persona.
  void _programarParpadeo() {
    _proximoParpadeo = Timer(
      Duration(milliseconds: 2200 + _azar.nextInt(2800)),
      () {
        if (!mounted) return;
        _parpadear(doble: _azar.nextDouble() < .2);
        _programarParpadeo();
      },
    );
  }

  void _parpadear({bool doble = false}) {
    setState(() => _parpadeo = true);
    _abrirOjos = Timer(const Duration(milliseconds: 110), () {
      if (!mounted) return;
      setState(() => _parpadeo = false);
      if (doble) {
        _abrirOjos = Timer(const Duration(milliseconds: 160), () {
          if (mounted) _parpadear();
        });
      }
    });
  }

  /// La boca se abre y se cierra a ritmo de habla, con alguna pausa.
  void _hablar() {
    _boca?.cancel();
    _boca = Timer.periodic(const Duration(milliseconds: 95), (_) {
      if (!mounted) return;
      setState(
        () => _bocaAbierta = _bocaAbierta
            ? _azar.nextDouble() < .2
            : _azar.nextDouble() < .8,
      );
    });
  }

  /// Los efectos que se mueven (la gota, los brillos) solo corren mientras
  /// se ven.
  void _animarEfectos() {
    final efectos = _caras[widget.expresion]!.efectos;
    final seMueven = efectos.any((e) => e != _Efecto.rubor);
    if (seMueven) {
      if (!_efectos.isAnimating) _efectos.repeat();
    } else {
      _efectos
        ..stop()
        ..value = 0;
    }
  }

  _Salto get _comoSalta => switch (widget.expresion) {
    ExpresionCrupier.feliz ||
    ExpresionCrupier.risa ||
    ExpresionCrupier.guino => _Salto.festeja,
    ExpresionCrupier.triste ||
    ExpresionCrupier.nervioso ||
    ExpresionCrupier.enojado => _Salto.lamenta,
    ExpresionCrupier.sorprendido => _Salto.sorpresa,
    _ => _Salto.habla,
  };

  @override
  Widget build(BuildContext context) {
    final tamano = widget.tamano;
    final radio = BorderRadius.circular(tamano * .2);
    final retrato = Container(
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * .035),
      decoration: BoxDecoration(
        borderRadius: radio,
        gradient: const SweepGradient(
          colors: [
            ColoresCarta.oroClaro,
            ColoresCarta.oro,
            Color(0xFF8A6414),
            ColoresCarta.oro,
            ColoresCarta.oroClaro,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tamano * .17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            // La misma imagen que precarga la mesa, para que este lista
            // desde el primer cuadro.
            Image(
              image: const AssetImage(rutaFotoCrupier),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              // La cara se dibuja encima de la foto: sin la foto todavia
              // (en la web puede tardar un instante), los ojos quedarian
              // flotando sobre el blanco. Llegan juntas.
              frameBuilder: (context, foto, cuadro, alInstante) {
                final lista = alInstante || cuadro != null;
                final cara = Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(child: foto),
                    if (lista)
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: PintorCaraCrupier(
                            expresion: widget.expresion,
                            parpadeo: _parpadeo,
                            bocaAbierta: widget.hablando && _bocaAbierta,
                            efectos: _efectos,
                          ),
                        ),
                      ),
                  ],
                );
                if (alInstante) return cara;
                return AnimatedOpacity(
                  opacity: lista ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  child: cara,
                );
              },
            ),
          ],
        ),
      ),
    );
    return Semantics(
      image: true,
      label: 'MacIAs, el crupier',
      child: AnimatedBuilder(
        animation: _salto,
        child: retrato,
        builder: (context, hijo) {
          final t = _salto.value;
          final onda = math.sin(t * math.pi);
          final (dy, giro, crece) = switch (_comoSalta) {
            _Salto.habla => (-4 * onda, 0.0, .025 * onda),
            _Salto.festeja => (
              -13 * onda * (1 - t * .3),
              .06 * math.sin(t * math.pi * 3) * (1 - t),
              .07 * onda,
            ),
            _Salto.lamenta => (
              2 * onda,
              .08 * math.sin(t * math.pi * 4) * (1 - t),
              -.03 * onda,
            ),
            _Salto.sorpresa => (
              -16 * math.sin(math.min(1, t * 2) * math.pi),
              0.0,
              .1 * math.sin(math.min(1, t * 1.6) * math.pi),
            ),
          };
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.translationValues(0, dy, 0)
              ..rotateZ(giro)
              ..scaleByDouble(1 + crece, 1 + crece, 1, 1),
            child: hijo,
          );
        },
      ),
    );
  }
}

/// El cartelito con el nombre, debajo del retrato.
class PlacaCrupier extends StatelessWidget {
  const PlacaCrupier({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xE6141210),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ColoresCarta.oro.withValues(alpha: .8)),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Text(
        'CRUPIER',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: 9.5,
          letterSpacing: 1.6,
          height: 1.2,
          color: ColoresCarta.oroClaro,
        ),
      ),
    ),
  );
}

/// Lo que dice MacIAs, como en una novela visual: una caja con su nombre
/// arriba, y el texto que aparece letra por letra.
///
/// Tocarla completa el texto de una. Avisa con [alHablar] cuando empieza y
/// cuando termina de "decirlo" (para mover la boca), y con [alSonar] cada
/// tantas letras (para la vocecita).
class DialogoCrupier extends StatefulWidget {
  const DialogoCrupier({
    required this.texto,
    this.msPorLetra = 28,
    this.alHablar,
    this.alSonar,
    super.key,
  });

  final String texto;
  final int msPorLetra;
  final ValueChanged<bool>? alHablar;
  final VoidCallback? alSonar;

  @override
  State<DialogoCrupier> createState() => _DialogoCrupierState();
}

class _DialogoCrupierState extends State<DialogoCrupier>
    with TickerProviderStateMixin {
  late final AnimationController _escritura = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: math.max(1, widget.texto.length * widget.msPorLetra),
    ),
  );
  late final AnimationController _cursor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  int _letras = 0;

  @override
  void initState() {
    super.initState();
    _escritura
      ..addListener(_avanzar)
      ..addStatusListener((estado) {
        if (estado != AnimationStatus.completed) return;
        widget.alHablar?.call(false);
        _cursor.repeat(reverse: true);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.alHablar?.call(true);
      _escritura.forward();
    });
  }

  void _avanzar() {
    final total = widget.texto.length;
    final letras = (_escritura.value * total).round().clamp(0, total);
    if (letras == _letras) return;
    var suena = false;
    for (var i = _letras; i < letras; i++) {
      if (i % 3 == 0 && widget.texto[i].trim().isNotEmpty) suena = true;
    }
    if (suena) widget.alSonar?.call();
    setState(() => _letras = letras);
  }

  void _completar() {
    if (_escritura.isAnimating) _escritura.value = 1;
  }

  @override
  void dispose() {
    _escritura.dispose();
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w800,
      fontSize: 13.5,
      height: 1.32,
      color: Color(0xFFF7EEDC),
    );
    final terminado = _letras >= widget.texto.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _completar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 11),
            padding: const EdgeInsets.fromLTRB(13, 15, 10, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF2271D18), Color(0xF2140F0C)],
              ),
              border: Border.all(
                color: ColoresCarta.oro.withValues(alpha: .85),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lo que falta escribir ya ocupa su lugar (transparente): la
                // caja no crece ni salta mientras aparecen las letras.
                Text.rich(
                  TextSpan(
                    style: estilo,
                    children: [
                      TextSpan(text: widget.texto.substring(0, _letras)),
                      TextSpan(
                        text: widget.texto.substring(_letras),
                        style: const TextStyle(color: Colors.transparent),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FadeTransition(
                    opacity: terminado ? _cursor : kAlwaysDismissedAnimation,
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: ColoresCarta.oroClaro,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ColoresCarta.oroClaro, ColoresCarta.oro],
                ),
                border: Border.all(color: const Color(0xFF5A3D08)),
              ),
              child: const Text(
                'MacIAs',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  height: 1.25,
                  color: Color(0xFF2B1E05),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
