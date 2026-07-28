import 'package:flutter/material.dart';

import '../modelos/categoria_marketplace.dart';
import 'animated_category_chip.dart';

/// Botón que hace evidente la categoría actualmente seleccionada.
class BotonCategoriaMarketplace extends StatelessWidget {
  const BotonCategoriaMarketplace({
    required this.categoria,
    required this.seleccionado,
    required this.alPresionar,
    this.compactProgress = 0,
    super.key,
  });
  final CategoriaMarketplace categoria;
  final bool seleccionado;
  final VoidCallback alPresionar;
  final double compactProgress;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    // Los colores se calculan aqui y se le pasan al chip de Lucas tal cual:
    // su animacion queda intacta y aun asi responde al tema.
    return AnimatedCategoryChip(
      label: categoria.nombre,
      icon: categoria.icono,
      isSelected: seleccionado,
      onTap: alPresionar,
      selectedBackgroundColor: esOscuro
          ? const Color(0xFF2E4636)
          : const Color(0xFFDDECDD),
      unselectedBackgroundColor: esOscuro
          ? tema.colorScheme.surfaceContainerHighest
          : const Color(0xFFF2F2F2),
      selectedForegroundColor: esOscuro
          ? const Color(0xFFAFD6B6)
          : Colors.black,
      unselectedForegroundColor: esOscuro ? Colors.white : Colors.black,
      compactProgress: compactProgress,
    );
  }
}
