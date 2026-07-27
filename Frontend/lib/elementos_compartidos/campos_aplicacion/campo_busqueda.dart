import 'package:flutter/material.dart';
import 'dart:ui';

/// Buscador visual compartido por inicio y locales.
class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({
    required this.alCambiar,
    this.texto = 'Buscar en UPSA Net',
    this.compactProgress = 0,
    super.key,
  });
  final ValueChanged<String> alCambiar;
  final String texto;
  final double compactProgress;

  @override
  Widget build(BuildContext context) {
    final radio = lerpDouble(28, 22, compactProgress)!;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radio),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: lerpDouble(56, 46, compactProgress),
      child: TextField(
        onChanged: alCambiar,
        style: TextStyle(fontSize: lerpDouble(14, 13, compactProgress)),
        decoration: InputDecoration(
          hintText: texto,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: lerpDouble(20, 14, compactProgress)!,
            vertical: lerpDouble(18, 12, compactProgress)!,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: lerpDouble(24, 21, compactProgress),
          ),
          border: borde,
          enabledBorder: borde,
        ),
      ),
    );
  }
}
