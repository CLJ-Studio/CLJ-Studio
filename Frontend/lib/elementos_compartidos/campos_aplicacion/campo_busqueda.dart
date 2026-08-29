import 'package:flutter/material.dart';
import 'dart:ui';

import '../../configuracion_aplicacion/configuracion_tema.dart';

/// Buscador visual compartido por inicio y locales.
class CampoBusqueda extends StatefulWidget {
  const CampoBusqueda({
    required this.alCambiar,
    this.texto = 'Buscar en U market',
    this.compactProgress = 0,
    this.colorFondo,
    super.key,
  });
  final ValueChanged<String> alCambiar;
  final String texto;
  final double compactProgress;
  final Color? colorFondo;

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
    final sobreFondoPersonalizado = widget.colorFondo != null;
    final colorTexto = oscuro && !sobreFondoPersonalizado
        ? Color(0xFFE6E1D5)
        : ConfiguracionTema.grafito;
    final radio = lerpDouble(28, 22, widget.compactProgress)!;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radio),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: lerpDouble(54, 44, widget.compactProgress),
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
            color: oscuro && !sobreFondoPersonalizado
                ? Color(0xFFE6E1D5).withValues(alpha: .55)
                : const Color(0xFF969A82),
          ),
          filled: true,
          fillColor:
              widget.colorFondo ??
              (oscuro
                  ? const Color(0xFF474646)
                  : ConfiguracionTema.cremaSuperficie),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: lerpDouble(16, 13, widget.compactProgress)!,
            vertical: lerpDouble(13, 10, widget.compactProgress)!,
          ),
          suffixIcon: _controladorTexto.text.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(5),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: ConfiguracionTema.primario,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFE6E1D5),
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Borrar búsqueda',
                  onPressed: _limpiar,
                  icon: Icon(
                    Icons.close_rounded,
                    color: oscuro && !sobreFondoPersonalizado
                        ? const Color(0xFFBBBCA7)
                        : ConfiguracionTema.primario,
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
