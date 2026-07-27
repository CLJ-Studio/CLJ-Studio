import 'package:flutter/material.dart';

import '../../pedidos/pantalla/pantalla_pedidos_completa.dart';

/// Acceso a compras y ventas desde Configuracion.
class OpcionPedidos extends StatelessWidget {
  const OpcionPedidos({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PantallaPedidosCompleta()),
    ),
    leading: Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary),
    title: const Text('Pedidos'),
    subtitle: const Text('Tus compras y ventas'),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
