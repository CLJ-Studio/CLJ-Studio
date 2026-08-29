import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
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

  Future<void> _cancelar(Pedido pedido) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text(
          'Se cancelará tu pedido en ${pedido.nombreLocal}. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAE7960),
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final error = await widget.controlador.cancelar(pedido.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
    }
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
            labelColor: const Color(0xFF474646),
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            indicatorColor: const Color(0xFF474646),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900),
            tabs: [
              _PestanaConAviso(
                titulo: 'Mis compras',
                pendientes: controlador.comprasPorConfirmar,
              ),
              _PestanaConAviso(
                titulo: 'Mis ventas',
                pendientes: controlador.ventasPorResponder,
              ),
            ],
          ),
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
                    sinLeerDe: controlador.mensajesSinLeerDe,
                    // Solo el comprador puede cancelar, y solo mientras el
                    // vendedor no haya respondido.
                    alCancelar: _cancelar,
                  ),
                  _ListaPedidos(
                    pedidos: controlador.ventas,
                    soyVendedor: true,
                    mostrarTotalVendido: true,
                    vacio: 'Aún no has recibido pedidos en tu local.',
                    alRefrescar: controlador.cargar,
                    alAbrir: _abrir,
                    sinLeerDe: controlador.mensajesSinLeerDe,
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

/// Pestaña con el número de cosas que esperan a esta persona.
///
/// Las dos pestañas lo usan: antes el distintivo era solo para el vendedor,
/// pero ahora al comprador también le puede tocar confirmar una entrega, y
/// sin aviso no volvería a entrar a mirar.
class _PestanaConAviso extends StatelessWidget {
  const _PestanaConAviso({required this.titulo, required this.pendientes});

  final String titulo;
  final int pendientes;

  @override
  Widget build(BuildContext context) => Tab(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(titulo),
        if (pendientes > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFAE7960),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pendientes',
              style: const TextStyle(
                color: Color(0xFFE6E1D5),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ListaPedidos extends StatefulWidget {
  const _ListaPedidos({
    required this.pedidos,
    required this.soyVendedor,
    required this.vacio,
    required this.alRefrescar,
    required this.alAbrir,
    this.alCancelar,
    this.mostrarTotalVendido = false,
    this.sinLeerDe,
  });

  final List<Pedido> pedidos;
  final bool soyVendedor;
  final String vacio;
  final Future<void> Function() alRefrescar;
  final void Function(Pedido) alAbrir;
  final void Function(Pedido)? alCancelar;
  final bool mostrarTotalVendido;

  /// Mensajes sin leer de un pedido, para su distintivo.
  final int Function(String)? sinLeerDe;

  @override
  State<_ListaPedidos> createState() => _ListaPedidosState();
}

class _ListaPedidosState extends State<_ListaPedidos> {
  String _busqueda = '';

  List<Pedido> get _filtrados {
    final consulta = _busqueda.trim().toLowerCase();
    if (consulta.isEmpty) return widget.pedidos;
    return widget.pedidos.where((pedido) {
      final productos = pedido.items.map((item) => item.nombre).join(' ');
      return pedido.nombreLocal.toLowerCase().contains(consulta) ||
          pedido.nombreComprador.toLowerCase().contains(consulta) ||
          productos.toLowerCase().contains(consulta);
    }).toList();
  }

  /// Lo vendido incluye lo que está en el aire pero no se cayó: un pedido a
  /// medio confirmar ya se entregó, solo falta que alguien lo diga.
  double get _totalVendido => widget.pedidos
      .where(
        (pedido) =>
            pedido.estado == EstadoPedido.aceptado ||
            pedido.estado == EstadoPedido.porConfirmar ||
            pedido.estado == EstadoPedido.entregado,
      )
      .fold(0, (total, pedido) => total + pedido.total);

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: widget.alRefrescar,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      children: [
        ContenidoCentrado(
          anchoMaximo: 620,
          child: widget.pedidos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 46,
                        color: Color(0xFFBBBCA7),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.vacio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF848381)),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResumenMovimiento(
                      titulo: widget.mostrarTotalVendido
                          ? 'Total vendido'
                          : 'Total comprado',
                      total: widget.mostrarTotalVendido
                          ? _totalVendido
                          : widget.pedidos.fold(
                              0,
                              (total, pedido) => total + pedido.total,
                            ),
                      cantidad: widget.pedidos.length,
                      esVenta: widget.mostrarTotalVendido,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (valor) => setState(() => _busqueda = valor),
                      decoration: InputDecoration(
                        hintText: 'Buscar pedido',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF474646)
                            : Color(0xFFE6E1D5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final pedido in _filtrados)
                      TarjetaPedido(
                        pedido: pedido,
                        soyVendedor: widget.soyVendedor,
                        mensajesSinLeer: widget.sinLeerDe?.call(pedido.id) ?? 0,
                        alAbrir: () => widget.alAbrir(pedido),
                        alCancelar:
                            widget.alCancelar != null &&
                                pedido.estado == EstadoPedido.solicitado
                            ? () => widget.alCancelar!(pedido)
                            : null,
                      ),
                    if (_filtrados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 44),
                        child: Text(
                          'No encontramos pedidos con esa búsqueda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF848381)),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class _ResumenMovimiento extends StatelessWidget {
  const _ResumenMovimiento({
    required this.titulo,
    required this.total,
    required this.cantidad,
    required this.esVenta,
  });

  final String titulo;
  final double total;
  final int cantidad;
  final bool esVenta;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: esVenta ? const Color(0xFF474646) : const Color(0xFF474646),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22474646),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xB3E6E1D5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Bs ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFE6E1D5),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFFE6E1D5).withValues(alpha: .16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '$cantidad ${cantidad == 1 ? 'pedido' : 'pedidos'}',
            style: const TextStyle(
              color: Color(0xFFE6E1D5),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
