import 'package:flutter/material.dart';

import '../../../elementos_compartidos/marca/marca_u_market.dart';
import '../logica/controlador_instalacion.dart';

/// Invitacion a instalar la app, adaptada a lo que el navegador permite.
///
/// En Android abre el dialogo del sistema; en iPhone no existe tal dialogo,
/// asi que explica el gesto manual paso a paso.
class AvisoInstalacion extends StatelessWidget {
  const AvisoInstalacion({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ControladorInstalacion.instancia,
    builder: (context, _) {
      final controlador = ControladorInstalacion.instancia;
      if (!controlador.mostrarAviso) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TarjetaInstalacion(alDescartar: controlador.descartar),
      );
    },
  );
}

/// El contenido en si, sin la decision de mostrarlo.
///
/// Se separa porque Configuracion lo ofrece siempre, incluso si en el inicio
/// ya lo descartaron.
class TarjetaInstalacion extends StatelessWidget {
  const TarjetaInstalacion({this.alDescartar, super.key});

  /// Si se omite, la tarjeta no se puede cerrar (caso de Configuracion).
  final VoidCallback? alDescartar;

  Future<void> _instalar(BuildContext context) async {
    final acepto = await ControladorInstalacion.instancia.instalar();
    if (!acepto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puedes instalarla más tarde desde Configuración.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final controlador = ControladorInstalacion.instancia;
    final manual = controlador.requiereGestoManual;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      decoration: BoxDecoration(
        color: tema.colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.install_mobile_rounded,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextoConMarcaUMarket(
                  'Instala U market',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (alDescartar case final VoidCallback cerrar)
                IconButton(
                  tooltip: 'Ahora no',
                  visualDensity: VisualDensity.compact,
                  onPressed: cerrar,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            manual
                // En iOS el push solo funciona instalada, asi que la razon
                // de peso va por delante del gesto.
                ? 'En iPhone las notificaciones de tus pedidos solo llegan '
                      'si la app está en tu pantalla de inicio.'
                : 'Ábrela desde tu pantalla de inicio, a pantalla completa '
                      'y con avisos de tus pedidos.',
            style: TextStyle(
              color: tema.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (manual)
            const _PasosIOS()
          else
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () => _instalar(context),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text('Instalar'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Safari no permite lanzar la instalacion por codigo: el unico camino es
/// que la persona lo haga a mano, asi que se enumera tal cual lo vera.
class _PasosIOS extends StatelessWidget {
  const _PasosIOS();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Paso(
        numero: '1',
        icono: Icons.ios_share_rounded,
        texto: 'Toca Compartir, abajo en Safari',
      ),
      _Paso(
        numero: '2',
        icono: Icons.add_box_outlined,
        texto: 'Elige "Añadir a pantalla de inicio"',
      ),
      _Paso(
        numero: '3',
        icono: Icons.check_rounded,
        texto: 'Abre U market desde el ícono nuevo',
      ),
    ],
  );
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.icono, required this.texto});

  final String numero;
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tema.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              numero,
              style: TextStyle(
                color: tema.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icono, size: 18, color: tema.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextoConMarcaUMarket(
              texto,
              style: TextStyle(
                color: tema.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
