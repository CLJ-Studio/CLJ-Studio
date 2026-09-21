import 'dart:typed_data';
import 'dart:ui' as ui;

import 'codificar_jpeg.dart';

/// Medida unica de todas las portadas del catalogo.
///
/// Las tarjetas dibujan la foto en 4:3. Si cada una llegara con su propia
/// proporcion, la cuadricula recortaria por su cuenta y sin criterio: una
/// foto vertical de un producto perderia justo el producto.
const anchoPortada = 1200;
const altoPortada = 900;

/// Deja la foto en 1200 x 900 recortando por el centro, sin deformarla.
///
/// Es lo que hace falta al elegir varias fotos de una vez: pasar por la
/// pantalla de encuadre cinco veces seguidas cansa a cualquiera, asi que se
/// encuadra solo y quien quiera corregir una lo hace despues, foto por foto.
///
/// Recorta y NO estira: se toma del original el rectangulo 4:3 mas grande que
/// quepa, centrado, y ese se lleva a 1200 x 900. Estirar es peor que recortar
/// porque deforma caras y objetos, y eso se nota aunque no se sepa por que.
Future<Uint8List> normalizarPortada(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final cuadro = await codec.getNextFrame();
  final original = cuadro.image;

  try {
    final anchoOriginal = original.width.toDouble();
    final altoOriginal = original.height.toDouble();
    const proporcion = anchoPortada / altoPortada;

    // El recorte mas grande con proporcion 4:3 que entra en la original.
    var anchoRecorte = anchoOriginal;
    var altoRecorte = anchoOriginal / proporcion;
    if (altoRecorte > altoOriginal) {
      altoRecorte = altoOriginal;
      anchoRecorte = altoOriginal * proporcion;
    }

    final origen = ui.Rect.fromLTWH(
      (anchoOriginal - anchoRecorte) / 2,
      (altoOriginal - altoRecorte) / 2,
      anchoRecorte,
      altoRecorte,
    );

    final grabadora = ui.PictureRecorder();
    ui.Canvas(grabadora).drawImageRect(
      original,
      origen,
      const ui.Rect.fromLTWH(0, 0, anchoPortada * 1.0, altoPortada * 1.0),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );

    final dibujo = grabadora.endRecording();
    final destino = await dibujo.toImage(anchoPortada, altoPortada);
    dibujo.dispose();

    try {
      // JPEG y no PNG: ver `comoJpeg`. En una foto la diferencia es de un
      // megabyte a doscientos kilobytes, y eso se nota al abrir el feed.
      return await comoJpeg(destino);
    } finally {
      destino.dispose();
    }
  } finally {
    original.dispose();
    codec.dispose();
  }
}
