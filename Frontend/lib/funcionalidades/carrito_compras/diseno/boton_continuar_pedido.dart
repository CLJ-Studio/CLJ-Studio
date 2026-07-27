import 'package:flutter/material.dart';

class BotonContinuarPedido extends StatelessWidget {
  const BotonContinuarPedido({
    required this.habilitado,
    required this.total,
    required this.alPresionar,
    super.key,
  });
  final bool habilitado;
  final double total;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Material(
    color: habilitado ? Theme.of(context).colorScheme.primary : const Color(0xFFC9CEC9),
    borderRadius: BorderRadius.circular(32),
    child: InkWell(
      onTap: habilitado ? alPresionar : null,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
        child: Row(
          children: [
            const Icon(Icons.forum_rounded, color: Colors.white, size: 21),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Contactar con el vendedor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Bs ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
