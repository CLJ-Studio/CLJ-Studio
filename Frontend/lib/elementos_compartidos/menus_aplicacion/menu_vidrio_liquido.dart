import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'elemento_menu_liquido.dart';

/// Pestaña compacta que se transforma en un menú Apple Liquid Glass.
///
/// El paquete administra un único progreso de morph, la física spring, el
/// cierre al tocar fuera y el ajuste a los límites de la pantalla.
class MenuVidrioLiquido extends StatelessWidget {
  const MenuVidrioLiquido({
    required this.elementos,
    required this.etiquetaActual,
    required this.iconoActual,
    this.ancho = 300,
    this.alCerrar,
    super.key,
  });

  final List<ElementoMenuLiquido> elementos;
  final String etiquetaActual;
  final IconData iconoActual;
  final double ancho;
  final VoidCallback? alCerrar;

  @override
  Widget build(BuildContext context) {
    final temaCupertino = CupertinoTheme.of(context);
    final colorTexto =
        temaCupertino.textTheme.textStyle.color ??
        Theme.of(context).colorScheme.onSurface;
    final altoMenu = (elementos.length * 46.0).clamp(92.0, 330.0);

    return RepaintBoundary(
      child: GlassMenu(
        autoAdjustToScreen: true,
        menuAlignment: GlassMenuAlignment.topLeft,
        menuPadding: const EdgeInsets.all(12),
        menuWidth: ancho,
        menuHeight: altoMenu,
        menuBorderRadius: 24,
        itemBorderRadius: 18,
        quality: GlassQuality.standard,
        stretch: .32,
        onClose: alCerrar,
        trigger: Semantics(
          button: true,
          label: 'Categoría: $etiquetaActual. Toca para cambiarla.',
          child: SizedBox(
            width: ancho,
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(iconoActual, size: 21, color: colorTexto),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      etiquetaActual,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: temaCupertino.textTheme.textStyle.copyWith(
                        color: colorTexto,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 16),
                ],
              ),
            ),
          ),
        ),
        items: [
          for (final elemento in elementos)
            GlassMenuItem(
              title: elemento.etiqueta,
              icon: Icon(elemento.icono),
              isSelected: elemento.seleccionado,
              trailing: elemento.seleccionado
                  ? const Icon(CupertinoIcons.check_mark, size: 17)
                  : null,
              onTap: elemento.alPresionar,
            ),
        ],
      ),
    );
  }
}
