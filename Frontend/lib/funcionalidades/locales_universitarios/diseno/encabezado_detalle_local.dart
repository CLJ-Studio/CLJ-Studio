import 'package:flutter/material.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Hero visual del detalle del local: su logo real o un lienzo con su emoji.
class EncabezadoDetalleLocal extends StatelessWidget {
  const EncabezadoDetalleLocal({required this.local, super.key});
  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 210,
        width: double.infinity,
        child: switch (local.logoUrl) {
          final String url => Image.network(
            url,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, _, _) => _LienzoEmoji(local: local),
          ),
          _ => _LienzoEmoji(local: local),
        },
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local.esPersonal ? local.vendedorNombre : local.nombre,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            // El nombre de la persona detras del negocio: en un campus la
            // confianza viene de saber a quien le estas comprando.
            if (!local.esPersonal && local.vendedorNombre.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Por ${local.vendedorNombre}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(local.descripcion),
            const SizedBox(height: 10),
            Text(
              local.esPersonal
                  ? 'Vendedor independiente'
                  : '${local.tiempoEstimado}  ·  Entrega Bs ${local.costoEntrega.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    ],
  );
}

/// Portada de respaldo con el color e icono del propio local.
class _LienzoEmoji extends StatelessWidget {
  const _LienzoEmoji({required this.local});
  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Color(local.colorHexadecimal),
    child: Center(
      child: Text(local.emoji, style: const TextStyle(fontSize: 90)),
    ),
  );
}
