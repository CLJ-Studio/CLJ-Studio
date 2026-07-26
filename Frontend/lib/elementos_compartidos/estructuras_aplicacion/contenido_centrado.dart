import 'package:flutter/material.dart';

/// Evita que el contenido se estire demasiado en navegadores de escritorio.
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({
    required this.child,
    this.anchoMaximo = 1200,
    super.key,
  });
  final Widget child;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: anchoMaximo),
      child: child,
    ),
  );
}
