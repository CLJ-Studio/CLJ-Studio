import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../logica/controlador_carrito_compras.dart';

/// Resumen persistente que aparece al agregar productos desde un local.
class BarraResumenCarrito extends StatelessWidget {
  const BarraResumenCarrito({required this.localId, super.key});

  final String localId;

  @override
  Widget build(BuildContext context) {
    final carrito = ControladorCarritoCompras.instancia;

    return AnimatedBuilder(
      animation: carrito,
      builder: (context, _) {
        final visible = !carrito.estaVacio && carrito.local?.id == localId;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animacion) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animacion,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animacion, child: child),
          ),
          child: visible
              ? SafeArea(
                  key: const ValueKey('resumen-carrito-visible'),
                  minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            elevation: 10,
                            shadowColor: Colors.black38,
                            child: SizedBox(
                              width: 76,
                              height: 68,
                              child: Center(
                                child: Text(
                                  '${carrito.unidades}',
                                  style: const TextStyle(
                                    color: Color(0xFF315638),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              color: const Color(0xFF138A5B),
                              borderRadius: BorderRadius.circular(28),
                              elevation: 10,
                              shadowColor: Colors.black38,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(ConfiguracionRutas.carrito),
                                child: SizedBox(
                                  height: 68,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Ver carrito',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Bs ${carrito.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('resumen-carrito-oculto')),
        );
      },
    );
  }
}
