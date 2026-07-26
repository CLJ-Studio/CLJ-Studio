import 'package:flutter/material.dart';

import '../modelos/local_universitario.dart';

/// Tarjeta fotográfica de ancho completo inspirada en la referencia.
class TarjetaLocalUniversitario extends StatelessWidget {
  const TarjetaLocalUniversitario({
    required this.local,
    required this.alAbrir,
    super.key,
  });

  final LocalUniversitario local;
  final VoidCallback alAbrir;

  String get _imagen => switch (local.id) {
    'cafeteria' => 'assets/images/real/coffee3.jpg',
    'snack' => 'assets/images/real/hamburger2.jpg',
    'tech' => 'assets/images/real/western2.jpg',
    'libreria' => 'assets/images/real/bakery.jpg',
    _ => 'assets/images/real/breakfast.jpg',
  };

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
            borderRadius: BorderRadius.circular(34),
            image: DecorationImage(
              image: ResizeImage.resizeIfNeeded(
                1200,
                null,
                AssetImage(_imagen),
              ),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
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
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.white,
                          child: Text(
                            local.emoji,
                            style: const TextStyle(fontSize: 13),
                          ),
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
