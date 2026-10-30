import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logica/mesa_pesca.dart';
import 'dibujos_pesca.dart';

/// Lo que se mueve en la rueda ademas del giro: la aguja que golpea, la
/// casilla que salio (con su cubo de hielo o su brillo) y la moneda de oro
/// del centro. Cambia todo el tiempo mientras gira: la rueda solo se
/// repinta, no se reconstruye.
class EfectosRueda extends ChangeNotifier {
  /// Cuanto se dobla la aguja (0 quieta, 1 lo mas que se dobla).
  double _aguja = 0;
  double get aguja => _aguja;
  set aguja(double valor) {
    if (valor == _aguja) return;
    _aguja = valor;
    notifyListeners();
  }

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
}

/// Las medidas de la rueda, en fracciones del radio.
abstract final class MedidasRueda {
  static const centro = .2;
  static const anillo = .86;
  static const borde = .95;
  static const iconos = .79;
  static const etiquetas = .64;

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
/// marco y el centro de hielo.
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
  /// La rueda dibujada una vez: girarla no la vuelve a pintar.
  ui.Picture? _disco;
  ui.Picture? _marco;
  double _radioGrabado = 0;
  Multiplicadores? _multiplicadoresGrabados;

  @override
  void dispose() {
    _disco?.dispose();
    _marco?.dispose();
    super.dispose();
  }

  void _grabar(double radio) {
    if (radio == _radioGrabado &&
        identical(_multiplicadoresGrabados, widget.multiplicadores)) {
      return;
    }
    if (radio != _radioGrabado) {
      _marco?.dispose();
      _marco = _grabarMarco(radio);
    }
    _disco?.dispose();
    _disco = _grabarDisco(radio, widget.multiplicadores);
    _radioGrabado = radio;
    _multiplicadoresGrabados = widget.multiplicadores;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, caja) {
      final lado = caja.biggest.shortestSide;
      _grabar(lado / 2);
      return RepaintBoundary(
        child: CustomPaint(
          size: Size.square(lado),
          painter: _PintorRueda(
            giro: widget.giro,
            efectos: widget.efectos,
            disco: _disco!,
            marco: _marco!,
          ),
        ),
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
  final ui.Picture disco;
  final ui.Picture marco;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centro = Offset(r, r);
    final angulo = giro.value;

    canvas
      ..save()
      ..translate(r, r)
      ..drawPicture(marco)
      ..rotate(angulo)
      ..drawPicture(disco)
      ..restore();

    final ganadora = efectos.ganadora;
    if (ganadora != null && efectos.efecto > 0) {
      _pintarGanadora(canvas, centro, r, ganadora, angulo, efectos.efecto);
    }
    _pintarCentro(canvas, centro, r);
    _pintarAguja(canvas, centro, r, ganadora);
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
      // El hielo se congela: un cubo crece sobre la casilla, con su copo.
      final escala = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
      final donde = centro + Offset(math.cos(phi), math.sin(phi)) * r * .76;
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
    // Un pez: la casilla brilla con su color y late.
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
          ..color = claro.withValues(alpha: .55 * t)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
      )
      ..drawPath(
        cuna,
        Paint()..color = Colors.white.withValues(alpha: .28 * t),
      );
  }

  void _pintarCentro(Canvas canvas, Offset centro, double r) {
    final radio = r * MedidasRueda.centro;
    final moneda = efectos.moneda;
    if (moneda < 1) {
      // El hielo del centro, con su nombre.
      canvas
        ..drawCircle(
          centro,
          radio,
          Paint()
            ..shader = const RadialGradient(
              colors: [ColoresPesca.metal, ColoresPesca.metalOscuro],
              stops: [.75, 1],
            ).createShader(Rect.fromCircle(center: centro, radius: radio)),
        )
        ..drawCircle(
          centro,
          radio * .88,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.3, -.35),
              colors: [Colors.white, Color(0xFFDDEBF3), Color(0xFFA8C6D7)],
              stops: [0, .55, 1],
            ).createShader(Rect.fromCircle(center: centro, radius: radio)),
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
            color: const Color(0xFF5F8BA4),
            shadows: const [
              Shadow(color: Colors.white, offset: Offset(0, 1.2)),
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
      // La moneda: gira de canto y muestra lo que multiplica.
      final ancho = math.cos(efectos.monedaGiro).abs().clamp(.08, 1.0);
      final escala = .7 + .3 * Curves.easeOutBack.transform(moneda);
      canvas
        ..save()
        ..translate(centro.dx, centro.dy)
        ..scale(ancho * escala, escala);
      final rect = Rect.fromCircle(center: Offset.zero, radius: radio * 1.05);
      canvas
        ..drawCircle(
          Offset.zero,
          radio * 1.2,
          Paint()
            ..color = ColoresPesca.oro.withValues(alpha: .45 * moneda)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radio * .3),
        )
        ..drawCircle(
          Offset.zero,
          radio * 1.05,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.3, -.4),
              colors: [
                ColoresPesca.oroClaro.withValues(alpha: moneda),
                ColoresPesca.oro.withValues(alpha: moneda),
                ColoresPesca.oroOscuro.withValues(alpha: moneda),
              ],
              stops: const [0, .55, 1],
            ).createShader(rect),
        )
        ..drawCircle(
          Offset.zero,
          radio * .86,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radio * .06
            ..color = ColoresPesca.oroOscuro.withValues(alpha: .6 * moneda),
        );
      final texto = efectos.monedaTexto;
      if (texto != null) {
        final letra = TextPainter(
          text: TextSpan(
            text: texto,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: radio * .62,
              height: 1,
              color: const Color(0xFF6B4A05).withValues(alpha: moneda),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        letra.paint(canvas, Offset(-letra.width / 2, -letra.height / 2));
      }
      canvas.restore();
    }
  }

  void _pintarAguja(Canvas canvas, Offset centro, double r, int? ganadora) {
    final tipo = ganadora == null ? null : RuedaPesca.casillas[ganadora];
    final brillo = tipo?.pez == null ? 0.0 : efectos.efecto;
    final pivote = centro + Offset(0, -r * .99);
    canvas
      ..save()
      ..translate(pivote.dx, pivote.dy)
      ..rotate(-efectos.aguja * .32);
    final aguja = Path()
      ..moveTo(-r * .075, -r * .02)
      ..lineTo(r * .075, -r * .02)
      ..lineTo(0, r * .17)
      ..close();
    if (brillo > 0) {
      final (claro, _) = ColoresPesca.deCasilla(tipo!);
      canvas.drawPath(
        aguja,
        Paint()
          ..color = claro.withValues(alpha: .9 * brillo)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .06),
      );
    }
    canvas
      ..drawPath(
        aguja.shift(Offset(0, r * .012)),
        Paint()..color = Colors.black.withValues(alpha: .35),
      )
      ..drawPath(
        aguja,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFE9EEF1),
              ColoresPesca.metal,
              ColoresPesca.metalOscuro,
            ],
          ).createShader(Rect.fromLTRB(-r * .075, 0, r * .075, r * .17)),
      )
      ..drawPath(
        aguja,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .008
          ..color = const Color(0xFF3A4750),
      )
      // La piedra roja de la punta, como la del video.
      ..drawCircle(
        Offset(0, r * .03),
        r * .022,
        Paint()..color = const Color(0xFFC81E2B),
      )
      ..drawCircle(
        Offset(-r * .006, r * .024),
        r * .007,
        Paint()..color = Colors.white.withValues(alpha: .8),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_PintorRueda viejo) =>
      viejo.disco != disco || viejo.marco != marco;
}

/// El marco que no gira: el anillo oscuro de afuera, con su escarcha.
ui.Picture _grabarMarco(double r) {
  final grabadora = ui.PictureRecorder();
  final canvas = Canvas(grabadora);
  final rect = Rect.fromCircle(center: Offset.zero, radius: r);
  canvas
    ..drawCircle(
      const Offset(0, 6),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
    )
    ..drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [ColoresPesca.marco, ColoresPesca.marcoOscuro],
          stops: [.9, 1],
        ).createShader(rect),
    );
  // Los dientes del marco, como los de un engranaje de hielo.
  final dientes = Paint()..color = const Color(0xFF2C5266);
  for (var i = 0; i < RuedaPesca.cantidad; i++) {
    final a = i * MedidasRueda.casilla - math.pi / 2 + MedidasRueda.casilla / 2;
    final d = Offset(math.cos(a), math.sin(a));
    canvas.drawCircle(d * r * .975, r * .018, dientes);
  }
  canvas.drawCircle(
    Offset.zero,
    r * .995,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .012
      ..color = Colors.white.withValues(alpha: .35),
  );
  return grabadora.endRecording();
}

/// El disco que gira: las 53 casillas, el anillo de metal con sus remaches,
/// los iconos, los nombres de los peces y lo que ya cayo encima.
ui.Picture _grabarDisco(double r, Multiplicadores multiplicadores) {
  final grabadora = ui.PictureRecorder();
  final canvas = Canvas(grabadora);
  final a = MedidasRueda.casilla;
  final adentro = r * MedidasRueda.centro;
  final afuera = r * MedidasRueda.anillo;

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
  }

  // Las lineas entre casillas.
  final linea = Paint()
    ..strokeWidth = math.max(.6, r * .006)
    ..color = Colors.white.withValues(alpha: .55);
  for (var i = 0; i < RuedaPesca.cantidad; i++) {
    final b = -math.pi / 2 + i * a - a / 2;
    final d = Offset(math.cos(b), math.sin(b));
    canvas.drawLine(d * adentro, d * afuera, linea);
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
            shadows: const [Shadow(color: Color(0x80000000), blurRadius: 2)],
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
