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
      'image_path, is_available, view_count, '
      'product_images(storage_path, position)';

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
  /// El vendedor se toma de `locales_publicos` y no del join con `stores`.
  /// Unir `profiles` desde la tabla devuelve vacio para todos menos uno: su
  /// RLS solo deja leer el perfil propio. Por eso el detalle mostraba el
  /// nombre del negocio con un "Por" sin nadie detras.
  Future<List<ProductoMarketplace>> obtenerPublicaciones() async {
    final (locales, filas) = await (
      obtenerLocales(),
      _cliente
          .from('products')
          .select(camposProducto)
          .eq('is_available', true)
          // Por recencia, no por vistas. Ordenar por vistas hundia al final
          // todo lo recien publicado, que nace con cero: subias algo y
          // aparecia el ultimo, donde nadie lo veia, asi que nunca ganaba
          // las vistas que lo habrian subido. Lo popular ya tiene su sitio
          // en el carrusel de destacados.
          .order('bumped_at', ascending: false)
          .limit(120),
    ).wait;

    final porId = {for (final local in locales) local.id: local};

    return filas
        .map(
          (fila) => ProductoMarketplace.desdeMapa(
            fila,
            local: porId[fila['store_id'] as String],
          ),
        )
        // Sin local es que su vendedor esta inactivo: la vista ya los excluye,
        // y antes ese filtro lo hacia el `stores.is_active` del join.
        .where((publicacion) => publicacion.local != null)
        .toList();
  }

  /// Un local suelto por su id. Lo necesitan las notificaciones, que solo
  /// guardan la referencia y tienen que resolverla al tocarlas.
  Future<LocalUniversitario?> obtenerLocal(String localId) async {
    final fila = await _cliente
        .from('locales_publicos')
        .select()
        .eq('id', localId)
        .maybeSingle();

    return fila == null ? null : LocalUniversitario.desdeMapa(fila);
  }

  /// Una publicacion con su local ya resuelto, lista para abrir el detalle.
  Future<ProductoMarketplace?> obtenerPublicacion(String productoId) async {
    final fila = await _cliente
        .from('products')
        .select(camposProducto)
        .eq('id', productoId)
        .maybeSingle();
    if (fila == null) return null;

    final local = await obtenerLocal(fila['store_id'] as String);
    if (local == null) return null;

    return ProductoMarketplace.desdeMapa(fila, local: local);
  }

  /// Nombre y carrera de una persona, sin datos sensibles.
  ///
  /// Sale de `perfiles_publicos`, que corre como owner y solo deja salir lo
  /// que puede ver cualquiera: el whatsapp jamas aparece ahi.
  Future<({String nombre, String carrera, String biografia})?>
  obtenerPerfilPublico(String usuarioId) async {
    final fila = await _cliente
        .from('perfiles_publicos')
        .select('full_name, career, bio')
        .eq('id', usuarioId)
        .maybeSingle();
    if (fila == null) return null;

    return (
      nombre: (fila['full_name'] as String?) ?? '',
      carrera: (fila['career'] as String?) ?? '',
      biografia: (fila['bio'] as String?) ?? '',
    );
  }

  /// Los locales de una misma persona: su espacio personal y su negocio.
  ///
  /// El perfil publico los necesita separados porque una publicacion suelta
  /// no es lo mismo que un producto del local, y cada pestaña enseña una cosa.
  Future<List<LocalUniversitario>> obtenerLocalesDe(String duenoId) async {
    final filas = await _cliente
        .from('locales_publicos')
        .select()
        .eq('owner_id', duenoId);

    return filas.map(LocalUniversitario.desdeMapa).toList();
  }

  /// Publicaciones de varios locales a la vez, con su local ya resuelto.
  Future<List<ProductoMarketplace>> obtenerProductosDe(
    List<LocalUniversitario> locales,
  ) async {
    if (locales.isEmpty) return const [];
    final porId = {for (final local in locales) local.id: local};

    final filas = await _cliente
        .from('products')
        .select(camposProducto)
        .inFilter('store_id', porId.keys.toList())
        .eq('is_available', true)
        .order('bumped_at', ascending: false);

    return filas
        .map(
          (fila) => ProductoMarketplace.desdeMapa(
            fila,
            local: porId[fila['store_id'] as String],
          ),
        )
        .toList();
  }

  /// Lo que esa persona marco como favorito, si decidio enseñarlo.
  ///
  /// La funcion del servidor devuelve vacio cuando lo tiene apagado, asi que
  /// aqui no hace falta comprobar nada: sin ids no hay nada que pedir.
  Future<List<ProductoMarketplace>> obtenerFavoritosPublicos(
    String duenoId,
  ) async {
    final ids = await _cliente.rpc<List<dynamic>>(
      'favoritos_publicos',
      params: {'p_usuario': duenoId},
    );
    if (ids.isEmpty) return const [];

    final filas = await _cliente
        .from('products')
        .select('$camposProducto, stores!inner(*)')
        .inFilter('id', ids.cast<String>())
        .eq('is_available', true);

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
