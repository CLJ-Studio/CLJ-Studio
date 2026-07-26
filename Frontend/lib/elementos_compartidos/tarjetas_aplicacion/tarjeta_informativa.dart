import 'package:flutter/material.dart';

/// Superficie compartida para bloques breves de información.
class TarjetaInformativa extends StatelessWidget {
  const TarjetaInformativa({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );
}
