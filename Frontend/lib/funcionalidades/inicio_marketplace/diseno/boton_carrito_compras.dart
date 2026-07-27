import 'package:flutter/material.dart';

import '../../carrito_compras/logica/controlador_carrito_compras.dart';

/// Acceso al carrito con el contador real de unidades.
class BotonCarritoCompras extends StatelessWidget {
  const BotonCarritoCompras({required this.alPresionar, super.key});
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ControladorCarritoCompras.instancia,
    builder: (context, _) {
      final unidades = ControladorCarritoCompras.instancia.unidades;
      return Badge(
        isLabelVisible: unidades > 0,
        label: Text('$unidades'),
        child: IconButton.filledTonal(
          tooltip: 'Abrir carrito',
          onPressed: alPresionar,
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      );
    },
  );
}
