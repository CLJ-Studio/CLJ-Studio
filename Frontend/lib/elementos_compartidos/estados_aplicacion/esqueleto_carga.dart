import 'package:flutter/material.dart';

/// Bloque de carga con un brillo suave, para mantener las dimensiones del
/// contenido mientras llegan los datos o las imágenes.
class EsqueletoCarga extends StatefulWidget {
  const EsqueletoCarga({
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    super.key,
  });

  final BorderRadius borderRadius;

  @override
  State<EsqueletoCarga> createState() => _EsqueletoCargaState();
}

class _EsqueletoCargaState extends State<EsqueletoCarga>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final base = tema.colorScheme.onSurface.withValues(
      alpha: tema.brightness == Brightness.dark ? .10 : .11,
    );
    final brillo = tema.colorScheme.onSurface.withValues(
      alpha: tema.brightness == Brightness.dark ? .19 : .20,
    );

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: LayoutBuilder(
          builder: (context, limites) {
            final ancho = limites.maxWidth.isFinite ? limites.maxWidth : 120.0;
            final anchoBrillo = ancho * .42;
            return AnimatedBuilder(
              animation: _animacion,
              builder: (context, _) => Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: base),
                  Positioned(
                    left:
                        (ancho + anchoBrillo) * _animacion.value - anchoBrillo,
                    top: 0,
                    bottom: 0,
                    width: anchoBrillo,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            brillo.withValues(alpha: 0),
                            brillo,
                            brillo.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
