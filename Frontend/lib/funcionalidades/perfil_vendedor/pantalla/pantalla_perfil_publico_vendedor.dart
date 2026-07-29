import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_producto.dart';

/// Perfil público al que se llega tocando el vendedor de una publicación.
class PantallaPerfilPublicoVendedor extends StatefulWidget {
  const PantallaPerfilPublicoVendedor({
    required this.local,
    required this.publicacionInicial,
    super.key,
  });

  final LocalUniversitario local;
  final ProductoMarketplace publicacionInicial;

  @override
  State<PantallaPerfilPublicoVendedor> createState() =>
      _PantallaPerfilPublicoVendedorState();
}

/// Lo que se enseña en cada pestaña del perfil.
class _ContenidoPerfil {
  const _ContenidoPerfil({
    this.personales = const [],
    this.delLocal = const [],
    this.favoritos = const [],
    this.tieneLocal = false,
    this.favoritosPublicos = false,
  });

  final List<ProductoMarketplace> personales;
  final List<ProductoMarketplace> delLocal;
  final List<ProductoMarketplace> favoritos;
  final bool tieneLocal;

  /// Si la persona decidio enseñar sus favoritos. Se distingue de "no tiene
  /// ninguno" para poder explicar por que la pestaña esta vacia.
  final bool favoritosPublicos;

  int get totalPublicaciones => personales.length + delLocal.length;

  int get vistas => [
    ...personales,
    ...delLocal,
  ].fold(0, (total, producto) => total + producto.vistas);
}

class _PantallaPerfilPublicoVendedorState
    extends State<PantallaPerfilPublicoVendedor> {
  int seccion = 0;

  late final Future<_ContenidoPerfil> contenido = _cargar();

  /// Las tres pestañas enseñaban lo mismo porque solo se conocia el local
  /// desde el que se abrio el perfil. Una persona puede tener su espacio
  /// personal Y su negocio, asi que se piden los dos por su dueño y se
  /// reparten; los favoritos vienen por su propia puerta, que respeta el
  /// interruptor de privacidad.
  Future<_ContenidoPerfil> _cargar() async {
    const repositorio = RepositorioInicioMarketplace();
    final dueno = widget.local.duenoId;

    if (dueno.isEmpty) {
      return _ContenidoPerfil(personales: [widget.publicacionInicial]);
    }

    try {
      final locales = await repositorio.obtenerLocalesDe(dueno);
      final personales = locales.where((l) => l.esPersonal).toList();
      final negocios = locales.where((l) => !l.esPersonal).toList();

      final (sueltas, delLocal, favoritos) = await (
        repositorio.obtenerProductosDe(personales),
        repositorio.obtenerProductosDe(negocios),
        repositorio.obtenerFavoritosPublicos(dueno),
      ).wait;

      return _ContenidoPerfil(
        personales: sueltas,
        delLocal: delLocal,
        favoritos: favoritos,
        tieneLocal: negocios.isNotEmpty,
        favoritosPublicos: favoritos.isNotEmpty,
      );
    } catch (_) {
      return _ContenidoPerfil(personales: [widget.publicacionInicial]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.local;
    final nombre = local.vendedorNombre.isEmpty
        ? local.nombre
        : local.vendedorNombre;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorContenido = oscuro ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: colorContenido,
        title: Text(
          nombre,
          style: TextStyle(color: colorContenido, fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<_ContenidoPerfil>(
        future: contenido,
        builder: (context, snapshot) {
          final datos =
              snapshot.data ??
              _ContenidoPerfil(personales: [widget.publicacionInicial]);
          final vistas = datos.vistas;
          // Cada pestaña con lo suyo: sueltas, del local y me gusta.
          final productos = switch (seccion) {
            0 => datos.personales,
            1 => datos.delLocal,
            _ => datos.favoritos,
          };

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 138,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AvatarVendedor(local: local),
                                const SizedBox(height: 10),
                                Text(
                                  nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorContenido,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (local.categoria.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    local.categoria,
                                    style: TextStyle(
                                      color: colorContenido,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 38),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _Metrica(
                                    valor: '${datos.totalPublicaciones}',
                                    etiqueta: 'Post',
                                  ),
                                  // Solo si quien vende lo permite en
                                  // Privacidad. Se oculta la metrica entera,
                                  // no se pinta un cero: un cero dice tanto
                                  // como el numero real.
                                  if (local.muestraVistas)
                                    _Metrica(
                                      valor: '$vistas',
                                      etiqueta: 'Vistas',
                                    ),
                                  // Solo si los hizo publicos: un cero
                                  // fijo decia lo mismo tanto si no tiene
                                  // ninguno como si los oculto.
                                  if (datos.favoritosPublicos)
                                    _Metrica(
                                      valor: '${datos.favoritos.length}',
                                      etiqueta: 'Me gusta',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SelectorPublico(
                        seleccionado: seccion,
                        alSeleccionar: (valor) =>
                            setState(() => seccion = valor),
                      ),
                    ],
                  ),
                ),
              ),
              if (productos.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 0, 40, 100),
                      child: Text(
                        // El motivo importa: no es lo mismo que no tenga
                        // nada a que haya decidido no enseñarlo.
                        switch (seccion) {
                          0 => 'Todavía no publicó nada por su cuenta.',
                          1 =>
                            datos.tieneLocal
                                ? 'Su local aún no tiene publicaciones.'
                                : 'No tiene un local abierto.',
                          _ =>
                            datos.favoritosPublicos
                                ? 'Todavía no guardó ningún favorito.'
                                : 'Prefiere mantener sus favoritos en privado.',
                        },
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: oscuro ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(3, 0, 3, 30),
                  sliver: SliverGrid.builder(
                    itemCount: productos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                          childAspectRatio: .72,
                        ),
                    itemBuilder: (_, indice) => _Publicacion(
                      producto: productos[indice],
                      local: widget.local,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarVendedor extends StatelessWidget {
  const _AvatarVendedor({required this.local});

  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) => Container(
    width: 122,
    height: 122,
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Color(local.colorHexadecimal),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: switch (local.vendedorAvatarUrl) {
      final String url => Image.network(
        url,
        width: 122,
        height: 122,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Text(local.emoji, style: const TextStyle(fontSize: 48)),
      ),
      _ => Text(local.emoji, style: const TextStyle(fontSize: 48)),
    },
  );
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(etiqueta, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

class _SelectorPublico extends StatelessWidget {
  const _SelectorPublico({
    required this.seleccionado,
    required this.alSeleccionar,
  });

  final int seleccionado;
  final ValueChanged<int> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    const iconos = [
      Icons.grid_view_rounded,
      Icons.storefront_rounded,
      Icons.favorite_rounded,
    ];

    return SizedBox(
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
                    color: color,
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
                  child: InkWell(
                    onTap: () => alSeleccionar(indice),
                    child: Center(
                      child: Icon(
                        iconos[indice],
                        color: indice == 2 ? const Color(0xFFE53935) : color,
                        size: 25,
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

class _Publicacion extends StatelessWidget {
  const _Publicacion({required this.producto, required this.local});

  final ProductoMarketplace producto;
  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) => OpenContainer<void>(
    transitionDuration: const Duration(milliseconds: 580),
    transitionType: ContainerTransitionType.fade,
    closedElevation: 0,
    openElevation: 0,
    closedColor: Colors.transparent,
    openColor: Theme.of(context).scaffoldBackgroundColor,
    closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    openShape: const RoundedRectangleBorder(),
    openBuilder: (_, _) =>
        PantallaDetalleProducto(producto: producto, local: local),
    closedBuilder: (_, abrir) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: abrir,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          child: switch (producto.imagenUrl) {
            final String url => Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  producto.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            _ => Center(
              child: Text(producto.emoji, style: const TextStyle(fontSize: 40)),
            ),
          },
        ),
      ),
    ),
  );
}
