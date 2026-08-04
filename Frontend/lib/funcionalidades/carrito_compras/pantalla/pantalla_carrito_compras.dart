import 'package:flutter/material.dart';

import '../../pedidos/datos/repositorio_pedidos.dart';
import '../diseno/boton_continuar_pedido.dart';
import '../diseno/lista_productos_carrito.dart';
import '../diseno/resumen_compra.dart';
import '../logica/controlador_carrito_compras.dart';
import 'pantalla_contactando_vendedor.dart';

/// Carrito del usuario y punto de partida del pedido.
class PantallaCarritoCompras extends StatefulWidget {
  const PantallaCarritoCompras({super.key});
  @override
  State<PantallaCarritoCompras> createState() => _PantallaCarritoComprasState();
}

class _PantallaCarritoComprasState extends State<PantallaCarritoCompras> {
  // Singleton: el carrito se llena desde el catalogo, en otra pantalla.
  final controlador = ControladorCarritoCompras.instancia;
  bool _enviando = false;

  Future<void> _confirmarPedido() async {
    setState(() => _enviando = true);
    try {
      final pedidoId = await const RepositorioPedidos().crear(
        items: controlador.aItemsDePedido(),
        puntoEncuentro: null,
      );

      // El carrito ya cumplio su papel: a partir de aqui manda el pedido.
      controlador.vaciar();
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PantallaContactandoVendedor(pedidoId: pedidoId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_mensajeDeError(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Traduce los codigos que lanza `crear_pedido` a algo legible.
  String _mensajeDeError(Object error) {
    final texto = error.toString();
    if (texto.contains('ONBOARDING_INCOMPLETO')) {
      return 'Completa tu perfil antes de pedir.';
    }
    if (texto.contains('STOCK_INSUFICIENTE')) {
      return 'Uno de los productos ya no tiene stock suficiente.';
    }
    if (texto.contains('LOCAL_CERRADO')) {
      return 'El local no está disponible en este momento.';
    }
    if (texto.contains('AUTOCOMPRA_NO_PERMITIDA')) {
      return 'No puedes pedirte productos a ti mismo.';
    }
    if (texto.contains('CARRITO_MULTIPLE_LOCAL')) {
      return 'Haz un pedido por cada local.';
    }
    return 'No se pudo enviar el pedido. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFF1F2F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F2F3),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 6, bottom: 6),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left_rounded, size: 30),
            ),
          ),
        ),
        title: const Text(
          'Carrito',
          style: TextStyle(
            color: Color(0xFF171717),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 6, bottom: 6),
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: PopupMenuButton<void>(
                tooltip: 'Opciones',
                icon: const Icon(Icons.more_horiz_rounded),
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    enabled: !controlador.estaVacio,
                    onTap: controlador.vaciar,
                    child: const Text('Vaciar carrito'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListaProductosCarrito(controlador: controlador),
                if (!controlador.estaVacio) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        ResumenCompra(
                          subtotal: controlador.subtotal,
                          entrega: controlador.costoEntrega,
                          total: controlador.total,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: BotonContinuarPedido(
                            habilitado: !_enviando,
                            alPresionar: _confirmarPedido,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
