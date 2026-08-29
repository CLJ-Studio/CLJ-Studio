import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class VisorImagenProductoPantalla extends StatefulWidget {
  const VisorImagenProductoPantalla({
    required this.urlsImagenes,
    required this.indiceInicial,
    required this.prefijoHero,
    this.etiquetaSemantica,
    super.key,
  }) : assert(urlsImagenes.length > 0),
       assert(indiceInicial >= 0 && indiceInicial < urlsImagenes.length);

  final List<String> urlsImagenes;
  final int indiceInicial;
  final String prefijoHero;
  final String? etiquetaSemantica;

  @override
  State<VisorImagenProductoPantalla> createState() =>
      _VisorImagenProductoPantallaState();
}

class _VisorImagenProductoPantallaState
    extends State<VisorImagenProductoPantalla> {
  late final PageController _paginas = PageController(
    initialPage: widget.indiceInicial,
  );
  late final List<PhotoViewController> _controladores = List.generate(
    widget.urlsImagenes.length,
    (_) => PhotoViewController(),
  );
  late int _indice = widget.indiceInicial;

  String _tagHero(int indice) =>
      '${widget.prefijoHero}-imagen-producto-$indice';

  void _cerrar() => Navigator.of(context).pop(_indice);

  void _irA(int indice) {
    if (indice < 0 || indice >= widget.urlsImagenes.length) return;
    _paginas.animateToPage(
      indice,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _alPresionarTecla(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent) return KeyEventResult.ignored;
    if (evento.logicalKey == LogicalKeyboardKey.escape) {
      _cerrar();
      return KeyEventResult.handled;
    }
    if (evento.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _irA(_indice - 1);
      return KeyEventResult.handled;
    }
    if (evento.logicalKey == LogicalKeyboardKey.arrowRight) {
      _irA(_indice + 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _alUsarRueda(PointerSignalEvent evento) {
    if (evento is! PointerScrollEvent) return;
    final controlador = _controladores[_indice];
    final escala = controlador.scale;
    if (escala == null) return;
    final factor = math.exp(-evento.scrollDelta.dy * .0015);
    controlador.scale = (escala * factor).clamp(.1, 20);
  }

  @override
  void dispose() {
    _paginas.dispose();
    for (final controlador in _controladores) {
      controlador.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Focus(
      autofocus: true,
      onKeyEvent: _alPresionarTecla,
      child: Scaffold(
        backgroundColor: Color(0xFF474646),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              onPointerSignal: _alUsarRueda,
              child: RepaintBoundary(
                child: PhotoViewGallery.builder(
                  itemCount: widget.urlsImagenes.length,
                  pageController: _paginas,
                  backgroundDecoration: const BoxDecoration(
                    color: Color(0xFF474646),
                  ),
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (indice) => setState(() => _indice = indice),
                  loadingBuilder: (_, progreso) => Center(
                    child: SizedBox.square(
                      dimension: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFE6E1D5),
                        value: progreso?.expectedTotalBytes == null
                            ? null
                            : progreso!.cumulativeBytesLoaded /
                                  progreso.expectedTotalBytes!,
                      ),
                    ),
                  ),
                  builder: (_, indice) => PhotoViewGalleryPageOptions(
                    key: ValueKey(widget.urlsImagenes[indice]),
                    imageProvider: NetworkImage(widget.urlsImagenes[indice]),
                    semanticLabel:
                        '${widget.etiquetaSemantica ?? 'Imagen del producto'}, ${indice + 1} de ${widget.urlsImagenes.length}',
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: _tagHero(indice),
                      transitionOnUserGestures: true,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    initialScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    basePosition: Alignment.center,
                    controller: _controladores[indice],
                    errorBuilder: (_, _, _) => const _ErrorImagen(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Semantics(
                    button: true,
                    label: 'Cerrar visor de imágenes',
                    child: _ControlCircular(
                      tooltip: 'Cerrar',
                      icono: Icons.close_rounded,
                      alPresionar: _cerrar,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.urlsImagenes.length > 1)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x99474646),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          '${_indice + 1} / ${widget.urlsImagenes.length}',
                          style: const TextStyle(
                            color: Color(0xFFE6E1D5),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.urlsImagenes.length > 1) ...[
              if (_indice > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: 'Imagen anterior',
                    child: _ControlCircular(
                      tooltip: 'Imagen anterior',
                      icono: Icons.chevron_left_rounded,
                      alPresionar: () => _irA(_indice - 1),
                    ),
                  ),
                ),
              if (_indice < widget.urlsImagenes.length - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    button: true,
                    label: 'Imagen siguiente',
                    child: _ControlCircular(
                      tooltip: 'Imagen siguiente',
                      icono: Icons.chevron_right_rounded,
                      alPresionar: () => _irA(_indice + 1),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ControlCircular extends StatelessWidget {
  const _ControlCircular({
    required this.tooltip,
    required this.icono,
    required this.alPresionar,
  });

  final String tooltip;
  final IconData icono;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Material(
      color: const Color(0x99474646),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: alPresionar,
        icon: Icon(icono, color: Color(0xFFE6E1D5)),
      ),
    ),
  );
}

class _ErrorImagen extends StatelessWidget {
  const _ErrorImagen();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: Color(0xB3E6E1D5), size: 46),
        SizedBox(height: 12),
        Text(
          'No se pudo cargar esta imagen',
          style: TextStyle(color: Color(0xB3E6E1D5)),
        ),
      ],
    ),
  );
}
