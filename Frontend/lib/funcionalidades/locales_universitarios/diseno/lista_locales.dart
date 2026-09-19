import 'package:flutter/material.dart';
import '../../inicio_marketplace/diseno/lista_locales_universitarios.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Reutiliza el comportamiento responsivo de la cuadrícula del inicio.
class ListaLocales extends StatelessWidget {
  const ListaLocales({
    required this.locales,
    required this.construirDetalle,
    this.tarjetaInicial,
    super.key,
  });
  final List<LocalUniversitario> locales;
  final Widget Function(BuildContext, LocalUniversitario) construirDetalle;
  final Widget? tarjetaInicial;

  @override
  Widget build(BuildContext context) => ListaLocalesUniversitarios(
    locales: locales,
    construirDetalle: construirDetalle,
    tarjetaInicial: tarjetaInicial,
  );
}
