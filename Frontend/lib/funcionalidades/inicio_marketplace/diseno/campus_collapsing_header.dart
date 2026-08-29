import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../notificaciones/diseno/boton_campana.dart';
import '../logica/ubicacion_comprador.dart';
import '../modelos/categoria_marketplace.dart';
import 'barra_busqueda_marketplace.dart';
import 'boton_carrito_compras.dart';

/// Cabecera compartida por Inicio y Locales.
///
/// Mantiene las acciones existentes, pero adopta la composición de una app de
/// marketplace: ubicación y accesos arriba, buscador blanco dentro de un
/// bloque de marca que se contrae al hacer scroll.
class CampusCollapsingHeader extends StatelessWidget {
  const CampusCollapsingHeader({
    required this.nombre,
    required this.categorias,
    required this.categoriaId,
    required this.alBuscar,
    required this.alSeleccionarCategoria,
    required this.alAbrirCarrito,
    required this.alAbrirPedidos,
    required this.alAbrirChats,
    this.avatarUrl,
    this.mostrarCategorias = true,
    this.mostrarUbicacion = false,
    super.key,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;
  final VoidCallback alAbrirChats;
  final String? avatarUrl;
  final bool mostrarCategorias;
  final bool mostrarUbicacion;

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
      alAbrirChats: alAbrirChats,
      avatarUrl: avatarUrl,
      mostrarCategorias: mostrarCategorias,
      mostrarUbicacion: mostrarUbicacion,
    ),
  );
}

/// Versión fija usada cuando una pantalla compone el encabezado por fuera del
/// scroll principal.
class CampusFixedHeader extends StatelessWidget {
  const CampusFixedHeader({
    required this.nombre,
    required this.categorias,
    required this.categoriaId,
    required this.alBuscar,
    required this.alSeleccionarCategoria,
    required this.alAbrirCarrito,
    required this.alAbrirPedidos,
    required this.alAbrirChats,
    this.avatarUrl,
    this.mostrarCategorias = true,
    this.mostrarUbicacion = false,
    super.key,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;
  final VoidCallback alAbrirChats;
  final String? avatarUrl;
  final bool mostrarCategorias;
  final bool mostrarUbicacion;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: mostrarCategorias ? 218 : 158,
    child: CampusHeaderDelegate(
      nombre: nombre,
      categorias: categorias,
      categoriaId: categoriaId,
      alBuscar: alBuscar,
      alSeleccionarCategoria: alSeleccionarCategoria,
      alAbrirCarrito: alAbrirCarrito,
      alAbrirPedidos: alAbrirPedidos,
      alAbrirChats: alAbrirChats,
      avatarUrl: avatarUrl,
      mostrarCategorias: mostrarCategorias,
      mostrarUbicacion: mostrarUbicacion,
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
    required this.alAbrirChats,
    this.avatarUrl,
    this.mostrarCategorias = true,
    this.mostrarUbicacion = false,
  });

  final String nombre;
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alBuscar;
  final ValueChanged<String> alSeleccionarCategoria;
  final VoidCallback alAbrirCarrito;
  final VoidCallback alAbrirPedidos;
  final VoidCallback alAbrirChats;
  final String? avatarUrl;
  final bool mostrarCategorias;
  final bool mostrarUbicacion;

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
                '¿Dónde quieres encontrarte?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              subtitle: Text('Elige una zona del campus UPSA.'),
            ),
            for (final ubicacion in UbicacionComprador.zonas)
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: ConfiguracionTema.primario,
                ),
                title: Text(ubicacion),
                trailing: UbicacionComprador.instancia.zona == ubicacion
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: ConfiguracionTema.primario,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(ubicacion),
              ),
          ],
        ),
      ),
    );
    if (elegida != null) await UbicacionComprador.instancia.elegir(elegida);
  }

  @override
  double get maxExtent => mostrarCategorias ? 218 : 158;

  @override
  double get minExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final recorrido = (maxExtent - minExtent).clamp(1, double.infinity);
    final progreso = (shrinkOffset / recorrido).clamp(0.0, 1.0);
    final opacidadBuscador = (1 - progreso * 1.75).clamp(0.0, 1.0);

    return Material(
      color: ConfiguracionTema.azulNoche,
      elevation: overlapsContent ? 6 : 0,
      shadowColor: const Color(0x33474646),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                SizedBox(
                  height: 66,
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: UbicacionComprador.instancia,
                          builder: (context, _) => InkWell(
                            onTap: () => _elegirUbicacion(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ENTREGA EN',
                                    style: TextStyle(
                                      color: Color(
                                        0xFFE6E1D5,
                                      ).withValues(alpha: .72),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .8,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          UbicacionComprador.instancia.elegida
                                              ? UbicacionComprador
                                                    .instancia
                                                    .etiqueta
                                              : 'Campus UPSA',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 21,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      BotonCarritoCompras(
                        alPresionar: alAbrirCarrito,
                        sobreFondoMarca: true,
                      ),
                      _AccionEncabezado(
                        tooltip: 'Mis pedidos',
                        icono: Icons.receipt_long_outlined,
                        alPresionar: alAbrirPedidos,
                      ),
                      _AccionEncabezado(
                        tooltip: 'Chats',
                        icono: Icons.forum_outlined,
                        alPresionar: alAbrirChats,
                      ),
                      const BotonCampana(sobreFondoMarca: true),
                      const SizedBox(width: 4),
                      _AvatarEncabezado(nombre: nombre, avatarUrl: avatarUrl),
                    ],
                  ),
                ),
                ClipRect(
                  child: Align(
                    heightFactor: opacidadBuscador,
                    child: IgnorePointer(
                      ignoring: opacidadBuscador < .1,
                      child: Opacity(
                        opacity: opacidadBuscador,
                        child: BarraBusquedaMarketplace(alCambiar: alBuscar),
                      ),
                    ),
                  ),
                ),
                if (mostrarCategorias)
                  ClipRect(
                    child: Align(
                      heightFactor: opacidadBuscador,
                      child: Opacity(
                        opacity: opacidadBuscador,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              const Text(
                                'Compra y vende dentro del campus',
                                style: TextStyle(
                                  color: Color(0xFFE6E1D5),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${categorias.length} categorías',
                                style: TextStyle(
                                  color: Color(
                                    0xFFE6E1D5,
                                  ).withValues(alpha: .76),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
      oldDelegate.nombre != nombre ||
      oldDelegate.avatarUrl != avatarUrl ||
      oldDelegate.mostrarCategorias != mostrarCategorias ||
      oldDelegate.mostrarUbicacion != mostrarUbicacion;
}

class _AccionEncabezado extends StatelessWidget {
  const _AccionEncabezado({
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
    style: IconButton.styleFrom(foregroundColor: Colors.white),
    icon: Icon(icono, size: 26, weight: 700),
  );
}

class _AvatarEncabezado extends StatelessWidget {
  const _AvatarEncabezado({required this.nombre, this.avatarUrl});

  final String nombre;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final inicial = nombre.trim().isEmpty
        ? null
        : nombre.trim()[0].toUpperCase();

    Widget respaldo() => ColoredBox(
      color: const Color(0xFFE6E1D5),
      child: Center(
        child: inicial == null
            ? const Icon(
                Icons.person_rounded,
                color: ConfiguracionTema.grafito,
                size: 23,
              )
            : Text(
                inicial,
                style: const TextStyle(
                  color: ConfiguracionTema.grafito,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );

    return Semantics(
      label: 'Foto de perfil',
      image: true,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(0xFFE6E1D5).withValues(alpha: .82),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: url == null || url.isEmpty
            ? respaldo()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => respaldo(),
              ),
      ),
    );
  }
}
