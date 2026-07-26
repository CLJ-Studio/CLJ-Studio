import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Espera la futura confirmación del vendedor enviada por el backend.
class PantallaContactandoVendedor extends StatelessWidget {
  const PantallaContactandoVendedor({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7F3),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        tooltip: 'Cancelar contacto',
        // Al conectar el backend, aquí también se cancelará la solicitud.
        onPressed: () => Navigator.of(context).pop(false),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Se repite hasta que el backend notifique la aceptación.
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF252825),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enviamos tu pedido y estamos esperando que el vendedor lo acepte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF747B76),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                const _IndicadorEspera(),
              ],
            ),
          ),
        ),
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
