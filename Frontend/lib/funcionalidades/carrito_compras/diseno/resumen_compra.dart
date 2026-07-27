import 'package:flutter/material.dart';

class ResumenCompra extends StatelessWidget {
  const ResumenCompra({
    required this.subtotal,
    required this.entrega,
    required this.total,
    super.key,
  });
  final double subtotal;
  final double entrega;
  final double total;
  Widget fila(String etiqueta, String valor, {bool fuerte = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            color: fuerte ? const Color(0xFF202221) : const Color(0xFF7C827E),
            fontWeight: fuerte ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            color: const Color(0xFF202221),
            fontWeight: fuerte ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          fila('Importe', 'Bs ${subtotal.toStringAsFixed(2)}'),
          fila('Costo de entrega', 'Bs ${entrega.toStringAsFixed(2)}'),
          fila('Método de pago', 'Al recoger'),
          Divider(color: Theme.of(context).dividerColor),
          fila('Total', 'Bs ${total.toStringAsFixed(2)}', fuerte: true),
        ],
      ),
    ),
  );
}
