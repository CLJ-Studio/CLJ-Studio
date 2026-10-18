import 'package:flutter/material.dart';

import '../pantalla/pantalla_solicitudes_egresado.dart';

/// La entrada a las solicitudes de egresados. Solo se pone para los admins
/// (ver PantallaConfiguracionUsuario).
class OpcionSolicitudesEgresado extends StatelessWidget {
  const OpcionSolicitudesEgresado({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaSolicitudesEgresado(),
      ),
    ),
    leading: const Icon(Icons.workspace_premium_outlined),
    title: const Text('Solicitudes de egresados'),
    subtitle: const Text('Aprobar a quien dice que se graduó'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
