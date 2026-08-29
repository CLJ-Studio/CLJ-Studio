import 'package:flutter/material.dart';

class IndicadorVistas extends StatelessWidget {
  const IndicadorVistas({
    required this.total,
    this.compacto = false,
    super.key,
  });

  final int total;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final etiqueta = '$total ${total == 1 ? 'vista' : 'vistas'}';
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFFE6E1D5)
        : const Color(0xFF474646);

    return Semantics(
      label: etiqueta,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_rounded,
            size: compacto ? 18 : 23,
            color: color,
            weight: 700,
          ),
          const SizedBox(width: 5),
          Text(
            '$total',
            style: TextStyle(
              color: color,
              fontSize: compacto ? 12 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
