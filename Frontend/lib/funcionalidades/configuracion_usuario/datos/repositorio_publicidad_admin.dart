import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../inicio_marketplace/modelos/publicidad.dart';

/// Acceso administrativo a anuncios e imágenes.
///
/// La interfaz nunca decide quién es administrador: todas las operaciones
/// vuelven a validarse mediante las políticas RLS del backend.
class RepositorioPublicidadAdmin {
  const RepositorioPublicidadAdmin();

  SupabaseClient get _cliente => Supabase.instance.client;

  static const _campos =
      'id, title, image_path, placement, link_url, sort_order, is_active, '
      'starts_at, ends_at, updated_at';

  Future<bool> esAdministrador() async {
    try {
      final resultado = await _cliente.rpc('soy_administrador');
      return resultado == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Publicidad>> listar() async {
    final filas = await _cliente
        .from('advertisements')
        .select(_campos)
        .order('placement')
        .order('sort_order')
        .order('created_at');
    return filas.map(Publicidad.desdeMapa).nonNulls.toList(growable: false);
  }

  Future<String> subirImagen({
    required Uint8List bytes,
    required String tipo,
  }) async {
    final uid = _cliente.auth.currentUser!.id;
    final extension = tipo.contains('png')
        ? 'png'
        : tipo.contains('webp')
        ? 'webp'
        : 'jpg';
    final ruta = '$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _cliente.storage
        .from('advertisements')
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: FileOptions(contentType: tipo, upsert: false),
        );
    return ruta;
  }

  Future<void> guardar({
    String? id,
    required String titulo,
    required String rutaImagen,
    required UbicacionPublicidad ubicacion,
    required int orden,
    required bool activa,
    String? enlaceUrl,
    DateTime? iniciaEn,
    DateTime? terminaEn,
  }) async {
    final datos = <String, dynamic>{
      'title': titulo.trim(),
      'image_path': rutaImagen,
      'placement': ubicacion.valor,
      'link_url': (enlaceUrl?.trim().isEmpty ?? true)
          ? null
          : enlaceUrl!.trim(),
      'sort_order': orden,
      'is_active': activa,
      'starts_at': iniciaEn?.toUtc().toIso8601String(),
      'ends_at': terminaEn?.toUtc().toIso8601String(),
    };
    if (id == null) {
      await _cliente.from('advertisements').insert(datos);
    } else {
      await _cliente.from('advertisements').update(datos).eq('id', id);
    }
  }

  Future<void> cambiarEstado(Publicidad anuncio, bool activa) async {
    await _cliente
        .from('advertisements')
        .update({'is_active': activa})
        .eq('id', anuncio.id);
  }

  Future<void> eliminar(Publicidad anuncio) async {
    await _cliente.from('advertisements').delete().eq('id', anuncio.id);
    try {
      await _cliente.storage.from('advertisements').remove([
        anuncio.rutaImagen,
      ]);
    } catch (_) {
      // La fila ya no se publica. Un archivo huérfano no debe impedir borrar.
    }
  }

  Future<void> eliminarImagen(String ruta) async {
    try {
      await _cliente.storage.from('advertisements').remove([ruta]);
    } catch (_) {
      // La imagen nueva ya quedó vinculada; limpiar la anterior es secundario.
    }
  }
}
