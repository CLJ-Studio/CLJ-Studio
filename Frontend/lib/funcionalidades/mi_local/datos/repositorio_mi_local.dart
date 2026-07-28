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
      'is_personal, logo_path, categories(name)';

  static const _camposProducto =
      'id, store_id, name, description, price, emoji, stock, kind, '
      'image_path, is_available, product_images(storage_path, position)';

  /// Contenedor de las publicaciones sueltas. Null si nunca publico nada.
  Future<LocalUniversitario?> cargarEspacioPersonal() =>
      _cargarPorTipo(personal: true);

  /// Negocio con vitrina propia. Null si solo publica a titulo personal.
  Future<LocalUniversitario?> cargarNegocio() =>
      _cargarPorTipo(personal: false);

  /// Los dos conviven: publicar algo suelto no debe meterlo en el catalogo
  /// del negocio, que es otra cosa.
  Future<LocalUniversitario?> _cargarPorTipo({required bool personal}) async {
    final fila = await _cliente
        .from('stores')
        .select(_camposLocal)
        .eq('owner_id', _usuarioId)
        .eq('is_active', true)
        .eq('is_personal', personal)
        .maybeSingle();

    return fila == null ? null : LocalUniversitario.desdeMapa(fila);
  }

  /// Todo lo que la persona publico, sin importar en cual de sus dos
  /// espacios cayo. Incluye lo oculto: el dueno debe poder relanzarlo.
  Future<List<ProductoMarketplace>> cargarMisPublicaciones() async {
    final locales = await _cliente
        .from('stores')
        .select('id')
        .eq('owner_id', _usuarioId)
        .eq('is_active', true);
    if (locales.isEmpty) return const [];

    final filas = await _cliente
        .from('products')
        .select(_camposProducto)
        .inFilter(
          'store_id',
          locales.map((fila) => fila['id'] as String).toList(),
        )
        .order('bumped_at', ascending: false);

    return filas.map(ProductoMarketplace.desdeMapa).toList();
  }

  /// Retira el negocio del catalogo y cancela sus pedidos vivos.
  ///
  /// No es un DELETE: `orders.store_id` es `on delete restrict` para que el
  /// historial del comprador no desaparezca porque el vendedor cierre.
  Future<void> cerrarLocal(String localId) =>
      _cliente.rpc<void>('cerrar_local', params: {'p_local': localId});

  /// Incluye las ocultas: el dueno debe verlas para poder relanzarlas.
  Future<List<ProductoMarketplace>> cargarInventario(String localId) async {
    final filas = await _cliente
        .from('products')
        .select(_camposProducto)
        .eq('store_id', localId)
        .order('bumped_at', ascending: false);

    return filas.map(ProductoMarketplace.desdeMapa).toList();
  }

  /// Espacio invisible que permite publicar sin abrir un local formal.
  /// El esquema exige que todo producto pertenezca a un store (pedidos,
  /// stock y RLS dependen de eso); este store personal es ese contenedor.
  Future<LocalUniversitario> crearEspacioPersonal({
    required String nombreEstudiante,
  }) async {
    final fila = await _cliente
        .from('stores')
        .insert({
          'owner_id': _usuarioId,
          'name': 'Ventas de $nombreEstudiante',
          'description': 'Publicaciones personales',
          'emoji': '🛍️',
          'is_personal': true,
        })
        .select(_camposLocal)
        .single();

    return LocalUniversitario.desdeMapa(fila);
  }

  /// Abre un negocio, sin tocar el espacio personal.
  ///
  /// Antes lo convertia, porque solo cabia un store activo por persona: al
  /// abrir un negocio, todo lo publicado a titulo personal pasaba a colgar
  /// de la marca. Ahora son dos registros distintos.
  Future<LocalUniversitario> crearLocal({
    required String nombre,
    required String descripcion,
    required String emoji,
    required String categoriaId,
    String? logoPath,
  }) async {
    final existente = await _cliente
        .from('stores')
        .select('id')
        .eq('owner_id', _usuarioId)
        .eq('is_active', true)
        .eq('is_personal', false)
        .maybeSingle();

    final datos = {
      'name': nombre,
      'description': descripcion,
      'emoji': emoji,
      'category_id': categoriaId,
      'is_personal': false,
      'logo_path': ?logoPath,
    };

    final fila = existente == null
        ? await _cliente
              .from('stores')
              .insert({'owner_id': _usuarioId, ...datos})
              .select(_camposLocal)
              .single()
        : await _cliente
              .from('stores')
              .update(datos)
              .eq('id', existente['id'] as String)
              .select(_camposLocal)
              .single();

    return LocalUniversitario.desdeMapa(fila);
  }

  Future<void> cambiarDisponibilidad(String localId, {required bool abierto}) =>
      _cliente.from('stores').update({'is_open': abierto}).eq('id', localId);

  /// [galeria] son las fotos adicionales; la primera de todas viaja como
  /// `image_path` porque es la que se ve en las tarjetas del catalogo.
  Future<void> agregarProducto({
    required String localId,
    required String nombre,
    required double precio,
    required int stock,
    required String emoji,
    String? descripcion,
    bool esServicio = false,
    List<String> galeria = const [],
  }) async {
    final creado = await _cliente
        .from('products')
        .insert({
          'store_id': localId,
          'name': nombre,
          'description': descripcion ?? '',
          'price': precio,
          'stock': stock,
          'emoji': emoji,
          'kind': esServicio ? 'servicio' : 'producto',
          'image_path': ?galeria.firstOrNull,
        })
        .select('id')
        .single();

    await _guardarGaleria(creado['id'] as String, galeria);
  }

  /// Las fotos secundarias van en `product_images`; se reescriben enteras
  /// porque reordenarlas o quitar una del medio es mas simple asi.
  Future<void> _guardarGaleria(String productoId, List<String> galeria) async {
    await _cliente.from('product_images').delete().eq('product_id', productoId);

    if (galeria.length < 2) return;
    await _cliente.from('product_images').insert([
      for (var i = 1; i < galeria.length; i++)
        {'product_id': productoId, 'storage_path': galeria[i], 'position': i},
    ]);
  }

  Future<void> editarProducto({
    required String productoId,
    required String nombre,
    required double precio,
    required int stock,
    required String emoji,
    String? descripcion,
    List<String> galeria = const [],
  }) async {
    await _cliente
        .from('products')
        .update({
          'name': nombre,
          'description': descripcion ?? '',
          'price': precio,
          'stock': stock,
          'emoji': emoji,
          'image_path': galeria.firstOrNull,
        })
        .eq('id', productoId);

    await _guardarGaleria(productoId, galeria);
  }

  /// Ocultar en vez de borrar: conserva historial y favoritos.
  Future<void> cambiarVisibilidad(String productoId, {required bool visible}) =>
      _cliente
          .from('products')
          .update({'is_available': visible})
          .eq('id', productoId);

  /// Sube la publicacion al tope del catalogo y la vuelve visible.
  Future<void> relanzarProducto(String productoId) =>
      _cliente.rpc('relanzar_producto', params: {'p_producto_id': productoId});

  /// El stock nunca baja de cero: la restriccion de la tabla lo rechazaria.
  Future<void> cambiarStock(String productoId, int nuevoStock) => _cliente
      .from('products')
      .update({'stock': nuevoStock < 0 ? 0 : nuevoStock})
      .eq('id', productoId);

  Future<void> eliminarProducto(String productoId) =>
      _cliente.from('products').delete().eq('id', productoId);
}
