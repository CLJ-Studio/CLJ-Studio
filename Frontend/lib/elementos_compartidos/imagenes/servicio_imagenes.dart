import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../configuracion_aplicacion/modo_local.dart';

/// Seleccion y subida de imagenes al bucket publico `imagenes`.
///
/// Cada archivo se guarda bajo la carpeta del usuario (`<uid>/...`): las
/// politicas de Storage solo permiten escribir ahi, asi que nadie puede
/// pisar imagenes ajenas aunque conozca la ruta.
abstract final class ServicioImagenes {
  static final _selector = ImagePicker();

  /// Abre el selector del sistema, sube la imagen elegida y devuelve su
  /// ruta dentro del bucket. Null si el usuario cancela.
  ///
  /// [etiqueta] distingue el uso en el nombre del archivo ('logo',
  /// 'producto'...), util al depurar el bucket.
  static Future<String?> elegirYSubir({required String etiqueta}) async {
    final elegida = await elegir();
    if (elegida == null) return null;
    if (ModoLocal.activo) return elegida.rutaLocal;

    return subir(bytes: elegida.bytes, etiqueta: etiqueta);
  }

  /// Solo elige y devuelve los bytes, sin subir nada.
  ///
  /// Existe separado para poder meter un paso en medio, como el recorte del
  /// avatar: subir primero y recortar despues dejaria basura en el bucket.
  static Future<ImagenElegida?> elegir({
    double maxWidth = 1280,
    int imageQuality = 82,
  }) async {
    final archivo = await _selector.pickImage(
      source: ImageSource.gallery,
      // Reencoda a un tamano razonable: nadie necesita fotos de 12 MP para
      // una tarjeta de producto, y el plan gratuito de Storage se agradece.
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    if (archivo == null) return null;

    return ImagenElegida(
      bytes: await archivo.readAsBytes(),
      rutaLocal: archivo.path,
      tipo: archivo.mimeType ?? 'image/jpeg',
    );
  }

  /// Sube bytes ya listos y devuelve su ruta dentro del bucket.
  static Future<String> subir({
    required Uint8List bytes,
    required String etiqueta,
    String tipo = 'image/jpeg',
  }) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final extension = tipo.contains('png') ? 'png' : 'jpg';
    final ruta =
        '$uid/${DateTime.now().millisecondsSinceEpoch}_$etiqueta.$extension';

    await Supabase.instance.client.storage
        .from('imagenes')
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: FileOptions(
            contentType: tipo,
            // Un ano. Cada subida estrena ruta (lleva la marca de tiempo
            // arriba), asi que el archivo de una ruta NUNCA cambia: no hay
            // nada que revalidar. Por defecto Supabase manda una hora, y
            // entonces el navegador vuelve a preguntar por cada foto del
            // catalogo cada sesion larga, que es puro viaje perdido.
            cacheControl: '31536000',
          ),
        );

    return ruta;
  }

  /// URL publica y cacheable de una ruta del bucket.
  static String? urlPublica(String? ruta) {
    if (ruta == null || ruta.isEmpty) return null;
    if (ModoLocal.activo ||
        ruta.startsWith('blob:') ||
        ruta.startsWith('data:') ||
        ruta.startsWith('http')) {
      return ruta;
    }
    return Supabase.instance.client.storage.from('imagenes').getPublicUrl(ruta);
  }
}

/// Imagen recien elegida, todavia sin subir.
class ImagenElegida {
  const ImagenElegida({
    required this.bytes,
    required this.rutaLocal,
    required this.tipo,
  });

  final Uint8List bytes;

  /// Ruta del archivo en el dispositivo; solo la usa el modo sin servidor.
  final String rutaLocal;

  final String tipo;
}
