import 'package:flutter/foundation.dart';

import '../datos/repositorio_inicio_marketplace.dart';
import 'estado_inicio_marketplace.dart';

/// Gestiona búsqueda y categoría sin acoplar la vista a los datos de prueba.
class ControladorInicioMarketplace extends ChangeNotifier {
  ControladorInicioMarketplace(this.repositorio)
    : estado = EstadoInicioMarketplace(
        categoriaId: 'todas',
        busqueda: '',
        locales: repositorio.obtenerLocales(),
      );

  final RepositorioInicioMarketplace repositorio;
  EstadoInicioMarketplace estado;

  /// Cambia la selección visual y vuelve a aplicar todos los filtros.
  void seleccionarCategoria(String categoriaId) =>
      _filtrar(categoriaId: categoriaId);
  void buscar(String texto) => _filtrar(busqueda: texto);

  void _filtrar({String? categoriaId, String? busqueda}) {
    final categoria = categoriaId ?? estado.categoriaId;
    final consulta = (busqueda ?? estado.busqueda).trim().toLowerCase();
    final locales = repositorio.obtenerLocales().where((local) {
      final coincideCategoria =
          categoria == 'todas' || local.categoriaId == categoria;
      final coincideTexto =
          local.nombre.toLowerCase().contains(consulta) ||
          local.descripcion.toLowerCase().contains(consulta);
      return coincideCategoria && coincideTexto;
    }).toList();
    estado = EstadoInicioMarketplace(
      categoriaId: categoria,
      busqueda: consulta,
      locales: locales,
    );
    notifyListeners();
  }
}
