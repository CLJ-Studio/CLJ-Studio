import 'package:flutter/material.dart';

import '../../notificaciones/diseno/boton_campana.dart';
import '../modelos/categoria_marketplace.dart';
import 'barra_busqueda_marketplace.dart';
import 'barra_categorias_marketplace.dart';
import 'boton_carrito_compras.dart';

/// Cabecera compartida por Inicio y Locales inspirada en una app de delivery.
class CampusCollapsingHeader extends StatelessWidget {
  const CampusCollapsingHeader({
    required this.nombre,
    required this.categorias,
    required this.categoriaId,
    required this.alBuscar,
    required this.alSeleccionarCategoria,
    required this.alAbrirCarrito,
    required this.alAbrirPedidos,
    super.key,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
    pinned: true,
    delegate: CampusHeaderDelegate(
      nombre: nombre,
      categorias: categorias,
      categoriaId: categoriaId,
      alBuscar: alBuscar,
      alSeleccionarCategoria: alSeleccionarCategoria,
      alAbrirCarrito: alAbrirCarrito,
      alAbrirPedidos: alAbrirPedidos,
    ),
  );
}

/// Versión fija situada por encima del PageView principal.
class CampusFixedHeader extends StatelessWidget {
  const CampusFixedHeader({
    required this.nombre,
    required this.categorias,
    required this.categoriaId,
    required this.alBuscar,
    required this.alSeleccionarCategoria,
    required this.alAbrirCarrito,
    required this.alAbrirPedidos,
    super.key,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 234,
    child: CampusHeaderDelegate(
      nombre: nombre,
      categorias: categorias,
      categoriaId: categoriaId,
      alBuscar: alBuscar,
      alSeleccionarCategoria: alSeleccionarCategoria,
      alAbrirCarrito: alAbrirCarrito,
      alAbrirPedidos: alAbrirPedidos,
    ).build(context, 0, false),
  );
}

class CampusHeaderDelegate extends SliverPersistentHeaderDelegate {
  CampusHeaderDelegate({
    required this.nombre,
    required this.categorias,
    required this.categoriaId,
    required this.alBuscar,
    required this.alSeleccionarCategoria,
    required this.alAbrirCarrito,
    required this.alAbrirPedidos,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;

  @override
  double get maxExtent => 234;

  @override
  double get minExtent => 234;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = oscuro ? Theme.of(context).colorScheme.surface : Colors.white;
    final texto = oscuro ? Colors.white : const Color(0xFF202220);
    final secundario = oscuro
        ? Colors.white.withValues(alpha: .62)
        : const Color(0xFF8A8E8A);

    return ColoredBox(
      color: fondo,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200, minHeight: 234),
            child: Column(
              children: [
                SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5C8A63),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          nombre.isEmpty ? 'U' : nombre[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ubicación',
                              style: TextStyle(
                                color: secundario,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF5C8A63),
                                  size: 17,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'Campus UPSA',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: texto,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF5C8A63),
                                  size: 19,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const BotonCampana(),
                      const SizedBox(width: 5),
                      _AccionCircular(
                        tooltip: 'Mis pedidos',
                        icono: Icons.local_shipping_rounded,
                        alPresionar: alAbrirPedidos,
                      ),
                      const SizedBox(width: 5),
                      BotonCarritoCompras(alPresionar: alAbrirCarrito),
                    ],
                  ),
                ),
                BarraBusquedaMarketplace(alCambiar: alBuscar),
                const SizedBox(height: 7),
                SizedBox(
                  height: 34,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Explora categorías',
                          style: TextStyle(
                            color: texto,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => alSeleccionarCategoria('todas'),
                        child: const Text(
                          'Ver todo',
                          style: TextStyle(
                            color: Color(0xFF5C8A63),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BarraCategoriasMarketplace(
                    categorias: categorias,
                    categoriaId: categoriaId,
                    alSeleccionar: alSeleccionarCategoria,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CampusHeaderDelegate oldDelegate) =>
      oldDelegate.categoriaId != categoriaId ||
      oldDelegate.categorias != categorias ||
      oldDelegate.nombre != nombre;
}

class _AccionCircular extends StatelessWidget {
  const _AccionCircular({
    required this.tooltip,
    required this.icono,
    required this.alPresionar,
  });

  final String tooltip;
  final IconData icono;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: alPresionar,
    style: IconButton.styleFrom(
      foregroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF202220),
    ),
    icon: Icon(icono, size: 27, weight: 700),
  );
}
