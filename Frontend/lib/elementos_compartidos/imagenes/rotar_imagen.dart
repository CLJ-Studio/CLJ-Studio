import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Gira una foto un cuarto de vuelta a la derecha.
///
/// Hace falta mas seguido de lo que parece: una foto sacada con el telefono
/// de costado llega acostada, y encuadrar una foto acostada es imposible,
/// porque lo que se quiere mostrar esta de lado.
///
/// El paquete de recorte no sabe girar, asi que se gira la imagen misma y se
/// le vuelve a entregar ya derecha. Como el resultado se reencuadra despues,
/// no importa que el giro sea una operacion aparte.
Future<Uint8List> rotarUnCuarto(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final cuadro = await codec.getNextFrame();
  final original = cuadro.image;

  try {
    // Al girar 90 grados, alto y ancho se intercambian.
    final ancho = original.height;
    final alto = original.width;

    final grabadora = ui.PictureRecorder();
    final lienzo = ui.Canvas(grabadora);

    // Se lleva el origen a la esquina que queda arriba a la derecha tras el
    // giro; si no, la imagen se dibuja fuera del lienzo y sale en blanco.
    lienzo.translate(ancho.toDouble(), 0);
    lienzo.rotate(math.pi / 2);
    lienzo.drawImage(
      original,
      ui.Offset.zero,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );

    final dibujo = grabadora.endRecording();
    final girada = await dibujo.toImage(ancho, alto);
    dibujo.dispose();

    try {
      final datos = await girada.toByteData(format: ui.ImageByteFormat.png);
      if (datos == null) throw StateError('Imagen sin datos');
      return datos.buffer.asUint8List();
    } finally {
      girada.dispose();
    }
  } finally {
    original.dispose();
    codec.dispose();
  }
}
