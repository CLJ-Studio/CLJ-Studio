import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../configuracion_aplicacion/modo_local.dart';

/// Dónde se muestra un aviso dentro del inicio.
///
/// Cada ubicación tiene su propia proporción, y la imagen se prepara para
/// esa medida: mezclarlas deforma el aviso o lo recorta.
enum UbicacionPublicidad {
  /// El banner grande de arriba. Proporción 1.68:1 (ideal 1680 × 1000).
  bannerPrincipal('main_banner', 1.68),

  /// Los rectángulos de empresas del carrusel. 2.596:1 (ideal 1620 × 624).
  carruselEmpresas('company_carousel', 270 / 104);

  const UbicacionPublicidad(this.valor, this.proporcion);

  /// El literal del enum `ubicacion_publicidad` en Postgres.
  final String valor;

  /// Ancho dividido alto. El widget reserva el espacio con esta proporción
  /// antes de que la imagen llegue, así el inicio no salta cuando carga.
  final double proporcion;

  static UbicacionPublicidad? desdeValor(String? valor) {
    for (final ubicacion in values) {
      if (ubicacion.valor == valor) return ubicacion;
    }
    // Una ubicación que esta versión de la app no conoce todavía: se ignora
    // en vez de romper el inicio. Permite agregar espacios nuevos en la base
    // sin dejar fuera de servicio a quien no actualizó.
    return null;
  }
}

/// Un aviso publicitario administrado desde Supabase.
///
/// Reemplaza a los banners de `assets/` sin recompilar la aplicación. Si no
/// hay ninguno activo, el inicio vuelve solo a las imágenes locales.
class Publicidad {
  const Publicidad({
    required this.id,
    required this.titulo,
    required this.rutaImagen,
    required this.ubicacion,
    required this.enlaceUrl,
    required this.actualizadoEn,
  });

  final String id;

  /// Nombre interno del aviso; no se muestra. Sirve de texto alternativo
  /// para lectores de pantalla, que si no anunciarían "imagen" y nada más.
  final String titulo;

  final String rutaImagen;
  final UbicacionPublicidad ubicacion;

  /// A dónde lleva al tocarlo. Null cuando el aviso no es navegable.
  final String? enlaceUrl;

  final DateTime? actualizadoEn;

  static Publicidad? desdeMapa(Map<String, dynamic> fila) {
    final ubicacion = UbicacionPublicidad.desdeValor(
      fila['placement'] as String?,
    );
    final ruta = (fila['image_path'] as String?)?.trim() ?? '';
    if (ubicacion == null || ruta.isEmpty) return null;

    return Publicidad(
      id: fila['id'] as String,
      titulo: (fila['title'] as String?)?.trim() ?? '',
      rutaImagen: ruta,
      ubicacion: ubicacion,
      enlaceUrl: (fila['link_url'] as String?)?.trim(),
      actualizadoEn: DateTime.tryParse(fila['updated_at'] as String? ?? ''),
    );
  }

  bool get tieneEnlace => (enlaceUrl ?? '').isNotEmpty;

  /// URL pública de la imagen, con la marca de la última edición pegada.
  ///
  /// El `?v=` importa: si alguien reemplaza el archivo conservando el
  /// nombre, los teléfonos que ya bajaron la versión anterior seguirían
  /// mostrándola durante horas. Cambiar la consulta hace que el sistema lo
  /// trate como una imagen distinta y la vuelva a pedir.
  String get urlImagen {
    if (ModoLocal.activo || rutaImagen.startsWith('http')) return rutaImagen;

    final base = Supabase.instance.client.storage
        .from('advertisements')
        .getPublicUrl(rutaImagen);
    final version = actualizadoEn?.millisecondsSinceEpoch;
    if (version == null) return base;

    return '$base${base.contains('?') ? '&' : '?'}v=$version';
  }
}
