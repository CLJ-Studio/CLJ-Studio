import 'package:flutter/material.dart';

import '../modelos/pedido.dart';
import 'etiqueta_estado_pedido.dart';

/// Resumen de un pedido dentro de la lista de compras o ventas.
class TarjetaPedido extends StatelessWidget {
  const TarjetaPedido({
    required this.pedido,
    required this.soyVendedor,
    required this.alAbrir,
    super.key,
  });

  final Pedido pedido;
  final bool soyVendedor;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alAbrir,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFECEFED)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pedido.emojiLocal,
                      style: const TextStyle(fontSize: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // Al vendedor le importa quien pide; al comprador,
                            // de que local es.
                            soyVendedor
                                ? pedido.nombreComprador
                                : pedido.nombreLocal,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF252825),
                            ),
                          ),
                          Text(
                            '${pedido.unidades} '
                            '${pedido.unidades == 1 ? 'producto' : 'productos'}',
                            style: const TextStyle(
                              color: Color(0xFF7C827E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    EtiquetaEstadoPedido(estado: pedido.estado),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pedido.items.map((i) => i.nombre).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF858585),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bs ${pedido.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF202220),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
