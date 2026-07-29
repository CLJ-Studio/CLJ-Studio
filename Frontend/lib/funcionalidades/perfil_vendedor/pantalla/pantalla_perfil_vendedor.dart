import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

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
  const PantallaPerfilVendedor({required this.controlador, super.key});

  final ControladorMiLocal controlador;

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
          body: const ArbolConfiguracionUsuario(),
        ),
      ),
    );
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
    return null;
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
                child: _EncabezadoPerfil(
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
                child: _PerfilSinPublicaciones(
                  mensaje: switch (seccion) {
                    0 => 'Tus publicaciones personales aparecerán aquí.',
                    1 => 'Las publicaciones de tu local aparecerán aquí.',
                    _ => 'Los productos que te gusten aparecerán aquí.',
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 120),
                sliver: SliverGrid.builder(
                  itemCount: productos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    childAspectRatio: .72,
                  ),
                  itemBuilder: (_, indice) => _PublicacionPerfil(
                    producto: productos[indice],
                    local: _localDe(productos[indice]),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

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
    final colorContenido = oscuro ? Colors.white : Colors.black;
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
    final colorContenido = oscuro ? Colors.white : Colors.black;
    final iconos = [
      (Icons.grid_view_rounded, 'Publicaciones'),
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
                    color: colorContenido,
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
                          color: indice == 2
                              ? const Color(0xFFE53935)
                              : colorContenido,
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
            color: const Color(0xFFE4E6E4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
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
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
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
        ? Colors.white
        : Colors.black;
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
        ? Colors.white
        : Colors.black;
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
  const _PublicacionPerfil({required this.producto, required this.local});

  final ProductoMarketplace producto;
  final LocalUniversitario? local;

  @override
  Widget build(BuildContext context) {
    Widget tarjeta(VoidCallback? abrir) => Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: abrir,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Color(producto.local?.colorHexadecimal ?? 0xFFF1F6F0),
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
                  colors: [Colors.transparent, Color(0x99000000)],
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
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${producto.vistas}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!producto.disponible)
                    const Icon(
                      Icons.visibility_off_rounded,
                      color: Colors.white,
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
        borderRadius: BorderRadius.circular(10),
      ),
      openShape: const RoundedRectangleBorder(),
      closedBuilder: (_, abrir) => tarjeta(abrir),
      openBuilder: (_, _) =>
          PantallaDetalleProducto(producto: producto, local: local!),
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

class _PerfilSinPublicaciones extends StatelessWidget {
  const _PerfilSinPublicaciones({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
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
