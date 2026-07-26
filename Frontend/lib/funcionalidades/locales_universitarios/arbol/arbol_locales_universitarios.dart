import 'package:flutter/material.dart';
import '../pantalla/pantalla_locales_universitarios.dart';

/// Ensambla el catálogo de locales.
class ArbolLocalesUniversitarios extends StatelessWidget {
  const ArbolLocalesUniversitarios({
    required this.alCrearLocal,
    required this.yaTieneLocal,
    super.key,
  });

  final VoidCallback alCrearLocal;
  final bool yaTieneLocal;

  @override
  Widget build(BuildContext context) => PantallaLocalesUniversitarios(
    alCrearLocal: alCrearLocal,
    yaTieneLocal: yaTieneLocal,
  );
}
