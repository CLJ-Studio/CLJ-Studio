import 'package:flutter/material.dart';
import '../../inicio_marketplace/logica/ubicacion_comprador.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';

/// Hero visual del detalle del local: su logo real o un lienzo con su emoji.
class EncabezadoDetalleLocal extends StatelessWidget {
  const EncabezadoDetalleLocal({
    required this.local,
    required this.alAbrirPerfil,
    super.key,
  });
  final LocalUniversitario local;
  final VoidCallback alAbrirPerfil;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(
        // Es el mismo marco usado antes de subir la portada (1200 x 900).
        // Así el detalle muestra exactamente el encuadre que eligió la persona.
        aspectRatio: 4 / 3,
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
              const SizedBox(height: 10),
              _AccesoVendedor(local: local, alAbrir: alAbrirPerfil),
              const SizedBox(height: 10),
              Text(local.descripcion),
              const SizedBox(height: 10),
              Text(
                local.esPersonal
                    ? 'Vendedor independiente'
                    : 'Entrega Bs ${local.costoEntrega.toStringAsFixed(0)}',
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

class _AccesoVendedor extends StatelessWidget {
  const _AccesoVendedor({required this.local, required this.alAbrir});

  final LocalUniversitario local;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: alAbrir,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: switch (local.vendedorAvatarUrl) {
                final String url => Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(child: Text(local.emoji)),
                ),
                _ => Center(child: Text(local.emoji)),
              },
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                local.vendedorNombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
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
