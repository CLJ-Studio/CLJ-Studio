import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../carrito_compras/logica/controlador_carrito_compras.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../diseno/tarjeta_pedido.dart';
import '../logica/controlador_pedidos.dart';
import '../modelos/pedido.dart';
import 'pantalla_chats.dart';
import 'pantalla_detalle_pedido.dart';

/// Compras y ventas con la apariencia de un historial de pedidos nativo.
class PantallaPedidos extends StatefulWidget {
  const PantallaPedidos({required this.controlador, super.key});

  final ControladorPedidos controlador;

  @override
  State<PantallaPedidos> createState() => _PantallaPedidosState();
}

class _PantallaPedidosState extends State<PantallaPedidos>
    with SingleTickerProviderStateMixin {
  static const _marketplace = RepositorioInicioMarketplace();
  late final _pestanas = TabController(length: 3, vsync: this);
  String? _repitiendoId;

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
    await widget.controlador.cargar();
  }

  ProductoMarketplace? _encontrarProducto(
    ItemPedido item,
    List<ProductoMarketplace> productos,
  ) {
    for (final producto in productos) {
      if (item.productoId != null && producto.id == item.productoId) {
        return producto;
      }
    }
    final nombre = item.nombre.trim().toLowerCase();
    for (final producto in productos) {
      if (producto.nombre.trim().toLowerCase() == nombre) return producto;
    }
    return null;
  }

  Future<void> _repetir(Pedido pedido) async {
    if (_repitiendoId != null) return;
    setState(() => _repitiendoId = pedido.id);

    try {
      final (local, productos) = await (
        _marketplace.obtenerLocal(pedido.localId),
        _marketplace.obtenerProductos(pedido.localId),
      ).wait;
      if (!mounted) return;
      if (local == null) {
        _avisar('Este local ya no está disponible.');
        return;
      }

      final disponibles = <(ProductoMarketplace, int)>[];
      var omitidos = 0;
      for (final item in pedido.items) {
        final producto = _encontrarProducto(item, productos);
        if (producto == null || !producto.disponible) {
          omitidos++;
          continue;
        }
        final cantidad = producto.esServicio
            ? item.cantidad
            : math.min(item.cantidad, producto.stock);
        if (cantidad <= 0) {
          omitidos++;
          continue;
        }
        disponibles.add((producto, cantidad));
      }
      if (disponibles.isEmpty) {
        _avisar('Los productos de este pedido ya no están disponibles.');
        return;
      }

      final carrito = ControladorCarritoCompras.instancia;
      if (!carrito.estaVacio) {
        final reemplazar = await showDialog<bool>(
          context: context,
          builder: (contexto) => AlertDialog(
            title: const Text('Reemplazar el carrito'),
            content: const Text(
              'Para repetir este pedido reemplazaremos lo que tienes ahora '
              'en el carrito.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(contexto).pop(false),
                child: const Text('Conservar carrito'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(contexto).pop(true),
                child: const Text('Reemplazar'),
              ),
            ],
          ),
        );
        if (reemplazar != true || !mounted) return;
      }

      carrito.vaciar();
      for (final (producto, cantidad) in disponibles) {
        for (var i = 0; i < cantidad; i++) {
          carrito.agregar(producto, local);
        }
      }
      await Navigator.of(context).pushNamed(ConfiguracionRutas.carrito);
      if (omitidos > 0 && mounted) {
        _avisar(
          omitidos == 1
              ? 'Un producto ya no estaba disponible y no se agregó.'
              : '$omitidos productos ya no estaban disponibles.',
        );
      }
    } catch (_) {
      if (mounted) _avisar('No pudimos preparar nuevamente este pedido.');
    } finally {
      if (mounted) setState(() => _repitiendoId = null);
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: AnimatedBuilder(
      animation: widget.controlador,
      builder: (context, _) {
        final controlador = widget.controlador;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _pestanas,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFFF4F3F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                  labelColor: const Color(0xFF10091D),
                  unselectedLabelColor: const Color(0xFF10091D),
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: [
                    _PestanaConAviso(
                      titulo: 'Mis pedidos',
                      pendientes: controlador.comprasPorConfirmar,
                    ),
                    _PestanaConAviso(
                      titulo: 'Mis ventas',
                      pendientes: controlador.ventasPorResponder,
                    ),
                    _PestanaConAviso(
                      titulo: 'Chats',
                      pendientes: controlador.chatsAbiertos,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1EFF3)),
            Expanded(
              child: switch (controlador) {
                ControladorPedidos(cargando: true) => const Center(
                  child: IndicadorCarga(),
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
                      alRepetir: _repetir,
                      repitiendoId: _repitiendoId,
                      sinLeerDe: controlador.mensajesSinLeerDe,
                    ),
                    _ListaPedidos(
                      pedidos: controlador.ventas,
                      soyVendedor: true,
                      vacio: 'Aún no has recibido pedidos en tu local.',
                      alRefrescar: controlador.cargar,
                      alAbrir: _abrir,
                      repitiendoId: _repitiendoId,
                      sinLeerDe: controlador.mensajesSinLeerDe,
                    ),
                    ContenidoChats(
                      chats: controlador.chats,
                      alRefrescar: controlador.recargar,
                    ),
                  ],
                ),
              },
            ),
          ],
        );
      },
    ),
  );
}

class _PestanaConAviso extends StatelessWidget {
  const _PestanaConAviso({required this.titulo, required this.pendientes});

  final String titulo;
  final int pendientes;

  @override
  Widget build(BuildContext context) => Tab(
    height: 48,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titulo),
        if (pendientes > 0) ...[
          const SizedBox(width: 7),
          Container(
            constraints: const BoxConstraints(minWidth: 21),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE93636),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pendientes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ListaPedidos extends StatelessWidget {
  const _ListaPedidos({
    required this.pedidos,
    required this.soyVendedor,
    required this.vacio,
    required this.alRefrescar,
    required this.alAbrir,
    required this.repitiendoId,
    required this.sinLeerDe,
    this.alRepetir,
  });

  final List<Pedido> pedidos;
  final bool soyVendedor;
  final String vacio;
  final Future<void> Function() alRefrescar;
  final void Function(Pedido) alAbrir;
  final void Function(Pedido)? alRepetir;
  final String? repitiendoId;
  final int Function(String) sinLeerDe;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: alRefrescar,
    color: const Color(0xFF252B68),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 96),
      children: [
        ContenidoCentrado(
          anchoMaximo: 650,
          child: pedidos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 90),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: Color(0xFFB9B5BE),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        vacio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF625C68),
                          fontSize: 15,
                        ),
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
                        mensajesSinLeer: sinLeerDe(pedido.id),
                        alAbrir: () => alAbrir(pedido),
                        alRepetir:
                            !soyVendedor &&
                                pedido.estado.estaCerrado &&
                                alRepetir != null
                            ? () => alRepetir!(pedido)
                            : null,
                        repitiendo: repitiendoId == pedido.id,
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
