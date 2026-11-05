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
const _cromo = Color(0xFFE3EAEE);

/// El filo de las piezas: apenas marcado, para que no se pierdan contra la
/// nieve (el volumen lo da el lustre, no un borde negro).
const _filo = Color(0x661A242B);

/// Para armar caminos con puntos.
extension _Trazo on Path {
  void ir(Offset p) => moveTo(p.dx, p.dy);
  void linea(Offset p) => lineTo(p.dx, p.dy);
  void curva(Offset control, Offset p) =>
      quadraticBezierTo(control.dx, control.dy, p.dx, p.dy);
  void cubica(Offset c1, Offset c2, Offset p) =>
      cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p.dx, p.dy);
}

/// El lustre de una pieza pintada o de metal: la luz del sol arriba, el
/// reflejo celeste del cielo del lado de la sombra (a la derecha, o abajo si
/// [reflejoAbajo]) y la sombra de abajo. Se pinta encima, sobre la misma
/// [forma] ([caja] la encierra): le da volumen sin borde oscuro.
extension _Lustre on Canvas {
  void lustre(
    Path forma,
    Rect caja, {
    double fuerza = 1,
    bool reflejoAbajo = false,
    bool sombra = true,
  }) {
    const cielo = Color(0xFFBFE6FF);
    drawPath(
      forma,
      _degradado(
        caja.topCenter,
        Offset(caja.center.dx, caja.top + caja.height * .42),
        [
          Colors.white.withValues(alpha: .34 * fuerza),
          Colors.white.withValues(alpha: 0),
        ],
      ),
    );
    drawPath(
      forma,
      reflejoAbajo
          ? _degradado(
              caja.bottomCenter,
              Offset(caja.center.dx, caja.bottom - caja.height * .3),
              [
                cielo.withValues(alpha: .34 * fuerza),
                cielo.withValues(alpha: 0),
              ],
            )
          : _degradado(
              caja.centerRight,
              Offset(caja.right - caja.width * .3, caja.center.dy),
              [
                cielo.withValues(alpha: .34 * fuerza),
                cielo.withValues(alpha: 0),
              ],
            ),
    );
    if (sombra) {
      drawPath(
        forma,
        _degradado(
          caja.bottomCenter,
          Offset(caja.center.dx, caja.bottom - caja.height * .38),
          [
            Colors.black.withValues(alpha: .2 * fuerza),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      );
    }
  }
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

// ------------------------------------------------------------------ el pez

/// Un pez colgado de la boca, recien sacado del agua: la boca abierta
/// arriba, en [boca] (de ahi tira el hilo), y el cuerpo colgando, con el
/// lomo a la izquierda y la panza a la derecha.
///
/// Brilla mojado: la luz del sol le pega arriba a la izquierda (el brillo
/// largo del lomo, las escamas que se ven solo de ese lado), la panza queda
/// en sombra con el reflejo celeste del cielo en el borde, y las aletas son
/// translucidas, con la luz que pasa a traves. Al patalear, una ola le
/// recorre el cuerpo de la cabeza a la cola ([pataleo] de 0, quieto, a 1,
/// peleando; [ritmo] en olas por segundo), y boquea. [giro] lo gira entero
/// desde la boca. Con [anzuelo] se le ve el anzuelo de la caña en el labio.
void pintarPezColgado(
  Canvas canvas,
  Offset boca,
  double largo,
  double grosor,
  Pez pez, {
  double giro = 0,
  double pataleo = 0,
  double ritmo = 1.5,
  double tiempo = 0,
  bool anzuelo = false,
}) {
  if (largo < 6) return;
  final (lomo, flanco, panza) = ColoresPesca.dePez(pez);
  final oscuro = Color.lerp(lomo, Colors.black, .35)!;
  final ancho = largo * grosor;
  final rayo = _borde(
    Colors.white.withValues(alpha: .26),
    math.max(.5, ancho * .01),
  );
  // La ola: nada en la cabeza, cada vez mas hacia la cola.
  final fase = 2 * math.pi * ritmo * tiempo;
  double envolvente(double u) {
    final s = ((u - .22) / .78).clamp(0.0, 1.0);
    return s * s;
  }

  double ola(double u) =>
      pataleo *
      largo *
      .08 *
      envolvente(u) *
      math.sin(2 * math.pi * 1.1 * u - fase);
  // Un punto del pez: [u] a lo largo (0 la boca, 1 la cola) y [v] a lo
  // ancho (negativo del lado del lomo).
  Offset q(double u, double v) => Offset(v * ancho + ola(u), u * largo);

  canvas
    ..save()
    ..translate(boca.dx, boca.dy)
    ..rotate(giro);

  // La cola, de horquilla: sigue la ola del cuerpo y se dobla un poco mas.
  final nace = q(.83, 0);
  final pendiente = (ola(.86) - ola(.8)) / (largo * .06);
  final anguloCola =
      -math.atan(pendiente) -
      pataleo * .3 * math.sin(2 * math.pi * 1.1 * .9 - fase - .8);
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
  final luzDeAleta = Color.lerp(flanco, Colors.white, .35)!;
  canvas
    ..save()
    ..translate(nace.dx, nace.dy)
    ..rotate(anguloCola)
    ..drawPath(
      aletaCola,
      _degradado(
        Offset(-puntaCola, 0),
        Offset(puntaCola, largoCola),
        [
          lomo.withValues(alpha: .95),
          flanco.withValues(alpha: .85),
          luzDeAleta.withValues(alpha: .6),
        ],
        const [0, .5, 1],
      ),
    )
    ..drawPath(rayosCola, rayo)
    ..drawPath(aletaCola, _borde(oscuro.withValues(alpha: .35), ancho * .008))
    ..restore();

  // Las aletas de atras del cuerpo, que ondean: la del lomo con espinas y
  // las de la panza. Translucidas: mas claras en las puntas, donde pasa la
  // luz.
  final ondea = math.sin(tiempo * 5) * .015 + pataleo * .02 * math.sin(fase);
  final dorsal = Path()
    ..ir(q(.2, -.4))
    ..linea(q(.245, -.63 + ondea))
    ..curva(q(.262, -.585), q(.28, -.57))
    ..linea(q(.305, -.67 + ondea))
    ..curva(q(.322, -.61), q(.34, -.595))
    ..linea(q(.365, -.66 + ondea))
    ..curva(q(.382, -.6), q(.4, -.59))
    ..linea(q(.425, -.63 + ondea))
    ..curva(q(.442, -.58), q(.46, -.565))
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
    Color.lerp(lomo, flanco, .35)!.withValues(alpha: .9),
    luzDeAleta.withValues(alpha: .55),
  ]);
  final filoAleta = _borde(oscuro.withValues(alpha: .3), ancho * .008);
  canvas
    ..drawPath(
      dorsal,
      _degradado(q(.4, -.4), q(.4, -.68), [
        lomo.withValues(alpha: .95),
        luzDeAleta.withValues(alpha: .6),
      ]),
    )
    ..drawPath(espinas, _borde(oscuro.withValues(alpha: .4), ancho * .011))
    ..drawPath(dorsal, filoAleta)
    ..drawPath(anal, aletaPanza)
    ..drawPath(pelvica, aletaPanza)
    ..drawPath(rayosPanza, rayo)
    ..drawPath(anal, filoAleta)
    ..drawPath(pelvica, filoAleta);

  // El cuerpo: oscuro en el lomo y claro en la panza, como los peces de
  // verdad.
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
        [oscuro, lomo, flanco, flanco, panza],
        const [0, .14, .42, .6, .92],
      ),
    )
    ..save()
    ..clipPath(cuerpo);

  // El dibujo de cada especie: pintas claras, franjas de koi o motas de
  // oro.
  final marcas = Path();
  final colorMarcas = switch (pez) {
    Pez.azulitos => Colors.white.withValues(alpha: .36),
    Pez.naranjotes => Color.lerp(
      lomo,
      Colors.black,
      .25,
    )!.withValues(alpha: .42),
    Pez.rojazos => const Color(0xFFFFD86B).withValues(alpha: .62),
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
        marcas.addOval(Rect.fromCircle(center: q(u, v), radius: ancho * .026));
      }
  }
  canvas.drawPath(marcas, Paint()..color = colorMarcas);

  // Las escamas, como tejas hacia la cola: se ven del lado del sol y se
  // pierden en la sombra.
  if (ancho > 14) {
    final paso = ancho * .12;
    final escamas = Path();
    var fila = 0;
    for (var y = largo * .27; y < largo * .84; y += paso * .72) {
      final corrido = fila.isOdd ? paso * .5 : 0.0;
      final medio = q(y / largo, 0).dx;
      for (var x = -ancho * .5 + corrido; x < ancho * .5; x += paso) {
        escamas.addArc(
          Rect.fromCircle(center: Offset(medio + x, y), radius: paso * .55),
          .15,
          math.pi - .3,
        );
      }
      fila++;
    }
    canvas.drawPath(
      escamas,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, ancho * .012)
        ..shader = ui.Gradient.linear(
          q(.4, -.5),
          q(.4, .35),
          [
            Colors.white.withValues(alpha: .3),
            Colors.white.withValues(alpha: .1),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, .45, 1],
        ),
    );
  }

  // La sombra de la panza (el sol le pega del otro lado), con el reflejo
  // celeste del cielo en el borde; el filo del lomo, mas oscuro.
  final todo = Rect.fromLTRB(-ancho * 1.4, -largo * .05, ancho * 1.4, largo);
  canvas
    ..drawRect(
      todo,
      _degradado(q(.4, .02), q(.4, .5), [
        Colors.black.withValues(alpha: 0),
        Colors.black.withValues(alpha: .3),
      ]),
    )
    ..drawPath(
      cuerpo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ancho * .07
        ..shader = ui.Gradient.linear(q(.4, .2), q(.4, .5), [
          const Color(0xFFBFE6FF).withValues(alpha: 0),
          const Color(0xFFBFE6FF).withValues(alpha: .4),
        ]),
    )
    ..drawRect(
      todo,
      _degradado(q(.4, -.5), q(.4, -.32), [
        Colors.black.withValues(alpha: .22),
        Colors.black.withValues(alpha: 0),
      ]),
    );
  // El brillo largo del lomo, mojado: suave en los bordes.
  final brillo = Path()
    ..ir(q(.1, -.3))
    ..cubica(q(.25, -.38), q(.45, -.35), q(.64, -.2))
    ..cubica(q(.47, -.26), q(.27, -.26), q(.1, -.3))
    ..close();
  canvas
    ..drawPath(
      brillo,
      _degradado(
        q(.35, -.42),
        q(.35, -.2),
        [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: .44),
          Colors.white.withValues(alpha: 0),
        ],
        const [0, .45, 1],
      ),
    )
    ..drawPath(
      Path()
        ..ir(q(.14, -.31))
        ..cubica(q(.25, -.355), q(.4, -.34), q(.5, -.27)),
      _borde(Colors.white.withValues(alpha: .55), ancho * .018),
    )
    // La linea del costado.
    ..drawPath(
      Path()
        ..ir(q(.25, -.07))
        ..curva(q(.52, -.13), q(.82, -.01)),
      _borde(Colors.white.withValues(alpha: .2), math.max(.5, ancho * .013)),
    );
  // La agalla: la tapa, que se abre un poco cuando boquea, con su sombra y
  // el filo de luz.
  final abre = .5 + .5 * math.sin(tiempo * 3.8);
  final agalla = Path()
    ..ir(q(.17, -.43))
    ..curva(q(.32 + .015 * (1 - abre), -.02), q(.2, .45));
  canvas
    ..drawPath(
      agalla.shift(Offset(0, largo * .014)),
      _borde(Colors.black.withValues(alpha: .1), ancho * .06),
    )
    ..drawPath(agalla, _borde(oscuro.withValues(alpha: .35), ancho * .012))
    ..drawPath(
      agalla.shift(Offset(0, -largo * .006)),
      _borde(Colors.white.withValues(alpha: .25), ancho * .012),
    )
    ..restore()
    // El filo del cuerpo, apenas: que no se pierda contra la nieve.
    ..drawPath(cuerpo, _borde(oscuro.withValues(alpha: .4), ancho * .01));

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
    ..rotate(math.sin(tiempo * 6) * .2 - pataleo * .25 * math.sin(fase))
    ..drawPath(
      pectoral,
      _degradado(Offset.zero, Offset(ancho * .1, ancho * .4), [
        Color.lerp(lomo, flanco, .3)!.withValues(alpha: .85),
        luzDeAleta.withValues(alpha: .5),
      ]),
    )
    ..drawPath(rayosPectoral, rayo)
    ..drawPath(pectoral, filoAleta)
    ..restore();

  // El ojo: brillante como una bolita, con la sombra de la cuenca arriba y
  // el iris que mira para arriba (al anzuelo).
  final ojo = q(.11, -.15);
  final radio = math.max(1.5, ancho * .11);
  canvas
    ..drawCircle(
      ojo + Offset(0, -radio * .12),
      radio * 1.25,
      Paint()
        ..shader = ui.Gradient.radial(ojo, radio * 1.3, [
          oscuro.withValues(alpha: .55),
          oscuro.withValues(alpha: 0),
        ]),
    )
    ..drawCircle(
      ojo,
      radio,
      Paint()
        ..shader = ui.Gradient.radial(
          ojo - Offset(radio * .3, radio * .35),
          radio * 1.2,
          const [Colors.white, Color(0xFFE6ECF0), Color(0xFFB7C3CC)],
          const [0, .6, 1],
        ),
    )
    ..drawCircle(
      ojo + Offset(0, -radio * .14),
      radio * .66,
      Paint()
        ..shader =
            ui.Gradient.radial(ojo + Offset(0, -radio * .05), radio * .66, [
              Color.lerp(const Color(0xFFE0A53A), lomo, .35)!,
              Color.lerp(lomo, Colors.black, .45)!,
            ]),
    )
    ..drawCircle(
      ojo + Offset(0, -radio * .2),
      radio * .38,
      Paint()..color = const Color(0xFF0B141B),
    )
    ..drawCircle(
      ojo + Offset(radio * .26, -radio * .44),
      radio * .3,
      Paint()
        ..shader = ui.Gradient.radial(
          ojo + Offset(radio * .26, -radio * .44),
          radio * .3,
          [
            Colors.white,
            Colors.white.withValues(alpha: .9),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, .7, 1],
        ),
    )
    ..drawCircle(
      ojo + Offset(-radio * .22, radio * .3),
      radio * .1,
      Paint()..color = Colors.white.withValues(alpha: .7),
    );

  // La boca abierta, arriba, que boquea: los labios carnosos y oscura
  // adentro.
  final labioArriba = q(.004 - .004 * abre, -.085 - .01 * abre);
  final labioAbajo = q(.03 + .008 * abre, .095 + .05 * abre);
  final comisura = q(.1, 0);
  final hueco = Path()
    ..ir(labioArriba)
    ..curva(q(.06, -.06), comisura)
    ..curva(q(.075, .07 + .03 * abre), labioAbajo)
    ..curva(q(0, .02), labioArriba)
    ..close();
  final colorLabio = Color.lerp(panza, const Color(0xFFF08A95), .4)!;
  final labio = _borde(colorLabio, math.max(1.2, ancho * .055));
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
        ..curva(q(.075, .07 + .03 * abre), labioAbajo),
      labio,
    )
    ..drawPath(
      hueco,
      _degradado(q(0, .02), comisura, const [
        Color(0xFF6A1420),
        Color(0xFF1C0306),
      ]),
    )
    ..drawPath(
      Path()
        ..ir(q(.006, -.105))
        ..curva(q(.04, -.1), q(.06, -.075)),
      _borde(Colors.white.withValues(alpha: .5), ancho * .012),
    );

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
      ..drawPath(gancho, _borde(const Color(0xFF4A5862), t * .17))
      ..drawPath(gancho, _borde(plata, t * .08))
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
/// del todo). Brilla mojada como el pez: la luz del sol a la izquierda, la
/// sombra y el reflejo del cielo a la derecha.
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
  final oscuro = Color.lerp(lomo, Colors.black, .35)!;
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
    // Las aletas de los costados, translucidas, que abanican.
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
    final luz = Color.lerp(flanco, Colors.white, .35)!;
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
            lomo.withValues(alpha: .95),
            luz.withValues(alpha: .55),
          ]),
        )
        ..drawPath(
          rayos,
          _borde(
            Colors.white.withValues(alpha: .28),
            math.max(.6, ancho * .008),
          ),
        )
        ..drawPath(aleta, _borde(oscuro.withValues(alpha: .3), ancho * .007))
        ..restore();
    }
    if (abre <= .04) return;
    // El fondo de la boca: oscuro hacia la garganta, mojado arriba.
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
          const [Color(0xFF14020A), Color(0xFF4A0A14), Color(0xFF9A2234)],
          const [0, .55, 1],
        ),
    );
    // La lengua, con su brillo.
    final lengua = Rect.fromCenter(
      center: Offset(base.dx, garganta - alto * .06 * abre),
      width: labio * .8,
      height: alto * .16 * abre,
    );
    canvas
      ..drawOval(
        lengua,
        _degradado(lengua.topCenter, lengua.bottomCenter, const [
          Color(0xFFEF8A97),
          Color(0xFFB23446),
        ]),
      )
      ..drawOval(
        Rect.fromCenter(
          center:
              lengua.center - Offset(lengua.width * .15, lengua.height * .2),
          width: lengua.width * .35,
          height: lengua.height * .25,
        ),
        Paint()..color = Colors.white.withValues(alpha: .3),
      );
    // Los dientes de atras, colgando del labio de arriba: en la sombra.
    final dientes = Path();
    final tam = ancho * .034 * abre;
    for (var k = 1; k < 8; k++) {
      final f = k / 8;
      final g = 1 - f;
      final p = izquierda * (g * g) + lejos * (2 * g * f) + derecha * (f * f);
      dientes
        ..moveTo(p.dx - tam * .5, p.dy - 1)
        ..quadraticBezierTo(
          p.dx - tam * .2,
          p.dy + tam * .6,
          p.dx,
          p.dy + tam * 1.1,
        )
        ..quadraticBezierTo(
          p.dx + tam * .2,
          p.dy + tam * .6,
          p.dx + tam * .5,
          p.dy - 1,
        )
        ..close();
    }
    canvas
      ..drawPath(dientes, Paint()..color = const Color(0xFFD9CFC2))
      ..drawPath(
        Path()
          ..ir(izquierda)
          ..curva(lejos, derecha),
        _borde(Color.lerp(flanco, lomo, .3)!, math.max(1.0, ancho * .024)),
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
        [lomo, flanco, panza, flanco, oscuro],
        const [0, .2, .45, .75, 1],
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
        .15,
        math.pi - .3,
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
  final luz = Path()
    ..moveTo(base.dx - mitad * .78, base.dy)
    ..quadraticBezierTo(
      base.dx - mitad * .9,
      base.dy - alto * .5,
      base.dx - labio * .78,
      puntaLabio + alto * .14,
    );
  canvas
    ..drawPath(
      escamas,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, ancho * .007)
        ..shader = ui.Gradient.linear(
          caja.centerLeft,
          caja.centerRight,
          [
            Colors.white.withValues(alpha: .26),
            Colors.white.withValues(alpha: .14),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, .5, 1],
        ),
    )
    // Redonda: sombra en los costados (mas del lado de la sombra) y el
    // reflejo celeste del cielo en el borde derecho.
    ..drawRect(
      caja,
      _degradado(
        caja.centerLeft,
        caja.centerRight,
        [
          Colors.black.withValues(alpha: .22),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: .34),
        ],
        const [0, .22, .62, 1],
      ),
    )
    ..drawPath(
      cara,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ancho * .05
        ..shader = ui.Gradient.linear(
          Offset(base.dx + mitad * .6, 0),
          Offset(base.dx + mitad, 0),
          [
            const Color(0xFFBFE6FF).withValues(alpha: 0),
            const Color(0xFFBFE6FF).withValues(alpha: .38),
          ],
        ),
    )
    ..drawPath(agallas, _borde(oscuro.withValues(alpha: .45), ancho * .012))
    // La luz del sol, mojada, sobre el costado izquierdo.
    ..drawPath(
      luz,
      _degradado(
          Offset(base.dx - mitad * 1.02, 0),
          Offset(base.dx - mitad * .58, 0),
          [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .3),
            Colors.white.withValues(alpha: 0),
          ],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = ancho * .09
        ..strokeCap = StrokeCap.round,
    )
    ..drawPath(luz, _borde(Colors.white.withValues(alpha: .45), ancho * .014))
    ..restore()
    ..drawPath(cara, _borde(oscuro.withValues(alpha: .4), ancho * .008));

  // Los dientes de adelante, sobre el labio, con su sombra.
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
        final medio = p + n * tam * .6;
        dientes
          ..ir(a)
          ..curva(medio - t * tam * .12, c)
          ..curva(medio + t * tam * .12, b)
          ..close();
      }
    }
    canvas
      ..drawPath(
        dientes.shift(Offset(tam * .08, tam * .1)),
        Paint()..color = Colors.black.withValues(alpha: .3),
      )
      ..drawPath(
        dientes,
        _degradado(
          Offset(base.dx - labio, 0),
          Offset(base.dx + labio, 0),
          const [Colors.white, Color(0xFFF1ECE3), Color(0xFFD2C9BC)],
        ),
      );
  }
  // El labio de adelante, carnoso y con brillo.
  final labioDeAdelante = Path()
    ..ir(izquierda)
    ..curva(controlIzquierdo, fondo)
    ..curva(controlDerecho, derecha);
  final colorLabio = Color.lerp(panza, const Color(0xFFF08A95), .35)!;
  canvas
    ..drawPath(
      labioDeAdelante.shift(Offset(0, ancho * .012)),
      _borde(Color.lerp(colorLabio, Colors.black, .35)!, ancho * .04),
    )
    ..drawPath(labioDeAdelante, _borde(colorLabio, ancho * .036))
    ..drawPath(
      labioDeAdelante.shift(Offset(0, -ancho * .009)),
      _borde(Colors.white.withValues(alpha: .5), ancho * .009),
    );

  // Los ojos, brillantes, que miran al chico, con el parpado en diagonal:
  // cara de hambre.
  for (final lado in const [-1.0, 1.0]) {
    final ojo = Offset(base.dx + lado * mitad * .6, arriba + alto * .5);
    final radio = ancho * .08;
    final afuera = lado < 0 ? .7 : .32;
    final adentroDelOjo = lado < 0 ? .32 : .7;
    canvas
      ..drawCircle(
        ojo,
        radio * 1.32,
        Paint()
          ..shader = ui.Gradient.radial(
            ojo,
            radio * 1.32,
            [oscuro.withValues(alpha: .7), oscuro.withValues(alpha: 0)],
            const [.7, 1],
          ),
      )
      ..drawCircle(
        ojo,
        radio,
        Paint()
          ..shader = ui.Gradient.radial(
            ojo - Offset(radio * .3, radio * .35),
            radio * 1.2,
            const [Colors.white, Color(0xFFE6ECF0), Color(0xFFB7C3CC)],
            const [0, .6, 1],
          ),
      )
      ..drawCircle(
        ojo + Offset(-lado * radio * .25, -radio * .1),
        radio * .62,
        Paint()
          ..shader = ui.Gradient.radial(
            ojo + Offset(-lado * radio * .25, -radio * .1),
            radio * .62,
            [
              const Color(0xFFF5C542),
              Color.lerp(const Color(0xFFF5C542), lomo, .55)!,
            ],
          ),
      )
      ..drawCircle(
        ojo + Offset(-lado * radio * .3, -radio * .12),
        radio * .36,
        Paint()..color = const Color(0xFF0B141B),
      )
      ..drawCircle(
        ojo + Offset(-lado * radio * .08, -radio * .32),
        radio * .17,
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
        _degradado(Offset(ojo.dx, ojo.dy - radio), Offset(ojo.dx, ojo.dy), [
          Color.lerp(flanco, Colors.white, .15)!,
          flanco,
        ]),
      )
      ..drawLine(
        izquierdo,
        derecho,
        _borde(oscuro.withValues(alpha: .8), ancho * .012),
      )
      ..restore();
  }
}

// ----------------------------------------------------------------- la caña

/// Donde esta la perilla de la manivela del carrete (la agarra la mano de
/// MacIAs), para la caña que va de [mango] a [baseCana] y la manivela girada
/// [vuelta]. Es la misma cuenta que usa [pintarCana] para dibujarla.
Offset perillaCarrete(Offset mango, Offset baseCana, double vuelta, double h) {
  final s = h / 900;
  final d = (baseCana - mango) / math.max(1e-6, (baseCana - mango).distance);
  final centro = Offset.lerp(mango, baseCana, .51)!;
  final local =
      const Offset(-1, 15) +
      Offset(math.cos(vuelta + 2.4), math.sin(vuelta + 2.4)) * 10;
  return centro + _girar(local * s, math.atan2(d.dy, d.dx));
}

/// La caña en las manos de MacIAs: la culata con su tapa, el mango de goma,
/// el portacarrete con el carrete (la manivela gira mientras recoge, segun
/// [vuelta]), el corcho y la caña roja que se afina hasta la punta naranja,
/// con sus pasahilos y el hilo que corre por ellos. [tension] la dobla: 0
/// casi derecha, 1 doblada por el peso. [hilo] es lo grueso del hilo.
void pintarCana(
  Canvas canvas,
  Offset mango,
  Offset baseCana,
  Offset punta,
  double tension,
  double vuelta,
  double w,
  double h, {
  double hilo = 1.4,
}) {
  final s = h / 900;
  final largoMango = math.max(1e-6, (baseCana - mango).distance);
  final d = (baseCana - mango) / largoMango;
  // Del lado de abajo de la caña (hacia el hoyo) van el carrete y los
  // pasahilos.
  final abajo = Offset(-d.dy, d.dx);
  Offset enMango(double f) => mango + d * largoMango * f;
  final filo = _borde(const Color(0x991A242B), .8 * s);

  // La caña, de la base a la punta: sale derecha del mango y se dobla al
  // final, hacia donde tira el pez.
  final cuerda = (punta - baseCana).distance;
  final angulo = ui.lerpDouble(-1.08, -.17, tension)!;
  final c1 = baseCana + d * cuerda * .36;
  final c2 = punta - Offset(math.cos(angulo), math.sin(angulo)) * cuerda * .3;
  Offset enCana(double t) {
    final g = 1 - t;
    return baseCana * (g * g * g) +
        c1 * (3 * g * g * t) +
        c2 * (3 * g * t * t) +
        punta * (t * t * t);
  }

  Offset normal(double t) {
    final g = 1 - t;
    final v =
        (c1 - baseCana) * (3 * g * g) +
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

  // La culata con su tapa de goma, y el mango de goma con sus anillos.
  final tapa = mango - d * 2.5 * s;
  final goma = _barra(tapa, enMango(.38), 8.4 * s, 7.4 * s);
  final anillos = Path();
  for (final f in const [.1, .2, .3]) {
    final p = enMango(f);
    anillos
      ..ir(p - abajo * 3.9 * s)
      ..linea(p + abajo * 3.9 * s);
  }
  canvas
    ..drawPath(
      goma,
      _tubo(tapa, enMango(.38), 8.4 * s, const [
        Color(0xFF5E646C),
        Color(0xFF2C3036),
        Color(0xFF15181C),
      ]),
    )
    ..drawPath(anillos, _borde(Colors.black.withValues(alpha: .35), 1 * s))
    ..drawPath(
      _barra(tapa - d * 1.6 * s, tapa + d * 1.4 * s, 9.6 * s, 9.6 * s),
      _tubo(tapa, tapa + d, 9.6 * s, _metalOscuro),
    );

  // El portacarrete, con sus anillos, y el mango de corcho con pintas.
  final asientoDesde = enMango(.38);
  final asientoHasta = enMango(.64);
  final asiento = _barra(asientoDesde, asientoHasta, 6.4 * s, 6.4 * s);
  canvas.drawPath(
    asiento,
    _tubo(asientoDesde, asientoHasta, 6.4 * s, const [
      Color(0xFF8A96A0),
      Color(0xFF3E474F),
      Color(0xFF1D2328),
    ]),
  );
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
  final corchoHasta = baseCana + d * 3 * s;
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
        Color(0xFFEACFA2),
        Color(0xFFC9A26B),
        Color(0xFF8E6639),
      ]),
    )
    ..drawPath(
      pintas,
      Paint()..color = const Color(0xFF7A5530).withValues(alpha: .6),
    );

  // La caña roja, brillante, que se afina; la punta naranja con una franja
  // blanca.
  final cana = tramo(0, 1, 28);
  canvas
    ..drawPath(cana, Paint()..color = const Color(0xFFB0242F))
    ..drawPath(tramo(.87, 1, 6), Paint()..color = const Color(0xFFFF8A3D))
    ..drawPath(tramo(.91, .935, 2), Paint()..color = Colors.white)
    ..drawPath(cana, _borde(const Color(0x993A1218), .8 * s));
  final brillo = Path()..ir(enCana(0) - normal(0) * gruesoEn(0) * .22);
  final sombra = Path()..ir(enCana(0) + normal(0) * gruesoEn(0) * .3);
  for (var i = 1; i <= 16; i++) {
    final t = i / 16 * .86;
    brillo.linea(enCana(t) - normal(t) * gruesoEn(t) * .22);
    sombra.linea(enCana(t) + normal(t) * gruesoEn(t) * .3);
  }
  canvas
    ..drawPath(
      sombra,
      _borde(const Color(0xFF6E0F1A).withValues(alpha: .8), 1.2 * s),
    )
    ..drawPath(
      brillo,
      _borde(const Color(0xFFFF9AA3).withValues(alpha: .85), 1.1 * s),
    )
    // El anillo donde termina el corcho.
    ..drawLine(
      baseCana - abajo * 3.4 * s,
      baseCana + abajo * 3.4 * s,
      Paint()
        ..strokeWidth = 2 * s
        ..color = _cromo,
    );

  // Los pasahilos: anillos de metal del lado de abajo, con su atadura.
  final pasos = <Offset>[];
  final ataduras = Path();
  final patas = Path();
  final aros = Path();
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
    aros.addOval(Rect.fromCircle(center: anillo, radius: r));
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
    ..drawPath(aros, _borde(const Color(0xFF4A5862), 2 * s))
    ..drawPath(aros, _borde(_cromo, 1 * s));

  // El carrete, colgando del portacarrete del lado de abajo: la pata, el
  // cuerpo, la bobina con hilo, el arco y la manivela que gira.
  final centroCarrete = enMango(.51);
  final salida = centroCarrete + d * 12.5 * s + abajo * 9.5 * s;
  canvas
    ..save()
    ..translate(centroCarrete.dx, centroCarrete.dy)
    ..rotate(math.atan2(d.dy, d.dx))
    ..scale(s);
  final cuerpo = RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(-1, 15), width: 15, height: 12),
    const Radius.circular(4.5),
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
      _degradado(const Offset(-8, 9), const Offset(6, 21), const [
        Color(0xFF8A96A0),
        Color(0xFF3E474F),
        Color(0xFF1D2328),
      ]),
    )
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
    ..drawRRect(bobina, _borde(const Color(0x991A242B), .8))
    ..drawPath(
      Path()
        ..moveTo(12.5, 8.5)
        ..quadraticBezierTo(16.5, 15, 12.5, 21.5),
      _borde(_cromo, 1.3),
    )
    ..drawLine(const Offset(-1, 15), manivela, _borde(_grafito, 3.2))
    ..drawLine(const Offset(-1, 15), manivela, _borde(_cromo, 1.4))
    ..drawCircle(manivela, 2.7, Paint()..color = const Color(0xFFF1E3C6))
    ..drawCircle(const Offset(-1, 15), 1.6, Paint()..color = _cromo)
    ..restore()
    ..drawPath(goma, filo)
    ..drawPath(corcho, filo);

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
}

// ----------------------------------------------------------------- la grua

/// El gancho al final del cable: el moton amarillo con franjas, el
/// giratorio y el gancho de acero, con la carga colgando en [donde].
void pintarGancho(Canvas canvas, Offset donde, double tam) {
  final borde = _borde(_filo, math.max(.7, tam * .07));
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
  final borde = _borde(_filo, grueso * .7);
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
    ..lustre(Path()..addRRect(cubierta), cajaCubierta)
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
    ..lustre(cabina, cajaCabina)
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
    _borde(_filo, grueso * .6),
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
    ..lustre(Path()..addRRect(casilla), cajaCasilla)
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
  canvas
    ..drawPath(operador, pintura(cajaOperador))
    ..lustre(operador, cajaOperador);
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
    _borde(_filo, grueso * .6),
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
      ..lustre(Path()..addRect(caja), caja, reflejoAbajo: true)
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
    ..drawOval(
      disco,
      _degradado(disco.centerLeft, disco.centerRight, [
        _tinta.withValues(alpha: .16),
        _tinta.withValues(alpha: .04),
        _tinta.withValues(alpha: .16),
      ]),
    )
    ..drawOval(disco, _borde(Colors.white.withValues(alpha: .18), alto * .06));
  for (final (atras, alfa) in const [
    (.42, .1),
    (.28, .16),
    (.14, .26),
    (0.0, .6),
  ]) {
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
  final borde = _borde(_filo, grueso * .7);
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
    ..lustre(botalon, botalon.getBounds(), reflejoAbajo: true)
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
    ..lustre(deriva, deriva.getBounds())
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
    ..lustre(cuerpo, cuerpo.getBounds(), reflejoAbajo: true)
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
    _borde(_filo, grueso * .6),
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
  final borde = _borde(_filo, grueso * .7);
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
    ..lustre(torre, torre.getBounds())
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
    ..lustre(cuerpo, cuerpo.getBounds(), reflejoAbajo: true)
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
    _borde(_filo, grueso * .6),
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
    _borde(_filo, grueso * .6),
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
    ..lustre(joroba, joroba.getBounds())
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

// El robot: acero oscuro azulado. Las caras que miran al sol (a la
// izquierda) mas claras que las que quedan en sombra; franjas amarillas de
// peligro y luces ambar.
const _caraLuz = Color(0xFF5A6D82);
const _caraFrente = Color(0xFF3F4E60);
const _caraSombra = Color(0xFF2A3644);
const _mecanica = Color(0xFF222A34);
const _ambar = Color(0xFFFFB23E);
const _ambarClaro = Color(0xFFFFF0C2);

/// Una placa del blindaje: el acero con su degradado, la luz de la nieve que
/// rebota desde abajo, el reflejo del cielo arriba y los filos biselados
/// (claros los de arriba a la izquierda, oscuros los de abajo a la derecha).
void _placa(
  Canvas canvas,
  Path forma, {
  Color base = _caraFrente,
  double bisel = 1.5,
}) {
  final caja = forma.getBounds();
  final claro = Color.lerp(base, const Color(0xFFA9BCCF), .45)!;
  final oscuro = Color.lerp(base, const Color(0xFF10161D), .55)!;
  const nieve = Color(0xFFD7ECFA);
  const cielo = Color(0xFFBFE6FF);
  canvas
    ..drawPath(
      forma,
      _degradado(
        caja.topLeft,
        caja.bottomRight,
        [claro, base, oscuro],
        const [0, .45, 1],
      ),
    )
    ..drawPath(
      forma,
      _degradado(
        caja.bottomCenter,
        Offset(caja.center.dx, caja.bottom - caja.height * .32),
        [nieve.withValues(alpha: .26), nieve.withValues(alpha: 0)],
      ),
    )
    ..drawPath(
      forma,
      _degradado(
        caja.topCenter,
        Offset(caja.center.dx, caja.top + caja.height * .3),
        [cielo.withValues(alpha: .28), cielo.withValues(alpha: 0)],
      ),
    )
    ..drawPath(
      forma,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bisel
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(caja.topLeft, caja.center, [
          Colors.white.withValues(alpha: .62),
          Colors.white.withValues(alpha: 0),
        ]),
    )
    ..drawPath(
      forma,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bisel
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(caja.center, caja.bottomRight, [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: .6),
        ]),
    );
}

Path _poligono(List<Offset> puntos) => Path()..addPolygon(puntos, true);

/// Nieve encima de una pieza: una capa blanda que sigue el borde de arriba
/// (de [izquierda] a [derecha], con [alto] de grosor), con su sombra celeste.
void _nieveEncima(
  Canvas canvas,
  Offset izquierda,
  Offset derecha,
  double alto, {
  double comba = 0,
}) {
  final medio = Offset.lerp(izquierda, derecha, .5)! + Offset(0, -comba);
  final nieve = Path()
    ..ir(izquierda + Offset(0, alto * .2))
    ..cubica(
      izquierda + Offset(0, -alto * .9),
      Offset.lerp(izquierda, medio, .5)! + Offset(0, -alto * 1.3),
      medio + Offset(0, -alto),
    )
    ..cubica(
      Offset.lerp(medio, derecha, .5)! + Offset(0, -alto * 1.2),
      derecha + Offset(0, -alto * .8),
      derecha + Offset(0, alto * .2),
    )
    ..curva(medio + Offset(0, alto * .45), izquierda + Offset(0, alto * .2))
    ..close();
  final caja = nieve.getBounds();
  canvas.drawPath(
    nieve,
    _degradado(caja.topCenter, caja.bottomCenter, const [
      Colors.white,
      Color(0xFFF2F8FC),
      Color(0xFFC3DCEB),
    ]),
  );
}

/// Carambanos que cuelgan de una pieza, de [desde] a [hasta].
void _carambanos(
  Canvas canvas,
  Offset desde,
  Offset hasta,
  double largo,
  int cuantos,
) {
  final hielo = Path();
  for (var k = 0; k < cuantos; k++) {
    final f = (k + .5) / cuantos;
    final p = Offset.lerp(desde, hasta, f)!;
    final l = largo * (.55 + .45 * ((k * 7 % 5) / 4));
    hielo
      ..moveTo(p.dx - largo * .14, p.dy)
      ..lineTo(p.dx + largo * .14, p.dy)
      ..lineTo(p.dx + largo * .02, p.dy + l)
      ..close();
  }
  final caja = hielo.getBounds();
  canvas.drawPath(
    hielo,
    _degradado(caja.topCenter, caja.bottomCenter, [
      const Color(0xFFF4FBFF),
      const Color(0xFFBFE2F5).withValues(alpha: .8),
    ]),
  );
}

/// Donde queda el cuerpo del robot (sin los brazos) parado en [pies]: para
/// grabarlo una vez en una imagen.
Rect cajaRobot(Offset pies, double alto) {
  final ancho = alto * .48;
  return Rect.fromLTRB(
    pies.dx - ancho * .64,
    pies.dy - alto * 1.02,
    pies.dx + ancho * .64,
    pies.dy + alto * .02,
  );
}

/// El cuerpo del robot (todo lo que no se mueve) grabado en una imagen, con
/// [escala] pixeles por punto: en cada cuadro solo se pinta la imagen, y
/// encima las luces y el vapor.
ui.Image grabarRobot(double alto, double escala) {
  final caja = cajaRobot(Offset.zero, alto);
  final grabadora = ui.PictureRecorder();
  final canvas = Canvas(grabadora)
    ..scale(escala)
    ..translate(-caja.left, -caja.top);
  pintarCuerpoRobot(canvas, Offset.zero, alto);
  final dibujo = grabadora.endRecording();
  final imagen = dibujo.toImageSync(
    (caja.width * escala).ceil(),
    (caja.height * escala).ceil(),
  );
  dibujo.dispose();
  return imagen;
}

/// El robot que sale del hielo a sacar los peces enormes: un gigante de
/// acero, con las luces que se prenden mientras sale ([encendido] de 0 a 1,
/// titilando), el vapor de la espalda y, si viene, su cuerpo ya grabado
/// ([grabado], de [grabarRobot]). Los brazos van aparte
/// ([pintarBrazosRobot]), delante del pez.
void pintarRobot(
  Canvas canvas,
  Offset pies,
  double alto,
  double tiempo, {
  double encendido = 1,
  ui.Image? grabado,
}) {
  final ancho = alto * .48;
  double x(double f) => pies.dx + ancho * f;
  double y(double f) => pies.dy - alto * f;

  // La sombra en el hielo.
  final sombra = Rect.fromCenter(
    center: Offset(pies.dx + ancho * .05, pies.dy + alto * .005),
    width: ancho * 1.5,
    height: alto * .05,
  );
  canvas.drawOval(
    sombra,
    Paint()
      ..shader = ui.Gradient.radial(sombra.center, sombra.width / 2, [
        const Color(0xFF2B3E4C).withValues(alpha: .4),
        const Color(0xFF2B3E4C).withValues(alpha: 0),
      ]),
  );

  // El vapor que larga por las ventilas de la espalda.
  final vapor = Paint();
  for (final lado in const [-1.0, 1.0]) {
    final ventila = Offset(x(lado * .36), y(.79));
    for (var k = 0; k < 5; k++) {
      final edad = (tiempo * .8 + k / 5 + (lado > 0 ? .5 : 0)) % 1;
      vapor.color = Colors.white.withValues(alpha: .5 * (1 - edad));
      canvas.drawCircle(
        ventila + Offset(lado * edad * ancho * .22, -edad * alto * .18),
        ancho * (.04 + edad * .08),
        vapor,
      );
    }
  }

  if (grabado != null) {
    canvas.drawImageRect(
      grabado,
      Rect.fromLTWH(0, 0, grabado.width.toDouble(), grabado.height.toDouble()),
      cajaRobot(pies, alto),
      Paint()..filterQuality = FilterQuality.medium,
    );
  } else {
    pintarCuerpoRobot(canvas, pies, alto);
  }

  // Las luces: mientras se prenden, titilan.
  final luz = encendido >= 1
      ? 1.0
      : encendido * (math.sin(tiempo * 63) > -.2 ? 1 : .3);
  if (luz <= 0) return;

  // El reactor del pecho, que late.
  final nucleo = Offset(x(0), y(.655));
  final late = .65 + .35 * math.sin(tiempo * 4.5);
  _resplandor(
    canvas,
    nucleo,
    ancho * .42,
    _ambar.withValues(alpha: .4 * late * luz),
  );
  canvas.drawCircle(
    nucleo,
    ancho * .075,
    Paint()
      ..shader = ui.Gradient.radial(
        nucleo,
        ancho * .075,
        [
          _ambarClaro.withValues(alpha: luz),
          _ambar.withValues(alpha: .9 * luz),
          _ambar.withValues(alpha: .15 * luz),
        ],
        const [0, .55, 1],
      ),
  );
  // La rejilla del reactor, por delante de la luz.
  final rejilla = Path();
  for (var k = -2; k <= 2; k++) {
    final dx = k * ancho * .028;
    final mitad =
        math.sqrt(math.max(0, .075 * .075 - (dx / ancho) * (dx / ancho))) *
        ancho;
    rejilla
      ..moveTo(nucleo.dx + dx, nucleo.dy - mitad)
      ..lineTo(nucleo.dx + dx, nucleo.dy + mitad);
  }
  canvas.drawPath(
    rejilla,
    _borde(const Color(0xFF2A1A08).withValues(alpha: .7), ancho * .012),
  );

  // La luz de las ventilas del pecho.
  for (final lado in const [-1.0, 1.0]) {
    for (var k = 0; k < 3; k++) {
      final c = Offset(x(lado * .27), y(.705 - k * .025));
      canvas.drawLine(
        c - Offset(ancho * .05, 0),
        c + Offset(ancho * .05, 0),
        _borde(_ambar.withValues(alpha: .35 * luz * late), ancho * .012),
      );
    }
  }

  // El visor, que mira de un lado a otro, con sus dos ojos.
  final visor = Offset(x(0), y(.858));
  final mira = math.sin(tiempo * 1.2) * ancho * .045;
  _resplandor(
    canvas,
    visor + Offset(mira, 0),
    ancho * .2,
    _ambar.withValues(alpha: .5 * luz),
  );
  for (final lado in const [-1.0, 1.0]) {
    final ojo = visor + Offset(mira + lado * ancho * .06, 0);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: ojo,
            width: ancho * .085,
            height: alto * .016,
          ),
          Radius.circular(alto * .008),
        ),
        Paint()..color = _ambarClaro.withValues(alpha: luz),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: ojo, width: ancho * .12, height: alto * .026),
          Radius.circular(alto * .013),
        ),
        Paint()..color = _ambar.withValues(alpha: .35 * luz),
      );
  }

  // La baliza de la antena, que parpadea.
  final antena = Offset(x(.17), y(.985));
  final prende = (1 + math.sin(tiempo * 9)) / 2 * luz;
  _resplandor(
    canvas,
    antena,
    ancho * .14,
    const Color(0xFFFF3B30).withValues(alpha: .55 * prende),
  );
  canvas.drawCircle(
    antena,
    ancho * .028,
    Paint()
      ..color = Color.lerp(
        const Color(0xFF7A1A1A),
        const Color(0xFFFF6B5E),
        prende,
      )!,
  );
}

/// El cuerpo del robot, quieto: las piernas con sus pistones, rodilleras y
/// botas de pisar hielo, la cintura, el pecho de dos caras con el reactor y
/// las ventilas, el cuello alto y la cabeza con el visor, todo en placas
/// biseladas y remachadas, con nieve y carambanos encima.
void pintarCuerpoRobot(Canvas canvas, Offset pies, double alto) {
  final ancho = alto * .48;
  final b = math.max(1.0, ancho * .011);
  double x(double f) => pies.dx + ancho * f;
  double y(double f) => pies.dy - alto * f;
  Offset p(double fx, double fy) => Offset(x(fx), y(fy));
  final remaches = Path();
  void remache(Offset c) =>
      remaches.addOval(Rect.fromCircle(center: c, radius: ancho * .011));
  final cromo = _metalClaro;

  // ------------------------------------------------------- las piernas
  for (final lado in const [-1.0, 1.0]) {
    final m = lado * .25;
    // Lo de adentro del muslo: el hueso de metal y el piston.
    final cadera = p(m * .78, .44);
    final rodilla = p(m, .27);
    canvas
      ..drawPath(
        _barra(cadera, rodilla, ancho * .17, ancho * .14),
        _tubo(cadera, rodilla, ancho * .17, const [
          Color(0xFF5B6673),
          _mecanica,
          Color(0xFF11161C),
        ]),
      )
      ..drawLine(
        p(m + lado * .13, .43),
        p(m + lado * .13, .24),
        _borde(_tinta, ancho * .05),
      )
      ..drawLine(
        p(m + lado * .13, .43),
        p(m + lado * .13, .24),
        _borde(cromo[1], ancho * .028),
      )
      ..drawLine(
        p(m + lado * .13, .43),
        p(m + lado * .13, .34),
        _borde(_mecanica, ancho * .055),
      );
    // El blindaje del muslo, de dos caras.
    final arriba = .455;
    final abajo = .3;
    _placa(
      canvas,
      _poligono([
        p(m - .12, arriba),
        p(m, arriba + .008),
        p(m, abajo - .005),
        p(m - .1, abajo),
      ]),
      base: _caraLuz,
      bisel: b,
    );
    _placa(
      canvas,
      _poligono([
        p(m, arriba + .008),
        p(m + .12, arriba),
        p(m + .1, abajo),
        p(m, abajo - .005),
      ]),
      base: _caraSombra,
      bisel: b,
    );
    // La rodillera, como un escudo con el perno en el medio.
    final rodillera = Path()
      ..ir(p(m - .15, .3))
      ..curva(p(m, .325), p(m + .15, .3))
      ..linea(p(m + .12, .245))
      ..curva(p(m, .215), p(m - .12, .245))
      ..close();
    _placa(canvas, rodillera, bisel: b);
    canvas.drawCircle(
      p(m, .27),
      ancho * .035,
      Paint()
        ..shader = ui.Gradient.radial(p(m - .01, .275), ancho * .04, [
          const Color(0xFFB9C6D2),
          const Color(0xFF4A5866),
        ]),
    );
    // La canilla: dos caras, mas ancha arriba, con franjas de peligro.
    final canillaLuz = _poligono([
      p(m - .16, .235),
      p(m, .245),
      p(m, .085),
      p(m - .12, .09),
    ]);
    final canillaSombra = _poligono([
      p(m, .245),
      p(m + .16, .235),
      p(m + .12, .09),
      p(m, .085),
    ]);
    _placa(canvas, canillaLuz, base: _caraLuz, bisel: b);
    _placa(canvas, canillaSombra, base: _caraSombra, bisel: b);
    final cajaFranja = Rect.fromLTRB(x(m - .16), y(.215), x(m + .16), y(.19));
    _franjas(
      canvas,
      Path()
        ..addPath(canillaLuz, Offset.zero)
        ..addPath(canillaSombra, Offset.zero),
      cajaFranja,
      ancho * .03,
    );
    canvas.drawRect(
      cajaFranja,
      Paint()..color = Colors.black.withValues(alpha: .12),
    );
    // La ventila de la canilla.
    final ventila = Path();
    for (var k = 0; k < 3; k++) {
      ventila
        ..ir(p(m - .06, .155 - k * .02))
        ..linea(p(m + .06, .155 - k * .02));
    }
    canvas.drawPath(ventila, _borde(const Color(0xFF0E1318), alto * .006));
    remache(p(m - .11, .225));
    remache(p(m + .11, .225));
    // El tobillo y la bota: arriba clara (la mira el sol), adelante en
    // sombra, la suela y los dedos con pernos.
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(m - .08),
        y(.1),
        x(m + .08),
        y(.065),
        Radius.circular(ancho * .02),
      ),
      Paint()..color = _mecanica,
    );
    final arribaBota = _poligono([
      p(m - .15, .075),
      p(m + .15, .075),
      p(m + .21, .045),
      p(m - .21, .045),
    ]);
    final frenteBota = _poligono([
      p(m - .21, .045),
      p(m + .21, .045),
      p(m + .22, .012),
      p(m - .22, .012),
    ]);
    _placa(canvas, arribaBota, base: _caraLuz, bisel: b);
    _placa(canvas, frenteBota, base: _caraSombra, bisel: b);
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(m - .23),
        y(.014),
        x(m + .23),
        y(0),
        Radius.circular(ancho * .01),
      ),
      Paint()..color = const Color(0xFF12171D),
    );
    for (final f in const [-.14, -.05, .05, .14]) {
      remache(p(m + f, .03));
    }
  }

  // ------------------------------------------------------ la cintura
  final cintura = RRect.fromLTRBR(
    x(-.31),
    y(.5),
    x(.31),
    y(.415),
    Radius.circular(ancho * .03),
  );
  canvas.drawRRect(
    cintura,
    _degradado(
      cintura.outerRect.topCenter,
      cintura.outerRect.bottomCenter,
      const [Color(0xFF3B4553), _mecanica, Color(0xFF12171D)],
    ),
  );
  // Las tapas de las caderas.
  for (final lado in const [-1.0, 1.0]) {
    final tapa = Path()
      ..addOval(
        Rect.fromCircle(center: p(lado * .24, .455), radius: ancho * .075),
      );
    _placa(canvas, tapa, base: lado < 0 ? _caraLuz : _caraSombra, bisel: b);
    canvas.drawCircle(
      p(lado * .24, .455),
      ancho * .025,
      Paint()..color = _mecanica,
    );
  }
  // La placa del medio, con franjas.
  final placaCintura = _poligono([
    p(-.13, .505),
    p(.13, .505),
    p(.09, .4),
    p(-.09, .4),
  ]);
  _placa(canvas, placaCintura, bisel: b);
  _franjas(
    canvas,
    placaCintura,
    Rect.fromLTRB(x(-.13), y(.47), x(.13), y(.43)),
    ancho * .03,
  );

  // ------------------------------------------------------- la panza
  for (var k = 0; k < 3; k++) {
    final arriba = .565 - k * .022;
    final mitad = .21 - k * .015;
    _placa(
      canvas,
      Path()..addRRect(
        RRect.fromLTRBR(
          x(-mitad),
          y(arriba),
          x(mitad),
          y(arriba - .024),
          Radius.circular(ancho * .015),
        ),
      ),
      base: _mecanica,
      bisel: b * .8,
    );
  }

  // -------------------------------------------------------- el pecho
  // Dos caras (la del sol y la de la sombra) que se juntan en la quilla
  // del medio, con el borde de arriba redondeado hacia los hombros.
  final pechoLuz = Path()
    ..ir(p(0, .795))
    ..linea(p(-.36, .79))
    ..curva(p(-.5, .785), p(-.5, .73))
    ..linea(p(-.42, .6))
    ..curva(p(-.36, .555), p(-.25, .555))
    ..linea(p(0, .545))
    ..close();
  final pechoSombra = Path()
    ..ir(p(0, .795))
    ..linea(p(.36, .79))
    ..curva(p(.5, .785), p(.5, .73))
    ..linea(p(.42, .6))
    ..curva(p(.36, .555), p(.25, .555))
    ..linea(p(0, .545))
    ..close();
  _placa(canvas, pechoLuz, base: _caraLuz, bisel: b * 1.3);
  _placa(canvas, pechoSombra, base: _caraSombra, bisel: b * 1.3);
  // La quilla del medio.
  final quilla = _poligono([
    p(-.05, .79),
    p(.05, .79),
    p(.035, .555),
    p(-.035, .555),
  ]);
  _placa(canvas, quilla, bisel: b);
  // Las placas de los pectorales, una sobre otra.
  for (final lado in const [-1.0, 1.0]) {
    final pectoral = _poligono([
      p(lado * .08, .775),
      p(lado * .4, .765),
      p(lado * .36, .67),
      p(lado * .1, .675),
    ]);
    _placa(canvas, pectoral, base: lado < 0 ? _caraLuz : _caraSombra, bisel: b);
    // Las ventilas, con su luz por dentro (va con las luces).
    final ranuras = Path();
    for (var k = 0; k < 3; k++) {
      final c = p(lado * .27, .705 - k * .025);
      ranuras.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: ancho * .12, height: alto * .011),
          Radius.circular(alto * .005),
        ),
      );
    }
    canvas.drawPath(ranuras, Paint()..color = const Color(0xFF0B0F14));
    remache(p(lado * .12, .765));
    remache(p(lado * .37, .755));
    remache(p(lado * .34, .685));
    remache(p(lado * .13, .69));
    // Las franjas de las esquinas de abajo.
    final esquina = _poligono([
      p(lado * .42, .6),
      p(lado * .3, .58),
      p(lado * .26, .556),
      p(lado * .36, .556),
    ]);
    _franjas(canvas, esquina, esquina.getBounds(), ancho * .025);
  }
  // El aro del reactor (la luz va aparte).
  final nucleo = p(0, .655);
  canvas
    ..drawCircle(
      nucleo,
      ancho * .12,
      Paint()
        ..shader = ui.Gradient.radial(
          nucleo - Offset(ancho * .04, ancho * .04),
          ancho * .14,
          const [Color(0xFFC9D5DF), Color(0xFF6C7C8C), Color(0xFF2A3440)],
          const [0, .55, 1],
        ),
    )
    ..drawCircle(nucleo, ancho * .12, _borde(_filo, b))
    ..drawCircle(
      nucleo,
      ancho * .088,
      Paint()..color = const Color(0xFF1A1006),
    );
  for (var k = 0; k < 6; k++) {
    final a = k * math.pi / 3 + math.pi / 6;
    remache(nucleo + Offset(math.cos(a), math.sin(a)) * ancho * .104);
  }
  // Los carambanos del borde de abajo del pecho.
  _carambanos(canvas, p(-.38, .575), p(-.2, .556), ancho * .07, 3);
  _carambanos(canvas, p(.22, .556), p(.36, .57), ancho * .06, 2);

  // ------------------------------------------- el cuello y la cabeza
  // La cabeza, metida entre el cuello alto: un casco de dos caras, con la
  // cresta arriba, las orejas y el visor (sus luces van aparte).
  for (final lado in const [-1.0, 1.0]) {
    final oreja = Path()
      ..addRRect(
        RRect.fromLTRBR(
          x(lado < 0 ? -.24 : .17),
          y(.89),
          x(lado < 0 ? -.17 : .24),
          y(.825),
          Radius.circular(ancho * .02),
        ),
      );
    _placa(canvas, oreja, base: lado < 0 ? _caraLuz : _caraSombra, bisel: b);
    canvas.drawLine(
      p(lado * .205, .885),
      p(lado * .205, .83),
      _borde(_amarillo.withValues(alpha: .85), ancho * .012),
    );
  }
  final cascoLuz = Path()
    ..ir(p(0, .935))
    ..curva(p(-.13, .935), p(-.18, .9))
    ..linea(p(-.2, .82))
    ..linea(p(0, .8))
    ..close();
  final cascoSombra = Path()
    ..ir(p(0, .935))
    ..curva(p(.13, .935), p(.18, .9))
    ..linea(p(.2, .82))
    ..linea(p(0, .8))
    ..close();
  _placa(canvas, cascoLuz, base: _caraLuz, bisel: b);
  _placa(canvas, cascoSombra, base: _caraSombra, bisel: b);
  // La cresta.
  _placa(
    canvas,
    _poligono([p(-.025, .955), p(.025, .955), p(.035, .89), p(-.035, .89)]),
    bisel: b * .8,
  );
  // El visor, oscuro: el vidrio de las luces.
  final visor = RRect.fromLTRBR(
    x(-.16),
    y(.875),
    x(.16),
    y(.84),
    Radius.circular(ancho * .02),
  );
  canvas
    ..drawRRect(
      visor,
      _degradado(
        visor.outerRect.topCenter,
        visor.outerRect.bottomCenter,
        const [Color(0xFF1B2128), Color(0xFF07090C)],
      ),
    )
    ..drawLine(
      p(-.14, .871),
      p(-.02, .871),
      _borde(Colors.white.withValues(alpha: .25), alto * .003),
    );
  // La antena.
  canvas.drawLine(p(.15, .91), p(.17, .98), _borde(_mecanica, ancho * .016));
  // El cuello alto, por delante de la barbilla.
  final cuello = Path()
    ..ir(p(-.3, .8))
    ..curva(p(-.26, .835), p(-.17, .84))
    ..linea(p(-.13, .81))
    ..linea(p(.13, .81))
    ..linea(p(.17, .84))
    ..curva(p(.26, .835), p(.3, .8))
    ..linea(p(.24, .77))
    ..linea(p(-.24, .77))
    ..close();
  _placa(canvas, cuello, bisel: b);
  // La nieve de la cabeza y del pecho.
  _nieveEncima(
    canvas,
    p(-.15, .925),
    p(.15, .925),
    alto * .022,
    comba: alto * .006,
  );
  _nieveEncima(canvas, p(-.46, .775), p(-.14, .79), alto * .014);
  _nieveEncima(canvas, p(.16, .79), p(.44, .775), alto * .012);

  canvas
    ..drawPath(remaches, Paint()..color = const Color(0xFF151B22))
    ..drawPath(
      remaches.shift(Offset(-ancho * .004, -ancho * .004)),
      Paint()..color = Colors.white.withValues(alpha: .35),
    );
}

/// Los brazos del robot, de los hombros a las manos, por delante del pez: el
/// brazo con su piston, el codo, el antebrazo blindado con franjas y la
/// mano de tres dedos gruesos y el pulgar, que se cierra sobre el pez
/// ([agarra] de 0, suelta, a 1, apretando). Arriba, las hombreras de dos
/// placas, con nieve y carambanos.
void pintarBrazosRobot(
  Canvas canvas,
  Offset pies,
  double alto,
  Offset garra,
  Offset garraAtras, {
  double agarra = 1,
}) {
  final ancho = alto * .48;
  final b = math.max(1.0, ancho * .011);
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
    final luzDelLado = haciaElPez > 0 ? _caraLuz : _caraSombra;

    // El brazo: el hueso con el piston y la manga blindada.
    canvas.drawPath(
      _barra(hombro, codo, ancho * .16, ancho * .13),
      _tubo(hombro, codo, ancho * .16, const [
        Color(0xFF5B6673),
        _mecanica,
        Color(0xFF11161C),
      ]),
    );
    final d = codo - hombro;
    final n = Offset(-d.dy, d.dx) / math.max(1e-6, d.distance);
    final pistonDesde = hombro + n * ancho * .1 + d * .12;
    final pistonHasta = hombro + n * ancho * .085 + d * .9;
    canvas
      ..drawLine(pistonDesde, pistonHasta, _borde(_tinta, ancho * .045))
      ..drawLine(pistonDesde, pistonHasta, _borde(_cromo, ancho * .026))
      ..drawLine(
        pistonDesde,
        Offset.lerp(pistonDesde, pistonHasta, .5)!,
        _borde(_mecanica, ancho * .05),
      );
    _placa(
      canvas,
      _barra(
        Offset.lerp(hombro, codo, .2)!,
        Offset.lerp(hombro, codo, .78)!,
        ancho * .2,
        ancho * .17,
      ),
      base: luzDelLado,
      bisel: b,
    );

    // El antebrazo: un guantelete de dos caras, mas ancho hacia la mano,
    // con su franja de peligro.
    final hacia = (mano - codo) / math.max(1e-6, (mano - codo).distance);
    final normal = Offset(-hacia.dy, hacia.dx);
    final muneca = mano - hacia * ancho * .05;
    final media = Offset.lerp(codo, muneca, .1)!;
    final caraArriba = _poligono([
      media + normal * ancho * .08,
      muneca + normal * ancho * .13,
      muneca,
      media,
    ]);
    final caraAbajo = _poligono([
      media,
      muneca,
      muneca - normal * ancho * .13,
      media - normal * ancho * .08,
    ]);
    final arribaEsLuz = normal.dx + normal.dy * .6 < 0;
    _placa(
      canvas,
      caraArriba,
      base: arribaEsLuz ? _caraLuz : _caraSombra,
      bisel: b,
    );
    _placa(
      canvas,
      caraAbajo,
      base: arribaEsLuz ? _caraSombra : _caraLuz,
      bisel: b,
    );
    final banda = _barra(
      Offset.lerp(codo, muneca, .68)!,
      Offset.lerp(codo, muneca, .82)!,
      ancho * .22,
      ancho * .24,
    );
    _franjas(canvas, banda, banda.getBounds(), ancho * .03);
    canvas.drawPath(banda, _borde(_filo, b * .7));

    // El codo: una tapa redonda con el perno.
    canvas
      ..drawCircle(codo, ancho * .1, Paint()..color = _mecanica)
      ..drawCircle(
        codo,
        ancho * .075,
        Paint()
          ..shader = ui.Gradient.radial(
            codo - Offset(ancho * .025, ancho * .025),
            ancho * .09,
            const [Color(0xFFB9C6D2), Color(0xFF55657A), Color(0xFF26303B)],
            const [0, .5, 1],
          ),
      )
      ..drawCircle(codo, ancho * .075, _borde(_filo, b))
      ..drawCircle(codo, ancho * .022, Paint()..color = _mecanica);

    // La mano: la palma y tres dedos gruesos de dos partes, mas el pulgar
    // del otro lado; al agarrar apuntan al pez y se cierran.
    final adentro = Offset(haciaElPez, .45);
    final hacia2 = Offset.lerp(
      hacia,
      adentro / adentro.distance,
      agarra * .75,
    )!;
    final g = hacia2 / math.max(1e-6, hacia2.distance);
    final ng = Offset(-g.dy, g.dx);
    final palma = muneca + g * ancho * .07;
    _placa(
      canvas,
      _barra(
        muneca - g * ancho * .01,
        palma + g * ancho * .03,
        ancho * .24,
        ancho * .2,
      ),
      base: _caraFrente,
      bisel: b,
    );
    for (final k in const [-1.0, 0.0, 1.0]) {
      final raiz = palma + g * ancho * .02 + ng * ancho * .07 * k;
      final d1 = _girar(g, k * (.35 - .2 * agarra));
      final nudillo = raiz + d1 * ancho * .1;
      final d2 = _girar(
        d1,
        -k * (.4 + .5 * agarra) + .35 * agarra * haciaElPez,
      );
      final punta = nudillo + d2 * ancho * .085;
      _placa(
        canvas,
        _barra(raiz, nudillo, ancho * .07, ancho * .062),
        base: _caraLuz,
        bisel: b * .8,
      );
      _placa(
        canvas,
        _barra(nudillo, punta, ancho * .06, ancho * .045),
        base: _caraSombra,
        bisel: b * .8,
      );
      canvas
        ..drawCircle(nudillo, ancho * .03, Paint()..color = _mecanica)
        ..drawCircle(
          punta + d2 * ancho * .01,
          ancho * .022,
          Paint()..color = const Color(0xFF151B22),
        );
    }
    // El pulgar, del otro lado de la palma.
    final raizPulgar = palma - ng * ancho * .11 * haciaElPez.sign;
    final dPulgar = _girar(g, -haciaElPez * (.9 - .5 * agarra));
    final puntaPulgar = raizPulgar + dPulgar * ancho * .11;
    _placa(
      canvas,
      _barra(raizPulgar, puntaPulgar, ancho * .075, ancho * .05),
      base: _caraLuz,
      bisel: b * .8,
    );

    // La hombrera: dos placas una sobre otra, con el filo amarillo, nieve
    // arriba y carambanos abajo.
    final centro = hombro - Offset(0, ancho * .03);
    final abajoHombrera = centro.dy + ancho * .07;
    final grande = Path()
      ..ir(Offset(centro.dx - ancho * .23, abajoHombrera))
      ..cubica(
        Offset(centro.dx - ancho * .25, centro.dy - ancho * .2),
        Offset(centro.dx + ancho * .25, centro.dy - ancho * .2),
        Offset(centro.dx + ancho * .23, abajoHombrera),
      )
      ..curva(
        Offset(centro.dx, abajoHombrera + ancho * .07),
        Offset(centro.dx - ancho * .23, abajoHombrera),
      )
      ..close();
    final labio = Path()
      ..ir(Offset(centro.dx - ancho * .21, abajoHombrera - ancho * .005))
      ..curva(
        Offset(centro.dx, abajoHombrera + ancho * .075),
        Offset(centro.dx + ancho * .21, abajoHombrera - ancho * .005),
      )
      ..linea(Offset(centro.dx + ancho * .17, abajoHombrera + ancho * .06))
      ..curva(
        Offset(centro.dx, abajoHombrera + ancho * .12),
        Offset(centro.dx - ancho * .17, abajoHombrera + ancho * .06),
      )
      ..close();
    _carambanos(
      canvas,
      Offset(centro.dx - ancho * .15, abajoHombrera + ancho * .07),
      Offset(centro.dx + ancho * .15, abajoHombrera + ancho * .07),
      ancho * .07,
      4,
    );
    _placa(canvas, labio, base: luzDelLado, bisel: b);
    _franjas(canvas, labio, labio.getBounds(), ancho * .028);
    canvas.drawPath(labio, _borde(_filo, b * .7));
    _placa(canvas, grande, base: luzDelLado, bisel: b * 1.2);
    canvas
      ..drawCircle(
        Offset(centro.dx, centro.dy - ancho * .02),
        ancho * .018,
        Paint()..color = const Color(0xFF151B22),
      )
      ..drawCircle(
        Offset(centro.dx - ancho * .12, abajoHombrera - ancho * .02),
        ancho * .012,
        Paint()..color = const Color(0xFF151B22),
      )
      ..drawCircle(
        Offset(centro.dx + ancho * .12, abajoHombrera - ancho * .02),
        ancho * .012,
        Paint()..color = const Color(0xFF151B22),
      );
    _nieveEncima(
      canvas,
      Offset(centro.dx - ancho * .19, centro.dy - ancho * .06),
      Offset(centro.dx + ancho * .19, centro.dy - ancho * .06),
      ancho * .05,
      comba: ancho * .06,
    );
  }
}
