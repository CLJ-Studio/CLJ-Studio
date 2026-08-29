import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../mi_local/diseno/acciones_publicacion.dart';
import '../../mi_local/pantalla/pantalla_crear_local.dart';
import '../../../configuracion_aplicacion/modo_local.dart';
import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../configuracion_usuario/arbol/arbol_configuracion_usuario.dart';
import '../../configuracion_usuario/modelos/usuario_upsa.dart';
import '../../configuracion_usuario/pantalla/pantalla_editar_perfil.dart';
import '../../favoritos/logica/controlador_favoritos.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_producto.dart';
import '../../mi_local/datos/repositorio_mi_local.dart';
import '../../mi_local/logica/controlador_mi_local.dart';

/// Perfil del vendedor con sus métricas y publicaciones.
class PantallaPerfilVendedor extends StatefulWidget {
  const PantallaPerfilVendedor({
    required this.controlador,
    this.alCerrarSesion,
    super.key,
  });

  final ControladorMiLocal controlador;
  final VoidCallback? alCerrarSesion;

  @override
  State<PantallaPerfilVendedor> createState() => _PantallaPerfilVendedorState();
}

class _PantallaPerfilVendedorState extends State<PantallaPerfilVendedor> {
  final sesion = SesionUsuario.instancia;
  final favoritos = ControladorFavoritos.instancia;
  static const repositorio = RepositorioMiLocal();

  int seccion = 0;
  List<ProductoMarketplace> publicacionesPersonales = const [];
  bool cargandoPublicaciones = false;

  @override
  void initState() {
    super.initState();
    sesion.cargar();
    favoritos.cargar();
    _cargarPublicacionesPersonales();
  }

  Future<void> _cargarPublicacionesPersonales() async {
    if (ModoLocal.activo) return;
    setState(() => cargandoPublicaciones = true);
    try {
      final todas = await repositorio.cargarMisPublicaciones();
      final espacioId = widget.controlador.espacioPersonal?.id;
      publicacionesPersonales = espacioId == null
          ? const []
          : todas.where((producto) => producto.localId == espacioId).toList();
    } finally {
      if (mounted) setState(() => cargandoPublicaciones = false);
    }
  }

  /// Gestiona una publicacion propia sin entrar en ella.
  Future<void> _gestionar(ProductoMarketplace producto) async {
    final resultado = await mostrarAccionesPublicacion(context, producto);
    if (resultado == ResultadoAccion.sinCambios || !mounted) return;

    // Se recargan las dos fuentes: la publicacion pudo ser del local o
    // suelta, y desde aqui no se sabe cual sin volver a preguntar.
    await widget.controlador.cargar();
    await _cargarPublicacionesPersonales();
  }

  void _abrirConfiguracion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Configuración',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ArbolConfiguracionUsuario(
            alCerrarSesion: widget.alCerrarSesion,
          ),
        ),
      ),
    );
  }

  Future<void> _crearLocal() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaCrearLocal(
          controlador: widget.controlador,
          alCompletar: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
    if (mounted) await widget.controlador.cargar();
  }

  void _editarPerfil() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaEditarPerfil()),
    );
  }

  LocalUniversitario? _localDe(ProductoMarketplace producto) {
    if (producto.local != null) return producto.local;
    if (widget.controlador.negocio?.id == producto.localId) {
      return widget.controlador.negocio;
    }
    if (widget.controlador.espacioPersonal?.id == producto.localId) {
      return widget.controlador.espacioPersonal;
    }
    // Ultimo recurso: sin local la tarjeta no abre nada, y es preferible
    // mostrar el detalle con el local propio que dejarla sin responder.
    return widget.controlador.negocio ?? widget.controlador.espacioPersonal;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([sesion, widget.controlador, favoritos]),
    builder: (context, _) {
      final perfil = sesion.perfil;
      final personales = ModoLocal.activo
          ? widget.controlador.productos
          : publicacionesPersonales;
      final productosLocal = widget.controlador.productos;
      final productos = switch (seccion) {
        0 => personales,
        1 => productosLocal,
        _ => favoritos.productos,
      };
      final totalPublicaciones = <String>{
        for (final producto in personales) producto.id,
        for (final producto in productosLocal) producto.id,
      }.length;
      final publicacionesUnicas = {
        for (final producto in [...personales, ...productosLocal])
          producto.id: producto,
      }.values;

      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: _EncabezadoPerfilMarketplace(
                  perfil: perfil,
                  publicaciones: totalPublicaciones,
                  vistas: publicacionesUnicas.fold(
                    0,
                    (total, producto) => total + producto.vistas,
                  ),
                  meGusta: favoritos.cantidad,
                  alAbrirConfiguracion: _abrirConfiguracion,
                  alEditarPerfil: _editarPerfil,
                  seccion: seccion,
                  alCambiarSeccion: (valor) => setState(() => seccion = valor),
                ),
              ),
            ),
            if (perfil == null ||
                widget.controlador.cargando ||
                cargandoPublicaciones ||
                favoritos.cargando)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: IndicadorCarga()),
              )
            else if (productos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                // Sin local, la pestaña del medio no tiene nada que
                // enseñar: en vez de un vacio sin salida, invita a abrirlo.
                child: seccion == 1 && !widget.controlador.tieneLocal
                    ? _PerfilSinLocal(alCrear: _crearLocal)
                    : _PerfilSinPublicaciones(
                        mensaje: switch (seccion) {
                          0 => 'Tus publicaciones personales aparecerán aquí.',
                          1 => 'Las publicaciones de tu local aparecerán aquí.',
                          _ => 'Los productos que te gusten aparecerán aquí.',
                        },
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 3, 14, 120),
                sliver: SliverGrid.builder(
                  itemCount: productos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .76,
                  ),
                  itemBuilder: (_, indice) => _PublicacionPerfil(
                    producto: productos[indice],
                    local: _localDe(productos[indice]),
                    // Los favoritos son de otras personas: ahi no hay nada
                    // que gestionar.
                    alGestionar: seccion == 2
                        ? () {}
                        : () => _gestionar(productos[indice]),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _EncabezadoPerfilMarketplace extends StatelessWidget {
  const _EncabezadoPerfilMarketplace({
    required this.perfil,
    required this.publicaciones,
    required this.vistas,
    required this.meGusta,
    required this.alAbrirConfiguracion,
    required this.alEditarPerfil,
    required this.seccion,
    required this.alCambiarSeccion,
  });

  final UsuarioUpsa? perfil;
  final int publicaciones;
  final int vistas;
  final int meGusta;
  final VoidCallback alAbrirConfiguracion;
  final VoidCallback alEditarPerfil;
  final int seccion;
  final ValueChanged<int> alCambiarSeccion;

  static String _abreviar(int valor) {
    if (valor >= 1000000) {
      return '${(valor / 1000000).toStringAsFixed(1)}M';
    }
    if (valor >= 1000) return '${(valor / 1000).toStringAsFixed(1)}K';
    return '$valor';
  }

  @override
  Widget build(BuildContext context) {
    final nombre = perfil?.nombre.trim();
    final correo = perfil?.correo.trim();
    final carrera = perfil?.carrera.trim();
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 42),
          decoration: const BoxDecoration(
            color: ConfiguracionTema.primario,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mi perfil',
                        style: TextStyle(
                          color: Color(0xFFE6E1D5),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Configuración',
                      onPressed: alAbrirConfiguracion,
                      style: IconButton.styleFrom(
                        foregroundColor: Color(0xFFE6E1D5),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AvatarPerfil(perfil: perfil, alEditar: alEditarPerfil),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre == null || nombre.isEmpty
                              ? 'Vendedor UPSA'
                              : nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE6E1D5),
                            fontSize: 22,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          carrera == null || carrera.isEmpty
                              ? 'Comunidad UPSA'
                              : carrera,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFE6E1D5).withValues(alpha: .82),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 11),
                        OutlinedButton.icon(
                          onPressed: alEditarPerfil,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ConfiguracionTema.primario,
                            backgroundColor: Color(0xFFE6E1D5),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text(
                            'Editar perfil',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: oscuro ? const Color(0xFF474646) : Color(0xFFE6E1D5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18474646),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricaMarketplace(
                    valor: '$publicaciones',
                    etiqueta: 'Publicaciones',
                  ),
                  _MetricaMarketplace(
                    valor: _abreviar(vistas),
                    etiqueta: 'Vistas',
                  ),
                  _MetricaMarketplace(
                    valor: _abreviar(meGusta),
                    etiqueta: 'Favoritos',
                  ),
                ],
              ),
            ),
          ),
        ),
        if (correo != null && correo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              correo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (perfil?.biografia case final String bio when bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(bio, textAlign: TextAlign.center),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: _SelectorPerfil(
            seleccionado: seccion,
            alSeleccionar: alCambiarSeccion,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MetricaMarketplace extends StatelessWidget {
  const _MetricaMarketplace({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        valor,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 2),
      Text(
        etiqueta,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

// Conserva temporalmente la composición anterior para facilitar una posible
// comparación visual durante la transición del diseño.
// ignore: unused_element
class _EncabezadoPerfil extends StatelessWidget {
  const _EncabezadoPerfil({
    required this.perfil,
    required this.publicaciones,
    required this.vistas,
    required this.meGusta,
    required this.alAbrirConfiguracion,
    required this.alEditarPerfil,
    required this.seccion,
    required this.alCambiarSeccion,
  });

  final UsuarioUpsa? perfil;
  final int publicaciones;
  final int vistas;
  final int meGusta;
  final VoidCallback alAbrirConfiguracion;
  final VoidCallback alEditarPerfil;
  final int seccion;
  final ValueChanged<int> alCambiarSeccion;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorContenido = oscuro ? Color(0xFFE6E1D5) : Color(0xFF474646);
    final nombre = perfil?.nombre.trim();
    final correo = perfil?.correo.trim();
    final carrera = perfil?.carrera.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 5, 8, 0),
          child: SizedBox(
            width: double.infinity,
            height: 53,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: Text(
                    'Perfil',
                    style: TextStyle(
                      color: colorContenido,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    correo == null || correo.isEmpty
                        ? 'correo@upsa.edu.bo'
                        : correo,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorContenido,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    tooltip: 'Configuración',
                    onPressed: alAbrirConfiguracion,
                    icon: Icon(Icons.settings_outlined, color: colorContenido),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 138,
                child: _AvatarPerfil(perfil: perfil, alEditar: alEditarPerfil),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 38),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricaPerfil(valor: '$publicaciones', etiqueta: 'Post'),
                      _MetricaPerfil(
                        valor: _abreviar(vistas),
                        etiqueta: 'Vistas',
                      ),
                      _MetricaPerfil(
                        valor: _abreviar(meGusta),
                        etiqueta: 'Me gusta',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre == null || nombre.isEmpty
                          ? 'Vendedor UPSA'
                          : nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorContenido,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: alEditarPerfil,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorContenido,
                      side: BorderSide(color: colorContenido, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text(
                      'Editar perfil',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                carrera == null || carrera.isEmpty
                    ? 'Carrera no registrada'
                    : carrera,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorContenido,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (perfil?.biografia case final String bio when bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    bio,
                    style: TextStyle(
                      color: colorContenido,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _SelectorPerfil(
            seleccionado: seccion,
            alSeleccionar: alCambiarSeccion,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  static String _abreviar(int valor) {
    if (valor >= 1000000) {
      return '${(valor / 1000000).toStringAsFixed(1)}M';
    }
    if (valor >= 1000) return '${(valor / 1000).toStringAsFixed(1)}K';
    return '$valor';
  }
}

class _SelectorPerfil extends StatelessWidget {
  const _SelectorPerfil({
    required this.seleccionado,
    required this.alSeleccionar,
  });

  final int seleccionado;
  final ValueChanged<int> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorContenido = oscuro ? Color(0xFFE6E1D5) : Color(0xFF474646);
    final iconos = [
      (Icons.grid_view_rounded, 'Publicaciones personales'),
      (Icons.storefront_rounded, 'Publicaciones del local'),
      (Icons.favorite_rounded, 'Favoritos'),
    ];

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic,
            alignment: Alignment((seleccionado - 1).toDouble(), 1),
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: ConfiguracionTema.primario,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var indice = 0; indice < iconos.length; indice++)
                Expanded(
                  child: Tooltip(
                    message: iconos[indice].$2,
                    child: InkWell(
                      onTap: () => alSeleccionar(indice),
                      child: Center(
                        child: Icon(
                          iconos[indice].$1,
                          size: 25,
                          color: indice == seleccionado
                              ? ConfiguracionTema.primario
                              : indice == 2
                              ? const Color(0xFFAE7960)
                              : colorContenido.withValues(alpha: .48),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarPerfil extends StatelessWidget {
  const _AvatarPerfil({required this.perfil, required this.alEditar});

  final UsuarioUpsa? perfil;
  final VoidCallback alEditar;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 122,
    height: 122,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 122,
          height: 122,
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE6E1D5),
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFFE6E1D5), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22474646),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: switch (perfil?.avatarUrl) {
            final String url => Image.network(
              url,
              width: 122,
              height: 122,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InicialPerfil(perfil: perfil),
            ),
            _ => _InicialPerfil(perfil: perfil),
          },
        ),
        Positioned(
          right: -2,
          bottom: 3,
          child: IconButton.filled(
            tooltip: 'Cambiar foto',
            onPressed: alEditar,
            iconSize: 18,
            style: IconButton.styleFrom(
              backgroundColor: Color(0xFF474646),
              foregroundColor: Color(0xFFE6E1D5),
            ),
            icon: const Icon(Icons.camera_alt_rounded),
          ),
        ),
      ],
    ),
  );
}

class _InicialPerfil extends StatelessWidget {
  const _InicialPerfil({required this.perfil});

  final UsuarioUpsa? perfil;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFFE6E1D5)
        : Color(0xFF474646);
    return Text(
      perfil?.inicial ?? '?',
      style: TextStyle(color: color, fontSize: 50, fontWeight: FontWeight.w900),
    );
  }
}

class _MetricaPerfil extends StatelessWidget {
  const _MetricaPerfil({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFFE6E1D5)
        : Color(0xFF474646);
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicacionPerfil extends StatelessWidget {
  const _PublicacionPerfil({
    required this.producto,
    required this.local,
    required this.alGestionar,
  });

  final ProductoMarketplace producto;
  final LocalUniversitario? local;

  /// Manteniendo pulsado se gestiona sin abrir la publicacion. El perfil es
  /// la unica lista donde estan todas juntas, asi que tener que entrar en
  /// cada una para editarla obligaba a ir y volver por cada cambio.
  final VoidCallback alGestionar;

  @override
  Widget build(BuildContext context) {
    Widget tarjeta(VoidCallback? abrir) => Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: abrir,
        onLongPress: alGestionar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Color(producto.local?.colorHexadecimal ?? 0xFFE6E1D5),
              child: switch (producto.imagenUrl) {
                final String url => Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _EmojiProducto(producto.emoji),
                ),
                _ => _EmojiProducto(producto.emoji),
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99474646)],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 7,
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_rounded,
                    color: Color(0xFFE6E1D5),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${producto.vistas}',
                      style: const TextStyle(
                        color: Color(0xFFE6E1D5),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!producto.disponible)
                    const Icon(
                      Icons.visibility_off_rounded,
                      color: Color(0xFFE6E1D5),
                      size: 15,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (local == null) return tarjeta(null);
    return OpenContainer<void>(
      transitionDuration: const Duration(milliseconds: 580),
      transitionType: ContainerTransitionType.fade,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      openShape: const RoundedRectangleBorder(),
      closedBuilder: (_, abrir) => tarjeta(abrir),
      openBuilder: (_, _) => PantallaDetalleProducto(
        producto: producto,
        local: local!,
        // Ya se viene del perfil de quien vende: el enlace volveria a
        // apilar la pantalla de la que se acaba de salir.
        vendedorNavegable: false,
      ),
    );
  }
}

class _EmojiProducto extends StatelessWidget {
  const _EmojiProducto(this.emoji);

  final String emoji;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(emoji, style: const TextStyle(fontSize: 42)));
}

/// Invitacion a abrir un local desde la pestaña que aun no tiene ninguno.
class _PerfilSinLocal extends StatelessWidget {
  const _PerfilSinLocal({required this.alCrear});

  final VoidCallback alCrear;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 46,
            color: tema.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no tienes un local',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ábrelo si vendes con una marca y quieres tu propia vitrina. '
            'Lo que publiques por tu cuenta seguirá donde está.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tema.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: alCrear,
            icon: const Icon(Icons.add_business_rounded, size: 20),
            label: const Text('Crear mi local'),
          ),
        ],
      ),
    );
  }
}

class _PerfilSinPublicaciones extends StatelessWidget {
  const _PerfilSinPublicaciones({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFFE6E1D5)
        : Color(0xFF474646);
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view_rounded, size: 46, color: color),
          const SizedBox(height: 12),
          Text(
            'Todavía no tienes publicaciones',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
