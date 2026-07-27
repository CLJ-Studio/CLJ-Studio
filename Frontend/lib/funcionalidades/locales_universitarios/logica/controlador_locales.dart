import 'package:flutter/foundation.dart';

import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/categoria_marketplace.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Catalogo de negocios del campus.
///
/// Vive aparte del feed del inicio: ahi se mezclan publicaciones sueltas de
/// todos, y aqui se listan los negocios para entrar a ver su catalogo.
class ControladorLocales extends ChangeNotifier {
  ControladorLocales([this._repositorio = const RepositorioInicioMarketplace()]);

  final RepositorioInicioMarketplace _repositorio;

  List<LocalUniversitario> locales = const [];
  List<CategoriaMarketplace> categorias = const [];
  String categoriaId = 'todas';
  String busqueda = '';
  bool cargando = true;
  String? error;

  List<LocalUniversitario> _todos = const [];

  late final _escucha = EscuchaTabla(
    tabla: 'stores',
    alCambiar: _recargarEnSilencio,
  );

  void iniciarTiempoReal() => _escucha.iniciar();

  @override
  void dispose() {
    _escucha.detener();
    super.dispose();
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      categorias = await _repositorio.obtenerCategorias();
      _todos = await _repositorio.obtenerLocales();
      locales = _filtrar();
    } catch (_) {
      error = 'No se pudieron cargar los locales.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> _recargarEnSilencio() async {
    try {
      _todos = await _repositorio.obtenerLocales();
      locales = _filtrar();
      notifyListeners();
    } catch (_) {
      // Se reintenta en el siguiente evento o sondeo.
    }
  }

  void seleccionarCategoria(String valor) {
    categoriaId = valor;
    locales = _filtrar();
    notifyListeners();
  }

  void buscar(String texto) {
    busqueda = texto.trim().toLowerCase();
    locales = _filtrar();
    notifyListeners();
  }

  List<LocalUniversitario> _filtrar() => _todos.where((local) {
    // Los espacios personales no son negocios: quedan fuera de esta seccion,
    // aunque sus publicaciones si aparecen en el inicio.
    if (local.esPersonal) return false;

    final coincideCategoria =
        categoriaId == 'todas' || local.categoriaId == categoriaId;
    final coincideTexto =
        busqueda.isEmpty ||
        local.nombre.toLowerCase().contains(busqueda) ||
        local.descripcion.toLowerCase().contains(busqueda);

    return coincideCategoria && coincideTexto;
  }).toList();
}
