import 'package:flutter/material.dart';

class OpcionTemaAplicacion extends StatelessWidget {
  const OpcionTemaAplicacion({
    required this.valor,
    required this.alCambiar,
    super.key,
  });
  final bool valor;
  final ValueChanged<bool> alCambiar;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    activeThumbColor: Colors.white,
    activeTrackColor: const Color(0xFF5F9368),
    inactiveThumbColor: Colors.white,
    inactiveTrackColor: const Color(0xFFD2D5D2),
    secondary: const Icon(Icons.dark_mode_outlined),
    title: const Text('Tema de la aplicacion'),
    subtitle: const Text('Vista oscura (demostracion)'),
    value: valor,
    onChanged: alCambiar,
  );
}
