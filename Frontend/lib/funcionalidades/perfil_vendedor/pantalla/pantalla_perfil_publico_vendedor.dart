import 'package:flutter/material.dart';

import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';

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

class _PantallaPerfilPublicoVendedorState
    extends State<PantallaPerfilPublicoVendedor> {
  int seccion = 0;

  late final Future<List<ProductoMarketplace>> publicaciones =
      _cargarPublicaciones();

  Future<List<ProductoMarketplace>> _cargarPublicaciones() async {
    try {
      return await const RepositorioInicioMarketplace().obtenerProductos(
        widget.local.id,
      );
    } catch (_) {
      return [widget.publicacionInicial];
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
      body: FutureBuilder<List<ProductoMarketplace>>(
        future: publicaciones,
        builder: (context, snapshot) {
          final productos = snapshot.data ?? [widget.publicacionInicial];
          final vistas = productos.fold(
            0,
            (total, producto) => total + producto.vistas,
          );

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
                                    valor: '${productos.length}',
                                    etiqueta: 'Post',
                                  ),
                                  _Metrica(
                                    valor: '$vistas',
                                    etiqueta: 'Vistas',
                                  ),
                                  const _Metrica(
                                    valor: '0',
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
              if (seccion == 2)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 100),
                      child: Text(
                        'Los favoritos son privados.',
                        style: TextStyle(
                          color: Colors.black,
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
                    itemBuilder: (_, indice) =>
                        _Publicacion(producto: productos[indice]),
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
                      child: Icon(iconos[indice], color: color, size: 25),
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
  const _Publicacion({required this.producto});

  final ProductoMarketplace producto;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: ColoredBox(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      child: switch (producto.imagenUrl) {
        final String url => Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(producto.emoji, style: const TextStyle(fontSize: 40)),
          ),
        ),
        _ => Center(
          child: Text(producto.emoji, style: const TextStyle(fontSize: 40)),
        ),
      },
    ),
  );
}
