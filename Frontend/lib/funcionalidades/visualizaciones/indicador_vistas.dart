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
    return Semantics(
      label: etiqueta,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_rounded,
            size: compacto ? 18 : 23,
            color: const Color(0xFF202220),
            weight: 700,
          ),
          const SizedBox(width: 5),
          Text(
            '$total',
            style: TextStyle(
              color: const Color(0xFF202220),
              fontSize: compacto ? 12 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
