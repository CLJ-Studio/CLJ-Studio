import '../funcionalidades/inicio_marketplace/datos/repositorio_inicio_marketplace.dart';

/// Punto único de composición para sustituir repositorios de prueba por reales.
abstract final class ArbolDependencias {
  static RepositorioInicioMarketplace crearRepositorioInicio() {
    return RepositorioInicioMarketplace();
  }
}
