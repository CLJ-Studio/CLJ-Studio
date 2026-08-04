import 'package:flutter/material.dart';

import '../modelos/local_universitario.dart';

/// Tarjeta de local compartida visualmente con "Locales más vistos".
///
/// La portada conserva su marco 4:3, sin desenfoque ni texto superpuesto; la
/// información vive en un pie oscuro separado para que siempre sea legible.
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
      color: const Color(0xFF2B292A),
      borderRadius: BorderRadius.circular(9),
      clipBehavior: Clip.antiAlias,
      elevation: 7,
      shadowColor: const Color(0x55000000),
      child: InkWell(
        onTap: alAbrir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          local.nombreVisible,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.visibility_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${local.vistas}',
                        style: const TextStyle(
                          color: Color(0xFFCAC6C8),
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
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          local.ubicacionCampus ?? 'Campus UPSA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCAC6C8),
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
