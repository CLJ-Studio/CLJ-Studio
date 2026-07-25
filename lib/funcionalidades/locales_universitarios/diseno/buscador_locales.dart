import 'package:flutter/material.dart';
import '../../../elementos_compartidos/campos_aplicacion/campo_busqueda.dart';

/// Buscador específico de locales.
class BuscadorLocales extends StatelessWidget {
  const BuscadorLocales({required this.alCambiar, super.key});
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) =>
      CampoBusqueda(alCambiar: alCambiar, texto: 'Buscar un local');
}
