import 'dart:async';

import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../instalacion_app/diseno/aviso_instalacion.dart';
import '../../locales_universitarios/diseno/carrusel_locales_destacados.dart';
import '../../locales_universitarios/diseno/lista_productos_local.dart';
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

  /// Las categorías que hoy tienen algo publicado, en el orden del catálogo.
  ///
  /// El banner solo puede ofrecer estas: mandar a alguien a una categoría
  /// vacía es prometer algo que no está.
  static List<CategoriaMarketplace> _conContenido(
    List<CategoriaMarketplace> categorias,
    List<ProductoMarketplace> publicaciones,
  ) {
    final conAlgo = {
      for (final publicacion in publicaciones) publicacion.categoriaEfectiva,
    };
    return categorias
        .where((categoria) => conAlgo.contains(categoria.id))
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
      final estadoHome = buscando
          ? estado.copiarCon(busqueda: '', publicaciones: publicacionesHome)
          : estado;
      final localesPorId = <String, LocalUniversitario>{};
      for (final publicacion in publicacionesHome) {
        final local = publicacion.local;
        if (local != null) localesPorId[local.id] = local;
      }
      final localesMasVistos = localesPorId.values.toList(growable: false)
        ..sort((a, b) => b.vistas.compareTo(a.vistas));
      return Stack(
        children: [
          CustomScrollView(
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
                    child: switch (estadoHome) {
                      EstadoInicioMarketplace(cargando: true) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: IndicadorCarga(tamanio: 140)),
                      ),
                      EstadoInicioMarketplace(error: final String mensaje) =>
                        MensajeCatalogo(
                          mensaje: mensaje,
                          alReintentar: controlador.cargar,
                        ),
                      // Las categorías van CON el mensaje de vacío, no solo
                      // con el contenido. Al filtrar por una categoría sin
                      // publicaciones desaparecían junto al feed: el cartel
                      // decía "prueba con otra categoría" y no quedaba
                      // ninguna en pantalla para tocar. Solo se salía
                      // recargando.
                      EstadoInicioMarketplace(publicaciones: []) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CategoriasInicio(
                            categorias: estado.categorias,
                            categoriaId: estado.categoriaId,
                            alSeleccionar: controlador.seleccionarCategoria,
                          ),
                          _FeedVacio(
                            hayFiltro:
                                estado.categoriaId != 'todas' ||
                                estado.busqueda.isNotEmpty,
                          ),
                        ],
                      ),
                      _ => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AnuncioPrincipal(
                            categoriasConContenido: _conContenido(
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
                                () => controlador.seleccionarCategoria('todas'),
                          ),
                          const SizedBox(height: 6),
                          CarruselLocalesDestacados(
                            locales: localesMasVistos,
                            construirDetalle: (_, local) =>
                                PantallaDetalleLocal(local: local),
                          ),
                          const SizedBox(height: 22),
                          // Hacia abajo y no de costado. En una tira
                          // horizontal solo se ven tres publicaciones y el
                          // resto hay que arrastrarlo de derecha a izquierda
                          // sin saber cuanto falta. Es la misma cuadricula de
                          // Locales y Favoritos, asi que se recorre igual en
                          // toda la aplicacion.
                          _TituloSeccion(
                            titulo: 'Lo último en el campus',
                            alVerTodo: () =>
                                controlador.seleccionarCategoria('todas'),
                          ),
                          const SizedBox(height: 10),
                          ListaProductosLocal(productos: publicacionesHome),
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
  });

  final String consulta;
  final List<ProductoMarketplace> publicaciones;

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

    // Lo que se busca en un marketplace es lo que se vende. Faltaba: el panel
    // solo miraba locales y personas, así que escribir "empanada" no encontraba
    // una publicación llamada "Empanadas de queso" salvo que el local se
    // llamara parecido.
    final publicacionesHalladas = [
      for (final publicacion in publicaciones)
        if (publicacion.local != null &&
            (_coincide(publicacion.nombre, buscado) ||
                _coincide(publicacion.descripcion, buscado)))
          publicacion,
    ];

    final total =
        publicacionesHalladas.length + localesPorId.length + personas.length;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total == 0)
            const _BusquedaVacia()
          else ...[
            // Primero lo que se vende: es lo que casi siempre se busca.
            if (publicacionesHalladas.isNotEmpty)
              _SeccionResultados(
                titulo: 'Publicaciones',
                children: [
                  for (final publicacion in publicacionesHalladas)
                    _ResultadoBusqueda(
                      icono: Icons.sell_rounded,
                      titulo: publicacion.nombre,
                      imagenUrl: publicacion.imagenUrl,
                      alPresionar: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PantallaDetalleProducto(
                            producto: publicacion,
                            local: publicacion.local!,
                            vendedorNavegable: true,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            if (personas.isNotEmpty)
              _SeccionResultados(
                titulo: 'Personas',
                children: [
                  for (final persona in personas.values)
                    _ResultadoBusqueda(
                      icono: Icons.person_rounded,
                      titulo: persona.$1.vendedorNombre,
                      imagenUrl: persona.$1.vendedorAvatarUrl,
                      alPresionar: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PantallaPerfilPublicoVendedor(
                            local: persona.$1,
                            publicacionInicial: persona.$2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            if (localesPorId.isNotEmpty)
              _SeccionResultados(
                titulo: 'Locales',
                children: [
                  for (final local in localesPorId.values)
                    _ResultadoBusqueda(
                      icono: Icons.storefront_rounded,
                      titulo: local.nombreVisible,
                      alPresionar: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PantallaDetalleLocal(local: local),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _SeccionResultados extends StatelessWidget {
  const _SeccionResultados({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 58,
                    color: Theme.of(context).dividerColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResultadoBusqueda extends StatelessWidget {
  const _ResultadoBusqueda({
    required this.icono,
    required this.titulo,
    required this.alPresionar,
    this.imagenUrl,
  });

  final IconData icono;
  final String titulo;
  final String? imagenUrl;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: alPresionar,
    leading: _ImagenResultado(icono: icono, imagenUrl: imagenUrl),
    title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
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

/// Banner de bienvenida con sus diapositivas armadas desde el catálogo real.
///
/// Las categorías que ofrece salen de lo que hay publicado ahora mismo, no de
/// una lista escrita a mano. Antes decía "Ver comida" siempre: si ese día
/// nadie vendía comida, el botón llevaba a una pantalla vacía. Un anuncio que
/// promete algo que no está es peor que no tener anuncio.
class _AnuncioPrincipal extends StatefulWidget {
  const _AnuncioPrincipal({
    required this.categoriasConContenido,
    required this.alSeleccionar,
  });

  /// Solo las categorías que hoy tienen algo que enseñar.
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

  /// Textos escritos para las categorías que más se usan.
  ///
  /// Lo que no esté aquí igual sale, con un texto armado desde su nombre: es
  /// preferible un anuncio genérico y cierto a uno bonito que no lleva a nada.
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
    'libros': (
      'Los libros que\nya no usás.',
      'Material que pasa de mano en mano.',
    ),
    'ropa': ('Ropa con\nsegunda vuelta.', 'Lo que otro ya no se pone.'),
  };

  /// Los dos verdes que acompañan al principal, alternados.
  static const _colores = [Color(0xFF237A45), Color(0xFF315C3B)];

  List<BannerData> get _banners => [
    BannerData(
      titulo: 'Todo lo que\nnecesitas,\nen el campus.',
      subtitulo: 'Compra, vende y descubre.',
      textoBoton: 'Explorar ahora',
      colorDegradado: const Color(0xFF16A34A),
      accion: () => widget.alSeleccionar('todas'),
    ),
    // Como mucho dos más: el banner se pasa solo y con más nadie llega al final.
    for (final (indice, categoria)
        in widget.categoriasConContenido.take(2).indexed)
      BannerData(
        titulo:
            _textos[categoria.id]?.$1 ??
            'Hay ${categoria.nombre}\nen el campus.',
        subtitulo: _textos[categoria.id]?.$2 ?? 'Mirá lo que publicaron.',
        textoBoton: 'Ver ${categoria.nombre.toLowerCase()}',
        colorDegradado: _colores[indice % _colores.length],
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
    // El catálogo llega por Realtime: si una categoría se queda sin nada, hay
    // una diapositiva menos y el punto activo apuntaría a una que ya no está.
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
    required this.accion,
  });

  final String titulo;
  final String subtitulo;
  final String textoBoton;
  final Color colorDegradado;
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
        // Fondo neutro: las campañas reales podrán llegar desde el backend.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                data.colorDegradado,
                data.colorDegradado.withValues(alpha: .84),
                data.colorDegradado.withValues(alpha: .7),
              ],
              stops: const [0, .52, 1],
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

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 62,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categorias.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, indice) {
        final categoria = categorias[indice];
        final seleccionada = categoria.id == categoriaId;
        return Tooltip(
          message: categoria.nombre,
          child: GestureDetector(
            onTap: () => alSeleccionar(categoria.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: seleccionada
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

class _FeedVacio extends StatelessWidget {
  const _FeedVacio({required this.hayFiltro});

  final bool hayFiltro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 50,
          color: Color(0xFFB8BDB8),
        ),
        const SizedBox(height: 16),
        Text(
          hayFiltro ? 'Nada por aquí todavía' : 'Sé el primero en publicar',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          hayFiltro
              ? 'Prueba con otra categoría o busca otra cosa.'
              : 'Lo que publiques aparecerá aquí para toda la comunidad.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7B817D)),
        ),
      ],
    ),
  );
}
