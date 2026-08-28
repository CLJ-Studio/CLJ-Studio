import 'package:flutter/material.dart';

import '../../publicar_producto/pantalla/pantalla_mis_publicaciones.dart';

/// Acceso a los productos publicados en el local del estudiante.
class OpcionMisPublicaciones extends StatelessWidget {
  const OpcionMisPublicaciones({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaMisPublicaciones()),
    ),
    leading: const Icon(Icons.grid_on_rounded, color: Color(0xFF138A5B)),
    title: const Text('Mis publicaciones'),
    subtitle: const Text('Lo que ofreces en tu local'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
