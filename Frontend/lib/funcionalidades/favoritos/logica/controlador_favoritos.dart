import 'package:flutter/foundation.dart';

import '../../../configuracion_aplicacion/modo_local.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../datos/repositorio_favoritos.dart';

/// Productos marcados con corazon, respaldados por la tabla `favorites`.
class ControladorFavoritos extends ChangeNotifier {
  ControladorFavoritos._();

  static final ControladorFavoritos instancia = ControladorFavoritos._();

  static const _repositorio = RepositorioFavoritos();

  final Map<String, ProductoMarketplace> _productos = {};
  bool cargando = false;
  String? error;

  List<ProductoMarketplace> get productos =>
      List.unmodifiable(_productos.values);
  int get cantidad => _productos.length;

  bool contiene(ProductoMarketplace producto) =>
      _productos.containsKey(producto.id);

  Future<void> cargar() async {
    if (ModoLocal.activo) {
      cargando = false;
      error = null;
      notifyListeners();
      return;
    }
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final guardados = await _repositorio.cargar();
      _productos
        ..clear()
        ..addEntries(guardados.map((p) => MapEntry(p.id, p)));
    } catch (_) {
      error = 'No se pudieron cargar tus favoritos.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Se actualiza la interfaz antes de que responda el servidor para que el
  /// corazon reaccione al instante; si la escritura falla, se revierte.
  Future<void> alternar(ProductoMarketplace producto) async {
    final estaba = contiene(producto);

    if (estaba) {
      _productos.remove(producto.id);
    } else {
      _productos[producto.id] = producto;
    }
    notifyListeners();

    if (ModoLocal.activo) return;

    try {
      if (estaba) {
        await _repositorio.quitar(producto.id);
      } else {
        await _repositorio.agregar(producto.id);
      }
    } catch (_) {
      if (estaba) {
        _productos[producto.id] = producto;
      } else {
        _productos.remove(producto.id);
      }
      error = 'No se pudo guardar el cambio.';
      notifyListeners();
    }
  }

  /// Al cerrar sesion, para no mostrar los favoritos del usuario anterior.
  void limpiar() {
    _productos.clear();
    notifyListeners();
  }
}
