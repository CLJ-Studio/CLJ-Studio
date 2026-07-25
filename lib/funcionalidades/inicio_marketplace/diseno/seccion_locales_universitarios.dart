import 'package:flutter/material.dart';

import '../modelos/local_universitario.dart';
import 'lista_locales_universitarios.dart';

/// Sección titulada que agrupa el catálogo filtrado.
class SeccionLocalesUniversitarios extends StatelessWidget {
  const SeccionLocalesUniversitarios({
    required this.locales,
    required this.construirDetalle,
    super.key,
  });
  final List<LocalUniversitario> locales;
  final Widget Function(BuildContext, LocalUniversitario) construirDetalle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Locales universitarios',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 14),
      ListaLocalesUniversitarios(
        locales: locales,
        construirDetalle: construirDetalle,
      ),
    ],
  );
}
