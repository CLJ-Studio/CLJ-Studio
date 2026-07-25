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
  Widget fila(String etiqueta, double valor, {bool fuerte = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontWeight: fuerte ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          'Bs ${valor.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: fuerte ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          fila('Subtotal', subtotal),
          fila('Costo de entrega', entrega),
          const Divider(),
          fila('Total', total, fuerte: true),
        ],
      ),
    ),
  );
}
