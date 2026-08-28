import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/estado_vacio.dart';
import '../modelos/local_universitario.dart';
import 'tarjeta_local_universitario.dart';

/// Alterna entre lista y cuadrícula según el ancho disponible.
class ListaLocalesUniversitarios extends StatelessWidget {
  const ListaLocalesUniversitarios({
    required this.locales,
    required this.construirDetalle,
    super.key,
  });
  final List<LocalUniversitario> locales;
  final Widget Function(BuildContext, LocalUniversitario) construirDetalle;

  @override
  Widget build(BuildContext context) {
    if (locales.isEmpty) {
      return const EstadoVacio(
        mensaje: 'No encontramos locales con esos filtros.',
      );
    }
    return LayoutBuilder(
      builder: (_, restricciones) {
        final columnas = restricciones.maxWidth >= 980 ? 2 : 1;
        final anchoTarjeta =
            (restricciones.maxWidth - 18 * (columnas - 1)) / columnas;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: anchoTarjeta * 3 / 4 + 76,
          ),
          itemCount: locales.length,
          itemBuilder: (_, indice) {
            final local = locales[indice];
            return OpenContainer<void>(
              transitionDuration: const Duration(milliseconds: 580),
              transitionType: ContainerTransitionType.fade,
              closedElevation: 0,
              openElevation: 0,
              closedColor: Colors.transparent,
              openColor: Theme.of(context).scaffoldBackgroundColor,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              openShape: const RoundedRectangleBorder(),
              closedBuilder: (_, abrir) =>
                  TarjetaLocalUniversitario(local: local, alAbrir: abrir),
              openBuilder: (context, _) => construirDetalle(context, local),
            );
          },
        );
      },
    );
  }
}
