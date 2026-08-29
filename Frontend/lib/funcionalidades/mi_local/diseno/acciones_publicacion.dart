import 'package:flutter/material.dart';

import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../datos/repositorio_mi_local.dart';
import 'dialogo_ajustar_stock.dart';
import 'dialogo_producto.dart';

/// Qué se hizo con la publicación, para que quien llamó sepa si refrescar.
enum ResultadoAccion {
  sinCambios,
  editada,
  ocultada,
  relanzada,
  eliminada,
  stockAjustado,
}

/// Menú de gestión de una publicación propia.
///
/// Vive aparte porque se abre desde dos sitios: la ficha de la publicación y
/// el propio perfil. Tenerlo duplicado acabaría con una versión que sabe
/// borrar y otra que no.
///
/// Las acciones van por id y no por posición en una lista: el perfil mezcla
/// lo suelto con lo del local, así que no hay un índice común.
Future<ResultadoAccion> mostrarAccionesPublicacion(
  BuildContext context,
  ProductoMarketplace producto, {
  VoidCallback? alVer,
}) async {
  const repositorio = RepositorioMiLocal();

  final opcion = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (hoja) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              producto.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                hoja,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          if (alVer != null)
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver publicación'),
              onTap: () => Navigator.of(hoja).pop('ver'),
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar'),
            onTap: () => Navigator.of(hoja).pop('editar'),
          ),
          ListTile(
            leading: const Icon(Icons.tag_outlined),
            title: const Text('Ajustar unidades'),
            subtitle: Text('Quedan ${producto.stock}'),
            onTap: () => Navigator.of(hoja).pop('stock'),
          ),
          ListTile(
            leading: Icon(
              producto.disponible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            title: Text(producto.disponible ? 'Ocultar' : 'Mostrar'),
            subtitle: Text(
              producto.disponible
                  ? 'Se retira del catálogo pero no se borra'
                  : 'Vuelve a aparecer en el catálogo',
            ),
            onTap: () => Navigator.of(hoja).pop('ocultar'),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_upward_rounded),
            title: const Text('Volver a publicar'),
            subtitle: const Text('Vuelve al inicio del catálogo'),
            onTap: () => Navigator.of(hoja).pop('relanzar'),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFAE7960),
            ),
            title: const Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFFAE7960)),
            ),
            onTap: () => Navigator.of(hoja).pop('eliminar'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (opcion == null || !context.mounted) return ResultadoAccion.sinCambios;

  try {
    switch (opcion) {
      case 'ver':
        alVer?.call();
        return ResultadoAccion.sinCambios;

      case 'editar':
        final datos = await mostrarDialogoProducto(context, producto: producto);
        if (datos == null) return ResultadoAccion.sinCambios;
        await repositorio.editarProducto(
          productoId: producto.id,
          nombre: datos.nombre,
          precio: datos.precio,
          stock: datos.cantidad,
          emoji: datos.emoji,
          descripcion: datos.descripcion,
          galeria: datos.galeria,
        );
        return ResultadoAccion.editada;

      case 'stock':
        final cambiado = await mostrarDialogoAjustarStock(context, producto);
        return cambiado
            ? ResultadoAccion.stockAjustado
            : ResultadoAccion.sinCambios;

      case 'ocultar':
        await repositorio.cambiarVisibilidad(
          producto.id,
          visible: !producto.disponible,
        );
        return ResultadoAccion.ocultada;

      case 'relanzar':
        await repositorio.relanzarProducto(producto.id);
        return ResultadoAccion.relanzada;

      default:
        if (!context.mounted) return ResultadoAccion.sinCambios;
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
                  backgroundColor: const Color(0xFFAE7960),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (confirmado != true) return ResultadoAccion.sinCambios;
        await repositorio.eliminarProducto(producto.id);
        return ResultadoAccion.eliminada;
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la acción.')),
      );
    }
    return ResultadoAccion.sinCambios;
  }
}
