import 'package:flutter/material.dart';

class OpcionNotificaciones extends StatelessWidget {
  const OpcionNotificaciones({
    required this.valor,
    required this.alCambiar,
    super.key,
  });
  final bool valor;
  final ValueChanged<bool> alCambiar;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: const Icon(Icons.notifications_outlined),
    title: const Text('Notificaciones'),
    subtitle: const Text('Pedidos y novedades'),
    value: valor,
    onChanged: alCambiar,
  );
}
