import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Carrusel centrado inspirado en el selector giratorio de Apple.
///
/// La tarjeta más cercana al centro crece y recupera toda su opacidad,
/// mientras las tarjetas laterales retroceden suavemente.
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
  final _controlador = PageController(viewportFraction: .56);
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

    return SizedBox(
      height: 242,
      child: Column(
        children: [
          Expanded(
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
                    final diferencia = (pagina - indice).clamp(-1.0, 1.0);
                    final distancia = diferencia.abs();
                    final escala = 1 - distancia * .17;
                    final matriz = Matrix4.identity()
                      ..setEntry(3, 2, .0015)
                      ..rotateY(diferencia * .48)
                      ..scaleByDouble(escala, escala, 1, 1);

                    return Transform.translate(
                      offset: Offset(diferencia * 12, distancia * 6),
                      child: Transform(
                        alignment: diferencia < 0
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        transform: matriz,
                        child: Opacity(
                          opacity: 1 - distancia * .3,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    child: OpenContainer<void>(
                      transitionDuration: const Duration(milliseconds: 580),
                      transitionType: ContainerTransitionType.fade,
                      closedElevation: 8,
                      openElevation: 0,
                      closedColor: Colors.transparent,
                      openColor: Theme.of(context).scaffoldBackgroundColor,
                      closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
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
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var indice = 0; indice < visibles.length; indice++)
                GestureDetector(
                  onTap: () => _controlador.animateToPage(
                    indice,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: indice == _paginaActiva ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: indice == _paginaActiva
                          ? const Color(0xFF5C8A63)
                          : const Color(0xFFD7DDD8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaDestacada extends StatelessWidget {
  const _TarjetaDestacada({required this.local, required this.alAbrir});

  final LocalUniversitario local;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: oscuro ? const Color(0xFF262826) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alAbrir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Color(local.colorHexadecimal),
                    child: switch (local.portadaUrl) {
                      final String url => Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _Emoji(local: local),
                      ),
                      _ => _Emoji(local: local),
                    },
                  ),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: _Etiqueta(
                      icono: Icons.star_rounded,
                      texto: local.calificacion.toStringAsFixed(1),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: _Etiqueta(
                      icono: Icons.visibility_rounded,
                      texto: '${local.vistas}',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    local.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${local.categoria} · ${local.estaAbierto ? 'Abierto' : 'Cerrado'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B817D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Emoji extends StatelessWidget {
  const _Emoji({required this.local});

  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(local.emoji, style: const TextStyle(fontSize: 54)));
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: const Color(0xFF79B982), size: 13),
        const SizedBox(width: 3),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
