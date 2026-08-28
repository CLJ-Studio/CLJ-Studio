import 'package:flutter/material.dart';
import 'dart:ui';

import '../../configuracion_aplicacion/configuracion_tema.dart';

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
    final colorTexto = oscuro ? Colors.white : ConfiguracionTema.tinta;
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
            color: oscuro
                ? Colors.white.withValues(alpha: .55)
                : const Color(0xFF9A9D9A),
          ),
          filled: true,
          fillColor: oscuro ? const Color(0xFF272329) : Colors.white,
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
                      color: ConfiguracionTema.verdeMarca,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Borrar búsqueda',
                  onPressed: _limpiar,
                  icon: Icon(
                    Icons.close_rounded,
                    color: oscuro
                        ? const Color(0xFFB9BDBA)
                        : ConfiguracionTema.verdeMarca,
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
