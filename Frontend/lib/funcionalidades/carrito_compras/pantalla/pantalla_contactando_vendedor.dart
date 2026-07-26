import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../pedidos/datos/repositorio_pedidos.dart';
import '../../pedidos/modelos/pedido.dart';
import '../../pedidos/pantalla/pantalla_detalle_pedido.dart';

/// Espera en tiempo real la respuesta del vendedor.
///
/// Antes era una animacion infinita sin conexion al backend. Ahora escucha
/// la fila del pedido por Realtime: en cuanto el vendedor acepta, rechaza,
/// o el barrido de cron lo vence, la pantalla reacciona sola.
class PantallaContactandoVendedor extends StatefulWidget {
  const PantallaContactandoVendedor({required this.pedidoId, super.key});

  final String pedidoId;

  @override
  State<PantallaContactandoVendedor> createState() =>
      _PantallaContactandoVendedorState();
}

class _PantallaContactandoVendedorState
    extends State<PantallaContactandoVendedor> {
  static const _repositorio = RepositorioPedidos();

  late final Stream<Pedido?> _pedido = _repositorio.escuchar(widget.pedidoId);
  bool _cancelando = false;

  Future<void> _cancelar() async {
    setState(() => _cancelando = true);
    try {
      await _repositorio.cancelar(widget.pedidoId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cancelar el pedido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _abrirDetalle(String pedidoId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetallePedido(pedidoId: pedidoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7F3),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        tooltip: 'Cancelar pedido',
        onPressed: _cancelando ? null : _cancelar,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: SafeArea(
      child: StreamBuilder<Pedido?>(
        stream: _pedido,
        builder: (context, snapshot) {
          final pedido = snapshot.data;

          // El vendedor ya respondio: se pasa al detalle, que muestra el
          // resultado y habilita WhatsApp si fue aceptado.
          if (pedido != null && pedido.estado != EstadoPedido.solicitado) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _abrirDetalle(pedido.id);
            });
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 310,
                      height: 310,
                      child: Lottie.asset(
                        'assets/animations/contactando-vendedor.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        frameRate: FrameRate.composition,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Contactando con el vendedor',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF252825),
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enviamos tu pedido y estamos esperando que el vendedor '
                      'lo acepte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF747B76),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _IndicadorEspera(),
                    if (pedido != null) ...[
                      const SizedBox(height: 16),
                      _CuentaRegresiva(venceEn: pedido.venceEn),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Refuerza visualmente que la solicitud continúa pendiente.
class _IndicadorEspera extends StatelessWidget {
  const _IndicadorEspera();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFE5F0E6),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFF5C8A63),
          ),
        ),
        SizedBox(width: 10),
        Text(
          'Esperando confirmación',
          style: TextStyle(
            color: Color(0xFF527A59),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

/// Muestra cuanto le queda al vendedor para responder antes del vencimiento.
class _CuentaRegresiva extends StatelessWidget {
  const _CuentaRegresiva({required this.venceEn});

  final DateTime venceEn;

  @override
  Widget build(BuildContext context) {
    final restante = venceEn.difference(DateTime.now());
    if (restante.isNegative) {
      return const Text(
        'El tiempo de respuesta terminó.',
        style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
      );
    }

    return Text(
      'El vendedor tiene ${restante.inMinutes + 1} min para responder.',
      style: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
    );
  }
}
