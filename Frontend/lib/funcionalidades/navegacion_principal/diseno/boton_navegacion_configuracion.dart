import 'package:flutter/material.dart';

class BotonNavegacionConfiguracion extends StatelessWidget {
  const BotonNavegacionConfiguracion({
    required this.activo,
    required this.alPresionar,
    super.key,
  });
  final bool activo;
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Configuracion',
    onPressed: alPresionar,
    icon: Icon(activo ? Icons.settings : Icons.settings_outlined),
  );
}
