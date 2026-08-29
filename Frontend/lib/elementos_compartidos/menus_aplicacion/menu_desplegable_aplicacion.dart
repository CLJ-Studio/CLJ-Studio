import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../configuracion_aplicacion/configuracion_tema.dart';
import 'elemento_menu_desplegable.dart';

/// Menú de categorías integrado en el flujo de la pantalla.
///
/// No utiliza overlays ni [MenuAnchor]: al abrirse ocupa espacio real dentro
/// del formulario, por lo que nunca puede bloquear los toques o el scroll.
class MenuDesplegableAplicacion extends StatefulWidget {
  const MenuDesplegableAplicacion({
    required this.elementos,
    required this.etiquetaActual,
    required this.iconoActual,
    this.ancho = 360,
    super.key,
  });

  final List<ElementoMenuDesplegable> elementos;
  final String etiquetaActual;
  final IconData iconoActual;
  final double ancho;

  @override
  State<MenuDesplegableAplicacion> createState() =>
      _MenuDesplegableAplicacionState();
}

class _MenuDesplegableAplicacionState extends State<MenuDesplegableAplicacion> {
  static const _verde = Color(0xFF474646);
  static const _altoFila = 52.0;
  static const _umbralBusqueda = 8;

  final _busqueda = TextEditingController();
  bool _abierto = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _alternar() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _abierto = !_abierto;
      if (!_abierto) _busqueda.clear();
    });
  }

  void _seleccionar(ElementoMenuDesplegable elemento) {
    setState(() {
      _abierto = false;
      _busqueda.clear();
    });
    elemento.alPresionar();
  }

  List<ElementoMenuDesplegable> _filtrar(String consulta) {
    final buscado = consulta.trim().toLowerCase();
    if (buscado.isEmpty) return widget.elementos;
    return widget.elementos
        .where((elemento) => elemento.etiqueta.toLowerCase().contains(buscado))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final fondo = oscuro
        ? const Color(0xFF474646)
        : ConfiguracionTema.cremaSuperficie;

    return SizedBox(
      width: widget.ancho,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            expanded: _abierto,
            label: 'Categoría: ${widget.etiquetaActual}',
            child: Material(
              color: fondo,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _alternar,
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: oscuro
                                ? const Color(0xFF474646)
                                : ConfiguracionTema.cremaSuperficie,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.iconoActual,
                            color: _verde,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CATEGORÍA',
                                style: tema.textTheme.labelSmall?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .7,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.etiquetaActual,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _abierto ? .5 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          child: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_abierto
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: fondo,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _busqueda,
                          builder: (context, valor, _) {
                            final visibles = _filtrar(valor.text);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.elementos.length >= _umbralBusqueda)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      10,
                                      10,
                                      4,
                                    ),
                                    child: TextField(
                                      controller: _busqueda,
                                      decoration: InputDecoration(
                                        hintText: 'Buscar categoría',
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                        ),
                                        suffixIcon: valor.text.isEmpty
                                            ? null
                                            : IconButton(
                                                onPressed: _busqueda.clear,
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                              ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: oscuro
                                            ? const Color(0xFF474646)
                                            : ConfiguracionTema.cremaSuperficie,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (visibles.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No encontramos esa categoría.',
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: math.min(
                                      visibles.length * _altoFila,
                                      312,
                                    ),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemExtent: _altoFila,
                                      itemCount: visibles.length,
                                      itemBuilder: (context, indice) {
                                        final elemento = visibles[indice];
                                        return _FilaMenuDesplegable(
                                          elemento: elemento,
                                          alPresionar: () =>
                                              _seleccionar(elemento),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMenuDesplegable extends StatelessWidget {
  const _FilaMenuDesplegable({
    required this.elemento,
    required this.alPresionar,
  });

  final ElementoMenuDesplegable elemento;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: elemento.seleccionado,
    button: true,
    child: InkWell(
      onTap: alPresionar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              elemento.icono,
              size: 20,
              color: elemento.seleccionado
                  ? _MenuDesplegableAplicacionState._verde
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                elemento.etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: elemento.seleccionado
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ),
            if (elemento.seleccionado)
              const Icon(
                Icons.check_rounded,
                color: _MenuDesplegableAplicacionState._verde,
                size: 20,
              ),
          ],
        ),
      ),
    ),
  );
}
