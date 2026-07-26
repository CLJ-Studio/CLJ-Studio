import 'package:flutter/material.dart';

import '../../favoritos/logica/controlador_favoritos.dart';
import '../../favoritos/pantalla/pantalla_favoritos.dart';

/// Acceso desde Ajustes a los productos marcados con corazón.
class OpcionFavoritos extends StatelessWidget {
  const OpcionFavoritos({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = ControladorFavoritos.instancia;
    return AnimatedBuilder(
      animation: controlador,
      builder: (context, _) => ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PantallaFavoritos()),
        ),
        leading: const Icon(
          Icons.favorite_border_rounded,
          color: Color(0xFF5C8A63),
        ),
        title: const Text('Favoritos'),
        subtitle: Text(
          controlador.cantidad == 0
              ? 'Productos que te gustan'
              : '${controlador.cantidad} guardados',
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
