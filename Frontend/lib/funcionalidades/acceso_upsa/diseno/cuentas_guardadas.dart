import 'package:flutter/material.dart';

/// Cuentas que ya entraron en este dispositivo.
///
/// Existe para no volver a teclear diez dígitos cada vez que se cierra
/// sesión. Elegir una no salta ninguna comprobación: el código llega igual
/// al correo, solo se ahorra escribirlo.
class CuentasGuardadas extends StatelessWidget {
  const CuentasGuardadas({
    required this.cuentas,
    required this.alElegir,
    required this.alOlvidar,
    super.key,
  });

  final List<String> cuentas;
  final ValueChanged<String> alElegir;
  final ValueChanged<String> alOlvidar;

  @override
  Widget build(BuildContext context) {
    if (cuentas.isEmpty) return const SizedBox.shrink();
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entrar con una cuenta guardada',
          style: TextStyle(
            color: tema.textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final cuenta in cuentas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: tema.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => alElegir(cuenta),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: tema.colorScheme.primary.withValues(
                          alpha: .18,
                        ),
                        child: Text(
                          // El registro empieza por 'a'; la letra siguiente
                          // no distingue nada, así que se usa el año.
                          cuenta.replaceAll(RegExp('[^0-9]'), '').isEmpty
                              ? '@'
                              : cuenta
                                    .replaceAll(RegExp('[^0-9]'), '')
                                    .substring(0, 2),
                          style: TextStyle(
                            color: tema.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cuenta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar de este dispositivo',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => alOlvidar(cuenta),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }
}
