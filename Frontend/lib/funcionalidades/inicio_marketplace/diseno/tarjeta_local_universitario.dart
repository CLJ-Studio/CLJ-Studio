import 'dart:ui';

import 'package:flutter/material.dart';

import '../modelos/local_universitario.dart';

/// Tarjeta fotográfica de ancho completo inspirada en la referencia.
///
/// El fondo es la foto real del local (su logo, o la primera foto de sus
/// productos). Antes eran imágenes de archivo asignadas por id, así que un
/// local de tecnología aparecía con una foto de desayuno.
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
    label: 'Abrir ${local.nombre}',
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(34),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alAbrir,
        child: Ink(
          decoration: BoxDecoration(
            color: Color(local.colorHexadecimal),
            borderRadius: BorderRadius.circular(34),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // La foto se difumina al fondo para que el texto se lea sin
              // competir con ella; encima va la misma imagen nítida y
              // contenida, para que el producto se vea completo.
              if (local.portadaUrl case final String url) ...[
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: const ColoredBox(color: Color(0x33000000)),
                ),
                Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ] else
                Center(
                  child: Text(
                    local.emoji,
                    style: const TextStyle(fontSize: 96),
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xB3000000),
                      Color(0x22000000),
                      Color(0xB8000000),
                    ],
                    stops: [0, .5, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 68),
                      child: Text(
                        local.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.08,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Cara de quien vende: en un campus la confianza
                        // viene de reconocer a la persona.
                        Container(
                          width: 26,
                          height: 26,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: switch (local.vendedorAvatarUrl) {
                            final String url => Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Text(
                                  local.emoji,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            _ => Center(
                              child: Text(
                                local.emoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${local.categoria} · ${local.estaAbierto ? 'Abierto' : 'Cerrado'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      local.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFC6011),
                          size: 20,
                        ),
                        Text(
                          ' ${local.calificacion}  ·  ${local.tiempoEstimado}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          local.costoEntrega == 0
                              ? 'Entrega gratis'
                              : 'Bs ${local.costoEntrega.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    color: Color(0xFF4A4B4D),
                    size: 27,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
