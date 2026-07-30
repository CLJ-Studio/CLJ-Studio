import 'package:flutter/foundation.dart';

import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import '../datos/repositorio_inicio_marketplace.dart';
import '../modelos/producto_marketplace.dart';
import 'estado_inicio_marketplace.dart';

/// Feed de publicaciones del campus, con busqueda y filtro por categoria.
///
/// El filtrado es en cliente a proposito: a escala de campus son decenas de
/// publicaciones, y filtrar sobre lo ya cargado hace que escribir en el
/// buscador responda al instante, sin un viaje al servidor por cada tecla.
class ControladorInicioMarketplace extends ChangeNotifier {
  ControladorInicioMarketplace(this.repositorio);

  final RepositorioInicioMarketplace repositorio;

  EstadoInicioMarketplace estado = const EstadoInicioMarketplace();

  /// Catalogo completo sin filtrar; la base de cada filtrado.
  List<ProductoMarketplace> _todas = const [];

  /// Una publicacion nueva de cualquier vendedor debe aparecer sola.
  late final _escuchaProductos = EscuchaTabla(
    tabla: 'products',
    alCambiar: _recargarEnSilencio,
  );

  /// Abrir o cerrar un local cambia que se ve en el feed.
  late final _escuchaLocales = EscuchaTabla(
    tabla: 'stores',
    alCambiar: _recargarEnSilencio,
  );

  void iniciarTiempoReal() {
    _escuchaProductos.iniciar();
    _escuchaLocales.iniciar();
  }

  @override
  void dispose() {
    _escuchaProductos.detener();
    _escuchaLocales.detener();
    super.dispose();
  }

  Future<void> cargar() async {
    estado = estado.copiarCon(cargando: true);
    notifyListeners();
    final esperaVisual = Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    try {
      final categorias = await repositorio.obtenerCategorias();
      _todas = await repositorio.obtenerPublicaciones();
      await esperaVisual;
      estado = estado.copiarCon(
        categorias: categorias,
        publicaciones: _aplicarFiltros(),
        cargando: false,
      );
    } catch (_) {
      await esperaVisual;
      estado = estado.copiarCon(
        cargando: false,
        error: 'No se pudo cargar el catálogo. Revisa tu conexión.',
      );
    }
    notifyListeners();
  }

  /// Refresca sin mostrar el indicador de carga: el usuario no pidio nada,
  /// asi que la lista debe cambiar sin parpadear.
  Future<void> _recargarEnSilencio() async {
    try {
      _todas = await repositorio.obtenerPublicaciones();
      estado = estado.copiarCon(publicaciones: _aplicarFiltros());
      notifyListeners();
    } catch (_) {
      // Se reintenta en el siguiente evento o sondeo.
    }
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
    estado = estado.copiarCon(publicaciones: _aplicarFiltros());
    notifyListeners();
  }

  List<ProductoMarketplace> _aplicarFiltros() {
    final categoria = estado.categoriaId;
    final consulta = estado.busqueda;

    return _todas.where((publicacion) {
      // La categoria vive en el local que publica.
      // Por la categoria de la publicacion, no la de su tienda: el espacio
      // personal nace sin ninguna, asi que antes nada de lo publicado a
      // titulo propio aparecia jamas al filtrar.
      final coincideCategoria =
          categoria == 'todas' || publicacion.categoriaEfectiva == categoria;

      final coincideTexto =
          consulta.isEmpty ||
          publicacion.nombre.toLowerCase().contains(consulta) ||
          publicacion.descripcion.toLowerCase().contains(consulta) ||
          (publicacion.local?.nombre.toLowerCase().contains(consulta) ?? false);

      return coincideCategoria && coincideTexto;
    }).toList();
  }
}
