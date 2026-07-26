import 'package:flutter/material.dart';

/// Acción primaria consistente en formularios y procesos de compra.
class BotonPrimario extends StatelessWidget {
  const BotonPrimario({
    required this.texto,
    required this.alPresionar,
    this.icono,
    super.key,
  });
  final String texto;
  final VoidCallback? alPresionar;
  final IconData? icono;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton.icon(
      onPressed: alPresionar,
      icon: Icon(icono ?? Icons.arrow_forward_rounded),
      label: Text(texto),
    ),
  );
}
