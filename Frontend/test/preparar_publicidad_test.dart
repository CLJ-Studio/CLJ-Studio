import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/configuracion_usuario/pantalla/pantalla_recortar_publicidad.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/publicidad.dart';

/// Un PNG de [colores].length x 1, un pixel de cada color.
Future<Uint8List> franja(List<ui.Color> colores) async {
  final grabadora = ui.PictureRecorder();
  final lienzo = ui.Canvas(grabadora);
  for (final (x, color) in colores.indexed) {
    lienzo.drawRect(
      ui.Rect.fromLTWH(x.toDouble(), 0, 1, 1),
      ui.Paint()..color = color,
    );
  }
  final dibujo = grabadora.endRecording();
  final imagen = await dibujo.toImage(colores.length, 1);
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  dibujo.dispose();
  imagen.dispose();
  return datos!.buffer.asUint8List();
}

/// Medida y pixeles de una imagen ya codificada.
Future<(int, int, ByteData)> abrir(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final cuadro = await codec.getNextFrame();
  final imagen = cuadro.image;
  final pixeles = await imagen.toByteData(format: ui.ImageByteFormat.rawRgba);
  final resultado = (imagen.width, imagen.height, pixeles!);
  imagen.dispose();
  codec.dispose();
  return resultado;
}

int rojoEn(ByteData pixeles, int ancho, int x, int y) =>
    pixeles.getUint8((y * ancho + x) * 4);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const banner = UbicacionPublicidad.bannerPrincipal;

  test('sale a la medida del espacio y en JPEG', () async {
    final preparada = await prepararImagenPublicidad(
      await franja(const [ui.Color(0xFF000000), ui.Color(0xFFFFFFFF)]),
      banner,
    );

    // FF D8 es la firma de un JPEG.
    expect(preparada.bytes.sublist(0, 2), [0xFF, 0xD8]);
    final (ancho, alto, _) = await abrir(preparada.bytes);
    expect((ancho, alto), (banner.anchoRecomendado, banner.altoRecomendado));
    expect(preparada.anchoRecorte, 2);
  });

  test('al agrandar no quedan cuadritos', () async {
    // Negro y blanco, un pixel cada uno, llevados a 1680 de ancho. Copiando
    // pixeles (lo que pasaba antes en la web) el centro seria negro puro o
    // blanco puro. Interpolando, ahi hay gris.
    final preparada = await prepararImagenPublicidad(
      await franja(const [ui.Color(0xFF000000), ui.Color(0xFFFFFFFF)]),
      banner,
    );
    final (ancho, alto, pixeles) = await abrir(preparada.bytes);
    final centro = rojoEn(pixeles, ancho, ancho ~/ 2, alto ~/ 2);
    expect(centro, inInclusiveRange(40, 215));

    // Y la transicion es gradual: de izquierda a derecha nunca baja.
    var anterior = -1;
    for (var x = ancho ~/ 4; x <= ancho * 3 ~/ 4; x += ancho ~/ 40) {
      final valor = rojoEn(pixeles, ancho, x, alto ~/ 2);
      expect(valor, greaterThanOrEqualTo(anterior - 6));
      anterior = valor;
    }
  });

  test('lo transparente queda blanco, no negro', () async {
    final preparada = await prepararImagenPublicidad(
      await franja(const [ui.Color(0x00000000), ui.Color(0x00000000)]),
      banner,
    );
    final (ancho, alto, pixeles) = await abrir(preparada.bytes);
    expect(rojoEn(pixeles, ancho, ancho ~/ 2, alto ~/ 2), greaterThan(245));
  });

  test('avisa cuando el recorte no da para el espacio', () {
    expect(recorteChicoPara(72, banner), isTrue);
    expect(recorteChicoPara(839, banner), isTrue);
    // La mitad del ancho pedido todavia se ve bien en un telefono.
    expect(recorteChicoPara(840, banner), isFalse);
    expect(recorteChicoPara(2400, banner), isFalse);
  });
}
