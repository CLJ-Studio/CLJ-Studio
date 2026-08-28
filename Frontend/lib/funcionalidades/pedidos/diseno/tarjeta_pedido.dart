import 'package:flutter/material.dart';

import '../modelos/pedido.dart';

/// Resumen de un pedido dentro de la lista de compras o ventas.
class TarjetaPedido extends StatelessWidget {
  const TarjetaPedido({
    required this.pedido,
    required this.soyVendedor,
    required this.alAbrir,
    this.alCancelar,
    this.mensajesSinLeer = 0,
    super.key,
  });

  final Pedido pedido;
  final bool soyVendedor;
  final VoidCallback alAbrir;

  /// Solo se ofrece al comprador de un pedido aun sin responder.
  final VoidCallback? alCancelar;

  /// Mensajes del chat que todavia no se han visto.
  final int mensajesSinLeer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF171A17)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alAbrir,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF242824)
                            : const Color(0xFFF3F4F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        pedido.items.isEmpty
                            ? pedido.emojiLocal
                            : pedido.items.first.emoji,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                    if (mensajesSinLeer > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C8A63),
                            borderRadius: BorderRadius.circular(20),
                            // El borde del color de la tarjeta despega el
                            // distintivo del emoji que tiene detras.
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF171A17)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '$mensajesSinLeer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        soyVendedor
                            ? pedido.nombreComprador
                            : pedido.nombreLocal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pedido.items.map((item) => item.nombre).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF858985),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: pedido.estado.color,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${pedido.estado.etiqueta} · ${pedido.unidades} '
                              '${pedido.unidades == 1 ? 'producto' : 'productos'}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF777C78),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'Bs ${pedido.total.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (alCancelar case final cancelar?) ...[
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Cancelar pedido',
                        onPressed: cancelar,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFB3453B),
                          size: 20,
                        ),
                      ),
                    ],
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
