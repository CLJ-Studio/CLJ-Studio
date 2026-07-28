import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/categoria_marketplace.dart';
import '../modelos/local_universitario.dart';
import '../modelos/producto_marketplace.dart';

/// Catalogo del marketplace leido desde Supabase.
class RepositorioInicioMarketplace {
  const RepositorioInicioMarketplace();

  SupabaseClient get _cliente => Supabase.instance.client;

  /// Campos de producto compartidos por el catalogo y el detalle.
  static const camposProducto =
      'id, store_id, name, description, price, emoji, stock, kind, '
      'image_path, is_available, product_images(storage_path, position)';

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

  /// Se lee de la vista y no de `stores` porque incluye el avatar del
  /// vendedor y una portada tomada de sus productos: la RLS de `profiles`
  /// impide obtener lo primero con un join normal.
  Future<List<LocalUniversitario>> obtenerLocales() async {
    final filas = await _cliente
        .from('locales_publicos')
        .select()
        // Los abiertos primero; dentro de cada grupo, los mejor calificados.
        .order('is_open', ascending: false)
        .order('rating_average', ascending: false);

    return filas.map(LocalUniversitario.desdeMapa).toList();
  }

  /// Todo lo publicado en el campus, de todos los vendedores.
  ///
  /// El inicio muestra publicaciones y no locales: con locales, quien
  /// publicaba tres cosas seguia viendo una sola tarjeta y parecia que las
  /// anteriores se habian borrado.
  Future<List<ProductoMarketplace>> obtenerPublicaciones() async {
    final filas = await _cliente
        .from('products')
        .select('''
          id, store_id, name, description, price, emoji, stock, kind,
          image_path, is_available, product_images(storage_path, position),
          stores!inner(
            id, name, description, category_id, emoji, color_hex,
            estimated_time, delivery_cost, is_open, rating_average,
            is_personal, logo_path, is_active, categories(name)
          )
        ''')
        .eq('is_available', true)
        .eq('stores.is_active', true)
        // Lo mas reciente o relanzado encabeza el feed.
        .order('bumped_at', ascending: false)
        .limit(120);

    return filas.map(ProductoMarketplace.desdeMapa).toList();
  }

  Future<List<ProductoMarketplace>> obtenerProductos(String localId) async {
    final filas = await _cliente
        .from('products')
        .select(camposProducto)
        .eq('store_id', localId)
        .eq('is_available', true)
        // Lo relanzado sube: es justo para eso que existe `bumped_at`.
        .order('bumped_at', ascending: false);

    return filas.map(ProductoMarketplace.desdeMapa).toList();
  }
}
