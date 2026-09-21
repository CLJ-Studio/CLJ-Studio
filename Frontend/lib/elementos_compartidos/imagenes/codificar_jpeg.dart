import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as codificador;

/// Calidad de guardado de las fotos del catalogo.
///
/// 82 es el punto donde la diferencia deja de verse a simple vista y el
/// archivo todavia baja mucho de peso. Mas arriba se paga tamano por una
/// mejora que nadie nota en la tarjeta de un producto.
const calidadJpeg = 82;

/// Convierte una imagen ya dibujada en JPEG.
///
/// POR QUE EXISTE: `dart:ui` solo sabe entregar PNG. PNG guarda pixel por
/// pixel sin perder nada, que es lo correcto para un logotipo o una captura
/// con texto, y lo peor posible para una fotografia: las fotos del catalogo
/// pesaban entre 800 KB y 1,4 MB cada una, contra los ~200 KB del mismo
/// contenido en JPEG. En un feed de veinte publicaciones esa diferencia son
/// veinte megabytes contra cuatro, y por eso las fotos tardaban en aparecer
/// aunque ya estuvieran cacheadas las que se habian visto.
///
/// Se parte de los pixeles en crudo y no de un PNG intermedio: codificar a
/// PNG para volver a decodificarlo seria hacer dos veces el trabajo caro.
Future<Uint8List> comoJpeg(ui.Image imagen) async {
  final crudo = await imagen.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (crudo == null) throw StateError('Imagen sin datos');

  final mapa = codificador.Image.fromBytes(
    width: imagen.width,
    height: imagen.height,
    bytes: crudo.buffer,
    numChannels: 4,
  );

  return codificador.encodeJpg(mapa, quality: calidadJpeg);
}

/// Reencoda a JPEG unos bytes que ya son una imagen.
///
/// El recortador devuelve siempre PNG, y hasta ahora ese PNG se subia con
/// etiqueta `image/jpeg` y extension `.jpg`: el contenido no coincidia con lo
/// que decia ser. Funcionaba porque los navegadores miran los bytes y no la
/// etiqueta, pero pesaba lo que pesa un PNG.
Future<Uint8List> bytesComoJpeg(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final cuadro = await codec.getNextFrame();
  try {
    return await comoJpeg(cuadro.image);
  } finally {
    cuadro.image.dispose();
    codec.dispose();
  }
}
