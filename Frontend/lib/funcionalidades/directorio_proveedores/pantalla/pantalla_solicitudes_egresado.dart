import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../datos/repositorio_directorio.dart';
import '../modelos/solicitud_egresado.dart';

/// Donde los admins aprueban o rechazan a quien dice que ya se graduo.
///
/// Aprobar es lo que hace que la UPSA lo vea como egresado en el directorio:
/// por eso no lo marca cada uno.
class PantallaSolicitudesEgresado extends StatefulWidget {
  const PantallaSolicitudesEgresado({
    this.repositorio = const RepositorioDirectorio(),
    super.key,
  });

  final RepositorioDirectorio repositorio;

  @override
  State<PantallaSolicitudesEgresado> createState() =>
      _PantallaSolicitudesEgresadoState();
}

class _PantallaSolicitudesEgresadoState
    extends State<PantallaSolicitudesEgresado> {
  List<SolicitudEgresado>? _solicitudes;
  bool _fallo = false;

  /// Las que se estan resolviendo: sus botones se apagan mientras tanto.
  final _resolviendo = <String>{};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _fallo = false);
    try {
      final solicitudes = await widget.repositorio.solicitudesEgresado();
      if (mounted) setState(() => _solicitudes = solicitudes);
    } catch (_) {
      if (mounted) setState(() => _fallo = true);
    }
  }

  Future<void> _resolver(SolicitudEgresado solicitud, bool aprobar) async {
    setState(() => _resolviendo.add(solicitud.usuarioId));
    try {
      await widget.repositorio.resolverEgresado(
        solicitud.usuarioId,
        aprobar: aprobar,
      );
      if (!mounted) return;
      setState(
        () => _solicitudes = [
          for (final otra in _solicitudes ?? const <SolicitudEgresado>[])
            if (otra.usuarioId != solicitud.usuarioId) otra,
        ],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aprobar
                ? '${solicitud.nombre} ya figura como egresado.'
                : 'Solicitud de ${solicitud.nombre} rechazada.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resolviendo.remove(solicitud.usuarioId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Solicitudes de egresados',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: _cuerpo(context),
  );

  Widget _cuerpo(BuildContext context) {
    if (_fallo) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudieron cargar las solicitudes.'),
            const SizedBox(height: 14),
            FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final solicitudes = _solicitudes;
    if (solicitudes == null) return const Center(child: IndicadorCarga());

    final apagado = Theme.of(context).textTheme.bodyMedium?.color;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Text(
                'Aprueba solo a quien sepas que se graduó: la UPSA lo verá '
                'como egresado en el directorio de proveedores. El año de '
                'ingreso sale de su número de registro.',
                style: TextStyle(color: apagado, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (solicitudes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No hay solicitudes pendientes.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final solicitud in solicitudes) ...[
                  _TarjetaSolicitud(
                    solicitud: solicitud,
                    ocupada: _resolviendo.contains(solicitud.usuarioId),
                    alAprobar: () => _resolver(solicitud, true),
                    alRechazar: () => _resolver(solicitud, false),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({
    required this.solicitud,
    required this.ocupada,
    required this.alAprobar,
    required this.alRechazar,
  });

  final SolicitudEgresado solicitud;
  final bool ocupada;
  final VoidCallback alAprobar;
  final VoidCallback alRechazar;

  static const _grafito = Color(0xFF474646);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final apagado = tema.textTheme.bodyMedium?.color;
    final pedido = solicitud.pedidoEn;
    final detalle = [
      ?solicitud.carrera,
      if (solicitud.anioIngreso case final int anio) 'Ingresó en $anio',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E1D5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            solicitud.nombre,
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(detalle, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 3),
          Text(
            [
              solicitud.correo,
              if (pedido != null)
                'pedido el ${pedido.day}/${pedido.month}/${pedido.year}',
            ].join(' · '),
            style: TextStyle(color: apagado, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: ocupada ? null : alRechazar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _grafito,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: ocupada ? null : alAprobar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _grafito,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Aprobar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
