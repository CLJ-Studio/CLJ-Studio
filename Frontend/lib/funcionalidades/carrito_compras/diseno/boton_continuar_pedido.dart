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
    color: habilitado ? const Color(0xFF474646) : const Color(0xFFBBBCA7),
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
              color: Color(0xFFE6E1D5),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  );
}
