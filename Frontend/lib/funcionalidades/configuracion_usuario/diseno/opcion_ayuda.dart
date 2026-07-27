import 'package:flutter/material.dart';

import '../pantalla/pantalla_ayuda.dart';

class OpcionAyuda extends StatelessWidget {
  const OpcionAyuda({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaAyuda()),
    ),
    leading: const Icon(Icons.help_outline_rounded),
    title: const Text('Ayuda'),
    subtitle: const Text('Preguntas frecuentes y contacto'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
