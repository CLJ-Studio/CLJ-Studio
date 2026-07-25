import 'package:flutter/material.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Hero visual del detalle del local.
class EncabezadoDetalleLocal extends StatelessWidget {
  const EncabezadoDetalleLocal({required this.local, super.key});
  final LocalUniversitario local;

  String get _imagen => switch (local.id) {
    'cafeteria' => 'assets/images/real/coffee3.jpg',
    'snack' => 'assets/images/real/hamburger2.jpg',
    'tech' => 'assets/images/real/western2.jpg',
    'libreria' => 'assets/images/real/bakery.jpg',
    _ => 'assets/images/real/breakfast.jpg',
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 210,
        width: double.infinity,
        child: Image.asset(
          _imagen,
          fit: BoxFit.cover,
          cacheWidth: 1400,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => Center(
            child: Text(local.emoji, style: const TextStyle(fontSize: 90)),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local.nombre,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(local.descripcion),
            const SizedBox(height: 10),
            Text(
              '⭐ ${local.calificacion}  ·  ${local.tiempoEstimado}  ·  Entrega Bs ${local.costoEntrega.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    ],
  );
}
