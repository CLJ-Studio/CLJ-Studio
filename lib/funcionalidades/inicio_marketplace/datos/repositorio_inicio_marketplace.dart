import '../../../datos_prueba/categorias_prueba.dart';
import '../../../datos_prueba/locales_prueba.dart';
import '../../../datos_prueba/productos_prueba.dart';
import '../modelos/categoria_marketplace.dart';
import '../modelos/local_universitario.dart';
import '../modelos/producto_marketplace.dart';

/// Fuente temporal con la misma interfaz que podrá implementar el backend.
class RepositorioInicioMarketplace {
  List<CategoriaMarketplace> obtenerCategorias() => CategoriasPrueba.todos;
  List<LocalUniversitario> obtenerLocales() => LocalesPrueba.todos;
  List<ProductoMarketplace> obtenerProductos(String localId) => ProductosPrueba
      .todos
      .where((producto) => producto.localId == localId)
      .toList();
}
