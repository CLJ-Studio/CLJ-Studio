import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../datos/repositorio_pedidos.dart';
import '../diseno/etiqueta_estado_pedido.dart';
import '../modelos/pedido.dart';
import 'pantalla_chat_pedido.dart';

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

  String? get _miId => Supabase.instance.client.auth.currentUser?.id;

  bool _soyElVendedor(Pedido pedido) => pedido.vendedorId == _miId;

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
    if (texto.contains('YA_LO_MARCASTE')) {
      return 'Ya marcaste la entrega. Falta que la confirme la otra parte.';
    }
    return 'No se pudo completar la acción.';
  }

  /// Pregunta antes de cancelar.
  ///
  /// Es la única acción del pedido que no se puede deshacer y que deja a la
  /// otra parte peor de lo que estaba: quien esperaba se queda sin nada.
  Future<void> _confirmarCancelacion(Pedido pedido) async {
    final soyVendedor = _soyElVendedor(pedido);
    final otro = soyVendedor
        ? pedido.nombreComprador.split(' ').first
        : pedido.nombreVendedor.split(' ').first;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text(
          soyVendedor
              ? 'Se avisará a $otro de que no vas a poder entregarlo, y las '
                    'unidades vuelven a tu stock.'
              : 'Se avisará a $otro de que ya no lo quieres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3453B),
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    await _ejecutar(() => _repositorio.cancelar(pedido.id));
  }

  /// Abre la conversación de este pedido.
  ///
  /// El chat vive dentro de la aplicación y se cierra solo cuando la entrega
  /// queda confirmada: lo acordado se queda junto al pedido en vez de
  /// perderse en un hilo de WhatsApp, y nadie tiene que dar su teléfono.
  void _abrirChat(Pedido pedido, bool soyVendedor) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatPedido(
          pedidoId: pedido.id,
          contraparte: soyVendedor
              ? pedido.nombreComprador
              : pedido.nombreVendedor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
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
          return const Center(child: IndicadorCarga());
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
            backgroundColor: const Color(0xFF138A5B),
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
          onPressed: _ocupado ? null : () => _abrirChat(pedido, soyVendedor),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF138A5B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.forum_rounded),
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
          // Lo puede marcar cualquiera de los dos, pero no dicen lo mismo:
          // uno entrega y el otro recibe.
          label: Text(
            soyVendedor ? 'Marcar como entregado' : 'Marcar como recibido',
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _ocupado ? null : () => _confirmarCancelacion(pedido),
          child: const Text(
            'Cancelar pedido',
            style: TextStyle(color: Color(0xFFB3453B)),
          ),
        ),
      ];
    }

    // Alguien ya dijo que la entrega está hecha; falta la otra mitad.
    if (pedido.estado == EstadoPedido.porConfirmar) {
      return [
        _AvisoConfirmacion(
          meToca: pedido.meTocaConfirmar(_miId),
          soyVendedor: soyVendedor,
          otro: soyVendedor
              ? pedido.nombreComprador.split(' ').first
              : pedido.nombreVendedor.split(' ').first,
        ),
        const SizedBox(height: 14),
        if (pedido.meTocaConfirmar(_miId))
          FilledButton.icon(
            onPressed: _ocupado
                ? null
                : () =>
                      _ejecutar(() => _repositorio.confirmarEntrega(pedido.id)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF138A5B),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(soyVendedor ? 'Sí, lo entregué' : 'Sí, lo recibí'),
          ),
        const SizedBox(height: 10),
        // El contacto sigue abierto: si algo no cuadra, se habla antes de
        // confirmar. Sin esto la única salida sería no responder.
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _abrirChat(pedido, soyVendedor),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF138A5B),
            side: const BorderSide(color: Color(0xFFAECBB3)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.forum_outlined),
          label: Text(
            soyVendedor
                ? 'Escribir a ${pedido.nombreComprador.split(' ').first}'
                : 'Escribir a ${pedido.nombreVendedor.split(' ').first}',
          ),
        ),
      ];
    }

    return const [];
  }
}

/// Explica de quién es el turno mientras el pedido espera confirmación.
///
/// Es la única insistencia que hay: un aviso en la pantalla. No se manda una
/// notificación por hora a nadie.
class _AvisoConfirmacion extends StatelessWidget {
  const _AvisoConfirmacion({
    required this.meToca,
    required this.soyVendedor,
    required this.otro,
  });

  final bool meToca;
  final bool soyVendedor;
  final String otro;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: oscuro ? const Color(0xFF2A2519) : const Color(0xFFFDF3E2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: oscuro ? const Color(0xFF4A4023) : const Color(0xFFF0DFC0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            color: Color(0xFFC98A2B),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !meToca
                      ? 'Esperando a $otro'
                      : soyVendedor
                      ? '¿Entregaste el pedido?'
                      : '¿Recibiste tu pedido?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFC98A2B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  !meToca
                      ? 'Ya lo marcaste. Falta que $otro lo confirme.'
                      : soyVendedor
                      ? '$otro marcó el pedido como recibido. Confírmalo '
                            'para cerrarlo.'
                      : '$otro marcó el pedido como entregado. Confírmalo '
                            'para cerrarlo.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: oscuro
                        ? const Color(0xFFBFB49A)
                        : const Color(0xFF8A7550),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      border: Border.all(color: Theme.of(context).dividerColor),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        _fila('Importe', pedido.subtotal),
        _fila('Costo de entrega', pedido.costoEntrega),
        Divider(color: Theme.of(context).dividerColor),
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
  const _Dato({required this.icono, required this.titulo, required this.valor});

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
            Text(titulo, style: const TextStyle(fontSize: 12)),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
}
