import 'package:flutter/material.dart';

/// Selector segmentado del tipo de publicación.
class SelectorTipoPublicacion extends StatelessWidget {
  const SelectorTipoPublicacion({
    required this.valor,
    required this.alCambiar,
    super.key,
  });
  final String valor;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
    segments: const [
      ButtonSegment(
        value: 'Producto',
        label: Text('Producto'),
        icon: Icon(Icons.inventory_2_outlined),
      ),
      ButtonSegment(
        value: 'Servicio',
        label: Text('Servicio'),
        icon: Icon(Icons.handyman_outlined),
      ),
    ],
    selected: {valor},
    onSelectionChanged: (seleccion) => alCambiar(seleccion.first),
  );
}
