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
    const colorTexto = Color(0xFF474646);

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFE6E1D5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          children: [
            fila(
              'Subtotal',
              'Bs ${subtotal.toStringAsFixed(2)}',
              colorTexto: colorTexto,
            ),
            fila(
              'Envío',
              'Bs ${entrega.toStringAsFixed(2)}',
              colorTexto: colorTexto,
            ),
            const Divider(color: Color(0xFFE6E1D5)),
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
