import 'package:flutter/material.dart';

import '../../../elementos_compartidos/menus_aplicacion/elemento_menu_desplegable.dart';
import '../../../elementos_compartidos/menus_aplicacion/menu_desplegable_aplicacion.dart';
import '../../inicio_marketplace/modelos/categoria_marketplace.dart';

/// Categoría de lo que se publica.
///
/// Antes la categoría vivía solo en el local, así que el filtro del inicio
/// no encontraba nada de lo publicado a título personal: ese espacio se crea
/// por detrás y nace sin ninguna. Preguntarla aquí es lo que hace que la
/// barra de categorías sirva para algo.
class SelectorCategoriaPublicacion extends StatelessWidget {
  const SelectorCategoriaPublicacion({
    required this.categorias,
    required this.seleccionada,
    required this.alSeleccionar,
    super.key,
  });

  final List<CategoriaMarketplace> categorias;
  final String? seleccionada;
  final ValueChanged<String> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    // 'Todo' encabeza la barra del inicio pero no es una categoría real: no
    // se puede publicar algo "en todo".
    final elegibles = categorias
        .where((c) => c.id != CategoriaMarketplace.todas.id)
        .toList();

    if (elegibles.isEmpty) return const SizedBox.shrink();
    CategoriaMarketplace? actual;
    for (final categoria in elegibles) {
      if (categoria.id == seleccionada) actual = categoria;
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth > 360
            ? 360.0
            : restricciones.maxWidth;
        return Align(
          alignment: Alignment.centerLeft,
          child: MenuDesplegableAplicacion(
            ancho: ancho,
            etiquetaActual: actual?.nombre ?? 'Selecciona una categoría',
            iconoActual: actual?.icono ?? Icons.category_outlined,
            elementos: [
              for (final categoria in elegibles)
                ElementoMenuDesplegable(
                  icono: categoria.icono,
                  etiqueta: categoria.nombre,
                  seleccionado: categoria.id == seleccionada,
                  alPresionar: () => alSeleccionar(categoria.id),
                ),
            ],
          ),
        );
      },
    );
  }
}
