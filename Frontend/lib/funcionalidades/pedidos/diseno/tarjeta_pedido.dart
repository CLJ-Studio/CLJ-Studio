import 'package:flutter/material.dart';
import '../../../elementos_compartidos/imagenes/foto_red.dart';

import '../modelos/pedido.dart';

/// Pedido presentado como historial visual: marca, estado, productos y total.
class TarjetaPedido extends StatelessWidget {
  const TarjetaPedido({
    required this.pedido,
    required this.soyVendedor,
    required this.alAbrir,
    this.alRepetir,
    this.repitiendo = false,
    this.mensajesSinLeer = 0,
    super.key,
  });

  final Pedido pedido;
  final bool soyVendedor;
  final VoidCallback alAbrir;
  final VoidCallback? alRepetir;
  final bool repitiendo;
  final int mensajesSinLeer;

  Color get _colorEstado => switch (pedido.estado) {
    EstadoPedido.entregado => const Color(0xFF098B67),
    EstadoPedido.cancelado ||
    EstadoPedido.rechazado ||
    EstadoPedido.vencido => const Color(0xFFB2194B),
    EstadoPedido.aceptado ||
    EstadoPedido.porConfirmar => const Color(0xFF252B68),
    EstadoPedido.solicitado => const Color(0xFFE4572E),
  };

  String get _fecha {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final fecha = pedido.resueltoEn?.toLocal() ?? pedido.creadoEn.toLocal();
    return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Abrir pedido de ${pedido.nombreLocal}',
          child: InkWell(
            onTap: alAbrir,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ImagenPedido(
                        url: pedido.localLogoUrl,
                        emoji: pedido.emojiLocal,
                        tamanio: 72,
                        radio: 18,
                      ),
                      if (mensajesSinLeer > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE93636),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '$mensajesSinLeer',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 5,
                          children: [
                            Text(
                              pedido.etiquetaPara(soyVendedor: soyVendedor),
                              style: TextStyle(
                                color: _colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _fecha,
                              style: const TextStyle(
                                color: Color(0xFF37323F),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          soyVendedor
                              ? pedido.nombreComprador
                              : pedido.nombreLocal,
                          maxLines: soyVendedor ? null : 2,
                          overflow: soyVendedor
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF10091D),
                            fontSize: 18,
                            height: 1.14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          pedido.items
                              .map(
                                (item) => item.cantidad > 1
                                    ? '${item.cantidad}× ${item.nombre}'
                                    : item.nombre,
                              )
                              .join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF625C68),
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Bs ${pedido.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF10091D),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (pedido.items.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pedido.items.length.clamp(0, 4),
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, indice) {
                final item = pedido.items[indice];
                return _ImagenPedido(
                  url: item.imagenUrl,
                  emoji: item.emoji,
                  tamanio: 70,
                  radio: 17,
                );
              },
            ),
          ),
        ],
        if (alRepetir != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: repitiendo ? null : alRepetir,
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFF6F5F7),
                disabledBackgroundColor: const Color(0xFFF6F5F7),
                foregroundColor: const Color(0xFF10091D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: repitiendo
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF10091D),
                      ),
                    )
                  : const Icon(Icons.replay_rounded, size: 24),
              label: Text(
                repitiendo ? 'Preparando pedido…' : 'Repetir',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Divider(height: 1, color: Color(0xFFEDEBF0)),
      ],
    ),
  );
}

class _ImagenPedido extends StatelessWidget {
  const _ImagenPedido({
    required this.url,
    required this.emoji,
    required this.tamanio,
    required this.radio,
  });

  final String? url;
  final String emoji;
  final double tamanio;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final reemplazo = ColoredBox(
      color: const Color(0xFFF4F3F5),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: tamanio * .42)),
      ),
    );
    return Container(
      width: tamanio,
      height: tamanio,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F5),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: const Color(0xFFE7E5E9)),
      ),
      child: url == null
          ? reemplazo
          : FotoRed(url: url!, anchoVisible: 96, alFallar: reemplazo),
    );
  }
}
