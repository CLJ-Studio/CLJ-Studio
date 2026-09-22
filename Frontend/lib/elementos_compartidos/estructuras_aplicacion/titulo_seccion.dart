import 'package:flutter/material.dart';

import '../../configuracion_aplicacion/configuracion_tema.dart';

/// El encabezado que separa una seccion de la siguiente.
///
/// POR QUE: cada pantalla escribia el suyo a mano y ninguno coincidia del
/// todo: 20 o 22, peso 800 o 900, y casi siempre con el gris grafito puesto
/// a mano. Ese color fijo es ademas el fondo del tema oscuro, asi que medio
/// titulo desaparecia al cambiar de tema.
///
/// El color sale del tema y el tamano es uno solo. Si un titulo tiene que
/// ser distinto, es que no es un titulo de seccion.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {this.alVerTodo, this.color, super.key});

  final String texto;

  /// Enlace opcional a la derecha, para secciones que muestran un adelanto.
  final VoidCallback? alVerTodo;

  /// Solo para secciones que viven sobre una superficie de color fijo, que no
  /// cambia con el tema. La ficha del producto, por ejemplo, es blanca
  /// siempre: ahi el color claro del tema oscuro seria blanco sobre blanco.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final titulo = Text(
      texto,
      style: TextStyle(
        color:
            color ??
            (Theme.of(context).brightness == Brightness.dark
                ? ConfiguracionTema.crema
                : ConfiguracionTema.grafito),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );

    if (alVerTodo == null) return titulo;
    return Row(
      children: [
        Expanded(child: titulo),
        TextButton(
          onPressed: alVerTodo,
          child: const Text(
            'Ver todo',
            style: TextStyle(
              color: ConfiguracionTema.primario,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
