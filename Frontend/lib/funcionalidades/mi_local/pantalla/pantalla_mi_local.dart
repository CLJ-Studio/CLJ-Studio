import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../visualizaciones/indicador_vistas.dart';
import '../diseno/dialogo_producto.dart';
import '../logica/controlador_mi_local.dart';

/// Panel para administrar el inventario del local.
class PantallaMiLocal extends StatelessWidget {
  const PantallaMiLocal({required this.controlador, super.key});

  final ControladorMiLocal controlador;

  Future<void> _agregar(BuildContext context) async {
    final datos = await mostrarDialogoProducto(context);
    if (datos == null) return;

    await controlador.agregarProducto(
      nombre: datos.nombre,
      precio: datos.precio,
      cantidad: datos.cantidad,
      emoji: datos.emoji,
      descripcion: datos.descripcion,
      galeria: datos.galeria,
    );
  }

  Future<void> _editar(
    BuildContext context,
    ProductoMarketplace producto,
  ) async {
    final datos = await mostrarDialogoProducto(context, producto: producto);
    if (datos == null) return;

    await controlador.editarProducto(
      productoId: producto.id,
      nombre: datos.nombre,
      precio: datos.precio,
      cantidad: datos.cantidad,
      emoji: datos.emoji,
      descripcion: datos.descripcion,
      galeria: datos.galeria,
    );
  }

  Future<void> _confirmarBorrado(BuildContext context, int indice) async {
    final producto = controlador.productos[indice];
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text(
          'Se eliminará "${producto.nombre}" para siempre. '
          'Si solo quieres dejar de mostrarla, usa "Ocultar".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3453B),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true) await controlador.eliminarProducto(indice);
  }

  /// Cerrar el local no borra su fila: `orders.store_id` es `on delete
  /// restrict` para que el historial del comprador no desaparezca porque el
  /// vendedor cierre. Sale del catalogo y sus pedidos vivos se cancelan.
  Future<void> _confirmarCierre(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cerrar el local'),
        content: const Text(
          'Tu local sale del catálogo y sus publicaciones dejan de verse. '
          'Los pedidos que estén esperando respuesta se cancelan y se avisa '
          'a quienes los hicieron.\n\n'
          'Lo que ya entregaste se conserva en tu historial y en el de tus '
          'compradores. Lo que publiques por tu cuenta no se toca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3453B),
            ),
            child: const Text('Cerrar el local'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await controlador.cerrarLocal();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tu local se cerró.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cerrar el local.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
      child: ContenidoCentrado(
        anchoMaximo: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Encabezado(
              controlador: controlador,
              alCerrar: () => _confirmarCierre(context),
            ),
            const SizedBox(height: 34),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mi inventario',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _agregar(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5C8A63),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Producto'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (controlador.productos.isEmpty)
              const _InventarioVacio()
            else
              ...List.generate(
                controlador.productos.length,
                (indice) => _FilaProducto(
                  producto: controlador.productos[indice],
                  alSumar: () => controlador.cambiarCantidad(indice, 1),
                  alRestar: () => controlador.cambiarCantidad(indice, -1),
                  alEditar: () =>
                      _editar(context, controlador.productos[indice]),
                  alAlternarVisibilidad: () =>
                      controlador.cambiarVisibilidad(indice),
                  alRelanzar: () => controlador.relanzarProducto(indice),
                  alEliminar: () => _confirmarBorrado(context, indice),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.controlador, required this.alCerrar});

  final ControladorMiLocal controlador;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: oscuro
                ? Colors.white.withValues(alpha: .12)
                : Colors.black.withValues(alpha: .1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: oscuro ? const Color(0xFF252825) : const Color(0xFFF1F2F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: switch (controlador.local?.logoUrl) {
              final String url => Image.network(
                url,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  controlador.logo,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              _ => Text(controlador.logo, style: const TextStyle(fontSize: 30)),
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi local',
                  style: TextStyle(
                    color: oscuro
                        ? Colors.white.withValues(alpha: .62)
                        : const Color(0xFF777A77),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controlador.nombre ?? 'Tu local',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                if ((controlador.descripcion ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    controlador.descripcion!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF797D79),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                IndicadorVistas(
                  total: controlador.local?.vistas ?? 0,
                  compacto: true,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones del local',
            icon: const Icon(Icons.more_horiz_rounded),
            color: oscuro ? const Color(0xFF202320) : const Color(0xFFF9FAF8),
            elevation: 18,
            surfaceTintColor: Colors.transparent,
            menuPadding: const EdgeInsets.all(8),
            offset: const Offset(-12, 8),
            constraints: const BoxConstraints.tightFor(width: 240),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onSelected: (opcion) {
              if (opcion == 'cerrar') alCerrar();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'cerrar',
                height: 60,
                padding: EdgeInsets.zero,
                child: _AccionMenuInventario(
                  icono: Icons.storefront_outlined,
                  titulo: 'Cerrar el local',
                  descripcion: 'Retíralo del catálogo',
                  destructiva: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({
    required this.producto,
    required this.alSumar,
    required this.alRestar,
    required this.alEditar,
    required this.alAlternarVisibilidad,
    required this.alRelanzar,
    required this.alEliminar,
  });

  final ProductoMarketplace producto;
  final VoidCallback alSumar;
  final VoidCallback alRestar;
  final VoidCallback alEditar;
  final VoidCallback alAlternarVisibilidad;
  final VoidCallback alRelanzar;
  final VoidCallback alEliminar;

  Widget _menu(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Más opciones',
    icon: const Icon(Icons.close_rounded, size: 22),
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF202320)
        : const Color(0xFFF9FAF8),
    elevation: 18,
    shadowColor: Colors.black.withValues(alpha: .24),
    surfaceTintColor: Colors.transparent,
    menuPadding: const EdgeInsets.all(8),
    offset: const Offset(-12, 8),
    constraints: const BoxConstraints.tightFor(width: 252),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
      side: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: .1)
            : Colors.black.withValues(alpha: .07),
      ),
    ),
    popUpAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 300),
      reverseDuration: Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    onSelected: (opcion) => switch (opcion) {
      'editar' => alEditar(),
      'visibilidad' => alAlternarVisibilidad(),
      'relanzar' => alRelanzar(),
      _ => alEliminar(),
    },
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'editar',
        height: 60,
        padding: EdgeInsets.zero,
        child: _AccionMenuInventario(
          icono: Icons.edit_rounded,
          titulo: 'Editar',
          descripcion: 'Cambia sus detalles',
        ),
      ),
      PopupMenuItem(
        value: 'visibilidad',
        height: 60,
        padding: EdgeInsets.zero,
        child: _AccionMenuInventario(
          icono: producto.disponible
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          titulo: producto.disponible ? 'Ocultar' : 'Mostrar',
          descripcion: producto.disponible
              ? 'Deja de mostrarla'
              : 'Vuelve a publicarla',
        ),
      ),
      const PopupMenuItem(
        value: 'relanzar',
        height: 60,
        padding: EdgeInsets.zero,
        child: _AccionMenuInventario(
          icono: Icons.north_east_rounded,
          titulo: 'Relanzar',
          descripcion: 'Súbela al inicio',
        ),
      ),
      const PopupMenuDivider(height: 9),
      const PopupMenuItem(
        value: 'eliminar',
        height: 60,
        padding: EdgeInsets.zero,
        child: _AccionMenuInventario(
          icono: Icons.delete_outline_rounded,
          titulo: 'Eliminar',
          descripcion: 'No se puede deshacer',
          destructiva: true,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      opacity: producto.disponible ? 1 : .5,
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final compacto = restricciones.maxWidth < 560;
          final ladoImagen = compacto ? 116.0 : 154.0;
          return Container(
            height: compacto ? 176 : 182,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: oscuro
                      ? Colors.white.withValues(alpha: .1)
                      : Colors.black.withValues(alpha: .09),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _Miniatura(producto: producto, lado: ladoImagen),
                ),
                SizedBox(width: compacto ? 14 : 22),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                producto.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: oscuro ? Colors.white : Colors.black,
                                  fontSize: compacto ? 17 : 20,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _menu(context),
                          ],
                        ),
                        if (producto.descripcion.isNotEmpty)
                          Text(
                            producto.descripcion,
                            maxLines: compacto ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF777A77),
                              fontSize: 13,
                            ),
                          ),
                        if (!producto.disponible)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'OCULTA',
                              style: TextStyle(
                                color: Color(0xFF5C8A63),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: IndicadorVistas(
                            total: producto.vistas,
                            compacto: true,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Bs ${producto.precio.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: oscuro ? Colors.white : Colors.black,
                                  fontSize: compacto ? 18 : 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _BotonCantidad(
                              icono: Icons.remove_rounded,
                              alPresionar: alRestar,
                            ),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${producto.stock}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _BotonCantidad(
                              icono: Icons.add_rounded,
                              alPresionar: alSumar,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  const _BotonCantidad({required this.icono, required this.alPresionar});

  final IconData icono;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: OutlinedButton(
      onPressed: alPresionar,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .35)
              : Colors.black.withValues(alpha: .28),
        ),
        shape: const RoundedRectangleBorder(),
      ),
      child: Icon(icono, size: 22),
    ),
  );
}

class _AccionMenuInventario extends StatefulWidget {
  const _AccionMenuInventario({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.destructiva = false,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool destructiva;

  @override
  State<_AccionMenuInventario> createState() => _AccionMenuInventarioState();
}

class _AccionMenuInventarioState extends State<_AccionMenuInventario> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final acento = widget.destructiva
        ? const Color(0xFFD9584F)
        : const Color(0xFF5C8A63);

    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _encima ? 1.015 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          transform: Matrix4.translationValues(_encima ? 3 : 0, 0, 0),
          decoration: BoxDecoration(
            color: _encima
                ? acento.withValues(alpha: oscuro ? .2 : .11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: acento.withValues(alpha: _encima ? .2 : .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.icono, size: 20, color: acento),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titulo,
                      style: TextStyle(
                        color: widget.destructiva
                            ? acento
                            : oscuro
                            ? Colors.white
                            : const Color(0xFF242724),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.descripcion,
                      style: TextStyle(
                        color: oscuro
                            ? Colors.white.withValues(alpha: .6)
                            : const Color(0xFF777C78),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _encima ? 1 : 0,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: acento,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.producto, required this.lado});

  final ProductoMarketplace producto;
  final double lado;

  @override
  Widget build(BuildContext context) => Container(
    width: lado,
    height: lado,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF242624)
          : const Color(0xFFF2F2F2),
    ),
    child: switch (producto.imagenUrl) {
      final String url => Image.network(
        url,
        width: lado,
        height: lado,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Text(producto.emoji, style: TextStyle(fontSize: lado * .34)),
        ),
      ),
      _ => Center(
        child: Text(producto.emoji, style: TextStyle(fontSize: lado * .34)),
      ),
    },
  );
}

class _InventarioVacio extends StatelessWidget {
  const _InventarioVacio();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 54),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(26),
    ),
    child: const Column(
      children: [
        Icon(Icons.inventory_2_outlined, size: 44, color: Color(0xFF8B928D)),
        SizedBox(height: 12),
        Text('Todavía no agregaste productos.'),
      ],
    ),
  );
}
