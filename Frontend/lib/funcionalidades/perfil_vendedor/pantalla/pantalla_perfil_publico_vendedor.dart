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
    this.favoritos = const [],
    this.favoritosPublicos = false,
    this.nombre = '',
    this.carrera = '',
    this.biografia = '',
    this.negocio,
  });

  final List<ProductoMarketplace> personales;
  final List<ProductoMarketplace> favoritos;

  /// Quien es la persona. El perfil es SUYO, no de su local: por eso el
  /// nombre sale de `perfiles_publicos` y no del nombre de la tienda.
  final String nombre;
  final String carrera;

  /// Lo que la persona escribio sobre si misma.
  final String biografia;

  /// Su negocio, si abrio uno. Se enseña como un enlace debajo de la
  /// carrera en vez de como una pestaña: un local no tiene favoritos ni
  /// carrera, asi que mezclarlo dentro del perfil no tenia sentido.
  final LocalUniversitario? negocio;

  /// Si la persona decidio enseñar sus favoritos. Se distingue de "no tiene
  /// ninguno" para poder explicar por que la pestaña esta vacia.
  final bool favoritosPublicos;

  int get totalPublicaciones => personales.length;

  int get vistas =>
      personales.fold(0, (total, producto) => total + producto.vistas);
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
      final (perfil, locales, favoritos) = await (
        repositorio.obtenerPerfilPublico(dueno),
        repositorio.obtenerLocalesDe(dueno),
        repositorio.obtenerFavoritosPublicos(dueno),
      ).wait;

      // Todo lo que publico, venga de su espacio personal o de su negocio:
      // para quien mira es una sola lista de cosas que vende.
      final publicaciones = await repositorio.obtenerProductosDe(locales);

      return _ContenidoPerfil(
        personales: publicaciones,
        favoritos: favoritos,
        favoritosPublicos: favoritos.isNotEmpty,
        nombre: perfil?.nombre ?? widget.local.vendedorNombre,
        carrera: perfil?.carrera ?? '',
        biografia: perfil?.biografia ?? '',
        negocio: locales.where((l) => !l.esPersonal).firstOrNull,
      );
    } catch (_) {
      return _ContenidoPerfil(
        personales: [widget.publicacionInicial],
        nombre: widget.local.vendedorNombre,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.local;
    // El perfil es de la persona: si su nombre no viniera, antes se caia al
    // nombre del local y la pantalla parecia el perfil de una tienda.
    final nombre = local.vendedorNombre;
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
          final productos = seccion == 0 ? datos.personales : datos.favoritos;

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
                      if (datos.carrera.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            datos.carrera,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      if (datos.biografia.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            datos.biografia,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      // El local va como enlace y no como pestaña: no tiene
                      // carrera ni favoritos, asi que meterlo dentro del
                      // perfil confundia las dos cosas.
                      if (datos.negocio case final LocalUniversitario negocio)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _EnlaceLocal(local: negocio),
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
                          0 => 'Todavía no publicó nada.',
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

/// Indica que esta persona tiene un local, sin llevar a ninguna parte.
///
/// NO es un boton a proposito. Cuando lo era se podia ir perfil -> local ->
/// producto -> vendedor -> local -> ... encadenando pantallas sin fin, porque
/// el mismo par de sitios se enlazaba en los dos sentidos. El camino hacia el
/// local sale de la publicacion; aqui solo se informa de quien es.
class _EnlaceLocal extends StatelessWidget {
  const _EnlaceLocal({required this.local});

  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tema.colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 20,
              color: tema.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dueño de',
                    style: TextStyle(
                      color: tema.textTheme.bodyMedium?.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    local.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tema.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    // La tienda ya no es una pestaña: se llega por el enlace de arriba.
    const iconos = [Icons.grid_view_rounded, Icons.favorite_rounded];

    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic,
            alignment: Alignment(seleccionado == 0 ? -1 : 1, 1),
            child: FractionallySizedBox(
              widthFactor: 1 / 2,
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
                        color: indice == 1 ? const Color(0xFFE53935) : color,
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
