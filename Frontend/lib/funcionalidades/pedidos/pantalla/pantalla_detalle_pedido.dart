import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../datos/repositorio_pedidos.dart';
import '../diseno/etiqueta_estado_pedido.dart';
import '../modelos/pedido.dart';

/// Detalle de un pedido con las acciones que permite su estado.
class PantallaDetallePedido extends StatefulWidget {
  const PantallaDetallePedido({required this.pedidoId, super.key});

  final String pedidoId;

  @override
  State<PantallaDetallePedido> createState() => _PantallaDetallePedidoState();
}

class _PantallaDetallePedidoState extends State<PantallaDetallePedido> {
  static const _repositorio = RepositorioPedidos();

  late Stream<Pedido?> _pedido = _repositorio.escuchar(widget.pedidoId);
  bool _ocupado = false;

  bool _soyElVendedor(Pedido pedido) =>
      pedido.vendedorId == Supabase.instance.client.auth.currentUser?.id;

  /// Envuelve las acciones para no repetir el bloqueo del boton ni el aviso.
  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() => _ocupado = true);
    try {
      await accion();
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
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _mensajeDeError(Object error) {
    final texto = error.toString();
    if (texto.contains('STOCK_INSUFICIENTE')) {
      return 'Ya no tienes stock suficiente para aceptar este pedido.';
    }
    if (texto.contains('PEDIDO_VENCIDO')) {
      return 'El pedido venció y ya no puede aceptarse.';
    }
    if (texto.contains('ESTADO_INVALIDO')) {
      return 'El pedido ya cambió de estado.';
    }
    if (texto.contains('CONTACTO_NO_DISPONIBLE')) {
      return 'El contacto se libera cuando el vendedor acepta.';
    }
    return 'No se pudo completar la acción.';
  }

  Future<void> _abrirWhatsapp() => _ejecutar(() async {
    final contacto = await _repositorio.obtenerContacto(widget.pedidoId);
    final url = Uri.parse(contacto.enlace);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFBFA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAFBFA),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Pedido',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: StreamBuilder<Pedido?>(
      stream: _pedido,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MensajeCatalogo(
            mensaje: 'No se pudo cargar el pedido.',
            alReintentar: () => setState(() {
              _pedido = _repositorio.escuchar(widget.pedidoId);
            }),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pedido = snapshot.data!;
        final soyVendedor = _soyElVendedor(pedido);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Encabezado(pedido: pedido, soyVendedor: soyVendedor),
                  const SizedBox(height: 20),
                  _Items(pedido: pedido),
                  const SizedBox(height: 18),
                  _Totales(pedido: pedido),
                  if (pedido.puntoEncuentro case final punto?) ...[
                    const SizedBox(height: 18),
                    _Dato(
                      icono: Icons.place_outlined,
                      titulo: 'Punto de encuentro',
                      valor: punto,
                    ),
                  ],
                  const SizedBox(height: 26),
                  ..._acciones(pedido, soyVendedor),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  List<Widget> _acciones(Pedido pedido, bool soyVendedor) {
    // El vendedor decide mientras el pedido siga pendiente.
    if (pedido.estado == EstadoPedido.solicitado && soyVendedor) {
      return [
        FilledButton.icon(
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() => _repositorio.aceptar(pedido.id)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5C8A63),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aceptar pedido'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() => _repositorio.rechazar(pedido.id)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB3453B),
            side: const BorderSide(color: Color(0xFFE0BDB9)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Rechazar'),
        ),
      ];
    }

    // El comprador puede desistir mientras no se haya entregado.
    if (pedido.estado == EstadoPedido.solicitado && !soyVendedor) {
      return [
        OutlinedButton.icon(
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() => _repositorio.cancelar(pedido.id)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB3453B),
            side: const BorderSide(color: Color(0xFFE0BDB9)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar pedido'),
        ),
      ];
    }

    if (pedido.estado == EstadoPedido.aceptado) {
      return [
        FilledButton.icon(
          onPressed: _ocupado ? null : _abrirWhatsapp,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.chat_rounded),
          label: Text(
            soyVendedor
                ? 'Coordinar con ${pedido.nombreComprador.split(' ').first}'
                : 'Coordinar con ${pedido.nombreVendedor.split(' ').first}',
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() => _repositorio.marcarEntregado(pedido.id)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4A7C93),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Marcar como entregado'),
        ),
        if (!soyVendedor) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: _ocupado
                ? null
                : () => _ejecutar(() => _repositorio.cancelar(pedido.id)),
            child: const Text(
              'Cancelar pedido',
              style: TextStyle(color: Color(0xFFB3453B)),
            ),
          ),
        ],
      ];
    }

    return const [];
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.pedido, required this.soyVendedor});

  final Pedido pedido;
  final bool soyVendedor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EtiquetaEstadoPedido(estado: pedido.estado),
      const SizedBox(height: 14),
      Row(
        children: [
          Text(pedido.emojiLocal, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pedido.nombreLocal,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF252825),
                  ),
                ),
                Text(
                  soyVendedor
                      ? 'Pedido de ${pedido.nombreComprador}'
                      : 'Vendedor: ${pedido.nombreVendedor}',
                  style: const TextStyle(
                    color: Color(0xFF7C827E),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _Items extends StatelessWidget {
  const _Items({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFECEFED)),
    ),
    child: Column(
      children: [
        for (final item in pedido.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '×${item.cantidad}',
                  style: const TextStyle(color: Color(0xFF7C827E)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Bs ${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Totales extends StatelessWidget {
  const _Totales({required this.pedido});

  final Pedido pedido;

  Widget _fila(String etiqueta, double valor, {bool fuerte = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            color: fuerte ? const Color(0xFF202221) : const Color(0xFF7C827E),
            fontWeight: fuerte ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          'Bs ${valor.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: fuerte ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F7F8),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        _fila('Importe', pedido.subtotal),
        _fila('Costo de entrega', pedido.costoEntrega),
        const Divider(color: Color(0xFFE2E5E3)),
        _fila('Total', pedido.total, fuerte: true),
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(Icons.payments_outlined, size: 15, color: Color(0xFF7C827E)),
            SizedBox(width: 6),
            Text(
              'Pago coordinado entre ustedes',
              style: TextStyle(color: Color(0xFF7C827E), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icono, size: 19, color: const Color(0xFF7C827E)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
            ),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
}
