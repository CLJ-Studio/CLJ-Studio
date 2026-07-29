import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../logica/controlador_notificaciones.dart';
import '../logica/navegador_notificaciones.dart';
import '../modelos/notificacion.dart';

/// Lista de avisos del usuario; tocar uno lo marca leido y abre su pedido.
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  final controlador = ControladorNotificaciones.instancia;

  @override
  void initState() {
    super.initState();
    controlador.cargar();
  }

  /// Cada aviso lleva a lo suyo; la resolucion vive en NavegadorNotificaciones
  /// porque el mismo destino tambien llega como deep link desde el push del
  /// sistema operativo.
  Future<void> _abrir(Notificacion notificacion) async {
    controlador.marcarLeida(notificacion);
    await NavegadorNotificaciones.abrir(
      context,
      pedidoId: notificacion.pedidoId,
      localId: notificacion.localId,
      productoId: notificacion.productoId,
    );
  }

  String _hace(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inMinutes < 1) return 'Ahora';
    if (diferencia.inHours < 1) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inDays < 1) return 'Hace ${diferencia.inHours} h';
    return 'Hace ${diferencia.inDays} d';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Notificaciones',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        AnimatedBuilder(
          animation: controlador,
          builder: (context, _) => controlador.noLeidas == 0
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: controlador.marcarTodasLeidas,
                  child: const Text(
                    'Marcar leídas',
                    style: TextStyle(
                      color: Color(0xFF5C8A63),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: controlador,
      builder: (context, _) {
        if (controlador.cargando && controlador.notificaciones.isEmpty) {
          return const Center(child: IndicadorCarga());
        }
        if (controlador.notificaciones.isEmpty) {
          return const _SinNotificaciones();
        }
        return RefreshIndicator(
          onRefresh: controlador.cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
            children: [
              ContenidoCentrado(
                anchoMaximo: 620,
                child: Column(
                  children: [
                    for (final notificacion in controlador.notificaciones)
                      _Fila(
                        notificacion: notificacion,
                        hace: _hace(notificacion.creadaEn),
                        alTocar: () => _abrir(notificacion),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.notificacion,
    required this.hace,
    required this.alTocar,
  });

  final Notificacion notificacion;
  final String hace;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: notificacion.leida
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primary.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: alTocar,
        leading: CircleAvatar(
          foregroundColor: const Color(0xFF5C8A63),
          child: Icon(notificacion.icono, size: 21),
        ),
        title: Text(
          notificacion.titulo,
          style: TextStyle(
            fontWeight: notificacion.leida ? FontWeight.w600 : FontWeight.w900,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          notificacion.cuerpo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(hace, style: const TextStyle(fontSize: 11)),
      ),
    ),
  );
}

class _SinNotificaciones extends StatelessWidget {
  const _SinNotificaciones();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: .12),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 42,
              color: Color(0xFF6F9A76),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Nada nuevo por ahora',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aquí verás tus pedidos y las novedades del campus.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7B817D)),
          ),
        ],
      ),
    ),
  );
}
