import 'package:flutter/material.dart';

class OpcionAyuda extends StatelessWidget {
  const OpcionAyuda({super.key});
  @override
  Widget build(BuildContext context) => const ListTile(
    leading: Icon(Icons.help_outline),
    title: Text('Ayuda'),
    trailing: Icon(Icons.chevron_right),
  );
}
