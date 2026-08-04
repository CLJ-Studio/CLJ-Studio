import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Carrusel de locales con una tarjeta central y sus vecinas visibles.
///
/// La escala y la opacidad siguen el desplazamiento sin reconstruir la
/// pantalla completa por cada píxel recorrido.
class CarruselLocalesDestacados extends StatefulWidget {
  const CarruselLocalesDestacados({
    required this.locales,
    required this.construirDetalle,
    super.key,
  });

  final List<LocalUniversitario> locales;
  final Widget Function(BuildContext, LocalUniversitario) construirDetalle;

  @override
  State<CarruselLocalesDestacados> createState() =>
      _CarruselLocalesDestacadosState();
}

class _CarruselLocalesDestacadosState extends State<CarruselLocalesDestacados> {
  final _controlador = PageController(viewportFraction: .86);
  int _paginaActiva = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destacados = [...widget.locales]
      ..sort((a, b) => b.vistas.compareTo(a.vistas));
    final visibles = destacados.take(8).toList(growable: false);

    if (visibles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, restricciones) {
        // Cada pagina ocupa el 86 % del carrusel y lleva 6 px por lado.
        // La foto usa exactamente el mismo 4:3 del editor (1200 x 900);
        // el pie oscuro se suma por fuera y no altera ni recorta la portada.
        final anchoTarjeta = restricciones.maxWidth * .86 - 12;
        // 68 deja margen para escalado de texto y redondeos fraccionarios
        // del navegador, sin alterar el marco 4:3 de la fotografía.
        final alto = anchoTarjeta * 3 / 4 + 68;
        return SizedBox(
          height: alto,
          child: PageView.builder(
            controller: _controlador,
            clipBehavior: Clip.none,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: visibles.length,
            onPageChanged: (pagina) => setState(() => _paginaActiva = pagina),
            itemBuilder: (context, indice) {
              final local = visibles[indice];
              return AnimatedBuilder(
                animation: _controlador,
                builder: (context, child) {
                  final pagina = _controlador.hasClients
                      ? (_controlador.page ?? _paginaActiva.toDouble())
                      : _paginaActiva.toDouble();
                  final distancia = (pagina - indice).abs().clamp(0.0, 1.0);
                  final escala = 1 - distancia * .08;
                  final opacidad = 1 - distancia * .28;

                  return Transform.scale(
                    scale: escala,
                    child: Opacity(opacity: opacidad, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: OpenContainer<void>(
                    transitionDuration: const Duration(milliseconds: 580),
                    transitionType: ContainerTransitionType.fade,
                    closedElevation: 8,
                    openElevation: 0,
                    closedColor: Colors.transparent,
                    openColor: Theme.of(context).scaffoldBackgroundColor,
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    openShape: const RoundedRectangleBorder(),
                    closedBuilder: (_, abrir) =>
                        _TarjetaDestacada(local: local, alAbrir: abrir),
                    openBuilder: (context, _) =>
                        widget.construirDetalle(context, local),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TarjetaDestacada extends StatelessWidget {
  const _TarjetaDestacada({required this.local, required this.alAbrir});

  final LocalUniversitario local;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF2B292A),
    borderRadius: BorderRadius.circular(9),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alAbrir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La foto domina la tarjeta, igual que en la referencia.
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
          // Nombre, vistas y ubicación permanecen en el pie oscuro.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.visibility_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${local.vistas}',
                      style: const TextStyle(
                        color: Color(0xFFCAC6C8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        local.ubicacionCampus ?? 'Campus UPSA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCAC6C8),
                          fontSize: 12,
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
  );
}

class _Emoji extends StatelessWidget {
  const _Emoji({required this.local});

  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(local.emoji, style: const TextStyle(fontSize: 54)));
}
