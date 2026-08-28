import 'package:flutter/material.dart';

import '../../../elementos_compartidos/campos_aplicacion/campo_busqueda.dart';

/// Especializa el buscador compartido para el marketplace.
class BarraBusquedaMarketplace extends StatelessWidget {
  const BarraBusquedaMarketplace({
    required this.alCambiar,
    this.compactProgress = 0,
    super.key,
  });
  final ValueChanged<String> alCambiar;
  final double compactProgress;

  @override
  Widget build(BuildContext context) => CampoBusqueda(
    alCambiar: alCambiar,
    texto: 'Buscar locales, productos o personas',
    compactProgress: compactProgress,
  );
}
