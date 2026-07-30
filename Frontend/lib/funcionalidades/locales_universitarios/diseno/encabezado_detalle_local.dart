import 'package:flutter/material.dart';
import '../../inicio_marketplace/logica/ubicacion_comprador.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Hero visual del detalle del local: su logo real o un lienzo con su emoji.
class EncabezadoDetalleLocal extends StatelessWidget {
  const EncabezadoDetalleLocal({required this.local, super.key});
  final LocalUniversitario local;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
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
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                local.esPersonal ? local.vendedorNombre : local.nombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
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
              // Donde esta ahora quien vende. Se guardaba desde hace varias
              // versiones y no lo veia nadie: era justo el dato que hacia
              // util el recordatorio horario.
              if (local.ubicacionCampus case final String zona
                  when zona.isNotEmpty) ...[
                const SizedBox(height: 10),
                _Ubicacion(zona: zona),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

/// Punto del campus donde está quien vende, y si coincide con el tuyo.
class _Ubicacion extends StatelessWidget {
  const _Ubicacion({required this.zona});

  final String zona;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Coincidir con la zona propia es lo que decide si vale la pena pedir
    // ahora o esperar, asi que se marca en vez de dejarlo a la comparacion
    // mental.
    final misma = UbicacionComprador.instancia.zona == zona;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 17,
            color: tema.colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Text(
            misma ? 'Está en $zona, como tú' : 'Está en $zona',
            style: TextStyle(
              color: tema.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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
