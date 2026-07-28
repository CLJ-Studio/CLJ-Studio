import 'package:flutter/material.dart';
import 'dart:ui';

/// Buscador visual compartido por inicio y locales.
class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({
    required this.alCambiar,
    this.texto = 'Buscar en UPSA Eat',
    this.compactProgress = 0,
    super.key,
  });
  final ValueChanged<String> alCambiar;
  final String texto;
  final double compactProgress;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = oscuro ? Colors.white : const Color(0xFF202220);
    final radio = lerpDouble(28, 22, compactProgress)!;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radio),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: lerpDouble(56, 46, compactProgress),
      child: TextField(
        onChanged: alCambiar,
        style: TextStyle(
          color: colorTexto,
          fontSize: lerpDouble(14, 13, compactProgress),
        ),
        decoration: InputDecoration(
          hintText: texto,
          hintStyle: TextStyle(
            color: oscuro
                ? Colors.white.withValues(alpha: .55)
                : const Color(0xFF9A9D9A),
          ),
          filled: true,
          fillColor: oscuro ? const Color(0xFF242724) : const Color(0xFFF5F6F4),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: lerpDouble(20, 14, compactProgress)!,
            vertical: lerpDouble(18, 12, compactProgress)!,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorTexto,
            size: lerpDouble(24, 21, compactProgress),
          ),
          border: borde,
          enabledBorder: borde,
        ),
      ),
    );
  }
}
