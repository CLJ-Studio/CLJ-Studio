import '../modelos/categoria_marketplace.dart';
import '../modelos/local_universitario.dart';

/// Estado de filtros y carga que consume únicamente la pantalla.
class EstadoInicioMarketplace {
  const EstadoInicioMarketplace({
    this.categoriaId = 'todas',
    this.busqueda = '',
    this.locales = const [],
    this.categorias = const [],
    this.cargando = true,
    this.error,
  });

  final String categoriaId;
  final String busqueda;

  /// Locales ya filtrados por categoria y busqueda.
  final List<LocalUniversitario> locales;
  final List<CategoriaMarketplace> categorias;
  final bool cargando;
  final String? error;

  EstadoInicioMarketplace copiarCon({
    String? categoriaId,
    String? busqueda,
    List<LocalUniversitario>? locales,
    List<CategoriaMarketplace>? categorias,
    bool? cargando,
    String? error,
  }) => EstadoInicioMarketplace(
    categoriaId: categoriaId ?? this.categoriaId,
    busqueda: busqueda ?? this.busqueda,
    locales: locales ?? this.locales,
    categorias: categorias ?? this.categorias,
    cargando: cargando ?? this.cargando,
    error: error,
  );
}
