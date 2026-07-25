import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../logica/controlador_mi_local.dart';

/// Panel básico para administrar el inventario del local creado.
class PantallaMiLocal extends StatelessWidget {
  const PantallaMiLocal({required this.controlador, super.key});

  final ControladorMiLocal controlador;

  Future<void> _mostrarFormulario(BuildContext context) async {
    final nombre = TextEditingController();
    final precio = TextEditingController();
    final cantidad = TextEditingController(text: '1');
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar producto'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombre,
                decoration: const InputDecoration(labelText: 'Producto'),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (resultado == true &&
        nombre.text.trim().isNotEmpty &&
        double.tryParse(precio.text.replaceAll(',', '.')) != null) {
      controlador.agregarProducto(
        nombre: nombre.text,
        precio: double.parse(precio.text.replaceAll(',', '.')),
        cantidad: int.tryParse(cantidad.text) ?? 0,
      );
    }
    nombre.dispose();
    precio.dispose();
    cantidad.dispose();
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3E9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      controlador.logo,
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controlador.nombre ?? 'Tu local',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
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
            ),
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
                  onPressed: () => _mostrarFormulario(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Producto'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controlador.productos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 54),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F5),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 44,
                      color: Color(0xFF8B928D),
                    ),
                    SizedBox(height: 12),
                    Text('Todavía no agregaste productos.'),
                  ],
                ),
              )
            else
              ...List.generate(controlador.productos.length, (indice) {
                final producto = controlador.productos[indice];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE7F2E8),
                          foregroundColor: Color(0xFF5C8A63),
                          child: Icon(Icons.fastfood_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text('Bs ${producto.precio.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              controlador.cambiarCantidad(indice, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${producto.cantidad}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        IconButton(
                          onPressed: () =>
                              controlador.cambiarCantidad(indice, 1),
                          icon: const Icon(Icons.add_circle_rounded),
                          color: const Color(0xFF5C8A63),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => controlador.eliminarProducto(indice),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    ),
  );
}
