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
        child: IconButton.filledTonal(
          tooltip: 'Notificaciones',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PantallaNotificaciones(),
            ),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      );
    },
  );
}
