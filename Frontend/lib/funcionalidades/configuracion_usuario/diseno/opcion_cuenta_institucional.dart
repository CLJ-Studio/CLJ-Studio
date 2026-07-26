import 'package:flutter/material.dart';

class OpcionCuentaInstitucional extends StatelessWidget {
  const OpcionCuentaInstitucional({super.key});
  @override
  Widget build(BuildContext context) => const ListTile(
    leading: Icon(Icons.school_outlined),
    title: Text('Cuenta institucional'),
    subtitle: Text('Correo UPSA verificado'),
    trailing: Icon(Icons.chevron_right),
  );
}
