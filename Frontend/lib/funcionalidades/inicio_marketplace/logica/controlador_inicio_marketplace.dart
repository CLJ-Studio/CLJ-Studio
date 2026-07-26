import 'package:flutter/foundation.dart';

import '../datos/repositorio_inicio_marketplace.dart';
import '../modelos/local_universitario.dart';
import 'estado_inicio_marketplace.dart';

/// Carga el catalogo desde el backend y aplica busqueda y categoria.
///
/// El filtrado es en cliente a proposito: a escala de campus son decenas de
/// locales, y filtrar sobre la lista ya cargada hace que escribir en el
/// buscador responda al instante, sin un viaje al servidor por cada tecla.
class ControladorInicioMarketplace extends ChangeNotifier {
  ControladorInicioMarketplace(this.repositorio);

  final RepositorioInicioMarketplace repositorio;

  EstadoInicioMarketplace estado = const EstadoInicioMarketplace();

  /// Catalogo completo sin filtrar; la base de cada filtrado.
  List<LocalUniversitario> _todos = const [];

  Future<void> cargar() async {
    estado = estado.copiarCon(cargando: true);
    notifyListeners();

    try {
      final categorias = await repositorio.obtenerCategorias();
      _todos = await repositorio.obtenerLocales();
      estado = estado.copiarCon(
        categorias: categorias,
        locales: _aplicarFiltros(),
        cargando: false,
      );
    } catch (_) {
      estado = estado.copiarCon(
        cargando: false,
        error: 'No se pudo cargar el catálogo. Revisa tu conexión.',
      );
    }
    notifyListeners();
  }

  void seleccionarCategoria(String categoriaId) {
    estado = estado.copiarCon(categoriaId: categoriaId);
    _refiltrar();
  }

  void buscar(String texto) {
    estado = estado.copiarCon(busqueda: texto.trim().toLowerCase());
    _refiltrar();
  }

  void _refiltrar() {
    estado = estado.copiarCon(locales: _aplicarFiltros());
    notifyListeners();
  }

  List<LocalUniversitario> _aplicarFiltros() {
    final categoria = estado.categoriaId;
    final consulta = estado.busqueda;

    return _todos.where((local) {
      final coincideCategoria =
          categoria == 'todas' || local.categoriaId == categoria;
      final coincideTexto =
          consulta.isEmpty ||
          local.nombre.toLowerCase().contains(consulta) ||
          local.descripcion.toLowerCase().contains(consulta);
      return coincideCategoria && coincideTexto;
    }).toList();
  }
}
