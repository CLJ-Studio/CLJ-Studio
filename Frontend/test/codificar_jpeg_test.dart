import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/imagenes/codificar_jpeg.dart';
import 'package:upsa_eat/elementos_compartidos/imagenes/normalizar_portada.dart';

/// Dibuja algo parecido a una fotografía: degradados y ruido, no colores
/// planos. Importa para la medición, porque PNG comprime muy bien lo plano y
/// muy mal lo fotográfico, que es justo el caso real del catálogo.
Future<ui.Image> fotoFalsa(int ancho, int alto) async {
  final grabadora = ui.PictureRecorder();
  final lienzo = ui.Canvas(grabadora);
  lienzo.drawRect(
    ui.Rect.fromLTWH(0, 0, ancho.toDouble(), alto.toDouble()),
    ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset.zero,
        ui.Offset(ancho.toDouble(), alto.toDouble()),
        const [ui.Color(0xFFB22222), ui.Color(0xFF104E8B)],
      ),
  );

  final azar = math.Random(7);
  for (var i = 0; i < 4000; i++) {
    lienzo.drawCircle(
      ui.Offset(azar.nextDouble() * ancho, azar.nextDouble() * alto),
      azar.nextDouble() * 6,
      ui.Paint()
        ..color = ui.Color.fromARGB(
          140,
          azar.nextInt(256),
          azar.nextInt(256),
          azar.nextInt(256),
        ),
    );
  }

  final dibujo = grabadora.endRecording();
  final imagen = await dibujo.toImage(ancho, alto);
  dibujo.dispose();
  return imagen;
}

Future<Uint8List> comoPng(ui.Image imagen) async {
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  return datos!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('una portada en JPEG pesa mucho menos que en PNG', () async {
    // Es la razon de ser de todo esto: las fotos del catalogo estaban
    // subiendose en PNG y pesaban entre 800 KB y 1,4 MB cada una.
    final imagen = await fotoFalsa(anchoPortada, altoPortada);

    final png = await comoPng(imagen);
    final jpeg = await comoJpeg(imagen);
    imagen.dispose();

    expect(
      jpeg.length,
      lessThan(png.length ~/ 3),
      reason:
          'JPEG ${jpeg.length ~/ 1024} KB contra PNG ${png.length ~/ 1024} KB',
    );
  });

  test('la portada normalizada se guarda como JPEG', () async {
    final imagen = await fotoFalsa(1600, 1200);
    final origen = await comoPng(imagen);
    imagen.dispose();

    final portada = await normalizarPortada(origen);

    // Cabecera JPEG: los dos primeros bytes son siempre FF D8.
    expect(portada[0], 0xFF);
    expect(portada[1], 0xD8);
  });

  test('la portada normalizada sigue midiendo 1200 x 900', () async {
    final imagen = await fotoFalsa(900, 1600);
    final origen = await comoPng(imagen);
    imagen.dispose();

    final portada = await normalizarPortada(origen);
    final codec = await ui.instantiateImageCodec(portada);
    final cuadro = await codec.getNextFrame();

    expect(cuadro.image.width, anchoPortada);
    expect(cuadro.image.height, altoPortada);
    cuadro.image.dispose();
    codec.dispose();
  });

  test('bytesComoJpeg convierte un PNG ya hecho', () async {
    final imagen = await fotoFalsa(500, 500);
    final png = await comoPng(imagen);
    imagen.dispose();

    final jpeg = await bytesComoJpeg(png);

    expect(jpeg[0], 0xFF);
    expect(jpeg[1], 0xD8);
    expect(jpeg.length, lessThan(png.length));
  });
}
