import 'package:supabase_flutter/supabase_flutter.dart';

import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Favoritos persistidos en la tabla `favorites`.
///
/// La RLS ya limita las filas al usuario en sesion, por eso las consultas
/// no filtran por user_id: solo lo envian al insertar, que es obligatorio.
class RepositorioFavoritos {
  const RepositorioFavoritos();

  SupabaseClient get _cliente => Supabase.instance.client;
  String get _usuarioId => _cliente.auth.currentUser!.id;

  /// Trae los productos guardados con su local, porque la pantalla mezcla
  /// vendedores distintos y cada tarjeta necesita saber a cual pertenece.
  Future<List<ProductoMarketplace>> cargar() async {
    final filas = await _cliente
        .from('favorites')
        .select('''
          products(
            id, store_id, name, description, price, emoji, stock, kind,
            stores(
              id, name, description, category_id, emoji, color_hex,
              estimated_time, delivery_cost, is_open, rating_average,
              categories(name)
            )
          )
        ''')
        .order('created_at', ascending: false);

    return filas
        .map((fila) => fila['products'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map(ProductoMarketplace.desdeMapa)
        .toList();
  }

  Future<void> agregar(String productoId) => _cliente.from('favorites').insert({
    'user_id': _usuarioId,
    'product_id': productoId,
  });

  Future<void> quitar(String productoId) => _cliente
      .from('favorites')
      .delete()
      .eq('user_id', _usuarioId)
      .eq('product_id', productoId);
}
