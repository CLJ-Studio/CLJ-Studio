import 'package:flutter/material.dart';

/// Encabezado de preferencias del usuario.
class EncabezadoConfiguracion extends StatelessWidget {
  const EncabezadoConfiguracion({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Configuracion',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      Text(
        'Administra tu cuenta y experiencia.',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    ],
  );
}
