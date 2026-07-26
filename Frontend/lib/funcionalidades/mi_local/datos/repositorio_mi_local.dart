import 'package:supabase_flutter/supabase_flutter.dart';

import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Local del usuario y su inventario, respaldados por `stores` y `products`.
///
/// Las RLS solo dejan escribir sobre el local propio, asi que estas consultas
/// no comprueban la propiedad: el servidor la impone.
class RepositorioMiLocal {
  const RepositorioMiLocal();

  SupabaseClient get _cliente => Supabase.instance.client;
  String get _usuarioId => _cliente.auth.currentUser!.id;

  static const _camposLocal =
      'id, name, description, category_id, emoji, color_hex, '
      'estimated_time, delivery_cost, is_open, rating_average, '
      'categories(name)';

  /// Null si el estudiante todavia no abrio su local.
  Future<LocalUniversitario?> cargarLocal() async {
    final fila = await _cliente
        .from('stores')
        .select(_camposLocal)
        .eq('owner_id', _usuarioId)
        .eq('is_active', true)
        .maybeSingle();

    return fila == null ? null : LocalUniversitario.desdeMapa(fila);
  }

  Future<List<ProductoMarketplace>> cargarInventario(String localId) async {
    final filas = await _cliente
        .from('products')
        .select('id, store_id, name, description, price, emoji, stock, kind')
        .eq('store_id', localId)
        .order('created_at');

    return filas.map(ProductoMarketplace.desdeMapa).toList();
  }

  Future<LocalUniversitario> crearLocal({
    required String nombre,
    required String descripcion,
    required String emoji,
    required String categoriaId,
  }) async {
    final fila = await _cliente
        .from('stores')
        .insert({
          'owner_id': _usuarioId,
          'name': nombre,
          'description': descripcion,
          'emoji': emoji,
          'category_id': categoriaId,
        })
        .select(_camposLocal)
        .single();

    return LocalUniversitario.desdeMapa(fila);
  }

  Future<void> cambiarDisponibilidad(String localId, {required bool abierto}) =>
      _cliente.from('stores').update({'is_open': abierto}).eq('id', localId);

  Future<void> agregarProducto({
    required String localId,
    required String nombre,
    required double precio,
    required int stock,
    required String emoji,
  }) => _cliente.from('products').insert({
    'store_id': localId,
    'name': nombre,
    'price': precio,
    'stock': stock,
    'emoji': emoji,
  });

  /// El stock nunca baja de cero: la restriccion de la tabla lo rechazaria.
  Future<void> cambiarStock(String productoId, int nuevoStock) => _cliente
      .from('products')
      .update({'stock': nuevoStock < 0 ? 0 : nuevoStock})
      .eq('id', productoId);

  Future<void> eliminarProducto(String productoId) =>
      _cliente.from('products').delete().eq('id', productoId);
}
