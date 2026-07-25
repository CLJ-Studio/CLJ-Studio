import 'package:flutter/material.dart';

class BotonNavegacionInicio extends StatelessWidget {
  const BotonNavegacionInicio({
    required this.activo,
    required this.alPresionar,
    super.key,
  });
  final bool activo;
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Inicio',
    onPressed: alPresionar,
    icon: Icon(activo ? Icons.home_rounded : Icons.home_outlined),
  );
}
