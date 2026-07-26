import 'package:flutter/material.dart';

/// Categoría que se enviará como identificador al backend.
class SelectorCategoriaPublicacion extends StatelessWidget {
  const SelectorCategoriaPublicacion({
    required this.valor,
    required this.alCambiar,
    super.key,
  });
  final String valor;
  final ValueChanged<String> alCambiar;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: valor,
    decoration: const InputDecoration(labelText: 'Categoria'),
    items: const [
      'Tecnologia',
      'Servicios',
    ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
    onChanged: (nuevo) {
      if (nuevo != null) alCambiar(nuevo);
    },
  );
}
