import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../diseno/tarjeta_pedido.dart';
import '../logica/controlador_pedidos.dart';
import '../modelos/pedido.dart';
import 'pantalla_detalle_pedido.dart';

/// Compras y ventas del usuario en dos pestañas.
class PantallaPedidos extends StatefulWidget {
  const PantallaPedidos({required this.controlador, super.key});

  final ControladorPedidos controlador;

  @override
  State<PantallaPedidos> createState() => _PantallaPedidosState();
}

class _PantallaPedidosState extends State<PantallaPedidos>
    with SingleTickerProviderStateMixin {
  late final _pestanas = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  Future<void> _abrir(Pedido pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetallePedido(pedidoId: pedido.id),
      ),
    );
    // Al volver, el estado pudo cambiar (aceptado, cancelado...).
    await widget.controlador.cargar();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controlador,
    builder: (context, _) {
      final controlador = widget.controlador;

      return Column(
        children: [
          const SizedBox(height: 12),
          TabBar(
            controller: _pestanas,
            labelColor: const Color(0xFF55785A),
            unselectedLabelColor: const Color(0xFF9A9A9A),
            indicatorColor: const Color(0xFF5C8A63),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900),
            tabs: [
              const Tab(text: 'Mis compras'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Mis ventas'),
                    if (controlador.ventasPorResponder > 0) ...[
                      const SizedBox(width: 6),
                      // Distintivo: aceptar o rechazar es lo unico que el
                      // vendedor no puede dejar pasar.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC98A2B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${controlador.ventasPorResponder}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: switch (controlador) {
              ControladorPedidos(cargando: true) => const Center(
                child: CircularProgressIndicator(),
              ),
              ControladorPedidos(error: final String mensaje) =>
                MensajeCatalogo(
                  mensaje: mensaje,
                  alReintentar: controlador.cargar,
                ),
              _ => TabBarView(
                controller: _pestanas,
                children: [
                  _ListaPedidos(
                    pedidos: controlador.compras,
                    soyVendedor: false,
                    vacio: 'Todavía no has hecho ningún pedido.',
                    alRefrescar: controlador.cargar,
                    alAbrir: _abrir,
                  ),
                  _ListaPedidos(
                    pedidos: controlador.ventas,
                    soyVendedor: true,
                    vacio: 'Aún no has recibido pedidos en tu local.',
                    alRefrescar: controlador.cargar,
                    alAbrir: _abrir,
                  ),
                ],
              ),
            },
          ),
        ],
      );
    },
  );
}

class _ListaPedidos extends StatelessWidget {
  const _ListaPedidos({
    required this.pedidos,
    required this.soyVendedor,
    required this.vacio,
    required this.alRefrescar,
    required this.alAbrir,
  });

  final List<Pedido> pedidos;
  final bool soyVendedor;
  final String vacio;
  final Future<void> Function() alRefrescar;
  final void Function(Pedido) alAbrir;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: alRefrescar,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        ContenidoCentrado(
          anchoMaximo: 620,
          child: pedidos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 46,
                        color: Color(0xFFB8BDB8),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        vacio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF858585)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final pedido in pedidos)
                      TarjetaPedido(
                        pedido: pedido,
                        soyVendedor: soyVendedor,
                        alAbrir: () => alAbrir(pedido),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
