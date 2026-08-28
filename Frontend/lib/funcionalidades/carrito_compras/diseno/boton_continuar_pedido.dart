import 'package:flutter/material.dart';

class BotonContinuarPedido extends StatelessWidget {
  const BotonContinuarPedido({
    required this.habilitado,
    required this.alPresionar,
    super.key,
  });
  final bool habilitado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Material(
    color: habilitado ? const Color(0xFF138A5B) : const Color(0xFFB9CEBD),
    borderRadius: BorderRadius.circular(28),
    child: InkWell(
      onTap: habilitado ? alPresionar : null,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
        child: const Center(
          child: Text(
            'Contactar con el vendedor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  );
}
