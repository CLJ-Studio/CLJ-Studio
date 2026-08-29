import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
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
  bool _cancelandoSolicitud = false;

  /// Salir NO cancela nada: el pedido sigue vivo esperando respuesta. Para
  /// cancelar de verdad esta el boton en Pedidos.
  ///
  /// Se vuelve hasta la raiz y no con un pop simple: a esta pantalla se
  /// llega reemplazando la del carrito, asi que un pop dejaba al usuario en
  /// una pila intermedia y parecia que el boton no hacia nada.
  void _volver() => Navigator.of(context).popUntil((ruta) => ruta.isFirst);

  void _abrirDetalle(String pedidoId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetallePedido(pedidoId: pedidoId),
      ),
    );
  }

  Future<void> _cancelarSolicitud() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.close_rounded,
          color: Color(0xFFAE7960),
          size: 30,
        ),
        title: const Text('¿Cancelar solicitud?', textAlign: TextAlign.center),
        content: const Text(
          'El vendedor dejará de recibir este pedido.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAE7960),
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;
    setState(() => _cancelandoSolicitud = true);
    try {
      await _repositorio.cancelar(widget.pedidoId);
      if (mounted) _volver();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelandoSolicitud = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo cancelar. Intenta nuevamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        tooltip: 'Volver',
        onPressed: _volver,
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
          if (!_cancelandoSolicitud &&
              pedido != null &&
              pedido.estado != EstadoPedido.solicitado) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _abrirDetalle(pedido.id);
            });
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Lottie.asset(
                        'assets/animations/contactando-vendedor.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        frameRate: FrameRate.composition,
                        backgroundLoading: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esperando al vendedor',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tu solicitud ya fue enviada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF848381),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _EstadoSolicitud(venceEn: pedido?.venceEn),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _volver,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF474646),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.explore_outlined, size: 20),
                        label: const Text(
                          'Seguir explorando',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: _cancelandoSolicitud
                            ? null
                            : _cancelarSolicitud,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFAE7960),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _cancelandoSolicitud
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFAE7960),
                                ),
                              )
                            : const Text(
                                'Cancelar solicitud',
                                style: TextStyle(fontWeight: FontWeight.w800),
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
  );
}

/// Reune estado y tiempo de respuesta sin repetir explicaciones.
class _EstadoSolicitud extends StatelessWidget {
  const _EstadoSolicitud({this.venceEn});

  final DateTime? venceEn;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
      ),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 19,
          height: 19,
          child: IndicadorCarga(tamanio: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esperando confirmación',
                style: TextStyle(
                  color: Color(0xFF474646),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (venceEn != null) ...[
                const SizedBox(height: 2),
                _CuentaRegresiva(venceEn: venceEn!),
              ],
            ],
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
        'Tiempo de respuesta finalizado',
        style: TextStyle(color: Color(0xFF848381), fontSize: 12),
      );
    }

    return Text(
      '${restante.inMinutes + 1} min restantes',
      style: const TextStyle(color: Color(0xFF848381), fontSize: 12),
    );
  }
}
