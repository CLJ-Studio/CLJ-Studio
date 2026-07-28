import 'package:flutter/material.dart';

import '../../notificaciones/diseno/boton_campana.dart';
import '../modelos/categoria_marketplace.dart';
import 'barra_busqueda_marketplace.dart';
import 'barra_categorias_marketplace.dart';
import 'boton_carrito_compras.dart';

final _ubicacionSeleccionada = ValueNotifier<String>('Elige tu ubicación');

const _ubicacionesCampus = [
  'Jatata',
  'Pascana',
  'Mozza',
  'Cafetería',
  'Bloque A',
  'Bloque B',
  'Ingeniería',
];

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
    this.avatarUrl,
    super.key,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;
  final String? avatarUrl;

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
      avatarUrl: avatarUrl,
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
    this.avatarUrl,
    super.key,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 264,
    child: CampusHeaderDelegate(
      nombre: nombre,
      categorias: categorias,
      categoriaId: categoriaId,
      alBuscar: alBuscar,
      alSeleccionarCategoria: alSeleccionarCategoria,
      alAbrirCarrito: alAbrirCarrito,
      alAbrirPedidos: alAbrirPedidos,
      avatarUrl: avatarUrl,
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
    this.avatarUrl,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;
  final String? avatarUrl;

  Future<void> _elegirUbicacion(BuildContext context) async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 14),
          children: [
            const ListTile(
              title: Text(
                'Elige una ubicación',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            for (final ubicacion in _ubicacionesCampus)
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF5C8A63),
                ),
                title: Text(ubicacion),
                trailing: _ubicacionSeleccionada.value == ubicacion
                    ? const Icon(Icons.check_rounded, color: Color(0xFF5C8A63))
                    : null,
                onTap: () => Navigator.of(context).pop(ubicacion),
              ),
          ],
        ),
      ),
    );
    if (elegida != null) _ubicacionSeleccionada.value = elegida;
  }

  Future<void> _mostrarTodasCategorias(BuildContext context) async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 14),
          children: [
            const ListTile(
              title: Text(
                'Todas las categorías',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            for (final categoria in categorias)
              ListTile(
                leading: Icon(categoria.icono, color: const Color(0xFF5C8A63)),
                title: Text(categoria.nombre),
                trailing: categoria.id == categoriaId
                    ? const Icon(Icons.check_rounded, color: Color(0xFF5C8A63))
                    : null,
                onTap: () => Navigator.of(context).pop(categoria.id),
              ),
          ],
        ),
      ),
    );
    if (elegida != null) alSeleccionarCategoria(elegida);
  }

  @override
  double get maxExtent => 264;

  @override
  double get minExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progreso = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final opacidadSecundaria = (1 - progreso * 1.8).clamp(0.0, 1.0);
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = oscuro ? Theme.of(context).colorScheme.surface : Colors.white;
    final texto = oscuro ? Colors.white : const Color(0xFF202220);
    final secundario = oscuro
        ? Colors.white.withValues(alpha: .62)
        : const Color(0xFF8A8E8A);

    return ColoredBox(
      color: fondo,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: maxExtent,
          maxHeight: maxExtent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                  minHeight: 264,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 68,
                      child: Transform.scale(
                        scale: 1 - progreso * .1,
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            _AvatarEncabezado(
                              nombre: nombre,
                              avatarUrl: avatarUrl,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: ValueListenableBuilder<String>(
                                valueListenable: _ubicacionSeleccionada,
                                builder: (context, ubicacion, _) => InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _elegirUbicacion(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                ubicacion,
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
                                ),
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
                    ),
                    IgnorePointer(
                      ignoring: opacidadSecundaria < .15,
                      child: Opacity(
                        opacity: opacidadSecundaria,
                        child: BarraBusquedaMarketplace(alCambiar: alBuscar),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Opacity(
                      opacity: opacidadSecundaria,
                      child: SizedBox(
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
                              onPressed: () => _mostrarTodasCategorias(context),
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
                    ),
                    Expanded(
                      child: IgnorePointer(
                        ignoring: opacidadSecundaria < .15,
                        child: Opacity(
                          opacity: opacidadSecundaria,
                          child: BarraCategoriasMarketplace(
                            categorias: categorias,
                            categoriaId: categoriaId,
                            alSeleccionar: alSeleccionarCategoria,
                            compactProgress: progreso,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      oldDelegate.nombre != nombre ||
      oldDelegate.avatarUrl != avatarUrl;
}

class _AvatarEncabezado extends StatelessWidget {
  const _AvatarEncabezado({required this.nombre, this.avatarUrl});

  final String nombre;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) => Container(
    width: 43,
    height: 43,
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFF5C8A63),
      shape: BoxShape.circle,
    ),
    child: avatarUrl == null || avatarUrl!.isEmpty
        ? _InicialAvatar(nombre: nombre)
        : Image.network(
            avatarUrl!,
            width: 43,
            height: 43,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _InicialAvatar(nombre: nombre),
          ),
  );
}

class _InicialAvatar extends StatelessWidget {
  const _InicialAvatar({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) => Text(
    nombre.isEmpty ? 'U' : nombre[0].toUpperCase(),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w900,
    ),
  );
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
