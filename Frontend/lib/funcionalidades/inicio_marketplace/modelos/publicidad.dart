import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../configuracion_aplicacion/modo_local.dart';

/// Espacios publicitarios admitidos por el backend.
enum UbicacionPublicidad {
  bannerPrincipal('main_banner', 'Banner principal', 1680, 1000),
  carruselEmpresas('company_carousel', 'Carrusel de empresas', 1350, 520);

  const UbicacionPublicidad(
    this.valor,
    this.etiqueta,
    this.anchoRecomendado,
    this.altoRecomendado,
  );

  final String valor;
  final String etiqueta;
  final int anchoRecomendado;
  final int altoRecomendado;

  double get proporcion => anchoRecomendado / altoRecomendado;

  String get resolucionRecomendada => '$anchoRecomendado × $altoRecomendado px';

  static UbicacionPublicidad? desdeValor(String? valor) {
    for (final ubicacion in values) {
      if (ubicacion.valor == valor) return ubicacion;
    }
    return null;
  }
}

/// Aviso almacenado en `advertisements`.
class Publicidad {
  const Publicidad({
    required this.id,
    required this.titulo,
    required this.rutaImagen,
    required this.ubicacion,
    required this.orden,
    required this.activa,
    this.enlaceUrl,
    this.iniciaEn,
    this.terminaEn,
    this.actualizadoEn,
  });

  final String id;
  final String titulo;
  final String rutaImagen;
  final UbicacionPublicidad ubicacion;
  final String? enlaceUrl;
  final int orden;
  final bool activa;
  final DateTime? iniciaEn;
  final DateTime? terminaEn;
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
      orden: (fila['sort_order'] as num?)?.toInt() ?? 0,
      activa: fila['is_active'] as bool? ?? true,
      iniciaEn: DateTime.tryParse(fila['starts_at'] as String? ?? ''),
      terminaEn: DateTime.tryParse(fila['ends_at'] as String? ?? ''),
      actualizadoEn: DateTime.tryParse(fila['updated_at'] as String? ?? ''),
    );
  }

  bool get tieneEnlace => (enlaceUrl ?? '').isNotEmpty;

  bool get vigenteAhora {
    final ahora = DateTime.now();
    return activa &&
        (iniciaEn == null || !iniciaEn!.isAfter(ahora)) &&
        (terminaEn == null || terminaEn!.isAfter(ahora));
  }

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
