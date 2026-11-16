import 'package:flutter/material.dart';

import '../../../elementos_compartidos/menus_aplicacion/elemento_menu_desplegable.dart';
import '../../../elementos_compartidos/menus_aplicacion/menu_desplegable_aplicacion.dart';
import '../logica/vigencia_publicacion.dart';

/// "¿Hasta cuándo se ve?": hasta que se venda (sin fecha, en un local), 24
/// horas, o hasta un día. Es el mismo menú de la categoría, para que el
/// formulario no estrene otro control.
class SelectorVigenciaPublicacion extends StatelessWidget {
  const SelectorVigenciaPublicacion({
    required this.vigencia,
    required this.esPersonal,
    required this.alCambiar,
    this.reloj = DateTime.now,
    super.key,
  });

  final VigenciaPublicacion vigencia;
  final bool esPersonal;
  final ValueChanged<VigenciaPublicacion> alCambiar;
  final DateTime Function() reloj;

  static IconData _icono(VigenciaPublicacion vigencia, bool esPersonal) =>
      switch (vigencia) {
        SinFecha() =>
          esPersonal ? Icons.sell_outlined : Icons.all_inclusive_rounded,
        UnDia() => Icons.schedule_rounded,
        HastaDia() || HastaInstante() => Icons.event_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ahora = reloj();
    const sinFecha = SinFecha();
    const unDia = UnDia();
    final conFecha = vigencia is HastaDia || vigencia is HastaInstante;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth > 360
            ? 360.0
            : restricciones.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: MenuDesplegableAplicacion(
                ancho: ancho,
                etiquetaActual: vigencia.etiqueta(
                  esPersonal: esPersonal,
                  ahora: ahora,
                ),
                iconoActual: _icono(vigencia, esPersonal),
                elementos: [
                  ElementoMenuDesplegable(
                    icono: _icono(sinFecha, esPersonal),
                    etiqueta: sinFecha.etiqueta(
                      esPersonal: esPersonal,
                      ahora: ahora,
                    ),
                    seleccionado: vigencia is SinFecha,
                    alPresionar: () => alCambiar(sinFecha),
                  ),
                  ElementoMenuDesplegable(
                    icono: _icono(unDia, esPersonal),
                    etiqueta: unDia.etiqueta(
                      esPersonal: esPersonal,
                      ahora: ahora,
                    ),
                    seleccionado: vigencia is UnDia,
                    alPresionar: () => alCambiar(unDia),
                  ),
                  ElementoMenuDesplegable(
                    icono: Icons.event_rounded,
                    etiqueta: 'Hasta una fecha…',
                    seleccionado: conFecha,
                    alPresionar: () async {
                      final dia = await elegirDiaVigencia(
                        context,
                        ahora: reloj(),
                      );
                      if (dia != null) alCambiar(HastaDia(dia));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vigencia.explicacion(esPersonal: esPersonal, ahora: ahora),
              style: const TextStyle(
                color: Color(0xFF848381),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Los próximos días, en palabras: el calendario de Flutter saldría en inglés,
/// porque la app no carga traducciones de Material. Para una entrada del
/// sábado o un evento del mes, un mes de días alcanza.
Future<DateTime?> elegirDiaVigencia(
  BuildContext context, {
  required DateTime ahora,
}) => showDialog<DateTime>(
  context: context,
  builder: (contexto) => AlertDialog(
    title: const Text('¿Hasta qué día se ve?'),
    contentPadding: const EdgeInsets.only(top: 12),
    content: SizedBox(
      width: 360,
      height: 400,
      child: ListView(
        children: [
          for (final dia in diasParaElegir(ahora))
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(nombreDia(dia, ahora)),
              onTap: () => Navigator.of(contexto).pop(dia),
            ),
        ],
      ),
    ),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.of(contexto).pop(),
        child: const Text('Cancelar'),
      ),
    ],
  ),
);
