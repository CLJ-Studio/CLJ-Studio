import 'package:flutter/material.dart';

import '../logica/controlador_notificaciones.dart';
import '../pantalla/pantalla_notificaciones.dart';

/// Campana del encabezado con el contador de no leidas.
class BotonCampana extends StatelessWidget {
  const BotonCampana({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ControladorNotificaciones.instancia,
    builder: (context, _) {
      final sinLeer = ControladorNotificaciones.instancia.noLeidas;
      return Badge(
        isLabelVisible: sinLeer > 0,
        label: Text('$sinLeer'),
        child: IconButton(
          tooltip: 'Notificaciones',
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF202220),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PantallaNotificaciones(),
            ),
          ),
          icon: const Icon(Icons.notifications_rounded, size: 27, weight: 700),
        ),
      );
    },
  );
}
