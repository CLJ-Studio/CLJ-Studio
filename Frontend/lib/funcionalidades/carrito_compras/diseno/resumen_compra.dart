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
  Widget fila(BuildContext context, String etiqueta, String valor, {bool fuerte = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            color: fuerte ? Theme.of(context).colorScheme.onSurface : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: fuerte ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
          fila(context, 'Importe', 'Bs ${subtotal.toStringAsFixed(2)}'),
          fila(context, 'Costo de entrega', 'Bs ${entrega.toStringAsFixed(2)}'),
          fila(context, 'Método de pago', 'Al recoger'),
          Divider(color: Theme.of(context).dividerColor),
          fila(context, 'Total', 'Bs ${total.toStringAsFixed(2)}', fuerte: true),
        ],
      ),
    ),
  );
}
