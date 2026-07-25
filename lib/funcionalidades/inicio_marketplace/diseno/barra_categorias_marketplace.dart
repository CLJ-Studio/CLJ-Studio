import 'package:flutter/material.dart';

import '../modelos/categoria_marketplace.dart';
import 'boton_categoria_marketplace.dart';

/// Lista horizontal que nunca provoca desbordamiento en móvil.
class BarraCategoriasMarketplace extends StatelessWidget {
  const BarraCategoriasMarketplace({
    required this.categorias,
    required this.categoriaId,
    required this.alSeleccionar,
    super.key,
  });
  final List<CategoriaMarketplace> categorias;
  final String categoriaId;
  final ValueChanged<String> alSeleccionar;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categorias.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, indice) {
        final categoria = categorias[indice];
        return BotonCategoriaMarketplace(
          categoria: categoria,
          seleccionado: categoria.id == categoriaId,
          alPresionar: () => alSeleccionar(categoria.id),
        );
      },
    ),
  );
}
