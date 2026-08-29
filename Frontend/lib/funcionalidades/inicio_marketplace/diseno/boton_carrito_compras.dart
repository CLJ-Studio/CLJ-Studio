import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../carrito_compras/logica/controlador_carrito_compras.dart';

/// Acceso al carrito con el contador real de unidades.
class BotonCarritoCompras extends StatelessWidget {
  const BotonCarritoCompras({
    required this.alPresionar,
    this.sobreFondoMarca = false,
    super.key,
  });
  final VoidCallback alPresionar;
  final bool sobreFondoMarca;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ControladorCarritoCompras.instancia,
    builder: (context, _) {
      final unidades = ControladorCarritoCompras.instancia.unidades;
      return Badge(
        isLabelVisible: unidades > 0,
        label: Text('$unidades'),
        child: IconButton(
          tooltip: 'Abrir carrito',
          style: IconButton.styleFrom(
            backgroundColor: sobreFondoMarca
                ? Colors.transparent
                : Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF474646)
                : ConfiguracionTema.cremaSuperficie,
            foregroundColor: sobreFondoMarca
                ? Colors.white
                : Theme.of(context).brightness == Brightness.dark
                ? Color(0xFFE6E1D5)
                : Color(0xFF474646),
          ),
          onPressed: alPresionar,
          icon: const Icon(Icons.shopping_cart_outlined, size: 27),
        ),
      );
    },
  );
}
