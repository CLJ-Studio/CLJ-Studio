import 'dart:ui';

import 'package:flutter/material.dart';

import '../../notificaciones/diseno/boton_campana.dart';
import '../modelos/categoria_marketplace.dart';
import 'barra_busqueda_marketplace.dart';
import 'barra_categorias_marketplace.dart';
import 'boton_carrito_compras.dart';
import 'saludo_estudiante.dart';

/// Cabecera fija compartida por Inicio y Locales.
///
/// El catálogo se desplaza a partir de los filtros; el nombre, las acciones,
/// el buscador y las categorías permanecen siempre en su sitio.
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

/// Versión fija usada fuera del área que cambia horizontalmente.
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

/// Convierte `shrinkOffset` en posiciones y tamaños coordinados.
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
  double get maxExtent => 230;

  @override
  double get minExtent => 230;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    // La cabecera no se colapsa: solo el contenido situado debajo se mueve.
    const progress = 0.0;
    final saludoOpacity = (1 - progress * 1.35).clamp(0.0, 1.0);
    // Al compactarse se vuelve opaco para separarse del contenido. Fijo en
    // blanco, en oscuro aparecia una franja clara al bajar.
    final fondo = Color.lerp(
      tema.scaffoldBackgroundColor,
      tema.brightness == Brightness.dark
          ? tema.colorScheme.surface
          : Colors.white.withValues(alpha: .98),
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
                tema.dividerColor,
                progress,
              )!,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: ConstrainedBox(
              // En la versión fija el Center entrega restricciones flexibles.
              // La altura mínima evita que el Stack mida cero y recorte las
              // categorías, aunque todos sus hijos sean Positioned.
              constraints: const BoxConstraints(maxWidth: 1200, minHeight: 230),
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
                  // Pedidos y carrito quedan a la derecha en ambos estados.
                  Positioned(
                    right: 0,
                    top: lerpDouble(20, 5, progress)!,
                    child: Transform.scale(
                      scale: lerpDouble(1, .92, progress)!,
                      alignment: Alignment.topRight,
                      child: Row(
                        children: [
                          const BotonCampana(),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Mis pedidos',
                            onPressed: alAbrirPedidos,
                            style: IconButton.styleFrom(
                              backgroundColor: esOscuro
                                  ? const Color(0xFF405844)
                                  : const Color(0xFFDDECDD),
                              foregroundColor: esOscuro
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            icon: const Icon(Icons.receipt_long_outlined),
                          ),
                          const SizedBox(width: 8),
                          BotonCarritoCompras(alPresionar: alAbrirCarrito),
                        ],
                      ),
                    ),
                  ),
                  // El buscador sube y deja espacio a los botones al compactarse.
                  Positioned(
                    left: 0,
                    right: lerpDouble(0, 158, progress)!,
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
