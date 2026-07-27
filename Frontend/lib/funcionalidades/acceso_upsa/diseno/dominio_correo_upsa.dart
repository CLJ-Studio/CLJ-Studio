import 'package:flutter/material.dart';

/// Hace visible el dominio fijo que el usuario no necesita escribir.
class DominioCorreoUpsa extends StatelessWidget {
  const DominioCorreoUpsa({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '@estudiantes.upsa.edu.bo',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
