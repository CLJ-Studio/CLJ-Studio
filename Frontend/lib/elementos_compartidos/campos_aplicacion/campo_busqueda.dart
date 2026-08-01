import 'package:flutter/material.dart';
import 'dart:ui';

/// Buscador visual compartido por inicio y locales.
class CampoBusqueda extends StatefulWidget {
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
  State<CampoBusqueda> createState() => _CampoBusquedaState();
}

class _CampoBusquedaState extends State<CampoBusqueda> {
  final TextEditingController _controladorTexto = TextEditingController();

  @override
  void dispose() {
    _controladorTexto.dispose();
    super.dispose();
  }

  void _alCambiar(String valor) {
    setState(() {});
    widget.alCambiar(valor);
  }

  void _limpiar() {
    _controladorTexto.clear();
    setState(() {});
    widget.alCambiar('');
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = oscuro ? Colors.white : const Color(0xFF202220);
    final radio = lerpDouble(17, 15, widget.compactProgress)!;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radio),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: lerpDouble(48, 42, widget.compactProgress),
      child: TextField(
        controller: _controladorTexto,
        onChanged: _alCambiar,
        style: TextStyle(
          color: colorTexto,
          fontSize: lerpDouble(15, 14, widget.compactProgress),
        ),
        decoration: InputDecoration(
          hintText: widget.texto,
          hintStyle: TextStyle(
            color: oscuro
                ? Colors.white.withValues(alpha: .55)
                : const Color(0xFF9A9D9A),
          ),
          filled: true,
          fillColor: oscuro ? const Color(0xFF24272A) : const Color(0xFFEEEDEB),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: lerpDouble(16, 13, widget.compactProgress)!,
            vertical: lerpDouble(13, 10, widget.compactProgress)!,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: oscuro ? const Color(0xFF9CA1A6) : const Color(0xFF646A67),
            size: lerpDouble(22, 20, widget.compactProgress),
          ),
          suffixIcon: _controladorTexto.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Borrar búsqueda',
                  onPressed: _limpiar,
                  icon: Icon(
                    Icons.close_rounded,
                    color: oscuro
                        ? const Color(0xFFB9BDBA)
                        : const Color(0xFF646A67),
                  ),
                ),
          border: borde,
          enabledBorder: borde,
          focusedBorder: borde,
          disabledBorder: borde,
        ),
      ),
    );
  }
}
