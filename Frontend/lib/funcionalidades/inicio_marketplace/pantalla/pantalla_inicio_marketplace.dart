import 'dart:async';

import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/marca/marca_u_market.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../favoritos/logica/controlador_favoritos.dart';
import '../../instalacion_app/diseno/aviso_instalacion.dart';
import '../../locales_universitarios/diseno/carrusel_locales_destacados.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_local.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_producto.dart';
import '../../pedidos/pantalla/pantalla_chats.dart';
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
    this.mostrarUbicacion = false,
    super.key,
  });
  final ControladorInicioMarketplace controlador;
  final VoidCallback? alVerLocalesDestacados;
  final bool mostrarEncabezado;
  final bool mostrarUbicacion;

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
      final localesMasVistos = controlador.localesMasVistos;
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
                    alAbrirChats: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PantallaChats(),
                      ),
                    ),
                    mostrarCategorias: false,
                    mostrarUbicacion: mostrarUbicacion,
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
                            const SizedBox(height: 26),
                            _EscaparatePopular(
                              publicaciones: publicacionesPopulares,
                              alVerTodo: () =>
                                  controlador.seleccionarCategoria('todas'),
                            ),
                            const SizedBox(height: 28),
                            _TituloSeccion(
                              titulo: 'Los mejores del campus',
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
                            const SizedBox(height: 28),
                            _TituloSeccion(titulo: 'Descubre algo nuevo'),
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
              top: mostrarEncabezado ? 124 : 0,
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
            top: mostrarEncabezado ? 124 : 0,
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
                    shadowColor: const Color(0x55474646),
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
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF474646)),
  );
}

class _ImagenResultado extends StatelessWidget {
  const _ImagenResultado({required this.icono, this.imagenUrl});

  final IconData icono;
  final String? imagenUrl;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: const Color(0xFF474646),
    foregroundColor: Color(0xFFE6E1D5),
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
        Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF474646)),
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
    'comida': ('Antojos entre\nclases.', 'Comida hecha en el campus.'),
    'servicios': (
      'Talento de\nnuestra comunidad.',
      'Servicios de otros estudiantes.',
    ),
    'tecnologia': (
      'Tecnología\nentre pasillos.',
      'Lo que necesitas para tus clases.',
    ),
  };

  static const _colores = [ConfiguracionTema.amarilloDorado];

  static const _imagenes = <String, String>{
    'comida': 'assets/images/banners/comida-buho.jpg',
    'deporte': 'assets/images/banners/deportes-buho.jpg',
    'deportes': 'assets/images/banners/deportes-buho.jpg',
  };

  List<BannerData> get _banners {
    final categorias = widget.categoriasConContenido;
    final indiceDeportes = categorias.indexWhere(
      (categoria) =>
          categoria.id.toLowerCase().contains('deporte') ||
          categoria.nombre.toLowerCase().contains('deporte'),
    );
    final categoriaDeportes = indiceDeportes < 0
        ? null
        : categorias[indiceDeportes];
    final otrasCategorias = categorias
        .where((categoria) => categoria != categoriaDeportes)
        .take(2);

    return [
      BannerData(
        titulo: 'Todo el campus\nen un solo lugar.',
        subtitulo: 'Compra, vende y descubre sin salir de la UPSA.',
        textoBoton: 'Explorar',
        colorDegradado: ConfiguracionTema.amarilloDorado,
        rutaImagen: 'assets/images/banners/comida-buho.jpg',
        accion: () => widget.alSeleccionar('todas'),
      ),
      for (final (indice, categoria) in otrasCategorias.indexed)
        BannerData(
          titulo:
              _textos[categoria.id]?.$1 ??
              'Hay ${categoria.nombre}\nen el campus.',
          subtitulo: _textos[categoria.id]?.$2 ?? 'Mira lo que publicaron.',
          textoBoton: 'Ver ${categoria.nombre.toLowerCase()}',
          colorDegradado: _colores[indice % _colores.length],
          rutaImagen:
              _imagenes[categoria.id] ??
              'assets/images/banners/campus-buhos.jpg',
          accion: () => widget.alSeleccionar(categoria.id),
        ),
      BannerData(
        titulo: 'Hay Deportes\nen el campus.',
        subtitulo: 'Mira lo que publicaron.',
        textoBoton: 'Ver deportes',
        colorDegradado: ConfiguracionTema.amarilloDorado,
        rutaImagen: 'assets/images/banners/deportes-buho.jpg',
        accion: () => widget.alSeleccionar(
          categoriaDeportes?.id ?? CategoriaMarketplace.todas.id,
        ),
      ),
    ];
  }

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
      aspectRatio: 1.68,
      // Un único recorte mantiene inmóvil la silueta exterior del banner.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
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
                            ? Color(0xFFE6E1D5)
                            : Color(0xFFE6E1D5).withValues(alpha: .42),
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
    borderRadius: BorderRadius.circular(30),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: data.colorDegradado),
        Positioned.fill(
          child: Image.asset(
            data.rutaImagen,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            filterQuality: FilterQuality.medium,
          ),
        ),
        // Refuerza el contraste del texto sin ocultar la ilustración.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                data.colorDegradado,
                data.colorDegradado,
                data.colorDegradado.withValues(alpha: .90),
                data.colorDegradado.withValues(alpha: .65),
                data.colorDegradado.withValues(alpha: .35),
                data.colorDegradado.withValues(alpha: .10),
                data.colorDegradado.withValues(alpha: 0),
              ],
              stops: const [0, .28, .33, .38, .43, .48, .53],
            ),
          ),
        ),
        // Este bloque pertenece a la página y se desliza con su imagen.
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 18, 24),
          child: FractionallySizedBox(
            widthFactor: .64,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.titulo,
                  style: const TextStyle(
                    color: ConfiguracionTema.azulNoche,
                    fontSize: 25,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  data.subtitulo,
                  maxLines: 2,
                  style: TextStyle(
                    color: ConfiguracionTema.azulNoche.withValues(alpha: .86),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 13),
                FilledButton.icon(
                  onPressed: data.accion,
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFFE6E1D5),
                    foregroundColor: ConfiguracionTema.azulNoche,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 10,
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

  static const _categoriaProductos = CategoriaMarketplace(
    id: 'productos',
    nombre: 'Productos',
    icono: Icons.shopping_bag_rounded,
  );

  static const _idsPrincipales = ['comida', 'productos'];
  static const _imagenesPrincipales = <String, String>{
    'comida': 'assets/images/categorias/comida-rapida.png',
    'productos': 'assets/images/categorias/productos-varios.png',
  };

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
                        backgroundColor: ConfiguracionTema.cremaSuperficie,
                        foregroundColor: const Color(0xFF474646),
                        child: Icon(categoria.icono),
                      ),
                      title: Text(
                        categoria.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: categoria.id == categoriaId
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF474646),
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
    final porId = {for (final categoria in categorias) categoria.id: categoria};
    final principales = [?porId['comida'], _categoriaProductos];
    final adicionales = [
      ...categorias.where(
        (categoria) =>
            categoria.id != CategoriaMarketplace.todas.id &&
            !_idsPrincipales.contains(categoria.id) &&
            categoria.id != 'otros',
      ),
      ...categorias.where((categoria) => categoria.id == 'otros'),
    ];
    final visibles = principales.take(2).toList(growable: false);
    final secundarias = [...principales.skip(2), ...adicionales.take(5)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '¿Qué estás buscando?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _mostrarOtrasCategorias(context, categorias),
              child: const Text(
                'Ver todo',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visibles.isNotEmpty)
          Row(
            children: [
              for (final (indice, categoria) in visibles.indexed) ...[
                Expanded(
                  child: _TarjetaCategoriaGrande(
                    categoria: categoria,
                    rutaImagenAsset: _imagenesPrincipales[categoria.id]!,
                    seleccionada: categoria.id == categoriaId,
                    alPresionar: () => alSeleccionar(categoria.id),
                  ),
                ),
                if (indice < visibles.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        if (secundarias.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: secundarias.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, indice) {
                if (indice == secundarias.length) {
                  return _TarjetaCategoriaCompacta(
                    categoria: const CategoriaMarketplace(
                      id: '_mas_categorias',
                      nombre: 'Más',
                      icono: Icons.more_horiz_rounded,
                    ),
                    alPresionar: () =>
                        _mostrarOtrasCategorias(context, categorias),
                  );
                }
                final categoria = secundarias[indice];
                return _TarjetaCategoriaCompacta(
                  categoria: categoria,
                  seleccionada: categoria.id == categoriaId,
                  alPresionar: () => alSeleccionar(categoria.id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _TarjetaCategoriaGrande extends StatelessWidget {
  const _TarjetaCategoriaGrande({
    required this.categoria,
    required this.alPresionar,
    required this.rutaImagenAsset,
    this.seleccionada = false,
  });

  final CategoriaMarketplace categoria;
  final VoidCallback alPresionar;
  final String rutaImagenAsset;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) => Material(
    color: seleccionada
        ? ConfiguracionTema.salviaClara
        : ConfiguracionTema.cremaSuperficie,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alPresionar,
      child: SizedBox(
        height: 142,
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: 0,
              bottom: 24,
              width: 160,
              child: Transform.scale(
                scale: categoria.id == 'productos' ? 1.22 : 1,
                alignment: Alignment.centerRight,
                child: Image.asset(
                  rutaImagenAsset,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Icon(
                    categoria.icono,
                    size: 72,
                    color: ConfiguracionTema.primario,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 12,
              bottom: 14,
              child: Text(
                categoria.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ConfiguracionTema.grafito,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TarjetaCategoriaCompacta extends StatelessWidget {
  const _TarjetaCategoriaCompacta({
    required this.categoria,
    required this.alPresionar,
    this.seleccionada = false,
  });

  final CategoriaMarketplace categoria;
  final VoidCallback alPresionar;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) => Material(
    color: seleccionada
        ? ConfiguracionTema.salviaClara
        : ConfiguracionTema.cremaSuperficie,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alPresionar,
      child: SizedBox(
        width: 106,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
          child: Column(
            children: [
              Expanded(
                child: Icon(
                  categoria.icono,
                  size: 42,
                  color: ConfiguracionTema.primario,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                categoria.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ConfiguracionTema.grafito,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Escaparate de alto contraste que reúne las publicaciones más consultadas.
class _EscaparatePopular extends StatelessWidget {
  const _EscaparatePopular({
    required this.publicaciones,
    required this.alVerTodo,
  });

  final List<ProductoMarketplace> publicaciones;
  final VoidCallback alVerTodo;

  @override
  Widget build(BuildContext context) {
    if (publicaciones.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, restricciones) {
        final anchoAplicacion = MediaQuery.sizeOf(context).width;
        final anchoCarrusel = anchoAplicacion > restricciones.maxWidth
            ? anchoAplicacion
            : restricciones.maxWidth;
        final margenExterior = (anchoCarrusel - restricciones.maxWidth) / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // El panel es solo la capa decorativa inferior. El carrusel tiene
            // el ancho completo de la app y se pinta por encima de sus bordes.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ConfiguracionTema.moradoPromocional,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(100),
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 18, right: 44),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6E1D5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const MarcaUMarket(
                                  style: TextStyle(
                                    color: ConfiguracionTema.grafito,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Lo que todos quieren\nen el campus',
                                style: TextStyle(
                                  color: Color(0xFFE6E1D5),
                                  fontSize: 23,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: alVerTodo,
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFFE6E1D5),
                          ),
                          child: const Text(
                            'Ver todo',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 246,
                    child: OverflowBox(
                      alignment: Alignment.center,
                      minWidth: anchoCarrusel,
                      maxWidth: anchoCarrusel,
                      child: _CarruselPublicaciones(
                        publicaciones: publicaciones,
                        margenHorizontal: margenExterior + 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Carrusel horizontal de publicaciones. El recorte del viewport hace que las
/// tarjetas se oculten progresivamente detrás de los laterales, en vez de
/// dibujarse fuera y desaparecer de golpe cuando Flutter las recicla.
class _CarruselPublicaciones extends StatelessWidget {
  const _CarruselPublicaciones({
    required this.publicaciones,
    required this.margenHorizontal,
  });

  final List<ProductoMarketplace> publicaciones;
  final double margenHorizontal;

  @override
  Widget build(BuildContext context) => ListView.separated(
    clipBehavior: Clip.hardEdge,
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    scrollDirection: Axis.horizontal,
    // El margen pertenece al contenido inicial, no al viewport. Así las
    // tarjetas pueden atravesar el panel y solo se ocultan al salir de la
    // pared exterior de la aplicación.
    padding: EdgeInsets.symmetric(horizontal: margenHorizontal),
    itemCount: publicaciones.length,
    separatorBuilder: (_, _) => const SizedBox(width: 10),
    itemBuilder: (_, indice) =>
        _TarjetaPublicacion(publicacion: publicaciones[indice]),
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
            childAspectRatio: anchoTarjeta / 205,
          ),
          itemBuilder: (_, indice) => _TarjetaPublicacion(
            publicacion: publicaciones[indice],
            ancho: double.infinity,
            superficieSuave: true,
            mostrarAcciones: false,
          ),
        );
      },
    );
  }
}

class _TarjetaPublicacion extends StatelessWidget {
  static const Color _superficieDescubre = Color(0xFFF5F4F0);

  const _TarjetaPublicacion({
    required this.publicacion,
    this.ancho = 164,
    this.superficieSuave = false,
    this.mostrarAcciones = true,
  });

  final ProductoMarketplace publicacion;
  final double ancho;
  final bool superficieSuave;
  final bool mostrarAcciones;

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
      color: Theme.of(context).brightness == Brightness.dark
          ? ConfiguracionTema.grafito
          : superficieSuave
          ? _superficieDescubre
          : Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrir(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? ConfiguracionTema.grafito
                : superficieSuave
                ? _superficieDescubre
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 132,
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
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publicacion.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
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
                            color: ConfiguracionTema.terracota,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (mostrarAcciones) ...[
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
                                    ? Color(0xFFE6E1D5)
                                    : Color(0xFF474646);
                                return IconButton(
                                  tooltip: favorito
                                      ? 'Quitar de favoritos'
                                      : 'Agregar a favoritos',
                                  onPressed: () => ControladorFavoritos
                                      .instancia
                                      .alternar(publicacion),
                                  style: IconButton.styleFrom(
                                    foregroundColor: favorito
                                        ? const Color(0xFFAE7960)
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
                                backgroundColor: ConfiguracionTema.primario,
                                foregroundColor: Color(0xFFE6E1D5),
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
  const _TituloSeccion({required this.titulo, this.alVerTodo});

  final String titulo;
  final VoidCallback? alVerTodo;

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
      if (alVerTodo != null)
        TextButton(
          onPressed: alVerTodo,
          child: const Text(
            'Ver todo',
            style: TextStyle(
              color: ConfiguracionTema.primario,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
    ],
  );
}
