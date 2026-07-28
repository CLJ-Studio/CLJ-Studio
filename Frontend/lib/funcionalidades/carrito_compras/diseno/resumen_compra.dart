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
  Widget fila(
    String etiqueta,
    String valor, {
    required Color colorTexto,
    bool fuerte = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            color: colorTexto,
            fontWeight: fuerte ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            color: colorTexto,
            fontWeight: fuerte ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF202221);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            fila(
              'Importe',
              'Bs ${subtotal.toStringAsFixed(2)}',
              colorTexto: colorTexto,
            ),
            fila(
              'Costo de entrega',
              'Bs ${entrega.toStringAsFixed(2)}',
              colorTexto: colorTexto,
            ),
            fila('Método de pago', 'Al recoger', colorTexto: colorTexto),
            Divider(color: Theme.of(context).dividerColor),
            fila(
              'Total',
              'Bs ${total.toStringAsFixed(2)}',
              colorTexto: colorTexto,
              fuerte: true,
            ),
          ],
        ),
      ),
    );
  }
}
