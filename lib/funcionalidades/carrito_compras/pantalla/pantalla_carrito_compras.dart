import 'package:flutter/material.dart';
import '../diseno/boton_continuar_pedido.dart';
import '../diseno/lista_productos_carrito.dart';
import '../logica/controlador_carrito_compras.dart';
import 'pantalla_contactando_vendedor.dart';

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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (context, _) => Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Carrito',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListaProductosCarrito(controlador: controlador),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: BotonContinuarPedido(
              habilitado: controlador.elementos.isNotEmpty,
              total: controlador.total,
              alPresionar: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PantallaContactandoVendedor(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
