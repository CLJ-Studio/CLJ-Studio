import 'package:flutter/material.dart';

import '../logica/controlador_instalacion.dart';
import 'aviso_instalacion.dart';

/// Entrada en Configuracion para instalar la app.
///
/// Existe aparte del aviso del inicio porque aquel se puede descartar, y
/// quien cambie de idea despues necesita un sitio donde encontrarlo. Se
/// oculta sola cuando ya esta instalada o el navegador no lo permite.
class OpcionInstalarApp extends StatelessWidget {
  const OpcionInstalarApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ControladorInstalacion.instancia,
    builder: (context, _) {
      final controlador = ControladorInstalacion.instancia;
      if (!controlador.disponible) return const SizedBox.shrink();

      return ListTile(
        leading: const Icon(Icons.install_mobile_rounded),
        title: const Text(
          'Instalar en tu teléfono',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          controlador.requiereGestoManual
              ? 'Necesario en iPhone para recibir notificaciones'
              : 'Ábrela desde la pantalla de inicio',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            // Sin `alDescartar`: aqui no tiene sentido cerrarla para
            // siempre, se sale con el gesto de la hoja.
            child: const TarjetaInstalacion(),
          ),
        ),
      );
    },
  );
}
