import 'package:flutter/material.dart';

import '../../../elementos_compartidos/campos_aplicacion/editor_variantes.dart';
import '../../../elementos_compartidos/imagenes/selector_galeria.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/categoria_marketplace.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../publicar_producto/diseno/selector_categoria_publicacion.dart';

/// Datos con los que se crea o edita un producto del inventario.
class DatosProducto {
  const DatosProducto({
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.emoji,
    required this.galeria,
    required this.variantes,
    required this.categoriaId,
  });

  final String nombre;
  final String descripcion;
  final double precio;
  final int cantidad;
  final String emoji;
  final List<String> galeria;

  /// Los sabores, por nombre. El repositorio se encarga de los ids.
  final List<String> variantes;
  final String categoriaId;
}

/// Formulario de producto reutilizado para agregar y para editar: son el
/// mismo conjunto de campos y mantenerlos separados los desincronizaria.
Future<DatosProducto?> mostrarDialogoProducto(
  BuildContext context, {
  ProductoMarketplace? producto,
}) async {
  late final List<CategoriaMarketplace> categorias;
  try {
    categorias = await const RepositorioInicioMarketplace().obtenerCategorias();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos cargar las categorías. Intenta de nuevo.'),
        ),
      );
    }
    return null;
  }
  if (!context.mounted) return null;

  final esEdicion = producto != null;
  final nombre = TextEditingController(text: producto?.nombre ?? '');
  final descripcion = TextEditingController(text: producto?.descripcion ?? '');
  final precio = TextEditingController(
    text: producto == null ? '' : producto.precio.toStringAsFixed(2),
  );
  final cantidad = TextEditingController(
    text: (producto?.stock ?? 1).toString(),
  );
  // `products.emoji` se conserva por compatibilidad con publicaciones
  // existentes, pero la clasificación y el icono visible dependen únicamente
  // de la categoría elegida. El usuario ya no tiene que elegir ambos.
  final emoji = producto?.emoji ?? '🛍️';
  String? categoriaId = producto?.categoriaId;
  var galeria = <String>[
    if (producto?.imagePath != null) producto!.imagePath!,
    ...?producto?.imagenes,
  ];
  var variantes = <String>[
    for (final variante in producto?.variantes ?? const []) variante.nombre,
  ];

  return showDialog<DatosProducto>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, actualizar) => AlertDialog(
        title: Text(esEdicion ? 'Editar producto' : 'Agregar producto'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombre,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Producto'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcion,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precio,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Precio en Bs'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidad,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad disponible',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Categoría obligatoria',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SelectorCategoriaPublicacion(
                  categorias: categorias,
                  seleccionada: categoriaId,
                  alSeleccionar: (valor) =>
                      actualizar(() => categoriaId = valor),
                ),
                const SizedBox(height: 20),
                SelectorGaleria(
                  rutas: galeria,
                  alCambiar: (rutas) => actualizar(() => galeria = rutas),
                ),
                const SizedBox(height: 20),
                EditorVariantes(
                  titulo: 'Sabores o tamaños',
                  variantes: variantes,
                  alCambiar: (nombres) =>
                      actualizar(() => variantes = nombres),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF474646),
            ),
            onPressed: () {
              final monto = double.tryParse(precio.text.replaceAll(',', '.'));
              if (nombre.text.trim().isEmpty ||
                  monto == null ||
                  categoriaId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Completa el nombre, un precio válido y la categoría.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                DatosProducto(
                  nombre: nombre.text,
                  descripcion: descripcion.text,
                  precio: monto,
                  cantidad: int.tryParse(cantidad.text) ?? 0,
                  emoji: emoji,
                  galeria: galeria,
                  variantes: variantes,
                  categoriaId: categoriaId!,
                ),
              );
            },
            child: Text(esEdicion ? 'Guardar' : 'Agregar'),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    nombre.dispose();
    descripcion.dispose();
    precio.dispose();
    cantidad.dispose();
  });
}
