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
                      final fin = await elegirFinVigencia(
                        context,
                        ahora: reloj(),
                        elegido: switch (vigencia) {
                          HastaDia(:final fin) => fin,
                          HastaInstante(:final instante) => instante,
                          _ => null,
                        },
                      );
                      if (fin != null) {
                        alCambiar(
                          HastaDia(fin, hora: fin.hour, minuto: fin.minute),
                        );
                      }
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

/// Hasta cuántos días adelante se puede elegir: un año alcanza para cualquier
/// evento sin dejar algo publicado para siempre por un descuido.
const diasMaximosVigencia = 365;

/// Día y hora en que deja de verse. Tocar un día no cierra nada: se puede
/// cambiar de día, pasar de mes deslizando, elegir la hora y recién confirmar
/// con "Listo". Sin tocar la hora, vence a las 23:59.
///
/// Sale en español porque la app carga las traducciones de Material (ver
/// `ArbolAplicacion`). Es un [Dialog] propio y no un [AlertDialog]: este mide
/// el ancho de su contenido, y el calendario no se deja medir así.
Future<DateTime?> elegirFinVigencia(
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
  var dia = inicial;
  var hora = elegido == null || !elegido.isAfter(ahora)
      ? const TimeOfDay(hour: 23, minute: 59)
      : TimeOfDay.fromDateTime(elegido);

  return showDialog<DateTime>(
    context: context,
    builder: (contexto) => StatefulBuilder(
      builder: (contexto, actualizar) {
        final vigencia = HastaDia(dia, hora: hora.hour, minuto: hora.minute);
        final fin = vigencia.fin;
        final valida = fin.isAfter(ahora);
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '¿Hasta cuándo se ve?',
                      style:
                          DialogTheme.of(contexto).titleTextStyle ??
                          Theme.of(contexto).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // initialDate fijo: el calendario lleva su propia seleccion,
                  // y cambiarle la inicial en cada toque lo reacomodaria.
                  CalendarDatePicker(
                    initialDate: inicial,
                    currentDate: hoy,
                    firstDate: hoy,
                    lastDate: ultimo,
                    onDateChanged: (nuevo) => actualizar(() => dia = nuevo),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Hora',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final nueva = await showTimePicker(
                              context: contexto,
                              initialTime: hora,
                              helpText: 'Hora en que deja de verse',
                              // La traduccion de Flutter dice "ACEPTAR", en
                              // mayusculas: el resto de la app no grita.
                              confirmText: 'Aceptar',
                              cancelText: 'Cancelar',
                            );
                            if (nueva != null) actualizar(() => hora = nueva);
                          },
                          icon: const Icon(Icons.expand_more_rounded),
                          iconAlignment: IconAlignment.end,
                          label: Text(
                            '${hora.hour.toString().padLeft(2, '0')}:'
                            '${hora.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      vigencia.explicacion(esPersonal: true, ahora: ahora),
                      style: TextStyle(
                        color: valida
                            ? const Color(0xFF848381)
                            : const Color(0xFFAE7960),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(contexto).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF474646),
                        ),
                        onPressed: valida
                            ? () => Navigator.of(contexto).pop(fin)
                            : null,
                        child: const Text('Listo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
