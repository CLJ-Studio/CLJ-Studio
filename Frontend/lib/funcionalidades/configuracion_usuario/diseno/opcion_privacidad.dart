import 'package:flutter/material.dart';

class OpcionPrivacidad extends StatelessWidget {
  const OpcionPrivacidad({super.key});
  @override
  Widget build(BuildContext context) => const ListTile(
    leading: Icon(Icons.lock_outline),
    title: Text('Privacidad'),
    trailing: Icon(Icons.chevron_right),
  );
}
