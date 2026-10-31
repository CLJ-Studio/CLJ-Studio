import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../logica/mesa_pesca.dart';
import 'dibujos_pesca.dart';

// Los colores de las maquinas: el borde, el amarillo de obra, el acero.
const _tinta = Color(0xFF1A242B);
const _amarillo = Color(0xFFF7B500);
const _amarilloClaro = Color(0xFFFFD866);
const _amarilloOscuro = Color(0xFFC07F00);
const _negroFranja = Color(0xFF23282C);
const _grafito = Color(0xFF2E373E);
const _acero = Color(0xFF627380);
const _aceroClaro = Color(0xFFA3B4C0);
const _aceroOscuro = Color(0xFF2F3A42);
const _cromo = Color(0xFFE3EAEE);
const _naranja = Color(0xFFF29F05);

/// Para armar caminos con puntos.
extension _Trazo on Path {
  void ir(Offset p) => moveTo(p.dx, p.dy);
  void linea(Offset p) => lineTo(p.dx, p.dy);
  void curva(Offset control, Offset p) =>
      quadraticBezierTo(control.dx, control.dy, p.dx, p.dy);
  void cubica(Offset c1, Offset c2, Offset p) =>
      cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p.dx, p.dy);
}

/// Un degradado entre dos puntos cualesquiera. Sin [paradas], los colores
/// van parejos (el de dart:ui las exige si son mas de dos).
Paint _degradado(
  Offset desde,
  Offset hasta,
  List<Color> colores, [
  List<double>? paradas,
]) => Paint()
  ..shader = ui.Gradient.linear(
    desde,
    hasta,
    colores,
    paradas ??
        switch (colores.length) {
          2 => null,
          3 => const [0.0, .5, 1.0],
          final n => [for (var i = 0; i < n; i++) i / (n - 1)],
        },
  );

/// Un trazo (o un borde) con las puntas redondas.
Paint _borde(Color color, double grueso) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = grueso
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = color;

/// Una luz que se apaga hacia afuera (sin desenfoque, que es caro).
void _resplandor(Canvas canvas, Offset centro, double radio, Color color) {
  if (radio <= 0 || color.a <= 0) return;
  canvas.drawCircle(
    centro,
    radio,
    Paint()
      ..shader = ui.Gradient.radial(centro, radio, [
        color,
        color.withValues(alpha: 0),
      ]),
  );
}

/// Las franjas amarillas y negras de peligro dentro de [forma] ([caja] la
/// encierra); [paso] es lo ancho de cada franja.
void _franjas(Canvas canvas, Path forma, Rect caja, double paso) {
  final negras = Path();
  final alto = caja.height;
  for (var x = caja.left - alto - paso; x < caja.right; x += paso * 2) {
    negras
      ..moveTo(x, caja.bottom)
      ..lineTo(x + paso, caja.bottom)
      ..lineTo(x + paso + alto, caja.top)
      ..lineTo(x + alto, caja.top)
      ..close();
  }
  canvas
    ..save()
    ..clipPath(forma)
    ..drawRect(caja, Paint()..color = _amarillo)
    ..drawPath(negras, Paint()..color = _negroFranja)
    ..restore();
}

/// Un vidrio: refleja el cielo arriba, se oscurece abajo y tiene un brillo
/// en diagonal. [detras] dibuja lo que se ve a traves.
void _vidrio(
  Canvas canvas,
  Path forma,
  Rect caja,
  Paint borde, {
  void Function()? detras,
}) {
  canvas
    ..drawPath(
      forma,
      _degradado(
        caja.topCenter,
        caja.bottomCenter,
        const [Color(0xFFE4F5FD), Color(0xFF93C7E3), Color(0xFF3F7699)],
        const [0, .45, 1],
      ),
    )
    ..save()
    ..clipPath(forma);
  detras?.call();
  canvas
    ..drawPath(
      Path()
        ..moveTo(caja.left + caja.width * .1, caja.bottom)
        ..lineTo(caja.left + caja.width * .42, caja.top)
        ..lineTo(caja.left + caja.width * .62, caja.top)
        ..lineTo(caja.left + caja.width * .3, caja.bottom)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: .38),
    )
    ..restore()
    ..drawPath(forma, borde);
}

/// [p] girado [angulo] radianes.
Offset _girar(Offset p, double angulo) => Offset(
  p.dx * math.cos(angulo) - p.dy * math.sin(angulo),
  p.dx * math.sin(angulo) + p.dy * math.cos(angulo),
);

/// Una pieza larga de [desde] a [hasta], que va de [gruesoDesde] a
/// [gruesoHasta].
Path _barra(
  Offset desde,
  Offset hasta,
  double gruesoDesde,
  double gruesoHasta,
) {
  final d = hasta - desde;
  final n = Offset(-d.dy, d.dx) / math.max(1e-6, d.distance);
  return Path()..addPolygon([
    desde + n * gruesoDesde / 2,
    hasta + n * gruesoHasta / 2,
    hasta - n * gruesoHasta / 2,
    desde - n * gruesoDesde / 2,
  ], true);
}

/// El degradado de un tubo de [desde] a [hasta]: [colores] van del lado
/// del sol (arriba a la izquierda) al de la sombra.
Paint _tubo(Offset desde, Offset hasta, double grueso, List<Color> colores) {
  final d = hasta - desde;
  var n = Offset(-d.dy, d.dx) / math.max(1e-6, d.distance);
  if (n.dx + n.dy > 0) n = -n;
  final medio = Offset.lerp(desde, hasta, .5)!;
  return _degradado(medio + n * grueso / 2, medio - n * grueso / 2, colores);
}

const _metalOscuro = [Color(0xFF7D8B95), Color(0xFF4A5862), Color(0xFF26313A)];
const _metalClaro = [Colors.white, _cromo, Color(0xFF8C9AA4)];
const _chapa = [_aceroClaro, _acero, _aceroOscuro];

// ------------------------------------------------------------------ el pez

/// Un pez colgado de la boca, recien sacado del agua: la boca abierta
/// arriba, en [boca] (de ahi tira el hilo), y el cuerpo colgando, con el
/// lomo a la izquierda y la panza a la derecha.
///
/// Tiene escamas, aletas con espinas y rayos, la agalla, un ojo grande que
/// mira para arriba y brillos de agua que titilan. [cola] es el pataleo,
/// en radianes: dobla el cuerpo y mueve la cola. [giro] lo gira entero
/// desde la boca. Con [anzuelo] se le ve el anzuelo de la caña en el labio.
void pintarPezColgado(
  Canvas canvas,
  Offset boca,
  double largo,
  double grosor,
  Pez pez, {
  double giro = 0,
  double cola = 0,
  double tiempo = 0,
  bool anzuelo = false,
}) {
  if (largo < 6) return;
  final (lomo, flanco, panza) = ColoresPesca.dePez(pez);
  final contorno = Color.lerp(lomo, Colors.black, .45)!;
  final ancho = largo * grosor;
  final grueso = math.max(.8, ancho * .022);
  final borde = _borde(contorno, grueso);
  final rayo = _borde(
    Colors.white.withValues(alpha: .3),
    math.max(.5, ancho * .012),
  );
  // Un punto del pez: [u] a lo largo (0 la boca, 1 la cola) y [v] a lo
  // ancho (negativo del lado del lomo). El cuerpo se dobla hacia donde va
  // la cola; la cabeza queda quieta.
  final doblez = -cola * largo * .14;
  Offset q(double u, double v) {
    final s = ((u - .3) / .7).clamp(0.0, 1.0);
    return Offset(v * ancho + doblez * s * s, u * largo);
  }

  canvas
    ..save()
    ..translate(boca.dx, boca.dy)
    ..rotate(giro);

  // La cola, de horquilla: sigue al cuerpo y patalea.
  final nace = q(.83, 0);
  final largoCola = largo * .2;
  final puntaCola = ancho * .46;
  final aletaCola = Path()
    ..moveTo(-ancho * .09, -largoCola * .06)
    ..quadraticBezierTo(-ancho * .2, largoCola * .45, -puntaCola, largoCola)
    ..quadraticBezierTo(-ancho * .15, largoCola * .78, 0, largoCola * .6)
    ..quadraticBezierTo(ancho * .15, largoCola * .78, puntaCola, largoCola)
    ..quadraticBezierTo(
      ancho * .2,
      largoCola * .45,
      ancho * .09,
      -largoCola * .06,
    )
    ..close();
  final rayosCola = Path();
  for (final f in const [-.86, -.58, -.3, .3, .58, .86]) {
    rayosCola
      ..moveTo(f * ancho * .05, largoCola * .05)
      ..lineTo(f * puntaCola * .88, largoCola * (.6 + .32 * f.abs()));
  }
  canvas
    ..save()
    ..translate(nace.dx, nace.dy)
    ..rotate(cola * 1.05)
    ..drawPath(
      aletaCola,
      _degradado(
        Offset.zero,
        Offset(0, largoCola),
        [flanco, lomo, Color.lerp(lomo, flanco, .5)!.withValues(alpha: .8)],
        const [0, .55, 1],
      ),
    )
    ..drawPath(rayosCola, rayo)
    ..drawPath(aletaCola, borde)
    ..restore();

  // Las aletas de atras del cuerpo, que ondean: la del lomo con espinas y
  // las de la panza.
  final ondea = math.sin(tiempo * 5) * .015 + cola * .06;
  final dorsal = Path()
    ..ir(q(.2, -.4))
    ..linea(q(.245, -.63 + ondea))
    ..linea(q(.28, -.565))
    ..linea(q(.305, -.67 + ondea))
    ..linea(q(.34, -.59))
    ..linea(q(.365, -.66 + ondea))
    ..linea(q(.4, -.585))
    ..linea(q(.425, -.63 + ondea))
    ..linea(q(.46, -.56))
    ..cubica(q(.52, -.6 + ondea), q(.6, -.54), q(.645, -.28))
    ..linea(q(.42, -.3))
    ..close();
  final espinas = Path();
  for (final (u, v) in const [
    (.245, -.63),
    (.305, -.67),
    (.365, -.66),
    (.425, -.63),
    (.5, -.575),
    (.565, -.51),
  ]) {
    espinas
      ..ir(q(u + .015, -.4))
      ..linea(q(u, v + ondea));
  }
  final anal = Path()
    ..ir(q(.57, .3))
    ..cubica(q(.61, .45), q(.67, .5 - ondea), q(.75, .47 - ondea))
    ..curva(q(.74, .3), q(.77, .16))
    ..close();
  final pelvica = Path()
    ..ir(q(.26, .4))
    ..curva(q(.32, .58), q(.43, .6 - ondea))
    ..curva(q(.38, .48), q(.37, .41))
    ..close();
  final rayosPanza = Path()
    ..ir(q(.6, .32))
    ..linea(q(.67, .46 - ondea))
    ..ir(q(.65, .3))
    ..linea(q(.72, .45 - ondea))
    ..ir(q(.29, .42))
    ..linea(q(.4, .57 - ondea));
  final aletaPanza = _degradado(q(.5, .3), q(.5, .6), [
    Color.lerp(lomo, flanco, .35)!,
    Color.lerp(flanco, panza, .35)!.withValues(alpha: .85),
  ]);
  canvas
    ..drawPath(
      dorsal,
      _degradado(q(.4, -.4), q(.4, -.68), [
        lomo,
        Color.lerp(lomo, flanco, .55)!.withValues(alpha: .85),
      ]),
    )
    ..drawPath(
      espinas,
      _borde(contorno.withValues(alpha: .45), math.max(.5, ancho * .012)),
    )
    ..drawPath(dorsal, borde)
    ..drawPath(anal, aletaPanza)
    ..drawPath(pelvica, aletaPanza)
    ..drawPath(rayosPanza, rayo)
    ..drawPath(anal, borde)
    ..drawPath(pelvica, borde);

  // El cuerpo.
  final cuerpo = Path()
    ..ir(q(.008, -.075))
    ..cubica(q(-.005, -.23), q(.06, -.375), q(.2, -.415))
    ..cubica(q(.34, -.455), q(.52, -.39), q(.66, -.245))
    ..cubica(q(.74, -.16), q(.79, -.1), q(.845, -.08))
    ..linea(q(.845, .08))
    ..cubica(q(.79, .11), q(.74, .18), q(.66, .265))
    ..cubica(q(.52, .42), q(.33, .47), q(.2, .425))
    ..cubica(q(.08, .38), q(.025, .26), q(.03, .12))
    ..curva(q(0, .02), q(.008, -.075))
    ..close();
  canvas
    ..drawPath(
      cuerpo,
      _degradado(
        q(.35, -.46),
        q(.35, .48),
        [lomo, flanco, flanco, panza],
        const [0, .4, .58, .95],
      ),
    )
    ..save()
    ..clipPath(cuerpo);

  // El dibujo de cada especie: pintas claras, franjas de koi o motas de
  // oro.
  final marcas = Path();
  final colorMarcas = switch (pez) {
    Pez.azulitos => Colors.white.withValues(alpha: .42),
    Pez.naranjotes => Color.lerp(
      lomo,
      Colors.black,
      .25,
    )!.withValues(alpha: .5),
    Pez.rojazos => const Color(0xFFFFD86B).withValues(alpha: .7),
  };
  switch (pez) {
    case Pez.azulitos:
      for (final (u, v, r) in const [
        (.3, -.27, .035),
        (.36, -.34, .026),
        (.4, -.2, .03),
        (.46, -.3, .027),
        (.52, -.21, .028),
        (.57, -.29, .022),
        (.63, -.17, .022),
        (.33, -.16, .022),
        (.49, -.37, .018),
        (.69, -.11, .018),
      ]) {
        marcas.addOval(Rect.fromCircle(center: q(u, v), radius: ancho * r));
      }
    case Pez.naranjotes:
      for (final u in const [.3, .44, .58]) {
        marcas
          ..ir(q(u, -.5))
          ..curva(q(u + .04, -.2), q(u - .01, .1))
          ..linea(q(u + .035, .1))
          ..curva(q(u + .085, -.2), q(u + .05, -.5))
          ..close();
      }
    case Pez.rojazos:
      for (final (u, v) in const [
        (.3, -.25),
        (.34, -.12),
        (.38, -.31),
        (.42, -.18),
        (.46, -.05),
        (.5, -.28),
        (.54, -.14),
        (.58, -.24),
        (.62, -.08),
        (.66, -.17),
        (.4, .03),
        (.52, .05),
        (.7, -.09),
      ]) {
        marcas.addOval(Rect.fromCircle(center: q(u, v), radius: ancho * .028));
      }
  }
  canvas.drawPath(marcas, Paint()..color = colorMarcas);

  // Las escamas, en filas, como tejas hacia la cola (no en los chiquitos).
  if (ancho > 14) {
    final paso = ancho * .13;
    final escamas = Path();
    var fila = 0;
    for (var y = largo * .28; y < largo * .84; y += paso * .72) {
      final corrido = fila.isOdd ? paso * .5 : 0.0;
      final medio = q(y / largo, 0).dx;
      for (var x = -ancho * .5 + corrido; x < ancho * .5; x += paso) {
        escamas.addArc(
          Rect.fromCircle(center: Offset(medio + x, y), radius: paso * .55),
          0,
          math.pi,
        );
      }
      fila++;
    }
    canvas
      ..drawPath(
        escamas.shift(Offset(0, paso * .12)),
        _borde(Colors.black.withValues(alpha: .1), math.max(.6, ancho * .012)),
      )
      ..drawPath(
        escamas,
        _borde(Colors.white.withValues(alpha: .2), math.max(.6, ancho * .013)),
      );
  }

  // Redondo: sombra en la panza y en el filo del lomo, la luz del sol
  // sobre el lomo y la linea del costado.
  final todo = Rect.fromLTRB(-ancho * 1.2, -largo * .05, ancho * 1.2, largo);
  canvas
    ..drawRect(
      todo,
      _degradado(q(.4, .1), q(.4, .5), [
        Colors.black.withValues(alpha: 0),
        Colors.black.withValues(alpha: .26),
      ]),
    )
    ..drawRect(
      todo,
      _degradado(q(.4, -.48), q(.4, -.3), [
        Colors.black.withValues(alpha: .18),
        Colors.black.withValues(alpha: 0),
      ]),
    )
    ..drawPath(
      Path()
        ..ir(q(.1, -.3))
        ..cubica(q(.25, -.37), q(.45, -.34), q(.63, -.2))
        ..cubica(q(.47, -.27), q(.27, -.27), q(.1, -.3))
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: .3),
    )
    ..drawPath(
      Path()
        ..ir(q(.25, -.07))
        ..curva(q(.52, -.13), q(.82, -.01)),
      _borde(Colors.white.withValues(alpha: .3), math.max(.5, ancho * .016)),
    );
  // La agalla: la tapa que se levanta, con su sombra y su filo de luz.
  final agalla = Path()
    ..ir(q(.17, -.43))
    ..curva(q(.32, -.02), q(.2, .45));
  canvas
    ..drawPath(
      agalla.shift(Offset(0, largo * .012)),
      _borde(Colors.black.withValues(alpha: .15), ancho * .05),
    )
    ..drawPath(agalla, _borde(contorno.withValues(alpha: .85), grueso))
    ..drawPath(
      agalla.shift(Offset(0, -largo * .006)),
      _borde(Colors.white.withValues(alpha: .22), grueso * .7),
    )
    ..restore()
    ..drawPath(cuerpo, borde);

  // La aleta del costado, que abanica.
  final raiz = q(.25, .12);
  final pectoral = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(ancho * .04, ancho * .2, ancho * .02, ancho * .42)
    ..quadraticBezierTo(ancho * .15, ancho * .36, ancho * .24, ancho * .26)
    ..quadraticBezierTo(ancho * .12, ancho * .12, 0, 0)
    ..close();
  final rayosPectoral = Path();
  for (final (x, y) in const [(.06, .36), (.13, .32), (.19, .27)]) {
    rayosPectoral
      ..moveTo(0, 0)
      ..lineTo(ancho * x, ancho * y);
  }
  canvas
    ..save()
    ..translate(raiz.dx, raiz.dy)
    ..rotate(math.sin(tiempo * 6) * .2 - cola * .5)
    ..drawPath(
      pectoral,
      _degradado(Offset.zero, Offset(ancho * .1, ancho * .4), [
        Color.lerp(lomo, flanco, .3)!.withValues(alpha: .85),
        Color.lerp(flanco, panza, .3)!.withValues(alpha: .6),
      ]),
    )
    ..drawPath(rayosPectoral, rayo)
    ..drawPath(pectoral, _borde(contorno, grueso * .8))
    ..restore();

  // El ojo, grande, que mira para arriba (al anzuelo).
  final ojo = q(.11, -.15);
  final radio = math.max(1.5, ancho * .11);
  canvas
    ..drawCircle(
      ojo,
      radio * 1.2,
      Paint()..color = contorno.withValues(alpha: .55),
    )
    ..drawCircle(ojo, radio, Paint()..color = Colors.white)
    ..drawCircle(
      ojo + Offset(0, -radio * .12),
      radio * .66,
      Paint()..color = Color.lerp(lomo, Colors.black, .2)!,
    )
    ..drawCircle(
      ojo + Offset(0, -radio * .18),
      radio * .4,
      Paint()..color = const Color(0xFF0B141B),
    )
    ..drawCircle(
      ojo + Offset(radio * .28, -radio * .42),
      radio * .24,
      Paint()..color = Colors.white,
    )
    ..drawCircle(
      ojo + Offset(-radio * .2, radio * .3),
      radio * .1,
      Paint()..color = Colors.white.withValues(alpha: .8),
    );

  // La boca abierta, arriba: los labios gruesos y oscura adentro.
  final labioArriba = q(.004, -.085);
  final labioAbajo = q(.03, .125);
  final comisura = q(.1, 0);
  final hueco = Path()
    ..ir(labioArriba)
    ..curva(q(.06, -.06), comisura)
    ..curva(q(.075, .09), labioAbajo)
    ..curva(q(0, .02), labioArriba)
    ..close();
  final labio = _borde(
    Color.lerp(panza, const Color(0xFFF08A95), .35)!,
    math.max(1.2, ancho * .05),
  );
  canvas
    ..drawPath(
      Path()
        ..ir(labioArriba)
        ..curva(q(.06, -.06), comisura),
      labio,
    )
    ..drawPath(
      Path()
        ..ir(comisura)
        ..curva(q(.075, .09), labioAbajo),
      labio,
    )
    ..drawPath(
      hueco,
      _degradado(q(0, .02), comisura, const [
        Color(0xFF5A0D16),
        Color(0xFF1C0306),
      ]),
    )
    ..drawPath(hueco, _borde(contorno, grueso * .7));

  if (anzuelo) {
    // El anzuelo: cuelga del hilo, entra en la boca y sale por el labio.
    final t = ancho * .14;
    final gancho = Path()
      ..moveTo(t * .1, -t * .45)
      ..lineTo(t * .1, t * .55)
      ..quadraticBezierTo(t * .1, t * 1.05, -t * .35, t)
      ..quadraticBezierTo(-t * .75, t * .92, -t * .72, t * .35);
    final punta = Offset(-t * .72, t * .35);
    const plata = Color(0xFFDCE3E8);
    canvas
      ..drawPath(gancho, _borde(const Color(0xFF263238), t * .2))
      ..drawPath(gancho, _borde(plata, t * .1))
      ..drawCircle(Offset(t * .1, -t * .55), t * .13, _borde(plata, t * .07))
      ..drawPath(
        Path()
          ..ir(punta)
          ..linea(punta + Offset(t * .22, t * .18))
          ..linea(punta + Offset(-t * .02, -t * .12))
          ..close(),
        Paint()..color = plata,
      );
  }

  // Brillos de agua que titilan.
  var i = 0;
  for (final (u, v) in const [(.3, -.3), (.48, -.18), (.62, -.24)]) {
    final brilla = math.sin(tiempo * 2.3 + i * 2.1);
    if (brilla > .3) {
      pintarDestello(
        canvas,
        q(u, v),
        ancho * (.04 + .06 * brilla),
        Colors.white.withValues(alpha: .9 * brilla),
        angulo: .3,
      );
    }
    i++;
  }
  canvas.restore();
}

/// La bocaza del pez gigante que sale del hielo a tragarse al chico, vista
/// de frente con la boca abierta para arriba ([abre]: 0 cerrada, 1 abierta
/// del todo).
///
/// Se pinta en dos veces para que el chico quede adentro: con [adentro],
/// las aletas y el fondo de la boca (la garganta, la lengua y los dientes
/// de atras), que van detras del chico; sin, la cara con sus escamas y
/// agallas, los dientes de adelante, el labio y los ojos con cara de
/// hambre, que van delante.
void pintarBocaza(
  Canvas canvas,
  Offset base,
  double ancho,
  double alto,
  double abre,
  Pez pez, {
  required bool adentro,
  double tiempo = 0,
}) {
  if (alto <= 0) return;
  final (lomo, flanco, panza) = ColoresPesca.dePez(pez);
  final contorno = Color.lerp(lomo, Colors.black, .45)!;
  final grueso = math.max(1.0, ancho * .016);
  final borde = _borde(contorno, grueso);
  final mitad = ancho / 2;
  final arriba = base.dy - alto;
  final labio = mitad * (.5 + .5 * abre);
  final puntaLabio = arriba + alto * .08 * (1 - abre);
  final garganta = arriba + alto * (.5 * abre - .06 * (1 - abre));
  final izquierda = Offset(base.dx - labio, puntaLabio);
  final derecha = Offset(base.dx + labio, puntaLabio);
  final fondo = Offset(base.dx, garganta);
  final lejos = Offset(base.dx, puntaLabio - alto * .12 * abre);
  final controlIzquierdo = Offset(base.dx - labio * .35, garganta);
  final controlDerecho = Offset(base.dx + labio * .35, garganta);

  if (adentro) {
    // Las aletas de los costados, que abanican.
    final aleta = Path()
      ..moveTo(0, -ancho * .06)
      ..quadraticBezierTo(ancho * .14, -ancho * .2, ancho * .3, -ancho * .22)
      ..quadraticBezierTo(ancho * .22, -ancho * .08, ancho * .26, ancho * .06)
      ..quadraticBezierTo(ancho * .12, ancho * .02, 0, ancho * .08)
      ..close();
    final rayos = Path();
    for (final (x, y) in const [(.27, -.19), (.25, -.08), (.22, .03)]) {
      rayos
        ..moveTo(0, 0)
        ..lineTo(ancho * x, ancho * y);
    }
    for (final lado in const [-1.0, 1.0]) {
      final raiz = Offset(base.dx + lado * mitad * .9, base.dy - alto * .22);
      canvas
        ..save()
        ..translate(raiz.dx, raiz.dy)
        ..scale(lado, 1)
        ..rotate(math.sin(tiempo * 8 + lado) * .12)
        ..drawPath(
          aleta,
          _degradado(Offset.zero, Offset(ancho * .3, -ancho * .2), [
            lomo,
            Color.lerp(lomo, flanco, .6)!.withValues(alpha: .85),
          ]),
        )
        ..drawPath(
          rayos,
          _borde(
            Colors.white.withValues(alpha: .3),
            math.max(.6, ancho * .008),
          ),
        )
        ..drawPath(aleta, borde)
        ..restore();
    }
    if (abre <= .04) return;
    // El fondo de la boca: oscuro hacia la garganta.
    final hueco = Path()
      ..ir(izquierda)
      ..curva(lejos, derecha)
      ..curva(controlDerecho, fondo)
      ..curva(controlIzquierdo, izquierda)
      ..close();
    canvas.drawPath(
      hueco,
      Paint()
        ..shader = ui.Gradient.radial(
          fondo,
          labio * 1.1,
          const [Color(0xFF14020A), Color(0xFF4A0A14), Color(0xFF8E1B2C)],
          const [0, .55, 1],
        ),
    );
    // La lengua.
    final lengua = Rect.fromCenter(
      center: Offset(base.dx, garganta - alto * .06 * abre),
      width: labio * .8,
      height: alto * .16 * abre,
    );
    canvas
      ..drawOval(
        lengua,
        _degradado(lengua.topCenter, lengua.bottomCenter, const [
          Color(0xFFE77A88),
          Color(0xFFB23446),
        ]),
      )
      ..drawLine(
        lengua.topCenter + Offset(0, lengua.height * .25),
        lengua.center + Offset(0, lengua.height * .2),
        _borde(
          const Color(0xFF8E2234).withValues(alpha: .6),
          math.max(.8, ancho * .008),
        ),
      );
    // Los dientes de atras, colgando del labio de arriba.
    final dientes = Path();
    final tam = ancho * .034 * abre;
    for (var k = 1; k < 8; k++) {
      final f = k / 8;
      final g = 1 - f;
      final p = izquierda * (g * g) + lejos * (2 * g * f) + derecha * (f * f);
      dientes
        ..moveTo(p.dx - tam * .5, p.dy - 1)
        ..lineTo(p.dx + tam * .5, p.dy - 1)
        ..lineTo(p.dx, p.dy + tam * 1.1)
        ..close();
    }
    canvas
      ..drawPath(dientes, Paint()..color = const Color(0xFFE6DED2))
      ..drawPath(
        Path()
          ..ir(izquierda)
          ..curva(lejos, derecha),
        _borde(Color.lerp(flanco, lomo, .3)!, math.max(1.0, ancho * .022)),
      );
    return;
  }

  // La cara: de frente, con el labio de adelante arriba.
  final cara = Path()
    ..moveTo(base.dx - mitad, base.dy + 4)
    ..cubica(
      Offset(base.dx - mitad * 1.1, base.dy - alto * .5),
      Offset(base.dx - labio * 1.12, puntaLabio + alto * .2),
      izquierda,
    )
    ..curva(controlIzquierdo, fondo)
    ..curva(controlDerecho, derecha)
    ..cubica(
      Offset(base.dx + labio * 1.12, puntaLabio + alto * .2),
      Offset(base.dx + mitad * 1.1, base.dy - alto * .5),
      Offset(base.dx + mitad, base.dy + 4),
    )
    ..close();
  final caja = Rect.fromLTRB(
    base.dx - mitad * 1.1,
    arriba - alto * .1,
    base.dx + mitad * 1.1,
    base.dy + 4,
  );
  canvas
    ..drawPath(
      cara,
      _degradado(
        caja.centerLeft,
        caja.centerRight,
        [lomo, flanco, panza, flanco, lomo],
        const [0, .22, .5, .78, 1],
      ),
    )
    ..save()
    ..clipPath(cara);
  final paso = ancho * .1;
  final escamas = Path();
  var fila = 0;
  for (var y = arriba + paso * .5; y < base.dy + paso; y += paso * .75) {
    final corrido = fila.isOdd ? paso * .5 : 0.0;
    for (var x = caja.left + corrido; x < caja.right; x += paso) {
      escamas.addArc(
        Rect.fromCircle(center: Offset(x, y), radius: paso * .5),
        0,
        math.pi,
      );
    }
    fila++;
  }
  // Las agallas de los costados, abajo y hacia afuera.
  final agallas = Path();
  for (final lado in const [-1.0, 1.0]) {
    for (final k in const [0.0, 1.0]) {
      final x = base.dx + lado * mitad * (.72 + k * .11);
      agallas
        ..moveTo(x, base.dy - alto * .26)
        ..quadraticBezierTo(
          x + lado * mitad * .09,
          base.dy - alto * .13,
          x,
          base.dy - alto * .01,
        );
    }
  }
  canvas
    ..drawPath(
      escamas,
      _borde(Colors.white.withValues(alpha: .18), math.max(.7, ancho * .007)),
    )
    ..drawRect(
      caja,
      _degradado(
        caja.centerLeft,
        caja.centerRight,
        [
          Colors.black.withValues(alpha: .26),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: .32),
        ],
        const [0, .25, .7, 1],
      ),
    )
    ..drawPath(agallas, _borde(contorno.withValues(alpha: .55), grueso))
    // La luz del sol, sobre el costado izquierdo.
    ..drawPath(
      Path()
        ..moveTo(base.dx - mitad * .8, base.dy)
        ..quadraticBezierTo(
          base.dx - mitad * .9,
          base.dy - alto * .5,
          base.dx - labio * .78,
          puntaLabio + alto * .14,
        ),
      _borde(Colors.white.withValues(alpha: .2), ancho * .05),
    )
    ..restore()
    ..drawPath(cara, borde);

  // Los dientes de adelante, sobre el labio.
  if (abre > .04) {
    final dientes = Path();
    final tam = ancho * .05 * abre;
    Offset enLabio(Offset comisura, Offset control, double f) {
      final g = 1 - f;
      return comisura * (g * g) + control * (2 * g * f) + fondo * (f * f);
    }

    for (final (comisura, control) in [
      (izquierda, controlIzquierdo),
      (derecha, controlDerecho),
    ]) {
      for (var k = 0; k < 5; k++) {
        final f = .1 + k * .18;
        final p = enLabio(comisura, control, f);
        final tangente =
            enLabio(comisura, control, f + .04) -
            enLabio(comisura, control, f - .04);
        final t = tangente / math.max(1e-6, tangente.distance);
        var n = Offset(-t.dy, t.dx);
        if (n.dy > 0) n = -n;
        final a = p - t * tam * .45;
        final b = p + t * tam * .45;
        final c = p + n * tam * 1.15;
        dientes
          ..ir(a)
          ..linea(b)
          ..linea(c)
          ..close();
      }
    }
    canvas
      ..drawPath(dientes, Paint()..color = const Color(0xFFFBF8F2))
      ..drawPath(
        dientes,
        _borde(contorno.withValues(alpha: .45), math.max(.6, grueso * .6)),
      );
  }
  // El labio de adelante, grueso y con brillo.
  final labioDeAdelante = Path()
    ..ir(izquierda)
    ..curva(controlIzquierdo, fondo)
    ..curva(controlDerecho, derecha);
  canvas
    ..drawPath(
      labioDeAdelante,
      _borde(Color.lerp(panza, const Color(0xFFF08A95), .3)!, ancho * .034),
    )
    ..drawPath(
      labioDeAdelante.shift(Offset(0, -ancho * .009)),
      _borde(Colors.white.withValues(alpha: .45), ancho * .009),
    );

  // Los ojos, que miran al chico, con el parpado en diagonal: cara de
  // hambre.
  for (final lado in const [-1.0, 1.0]) {
    final ojo = Offset(base.dx + lado * mitad * .6, arriba + alto * .5);
    final radio = ancho * .08;
    final afuera = lado < 0 ? .7 : .32;
    final adentroDelOjo = lado < 0 ? .32 : .7;
    canvas
      ..drawCircle(
        ojo,
        radio * 1.25,
        Paint()..color = Color.lerp(lomo, Colors.black, .25)!,
      )
      ..drawCircle(ojo, radio, Paint()..color = Colors.white)
      ..drawCircle(
        ojo + Offset(-lado * radio * .25, -radio * .1),
        radio * .62,
        Paint()..color = Color.lerp(const Color(0xFFF5C542), lomo, .3)!,
      )
      ..drawCircle(
        ojo + Offset(-lado * radio * .3, -radio * .12),
        radio * .36,
        Paint()..color = const Color(0xFF0B141B),
      )
      ..drawCircle(
        ojo + Offset(-lado * radio * .08, -radio * .3),
        radio * .15,
        Paint()..color = Colors.white,
      );
    final izquierdo = Offset(ojo.dx - radio * 1.1, ojo.dy - radio * afuera);
    final derecho = Offset(
      ojo.dx + radio * 1.1,
      ojo.dy - radio * adentroDelOjo,
    );
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(Rect.fromCircle(center: ojo, radius: radio * 1.02)),
      )
      ..drawPath(
        Path()..addPolygon([
          Offset(ojo.dx - radio * 1.1, ojo.dy - radio * 1.1),
          Offset(ojo.dx + radio * 1.1, ojo.dy - radio * 1.1),
          derecho,
          izquierdo,
        ], true),
        Paint()..color = flanco,
      )
      ..drawLine(izquierdo, derecho, _borde(contorno, grueso * 1.2))
      ..restore();
  }
}

// ----------------------------------------------------------------- la caña

/// La caña, parada en un tubo clavado en la nieve: el portacarrete con el
/// carrete (la manivela gira mientras recoge, segun [vuelta]), el mango de
/// corcho y la caña roja que se afina hasta la punta naranja, con sus
/// pasahilos y el hilo que corre por ellos. [tension] la dobla: 0 casi
/// derecha, 1 doblada por el peso. [hilo] es lo grueso del hilo.
void pintarCana(
  Canvas canvas,
  Offset mango,
  Offset horqueta,
  Offset punta,
  double tension,
  double vuelta,
  double w,
  double h, {
  double hilo = 1.4,
}) {
  final s = h / 900;
  final largoMango = math.max(1e-6, (horqueta - mango).distance);
  final d = (horqueta - mango) / largoMango;
  // Del lado de abajo de la caña (hacia el hoyo) van el carrete y los
  // pasahilos.
  final abajo = Offset(-d.dy, d.dx);
  Offset enMango(double f) => mango + d * largoMango * f;

  // La caña, de la horqueta a la punta: sale derecha del mango y se dobla
  // al final, hacia donde tira el pez.
  final cuerda = (punta - horqueta).distance;
  final angulo = ui.lerpDouble(-1.08, -.17, tension)!;
  final c1 = horqueta + d * cuerda * .36;
  final c2 = punta - Offset(math.cos(angulo), math.sin(angulo)) * cuerda * .3;
  Offset enCana(double t) {
    final g = 1 - t;
    return horqueta * (g * g * g) +
        c1 * (3 * g * g * t) +
        c2 * (3 * g * t * t) +
        punta * (t * t * t);
  }

  Offset normal(double t) {
    final g = 1 - t;
    final v =
        (c1 - horqueta) * (3 * g * g) +
        (c2 - c1) * (6 * g * t) +
        (punta - c2) * (3 * t * t);
    final tangente = v / math.max(1e-6, v.distance);
    return Offset(-tangente.dy, tangente.dx);
  }

  double gruesoEn(double t) => (5.6 - 3.9 * math.pow(t, .8)) * s;
  Path tramo(double desde, double hasta, int partes) {
    final ida = <Offset>[];
    final vuelta = <Offset>[];
    for (var i = 0; i <= partes; i++) {
      final t = ui.lerpDouble(desde, hasta, i / partes)!;
      final p = enCana(t);
      final n = normal(t) * (gruesoEn(t) / 2);
      ida.add(p - n);
      vuelta.add(p + n);
    }
    return Path()..addPolygon([...ida, ...vuelta.reversed], true);
  }

  // El tubo donde esta parada, con su anillo arriba y el tornillo.
  final tuboAbajo = mango - d * 6 * s;
  final tuboArriba = enMango(.4);
  final tubo = _barra(tuboAbajo, tuboArriba, 11 * s, 11 * s);
  canvas
    ..drawPath(tubo, _tubo(tuboAbajo, tuboArriba, 11 * s, _metalOscuro))
    ..drawPath(tubo, _borde(_tinta, 1.1 * s))
    ..drawPath(
      _barra(tuboArriba - d * 2.6 * s, tuboArriba + d * .6 * s, 13 * s, 13 * s),
      _tubo(tuboArriba - d * 2.6 * s, tuboArriba, 13 * s, _metalClaro),
    )
    ..drawCircle(
      enMango(.25) - abajo * 6.5 * s,
      2.2 * s,
      Paint()..color = _grafito,
    );

  // El portacarrete, con sus anillos, y el mango de corcho con pintas.
  final asientoDesde = enMango(.38);
  final asientoHasta = enMango(.64);
  final asiento = _barra(asientoDesde, asientoHasta, 6.4 * s, 6.4 * s);
  canvas
    ..drawPath(
      asiento,
      _tubo(asientoDesde, asientoHasta, 6.4 * s, const [
        Color(0xFF6E7A83),
        Color(0xFF353E45),
        Color(0xFF1D2328),
      ]),
    )
    ..drawPath(asiento, _borde(_tinta, s));
  for (final f in const [.42, .6]) {
    final p = enMango(f);
    canvas.drawLine(
      p - abajo * 3.9 * s,
      p + abajo * 3.9 * s,
      Paint()
        ..strokeWidth = 2 * s
        ..color = _cromo,
    );
  }
  final corchoDesde = enMango(.64);
  final corchoHasta = horqueta + d * 3 * s;
  final corcho = _barra(corchoDesde, corchoHasta, 7.6 * s, 6.4 * s);
  final pintas = Path();
  for (var k = 0; k < 9; k++) {
    final f = (k * 5 % 9) / 9;
    final lado = (k * 4 % 7) / 7 - .5;
    pintas.addOval(
      Rect.fromCircle(
        center:
            Offset.lerp(corchoDesde, corchoHasta, .08 + .84 * f)! +
            abajo * lado * 5 * s,
        radius: .6 * s,
      ),
    );
  }
  canvas
    ..drawPath(
      corcho,
      _tubo(corchoDesde, corchoHasta, 7.6 * s, const [
        Color(0xFFE6C796),
        Color(0xFFC9A26B),
        Color(0xFF8E6639),
      ]),
    )
    ..drawPath(
      pintas,
      Paint()..color = const Color(0xFF7A5530).withValues(alpha: .7),
    )
    ..drawPath(corcho, _borde(const Color(0xFF4A3018), s));

  // La caña roja, con brillo, que se afina; la punta naranja con una
  // franja blanca.
  final cana = tramo(0, 1, 28);
  canvas
    ..drawPath(cana, Paint()..color = const Color(0xFFB0242F))
    ..drawPath(tramo(.87, 1, 6), Paint()..color = const Color(0xFFFF8A3D))
    ..drawPath(tramo(.91, .935, 2), Paint()..color = Colors.white)
    ..drawPath(cana, _borde(const Color(0xFF3A1218), 1.1 * s));
  final brillo = Path()..ir(enCana(0) - normal(0) * gruesoEn(0) * .22);
  for (var i = 1; i <= 16; i++) {
    final t = i / 16 * .86;
    brillo.linea(enCana(t) - normal(t) * gruesoEn(t) * .22);
  }
  canvas
    ..drawPath(
      brillo,
      _borde(const Color(0xFFF07A84).withValues(alpha: .75), 1.1 * s),
    )
    // El anillo donde termina el corcho.
    ..drawLine(
      horqueta - abajo * 3.4 * s,
      horqueta + abajo * 3.4 * s,
      Paint()
        ..strokeWidth = 2 * s
        ..color = _cromo,
    );

  // Los pasahilos: anillos de metal del lado de abajo, con su atadura.
  final pasos = <Offset>[];
  final ataduras = Path();
  final patas = Path();
  final anillos = Path();
  for (final t in const [.1, .26, .41, .55, .67, .78, .87, .94]) {
    final p = enCana(t);
    final n = normal(t);
    final mitad = gruesoEn(t) / 2;
    final r = ui.lerpDouble(3.0, 1.4, t)! * s;
    final anillo = p + n * (mitad + r + 1.5 * s);
    pasos.add(anillo);
    ataduras
      ..ir(p - n * (mitad + .4 * s))
      ..linea(p + n * (mitad + .4 * s));
    patas
      ..ir(p + n * mitad)
      ..linea(anillo - n * r);
    anillos.addOval(Rect.fromCircle(center: anillo, radius: r));
  }
  canvas
    ..drawPath(
      ataduras,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * s
        ..color = const Color(0xFF1B1416),
    )
    ..drawPath(patas, _borde(_cromo, 1.3 * s))
    ..drawPath(anillos, _borde(const Color(0xFF263238), 2.3 * s))
    ..drawPath(anillos, _borde(_cromo, 1.1 * s));

  // El carrete, colgando del portacarrete del lado de abajo: la pata, el
  // cuerpo, la bobina con hilo, el arco y la manivela que gira.
  final centroCarrete = enMango(.51);
  final salida =
      centroCarrete + d * 12.5 * s + abajo * 9.5 * s; // De aca sale el hilo.
  canvas
    ..save()
    ..translate(centroCarrete.dx, centroCarrete.dy)
    ..rotate(math.atan2(d.dy, d.dx))
    ..scale(s);
  final cuerpo = RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(-1, 15), width: 15, height: 12),
    const Radius.circular(4),
  );
  final bobina = RRect.fromLTRBR(
    6,
    9.5,
    12.5,
    20.5,
    const Radius.circular(1.5),
  );
  final manivela =
      const Offset(-1, 15) +
      Offset(math.cos(vuelta + 2.4), math.sin(vuelta + 2.4)) * 10;
  canvas
    ..drawRRect(
      RRect.fromLTRBR(-1.6, 1, 1.6, 10, const Radius.circular(1)),
      Paint()..color = _grafito,
    )
    ..drawRRect(
      cuerpo,
      _degradado(const Offset(0, 9), const Offset(0, 21), const [
        Color(0xFF66737C),
        Color(0xFF2B3238),
      ]),
    )
    ..drawRRect(cuerpo, _borde(_tinta, 1))
    ..drawRRect(bobina, Paint()..color = const Color(0xFFE9F3F7));
  for (final yy in const [12.0, 15.0, 18.0]) {
    canvas.drawLine(
      Offset(6.5, yy),
      Offset(12, yy),
      Paint()
        ..strokeWidth = .7
        ..color = const Color(0xFFB9CCD6),
    );
  }
  canvas
    ..drawRRect(bobina, _borde(_tinta, 1))
    ..drawPath(
      Path()
        ..moveTo(12.5, 8.5)
        ..quadraticBezierTo(16.5, 15, 12.5, 21.5),
      _borde(_cromo, 1.3),
    )
    ..drawLine(const Offset(-1, 15), manivela, _borde(_tinta, 3.2))
    ..drawLine(const Offset(-1, 15), manivela, _borde(_cromo, 1.6))
    ..drawCircle(manivela, 2.7, Paint()..color = const Color(0xFFF1E3C6))
    ..drawCircle(manivela, 2.7, _borde(_tinta, .9))
    ..drawCircle(const Offset(-1, 15), 1.6, Paint()..color = _cromo)
    ..restore();

  // El hilo: sale del carrete, pasa por los pasahilos y llega a la punta.
  final recorrido = Path()..ir(salida);
  for (final p in pasos) {
    recorrido.linea(p);
  }
  recorrido.linea(punta);
  canvas.drawPath(
    recorrido,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hilo
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: .92),
  );

  // La nieve amontonada al pie del tubo, y su sombra.
  final suelo = mango + Offset(0, 2 * s);
  canvas
    ..drawOval(
      Rect.fromCenter(
        center: suelo + Offset(w * .02, 5 * s),
        width: w * .17,
        height: h * .02,
      ),
      Paint()..color = const Color(0xFF8DB3CC).withValues(alpha: .35),
    )
    ..drawPath(
      Path()
        ..moveTo(suelo.dx - w * .06, suelo.dy + 5 * s)
        ..quadraticBezierTo(
          suelo.dx - w * .03,
          suelo.dy - 7 * s,
          suelo.dx + w * .004,
          suelo.dy - 8 * s,
        )
        ..quadraticBezierTo(
          suelo.dx + w * .035,
          suelo.dy - 7 * s,
          suelo.dx + w * .065,
          suelo.dy + 5 * s,
        )
        ..close(),
      _degradado(
        Offset(suelo.dx, suelo.dy - 8 * s),
        Offset(suelo.dx, suelo.dy + 5 * s),
        const [Colors.white, Color(0xFFD6E7F2)],
      ),
    );
}

// ----------------------------------------------------------------- la grua

/// El gancho al final del cable: el moton amarillo con franjas, el
/// giratorio y el gancho de acero, con la carga colgando en [donde].
void pintarGancho(Canvas canvas, Offset donde, double tam) {
  final borde = _borde(_tinta, math.max(.8, tam * .1));
  final caja = Rect.fromCenter(
    center: donde - Offset(0, tam * 2.1),
    width: tam * 1.5,
    height: tam * 1.6,
  );
  final moton = Path()
    ..addRRect(RRect.fromRectAndRadius(caja, Radius.circular(tam * .3)));
  _franjas(canvas, moton, caja, tam * .3);
  final cuello = caja.bottom + tam * .3;
  final gancho = Path()
    ..moveTo(donde.dx, cuello)
    ..quadraticBezierTo(
      donde.dx + tam * .5,
      cuello + tam * .1,
      donde.dx + tam * .5,
      donde.dy - tam * .5,
    )
    ..arcTo(
      Rect.fromCircle(
        center: Offset(donde.dx, donde.dy - tam * .5),
        radius: tam * .5,
      ),
      0,
      math.pi,
      false,
    )
    ..lineTo(donde.dx - tam * .58, donde.dy - tam * .95);
  canvas
    ..drawPath(moton, borde)
    ..drawCircle(caja.center, tam * .24, Paint()..color = _grafito)
    ..drawCircle(caja.center, tam * .1, Paint()..color = _cromo)
    ..drawRect(
      Rect.fromLTRB(
        donde.dx - tam * .15,
        caja.bottom - 1,
        donde.dx + tam * .15,
        cuello + tam * .05,
      ),
      Paint()..color = _grafito,
    )
    ..drawPath(gancho, _borde(_tinta, tam * .42))
    ..drawPath(gancho, _borde(const Color(0xFF8C9AA4), tam * .26))
    ..drawPath(gancho, _borde(Colors.white.withValues(alpha: .45), tam * .07))
    // La traba, que cierra el gancho.
    ..drawLine(
      Offset(donde.dx - tam * .58, donde.dy - tam * .95),
      Offset(donde.dx + tam * .2, cuello + tam * .3),
      _borde(_cromo, tam * .08),
    );
}

/// Una rueda de camion girada [angulo]: la goma con su dibujo, la llanta y
/// las tuercas.
void _rueda(
  Canvas canvas,
  Offset centro,
  double radio,
  double angulo,
  Paint borde,
) {
  final dibujo = Path();
  final tuercas = Path();
  for (var k = 0; k < 12; k++) {
    final dir = Offset(
      math.cos(angulo + k * math.pi / 6),
      math.sin(angulo + k * math.pi / 6),
    );
    dibujo
      ..ir(centro + dir * radio * .84)
      ..linea(centro + dir * radio);
    if (k.isEven) {
      tuercas.addOval(
        Rect.fromCircle(
          center: centro + dir * radio * .36,
          radius: radio * .06,
        ),
      );
    }
  }
  canvas
    ..drawCircle(centro, radio, Paint()..color = const Color(0xFF22282D))
    ..drawCircle(
      centro,
      radio * .9,
      _borde(const Color(0xFF3A4249), radio * .1),
    )
    ..drawPath(
      dibujo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * .1
        ..color = const Color(0xFF111518),
    )
    ..drawCircle(centro, radio, borde)
    ..drawCircle(
      centro,
      radio * .58,
      Paint()
        ..shader = ui.Gradient.radial(
          centro - Offset(radio * .2, radio * .2),
          radio * .7,
          const [Color(0xFFE6ECF0), Color(0xFF8D99A2)],
        ),
    )
    ..drawCircle(
      centro,
      radio * .58,
      _borde(const Color(0xFF4E5A63), radio * .06),
    )
    ..drawCircle(centro, radio * .22, Paint()..color = const Color(0xFF59656E))
    ..drawPath(tuercas, Paint()..color = const Color(0xFF3E474E));
}

/// La grua: un camion amarillo con la cabina adelante (y su baliza que
/// parpadea), cuatro ruedas que giran mientras llega ([ruedas] es el
/// angulo), los gatos que bajan al hielo cuando para ([apoyo] de 0 a 1), la
/// torreta con el contrapeso y el brazo telescopico de tres tramos, con su
/// piston, que va de [base] a [punta] (de ahi cuelga el cable).
void pintarGrua(
  Canvas canvas,
  Offset camion,
  Offset base,
  Offset punta,
  double ruedas,
  double w,
  double h, {
  double apoyo = 1,
  double tiempo = 0,
}) {
  final largo = w * .52;
  final alto = h * .055;
  final piso = camion.dy;
  double x(double f) => camion.dx + largo * f;
  double y(double f) => piso - alto * f;
  final grueso = math.max(1.0, alto * .045);
  final borde = _borde(_tinta, grueso);
  final linea = _borde(_amarilloOscuro, math.max(.8, alto * .035));
  Paint pintura(Rect caja) => _degradado(
    caja.topCenter,
    caja.bottomCenter,
    const [_amarilloClaro, _amarillo, _amarilloOscuro],
    const [0, .35, 1],
  );

  // La sombra en el hielo.
  final sombra = Rect.fromCenter(
    center: Offset(camion.dx, piso + alto * .05),
    width: largo * 1.12,
    height: alto * .36,
  );
  canvas.drawOval(
    sombra,
    Paint()
      ..shader = ui.Gradient.radial(sombra.center, sombra.width / 2, [
        const Color(0xFF3A6A86).withValues(alpha: .32),
        const Color(0xFF3A6A86).withValues(alpha: 0),
      ]),
  );

  // El chasis y la cubierta, con las puertitas de las herramientas.
  final chasis = RRect.fromLTRBR(
    x(-.49),
    y(1),
    x(.47),
    y(.58),
    Radius.circular(alto * .08),
  );
  final cajaCubierta = Rect.fromLTRB(x(-.5), y(1.45), x(.28), y(.86));
  final cubierta = RRect.fromRectAndRadius(
    cajaCubierta,
    Radius.circular(alto * .12),
  );
  final puertas = Path();
  final manijas = Path();
  for (final (a, b) in const [(-.44, -.31), (-.17, -.03), (.04, .2)]) {
    puertas.addRRect(
      RRect.fromLTRBR(x(a), y(1.34), x(b), y(.98), Radius.circular(alto * .05)),
    );
    manijas.addRRect(
      RRect.fromLTRBR(
        x(b) - largo * .03,
        y(1.2),
        x(b) - largo * .012,
        y(1.13),
        Radius.circular(alto * .02),
      ),
    );
  }
  canvas
    ..drawRRect(chasis, Paint()..color = _grafito)
    ..drawRRect(chasis, borde)
    ..drawRRect(cubierta, pintura(cajaCubierta))
    ..drawPath(puertas, linea)
    ..drawPath(manijas, Paint()..color = _grafito)
    ..drawRRect(cubierta, borde);
  final cajaParagolpe = Rect.fromLTRB(x(-.55), y(1), x(-.5), y(.56));
  final paragolpe = Path()
    ..addRRect(
      RRect.fromRectAndRadius(cajaParagolpe, Radius.circular(alto * .05)),
    );
  _franjas(canvas, paragolpe, cajaParagolpe, alto * .11);
  canvas.drawPath(paragolpe, borde);

  // La cabina: el parabrisas inclinado, la ventana, la puerta, el espejo,
  // el faro, el paragolpe y la baliza.
  final cajaCabina = Rect.fromLTRB(x(.27), y(2.06), x(.49), y(.6));
  final cabina = Path()
    ..moveTo(x(.27), y(.6))
    ..lineTo(x(.27), y(1.9))
    ..quadraticBezierTo(x(.27), y(2.06), x(.3), y(2.06))
    ..lineTo(x(.41), y(2.06))
    ..quadraticBezierTo(x(.435), y(2.06), x(.443), y(1.98))
    ..lineTo(x(.48), y(1.42))
    ..quadraticBezierTo(x(.49), y(1.32), x(.49), y(1.2))
    ..lineTo(x(.49), y(.68))
    ..quadraticBezierTo(x(.49), y(.6), x(.475), y(.6))
    ..close();
  canvas
    ..drawLine(
      Offset(x(.46), y(1.72)),
      Offset(x(.515), y(1.72)),
      _borde(_grafito, alto * .05),
    )
    ..drawRRect(
      RRect.fromLTRBR(
        x(.505),
        y(1.95),
        x(.53),
        y(1.5),
        Radius.circular(alto * .04),
      ),
      Paint()..color = _grafito,
    )
    ..drawPath(cabina, pintura(cajaCabina))
    ..drawLine(
      Offset(x(.449), y(1.93)),
      Offset(x(.479), y(1.45)),
      _borde(const Color(0xFF7FB3D3), largo * .014),
    );
  _vidrio(
    canvas,
    Path()..addPolygon([
      Offset(x(.3), y(1.92)),
      Offset(x(.415), y(1.92)),
      Offset(x(.45), y(1.42)),
      Offset(x(.3), y(1.42)),
    ], true),
    Rect.fromLTRB(x(.3), y(1.92), x(.45), y(1.42)),
    _borde(_tinta, grueso * .8),
  );
  final faro = RRect.fromLTRBR(
    x(.468),
    y(1.06),
    x(.492),
    y(.86),
    Radius.circular(alto * .04),
  );
  canvas
    ..drawPath(
      Path()
        ..moveTo(x(.295), y(1.32))
        ..lineTo(x(.295), y(.72))
        ..lineTo(x(.44), y(.72))
        ..lineTo(x(.455), y(1.32)),
      linea,
    )
    ..drawRRect(
      RRect.fromLTRBR(
        x(.31),
        y(1.2),
        x(.345),
        y(1.13),
        Radius.circular(alto * .02),
      ),
      Paint()..color = _grafito,
    )
    ..drawRRect(
      RRect.fromLTRBR(
        x(.44),
        y(.8),
        x(.505),
        y(.58),
        Radius.circular(alto * .05),
      ),
      Paint()..color = _grafito,
    )
    ..drawRRect(faro, Paint()..color = const Color(0xFFFFF4C2))
    ..drawRRect(faro, borde)
    ..drawPath(cabina, borde);
  final baliza = Offset(x(.36), y(2.06));
  final prende = (math.sin(tiempo * 9) + 1) / 2;
  _resplandor(
    canvas,
    baliza - Offset(0, alto * .1),
    alto * .6,
    const Color(0xFFFFA726).withValues(alpha: .6 * prende),
  );
  canvas
    ..drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(
            center: baliza - Offset(0, alto * .04),
            radius: alto * .13,
          ),
          math.pi,
          math.pi,
        )
        ..close(),
      Paint()
        ..color = Color.lerp(
          const Color(0xFFB85C00),
          const Color(0xFFFFC46B),
          prende,
        )!,
    )
    ..drawRRect(
      RRect.fromLTRBR(
        baliza.dx - alto * .16,
        baliza.dy - alto * .05,
        baliza.dx + alto * .16,
        baliza.dy + alto * .02,
        Radius.circular(alto * .03),
      ),
      Paint()..color = _grafito,
    );

  // Las ruedas, con sus guardabarros.
  final radio = alto * .4;
  final guardabarros = Path();
  for (final f in const [-.38, -.22, .16, .335]) {
    final centro = Offset(x(f), piso - radio);
    _rueda(canvas, centro, radio, ruedas, borde);
    guardabarros.addArc(
      Rect.fromCircle(center: centro, radius: radio * 1.15),
      math.pi * 1.06,
      math.pi * .88,
    );
  }
  canvas.drawPath(guardabarros, _borde(_grafito, alto * .09));

  // Los gatos: bajan hasta el hielo cuando el camion para.
  for (final f in const [-.46, -.04]) {
    final medio = x(f);
    final pie = ui.lerpDouble(y(.42), piso + alto * .14, apoyo)!;
    final caja = RRect.fromLTRBR(
      medio - largo * .04,
      y(1.02),
      medio + largo * .04,
      y(.74),
      Radius.circular(alto * .04),
    );
    final gato = Rect.fromLTRB(
      medio - alto * .08,
      y(.8),
      medio + alto * .08,
      pie - alto * .06,
    );
    final zapata = RRect.fromLTRBR(
      medio - largo * .055,
      pie - alto * .1,
      medio + largo * .055,
      pie,
      Radius.circular(alto * .03),
    );
    canvas
      ..drawRRect(caja, Paint()..color = _acero)
      ..drawRRect(caja, borde)
      ..drawRect(
        gato,
        _degradado(gato.centerLeft, gato.centerRight, _metalClaro),
      )
      ..drawRect(gato, borde)
      ..drawRRect(zapata, Paint()..color = _grafito)
      ..drawRRect(zapata, borde);
  }

  // La torreta: la corona que gira, la casilla con su rejilla, el
  // contrapeso con franjas, la cabina del operador y el tambor del cable.
  final corona = RRect.fromLTRBR(
    base.dx - largo * .2,
    y(1.56),
    base.dx + largo * .1,
    y(1.43),
    Radius.circular(alto * .04),
  );
  final cajaCasilla = Rect.fromLTRB(
    base.dx - largo * .21,
    y(2.2),
    base.dx + largo * .06,
    y(1.54),
  );
  final casilla = RRect.fromRectAndCorners(
    cajaCasilla,
    topLeft: Radius.circular(alto * .2),
    topRight: Radius.circular(alto * .1),
    bottomLeft: Radius.circular(alto * .05),
    bottomRight: Radius.circular(alto * .05),
  );
  final rejilla = Path();
  for (var k = 0; k < 4; k++) {
    rejilla
      ..moveTo(base.dx - largo * .16, y(2.02 - k * .1))
      ..lineTo(base.dx - largo * .08, y(2.02 - k * .1));
  }
  canvas
    ..drawRRect(corona, Paint()..color = _grafito)
    ..drawRRect(corona, borde)
    ..drawRRect(casilla, pintura(cajaCasilla))
    ..drawPath(rejilla, _borde(_amarilloOscuro, alto * .045))
    ..drawRRect(casilla, borde);
  final cajaContrapeso = Rect.fromLTRB(
    base.dx - largo * .29,
    y(2.1),
    base.dx - largo * .2,
    y(1.56),
  );
  final contrapeso = Path()
    ..addRRect(
      RRect.fromRectAndRadius(cajaContrapeso, Radius.circular(alto * .06)),
    );
  _franjas(canvas, contrapeso, cajaContrapeso, alto * .14);
  canvas.drawPath(contrapeso, borde);
  final cajaOperador = Rect.fromLTRB(
    base.dx + largo * .02,
    y(2.36),
    base.dx + largo * .13,
    y(1.56),
  );
  final operador = Path()
    ..moveTo(cajaOperador.left, cajaOperador.bottom)
    ..lineTo(cajaOperador.left, cajaOperador.top + alto * .1)
    ..quadraticBezierTo(
      cajaOperador.left,
      cajaOperador.top,
      cajaOperador.left + alto * .1,
      cajaOperador.top,
    )
    ..lineTo(cajaOperador.right - largo * .03, cajaOperador.top)
    ..lineTo(cajaOperador.right, cajaOperador.top + alto * .35)
    ..lineTo(cajaOperador.right, cajaOperador.bottom)
    ..close();
  canvas.drawPath(operador, pintura(cajaOperador));
  _vidrio(
    canvas,
    Path()..addPolygon([
      Offset(cajaOperador.left + largo * .012, cajaOperador.top + alto * .1),
      Offset(cajaOperador.right - largo * .035, cajaOperador.top + alto * .1),
      Offset(cajaOperador.right - largo * .012, cajaOperador.top + alto * .38),
      Offset(cajaOperador.right - largo * .012, y(1.9)),
      Offset(cajaOperador.left + largo * .012, y(1.9)),
    ], true),
    Rect.fromLTRB(
      cajaOperador.left,
      cajaOperador.top + alto * .1,
      cajaOperador.right,
      y(1.9),
    ),
    _borde(_tinta, grueso * .8),
  );
  final tambor = Offset(base.dx - largo * .12, y(2.2));
  canvas
    ..drawPath(operador, borde)
    ..drawCircle(tambor, alto * .17, Paint()..color = _grafito)
    ..drawCircle(tambor, alto * .17, borde)
    ..drawCircle(tambor, alto * .07, Paint()..color = _acero);

  final dir = punta - base;
  final largoBrazo = dir.distance;
  if (largoBrazo < 1) return;
  final angulo = math.atan2(dir.dy, dir.dx);

  // El piston que levanta el brazo: la camisa oscura y el vastago de
  // cromo.
  final apoyoPiston = Offset(base.dx + largo * .05, y(1.6));
  final enBrazo = base + _girar(Offset(largoBrazo * .4, alto * .3), angulo);
  final camisa = Offset.lerp(apoyoPiston, enBrazo, .58)!;
  final barraCamisa = _barra(apoyoPiston, camisa, alto * .26, alto * .26);
  canvas
    ..drawPath(
      _barra(apoyoPiston, enBrazo, alto * .14, alto * .14),
      _tubo(apoyoPiston, enBrazo, alto * .14, _metalClaro),
    )
    ..drawPath(_barra(apoyoPiston, enBrazo, alto * .14, alto * .14), borde)
    ..drawPath(
      barraCamisa,
      _tubo(apoyoPiston, camisa, alto * .26, _metalOscuro),
    )
    ..drawPath(barraCamisa, borde)
    ..drawCircle(apoyoPiston, alto * .12, Paint()..color = _grafito);

  // El brazo: tres tramos, cada uno sale del anterior; la punta con
  // franjas, la roldana de donde cuelga el cable y el perno del pie.
  canvas
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(angulo);
  for (final (desde, hasta, mitad) in [
    (.72, 1.0, alto * .22),
    (.44, .78, alto * .28),
    (-alto * .35 / largoBrazo, .5, alto * .34),
  ]) {
    final caja = Rect.fromLTRB(
      largoBrazo * desde,
      -mitad,
      largoBrazo * hasta,
      mitad,
    );
    canvas
      ..drawRect(caja, pintura(caja))
      ..drawLine(
        Offset(caja.left + mitad * .3, -mitad * .55),
        Offset(caja.right - mitad * .3, -mitad * .55),
        _borde(Colors.white.withValues(alpha: .4), mitad * .14),
      )
      ..drawRect(caja, borde);
    if (hasta < 1) {
      final collar = Rect.fromLTRB(
        caja.right - alto * .16,
        -mitad - alto * .03,
        caja.right,
        mitad + alto * .03,
      );
      canvas
        ..drawRect(collar, Paint()..color = _grafito)
        ..drawRect(collar, borde);
    }
  }
  final franjasPunta = Rect.fromLTRB(
    largoBrazo - alto * .6,
    -alto * .22,
    largoBrazo - alto * .1,
    alto * .22,
  );
  _franjas(canvas, Path()..addRect(franjasPunta), franjasPunta, alto * .1);
  final cabeza = RRect.fromLTRBR(
    largoBrazo - alto * .12,
    -alto * .28,
    largoBrazo + alto * .22,
    alto * .28,
    Radius.circular(alto * .1),
  );
  final roldana = Offset(largoBrazo, 0);
  canvas
    ..drawRect(franjasPunta, borde)
    ..drawRRect(cabeza, Paint()..color = _grafito)
    ..drawRRect(cabeza, borde)
    ..drawCircle(roldana, alto * .2, Paint()..color = _acero)
    ..drawCircle(roldana, alto * .2, borde)
    ..drawCircle(roldana, alto * .07, Paint()..color = _cromo)
    ..drawCircle(Offset.zero, alto * .3, Paint()..color = _grafito)
    ..drawCircle(Offset.zero, alto * .3, borde)
    ..drawCircle(Offset.zero, alto * .11, Paint()..color = _cromo)
    ..restore()
    // El cable, del tambor a la roldana, por arriba del brazo.
    ..drawLine(
      tambor - Offset(0, alto * .17),
      base + _girar(Offset(largoBrazo, -alto * .2), angulo),
      _borde(_tinta, math.max(.8, alto * .04)),
    );
}

// ---------------------------------------------------------- los helicopteros

/// El rotor que gira: un disco borroso y las aspas (con un rastro, para que
/// se vean rapidas), vistas casi de canto.
void _rotor(
  Canvas canvas,
  Offset eje,
  double radio,
  double alto,
  double angulo,
  int aspas,
) {
  final disco = Rect.fromCenter(center: eje, width: radio * 2, height: alto);
  canvas
    ..drawOval(disco, Paint()..color = _tinta.withValues(alpha: .1))
    ..drawOval(disco, _borde(_tinta.withValues(alpha: .16), alto * .08));
  for (final (atras, alfa) in const [(.32, .2), (0.0, .62)]) {
    final aspa = _borde(_tinta.withValues(alpha: alfa), alto * .32);
    for (var k = 0; k < aspas; k++) {
      final a = angulo - atras + k * 2 * math.pi / aspas;
      canvas.drawLine(
        eje,
        eje + Offset(math.cos(a) * radio, math.sin(a) * alto / 2),
        aspa,
      );
    }
  }
  canvas.drawCircle(eje, alto * .35, Paint()..color = _grafito);
}

/// El helicoptero chico, de rescate: rojo con una franja blanca, la
/// burbuja de vidrio con el piloto adentro, el motor arriba, la cola con su
/// rotor chico, los patines, el malacate del cable y la baliza que
/// parpadea. [inclinacion] lo inclina hacia donde va y [mira] lo da vuelta:
/// 1 mira a la izquierda, -1 a la derecha (en el medio esta girando).
void pintarHelicoptero(
  Canvas canvas,
  Offset centro,
  double largo,
  double inclinacion,
  double tiempo, {
  double mira = 1,
}) {
  final l = largo;
  final a = largo * .3;
  const rojo = Color(0xFFD7263D);
  const rojoClaro = Color(0xFFF25C6E);
  const rojoOscuro = Color(0xFF8A1323);
  final grueso = math.max(.9, a * .05);
  final borde = _borde(_tinta, grueso);
  final pintura = _degradado(
    Offset(0, -a * .55),
    Offset(0, a * .5),
    const [rojoClaro, rojo, rojoOscuro],
    const [0, .45, 1],
  );
  canvas
    ..save()
    ..translate(centro.dx, centro.dy)
    ..rotate(inclinacion)
    ..scale(mira, 1);

  // El patin de atras (el del otro lado), mas claro.
  final patin = Path()
    ..moveTo(l * .12, a * .8)
    ..lineTo(-l * .36, a * .8)
    ..quadraticBezierTo(-l * .44, a * .8, -l * .47, a * .68);
  canvas
    ..drawPath(
      patin.shift(Offset(l * .03, -a * .06)),
      _borde(const Color(0xFF7A8790), a * .065),
    )
    ..drawLine(
      Offset(-l * .25, a * .4),
      Offset(-l * .27, a * .74),
      _borde(const Color(0xFF7A8790), a * .06),
    );

  // La cola: el botalon con su franja, el estabilizador, la deriva con la
  // baliza y el rotor chico.
  final botalon = Path()
    ..addPolygon([
      Offset(l * .08, -a * .36),
      Offset(l * .5, -a * .22),
      Offset(l * .52, -a * .06),
      Offset(l * .1, a * .06),
    ], true);
  final deriva = Path()
    ..moveTo(l * .44, -a * .18)
    ..lineTo(l * .5, -a * .66)
    ..quadraticBezierTo(l * .52, -a * .74, l * .56, -a * .72)
    ..lineTo(l * .56, -a * .1)
    ..lineTo(l * .58, a * .16)
    ..lineTo(l * .54, a * .14)
    ..lineTo(l * .5, -a * .04)
    ..close();
  final estabilizador = RRect.fromLTRBR(
    l * .35,
    -a * .17,
    l * .47,
    -a * .07,
    Radius.circular(a * .04),
  );
  canvas
    ..drawPath(botalon, pintura)
    ..drawPath(
      Path()..addPolygon([
        Offset(l * .12, -a * .17),
        Offset(l * .49, -a * .13),
        Offset(l * .49, -a * .07),
        Offset(l * .12, -a * .07),
      ], true),
      Paint()..color = Colors.white,
    )
    ..drawPath(botalon, borde)
    ..drawPath(deriva, pintura)
    ..drawPath(deriva, borde)
    ..drawRRect(estabilizador, Paint()..color = rojoOscuro)
    ..drawRRect(estabilizador, borde);
  final colita = Offset(l * .53, -a * .42);
  final giroCola = Offset(math.cos(tiempo * 40), math.sin(tiempo * 40));
  canvas
    ..drawCircle(colita, a * .26, Paint()..color = _tinta.withValues(alpha: .1))
    ..drawLine(
      colita - giroCola * a * .26,
      colita + giroCola * a * .26,
      _borde(_tinta.withValues(alpha: .6), a * .05),
    )
    ..drawLine(
      colita - Offset(-giroCola.dy, giroCola.dx) * a * .26,
      colita + Offset(-giroCola.dy, giroCola.dx) * a * .26,
      _borde(_tinta.withValues(alpha: .6), a * .05),
    )
    ..drawCircle(colita, a * .06, Paint()..color = _grafito);
  final prende = math.max(0.0, math.sin(tiempo * 7));
  final baliza = Offset(l * .545, -a * .74);
  _resplandor(
    canvas,
    baliza,
    a * .4,
    const Color(0xFFFF3D3D).withValues(alpha: .7 * prende),
  );
  canvas.drawCircle(
    baliza,
    a * .06,
    Paint()
      ..color = Color.lerp(
        const Color(0xFF7A1A1A),
        const Color(0xFFFF6B6B),
        prende,
      )!,
  );

  // El cuerpo, con la franja blanca y la puerta.
  final cuerpo = Path()
    ..moveTo(-l * .43, a * .1)
    ..cubicTo(-l * .45, -a * .22, -l * .34, -a * .5, -l * .16, -a * .52)
    ..lineTo(l * .02, -a * .52)
    ..cubicTo(l * .1, -a * .52, l * .14, -a * .4, l * .16, -a * .3)
    ..lineTo(l * .16, 0)
    ..cubicTo(l * .12, a * .3, l * .02, a * .5, -l * .12, a * .5)
    ..lineTo(-l * .3, a * .5)
    ..cubicTo(-l * .4, a * .5, -l * .43, a * .34, -l * .43, a * .1)
    ..close();
  canvas
    ..drawPath(cuerpo, pintura)
    ..save()
    ..clipPath(cuerpo)
    ..drawRect(
      Rect.fromLTRB(-l * .5, a * .14, l * .2, a * .27),
      Paint()..color = Colors.white,
    )
    ..restore();
  final puerta = RRect.fromLTRBR(
    -l * .14,
    -a * .4,
    l * .01,
    a * .38,
    Radius.circular(a * .08),
  );
  final ventanita = RRect.fromLTRBR(
    -l * .12,
    -a * .33,
    -l * .01,
    -a * .04,
    Radius.circular(a * .07),
  );
  canvas.drawRRect(puerta, _borde(rojoOscuro, grueso * .8));
  _vidrio(
    canvas,
    Path()..addRRect(ventanita),
    ventanita.outerRect,
    _borde(_tinta, grueso * .8),
  );
  canvas
    ..drawLine(
      Offset(-l * .03, a * .06),
      Offset(-l * .01, a * .06),
      _borde(_tinta, a * .05),
    )
    ..drawPath(cuerpo, borde);

  // La burbuja de vidrio, con el piloto (casco blanco y visor).
  final burbuja = Path()
    ..moveTo(-l * .42, a * .12)
    ..cubicTo(-l * .44, -a * .2, -l * .34, -a * .46, -l * .18, -a * .47)
    ..lineTo(-l * .155, -a * .47)
    ..lineTo(-l * .17, a * .08)
    ..quadraticBezierTo(-l * .3, a * .18, -l * .42, a * .12)
    ..close();
  _vidrio(
    canvas,
    burbuja,
    Rect.fromLTRB(-l * .44, -a * .47, -l * .155, a * .18),
    borde,
    detras: () {
      final casco = Offset(-l * .25, -a * .1);
      canvas
        ..drawRRect(
          RRect.fromLTRBR(
            casco.dx - a * .12,
            casco.dy + a * .1,
            casco.dx + a * .16,
            casco.dy + a * .5,
            Radius.circular(a * .08),
          ),
          Paint()..color = const Color(0xFFE65100).withValues(alpha: .85),
        )
        ..drawCircle(casco, a * .15, Paint()..color = const Color(0xFFF4F6F7))
        ..drawArc(
          Rect.fromCircle(center: casco, radius: a * .15),
          math.pi * .75,
          math.pi * .7,
          true,
          Paint()..color = const Color(0xFF263238),
        );
    },
  );
  canvas.drawLine(
    Offset(-l * .3, -a * .45),
    Offset(-l * .32, a * .15),
    _borde(rojo, a * .05),
  );

  // El motor arriba, con su escape, y el mastil del rotor.
  final motor = Path()
    ..moveTo(-l * .2, -a * .5)
    ..cubicTo(-l * .18, -a * .72, 0, -a * .78, l * .08, -a * .7)
    ..quadraticBezierTo(l * .14, -a * .62, l * .13, -a * .5)
    ..close();
  final rejilla = Path();
  for (var k = 0; k < 3; k++) {
    rejilla
      ..moveTo(-l * .1 + k * l * .04, -a * .64)
      ..lineTo(-l * .1 + k * l * .04, -a * .56);
  }
  canvas
    ..drawPath(
      motor,
      _degradado(Offset(0, -a * .78), Offset(0, -a * .5), const [
        Color(0xFFF4F6F7),
        Color(0xFFC3CDD3),
      ]),
    )
    ..drawPath(rejilla, _borde(const Color(0xFF5B6770), a * .035))
    ..drawPath(motor, borde)
    ..drawRRect(
      RRect.fromLTRBR(
        l * .1,
        -a * .66,
        l * .15,
        -a * .56,
        Radius.circular(a * .03),
      ),
      Paint()..color = _grafito,
    )
    ..drawRect(
      Rect.fromLTRB(-l * .075, -a * .92, -l * .045, -a * .72),
      Paint()..color = _grafito,
    );

  // El malacate del cable, abajo, y los patines de este lado.
  final malacate = RRect.fromLTRBR(
    -l * .18,
    a * .42,
    -l * .1,
    a * .56,
    Radius.circular(a * .04),
  );
  final patinCerca = _borde(const Color(0xFF3A464E), a * .07);
  canvas
    ..drawRRect(malacate, Paint()..color = _grafito)
    ..drawRRect(malacate, borde)
    ..drawLine(Offset(-l * .28, a * .46), Offset(-l * .31, a * .8), patinCerca)
    ..drawLine(Offset(-l * .02, a * .46), Offset(l * .01, a * .8), patinCerca)
    ..drawPath(patin, patinCerca);

  // El rotor de arriba.
  _rotor(canvas, Offset(-l * .06, -a * .93), l * .62, a * .2, tiempo * 47, 4);
  canvas.restore();
}

/// El helicoptero de carga: largo, azul con una franja amarilla, con un
/// rotor adelante y otro atras (giran al reves), la cabina, la fila de
/// ventanas, los tanques de los costados, las ruedas, el gancho de la
/// carga abajo y la baliza. [inclinacion] lo inclina hacia donde va y
/// [mira] lo da vuelta: 1 mira a la izquierda, -1 a la derecha.
void pintarHelicopteroDeCarga(
  Canvas canvas,
  Offset centro,
  double largo,
  double inclinacion,
  double tiempo, {
  double mira = 1,
}) {
  final l = largo;
  final a = largo * .2;
  const azul = Color(0xFF34506B);
  const azulClaro = Color(0xFF5E80A0);
  const azulOscuro = Color(0xFF1C2F42);
  final grueso = math.max(.9, a * .055);
  final borde = _borde(_tinta, grueso);
  final pintura = _degradado(
    Offset(0, -a * .55),
    Offset(0, a * .5),
    const [azulClaro, azul, azulOscuro],
    const [0, .42, 1],
  );
  canvas
    ..save()
    ..translate(centro.dx, centro.dy)
    ..rotate(inclinacion)
    ..scale(mira, 1);

  // Las ruedas, que asoman abajo de los tanques.
  for (final (x, r) in [(-l * .3, a * .17), (l * .3, a * .19)]) {
    final rueda = Offset(x, a * .74);
    canvas
      ..drawLine(Offset(x, a * .45), rueda, _borde(_grafito, a * .09))
      ..drawCircle(rueda, r, Paint()..color = const Color(0xFF22282D))
      ..drawCircle(rueda, r, borde)
      ..drawCircle(rueda, r * .45, Paint()..color = const Color(0xFFB0BBC2));
  }

  // La torre de atras, con el motor.
  final torre = Path()
    ..moveTo(l * .2, -a * .45)
    ..lineTo(l * .3, -a * 1.12)
    ..quadraticBezierTo(l * .32, -a * 1.2, l * .38, -a * 1.2)
    ..lineTo(l * .46, -a * 1.2)
    ..quadraticBezierTo(l * .5, -a * 1.2, l * .5, -a * 1.1)
    ..lineTo(l * .5, -a * .45)
    ..close();
  final motor = RRect.fromLTRBR(
    l * .27,
    -a * .94,
    l * .47,
    -a * .7,
    Radius.circular(a * .12),
  );
  canvas
    ..drawPath(torre, pintura)
    ..drawPath(torre, borde)
    ..drawRRect(
      motor,
      _degradado(Offset(0, -a * .94), Offset(0, -a * .7), const [
        Color(0xFF8995A0),
        Color(0xFF39434B),
      ]),
    )
    ..drawRRect(motor, borde)
    ..drawOval(
      Rect.fromLTRB(l * .265, -a * .9, l * .295, -a * .74),
      Paint()..color = const Color(0xFF151C21),
    );

  // El cuerpo, con la franja amarilla.
  final cuerpo = Path()
    ..moveTo(-l * .5, a * .08)
    ..cubicTo(-l * .5, -a * .32, -l * .47, -a * .5, -l * .38, -a * .5)
    ..lineTo(l * .44, -a * .5)
    ..quadraticBezierTo(l * .5, -a * .5, l * .5, -a * .38)
    ..lineTo(l * .5, a * .05)
    ..quadraticBezierTo(l * .49, a * .3, l * .4, a * .5)
    ..lineTo(-l * .36, a * .5)
    ..cubicTo(-l * .46, a * .5, -l * .5, a * .38, -l * .5, a * .08)
    ..close();
  canvas
    ..drawPath(cuerpo, pintura)
    ..save()
    ..clipPath(cuerpo)
    ..drawRect(
      Rect.fromLTRB(-l * .5, a * .1, l * .5, a * .22),
      Paint()..color = _amarillo,
    )
    ..restore()
    ..drawPath(cuerpo, borde);

  // Los tanques de los costados.
  final tanque = RRect.fromLTRBR(
    -l * .3,
    a * .2,
    l * .32,
    a * .58,
    Radius.circular(a * .18),
  );
  canvas
    ..drawRRect(
      tanque,
      _degradado(Offset(0, a * .2), Offset(0, a * .58), const [
        azul,
        azulOscuro,
      ]),
    )
    ..drawRRect(tanque, borde);

  // La fila de ventanas redondas y la puerta.
  final ventanas = Path();
  for (var k = 0; k < 7; k++) {
    ventanas.addOval(
      Rect.fromCircle(
        center: Offset(-l * .2 + k * l * .075, -a * .12),
        radius: a * .1,
      ),
    );
  }
  _vidrio(
    canvas,
    ventanas,
    Rect.fromLTRB(-l * .3, -a * .22, l * .3, -a * .02),
    _borde(_tinta, grueso * .8),
  );
  canvas.drawRRect(
    RRect.fromLTRBR(
      -l * .33,
      -a * .38,
      -l * .26,
      a * .36,
      Radius.circular(a * .06),
    ),
    _borde(azulOscuro, grueso),
  );

  // La cabina, adelante, y la joroba del rotor de adelante.
  final cabina = Path()
    ..moveTo(-l * .493, -a * .02)
    ..cubicTo(-l * .493, -a * .3, -l * .47, -a * .44, -l * .4, -a * .44)
    ..lineTo(-l * .37, -a * .44)
    ..lineTo(-l * .37, -a * .04)
    ..close();
  _vidrio(
    canvas,
    cabina,
    Rect.fromLTRB(-l * .493, -a * .44, -l * .37, -a * .02),
    _borde(_tinta, grueso * .8),
  );
  final joroba = Path()
    ..moveTo(-l * .44, -a * .48)
    ..cubicTo(-l * .42, -a * .78, -l * .3, -a * .8, -l * .26, -a * .62)
    ..lineTo(-l * .24, -a * .48)
    ..close();
  canvas
    ..drawLine(
      Offset(-l * .43, -a * .44),
      Offset(-l * .435, -a * .02),
      _borde(azul, a * .06),
    )
    ..drawPath(joroba, pintura)
    ..drawPath(joroba, borde);

  // El gancho de la carga, abajo en el medio.
  canvas
    ..drawPath(
      Path()..addPolygon([
        Offset(-l * .035, a * .46),
        Offset(l * .035, a * .46),
        Offset(l * .02, a * .58),
        Offset(-l * .02, a * .58),
      ], true),
      Paint()..color = _grafito,
    )
    // Los mastiles de los rotores.
    ..drawRect(
      Rect.fromLTRB(-l * .365, -a * .92, -l * .335, -a * .74),
      Paint()..color = _grafito,
    )
    ..drawRect(
      Rect.fromLTRB(l * .385, -a * 1.36, l * .415, -a * 1.18),
      Paint()..color = _grafito,
    );

  // La baliza, arriba de la torre.
  final prende = math.max(0.0, math.sin(tiempo * 6 + 1));
  final baliza = Offset(l * .47, -a * 1.21);
  _resplandor(
    canvas,
    baliza,
    a * .45,
    const Color(0xFFFF3D3D).withValues(alpha: .7 * prende),
  );
  canvas.drawCircle(
    baliza,
    a * .07,
    Paint()
      ..color = Color.lerp(
        const Color(0xFF7A1A1A),
        const Color(0xFFFF6B6B),
        prende,
      )!,
  );

  // Los dos rotores, de tres aspas, que giran al reves.
  _rotor(canvas, Offset(-l * .35, -a * .93), l * .38, a * .22, tiempo * 40, 3);
  _rotor(
    canvas,
    Offset(l * .4, -a * 1.37),
    l * .38,
    a * .22,
    -tiempo * 40 + 1,
    3,
  );
  canvas.restore();
}

// ---------------------------------------------------------------- el robot

/// El robot que sale del hielo a sacar los peces enormes: acero con placas
/// remachadas y franjas de peligro, las rodillas con pistones, el reactor
/// que late en el pecho, el visor que mira de un lado a otro, la antena con
/// su baliza, vapor por la espalda y nieve en la cabeza (viene de abajo del
/// hielo). Los brazos van aparte ([pintarBrazosRobot]), delante del pez.
void pintarRobot(Canvas canvas, Offset pies, double alto, double tiempo) {
  final ancho = alto * .48;
  final grueso = math.max(1.0, ancho * .012);
  final borde = _borde(_tinta, grueso);
  double x(double f) => pies.dx + ancho * f;
  double y(double f) => pies.dy - alto * f;
  Paint chapa(Rect caja) =>
      _degradado(caja.centerLeft, caja.centerRight, _chapa, const [0, .45, 1]);

  // El vapor que larga por las ventilas de la espalda.
  final vapor = Paint();
  for (final lado in const [-1.0, 1.0]) {
    final ventila = Offset(x(lado * .38), y(.73));
    for (var k = 0; k < 4; k++) {
      final edad = (tiempo * .9 + k / 4 + (lado > 0 ? .5 : 0)) % 1;
      vapor.color = Colors.white.withValues(alpha: .55 * (1 - edad));
      canvas.drawCircle(
        ventila + Offset(lado * edad * ancho * .2, -edad * alto * .16),
        ancho * (.04 + edad * .07),
        vapor,
      );
    }
  }

  // Las piernas: el muslo con su piston, la rodilla, la canilla con
  // franjas, el tobillo y la bota.
  for (final lado in const [-1.0, 1.0]) {
    final medio = lado * .22;
    final cajaMuslo = Rect.fromLTRB(
      x(medio - .1),
      y(.43),
      x(medio + .1),
      y(.25),
    );
    final muslo = Path()
      ..addPolygon([
        Offset(x(medio - .1), y(.43)),
        Offset(x(medio + .1), y(.43)),
        Offset(x(medio + .085), y(.25)),
        Offset(x(medio - .085), y(.25)),
      ], true);
    final cajaCanilla = Rect.fromLTRB(
      x(medio - .13),
      y(.24),
      x(medio + .13),
      y(.08),
    );
    final canilla = Path()
      ..addPolygon([
        Offset(x(medio - .13), y(.24)),
        Offset(x(medio + .13), y(.24)),
        Offset(x(medio + .1), y(.08)),
        Offset(x(medio - .1), y(.08)),
      ], true);
    final pistonArriba = Offset(x(medio + lado * .13), y(.41));
    final pistonAbajo = Offset(x(medio + lado * .12), y(.19));
    canvas
      ..drawPath(muslo, chapa(cajaMuslo))
      ..drawPath(muslo, borde)
      ..drawLine(pistonArriba, pistonAbajo, _borde(_tinta, ancho * .045))
      ..drawLine(pistonArriba, pistonAbajo, _borde(_cromo, ancho * .025))
      ..drawLine(
        pistonArriba,
        Offset.lerp(pistonArriba, pistonAbajo, .55)!,
        _borde(_grafito, ancho * .05),
      )
      ..drawPath(canilla, chapa(cajaCanilla));
    _franjas(
      canvas,
      canilla,
      Rect.fromLTRB(x(medio - .13), y(.215), x(medio + .13), y(.18)),
      ancho * .03,
    );
    final ventila = Path();
    for (var k = 0; k < 3; k++) {
      ventila
        ..moveTo(x(medio - .05), y(.15 - k * .018))
        ..lineTo(x(medio + .05), y(.15 - k * .018));
    }
    final rodilla = Offset(x(medio), y(.25));
    final tobillo = RRect.fromLTRBR(
      x(medio - .07),
      y(.09),
      x(medio + .07),
      y(.055),
      Radius.circular(ancho * .02),
    );
    final cajaBota = Rect.fromLTRB(
      x(medio - .18),
      y(.075),
      x(medio + .18),
      y(0),
    );
    final bota = Path()
      ..moveTo(x(medio - .18), y(0))
      ..lineTo(x(medio - .15), y(.062))
      ..quadraticBezierTo(x(medio - .14), y(.075), x(medio - .1), y(.075))
      ..lineTo(x(medio + .1), y(.075))
      ..quadraticBezierTo(x(medio + .14), y(.075), x(medio + .15), y(.062))
      ..lineTo(x(medio + .18), y(0))
      ..close();
    canvas
      ..drawPath(ventila, _borde(const Color(0xFF151C21), alto * .007))
      ..drawPath(canilla, borde)
      ..drawCircle(rodilla, ancho * .1, Paint()..color = _grafito)
      ..drawCircle(rodilla, ancho * .1, borde)
      ..drawCircle(
        rodilla,
        ancho * .065,
        Paint()
          ..shader = ui.Gradient.radial(
            rodilla - Offset(ancho * .02, ancho * .02),
            ancho * .08,
            const [_aceroClaro, _acero],
          ),
      )
      ..drawCircle(rodilla, ancho * .065, borde)
      ..drawCircle(rodilla, ancho * .018, Paint()..color = _aceroOscuro)
      ..drawRRect(tobillo, Paint()..color = _grafito)
      ..drawRRect(tobillo, borde)
      ..drawPath(bota, chapa(cajaBota))
      ..drawRect(
        Rect.fromLTRB(x(medio - .18), y(.016), x(medio + .18), y(0)),
        Paint()..color = _grafito,
      )
      ..drawPath(bota, borde);
  }

  // La cadera, con la hebilla de franjas.
  final cadera = RRect.fromLTRBR(
    x(-.3),
    y(.475),
    x(.3),
    y(.395),
    Radius.circular(ancho * .04),
  );
  final cajaHebilla = Rect.fromLTRB(x(-.11), y(.465), x(.11), y(.405));
  final hebilla = Path()
    ..addRRect(
      RRect.fromRectAndRadius(cajaHebilla, Radius.circular(ancho * .02)),
    );
  canvas
    ..drawRRect(cadera, Paint()..color = _grafito)
    ..drawRRect(cadera, borde);
  _franjas(canvas, hebilla, cajaHebilla, ancho * .035);
  canvas.drawPath(hebilla, borde);

  // El torso: la panza con costillas, franjas en las esquinas y la placa
  // del pecho, biselada y con remaches.
  final cajaTorso = Rect.fromLTRB(x(-.5), y(.745), x(.5), y(.465));
  final torso = Path()
    ..ir(Offset(x(-.5), y(.69)))
    ..curva(Offset(x(-.5), y(.745)), Offset(x(-.43), y(.745)))
    ..linea(Offset(x(.43), y(.745)))
    ..curva(Offset(x(.5), y(.745)), Offset(x(.5), y(.69)))
    ..linea(Offset(x(.35), y(.5)))
    ..curva(Offset(x(.32), y(.465)), Offset(x(.27), y(.465)))
    ..linea(Offset(x(-.27), y(.465)))
    ..curva(Offset(x(-.32), y(.465)), Offset(x(-.35), y(.5)))
    ..close();
  canvas.drawPath(torso, chapa(cajaTorso));
  for (final lado in const [-1.0, 1.0]) {
    _franjas(
      canvas,
      torso,
      Rect.fromLTRB(
        lado < 0 ? x(-.5) : x(.3),
        y(.56),
        lado < 0 ? x(-.3) : x(.5),
        y(.465),
      ),
      ancho * .035,
    );
  }
  final costillas = Path();
  for (var k = 0; k < 3; k++) {
    costillas
      ..moveTo(x(-.24 + k * .02), y(.555 - k * .025))
      ..lineTo(x(.24 - k * .02), y(.555 - k * .025));
  }
  final cajaPecho = Rect.fromLTRB(x(-.4), y(.72), x(.4), y(.575));
  final pecho = Path()
    ..addPolygon([
      Offset(x(-.4), y(.72)),
      Offset(x(.4), y(.72)),
      Offset(x(.31), y(.575)),
      Offset(x(-.31), y(.575)),
    ], true);
  final ventilas = Path();
  for (final lado in const [-1.0, 1.0]) {
    for (var k = 0; k < 3; k++) {
      ventilas
        ..moveTo(x(lado * .2), y(.69 - k * .028))
        ..lineTo(x(lado * .3), y(.69 - k * .028));
    }
  }
  final remaches = Path();
  final brilloRemaches = Path();
  for (final (fx, fy) in const [
    (-.36, .705),
    (.36, .705),
    (-.3, .59),
    (.3, .59),
    (-.44, .73),
    (.44, .73),
  ]) {
    final p = Offset(x(fx), y(fy));
    remaches.addOval(Rect.fromCircle(center: p, radius: ancho * .016));
    brilloRemaches.addOval(
      Rect.fromCircle(
        center: p - Offset(ancho * .005, ancho * .005),
        radius: ancho * .006,
      ),
    );
  }
  canvas
    ..drawPath(costillas, _borde(_aceroOscuro, alto * .01))
    ..drawPath(torso, borde)
    ..drawPath(
      pecho,
      _degradado(cajaPecho.topLeft, cajaPecho.bottomRight, const [
        Color(0xFFC3D0D9),
        Color(0xFF8A9CA9),
        Color(0xFF5E707D),
      ]),
    )
    ..drawLine(
      Offset(x(-.39), y(.716)),
      Offset(x(.39), y(.716)),
      _borde(Colors.white.withValues(alpha: .55), ancho * .012),
    )
    ..drawPath(pecho, borde)
    ..drawPath(ventilas, _borde(const Color(0xFF151C21), alto * .009))
    ..drawPath(remaches, Paint()..color = _aceroOscuro)
    ..drawPath(
      brilloRemaches,
      Paint()..color = Colors.white.withValues(alpha: .7),
    );

  // El reactor del pecho, que late: el aro de metal con tornillos y el
  // nucleo que brilla.
  final nucleo = Offset(pies.dx, y(.645));
  final late = .6 + .4 * math.sin(tiempo * 5);
  _resplandor(
    canvas,
    nucleo,
    ancho * .32,
    const Color(0xFFFFD54F).withValues(alpha: .42 * late),
  );
  final tornillos = Path();
  for (var k = 0; k < 4; k++) {
    final a = math.pi / 4 + k * math.pi / 2;
    tornillos.addOval(
      Rect.fromCircle(
        center: nucleo + Offset(math.cos(a), math.sin(a)) * ancho * .112,
        radius: ancho * .012,
      ),
    );
  }
  canvas
    ..drawCircle(
      nucleo,
      ancho * .13,
      Paint()
        ..shader = ui.Gradient.radial(
          nucleo - Offset(ancho * .04, ancho * .04),
          ancho * .16,
          const [_cromo, Color(0xFF7D8B95)],
        ),
    )
    ..drawCircle(nucleo, ancho * .13, borde)
    ..drawPath(tornillos, Paint()..color = _aceroOscuro)
    ..drawCircle(nucleo, ancho * .095, Paint()..color = const Color(0xFF151C21))
    ..drawCircle(
      nucleo,
      ancho * (.06 + .012 * late),
      Paint()
        ..shader = ui.Gradient.radial(
          nucleo,
          ancho * .075,
          const [Colors.white, Color(0xFFFFE082), Color(0xFFFFB300)],
          const [0, .45, 1],
        ),
    );

  // El cuello, las orejas y la cabeza con el visor.
  final cuello = RRect.fromLTRBR(
    x(-.09),
    y(.79),
    x(.09),
    y(.74),
    Radius.circular(ancho * .02),
  );
  canvas
    ..drawRRect(cuello, Paint()..color = _grafito)
    ..drawLine(
      Offset(x(-.08), y(.765)),
      Offset(x(.08), y(.765)),
      _borde(_acero, alto * .006),
    )
    ..drawRRect(cuello, borde);
  for (final lado in const [-1.0, 1.0]) {
    final oreja = Offset(x(lado * .215), y(.84));
    canvas
      ..drawCircle(oreja, ancho * .05, Paint()..color = _naranja)
      ..drawCircle(oreja, ancho * .05, borde)
      ..drawCircle(oreja, ancho * .02, Paint()..color = _grafito);
  }
  final cajaCabeza = Rect.fromLTRB(x(-.21), y(.905), x(.21), y(.778));
  final cabeza = RRect.fromRectAndCorners(
    cajaCabeza,
    topLeft: Radius.circular(ancho * .12),
    topRight: Radius.circular(ancho * .12),
    bottomLeft: Radius.circular(ancho * .04),
    bottomRight: Radius.circular(ancho * .04),
  );
  final visor = RRect.fromLTRBR(
    x(-.17),
    y(.865),
    x(.17),
    y(.81),
    Radius.circular(ancho * .03),
  );
  final mira = math.sin(tiempo * 1.3) * ancho * .05;
  final brilla = .75 + .25 * math.sin(tiempo * 3);
  canvas
    ..drawRRect(cabeza, chapa(cajaCabeza))
    ..drawRRect(visor, Paint()..color = const Color(0xFF0E161B))
    ..save()
    ..clipRRect(visor);
  _resplandor(
    canvas,
    Offset(pies.dx + mira, y(.8375)),
    ancho * .2,
    const Color(0xFFFFD54F).withValues(alpha: .55 * brilla),
  );
  for (final lado in const [-1.0, 1.0]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pies.dx + mira + lado * ancho * .065, y(.8375)),
          width: ancho * .075,
          height: alto * .022,
        ),
        Radius.circular(ancho * .015),
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xFFFFE082),
          Colors.white,
          brilla * .6,
        )!,
    );
  }
  canvas
    ..drawLine(
      Offset(x(-.15), y(.857)),
      Offset(x(-.02), y(.857)),
      _borde(Colors.white.withValues(alpha: .25), alto * .004),
    )
    ..restore()
    ..drawRRect(visor, borde)
    ..drawRRect(cabeza, borde);

  // La nieve en la cabeza.
  canvas.drawPath(
    Path()
      ..moveTo(x(-.17), y(.9))
      ..quadraticBezierTo(x(-.15), y(.93), x(-.08), y(.925))
      ..quadraticBezierTo(x(-.02), y(.94), x(.04), y(.928))
      ..quadraticBezierTo(x(.12), y(.932), x(.16), y(.9))
      ..quadraticBezierTo(x(0), y(.898), x(-.17), y(.9))
      ..close(),
    _degradado(Offset(0, y(.94)), Offset(0, y(.9)), const [
      Colors.white,
      Color(0xFFDCEAF3),
    ]),
  );

  // La antena, con la baliza roja que parpadea.
  final antena = Offset(x(.14), y(.995));
  final prende = (1 + math.sin(tiempo * 9)) / 2;
  canvas.drawLine(
    Offset(x(.12), y(.905)),
    antena,
    _borde(_grafito, ancho * .018),
  );
  _resplandor(
    canvas,
    antena,
    ancho * .14,
    const Color(0xFFE53935).withValues(alpha: .55 * prende),
  );
  canvas
    ..drawCircle(
      antena,
      ancho * .035,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF8E1B1B),
          const Color(0xFFFF5252),
          prende,
        )!,
    )
    ..drawCircle(antena, ancho * .035, borde);
}

/// Los brazos del robot, de los hombros a las garras, por delante del pez:
/// el brazo con su piston, el codo, el antebrazo con franjas y la garra de
/// tres dedos que se cierra sobre el pez ([agarra] de 0, suelta, a 1,
/// apretando). Arriba, las hombreras con nieve y carambanos.
void pintarBrazosRobot(
  Canvas canvas,
  Offset pies,
  double alto,
  Offset garra,
  Offset garraAtras, {
  double agarra = 1,
}) {
  final ancho = alto * .48;
  final grueso = math.max(1.0, ancho * .012);
  final borde = _borde(_tinta, grueso);
  final hombros = pies.dy - alto * .72;
  // El de la derecha agarra la panza y apunta al pez hacia la izquierda;
  // el de la izquierda agarra el lomo y apunta a la derecha.
  for (final (hombro, mano, haciaElPez) in [
    (Offset(pies.dx + ancho * .52, hombros), garraAtras, -1.0),
    (Offset(pies.dx - ancho * .52, hombros), garra, 1.0),
  ]) {
    // El codo sale hacia abajo y hacia afuera, tanto como haga falta para
    // que el brazo y el antebrazo no se estiren.
    final alcance = mano - hombro;
    final distancia = math.max(1e-6, alcance.distance);
    var afuera = Offset(-alcance.dy, alcance.dx) / distancia;
    if (afuera.dy - afuera.dx * haciaElPez < 0) afuera = -afuera;
    final tramo = ancho * .4;
    final codo =
        Offset.lerp(hombro, mano, .5)! +
        afuera *
            math.sqrt(math.max(0.0, tramo * tramo - distancia * distancia / 4));
    final brazo = _barra(hombro, codo, ancho * .17, ancho * .14);
    final d = codo - hombro;
    final n = Offset(-d.dy, d.dx) / math.max(1e-6, d.distance);
    final pistonDesde = hombro + n * ancho * .1 + d * .15;
    final pistonHasta = hombro + n * ancho * .085 + d * .85;
    canvas
      ..drawPath(brazo, _tubo(hombro, codo, ancho * .17, _chapa))
      ..drawPath(brazo, borde)
      ..drawLine(pistonDesde, pistonHasta, _borde(_tinta, ancho * .042))
      ..drawLine(pistonDesde, pistonHasta, _borde(_cromo, ancho * .024))
      ..drawLine(
        pistonDesde,
        Offset.lerp(pistonDesde, pistonHasta, .5)!,
        _borde(_grafito, ancho * .045),
      );

    // El antebrazo, mas grueso hacia la muñeca, con franjas.
    final hacia = (mano - codo) / math.max(1e-6, (mano - codo).distance);
    final muneca = mano - hacia * ancho * .04;
    final antebrazo = _barra(codo, muneca, ancho * .15, ancho * .2);
    final banda = _barra(
      Offset.lerp(codo, muneca, .66)!,
      Offset.lerp(codo, muneca, .84)!,
      ancho * .19,
      ancho * .2,
    );
    canvas.drawPath(antebrazo, _tubo(codo, muneca, ancho * .2, _chapa));
    _franjas(canvas, banda, banda.getBounds(), ancho * .035);
    canvas
      ..drawPath(banda, borde)
      ..drawPath(antebrazo, borde)
      ..drawCircle(codo, ancho * .1, Paint()..color = _grafito)
      ..drawCircle(codo, ancho * .1, borde)
      ..drawCircle(
        codo,
        ancho * .06,
        Paint()
          ..shader = ui.Gradient.radial(
            codo - Offset(ancho * .02, ancho * .02),
            ancho * .07,
            const [_aceroClaro, _acero],
          ),
      )
      ..drawCircle(codo, ancho * .06, borde);

    // La garra: la mano y tres dedos de dos partes, que al agarrar apuntan
    // al pez y se cierran.
    final adentro = Offset(haciaElPez, .45);
    final hacia2 = Offset.lerp(
      hacia,
      adentro / adentro.distance,
      agarra * .75,
    )!;
    final g = hacia2 / math.max(1e-6, hacia2.distance);
    final ng = Offset(-g.dy, g.dx);
    final palma = muneca + g * ancho * .06;
    final mano2 = _barra(
      muneca,
      palma + g * ancho * .03,
      ancho * .2,
      ancho * .17,
    );
    final dedos = Path();
    final puntas = Path();
    final nudillos = Path();
    for (final k in const [-1.0, 0.0, 1.0]) {
      final raiz = palma + ng * ancho * .065 * k;
      final d1 = _girar(g, k * (.5 - .25 * agarra));
      final nudillo = raiz + d1 * ancho * .09;
      final d2 = _girar(d1, -k * (.45 + .55 * agarra));
      final punta = nudillo + d2 * ancho * .075;
      final nn = Offset(-d2.dy, d2.dx);
      dedos
        ..ir(raiz)
        ..linea(nudillo)
        ..linea(punta);
      nudillos.addOval(Rect.fromCircle(center: nudillo, radius: ancho * .024));
      puntas
        ..ir(punta - nn * ancho * .024)
        ..linea(punta + d2 * ancho * .045)
        ..linea(punta + nn * ancho * .024)
        ..close();
    }
    canvas
      ..drawPath(mano2, Paint()..color = _grafito)
      ..drawPath(mano2, borde)
      ..drawPath(dedos, _borde(_tinta, ancho * .062))
      ..drawPath(dedos, _borde(_acero, ancho * .04))
      ..drawPath(nudillos, Paint()..color = _grafito)
      ..drawPath(puntas, Paint()..color = _cromo)
      ..drawPath(puntas, _borde(_tinta, grueso * .8));

    // La hombrera: con el filo naranja, nieve arriba y carambanos abajo.
    final caja = Rect.fromCenter(
      center: hombro - Offset(0, ancho * .02),
      width: ancho * .36,
      height: ancho * .3,
    );
    final abajoHombrera = caja.center.dy + ancho * .06;
    final hombrera = Path()
      ..moveTo(caja.left, abajoHombrera)
      ..quadraticBezierTo(caja.left, caja.top, caja.center.dx, caja.top)
      ..quadraticBezierTo(caja.right, caja.top, caja.right, abajoHombrera)
      ..quadraticBezierTo(
        caja.center.dx,
        abajoHombrera + ancho * .06,
        caja.left,
        abajoHombrera,
      )
      ..close();
    final filo = Path()
      ..moveTo(caja.left, abajoHombrera)
      ..quadraticBezierTo(
        caja.center.dx,
        abajoHombrera + ancho * .06,
        caja.right,
        abajoHombrera,
      );
    final carambanos = Path();
    for (final (f, largo) in const [
      (.25, .07),
      (.45, .1),
      (.62, .06),
      (.8, .08),
    ]) {
      final px = caja.left + caja.width * f;
      final py =
          abajoHombrera + ancho * .06 * (1 - (2 * f - 1) * (2 * f - 1)) * .9;
      carambanos
        ..moveTo(px - ancho * .014, py)
        ..lineTo(px + ancho * .014, py)
        ..lineTo(px, py + ancho * largo)
        ..close();
    }
    final nieve = Path()
      ..moveTo(caja.left + ancho * .04, caja.top + ancho * .1)
      ..quadraticBezierTo(
        caja.left + ancho * .05,
        caja.top - ancho * .03,
        caja.center.dx - ancho * .03,
        caja.top - ancho * .025,
      )
      ..quadraticBezierTo(
        caja.center.dx + ancho * .06,
        caja.top - ancho * .045,
        caja.right - ancho * .05,
        caja.top + ancho * .06,
      )
      ..quadraticBezierTo(
        caja.center.dx,
        caja.top + ancho * .03,
        caja.left + ancho * .04,
        caja.top + ancho * .1,
      )
      ..close();
    canvas
      ..drawPath(
        carambanos,
        Paint()..color = const Color(0xFFE3F2FA).withValues(alpha: .92),
      )
      ..drawPath(
        hombrera,
        _degradado(caja.topLeft, caja.bottomRight, const [
          Color(0xFFC3D0D9),
          _acero,
          _aceroOscuro,
        ]),
      )
      ..drawPath(filo, _borde(_naranja, ancho * .03))
      ..drawPath(hombrera, borde)
      ..drawCircle(
        Offset(caja.center.dx, caja.top + caja.height * .42),
        ancho * .018,
        Paint()..color = _aceroOscuro,
      )
      ..drawPath(
        nieve,
        _degradado(
          Offset(0, caja.top - ancho * .04),
          Offset(0, caja.top + ancho * .1),
          const [Colors.white, Color(0xFFDCEAF3)],
        ),
      );
  }
}
