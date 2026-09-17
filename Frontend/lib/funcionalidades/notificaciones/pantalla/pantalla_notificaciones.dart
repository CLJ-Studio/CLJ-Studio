import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../logica/controlador_notificaciones.dart';
import '../logica/navegador_notificaciones.dart';
import '../modelos/notificacion.dart';

/// Centro de avisos del usuario, con una jerarquia visual inspirada en iOS.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controlador.cargar();
    });
  }

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
    if (diferencia.inHours < 1) return '${diferencia.inMinutes} min';
    if (diferencia.inDays < 1) return '${diferencia.inHours} h';
    if (diferencia.inDays == 1) return 'Ayer';
    if (diferencia.inDays < 7) return '${diferencia.inDays} d';
    return '${(diferencia.inDays / 7).floor()} sem';
  }

  Map<String, List<Notificacion>> _agrupar(List<Notificacion> elementos) {
    final grupos = <String, List<Notificacion>>{};
    for (final notificacion in elementos) {
      final dias = DateTime.now().difference(notificacion.creadaEn).inDays;
      final titulo = dias == 0
          ? 'Hoy'
          : dias < 7
          ? 'Esta semana'
          : 'Anteriores';
      grupos.putIfAbsent(titulo, () => []).add(notificacion);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: controlador,
        builder: (context, _) {
          if (controlador.cargando && controlador.notificaciones.isEmpty) {
            return const Center(child: IndicadorCarga());
          }

          final grupos = _agrupar(controlador.notificaciones);
          return RefreshIndicator.adaptive(
            color: const Color(0xFF474646),
            onRefresh: controlador.cargar,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _Encabezado(
                  alMarcarTodas: controlador.noLeidas == 0
                      ? null
                      : controlador.marcarTodasLeidas,
                ),
                if (controlador.notificaciones.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _SinNotificaciones(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 44),
                    sliver: SliverToBoxAdapter(
                      child: ContenidoCentrado(
                        anchoMaximo: 620,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final grupo in grupos.entries) ...[
                              _TituloSeccion(titulo: grupo.key),
                              const SizedBox(height: 10),
                              for (var i = 0; i < grupo.value.length; i++)
                                _EntradaAnimada(
                                  indice: i,
                                  child: _TarjetaNotificacion(
                                    notificacion: grupo.value[i],
                                    hace: _hace(grupo.value[i].creadaEn),
                                    alTocar: () => _abrir(grupo.value[i]),
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.alMarcarTodas});

  final VoidCallback? alMarcarTodas;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      stretch: true,
      leading: Padding(
        padding: const EdgeInsets.all(7),
        child: _BotonCircular(
          tooltip: 'Volver',
          icono: Icons.arrow_back_ios_new_rounded,
          alTocar: () => Navigator.maybePop(context),
        ),
      ),
      title: const Text(
        'Notificaciones',
        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.7),
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: alMarcarTodas == null
              ? const SizedBox(width: 12)
              : Padding(
                  key: const ValueKey('marcar-todas'),
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: alMarcarTodas,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Leer todas'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A08A1),
                      backgroundColor: const Color(0x144A08A1),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BotonCircular extends StatelessWidget {
  const _BotonCircular({
    required this.tooltip,
    required this.icono,
    required this.alTocar,
  });

  final String tooltip;
  final IconData icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: alTocar,
    icon: Icon(icono, size: 19),
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: .86),
      shadowColor: Color(0xFF474646).withValues(alpha: .12),
      elevation: 1,
    ),
  );
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      titulo.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .46),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.15,
      ),
    ),
  );
}

class _EntradaAnimada extends StatelessWidget {
  const _EntradaAnimada({required this.indice, required this.child});

  final int indice;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 330 + (indice.clamp(0, 5) * 65)),
    curve: Curves.easeOutCubic,
    tween: Tween(begin: 0, end: 1),
    builder: (context, valor, child) => Opacity(
      opacity: valor,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - valor)),
        child: child,
      ),
    ),
    child: child,
  );
}

class _TarjetaNotificacion extends StatelessWidget {
  const _TarjetaNotificacion({
    required this.notificacion,
    required this.hace,
    required this.alTocar,
  });

  final Notificacion notificacion;
  final String hace;
  final VoidCallback alTocar;

  Color get _colorIcono => switch (notificacion.tipo) {
    'pedido_recibido' => const Color(0xFFE95026),
    'pedido_aceptado' || 'pedido_entregado' => const Color(0xFF098B67),
    'pedido_rechazado' || 'pedido_cancelado' => const Color(0xFFB2194B),
    'pedido_vencido' => const Color(0xFFE09A18),
    'mensaje_pedido' || 'nuevo_local' => const Color(0xFF8B5CD6),
    'entrega_por_confirmar' => const Color(0xFF3449A5),
    'ubicacion_pendiente' => const Color(0xFFE57B35),
    _ => const Color(0xFF4A08A1),
  };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final colorIcono = _colorIcono;
    final superficie = oscuro
        ? tema.colorScheme.surfaceContainerHighest
        : tema.colorScheme.surface;
    final fondoTarjeta = Color.alphaBlend(
      colorIcono.withValues(
        alpha: oscuro ? .13 : (notificacion.leida ? .035 : .065),
      ),
      superficie,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(26),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
            decoration: BoxDecoration(
              color: fondoTarjeta,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF474646).withValues(
                    alpha: oscuro ? .16 : (notificacion.leida ? .025 : .05),
                  ),
                  blurRadius: notificacion.leida ? 10 : 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: colorIcono,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorIcono.withValues(alpha: .24),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        notificacion.icono,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const Spacer(),
                    if (!notificacion.leida) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colorIcono,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      hace,
                      style: TextStyle(
                        color: tema.colorScheme.onSurface.withValues(alpha: .5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  notificacion.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: notificacion.leida
                        ? FontWeight.w700
                        : FontWeight.w900,
                    fontSize: 16.5,
                    height: 1.2,
                    letterSpacing: -.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notificacion.cuerpo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tema.colorScheme.onSurface.withValues(alpha: .68),
                    fontSize: 14,
                    height: 1.38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SinNotificaciones extends StatelessWidget {
  const _SinNotificaciones();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x26474646), Color(0x0D474646)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x22474646)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 42,
              color: Color(0xFF848381),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Todo está al día',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te avisaremos cuando haya novedades sobre tus pedidos y el campus.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .5),
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
}
