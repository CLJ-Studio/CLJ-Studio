import 'package:flutter/material.dart';

import '../pantalla/pantalla_acerca_de.dart';

class OpcionAcercaDe extends StatelessWidget {
  const OpcionAcercaDe({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PantallaAcercaDe())),
    leading: const Icon(Icons.info_outline_rounded),
    title: const Text('Acerca de nosotros'),
    subtitle: const Text('Quiénes somos y derechos de autor'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
