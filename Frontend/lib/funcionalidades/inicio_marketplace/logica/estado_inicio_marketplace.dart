import '../modelos/categoria_marketplace.dart';
import '../modelos/producto_marketplace.dart';

/// Estado del feed de publicaciones del inicio.
class EstadoInicioMarketplace {
  const EstadoInicioMarketplace({
    this.categoriaId = 'todas',
    this.busqueda = '',
    this.publicaciones = const [],
    this.categorias = const [],
    this.cargando = true,
    this.error,
  });

  final String categoriaId;
  final String busqueda;

  /// Publicaciones ya filtradas por categoria y busqueda.
  final List<ProductoMarketplace> publicaciones;
  final List<CategoriaMarketplace> categorias;
  final bool cargando;
  final String? error;

  EstadoInicioMarketplace copiarCon({
    String? categoriaId,
    String? busqueda,
    List<ProductoMarketplace>? publicaciones,
    List<CategoriaMarketplace>? categorias,
    bool? cargando,
    String? error,
  }) => EstadoInicioMarketplace(
    categoriaId: categoriaId ?? this.categoriaId,
    busqueda: busqueda ?? this.busqueda,
    publicaciones: publicaciones ?? this.publicaciones,
    categorias: categorias ?? this.categorias,
    cargando: cargando ?? this.cargando,
    error: error,
  );
}
