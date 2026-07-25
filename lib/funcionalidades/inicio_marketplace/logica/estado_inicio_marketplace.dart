import '../modelos/local_universitario.dart';

/// Estado de filtros que consume únicamente la pantalla.
class EstadoInicioMarketplace {
  const EstadoInicioMarketplace({
    required this.categoriaId,
    required this.busqueda,
    required this.locales,
  });
  final String categoriaId;
  final String busqueda;
  final List<LocalUniversitario> locales;
}
