import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/selector_galeria.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../publicar_producto/diseno/selector_emoji_publicacion.dart';

/// Datos con los que se crea o edita un producto del inventario.
class DatosProducto {
  const DatosProducto({
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.emoji,
    required this.galeria,
  });

  final String nombre;
  final String descripcion;
  final double precio;
  final int cantidad;
  final String emoji;
  final List<String> galeria;
}

/// Formulario de producto reutilizado para agregar y para editar: son el
/// mismo conjunto de campos y mantenerlos separados los desincronizaria.
Future<DatosProducto?> mostrarDialogoProducto(
  BuildContext context, {
  ProductoMarketplace? producto,
}) {
  final esEdicion = producto != null;
  final nombre = TextEditingController(text: producto?.nombre ?? '');
  final descripcion = TextEditingController(text: producto?.descripcion ?? '');
  final precio = TextEditingController(
    text: producto == null ? '' : producto.precio.toStringAsFixed(2),
  );
  final cantidad = TextEditingController(
    text: (producto?.stock ?? 1).toString(),
  );
  var emoji = producto?.emoji ?? '🛍️';
  var galeria = <String>[
    if (producto?.imagePath != null) producto!.imagePath!,
    ...?producto?.imagenes,
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
                const SizedBox(height: 20),
                SelectorGaleria(
                  rutas: galeria,
                  alCambiar: (rutas) => actualizar(() => galeria = rutas),
                ),
                const SizedBox(height: 18),
                SelectorEmojiPublicacion(
                  valor: emoji,
                  alCambiar: (valor) => actualizar(() => emoji = valor),
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
              if (nombre.text.trim().isEmpty || monto == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completa el nombre y un precio válido.'),
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
