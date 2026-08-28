import 'package:flutter/foundation.dart';

import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import '../datos/repositorio_inicio_marketplace.dart';
import '../modelos/producto_marketplace.dart';
import '../modelos/local_universitario.dart';
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
  List<ProductoMarketplace> _populares = const [];
  List<LocalUniversitario> _localesMasVistos = const [];
  static const _tamanoPagina = 10;
  int _limiteVisible = _tamanoPagina;

  /// Catálogo sin filtros para construir resultados separados.
  List<ProductoMarketplace> get catalogoCompleto =>
      _todas.isEmpty ? estado.publicaciones : List.unmodifiable(_todas);

  /// Ranking del dia, ordenado en la base por visitantes unicos.
  List<ProductoMarketplace> get publicacionesPopulares =>
      List.unmodifiable(_populares);
  List<LocalUniversitario> get localesMasVistos =>
      List.unmodifiable(_localesMasVistos);

  /// Indica si el filtro actual todavía tiene otra tanda de publicaciones.
  bool get hayMasPublicaciones =>
      _filtrarTodas().length > estado.publicaciones.length;

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
      final (categorias, publicaciones, populares, localesMasVistos) = await (
        repositorio.obtenerCategorias(),
        repositorio.obtenerPublicaciones(),
        repositorio.obtenerPublicacionesPopulares(),
        repositorio.obtenerLocalesMasVistos(),
      ).wait;
      _todas = publicaciones;
      _populares = populares;
      _localesMasVistos = localesMasVistos;
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
      final (publicaciones, populares, localesMasVistos) = await (
        repositorio.obtenerPublicaciones(),
        repositorio.obtenerPublicacionesPopulares(),
        repositorio.obtenerLocalesMasVistos(),
      ).wait;
      _todas = publicaciones;
      _populares = populares;
      _localesMasVistos = localesMasVistos;
      estado = estado.copiarCon(publicaciones: _aplicarFiltros());
      notifyListeners();
    } catch (_) {
      // Se reintenta en el siguiente evento o sondeo.
    }
  }

  void seleccionarCategoria(String categoriaId) {
    _limiteVisible = _tamanoPagina;
    estado = estado.copiarCon(categoriaId: categoriaId);
    _refiltrar();
  }

  /// Revela la siguiente tanda sin construir todo el feed en pantalla.
  void cargarMasPublicaciones() {
    if (!hayMasPublicaciones) return;
    _limiteVisible += _tamanoPagina;
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
    return _filtrarTodas().take(_limiteVisible).toList();
  }

  List<ProductoMarketplace> _filtrarTodas() {
    final categoria = estado.categoriaId;
    final consulta = estado.busqueda;

    return _todas.where((publicacion) {
      final local = publicacion.local;
      // "Comida" es tambien un agrupador de restaurantes: debe enseñar todo
      // su catalogo, aunque un producto concreto haya quedado bajo "Otros".
      // A la vez conserva las publicaciones personales marcadas como comida.
      final coincideCategoria = switch (categoria) {
        'todas' => true,
        'comida' =>
          publicacion.categoriaEfectiva == 'comida' ||
              (local != null &&
                  !local.esPersonal &&
                  local.categoriaId == 'comida'),
        // Agrupador exclusivo de la interfaz: reúne las publicaciones que no
        // son comida sin exigir una nueva categoría en la base de datos.
        'productos' =>
          publicacion.categoriaEfectiva != 'comida' &&
              (local == null ||
                  local.esPersonal ||
                  local.categoriaId != 'comida'),
        _ => publicacion.categoriaEfectiva == categoria,
      };

      final coincideTexto =
          consulta.isEmpty ||
          publicacion.nombre.toLowerCase().contains(consulta) ||
          publicacion.descripcion.toLowerCase().contains(consulta) ||
          (publicacion.local?.nombre.toLowerCase().contains(consulta) ??
              false) ||
          (publicacion.local?.descripcion.toLowerCase().contains(consulta) ??
              false) ||
          (publicacion.local?.categoria.toLowerCase().contains(consulta) ??
              false) ||
          (publicacion.local?.vendedorNombre.toLowerCase().contains(consulta) ??
              false);

      return coincideCategoria && coincideTexto;
    }).toList();
  }
}
