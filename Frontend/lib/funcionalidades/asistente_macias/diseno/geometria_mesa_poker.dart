import 'dart:math' as math;
import 'dart:ui';

import '../logica/coreografia_poker.dart';

/// Donde va cada cosa en la mesa de poker, para un tamaño de pantalla y
/// para quien mira: su asiento queda siempre abajo.
///
/// Todo lo que vuela sale y llega a estos mismos puntos, y las cosas quietas
/// se dibujan ahi: cuando una carta termina de volar y aparece la de la mesa,
/// estan en el mismo lugar, del mismo tamaño y con el mismo giro.
class GeometriaMesa {
  GeometriaMesa(this.tamano, {int? yo}) : _yo = yo ?? 0;

  final Size tamano;
  final int _yo;

  static const anchoAsiento = 92.0;
  static const altoAsiento = 124.0;

  /// El centro de la foto dentro de la caja del asiento.
  static const centroFoto = Offset(46, 45);

  static const anchoMiCarta = 54.0;
  static const anchoCartaAjena = 24.0;

  /// Los lugares alrededor del paño, desde el mio (abajo) en el sentido de
  /// las agujas del reloj, en fracciones del paño.
  static const _lugares = [
    Offset(.5, 1.0),
    Offset(0, .74),
    Offset(0, .26),
    Offset(.5, 0),
    Offset(1, .26),
    Offset(1, .74),
  ];

  /// El paño deja lugar a los asientos: los de los costados se apoyan en el
  /// borde, el de arriba asoma y el mio, abajo, lleva sus cartas encima.
  late final Rect pano = Rect.fromLTRB(
    46,
    50,
    math.max(47, tamano.width - 46),
    math.max(51, tamano.height - 80),
  );

  Offset get centro => pano.center;

  /// El ancho de las cartas de la mesa.
  late final double anchoComun = math.min(44.0, pano.width / 6.6);

  /// La caja de un asiento, sin salirse de la pantalla.
  Rect cajaAsiento(int posicion) {
    final lugar = _lugares[(posicion - _yo + 6) % 6];
    final punto = Offset(
      pano.left + lugar.dx * pano.width,
      pano.top + lugar.dy * pano.height,
    );
    final izquierda = (punto.dx - centroFoto.dx)
        .clamp(0.0, math.max(0.0, tamano.width - anchoAsiento))
        .toDouble();
    final arriba = (punto.dy - centroFoto.dy)
        .clamp(0.0, math.max(0.0, tamano.height - altoAsiento))
        .toDouble();
    return Rect.fromLTWH(izquierda, arriba, anchoAsiento, altoAsiento);
  }

  /// El centro de la foto de un asiento.
  Offset asiento(int posicion) => cajaAsiento(posicion).topLeft + centroFoto;

  bool esMio(int posicion) => posicion == _yo;

  /// El lugar alrededor de la mesa: 0 abajo (el mio), 1 y 2 a la
  /// izquierda, 3 arriba, 4 y 5 a la derecha.
  int lugar(int posicion) => (posicion - _yo + 6) % 6;

  /// Hacia que lado queda el centro de la mesa, mirando desde el asiento:
  /// las cartas y el boton van de ese lado, lejos de la etiqueta y la placa.
  /// El de arriba los lleva a la derecha.
  double _lado(int posicion) => lugar(posicion) >= 4 ? -1 : 1;

  /// Donde queda su apuesta: entre su asiento y el centro (la mia, arriba
  /// de mis cartas).
  Offset apuesta(int posicion) =>
      Offset.lerp(asiento(posicion), centro, switch (lugar(posicion)) {
        0 => .56,
        3 => .40,
        _ => .46,
      })!;

  /// El boton del repartidor, a un costado de la foto sin taparle nada.
  Offset botonDealer(int posicion) {
    final foto = asiento(posicion);
    return switch (lugar(posicion)) {
      0 => foto + const Offset(-66, -22),
      3 => foto + const Offset(-42, 4),
      _ => foto + Offset(_lado(posicion) * 46, -30),
    };
  }

  /// La carta [indice] de alguien: las mias grandes sobre mi foto; las
  /// demas, chicas, al costado de la foto que da al centro.
  Offset mano(int posicion, int indice) {
    final foto = asiento(posicion);
    if (esMio(posicion)) {
      return foto + Offset((indice - .5) * anchoMiCarta * .8, -66);
    }
    return foto + Offset(_lado(posicion) * (37 + indice * 11), -3 + indice * 2);
  }

  double anchoMano(int posicion) =>
      esMio(posicion) ? anchoMiCarta : anchoCartaAjena;

  double giroMano(int posicion, int indice) {
    if (esMio(posicion)) return indice == 0 ? -.08 : .08;
    return indice == 0 ? -.16 : .12;
  }

  /// Las cinco de la mesa, en fila por el medio.
  Offset comunitaria(int indice) =>
      Offset(centro.dx + (indice - 2) * anchoComun * 1.12, centro.dy + 8);

  /// El bote, encima de las cartas de la mesa.
  Offset get bote => Offset(centro.dx, centro.dy - anchoComun * .7 - 24);

  /// De donde salen las cartas: el medio de la mesa, como si repartiera
  /// MacIAs desde ahi.
  Offset get mazo => Offset(centro.dx, centro.dy - anchoComun * .25);

  Offset get descarte => centro;

  Offset punto(LugarMesa lugar) => switch (lugar) {
    EnMazo() => mazo,
    EnBote() => bote,
    EnDescarte() => descarte,
    EnAsiento(:final posicion) => asiento(posicion),
    EnApuesta(:final posicion) => apuesta(posicion),
    EnMano(:final posicion, :final indice) => mano(posicion, indice),
    EnComunitaria(:final indice) => comunitaria(indice),
  };

  /// El ancho al que llega una carta a ese lugar.
  double anchoCarta(LugarMesa lugar) => switch (lugar) {
    EnMano(:final posicion) => anchoMano(posicion),
    EnComunitaria() => anchoComun,
    _ => anchoCartaAjena,
  };

  double giroCarta(LugarMesa lugar) => switch (lugar) {
    EnMano(:final posicion, :final indice) => giroMano(posicion, indice),
    _ => 0,
  };
}
