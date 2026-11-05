import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'crupier_macias.dart';

/// La cabeza de MacIAs recortada de su foto de crupier, en la misma grilla de
/// 512 (ver `tool/recortar_cabeza_crupier.dart`).
const rutaCabezaCrupier = 'assets/images/marca/macias_cabeza.png';

/// Las caras de MacIAs para su cuerpo de la pesca: cada gesto (y cada cuadro
/// del parpadeo) se pinta una vez sobre la cabeza recortada, con
/// [PintorCaraCrupier], y queda guardado.
class CabezasMacias {
  CabezasMacias(this.cabeza);

  /// La cabeza recortada (la imagen la cuida quien la cargo).
  final ui.Image cabeza;
  final _hechas = <(ExpresionCrupier, ParpadeoCrupier), ui.Image>{};

  ui.Image de(ExpresionCrupier expresion, ParpadeoCrupier parpadeo) =>
      _hechas.putIfAbsent((expresion, parpadeo), () {
        const lado = 256;
        final grabadora = ui.PictureRecorder();
        PintorCaraCrupier(
          foto: cabeza,
          expresion: expresion,
          parpadeo: parpadeo,
        ).paint(Canvas(grabadora), const Size(256, 256));
        final dibujo = grabadora.endRecording();
        final imagen = dibujo.toImageSync(lado, lado);
        dibujo.dispose();
        return imagen;
      });

  void dispose() {
    for (final imagen in _hechas.values) {
      imagen.dispose();
    }
    _hechas.clear();
  }
}

/// El parpadeo de MacIAs en la pesca, por tiempo: cada tres segundos y
/// pico, en cuadros (a medias, cerrados, a medias), y a veces dos seguidos.
ParpadeoCrupier parpadeoEn(double tiempo) {
  final vuelta = (tiempo / 3.3).floor();
  var fase = tiempo - vuelta * 3.3;
  if (vuelta % 4 == 2 && fase > .3) fase -= .3;
  if (fase < .04) return ParpadeoCrupier.medio;
  if (fase < .11) return ParpadeoCrupier.cerrados;
  if (fase < .15) return ParpadeoCrupier.medio;
  return ParpadeoCrupier.abiertos;
}

/// Lo que esta haciendo MacIAs: [tira] de la caña (0 derecho, 1 con todo,
/// echado para atras; negativo, se va hacia el pez), [agacha] las rodillas,
/// [salto] (en altos suyos, para arriba), [cabezazo] (la cabeza que gira para
/// mirar), [festejo] (0 a 1: suelta la manivela y levanta el puño) y
/// [respira] (la fase de la respiracion, en radianes).
typedef PosePescador = ({
  double tira,
  double agacha,
  double salto,
  double cabezazo,
  double festejo,
  double respira,
});

/// Donde va cada parte de MacIAs en el lago, y la caña en sus manos.
/// Izquierda y derecha son las de la pantalla (el mira para adelante: su mano
/// derecha es la de la izquierda).
typedef CuerpoPescador = ({
  double alto,
  double giro,
  double giroCabeza,
  Offset cadera,
  Offset cuello,
  Offset hombroIzquierdo,
  Offset hombroDerecho,
  Offset codoIzquierdo,
  Offset codoDerecho,
  Offset manoIzquierda,
  Offset manoDerecha,
  Offset caderaIzquierda,
  Offset caderaDerecha,
  Offset rodillaIzquierda,
  Offset rodillaDerecha,
  Offset pieIzquierdo,
  Offset pieDerecho,
  Offset mango,
  Offset baseCana,
  double festejo,
});

/// Lo largo del mango de la caña, en altos de MacIAs.
const _largoMango = .27;

/// Arma a MacIAs, parado con los pies en [pies] y [alto] de alto, en la
/// [pose]. La caña la tiene parada frente a el, con la culata en la cadera:
/// la mano izquierda (la derecha suya) en el corcho y la otra en la manivela
/// del carrete, que da la funcion [perilla] (de donde esta la caña).
CuerpoPescador armarPescador(
  Offset pies,
  double alto,
  PosePescador pose, {
  required Offset Function(Offset mango, Offset baseCana) perilla,
}) {
  final a = alto;
  final salto = Offset(0, -pose.salto * a);
  final giro = -.16 * pose.tira + .012 * math.sin(pose.respira * .5);
  final agacha = pose.agacha.clamp(0.0, 1.0);
  final cadera =
      pies + salto + Offset(.02 * a * pose.tira, -a * (.47 - .055 * agacha));
  Offset delTorso(double x, double y) =>
      cadera + _girar(Offset(x, y) * a, giro);
  // Respira: los hombros suben y bajan un poquito.
  final aire = .004 * math.sin(pose.respira);
  final cuello = delTorso(0, -.31 - aire);
  final hombroIzquierdo = delTorso(-.13, -.285 - aire);
  final hombroDerecho = delTorso(.13, -.285 - aire);

  // La caña, con la culata en la cadera (un poco a la derecha) y parada.
  final mango = delTorso(.06, .05);
  final direccion = _girar(const Offset(.309, -.951), giro);
  final baseCana = mango + direccion * (_largoMango * a);
  final corcho = mango + direccion * (.82 * _largoMango * a);
  final manivela = perilla(mango, baseCana);
  final puno = hombroDerecho + _girar(Offset(.07 * a, -.24 * a), giro);
  final manoDerecha = Offset.lerp(manivela, puno, pose.festejo)!;

  final codoIzquierdo = _articulacion(
    hombroIzquierdo,
    corcho,
    .16 * a,
    .155 * a,
    const Offset(-.4, 1),
  );
  final codoDerecho = _articulacion(
    hombroDerecho,
    manoDerecha,
    .16 * a,
    .155 * a,
    Offset(1, .6 - pose.festejo * 1.4),
  );

  final pieIzquierdo = pies + salto * .8 + Offset(-.1 * a, 0);
  final pieDerecho = pies + salto * .8 + Offset(.1 * a, 0);
  final caderaIzquierda = cadera + _girar(Offset(-.07 * a, .03 * a), giro * .4);
  final caderaDerecha = cadera + _girar(Offset(.07 * a, .03 * a), giro * .4);
  return (
    alto: a,
    giro: giro,
    giroCabeza: pose.cabezazo,
    cadera: cadera,
    cuello: cuello,
    hombroIzquierdo: hombroIzquierdo,
    hombroDerecho: hombroDerecho,
    codoIzquierdo: codoIzquierdo,
    codoDerecho: codoDerecho,
    manoIzquierda: corcho,
    manoDerecha: manoDerecha,
    caderaIzquierda: caderaIzquierda,
    caderaDerecha: caderaDerecha,
    // Las rodillas se doblan hacia adelante (hacia el que mira): de frente
    // apenas se abren.
    rodillaIzquierda: _articulacion(
      caderaIzquierda,
      pieIzquierdo,
      .222 * a,
      .218 * a,
      const Offset(-1, 0),
      doblez: .35,
    ),
    rodillaDerecha: _articulacion(
      caderaDerecha,
      pieDerecho,
      .222 * a,
      .218 * a,
      const Offset(1, 0),
      doblez: .35,
    ),
    pieIzquierdo: pieIzquierdo,
    pieDerecho: pieDerecho,
    mango: mango,
    baseCana: baseCana,
    festejo: pose.festejo,
  );
}

Offset _girar(Offset p, double angulo) => Offset(
  p.dx * math.cos(angulo) - p.dy * math.sin(angulo),
  p.dx * math.sin(angulo) + p.dy * math.cos(angulo),
);

/// El codo (o la rodilla) entre [desde] y [hasta], con huesos de [largo1] y
/// [largo2], doblado hacia [afuera] (con [doblez] menos de 1, lo que se ve de
/// costado de una articulacion que se dobla hacia adelante). Si no llega, el
/// miembro queda estirado.
Offset _articulacion(
  Offset desde,
  Offset hasta,
  double largo1,
  double largo2,
  Offset afuera, {
  double doblez = 1,
}) {
  final d = hasta - desde;
  final distancia = d.distance;
  if (distancia < 1e-6) return desde + afuera * largo1;
  final u = d / distancia;
  final dist = math.min(distancia, (largo1 + largo2) * .999);
  final a = (largo1 * largo1 - largo2 * largo2 + dist * dist) / (2 * dist);
  final altura = math.sqrt(math.max(0.0, largo1 * largo1 - a * a));
  var n = Offset(-u.dy, u.dx);
  if (n.dx * afuera.dx + n.dy * afuera.dy < 0) n = -n;
  return desde + u * a + n * altura * doblez;
}

/// Un degradado entre dos puntos.
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
    paradas ?? (colores.length == 2 ? null : _parejas(colores.length)),
  );

List<double> _parejas(int n) => [for (var i = 0; i < n; i++) i / (n - 1)];

Paint _trazo(Color color, double grueso) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = grueso
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = color;

// Los colores: la piel y el pelo salen de la foto; la ropa de abrigo, encima
// de la de crupier.
const _piel = Color(0xFFE19169);
const _pelo = Color(0xFF1C1714);
const _campera = Color(0xFF2B6A9E);
const _camperaClara = Color(0xFF5B9BD0);
const _camperaOscura = Color(0xFF16405F);
const _chaleco = Color(0xFF353437);
const _camisa = Color(0xFFEEECEE);
const _pantalon = Color(0xFF2E323B);
const _pantalonClaro = Color(0xFF4A505D);
const _bota = Color(0xFF6E4527);
const _botaClara = Color(0xFF9A6A43);
const _pielDeAbrigo = Color(0xFFEDE4D3);
const _pielDeAbrigoSombra = Color(0xFFBFB09A);
const _guante = Color(0xFF34383F);
const _guanteClaro = Color(0xFF5A606B);

/// Un brazo o una pierna: un tubo liso que pasa por [puntos] (tres: el
/// hombro, el codo y la muñeca) y va de un grueso al otro, redondeado en las
/// puntas; en la articulacion se dobla en curva, sin quiebres.
Path _miembro(List<Offset> puntos, List<double> gruesos) {
  final izquierdo = <Offset>[];
  final derecho = <Offset>[];
  for (var i = 0; i < 3; i++) {
    final antes = i > 0 ? puntos[i] - puntos[i - 1] : puntos[1] - puntos[0];
    final despues = i < 2 ? puntos[i + 1] - puntos[i] : antes;
    var t =
        antes / math.max(1e-6, antes.distance) +
        despues / math.max(1e-6, despues.distance);
    t = t / math.max(1e-6, t.distance);
    final n = Offset(-t.dy, t.dx) * (gruesos[i] / 2);
    izquierdo.add(puntos[i] + n);
    derecho.add(puntos[i] - n);
  }
  final fin = puntos[2];
  final inicio = puntos[0];
  // Los puntos de control para que la curva pase por la articulacion.
  final controlIzquierdo = izquierdo[1] * 2 - (izquierdo[0] + izquierdo[2]) / 2;
  final controlDerecho = derecho[1] * 2 - (derecho[0] + derecho[2]) / 2;
  return Path()
    ..moveTo(izquierdo[0].dx, izquierdo[0].dy)
    ..quadraticBezierTo(
      controlIzquierdo.dx,
      controlIzquierdo.dy,
      izquierdo[2].dx,
      izquierdo[2].dy,
    )
    ..arcToPoint(
      derecho[2],
      radius: Radius.circular((izquierdo[2] - fin).distance),
      clockwise: false,
    )
    ..quadraticBezierTo(
      controlDerecho.dx,
      controlDerecho.dy,
      derecho[0].dx,
      derecho[0].dy,
    )
    ..arcToPoint(
      izquierdo[0],
      radius: Radius.circular((izquierdo[0] - inicio).distance),
      clockwise: false,
    )
    ..close();
}

/// El sombreado de un tubo que va de [desde] a [hasta]: claro del lado del
/// sol (arriba a la izquierda), oscuro del otro.
Paint _volumen(
  Offset desde,
  Offset hasta,
  double grueso,
  Color claro,
  Color medio,
  Color oscuro,
) {
  final d = hasta - desde;
  var n = Offset(-d.dy, d.dx) / math.max(1e-6, d.distance);
  if (n.dx + n.dy * .6 > 0) n = -n;
  final m = Offset.lerp(desde, hasta, .5)!;
  return _degradado(
    m + n * grueso * .55,
    m - n * grueso * .55,
    [claro, medio, oscuro],
    const [0, .45, 1],
  );
}

/// MacIAs pescando, de cuerpo entero (sin las manos, que van encima de la
/// caña: [pintarManosPescador]). Botas con piel, el pantalon, la campera
/// inflable abierta con el chaleco, la camisa y el moño de crupier, la
/// capucha con piel y su cabeza de siempre: [cara] es la cabeza con el gesto
/// de ahora (si todavia no cargo, va sin cabeza).
void pintarPescador(Canvas canvas, CuerpoPescador c, ui.Image? cara) {
  final a = c.alto;

  // La sombra en el muelle.
  final piso = Offset.lerp(c.pieIzquierdo, c.pieDerecho, .5)!;
  final sombra = Rect.fromCenter(
    center: Offset(
      piso.dx + a * .03,
      math.max(piso.dy, c.pieIzquierdo.dy) + a * .012,
    ),
    width: a * .52,
    height: a * .07,
  );
  canvas.drawOval(
    sombra,
    Paint()
      ..shader = ui.Gradient.radial(sombra.center, sombra.width / 2, [
        const Color(0xFF2B3E4C).withValues(alpha: .35),
        const Color(0xFF2B3E4C).withValues(alpha: 0),
      ]),
  );

  // Las piernas, con las rodillas y las botas.
  for (final (cadera, rodilla, pie, lado) in [
    (c.caderaIzquierda, c.rodillaIzquierda, c.pieIzquierdo, -1.0),
    (c.caderaDerecha, c.rodillaDerecha, c.pieDerecho, 1.0),
  ]) {
    final tobillo = pie + Offset(0, -a * .07);
    final pierna = _miembro(
      [cadera, rodilla, tobillo],
      [a * .125, a * .095, a * .085],
    );
    canvas
      ..drawPath(
        pierna,
        _volumen(
          cadera,
          tobillo,
          a * .12,
          _pantalonClaro,
          _pantalon,
          const Color(0xFF1B1E25),
        ),
      )
      // La luz de la rodilla, del lado del sol.
      ..save()
      ..clipPath(pierna)
      ..drawOval(
        Rect.fromCenter(
          center: rodilla + Offset(-a * .02, -a * .01),
          width: a * .05,
          height: a * .08,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            rodilla + Offset(-a * .02, -a * .01),
            a * .04,
            [
              Colors.white.withValues(alpha: .12),
              Colors.white.withValues(alpha: 0),
            ],
          ),
      )
      ..restore();
    _pintarBota(canvas, pie, a, lado);
  }

  // La cadera: une las dos piernas por debajo de la campera.
  Offset deLaCadera(double x, double y) =>
      c.cadera + _girar(Offset(x, y) * a, c.giro * .4);
  final cadera = Path()
    ..moveTo(deLaCadera(-.14, -.02).dx, deLaCadera(-.14, -.02).dy)
    ..lineTo(deLaCadera(.14, -.02).dx, deLaCadera(.14, -.02).dy)
    ..quadraticBezierTo(
      deLaCadera(.14, .09).dx,
      deLaCadera(.14, .09).dy,
      deLaCadera(.05, .13).dx,
      deLaCadera(.05, .13).dy,
    )
    ..quadraticBezierTo(
      deLaCadera(0, .1).dx,
      deLaCadera(0, .1).dy,
      deLaCadera(-.05, .13).dx,
      deLaCadera(-.05, .13).dy,
    )
    ..quadraticBezierTo(
      deLaCadera(-.14, .09).dx,
      deLaCadera(-.14, .09).dy,
      deLaCadera(-.14, -.02).dx,
      deLaCadera(-.14, -.02).dy,
    )
    ..close();
  canvas.drawPath(
    cadera,
    _degradado(deLaCadera(-.14, 0), deLaCadera(.14, 0), const [
      _pantalonClaro,
      _pantalon,
      Color(0xFF1B1E25),
    ]),
  );

  // El torso: la campera inflable abierta, con sus costuras.
  final torso = _torso(c);
  final cajaTorso = torso.getBounds();
  canvas.drawPath(
    torso,
    _degradado(
      cajaTorso.centerLeft,
      cajaTorso.centerRight,
      const [_camperaClara, _campera, _camperaOscura],
      const [0, .42, 1],
    ),
  );
  Offset delTorso(double x, double y) =>
      c.cadera + _girar(Offset(x, y) * a, c.giro);
  canvas
    ..save()
    ..clipPath(torso);
  // Lo inflado: cada franja con luz arriba y sombra en la costura de abajo.
  for (final y in const [-.25, -.17, -.09, -.01]) {
    final izquierda = delTorso(-.17, y);
    final medio = delTorso(0, y + .018);
    final derecha = delTorso(.17, y);
    final costura = Path()
      ..moveTo(izquierda.dx, izquierda.dy)
      ..quadraticBezierTo(medio.dx, medio.dy, derecha.dx, derecha.dy);
    canvas
      ..drawPath(
        costura.shift(_girar(Offset(0, -a * .016), c.giro)),
        _trazo(Colors.white.withValues(alpha: .16), a * .02),
      )
      ..drawPath(
        costura,
        _trazo(_camperaOscura.withValues(alpha: .7), a * .007),
      );
  }
  // La sombra de abajo de la campera, donde se dobla.
  canvas
    ..drawRect(
      cajaTorso,
      _degradado(delTorso(0, -.06), delTorso(0, .03), [
        Colors.black.withValues(alpha: 0),
        Colors.black.withValues(alpha: .22),
      ]),
    )
    ..restore();

  // Adelante, abierta: el chaleco, la camisa y los botones.
  final abierto = Path()
    ..moveTo(delTorso(-.055, -.305).dx, delTorso(-.055, -.305).dy)
    ..lineTo(delTorso(.055, -.305).dx, delTorso(.055, -.305).dy)
    ..quadraticBezierTo(
      delTorso(.06, -.14).dx,
      delTorso(.06, -.14).dy,
      delTorso(.035, .02).dx,
      delTorso(.035, .02).dy,
    )
    ..lineTo(delTorso(-.035, .02).dx, delTorso(-.035, .02).dy)
    ..quadraticBezierTo(
      delTorso(-.06, -.14).dx,
      delTorso(-.06, -.14).dy,
      delTorso(-.055, -.305).dx,
      delTorso(-.055, -.305).dy,
    )
    ..close();
  final camisa = Path()
    ..moveTo(delTorso(-.05, -.305).dx, delTorso(-.05, -.305).dy)
    ..lineTo(delTorso(.05, -.305).dx, delTorso(.05, -.305).dy)
    ..lineTo(delTorso(0, -.2).dx, delTorso(0, -.2).dy)
    ..close();
  final botones = Path();
  for (final y in const [-.17, -.11, -.05]) {
    botones.addOval(Rect.fromCircle(center: delTorso(0, y), radius: a * .007));
  }
  canvas
    ..drawPath(
      abierto,
      _degradado(delTorso(-.05, -.2), delTorso(.05, -.2), const [
        Color(0xFF4A494D),
        _chaleco,
        Color(0xFF1F1E21),
      ]),
    )
    ..drawPath(camisa, Paint()..color = _camisa)
    ..drawPath(botones, Paint()..color = const Color(0xFF8C8A90))
    // El borde del cierre, a cada lado.
    ..drawPath(
      Path()
        ..moveTo(delTorso(-.058, -.3).dx, delTorso(-.058, -.3).dy)
        ..quadraticBezierTo(
          delTorso(-.064, -.14).dx,
          delTorso(-.064, -.14).dy,
          delTorso(-.038, .02).dx,
          delTorso(-.038, .02).dy,
        )
        ..moveTo(delTorso(.058, -.3).dx, delTorso(.058, -.3).dy)
        ..quadraticBezierTo(
          delTorso(.064, -.14).dx,
          delTorso(.064, -.14).dy,
          delTorso(.038, .02).dx,
          delTorso(.038, .02).dy,
        ),
      _trazo(_camperaClara.withValues(alpha: .8), a * .008),
    );

  // El cuello de piel de la capucha, sobre los hombros y detras de la
  // cabeza: esponjoso por fuera.
  final centroPiel = c.cuello + _girar(Offset(0, a * .012), c.giro);
  final piel = Path();
  const ondas = 16;
  for (var i = 0; i <= ondas; i++) {
    final angulo = math.pi * (1 + i / ondas);
    final radio = i.isEven ? 1.0 : .9;
    final p =
        centroPiel +
        _girar(
          Offset(
            math.cos(angulo) * a * .13 * radio,
            math.sin(angulo) * a * .075 * radio,
          ),
          c.giro,
        );
    if (i == 0) {
      piel.moveTo(p.dx, p.dy);
    } else {
      piel.lineTo(p.dx, p.dy);
    }
  }
  for (var i = ondas; i >= 0; i--) {
    final angulo = math.pi * (1 + i / ondas);
    final p =
        centroPiel +
        _girar(
          Offset(math.cos(angulo) * a * .08, math.sin(angulo) * a * .035),
          c.giro,
        );
    piel.lineTo(p.dx, p.dy);
  }
  piel.close();
  canvas.drawPath(
    piel,
    _degradado(
      centroPiel - Offset(a * .1, a * .07),
      centroPiel + Offset(a * .12, a * .01),
      const [_pielDeAbrigo, _pielDeAbrigoSombra],
    ),
  );

  // El brazo de la derecha (el de la manivela), que va al costado.
  _brazo(canvas, c.hombroDerecho, c.codoDerecho, c.manoDerecha, a);

  // La cabeza: la suya, con el pelo redondeado arriba (la foto lo corta), y
  // el cuello de la camisa con el moño.
  _cabeza(canvas, c, cara);

  // El brazo de la izquierda, que cruza el pecho hasta el corcho.
  _brazo(canvas, c.hombroIzquierdo, c.codoIzquierdo, c.manoIzquierda, a);
}

/// La campera, de los hombros al ruedo, en el giro del torso.
Path _torso(CuerpoPescador c) {
  final a = c.alto;
  Offset p(double x, double y) => c.cadera + _girar(Offset(x, y) * a, c.giro);
  final camino = Path();
  void ir(Offset q) => camino.moveTo(q.dx, q.dy);
  void curva(Offset control, Offset q) =>
      camino.quadraticBezierTo(control.dx, control.dy, q.dx, q.dy);
  ir(p(-.05, -.315));
  curva(p(-.1, -.318), p(-.138, -.29));
  curva(p(-.16, -.26), p(-.154, -.18));
  curva(p(-.146, -.08), p(-.15, .02));
  curva(p(-.148, .045), p(-.12, .045));
  curva(p(0, .06), p(.12, .045));
  curva(p(.148, .045), p(.15, .02));
  curva(p(.146, -.08), p(.154, -.18));
  curva(p(.16, -.26), p(.138, -.29));
  curva(p(.1, -.318), p(.05, -.315));
  camino.close();
  return camino;
}

/// Una manga inflable del hombro a la muñeca, con su puño.
void _brazo(Canvas canvas, Offset hombro, Offset codo, Offset mano, double a) {
  final hacia = mano - codo;
  final muneca = mano - hacia / math.max(1e-6, hacia.distance) * (a * .035);
  final manga = _miembro([hombro, codo, muneca], [a * .12, a * .1, a * .085]);
  canvas
    ..drawPath(
      manga,
      _volumen(
        hombro,
        muneca,
        a * .11,
        _camperaClara,
        _campera,
        _camperaOscura,
      ),
    )
    // Lo inflado de la manga: una costura en el codo, que se dobla con el.
    ..save()
    ..clipPath(manga)
    ..drawPath(
      Path()
        ..moveTo(
          (codo + _girar(hacia, math.pi / 2) / hacia.distance * a * .07).dx,
          (codo + _girar(hacia, math.pi / 2) / hacia.distance * a * .07).dy,
        )
        ..lineTo(
          (codo - _girar(hacia, math.pi / 2) / hacia.distance * a * .07).dx,
          (codo - _girar(hacia, math.pi / 2) / hacia.distance * a * .07).dy,
        ),
      _trazo(_camperaOscura.withValues(alpha: .55), a * .007),
    )
    ..restore()
    // El puño de la manga.
    ..drawPath(
      _miembro(
        [
          muneca - hacia / hacia.distance * a * .02,
          muneca - hacia / hacia.distance * a * .005,
          muneca + hacia / hacia.distance * a * .01,
        ],
        [a * .09, a * .092, a * .09],
      ),
      Paint()..color = _camperaOscura,
    );
}

/// Una bota con piel en la caña, la puntera hacia afuera.
void _pintarBota(Canvas canvas, Offset pie, double a, double lado) {
  final forma = Path()
    ..moveTo(pie.dx - a * .05, pie.dy - a * .085)
    ..lineTo(pie.dx + a * .05, pie.dy - a * .085)
    ..quadraticBezierTo(
      pie.dx + a * .055,
      pie.dy - a * .04,
      pie.dx + a * (lado > 0 ? .1 : .06),
      pie.dy - a * .02,
    )
    ..quadraticBezierTo(
      pie.dx + a * (lado > 0 ? .115 : .07),
      pie.dy,
      pie.dx + a * (lado > 0 ? .085 : .05),
      pie.dy + a * .004,
    )
    ..lineTo(pie.dx - a * (lado < 0 ? .085 : .05), pie.dy + a * .004)
    ..quadraticBezierTo(
      pie.dx - a * (lado < 0 ? .115 : .07),
      pie.dy,
      pie.dx - a * (lado < 0 ? .1 : .06),
      pie.dy - a * .02,
    )
    ..quadraticBezierTo(
      pie.dx - a * .055,
      pie.dy - a * .04,
      pie.dx - a * .05,
      pie.dy - a * .085,
    )
    ..close();
  final caja = forma.getBounds();
  canvas
    ..drawPath(
      forma,
      _degradado(caja.topLeft, caja.bottomRight, const [
        _botaClara,
        _bota,
        Color(0xFF3E2513),
      ]),
    )
    // La suela.
    ..drawPath(
      Path()
        ..moveTo(caja.left + a * .01, pie.dy - a * .01)
        ..lineTo(caja.right - a * .01, pie.dy - a * .01),
      _trazo(const Color(0xFF2A1A0E), a * .016),
    )
    // El brillo de la puntera.
    ..drawOval(
      Rect.fromCenter(
        center: Offset(pie.dx + lado * a * .045, pie.dy - a * .035),
        width: a * .035,
        height: a * .014,
      ),
      Paint()..color = Colors.white.withValues(alpha: .25),
    );
  // La piel de arriba, esponjosa.
  final piel = Path();
  const ondas = 9;
  for (var i = 0; i <= ondas; i++) {
    final x = pie.dx - a * .06 + a * .12 * i / ondas;
    final y = pie.dy - a * (.098 + (i.isEven ? .014 : 0));
    if (i == 0) {
      piel.moveTo(x, y);
    } else {
      piel.lineTo(x, y);
    }
  }
  piel
    ..lineTo(pie.dx + a * .058, pie.dy - a * .074)
    ..quadraticBezierTo(
      pie.dx,
      pie.dy - a * .066,
      pie.dx - a * .058,
      pie.dy - a * .074,
    )
    ..close();
  canvas.drawPath(
    piel,
    _degradado(
      Offset(pie.dx, pie.dy - a * .11),
      Offset(pie.dx, pie.dy - a * .07),
      const [_pielDeAbrigo, _pielDeAbrigoSombra],
    ),
  );
}

/// La cabeza de MacIAs: la de la foto, con el gesto de ahora, parada sobre el
/// cuello; arriba el pelo que la foto corta, y abajo el cuello de la camisa
/// y el moño.
void _cabeza(Canvas canvas, CuerpoPescador c, ui.Image? cara) {
  final a = c.alto;
  // En la foto (512) la cabeza va del pelo (arriba, cortado) al cuello
  // (fila 398): eso es .235 del alto de MacIAs (un poco cabezon, de
  // dibujito).
  final escala = a * .235 / 398;
  final giro = c.giro * .6 + c.giroCabeza;
  canvas
    ..save()
    ..translate(c.cuello.dx, c.cuello.dy)
    ..rotate(giro)
    ..scale(escala)
    ..translate(-253, -398);
  // El pelo de arriba, que la foto corta: redondeado, del color del pelo.
  canvas.drawPath(
    Path()
      ..moveTo(150, 40)
      ..quadraticBezierTo(170, -6, 253, -16)
      ..quadraticBezierTo(336, -6, 356, 40)
      ..close(),
    Paint()..color = _pelo,
  );
  if (cara != null) {
    canvas.drawImageRect(
      cara,
      Rect.fromLTWH(0, 0, cara.width.toDouble(), cara.height.toDouble()),
      const Rect.fromLTWH(0, 0, 512, 512),
      Paint()..filterQuality = FilterQuality.medium,
    );
  } else {
    // Mientras carga la foto: la cara en su tono, sin gesto.
    canvas.drawOval(
      const Rect.fromLTRB(130, 60, 376, 398),
      Paint()..color = _piel,
    );
  }
  // El cuello de la camisa y el moño, sobre lo de abajo del cuello.
  canvas
    ..drawPath(
      Path()
        ..moveTo(196, 372)
        ..lineTo(253, 412)
        ..lineTo(226, 436)
        ..lineTo(182, 398)
        ..close()
        ..moveTo(310, 372)
        ..lineTo(253, 412)
        ..lineTo(280, 436)
        ..lineTo(324, 398)
        ..close(),
      _degradado(const Offset(253, 372), const Offset(253, 436), const [
        _camisa,
        Color(0xFFC9C7CC),
      ]),
    )
    ..drawPath(
      Path()
        ..moveTo(253, 414)
        ..lineTo(206, 396)
        ..quadraticBezierTo(198, 414, 206, 432)
        ..close()
        ..moveTo(253, 414)
        ..lineTo(300, 396)
        ..quadraticBezierTo(308, 414, 300, 432)
        ..close(),
      Paint()..color = const Color(0xFF26252A),
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(253, 414), width: 22, height: 26),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF3B3A40),
    )
    ..restore();
}

/// Las manos de MacIAs, con guantes: van encima de la caña. La izquierda
/// agarra el corcho; la derecha, la perilla de la manivela (o el puño
/// arriba, si festeja).
void pintarManosPescador(Canvas canvas, CuerpoPescador c) {
  final a = c.alto;
  for (final (codo, mano) in [
    (c.codoIzquierdo, c.manoIzquierda),
    (c.codoDerecho, c.manoDerecha),
  ]) {
    final hacia = (mano - codo) / math.max(1e-6, (mano - codo).distance);
    final normal = Offset(-hacia.dy, hacia.dx);
    final centro = mano - hacia * a * .01;
    // El puño: redondeado, mas ancho que largo, con los nudillos.
    final puno = Path()
      ..moveTo(
        (centro - hacia * a * .035 + normal * a * .032).dx,
        (centro - hacia * a * .035 + normal * a * .032).dy,
      )
      ..quadraticBezierTo(
        (centro + hacia * a * .045 + normal * a * .04).dx,
        (centro + hacia * a * .045 + normal * a * .04).dy,
        (centro + hacia * a * .045 - normal * a * .005).dx,
        (centro + hacia * a * .045 - normal * a * .005).dy,
      )
      ..quadraticBezierTo(
        (centro + hacia * a * .04 - normal * a * .045).dx,
        (centro + hacia * a * .04 - normal * a * .045).dy,
        (centro - hacia * a * .035 - normal * a * .032).dx,
        (centro - hacia * a * .035 - normal * a * .032).dy,
      )
      ..close();
    final caja = puno.getBounds();
    canvas
      ..drawPath(
        puno,
        _degradado(caja.topLeft, caja.bottomRight, const [
          _guanteClaro,
          _guante,
          Color(0xFF1C1F24),
        ]),
      )
      ..drawPath(
        Path()
          ..moveTo(
            (centro + hacia * a * .02 + normal * a * .028).dx,
            (centro + hacia * a * .02 + normal * a * .028).dy,
          )
          ..quadraticBezierTo(
            (centro + hacia * a * .034).dx,
            (centro + hacia * a * .034).dy,
            (centro + hacia * a * .02 - normal * a * .03).dx,
            (centro + hacia * a * .02 - normal * a * .03).dy,
          ),
        _trazo(Colors.white.withValues(alpha: .14), a * .006),
      );
  }
}
