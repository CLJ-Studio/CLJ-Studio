import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../modelos/local_universitario.dart';

/// Tarjeta de local compartida visualmente con "Locales más vistos".
///
/// La fotografía domina y la información vive en un pie blanco y limpio.
class TarjetaLocalUniversitario extends StatelessWidget {
  const TarjetaLocalUniversitario({
    required this.local,
    required this.alAbrir,
    super.key,
  });

  final LocalUniversitario local;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Abrir ${local.nombreVisible}',
    child: Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? ConfiguracionTema.grafito
          : Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: alAbrir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          local.nombreVisible,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.visibility_outlined,
                        color: ConfiguracionTema.primario,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${local.vistas}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: ConfiguracionTema.primario,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          local.ubicacionCampus ?? 'Campus UPSA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Emoji extends StatelessWidget {
  const _Emoji({required this.local});

  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(local.emoji, style: const TextStyle(fontSize: 72)));
}
