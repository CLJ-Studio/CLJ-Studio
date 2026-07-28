import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
      child: ContenidoCentrado(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Encabezado(controlador: controlador),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inventario',
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
            const SizedBox(height: 16),
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
  const _Encabezado({required this.controlador});

  final ControladorMiLocal controlador;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        Container(
          width: 78,
          height: 78,
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: switch (controlador.local?.logoUrl) {
            final String url => Image.network(
              url,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Text(
                controlador.logo,
                style: const TextStyle(fontSize: 38),
              ),
            ),
            _ => Text(
              controlador.logo,
              style: const TextStyle(fontSize: 38),
            ),
          },
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controlador.nombre ?? 'Tu local',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                controlador.descripcion ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF69716B)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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

  @override
  Widget build(BuildContext context) => Opacity(
    // Lo oculto se ve atenuado: sigue ahi, pero nadie mas lo ve.
    opacity: producto.disponible ? 1 : .55,
    child: Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _Miniatura(producto: producto),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          producto.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (!producto.disponible) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Oculta',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7C827E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text('Bs ${producto.precio.toStringAsFixed(2)}'),
                ],
              ),
            ),
            IconButton(
              onPressed: alRestar,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${producto.stock}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              onPressed: alSumar,
              icon: const Icon(Icons.add_circle_rounded),
              color: const Color(0xFF5C8A63),
            ),
            // Las acciones menos frecuentes van en un menu para no llenar
            // la fila de botones.
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              onSelected: (opcion) => switch (opcion) {
                'editar' => alEditar(),
                'visibilidad' => alAlternarVisibilidad(),
                'relanzar' => alRelanzar(),
                _ => alEliminar(),
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'visibilidad',
                  child: ListTile(
                    leading: Icon(
                      producto.disponible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    title: Text(producto.disponible ? 'Ocultar' : 'Mostrar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'relanzar',
                  child: ListTile(
                    leading: Icon(Icons.trending_up_rounded),
                    title: Text('Relanzar'),
                    subtitle: Text(
                      'La sube al inicio',
                      style: TextStyle(fontSize: 11),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFB3453B),
                    ),
                    title: Text(
                      'Eliminar',
                      style: TextStyle(color: Color(0xFFB3453B)),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.producto});

  final ProductoMarketplace producto;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      shape: BoxShape.circle,
    ),
    child: switch (producto.imagenUrl) {
      final String url => Image.network(
        url,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Text(producto.emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
      _ => Center(
        child: Text(producto.emoji, style: const TextStyle(fontSize: 20)),
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
