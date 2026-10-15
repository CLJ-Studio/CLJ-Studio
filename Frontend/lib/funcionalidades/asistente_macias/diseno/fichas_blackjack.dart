import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../logica/mesa_blackjack.dart';

/// La ficha del "all in": no vale una cantidad, es la que pone todas tus
/// fichas de una en el lugar que toques.
const valorTodo = -1;

/// Los colores de cada ficha: el fondo, las franjas del borde y el numero.
({Color base, Color franja, Color numero}) coloresFicha(int valor) =>
    switch (valor) {
      valorTodo => (
        // Marfil con franjas rojas: no se confunde con ninguna otra.
        base: const Color(0xFFF1ECE0),
        franja: const Color(0xFFB3202A),
        numero: const Color(0xFFB3202A),
      ),
      10 => (
        base: const Color(0xFF1F57B0),
        franja: Colors.white,
        numero: Colors.white,
      ),
      50 => (
        base: const Color(0xFFC0262D),
        franja: Colors.white,
        numero: Colors.white,
      ),
      100 => (
        base: const Color(0xFF1E1D21),
        franja: const Color(0xFFE2B33C),
        numero: const Color(0xFFF2CC5C),
      ),
      500 => (
        // El morado de las promociones de la app.
        base: ConfiguracionTema.moradoPromocional,
        franja: Colors.white,
        numero: Colors.white,
      ),
      _ => (
        base: const Color(0xFFE7A41A),
        franja: const Color(0xFF3B2A06),
        numero: const Color(0xFF3B2A06),
      ),
    };

String textoFicha(int valor) => valor >= 1000 ? '${valor ~/ 1000}K' : '$valor';

/// "1.250": con punto de miles, como se escribe en Bolivia.
String conMiles(int numero) {
  final signo = numero < 0 ? '-' : '';
  final digitos = numero.abs().toString();
  final partes = <String>[];
  for (var fin = digitos.length; fin > 0; fin -= 3) {
    partes.insert(0, digitos.substring(math.max(0, fin - 3), fin));
  }
  return '$signo${partes.join('.')}';
}

/// Una ficha vista de arriba.
void pintarFicha(
  Canvas canvas,
  Offset centro,
  double radio,
  int valor, {
  bool sombra = true,
  bool numero = true,
}) {
  final colores = coloresFicha(valor);
  if (sombra) {
    canvas.drawCircle(
      centro + Offset(0, radio * .1),
      radio,
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radio * .12),
    );
  }
  final circulo = Rect.fromCircle(center: centro, radius: radio);
  canvas.drawCircle(
    centro,
    radio,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.4),
        radius: 1.1,
        colors: [
          Color.lerp(colores.base, Colors.white, .22)!,
          colores.base,
          Color.lerp(colores.base, Colors.black, .35)!,
        ],
        stops: const [0, .55, 1],
      ).createShader(circulo),
  );
  // Las franjas del canto.
  final franja = Paint()..color = colores.franja;
  for (var k = 0; k < 8; k++) {
    canvas
      ..save()
      ..translate(centro.dx, centro.dy)
      ..rotate(k * math.pi / 4 + math.pi / 8)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -radio * .84),
            width: radio * .27,
            height: radio * .23,
          ),
          Radius.circular(radio * .05),
        ),
        franja,
      )
      ..restore();
  }
  // El anillo punteado de adentro.
  final anillo = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = radio * .055
    ..color = colores.franja.withValues(alpha: .8);
  final interior = Rect.fromCircle(center: centro, radius: radio * .66);
  for (var k = 0; k < 16; k++) {
    canvas.drawArc(interior, k * math.pi / 8, math.pi / 14, false, anillo);
  }
  canvas.drawCircle(
    centro,
    radio * .54,
    Paint()..color = Color.lerp(colores.base, Colors.black, .12)!,
  );
  if (!numero) return;
  final todo = valor == valorTodo;
  final texto = todo ? 'ALL\nIN' : textoFicha(valor);
  final pintor = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w900,
        fontSize: todo ? radio * .36 : radio * (texto.length <= 2 ? .56 : .44),
        height: todo ? .95 : 1,
        color: colores.numero,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  pintor.paint(canvas, centro - Offset(pintor.width / 2, pintor.height / 2));
}

/// Las fichas que forman un monto, de la mas grande a la mas chica.
List<int> fichasDe(int monto, {int maximo = 12}) {
  final fichas = <int>[];
  var resto = monto;
  for (final valor in MesaBlackjack.valoresFichas.reversed) {
    while (resto >= valor && fichas.length < maximo) {
      fichas.add(valor);
      resto -= valor;
    }
  }
  return fichas;
}

/// Una ficha suelta.
class FichaDibujada extends StatelessWidget {
  const FichaDibujada({required this.valor, required this.diametro, super.key});

  final int valor;
  final double diametro;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(diametro),
      painter: _PintorFicha(valor),
    ),
  );
}

class _PintorFicha extends CustomPainter {
  const _PintorFicha(this.valor);

  final int valor;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarFicha(canvas, size.center(Offset.zero), size.width / 2, valor);

  @override
  bool shouldRepaint(_PintorFicha viejo) => viejo.valor != valor;
}

/// Una pila de fichas: la apuesta sobre el paño.
///
/// Las grandes abajo y las chicas arriba, cada una un poco mas alta que la
/// anterior: vista desde arriba, se ve el canto de todas.
class PilaFichas extends StatelessWidget {
  const PilaFichas({
    required this.monto,
    this.diametro = 34,
    this.etiqueta = true,
    super.key,
  });

  final int monto;
  final double diametro;
  final bool etiqueta;

  /// Lo que ocupa: la pila mas alta posible y la etiqueta.
  static Size medida(double diametro) =>
      Size(diametro + 30, diametro + 12 * diametro * _grosor + 22);

  /// Cuanto sube cada ficha sobre la de abajo, en diametros: lo justo para
  /// ver el canto de cada una.
  static const _grosor = .2;

  @override
  Widget build(BuildContext context) {
    final medida = PilaFichas.medida(diametro);
    return SizedBox.fromSize(
      size: medida,
      child: monto <= 0
          ? null
          : RepaintBoundary(
              child: CustomPaint(
                painter: _PintorPila(monto, diametro, etiqueta),
              ),
            ),
    );
  }
}

class _PintorPila extends CustomPainter {
  const _PintorPila(this.monto, this.diametro, this.etiqueta);

  final int monto;
  final double diametro;
  final bool etiqueta;

  @override
  void paint(Canvas canvas, Size size) {
    final radio = diametro / 2;
    final grosor = diametro * PilaFichas._grosor;
    // La base de la pila queda a la altura del centro del lugar de apuesta.
    final base = Offset(size.width / 2, size.height - 22 - radio);
    final fichas = fichasDe(monto);
    for (final (i, valor) in fichas.indexed) {
      pintarFicha(
        canvas,
        base - Offset(0, i * grosor),
        radio,
        valor,
        sombra: i == 0,
        numero: i == fichas.length - 1,
      );
    }
    if (!etiqueta) return;
    final texto = TextPainter(
      text: TextSpan(
        text: conMiles(monto),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
          height: 1,
          color: Color(0xFFF7E7B5),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pildora = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 9),
        width: texto.width + 14,
        height: 18,
      ),
      const Radius.circular(9),
    );
    canvas
      ..drawRRect(pildora, Paint()..color = const Color(0xCC111111))
      ..drawRRect(
        pildora,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x99D9A21B),
      );
    texto.paint(
      canvas,
      pildora.center - Offset(texto.width / 2, texto.height / 2),
    );
  }

  @override
  bool shouldRepaint(_PintorPila viejo) =>
      viejo.monto != monto ||
      viejo.diametro != diametro ||
      viejo.etiqueta != etiqueta;
}

/// Fichas que viajan por la mesa: a la apuesta, a MacIAs o a tu bolsillo.
class FichasEnVuelo extends StatefulWidget {
  const FichasEnVuelo({
    required this.desde,
    required this.hasta,
    required this.monto,
    this.diametro = 30,
    this.retraso = Duration.zero,
    this.duracion = const Duration(milliseconds: 460),
    this.desvanecer = false,
    this.alLlegar,
    super.key,
  });

  final Offset desde;
  final Offset hasta;
  final int monto;
  final double diametro;
  final Duration retraso;
  final Duration duracion;

  /// Se apaga al llegar: lo que se lleva MacIAs.
  final bool desvanecer;
  final VoidCallback? alLlegar;

  @override
  State<FichasEnVuelo> createState() => _FichasEnVueloState();
}

class _FichasEnVueloState extends State<FichasEnVuelo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _viaje = AnimationController(
    vsync: this,
    duration: widget.duracion,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.retraso, () async {
      if (!mounted) return;
      await _viaje.forward();
      if (mounted) widget.alLlegar?.call();
    });
  }

  @override
  void dispose() {
    _viaje.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medida = PilaFichas.medida(widget.diametro);
    // El centro de la pila de fichas, dentro de su caja.
    final ancla = Offset(
      medida.width / 2,
      medida.height - 22 - widget.diametro / 2,
    );
    final pila = PilaFichas(
      monto: widget.monto,
      diametro: widget.diametro,
      etiqueta: false,
    );
    return Positioned(
      left: 0,
      top: 0,
      width: medida.width,
      height: medida.height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _viaje,
          child: pila,
          builder: (context, hijo) {
            final t = Curves.easeInOutCubic.transform(_viaje.value);
            final distancia = (widget.hasta - widget.desde).distance;
            final control =
                Offset.lerp(widget.desde, widget.hasta, .5)! +
                Offset(0, -math.min(60.0, distancia * .2));
            final u = 1 - t;
            final p =
                widget.desde * (u * u) +
                control * (2 * u * t) +
                widget.hasta * (t * t);
            // Se agranda un poco en el aire, como algo que se levanta.
            final escala = 1 + .14 * math.sin(t * math.pi);
            final opacidad = !_viaje.isAnimating && _viaje.value == 0
                ? 0.0
                : widget.desvanecer
                ? 1 - Curves.easeIn.transform(((t - .55) / .45).clamp(0.0, 1.0))
                : 1.0;
            return Opacity(
              opacity: opacidad,
              child: Transform(
                alignment: Alignment(0, (ancla.dy / medida.height) * 2 - 1),
                transform: Matrix4.translationValues(
                  p.dx - ancla.dx,
                  p.dy - ancla.dy,
                  0,
                )..scaleByDouble(escala, escala, 1, 1),
                child: hijo,
              ),
            );
          },
        ),
      ),
    );
  }
}
