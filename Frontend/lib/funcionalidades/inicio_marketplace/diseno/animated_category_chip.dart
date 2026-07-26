import 'package:flutter/material.dart';
import 'dart:ui';

/// Chip de categoría con una microinteracción corta y controlada.
class AnimatedCategoryChip extends StatefulWidget {
  const AnimatedCategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.selectedBackgroundColor,
    required this.unselectedBackgroundColor,
    required this.selectedForegroundColor,
    required this.unselectedForegroundColor,
    this.compactProgress = 0,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedBackgroundColor;
  final Color unselectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final double compactProgress;

  @override
  State<AnimatedCategoryChip> createState() => _AnimatedCategoryChipState();
}

class _AnimatedCategoryChipState extends State<AnimatedCategoryChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;
  bool _presionado = false;

  @override
  void initState() {
    super.initState();

    // Controla únicamente el rebote del chip que recibió el toque.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // Secuencia premium: compresión, rebote corto y asentamiento.
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: .94,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: .94,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: .98,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: .98,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    // Evita que el ticker continúe activo si el filtro elimina este widget.
    _controller.dispose();
    super.dispose();
  }

  void _alPresionar() {
    if (mounted) setState(() => _presionado = false);

    // El filtro se actualiza inmediatamente y el rebote continúa en paralelo.
    widget.onTap();
    _controller.forward(from: 0);
  }

  void _cambiarPresion(bool valor) {
    if (!mounted || _presionado == valor) return;
    setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final fondo = widget.isSelected
        ? widget.selectedBackgroundColor
        : widget.unselectedBackgroundColor;
    final frente = widget.isSelected
        ? widget.selectedForegroundColor
        : widget.unselectedForegroundColor;
    final progreso = widget.compactProgress.clamp(0.0, 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _cambiarPresion(true),
        onTapCancel: () => _cambiarPresion(false),
        onTapUp: (_) => _cambiarPresion(false),
        onTap: _alPresionar,
        child: AnimatedScale(
          scale: _presionado ? .96 : 1,
          duration: const Duration(milliseconds: 75),
          curve: Curves.easeOut,
          child: ScaleTransition(
            scale: _bounce,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                minHeight: lerpDouble(48, 40, progreso)!,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: lerpDouble(12, 9, progreso)!,
                vertical: lerpDouble(9, 6, progreso)!,
              ),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: frente),
                    duration: const Duration(milliseconds: 220),
                    builder: (_, color, _) => Icon(
                      widget.icon,
                      size: lerpDouble(18, 16, progreso),
                      color: color,
                    ),
                  ),
                  SizedBox(width: lerpDouble(8, 6, progreso)),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: frente,
                      fontFamily: 'Nunito',
                      fontSize: lerpDouble(14, 12.5, progreso),
                      fontWeight: FontWeight.w600,
                    ),
                    child: Text(widget.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
