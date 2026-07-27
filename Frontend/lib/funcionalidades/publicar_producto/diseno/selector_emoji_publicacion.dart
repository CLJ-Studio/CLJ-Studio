import 'package:flutter/material.dart';

/// Icono del producto: hace de imagen en el catálogo hasta que se conecte
/// Supabase Storage (ver la tabla product_images).
class SelectorEmojiPublicacion extends StatelessWidget {
  const SelectorEmojiPublicacion({
    required this.valor,
    required this.alCambiar,
    super.key,
  });

  final String valor;
  final ValueChanged<String> alCambiar;

  static const opciones = [
    '🛍️',
    '🥪',
    '☕',
    '🥤',
    '🍔',
    '🍕',
    '🧁',
    '🍱',
    '📓',
    '🔌',
    '💻',
    '🖨️',
    '📚',
    '🎧',
    '👕',
    '🎨',
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Icono',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final opcion in opciones)
            InkWell(
              onTap: () => alCambiar(opcion),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: valor == opcion
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .12)
                      : Colors.white,
                  border: Border.all(
                    color: valor == opcion
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    width: valor == opcion ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(opcion, style: const TextStyle(fontSize: 23)),
              ),
            ),
        ],
      ),
    ],
  );
}
