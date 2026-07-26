import 'dart:ui';

import 'package:flutter/material.dart';

import '../modelos/categoria_marketplace.dart';
import 'barra_busqueda_marketplace.dart';
import 'barra_categorias_marketplace.dart';
import 'boton_carrito_compras.dart';
import 'saludo_estudiante.dart';

/// Cabecera reutilizable que permanece visible y se compacta con el scroll.
class CampusCollapsingHeader extends StatelessWidget {
  const CampusCollapsingHeader({
    required this.nombre,
    required this.categorias,
    required this.categoriaId,
    required this.alBuscar,
    required this.alSeleccionarCategoria,
    required this.alAbrirCarrito,
    super.key,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;

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
    ),
  );
}

/// Convierte `shrinkOffset` en posiciones y tamaños coordinados.
class CampusHeaderDelegate extends SliverPersistentHeaderDelegate {
  CampusHeaderDelegate({
    required this.nombre,
    required this.categorias,
    required this.categoriaId,
    required this.alBuscar,
    required this.alSeleccionarCategoria,
    required this.alAbrirCarrito,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;

  @override
  double get maxExtent => 230;

  @override
  double get minExtent => 112;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final saludoOpacity = (1 - progress * 1.35).clamp(0.0, 1.0);
    final fondo = Color.lerp(
      Theme.of(context).scaffoldBackgroundColor,
      Colors.white.withValues(alpha: .98),
      progress,
    );

    return ColoredBox(
      color: fondo!,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.lerp(
                Colors.transparent,
                const Color(0xFFE9ECE8),
                progress,
              )!,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // El saludo sube y se desvanece sin capturar interacciones.
                  Positioned(
                    left: 0,
                    top: lerpDouble(20, -12, progress)!,
                    child: IgnorePointer(
                      ignoring: saludoOpacity == 0,
                      child: Opacity(
                        opacity: saludoOpacity,
                        child: SaludoEstudiante(nombre: nombre),
                      ),
                    ),
                  ),
                  // El carrito permanece en el extremo derecho en ambos estados.
                  Positioned(
                    right: 0,
                    top: lerpDouble(20, 5, progress)!,
                    child: Transform.scale(
                      scale: lerpDouble(1, .92, progress)!,
                      alignment: Alignment.topRight,
                      child: BotonCarritoCompras(alPresionar: alAbrirCarrito),
                    ),
                  ),
                  // El buscador sube y deja espacio al carrito al compactarse.
                  Positioned(
                    left: 0,
                    right: lerpDouble(0, 58, progress)!,
                    top: lerpDouble(88, 3, progress)!,
                    child: BarraBusquedaMarketplace(
                      alCambiar: alBuscar,
                      compactProgress: progress,
                    ),
                  ),
                  // Las categorías nunca desaparecen y conservan su scroll.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: lerpDouble(160, 59, progress)!,
                    child: BarraCategoriasMarketplace(
                      categorias: categorias,
                      categoriaId: categoriaId,
                      alSeleccionar: alSeleccionarCategoria,
                      compactProgress: progress,
                    ),
                  ),
                ],
              ),
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
