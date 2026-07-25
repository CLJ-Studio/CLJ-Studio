import 'package:flutter/material.dart';
import '../diseno/boton_continuar_pedido.dart';
import '../diseno/encabezado_carrito.dart';
import '../diseno/lista_productos_carrito.dart';
import '../diseno/resumen_compra.dart';
import '../logica/controlador_carrito_compras.dart';

/// Pantalla completa del carrito simulado.
class PantallaCarritoCompras extends StatefulWidget {
  const PantallaCarritoCompras({super.key});
  @override
  State<PantallaCarritoCompras> createState() => _PantallaCarritoComprasState();
}

class _PantallaCarritoComprasState extends State<PantallaCarritoCompras> {
  final controlador = ControladorCarritoCompras();
  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0F1F4),
    body: AnimatedBuilder(
      animation: controlador,
      builder: (_, _) => SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esMovil = constraints.maxWidth < 640;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: esMovil ? 0 : 24,
                vertical: esMovil ? 0 : 28,
              ),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 620,
                    minHeight: esMovil ? constraints.maxHeight : 0,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    esMovil ? 20 : 28,
                    18,
                    esMovil ? 20 : 28,
                    28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: esMovil
                        ? BorderRadius.zero
                        : BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EncabezadoCarrito(
                        alCerrar: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: 24),
                      const _InformacionPedido(),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE8EAE8)),
                      const SizedBox(height: 14),
                      ListaProductosCarrito(controlador: controlador),
                      const SizedBox(height: 18),
                      ResumenCompra(
                        subtotal: controlador.subtotal,
                        entrega: controlador.elementos.isEmpty
                            ? 0
                            : ControladorCarritoCompras.costoEntrega,
                        total: controlador.total,
                      ),
                      const SizedBox(height: 20),
                      BotonContinuarPedido(
                        habilitado: controlador.elementos.isNotEmpty,
                        alPresionar: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pedido simulado. El pago se habilitará con el backend.',
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Datos breves del pedido, siguiendo la jerarquía visual de la referencia.
class _InformacionPedido extends StatelessWidget {
  const _InformacionPedido();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del pedido',
              style: TextStyle(
                color: Color(0xFF3D6F4A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Revisa los productos antes de continuar',
              style: TextStyle(color: Color(0xFF858A87), fontSize: 13),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5EC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Nuevo',
          style: TextStyle(
            color: Color(0xFF5C8A63),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
