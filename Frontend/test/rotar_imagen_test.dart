import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/imagenes/rotar_imagen.dart';

/// Genera un PNG con la mitad izquierda de un color y la derecha de otro,
/// para poder comprobar que el giro mueve el contenido y no solo la medida.
Future<Uint8List> imagenPartida(int ancho, int alto) async {
  final grabadora = ui.PictureRecorder();
  final lienzo = ui.Canvas(grabadora);
  lienzo.drawRect(
    ui.Rect.fromLTWH(0, 0, ancho / 2, alto.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  lienzo.drawRect(
    ui.Rect.fromLTWH(ancho / 2, 0, ancho / 2, alto.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  final dibujo = grabadora.endRecording();
  final imagen = await dibujo.toImage(ancho, alto);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  dibujo.dispose();
  imagen.dispose();
  return datos!.buffer.asUint8List();
}

Future<ui.Image> decodificar(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final cuadro = await codec.getNextFrame();
  codec.dispose();
  return cuadro.image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('girar intercambia ancho y alto', () async {
    // Una foto acostada de 1600x900 tiene que quedar de pie en 900x1600.
    final girada = await rotarUnCuarto(await imagenPartida(1600, 900));
    final imagen = await decodificar(girada);

    expect(imagen.width, 900);
    expect(imagen.height, 1600);
    imagen.dispose();
  });

  test('girar cuatro veces devuelve la medida original', () async {
    var bytes = await imagenPartida(400, 300);
    for (var vuelta = 0; vuelta < 4; vuelta++) {
      bytes = await rotarUnCuarto(bytes);
    }
    final imagen = await decodificar(bytes);

    expect(imagen.width, 400);
    expect(imagen.height, 300);
    imagen.dispose();
  });

  test('gira a la derecha: lo de la izquierda termina arriba', () async {
    // Es la comprobacion que importa. Si el lienzo se trasladara mal, la
    // imagen saldria en blanco o cortada, y la medida seguiria estando bien.
    final girada = await rotarUnCuarto(await imagenPartida(400, 300));
    final imagen = await decodificar(girada);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.rawRgba);

    // Al girar un cuarto a la derecha, la mitad izquierda (roja) pasa a ser
    // la mitad de arriba.
    int pixelEn(int x, int y) {
      final posicion = (y * imagen.width + x) * 4;
      final r = datos!.getUint8(posicion);
      final b = datos.getUint8(posicion + 2);
      return r > b ? 0 : 1; // 0 = rojo, 1 = azul
    }

    expect(
      pixelEn(imagen.width ~/ 2, 10),
      0,
      reason: 'arriba deberia ser rojo',
    );
    expect(
      pixelEn(imagen.width ~/ 2, imagen.height - 10),
      1,
      reason: 'abajo deberia ser azul',
    );
    imagen.dispose();
  });
}
