import 'dart:ui';

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
    controlador.cargar();
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
    final oscuro = tema.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: oscuro
          ? const Color(0xFF090B0A)
          : const Color(0xFFF5F6F3),
      body: AnimatedBuilder(
        animation: controlador,
        builder: (context, _) {
          if (controlador.cargando && controlador.notificaciones.isEmpty) {
            return const Center(child: IndicadorCarga());
          }

          final grupos = _agrupar(controlador.notificaciones);
          return RefreshIndicator.adaptive(
            color: const Color(0xFF138A5B),
            onRefresh: controlador.cargar,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _Encabezado(
                  cantidadNoLeidas: controlador.noLeidas,
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
                            if (controlador.noLeidas > 0) ...[
                              _ResumenPendientes(
                                cantidad: controlador.noLeidas,
                              ),
                              const SizedBox(height: 28),
                            ],
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
  const _Encabezado({
    required this.cantidadNoLeidas,
    required this.alMarcarTodas,
  });

  final int cantidadNoLeidas;
  final VoidCallback? alMarcarTodas;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar.large(
      backgroundColor: oscuro
          ? const Color(0xE6090B0A)
          : const Color(0xEAF5F6F3),
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
                      foregroundColor: const Color(0xFF527A59),
                      backgroundColor: const Color(0x18138A5B),
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
      shadowColor: Colors.black.withValues(alpha: .12),
      elevation: 1,
    ),
  );
}

class _ResumenPendientes extends StatelessWidget {
  const _ResumenPendientes({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF527F5A), Color(0xFF719D77)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24527F5A),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .2)),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cantidad ${cantidad == 1 ? 'novedad' : 'novedades'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: -.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Todo lo importante de tus pedidos, en un solo lugar.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .78),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    'pedido_rechazado' || 'pedido_cancelado' => const Color(0xFFB65D54),
    'pedido_vencido' || 'entrega_por_confirmar' => const Color(0xFFC08335),
    'nuevo_local' => const Color(0xFF6B70B5),
    'ubicacion_pendiente' => const Color(0xFF3E8291),
    _ => const Color(0xFF138A5B),
  };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oscuro = tema.brightness == Brightness.dark;
    final colorIcono = _colorIcono;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(14, 15, 13, 15),
            decoration: BoxDecoration(
              color: oscuro
                  ? const Color(0xFF171A18)
                  : notificacion.leida
                  ? Colors.white.withValues(alpha: .72)
                  : Colors.white.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: notificacion.leida
                    ? tema.dividerColor.withValues(alpha: .08)
                    : colorIcono.withValues(alpha: .16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: oscuro ? .18 : (notificacion.leida ? .025 : .065),
                  ),
                  blurRadius: notificacion.leida ? 12 : 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorIcono.withValues(alpha: oscuro ? .2 : .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(notificacion.icono, color: colorIcono, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              notificacion.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: notificacion.leida
                                    ? FontWeight.w700
                                    : FontWeight.w900,
                                fontSize: 15.5,
                                letterSpacing: -.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!notificacion.leida) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: colorIcono,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorIcono.withValues(alpha: .3),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                          ],
                          Text(
                            hace,
                            style: TextStyle(
                              color: tema.colorScheme.onSurface.withValues(
                                alpha: .43,
                              ),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notificacion.cuerpo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tema.colorScheme.onSurface.withValues(
                            alpha: .64,
                          ),
                          fontSize: 13,
                          height: 1.38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notificacion.llevaAAlgunSitio) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 27),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: tema.colorScheme.onSurface.withValues(alpha: .25),
                    ),
                  ),
                ],
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
                colors: [Color(0x26138A5B), Color(0x0D138A5B)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x22138A5B)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 42,
              color: Color(0xFF628C69),
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
