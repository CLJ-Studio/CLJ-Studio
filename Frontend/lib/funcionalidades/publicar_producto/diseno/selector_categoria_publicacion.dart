import 'package:flutter/material.dart';

import '../../inicio_marketplace/modelos/categoria_marketplace.dart';

/// Categoría de lo que se publica.
///
/// Antes la categoría vivía solo en el local, así que el filtro del inicio
/// no encontraba nada de lo publicado a título personal: ese espacio se crea
/// por detrás y nace sin ninguna. Preguntarla aquí es lo que hace que la
/// barra de categorías sirva para algo.
class SelectorCategoriaPublicacion extends StatelessWidget {
  const SelectorCategoriaPublicacion({
    required this.categorias,
    required this.seleccionada,
    required this.alSeleccionar,
    super.key,
  });

  final List<CategoriaMarketplace> categorias;
  final String? seleccionada;
  final ValueChanged<String> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    // 'Todo' encabeza la barra del inicio pero no es una categoría real: no
    // se puede publicar algo "en todo".
    final elegibles = categorias
        .where((c) => c.id != CategoriaMarketplace.todas.id)
        .toList();

    if (elegibles.isEmpty) return const SizedBox.shrink();
    final tema = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final categoria in elegibles)
          ChoiceChip(
            selected: categoria.id == seleccionada,
            onSelected: (_) => alSeleccionar(categoria.id),
            avatar: Icon(
              categoria.icono,
              size: 17,
              color: categoria.id == seleccionada
                  ? tema.colorScheme.primary
                  : tema.textTheme.bodyMedium?.color,
            ),
            label: Text(categoria.nombre),
          ),
      ],
    );
  }
}
