import 'package:flutter/material.dart';

import '../pantalla/pantalla_privacidad.dart';

class OpcionPrivacidad extends StatelessWidget {
  const OpcionPrivacidad({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaPrivacidad()),
    ),
    leading: const Icon(Icons.lock_outline_rounded),
    title: const Text('Privacidad'),
    subtitle: const Text('Qué guardamos y quién lo ve'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
