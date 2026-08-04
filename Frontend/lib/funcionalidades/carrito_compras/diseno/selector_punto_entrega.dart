import 'package:flutter/material.dart';

import '../../mi_local/logica/controlador_mi_local.dart';

/// Dónde se entrega el pedido: un punto del campus más la referencia exacta.
///
/// Antes era un campo libre con un ejemplo de marcador. Eso deja que cada
/// quien escriba el mismo sitio de diez formas ("bloque a", "Bl. A", "el
/// A"), y el vendedor tiene que adivinar. La lista fija normaliza la zona;
/// el texto de al lado queda para el detalle que de verdad varía: la mesa,
/// el piso, la puerta.
class SelectorPuntoEntrega extends StatelessWidget {
  const SelectorPuntoEntrega({
    required this.punto,
    required this.referencia,
    required this.alElegirPunto,
    super.key,
  });

  final String? punto;
  final TextEditingController referencia;
  final ValueChanged<String> alElegirPunto;

  /// Los mismos puntos que usa el vendedor para decir dónde está: si aquí
  /// hubiera otra lista, comprador y vendedor hablarían de sitios distintos.
  static const puntos = ControladorMiLocal.ubicacionesCampus;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Dónde te lo entregan?',
          style: TextStyle(
            color: tema.textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                initialValue: punto,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.place_outlined),
                  hintText: 'Zona',
                ),
                items: [
                  for (final zona in puntos)
                    DropdownMenuItem(value: zona, child: Text(zona)),
                ],
                onChanged: (valor) {
                  if (valor != null) alElegirPunto(valor);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: TextField(
                controller: referencia,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Referencia',
                  helperText: 'Mesa, piso, puerta…',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
