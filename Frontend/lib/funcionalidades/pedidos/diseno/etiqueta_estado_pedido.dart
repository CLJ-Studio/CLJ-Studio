import 'package:flutter/material.dart';

import '../modelos/pedido.dart';

/// Distintivo de color con el estado actual del pedido.
class EtiquetaEstadoPedido extends StatelessWidget {
  const EtiquetaEstadoPedido({required this.estado, super.key});

  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: estado.fondo,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mientras espera respuesta gira un indicador: comunica que algo
        // sigue en curso, en vez de parecer un estado detenido.
        if (estado == EstadoPedido.solicitado)
          SizedBox(
            width: 9,
            height: 9,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: estado.color,
            ),
          )
        else
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: estado.color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 7),
        Text(
          estado.etiqueta,
          style: TextStyle(
            color: estado.color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
