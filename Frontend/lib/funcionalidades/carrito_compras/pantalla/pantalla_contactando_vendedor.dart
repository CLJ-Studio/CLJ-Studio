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
                        backgroundLoading: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Contactando con el vendedor',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
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
                    const SizedBox(height: 26),
                    // Deja claro que salir no pierde el pedido: antes el
                    // boton de atras lo cancelaba y nadie se atrevia a tocarlo.
                    const Text(
                      'Puedes seguir usando la app mientras tanto. Tu pedido '
                      'te espera en Pedidos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9AA29C), fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _volver,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF55785A),
                      ),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text(
                        'Seguir explorando',
                        style: TextStyle(fontWeight: FontWeight.w800),
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

/// Refuerza visualmente que la solicitud continúa pendiente.
class _IndicadorEspera extends StatelessWidget {
  const _IndicadorEspera();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 17, height: 17, child: IndicadorCarga(tamanio: 17)),
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
        style: TextStyle(fontSize: 12),
      );
    }

    return Text(
      'El vendedor tiene ${restante.inMinutes + 1} min para responder.',
      style: const TextStyle(fontSize: 12),
    );
  }
}
