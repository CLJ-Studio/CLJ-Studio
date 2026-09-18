import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/imagenes/normalizar_portada.dart';

/// Genera un PNG liso del tamaño pedido, para tener algo que encuadrar.
Future<Uint8List> imagenDe(int ancho, int alto) async {
  final grabadora = ui.PictureRecorder();
  ui.Canvas(grabadora).drawRect(
    ui.Rect.fromLTWH(0, 0, ancho.toDouble(), alto.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF3366CC),
  );
  final dibujo = grabadora.endRecording();
  final imagen = await dibujo.toImage(ancho, alto);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  dibujo.dispose();
  imagen.dispose();
  return datos!.buffer.asUint8List();
}

/// Mide un PNG ya codificado.
Future<(int, int)> medidaDe(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final cuadro = await codec.getNextFrame();
  final medida = (cuadro.image.width, cuadro.image.height);
  cuadro.image.dispose();
  codec.dispose();
  return medida;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('una foto vertical sale en 1200 x 900', () async {
    // El caso que mas duele: una foto de teléfono en vertical metida en una
    // tarjeta apaisada. Si se estirara en vez de recortarse, el producto
    // saldria aplastado.
    final resultado = await normalizarPortada(await imagenDe(900, 1600));

    expect(await medidaDe(resultado), (anchoPortada, altoPortada));
  });

  test('una foto muy apaisada también sale en 1200 x 900', () async {
    final resultado = await normalizarPortada(await imagenDe(3000, 800));

    expect(await medidaDe(resultado), (anchoPortada, altoPortada));
  });

  test('una que ya viene en 4:3 conserva la medida de portada', () async {
    final resultado = await normalizarPortada(await imagenDe(800, 600));

    expect(await medidaDe(resultado), (anchoPortada, altoPortada));
  });

  test('una foto cuadrada no queda deformada, queda recortada', () async {
    // Cuadrada a 4:3 significa perder arriba y abajo, nunca ensanchar.
    final resultado = await normalizarPortada(await imagenDe(1000, 1000));

    expect(await medidaDe(resultado), (anchoPortada, altoPortada));
  });

  test('la portada siempre tiene proporción 4:3', () {
    expect(anchoPortada / altoPortada, closeTo(4 / 3, 0.0001));
  });
}
