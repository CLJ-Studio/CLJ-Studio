import 'package:flutter/material.dart';

import '../modelos/proveedor_upsa.dart';

/// Un emprendimiento del directorio: que es, que le ofrece a la UPSA, de
/// quien es y como contactarlo.
class TarjetaProveedor extends StatelessWidget {
  const TarjetaProveedor({
    required this.proveedor,
    required this.alContactar,
    required this.alVerLocal,
    super.key,
  });

  final ProveedorUpsa proveedor;

  /// Null si el dueño no tiene WhatsApp: el boton queda apagado.
  final VoidCallback? alContactar;
  final VoidCallback alVerLocal;

  static const _grafito = Color(0xFF474646);
  static const _crema = Color(0xFFE6E1D5);

  String get _detalle {
    final partes = [proveedor.categoria];
    final publicaciones = proveedor.publicaciones;
    if (publicaciones > 0) {
      partes.add(
        '$publicaciones ${publicaciones == 1 ? 'publicación' : 'publicaciones'}',
      );
    }
    if (proveedor.calificaciones > 0) {
      final nota = proveedor.calificacion
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      partes.add('★ $nota');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final apagado = tema.textTheme.bodyMedium?.color;
    final quien = [
      'De ${proveedor.dueno}',
      ?proveedor.carrera,
      if (proveedor.anioIngreso case final int anio) 'Ingresó en $anio',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _crema, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(proveedor: proveedor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _detalle,
                      style: TextStyle(color: apagado, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Insignia(proveedor: proveedor),
            ],
          ),
          if (proveedor.queOfrece.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              proveedor.queOfrece,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Text(quien, style: TextStyle(color: apagado, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: alContactar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _grafito,
                    foregroundColor: _crema,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Contactar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: alVerLocal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _grafito,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: const Text('Ver local'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// El logo del local, o su emoji sobre su color si no subio uno.
class _Logo extends StatelessWidget {
  const _Logo({required this.proveedor});

  final ProveedorUpsa proveedor;

  @override
  Widget build(BuildContext context) {
    final url = proveedor.logoUrl;
    final emoji = Center(
      child: Text(proveedor.emoji, style: const TextStyle(fontSize: 26)),
    );

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52,
          height: 52,
          child: ColoredBox(
            color: Color(proveedor.colorHex),
            child: url == null
                ? emoji
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => emoji,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Estudiante o egresado: lo que la incubadora queria poder distinguir.
class _Insignia extends StatelessWidget {
  const _Insignia({required this.proveedor});

  final ProveedorUpsa proveedor;

  @override
  Widget build(BuildContext context) {
    final egresado = proveedor.esEgresado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: egresado ? const Color(0xFF474646) : const Color(0xFFE6E1D5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        proveedor.tipo,
        style: TextStyle(
          color: egresado ? const Color(0xFFE6E1D5) : const Color(0xFF474646),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
