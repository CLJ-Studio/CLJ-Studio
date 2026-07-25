import 'package:flutter/material.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
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
    appBar: AppBar(title: const Text('Carrito')),
    body: AnimatedBuilder(
      animation: controlador,
      builder: (_, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: ContenidoCentrado(
          anchoMaximo: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EncabezadoCarrito(),
              const SizedBox(height: 14),
              ListaProductosCarrito(controlador: controlador),
              const SizedBox(height: 16),
              ResumenCompra(
                subtotal: controlador.subtotal,
                entrega: controlador.elementos.isEmpty
                    ? 0
                    : ControladorCarritoCompras.costoEntrega,
                total: controlador.total,
              ),
              const SizedBox(height: 12),
              BotonContinuarPedido(
                habilitado: controlador.elementos.isNotEmpty,
                alPresionar: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Pedido simulado. El pago se habilitara con el backend.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
