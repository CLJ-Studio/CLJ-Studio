import '../funcionalidades/inicio_marketplace/datos/repositorio_inicio_marketplace.dart';

/// Punto único de composición de los repositorios de la aplicación.
abstract final class ArbolDependencias {
  static RepositorioInicioMarketplace crearRepositorioInicio() {
    return const RepositorioInicioMarketplace();
  }
}
