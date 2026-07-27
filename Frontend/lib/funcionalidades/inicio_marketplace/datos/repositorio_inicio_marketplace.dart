import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/categoria_marketplace.dart';
import '../modelos/local_universitario.dart';
import '../modelos/producto_marketplace.dart';

/// Catalogo del marketplace leido desde Supabase.
///
/// Las RLS ya limitan lo visible a locales activos, asi que las consultas no
/// repiten esas condiciones: solo piden lo que la pantalla necesita mostrar.
class RepositorioInicioMarketplace {
  const RepositorioInicioMarketplace();

  SupabaseClient get _cliente => Supabase.instance.client;

  Future<List<CategoriaMarketplace>> obtenerCategorias() async {
    final filas = await _cliente
        .from('categories')
        .select('id, name, icon_name')
        .order('sort_order');

    // 'Todo' encabeza la barra pero no existe como fila en la base.
    return [
      CategoriaMarketplace.todas,
      ...filas.map(CategoriaMarketplace.desdeMapa),
    ];
  }

  Future<List<LocalUniversitario>> obtenerLocales() async {
    final filas = await _cliente
        .from('stores')
        .select(
          'id, name, description, category_id, emoji, color_hex, '
          'estimated_time, delivery_cost, is_open, rating_average, '
          'is_personal, logo_path, categories(name)',
        )
        // Los abiertos primero; dentro de cada grupo, los mejor calificados.
        .order('is_open', ascending: false)
        .order('rating_average', ascending: false);

    return filas.map(LocalUniversitario.desdeMapa).toList();
  }

  Future<List<ProductoMarketplace>> obtenerProductos(String localId) async {
    final filas = await _cliente
        .from('products')
        .select(
          'id, store_id, name, description, price, emoji, stock, kind, '
          'image_path',
        )
        .eq('store_id', localId)
        .eq('is_available', true)
        .order('created_at');

    return filas.map(ProductoMarketplace.desdeMapa).toList();
  }
}
