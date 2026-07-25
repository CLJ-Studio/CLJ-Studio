import 'package:flutter/material.dart';

class EncabezadoCarrito extends StatelessWidget {
  const EncabezadoCarrito({required this.alCerrar, super.key});

  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'Detalle del carrito',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF202221),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Cerrar',
            onPressed: alCerrar,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF2F4F5),
              foregroundColor: const Color(0xFF303432),
            ),
            icon: const Icon(Icons.close_rounded, size: 22),
          ),
        ),
      ],
    ),
  );
}
