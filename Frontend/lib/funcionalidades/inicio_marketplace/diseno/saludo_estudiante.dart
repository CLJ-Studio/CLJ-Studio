import 'package:flutter/material.dart';

import '../../../elementos_compartidos/marca/marca_u_market.dart';

/// Marca compacta que encabeza la pantalla principal.
class SaludoEstudiante extends StatelessWidget {
  const SaludoEstudiante({required this.nombre, super.key});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFFE6E1D5)
        : Color(0xFF474646);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarcaUMarket(
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorTexto,
            fontSize: 32,
            letterSpacing: -1,
          ),
        ),
        Text(
          '¿Que necesitas hoy en el campus?',
          style: TextStyle(color: colorTexto),
        ),
      ],
    );
  }
}
