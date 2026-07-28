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
  final _puntoEncuentro = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _puntoEncuentro.dispose();
    super.dispose();
  }

  Future<void> _confirmarPedido() async {
    setState(() => _enviando = true);
    try {
      final pedidoId = await const RepositorioPedidos().crear(
        items: controlador.aItemsDePedido(),
        puntoEncuentro: _puntoEncuentro.text.trim().isEmpty
            ? null
            : _puntoEncuentro.text.trim(),
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
      appBar: AppBar(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controlador.local case final local?) ...[
                  Row(
                    children: [
                      Text(local.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          local.nombre,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                ListaProductosCarrito(controlador: controlador),
                if (!controlador.estaVacio) ...[
                  const SizedBox(height: 22),
                  TextField(
                    controller: _puntoEncuentro,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                    ),
                    decoration: InputDecoration(
                      labelText: '¿Dónde te lo entregan?',
                      hintText: 'Ej. Bloque A - Recepción',
                      labelStyle:
                          Theme.of(context).brightness == Brightness.dark
                          ? const TextStyle(color: Colors.white)
                          : null,
                      hintStyle: Theme.of(context).brightness == Brightness.dark
                          ? const TextStyle(color: Colors.white)
                          : null,
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ResumenCompra(
                    subtotal: controlador.subtotal,
                    entrega: controlador.costoEntrega,
                    total: controlador.total,
                  ),
                ],
              ],
            ),
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
              habilitado: !controlador.estaVacio && !_enviando,
              total: controlador.total,
              alPresionar: _confirmarPedido,
            ),
          ),
        ),
      ),
    ),
  );
}
