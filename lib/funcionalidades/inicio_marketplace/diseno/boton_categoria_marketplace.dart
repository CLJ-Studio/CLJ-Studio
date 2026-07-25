import 'package:flutter/material.dart';

import '../modelos/categoria_marketplace.dart';
import 'animated_category_chip.dart';

/// Botón que hace evidente la categoría actualmente seleccionada.
class BotonCategoriaMarketplace extends StatelessWidget {
  const BotonCategoriaMarketplace({
    required this.categoria,
    required this.seleccionado,
    required this.alPresionar,
    super.key,
  });
  final CategoriaMarketplace categoria;
  final bool seleccionado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => AnimatedCategoryChip(
    label: categoria.nombre,
    icon: categoria.icono,
    isSelected: seleccionado,
    onTap: alPresionar,
    selectedBackgroundColor: const Color(0xFFDDECDD),
    unselectedBackgroundColor: const Color(0xFFF2F2F2),
    selectedForegroundColor: const Color(0xFF55785A),
    unselectedForegroundColor: const Color(0xFF4A4B4D),
  );
}
