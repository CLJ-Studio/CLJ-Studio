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
      button: true,
      label: etiqueta,
      child: Tooltip(
        message: etiqueta,
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(
          Icons.visibility_rounded,
          size: compacto ? 20 : 25,
          color: const Color(0xFF202220),
          weight: 700,
        ),
      ),
    );
  }
}
