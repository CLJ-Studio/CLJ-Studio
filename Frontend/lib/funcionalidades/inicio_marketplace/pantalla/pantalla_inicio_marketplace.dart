import 'dart:async';

import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../favoritos/logica/controlador_favoritos.dart';
import '../../instalacion_app/diseno/aviso_instalacion.dart';
import '../../locales_universitarios/diseno/carrusel_locales_destacados.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_local.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_producto.dart';
import '../../pedidos/pantalla/pantalla_pedidos_completa.dart';
import '../../perfil_vendedor/pantalla/pantalla_perfil_publico_vendedor.dart';
import '../diseno/campus_collapsing_header.dart';
import '../logica/controlador_inicio_marketplace.dart';
import '../logica/estado_inicio_marketplace.dart';
import '../modelos/categoria_marketplace.dart';
import '../modelos/local_universitario.dart';
import '../modelos/producto_marketplace.dart';

/// Feed con todo lo que se publica en el campus.
///
/// Muestra publicaciones y no locales: el catalogo de cada vendedor vive en
/// la seccion Locales, y aqui se mezcla todo como en cualquier marketplace.
class PantallaInicioMarketplace extends StatelessWidget {
  const PantallaInicioMarketplace({
    required this.controlador,
    this.alVerLocalesDestacados,
    this.mostrarEncabezado = true,
    super.key,
  });
  final ControladorInicioMarketplace controlador;
  final VoidCallback? alVerLocalesDestacados;
  final bool mostrarEncabezado;

  static List<CategoriaMarketplace> _categoriasConContenido(
    List<CategoriaMarketplace> categorias,
    List<ProductoMarketplace> publicaciones,
  ) {
    final ids = {
      for (final publicacion in publicaciones) publicacion.categoriaEfectiva,
    };
    return categorias
        .where((categoria) => ids.contains(categoria.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    // Escucha ambos: los filtros del feed y el perfil compartido, para que
    // el saludo se actualice en cuanto el perfil termine de cargar.
    animation: Listenable.merge([controlador, SesionUsuario.instancia]),
    builder: (context, _) {
      final estado = controlador.estado;
      final buscando = estado.busqueda.trim().isNotEmpty;
      final publicacionesHome = buscando
          ? controlador.catalogoCompleto
          : estado.publicaciones;
      final publicacionesPopulares = controlador.publicacionesPopulares;
      final localesPorId = <String, LocalUniversitario>{};
      // Las categorías pertenecen a las publicaciones. Los locales destacados
      // deben permanecer estables aunque la categoría elegida no tenga ningún
      // producto.
      for (final publicacion in controlador.catalogoCompleto) {
        final local = publicacion.local;
        if (local != null) localesPorId[local.id] = local;
      }
      final localesMasVistos = localesPorId.values.toList(growable: false)
        ..sort((a, b) => b.vistas.compareTo(a.vistas));
      return Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notificacion) {
              if (notificacion is ScrollEndNotification &&
                  !buscando &&
                  notificacion.metrics.extentAfter < 500 &&
                  controlador.hayMasPublicaciones) {
                controlador.cargarMasPublicaciones();
              }
              return false;
            },
            child: CustomScrollView(
              // Mientras el buscador está abierto, el contenido de fondo queda
              // inmóvil. El panel de resultados conserva su propio scroll.
              physics: buscando ? const NeverScrollableScrollPhysics() : null,
              slivers: [
                if (mostrarEncabezado)
                  CampusCollapsingHeader(
                    nombre: SesionUsuario.instancia.primerNombre,
                    avatarUrl: SesionUsuario.instancia.perfil?.avatarUrl,
                    categorias: estado.categorias,
                    categoriaId: estado.categoriaId,
                    alBuscar: controlador.buscar,
                    alSeleccionarCategoria: controlador.seleccionarCategoria,
                    alAbrirCarrito: () => Navigator.of(
                      context,
                    ).pushNamed(ConfiguracionRutas.carrito),
                    alAbrirPedidos: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PantallaPedidosCompleta(),
                      ),
                    ),
                    mostrarCategorias: false,
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
                  sliver: SliverToBoxAdapter(
                    child: ContenidoCentrado(
                      anchoMaximo: 1000,
                      child: switch (estado) {
                        EstadoInicioMarketplace(cargando: true) =>
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(child: IndicadorCarga(tamanio: 140)),
                          ),
                        EstadoInicioMarketplace(error: final String mensaje) =>
                          MensajeCatalogo(
                            mensaje: mensaje,
                            alReintentar: controlador.cargar,
                          ),
                        _ => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AnuncioPrincipal(
                              categoriasConContenido: _categoriasConContenido(
                                estado.categorias,
                                controlador.catalogoCompleto,
                              ),
                              alSeleccionar: controlador.seleccionarCategoria,
                            ),
                            const SizedBox(height: 18),
                            _CategoriasInicio(
                              categorias: estado.categorias,
                              categoriaId: estado.categoriaId,
                              alSeleccionar: controlador.seleccionarCategoria,
                            ),
                            const SizedBox(height: 22),
                            _TituloSeccion(
                              titulo: 'Locales más vistos',
                              alVerTodo:
                                  alVerLocalesDestacados ??
                                  () =>
                                      controlador.seleccionarCategoria('todas'),
                            ),
                            const SizedBox(height: 6),
                            CarruselLocalesDestacados(
                              locales: localesMasVistos,
                              construirDetalle: (_, local) =>
                                  PantallaDetalleLocal(local: local),
                            ),
                            const SizedBox(height: 22),
                            _TituloSeccion(
                              titulo: 'Populares',
                              alVerTodo: () =>
                                  controlador.seleccionarCategoria('todas'),
                            ),
                            const SizedBox(height: 10),
                            _CarruselPublicaciones(
                              publicaciones: publicacionesPopulares,
                            ),
                            const SizedBox(height: 22),
                            _TituloSeccion(
                              titulo: 'Publicaciones',
                              alVerTodo: () =>
                                  controlador.seleccionarCategoria('todas'),
                            ),
                            const SizedBox(height: 10),
                            _CuadriculaPublicaciones(
                              publicaciones: publicacionesHome,
                            ),
                            const SizedBox(height: 18),
                            const AvisoInstalacion(),
                          ],
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Al tocar fuera de los resultados se cierra la búsqueda y el teclado.
          if (buscando)
            Positioned.fill(
              top: mostrarEncabezado ? 118 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  controlador.buscar('');
                },
              ),
            ),
          // El panel se conserva mientras se anima para comprimirse al cerrar.
          Positioned(
            top: mostrarEncabezado ? 118 : 0,
            left: 14,
            right: 14,
            child: IgnorePointer(
              ignoring: !buscando,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                opacity: buscando ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  scale: buscando ? 1 : .72,
                  child: Material(
                    elevation: 18,
                    shadowColor: const Color(0x55000000),
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 390),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                        child: _ResultadosBusqueda(
                          consulta: estado.busqueda,
                          publicaciones: controlador.catalogoCompleto,
                          alCerrar: () => controlador.buscar(''),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Resultados universales que aparecen inmediatamente debajo del buscador.
class _ResultadosBusqueda extends StatelessWidget {
  const _ResultadosBusqueda({
    required this.consulta,
    required this.publicaciones,
    required this.alCerrar,
  });

  final String consulta;
  final List<ProductoMarketplace> publicaciones;
  final VoidCallback alCerrar;

  /// Simplifica mayúsculas y acentos para encontrar resultados al escribir.
  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u');

  bool _coincide(String texto, String buscado) =>
      _normalizar(texto).contains(buscado);

  @override
  Widget build(BuildContext context) {
    final buscado = _normalizar(consulta.trim());

    // Un mismo local puede tener muchas publicaciones: se muestra una vez.
    final localesPorId = <String, LocalUniversitario>{};
    for (final publicacion in publicaciones) {
      final local = publicacion.local;
      if (local == null) continue;
      if (_coincide(local.nombreVisible, buscado) ||
          _coincide(local.descripcion, buscado) ||
          _coincide(local.categoria, buscado)) {
        localesPorId[local.id] = local;
      }
    }

    // La publicación inicial permite abrir el perfil completo del vendedor.
    final personas = <String, (LocalUniversitario, ProductoMarketplace)>{};
    for (final publicacion in publicaciones) {
      final local = publicacion.local;
      if (local == null || local.vendedorNombre.trim().isEmpty) continue;
      if (_coincide(local.vendedorNombre, buscado)) {
        final clave = local.duenoId.isEmpty
            ? local.vendedorNombre.toLowerCase()
            : local.duenoId;
        personas.putIfAbsent(clave, () => (local, publicacion));
      }
    }

    final publicacionesHalladas = [
      for (final publicacion in publicaciones)
        if (publicacion.local != null &&
            (_coincide(publicacion.nombre, buscado) ||
                _coincide(publicacion.descripcion, buscado)))
          publicacion,
    ];

    final resultados = <Widget>[
      for (final publicacion in publicacionesHalladas)
        _ResultadoBusqueda(
          icono: Icons.sell_rounded,
          titulo: publicacion.nombre,
          subtitulo: publicacion.local!.nombreVisible,
          imagenUrl: publicacion.imagenUrl,
          alPresionar: () {
            FocusManager.instance.primaryFocus?.unfocus();
            alCerrar();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaDetalleProducto(
                  producto: publicacion,
                  local: publicacion.local!,
                  vendedorNavegable: true,
                ),
              ),
            );
          },
        ),
      for (final persona in personas.values)
        _ResultadoBusqueda(
          icono: Icons.person_rounded,
          titulo: persona.$1.vendedorNombre,
          subtitulo: 'Persona',
          imagenUrl: persona.$1.vendedorAvatarUrl,
          alPresionar: () {
            FocusManager.instance.primaryFocus?.unfocus();
            alCerrar();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaPerfilPublicoVendedor(
                  local: persona.$1,
                  publicacionInicial: persona.$2,
                ),
              ),
            );
          },
        ),
      for (final local in localesPorId.values)
        _ResultadoBusqueda(
          icono: Icons.storefront_rounded,
          titulo: local.nombreVisible,
          subtitulo: local.categoria,
          imagenUrl: local.logoUrl,
          alPresionar: () {
            FocusManager.instance.primaryFocus?.unfocus();
            alCerrar();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaDetalleLocal(local: local),
              ),
            );
          },
        ),
    ];

    if (resultados.isEmpty) return const _BusquedaVacia();

    return Column(
      children: [
        for (var i = 0; i < resultados.length; i++) ...[
          resultados[i],
          if (i < resultados.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _ResultadoBusqueda extends StatelessWidget {
  const _ResultadoBusqueda({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.alPresionar,
    this.imagenUrl,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String? imagenUrl;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: alPresionar,
    leading: _ImagenResultado(icono: icono, imagenUrl: imagenUrl),
    title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitulo),
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF5C8A63)),
  );
}

class _ImagenResultado extends StatelessWidget {
  const _ImagenResultado({required this.icono, this.imagenUrl});

  final IconData icono;
  final String? imagenUrl;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: const Color(0xFF16A34A),
    foregroundColor: Colors.white,
    child: imagenUrl == null || imagenUrl!.isEmpty
        ? Icon(icono, size: 21)
        : ClipOval(
            child: Image.network(
              imagenUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(icono, size: 21),
            ),
          ),
  );
}

class _BusquedaVacia extends StatelessWidget {
  const _BusquedaVacia();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF5C8A63)),
        SizedBox(height: 10),
        Text(
          'No encontramos resultados',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 5),
        Text('Prueba con otro nombre, publicación o local.'),
      ],
    ),
  );
}

class _AnuncioPrincipal extends StatefulWidget {
  const _AnuncioPrincipal({
    required this.categoriasConContenido,
    required this.alSeleccionar,
  });

  final List<CategoriaMarketplace> categoriasConContenido;
  final ValueChanged<String> alSeleccionar;

  @override
  State<_AnuncioPrincipal> createState() => _AnuncioPrincipalState();
}

class _AnuncioPrincipalState extends State<_AnuncioPrincipal> {
  // El banner exterior permanece fijo; solo se mueve su contenido interno.
  final PageController _controlador = PageController(viewportFraction: 1.0);
  Timer? _temporizador;
  Timer? _temporizadorReanudacion;
  int _paginaActual = 0;

  static const _textos = <String, (String, String)>{
    'comida': ('Sabores que\nllegan hasta ti.', 'Comida hecha en el campus.'),
    'servicios': (
      'Talento de\nnuestra comunidad.',
      'Servicios de otros estudiantes.',
    ),
    'tecnologia': (
      'Tecnología\nentre pasillos.',
      'Lo que necesitas para tus clases.',
    ),
  };

  static const _colores = [Color(0xFF237A45), Color(0xFF315C3B)];

  static const _imagenes = <String, String>{
    'comida': 'assets/images/banners/comida-buho.jpg',
    'deporte': 'assets/images/banners/deportes-buho.jpg',
    'deportes': 'assets/images/banners/deportes-buho.jpg',
  };

  List<BannerData> get _banners => [
    BannerData(
      titulo: 'Todo lo que\nnecesitas,\nen el campus.',
      subtitulo: 'Compra, vende y descubre.',
      textoBoton: 'Explorar ahora',
      colorDegradado: const Color(0xFF16A34A),
      rutaImagen: 'assets/images/banners/comida-buho.jpg',
      accion: () => widget.alSeleccionar('todas'),
    ),
    for (final (indice, categoria)
        in widget.categoriasConContenido.take(2).indexed)
      BannerData(
        titulo:
            _textos[categoria.id]?.$1 ??
            'Hay ${categoria.nombre}\nen el campus.',
        subtitulo: _textos[categoria.id]?.$2 ?? 'Mira lo que publicaron.',
        textoBoton: 'Ver ${categoria.nombre.toLowerCase()}',
        colorDegradado: _colores[indice % _colores.length],
        rutaImagen:
            _imagenes[categoria.id] ?? 'assets/images/banners/campus-buhos.jpg',
        accion: () => widget.alSeleccionar(categoria.id),
      ),
  ];

  @override
  void initState() {
    super.initState();
    _iniciarAutoPlay();
  }

  /// Avanza periódicamente y vuelve al inicio después de la última página.
  void _iniciarAutoPlay() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controlador.hasClients) return;
      final siguiente = (_paginaActual + 1) % _banners.length;
      _controlador.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  /// Detiene el avance automático apenas el usuario toca el carrusel.
  void _pausarAutoPlay() {
    _temporizador?.cancel();
    _temporizadorReanudacion?.cancel();
  }

  /// Reanuda el autoplay unos segundos después de terminar la interacción.
  void _reanudarAutoPlay() {
    _temporizadorReanudacion?.cancel();
    _temporizadorReanudacion = Timer(
      const Duration(seconds: 7),
      _iniciarAutoPlay,
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _temporizadorReanudacion?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final banners = _banners;
    final paginaActual = _paginaActual.clamp(0, banners.length - 1);
    return AspectRatio(
      aspectRatio: 1.55,
      // Un único recorte mantiene inmóvil la silueta exterior del banner.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Listener(
          onPointerDown: (_) => _pausarAutoPlay(),
          onPointerUp: (_) => _reanudarAutoPlay(),
          onPointerCancel: (_) => _reanudarAutoPlay(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Solo el contenido de cada diapositiva se mueve dentro del marco.
              PageView.builder(
                controller: _controlador,
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: banners.length,
                onPageChanged: (pagina) => setState(() {
                  _paginaActual = pagina;
                }),
                itemBuilder: (_, indice) =>
                    BannerSlide(data: banners[indice], oscuro: oscuro),
              ),
              // Los indicadores también permanecen dentro del banner fijo.
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (indice) {
                    final activo = indice == paginaActual;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                      width: activo ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: activo
                            ? Colors.white
                            : Colors.white.withValues(alpha: .42),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenido y comportamiento propios de una diapositiva del banner.
class BannerData {
  const BannerData({
    required this.titulo,
    required this.subtitulo,
    required this.textoBoton,
    required this.colorDegradado,
    required this.rutaImagen,
    required this.accion,
  });

  final String titulo;
  final String subtitulo;
  final String textoBoton;
  final Color colorDegradado;
  final String rutaImagen;
  final VoidCallback accion;
}

/// Dibuja una página completa: imagen, degradado, textos y acción se mueven juntos.
class BannerSlide extends StatelessWidget {
  const BannerSlide({required this.data, required this.oscuro, super.key});

  final BannerData data;
  final bool oscuro;

  @override
  Widget build(BuildContext context) => ClipRRect(
    // Cada tarjeta recorta únicamente su propio contenido y sus esquinas.
    borderRadius: BorderRadius.circular(22),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          data.rutaImagen,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          filterQuality: FilterQuality.medium,
        ),
        // Refuerza el contraste del texto sin ocultar la ilustración.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                data.colorDegradado.withValues(alpha: .84),
                data.colorDegradado.withValues(alpha: .48),
                Colors.transparent,
              ],
              stops: const [0, .48, .82],
            ),
          ),
        ),
        // Este bloque pertenece a la página y se desliza con su imagen.
        Padding(
          padding: const EdgeInsets.all(24),
          child: FractionallySizedBox(
            widthFactor: .62,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: .98,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  data.subtitulo,
                  maxLines: 2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .92),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: data.accion,
                  style: FilledButton.styleFrom(
                    backgroundColor: oscuro
                        ? const Color(0xFF20251F)
                        : const Color(0xFF292A23),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 11,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    data.textoBoton,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CategoriasInicio extends StatelessWidget {
  const _CategoriasInicio({
    required this.categorias,
    required this.categoriaId,
    required this.alSeleccionar,
  });

  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alSeleccionar;

  static const _idsPrincipales = ['comida', 'tecnologia', 'servicios'];

  Future<void> _mostrarOtrasCategorias(
    BuildContext context,
    List<CategoriaMarketplace> categorias,
  ) async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                child: Text(
                  'Más categorías',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                  itemCount: categorias.length,
                  itemBuilder: (_, indice) {
                    final categoria = categorias[indice];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE3EEE5),
                        foregroundColor: const Color(0xFF2F4034),
                        child: Icon(categoria.icono),
                      ),
                      title: Text(
                        categoria.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: categoria.id == categoriaId
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF16A34A),
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(categoria.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (elegida != null) alSeleccionar(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final todas = categorias
        .where((categoria) => categoria.id == CategoriaMarketplace.todas.id)
        .toList();
    final porId = {for (final categoria in categorias) categoria.id: categoria};
    final principales = [for (final id in _idsPrincipales) ?porId[id]];
    final categoriaOtros = categorias
        .where((categoria) => categoria.id == 'otros')
        .toList();
    final adicionales = [
      ...categorias.where(
        (categoria) =>
            categoria.id != CategoriaMarketplace.todas.id &&
            !_idsPrincipales.contains(categoria.id) &&
            categoria.id != 'otros',
      ),
      // La categoría real "Otros" siempre cierra la lista de la hoja.
      ...categoriaOtros,
    ];
    final visibles = [...todas, ...principales];
    final haySeleccionAdicional = adicionales.any(
      (categoria) => categoria.id == categoriaId,
    );

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibles.length + (adicionales.isEmpty ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, indice) {
          final esBotonOtros = indice == visibles.length;
          final categoria = esBotonOtros
              ? const CategoriaMarketplace(
                  id: '_mas_categorias',
                  nombre: 'Otros',
                  icono: Icons.more_horiz_rounded,
                )
              : visibles[indice];
          final seleccionada = categoria.id == categoriaId;
          return Tooltip(
            message: categoria.nombre,
            child: GestureDetector(
              onTap: esBotonOtros
                  ? () => _mostrarOtrasCategorias(context, adicionales)
                  : () => alSeleccionar(categoria.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: seleccionada || (esBotonOtros && haySeleccionAdicional)
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF2F4034),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(categoria.icono, color: Colors.white, size: 28),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Recupera el carrusel horizontal de publicaciones que existía en Inicio.
class _CarruselPublicaciones extends StatelessWidget {
  const _CarruselPublicaciones({required this.publicaciones});

  final List<ProductoMarketplace> publicaciones;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 238,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: publicaciones.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, indice) =>
          _TarjetaPublicacion(publicacion: publicaciones[indice]),
    ),
  );
}

/// Las publicaciones normales forman parte del desplazamiento vertical del
/// inicio. Solo el ranking de populares se conserva como carrusel horizontal.
class _CuadriculaPublicaciones extends StatelessWidget {
  const _CuadriculaPublicaciones({required this.publicaciones});

  final List<ProductoMarketplace> publicaciones;

  @override
  Widget build(BuildContext context) {
    if (publicaciones.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const anchoMinimo = 150.0;
        const separacion = 10.0;
        final columnas =
            ((constraints.maxWidth + separacion) / (anchoMinimo + separacion))
                .floor()
                .clamp(1, 5);
        final anchoTarjeta =
            (constraints.maxWidth - separacion * (columnas - 1)) / columnas;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: publicaciones.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: separacion,
            mainAxisSpacing: separacion,
            childAspectRatio: anchoTarjeta / 238,
          ),
          itemBuilder: (_, indice) => _TarjetaPublicacion(
            publicacion: publicaciones[indice],
            ancho: double.infinity,
          ),
        );
      },
    );
  }
}

class _TarjetaPublicacion extends StatelessWidget {
  const _TarjetaPublicacion({required this.publicacion, this.ancho = 150});

  final ProductoMarketplace publicacion;
  final double ancho;

  void _abrir(BuildContext context) {
    final local = publicacion.local;
    if (local == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleProducto(
          producto: publicacion,
          local: local,
          vendedorNavegable: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ancho,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrir(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: .3),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 128,
                width: double.infinity,
                child: publicacion.imagenUrl == null
                    ? const _ImagenPublicacionVacia()
                    : Image.network(
                        publicacion.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _ImagenPublicacionVacia(),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publicacion.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bs ${publicacion.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedBuilder(
                            animation: ControladorFavoritos.instancia,
                            builder: (context, _) {
                              final favorito = ControladorFavoritos.instancia
                                  .contiene(publicacion);
                              final colorInactivo =
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black;
                              return IconButton(
                                tooltip: favorito
                                    ? 'Quitar de favoritos'
                                    : 'Agregar a favoritos',
                                onPressed: () => ControladorFavoritos.instancia
                                    .alternar(publicacion),
                                style: IconButton.styleFrom(
                                  foregroundColor: favorito
                                      ? const Color(0xFFE53935)
                                      : colorInactivo,
                                  minimumSize: const Size(30, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                icon: Icon(
                                  favorito
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton.filled(
                            tooltip: 'Ver publicación',
                            onPressed: () => _abrir(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(30, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ImagenPublicacionVacia extends StatelessWidget {
  const _ImagenPublicacionVacia();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.image_not_supported_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      size: 34,
    ),
  );
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.titulo, required this.alVerTodo});

  final String titulo;
  final VoidCallback alVerTodo;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      TextButton(
        onPressed: alVerTodo,
        child: const Text(
          'Ver todo',
          style: TextStyle(
            color: Color(0xFF5C8A63),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}
