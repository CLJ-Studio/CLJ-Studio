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
                        elegido: switch (vigencia) {
                          HastaDia(:final dia) => dia,
                          HastaInstante(:final instante) => instante,
                          _ => null,
                        },
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

/// Hasta cuántos días adelante se puede elegir: alcanza para un evento del
/// semestre sin dejar que algo quede publicado un año por un descuido.
const diasMaximosVigencia = 180;

/// Un calendario: tocar un día lo elige. Sale en español porque la app carga
/// las traducciones de Material (ver `ArbolAplicacion`).
///
/// Es un [Dialog] propio y no un [AlertDialog]: este mide el ancho de su
/// contenido, y el calendario no se deja medir así.
Future<DateTime?> elegirDiaVigencia(
  BuildContext context, {
  required DateTime ahora,
  DateTime? elegido,
}) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final ultimo = hoy.add(const Duration(days: diasMaximosVigencia));
  var inicial = elegido == null
      ? hoy
      : DateTime(elegido.year, elegido.month, elegido.day);
  if (inicial.isBefore(hoy) || inicial.isAfter(ultimo)) inicial = hoy;

  return showDialog<DateTime>(
    context: context,
    builder: (contexto) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '¿Hasta qué día se ve?',
                  style:
                      DialogTheme.of(contexto).titleTextStyle ??
                      Theme.of(contexto).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              CalendarDatePicker(
                initialDate: inicial,
                currentDate: hoy,
                firstDate: hoy,
                lastDate: ultimo,
                onDateChanged: (dia) => Navigator.of(contexto).pop(dia),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(contexto).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
