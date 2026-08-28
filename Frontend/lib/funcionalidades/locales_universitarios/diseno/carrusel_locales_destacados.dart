import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Carrusel horizontal de locales destacados con fotografía dominante.
class CarruselLocalesDestacados extends StatelessWidget {
  const CarruselLocalesDestacados({
    required this.locales,
    required this.construirDetalle,
    super.key,
  });

  final List<LocalUniversitario> locales;
  final Widget Function(BuildContext, LocalUniversitario) construirDetalle;

  @override
  Widget build(BuildContext context) {
    final visibles =
        ([...locales]..sort((a, b) => b.vistas.compareTo(a.vistas)))
            .take(8)
            .toList(growable: false);

    if (visibles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 238,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: visibles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, indice) {
          final local = visibles[indice];
          return SizedBox(
            width: 224,
            child: OpenContainer<void>(
              transitionDuration: const Duration(milliseconds: 480),
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
                  _TarjetaDestacada(local: local, alAbrir: abrir),
              openBuilder: (context, _) => construirDetalle(context, local),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaDestacada extends StatelessWidget {
  const _TarjetaDestacada({required this.local, required this.alAbrir});

  final LocalUniversitario local;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alAbrir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 158,
            width: double.infinity,
            child: ColoredBox(
              color: Color(local.colorHexadecimal),
              child: switch (local.portadaUrl) {
                final String url when url.isNotEmpty => Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _Emoji(local: local),
                ),
                _ => _Emoji(local: local),
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          local.nombreVisible,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                        color: ConfiguracionTema.verdeMarca,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: ConfiguracionTema.verdeMarca,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          local.ubicacionCampus ?? 'Campus UPSA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.visibility_outlined, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        '${local.vistas}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Emoji extends StatelessWidget {
  const _Emoji({required this.local});

  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: .7),
          ConfiguracionTema.verdeMarca.withValues(alpha: .12),
        ],
      ),
    ),
    child: Center(
      child: Text(local.emoji, style: const TextStyle(fontSize: 58)),
    ),
  );
}
