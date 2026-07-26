import 'package:flutter/material.dart';

import '../../publicar_producto/logica/controlador_mis_publicaciones.dart';
import '../../publicar_producto/pantalla/pantalla_mis_publicaciones.dart';

/// Acceso al historial personal de publicaciones.
class OpcionMisPublicaciones extends StatelessWidget {
  const OpcionMisPublicaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = ControladorMisPublicaciones.instancia;
    return AnimatedBuilder(
      animation: controlador,
      builder: (context, _) => ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PantallaMisPublicaciones(),
          ),
        ),
        leading: const Icon(Icons.grid_on_rounded, color: Color(0xFF5C8A63)),
        title: const Text('Mis publicaciones'),
        subtitle: Text(
          controlador.cantidad == 0
              ? 'Todo lo que publiques'
              : '${controlador.cantidad} publicadas',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controlador.cantidad > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EFE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${controlador.cantidad}',
                  style: const TextStyle(
                    color: Color(0xFF5C8A63),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
