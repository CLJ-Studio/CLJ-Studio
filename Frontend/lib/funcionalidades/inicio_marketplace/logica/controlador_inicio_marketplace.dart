import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import '../datos/repositorio_inicio_marketplace.dart';
import '../modelos/producto_marketplace.dart';
import '../modelos/local_universitario.dart';
import '../modelos/publicidad.dart';
import 'estado_inicio_marketplace.dart';

/// Feed de publicaciones del campus, con busqueda y filtro por categoria.
///
/// El filtrado es en cliente a proposito: filtrar sobre lo ya cargado hace
/// que escribir en el buscador responda al instante, sin un viaje al servidor
/// por cada tecla.
///
/// Pero lo cargado son solo las tandas mas recientes. Cuando lo filtrado se
/// acaba, "cargar mas" trae la tanda siguiente; y lo que se escribe en el
/// buscador tambien se le pregunta a la base, sobre el catalogo entero, cuando
/// se deja de escribir.
class ControladorInicioMarketplace extends ChangeNotifier {
  ControladorInicioMarketplace(this.repositorio);

  final RepositorioInicioMarketplace repositorio;

  EstadoInicioMarketplace estado = const EstadoInicioMarketplace();

  /// Lo bajado del catalogo, sin filtrar; la base de cada filtrado.
  List<ProductoMarketplace> _todas = const [];
  List<ProductoMarketplace> _populares = const [];
  List<LocalUniversitario> _localesMasVistos = const [];
  List<Publicidad> _publicidad = const [];
  static const _tamanoPagina = 10;
  int _limiteVisible = _tamanoPagina;

  static const _tandaServidor = RepositorioInicioMarketplace.tandaPublicaciones;

  /// Filas del servidor ya bajadas: desde donde pedir la tanda siguiente, y
  /// cuantas volver a pedir al recargar para no perder lo ya desplegado.
  int _filasBajadas = 0;

  /// Si la ultima tanda vino completa: puede haber mas en el servidor.
  bool _hayMasEnServidor = false;
  bool _bajandoTanda = false;

  /// Lo que la base encontro para lo que se busca, en el catalogo entero.
  List<ProductoMarketplace> _halladas = const [];
  Timer? _esperaBusqueda;
  int _busquedaVigente = 0;

  /// Cuanto se espera a que se deje de escribir para preguntarle a la base.
  static const esperaBusqueda = Duration(milliseconds: 350);

  /// Catálogo sin filtros para construir resultados separados.
  List<ProductoMarketplace> get catalogoCompleto =>
      _todas.isEmpty ? estado.publicaciones : List.unmodifiable(_todas);

  /// Ranking del dia, ordenado en la base por visitantes unicos.
  List<ProductoMarketplace> get publicacionesPopulares =>
      List.unmodifiable(_populares);
  List<LocalUniversitario> get localesMasVistos =>
      List.unmodifiable(_localesMasVistos);
  List<Publicidad> publicidadDe(UbicacionPublicidad ubicacion) => _publicidad
      .where((anuncio) => anuncio.ubicacion == ubicacion)
      .toList(growable: false);

  /// Donde busca el panel del buscador: lo ya bajado y, sin repetir, lo que
  /// la base encontro en el catalogo entero.
  List<ProductoMarketplace> get resultadosBusqueda {
    if (_halladas.isEmpty) return catalogoCompleto;
    final vistas = {for (final publicacion in _todas) publicacion.id};
    return List.unmodifiable([
      ..._todas,
      for (final publicacion in _halladas)
        if (vistas.add(publicacion.id)) publicacion,
    ]);
  }

  /// Indica si el filtro actual todavía tiene otra tanda de publicaciones,
  /// ya bajada o en el servidor.
  bool get hayMasPublicaciones =>
      _filtrarTodas().length > estado.publicaciones.length || _hayMasEnServidor;

  /// Una publicacion nueva de cualquier vendedor debe aparecer sola.
  late final _escuchaProductos = EscuchaTabla(
    tabla: 'products',
    alCambiar: _pedirRecarga,
  );

  /// Abrir o cerrar un local cambia que se ve en el feed.
  late final _escuchaLocales = EscuchaTabla(
    tabla: 'stores',
    alCambiar: _pedirRecarga,
  );

  /// Los cambios de los administradores aparecen sin reiniciar la app.
  late final _escuchaPublicidad = EscuchaTabla(
    tabla: 'advertisements',
    alCambiar: _pedirRecarga,
  );

  /// Como minimo, este tiempo entre dos recargas en silencio.
  ///
  /// Las tres escuchas avisan por separado y `products` avisa tambien cada vez
  /// que alguien abre una publicacion (sube su contador de visitas). Cada
  /// recarga baja el catalogo entero y redibuja el inicio en el mismo hilo
  /// que anima: sin esta pausa, con gente usando la app, el inicio se
  /// redibujaba varias veces por minuto y se notaba al desplazarse.
  static const pausaEntreRecargas = Duration(seconds: 8);

  Timer? _recargaPendiente;
  bool _recargando = false;
  bool _otraVuelta = false;
  bool _desechado = false;
  DateTime? _ultimaRecarga;

  /// Lo que se dibujo la ultima vez, para no redibujar si nada cambio.
  List<Object?> _firmaMostrada = const [];

  void iniciarTiempoReal() {
    _escuchaProductos.iniciar();
    _escuchaLocales.iniciar();
    _escuchaPublicidad.iniciar();
  }

  @override
  void dispose() {
    _desechado = true;
    _recargaPendiente?.cancel();
    _esperaBusqueda?.cancel();
    _escuchaProductos.detener();
    _escuchaLocales.detener();
    _escuchaPublicidad.detener();
    super.dispose();
  }

  Future<void> cargar() async {
    estado = estado.copiarCon(cargando: true);
    notifyListeners();
    final esperaVisual = Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    try {
      final (
        categorias,
        tanda,
        populares,
        localesMasVistos,
        publicidad,
      ) = await (
        repositorio.obtenerCategorias(),
        repositorio.obtenerPublicaciones(),
        repositorio.obtenerPublicacionesPopulares(),
        repositorio.obtenerLocalesMasVistos(),
        repositorio.obtenerPublicidad(),
      ).wait;
      _todas = tanda.publicaciones;
      _filasBajadas = tanda.filas;
      _hayMasEnServidor = tanda.filas == _tandaServidor;
      _populares = populares;
      _localesMasVistos = localesMasVistos;
      _publicidad = publicidad;
      await esperaVisual;
      _firmaMostrada = _firmaVisible();
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

  /// Junta los avisos de las tres escuchas en una sola recarga.
  ///
  /// Nunca hay dos recargas a la vez, ni dos mas cerca que
  /// [pausaEntreRecargas]. Un aviso que llega durante una recarga no se
  /// pierde: deja pedida otra para despues, porque ese cambio puede no haber
  /// entrado en la que estaba en curso.
  void _pedirRecarga() {
    if (_desechado) return;
    if (_recargando) {
      _otraVuelta = true;
      return;
    }
    if (_recargaPendiente != null) return;
    final ultima = _ultimaRecarga;
    final espera = ultima == null
        ? Duration.zero
        : pausaEntreRecargas - DateTime.now().difference(ultima);
    _recargaPendiente = Timer(
      espera.isNegative ? Duration.zero : espera,
      () async {
        _recargaPendiente = null;
        _recargando = true;
        _ultimaRecarga = DateTime.now();
        await _recargarEnSilencio();
        _recargando = false;
        if (_otraVuelta) {
          _otraVuelta = false;
          _pedirRecarga();
        }
      },
    );
  }

  /// Lo mismo que hace una escucha cuando la base avisa de un cambio.
  @visibleForTesting
  void simularAviso() => _pedirRecarga();

  /// Refresca sin mostrar el indicador de carga: el usuario no pidio nada,
  /// asi que la lista debe cambiar sin parpadear.
  ///
  /// Y si lo que llego es igual a lo que se ve, no se redibuja nada. Es el
  /// caso mas comun: el aviso fue una visita sumada a un contador que el
  /// inicio no muestra.
  Future<void> _recargarEnSilencio() async {
    try {
      // Tantas filas como las ya bajadas: quien bajo varias tandas no las
      // pierde por un aviso de la base.
      final cantidad = math.max(_tandaServidor, _filasBajadas);
      final (tanda, populares, localesMasVistos, publicidad) = await (
        repositorio.obtenerPublicaciones(cantidad: cantidad),
        repositorio.obtenerPublicacionesPopulares(),
        repositorio.obtenerLocalesMasVistos(),
        repositorio.obtenerPublicidad(),
      ).wait;
      if (_desechado) return;
      _todas = tanda.publicaciones;
      _filasBajadas = tanda.filas;
      _hayMasEnServidor = tanda.filas == cantidad;
      _populares = populares;
      _localesMasVistos = localesMasVistos;
      _publicidad = publicidad;
      final firma = _firmaVisible();
      if (listEquals(firma, _firmaMostrada)) return;
      _firmaMostrada = firma;
      estado = estado.copiarCon(publicaciones: _aplicarFiltros());
      notifyListeners();
    } catch (_) {
      // Se reintenta en el siguiente evento o sondeo.
    }
  }

  /// Todo lo que el inicio dibuja, en una forma que se puede comparar.
  ///
  /// Quedan fuera las visitas de cada publicacion: el inicio no las muestra,
  /// y son justamente lo que mas cambia. Las de los locales mas vistos si
  /// entran, porque esa tarjeta ensena el numero.
  ///
  /// Si algun dia se agrega un campo visible a estos modelos, va aqui
  /// tambien; si no, un cambio en ese campo solo se veria al recargar a mano.
  List<Object?> _firmaVisible() => [
    for (final publicacion in _todas) _firmaProducto(publicacion),
    '|',
    for (final publicacion in _populares) _firmaProducto(publicacion),
    '|',
    for (final local in _localesMasVistos) (_firmaLocal(local), local.vistas),
    '|',
    for (final anuncio in _publicidad) _firmaAnuncio(anuncio),
  ];

  static Object _firmaProducto(ProductoMarketplace p) => (
    p.id,
    p.localId,
    p.nombre,
    p.descripcion,
    p.precio,
    p.emoji,
    p.stock,
    p.esServicio,
    p.imagePath,
    p.disponible,
    p.imagenes.join('\n'),
    p.categoriaId,
    [
      for (final variante in p.variantes)
        '${variante.id}\t${variante.nombre}\t${variante.precio}',
    ].join('\n'),
    _firmaLocal(p.local),
  );

  static Object? _firmaLocal(LocalUniversitario? l) => l == null
      ? null
      : (
          l.id,
          l.nombre,
          l.categoriaId,
          l.categoria,
          l.descripcion,
          l.calificacion,
          l.tiempoEstimado,
          l.estaAbierto,
          l.costoEntrega,
          l.emoji,
          l.colorHexadecimal,
          l.esPersonal,
          l.logoPath,
          l.portadaPath,
          l.vendedorNombre,
          l.vendedorAvatarPath,
          l.muestraVistas,
          l.ubicacionCampus,
          l.duenoId,
        );

  static Object _firmaAnuncio(Publicidad a) => (
    a.id,
    a.titulo,
    a.rutaImagen,
    a.ubicacion,
    a.enlaceUrl,
    a.orden,
    a.activa,
    a.iniciaEn,
    a.terminaEn,
    a.actualizadoEn,
  );

  void seleccionarCategoria(String categoriaId) {
    _limiteVisible = _tamanoPagina;
    estado = estado.copiarCon(categoriaId: categoriaId);
    _refiltrar();
    unawaited(_completarDesdeServidor());
  }

  /// Revela la siguiente tanda sin construir todo el feed en pantalla. Si lo
  /// bajado ya no alcanza, la pide al servidor.
  void cargarMasPublicaciones() {
    if (_bajandoTanda || !hayMasPublicaciones) return;
    _limiteVisible += _tamanoPagina;
    _refiltrar();
    unawaited(_completarDesdeServidor());
  }

  /// Trae tandas del servidor hasta tener lo que hay que mostrar, o hasta que
  /// no queden. Con una categoria elegida, una tanda puede no traer ninguna
  /// de ella: por eso es un ciclo y no una sola tanda.
  Future<void> _completarDesdeServidor() async {
    if (_bajandoTanda) return;
    _bajandoTanda = true;
    try {
      while (!_desechado &&
          _hayMasEnServidor &&
          _filtrarTodas().length < _limiteVisible) {
        final tanda = await repositorio.obtenerPublicaciones(
          desde: _filasBajadas,
        );
        if (_desechado) return;
        // Sin repetir: si algo se relanzo mientras tanto, cambio de lugar.
        final vistas = {for (final publicacion in _todas) publicacion.id};
        _todas = [
          ..._todas,
          for (final publicacion in tanda.publicaciones)
            if (vistas.add(publicacion.id)) publicacion,
        ];
        _filasBajadas += tanda.filas;
        _hayMasEnServidor = tanda.filas == _tandaServidor;
        _firmaMostrada = _firmaVisible();
        _refiltrar();
      }
    } catch (_) {
      // Se vuelve a intentar al llegar otra vez al final.
    } finally {
      _bajandoTanda = false;
    }
  }

  void buscar(String texto) {
    estado = estado.copiarCon(busqueda: texto.trim().toLowerCase());
    _buscarEnServidor(estado.busqueda);
    _refiltrar();
  }

  /// Le pregunta a la base por [consulta] cuando se deja de escribir. Mientras
  /// tanto, y si la base no responde, el panel muestra lo encontrado en lo ya
  /// bajado. Una respuesta que llega tarde, de algo que ya no se busca, se
  /// descarta.
  void _buscarEnServidor(String consulta) {
    _esperaBusqueda?.cancel();
    final vigente = ++_busquedaVigente;
    if (consulta.length < 2) {
      _halladas = const [];
      return;
    }
    _esperaBusqueda = Timer(esperaBusqueda, () async {
      try {
        final halladas = await repositorio.buscarPublicaciones(consulta);
        if (_desechado || vigente != _busquedaVigente) return;
        _halladas = halladas;
        notifyListeners();
      } catch (_) {
        // Sin respuesta, o sin la funcion en la base todavia: queda lo
        // encontrado en lo ya bajado.
      }
    });
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
