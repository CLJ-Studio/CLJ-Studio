import 'package:flutter/material.dart';

import '../pantalla/pantalla_directorio_proveedores.dart';

/// La entrada al directorio en la configuracion. Solo se pone para las
/// cuentas de la UPSA y los admins (ver PantallaConfiguracionUsuario).
class OpcionDirectorioProveedores extends StatelessWidget {
  const OpcionDirectorioProveedores({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaDirectorioProveedores(),
      ),
    ),
    leading: const Icon(Icons.storefront_rounded),
    title: const Text('Directorio de proveedores'),
    subtitle: const Text('Emprendimientos de estudiantes y egresados'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
