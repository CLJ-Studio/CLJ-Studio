import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/pedidos/modelos/pedido.dart';

Map<String, dynamic> _pedidoCanceladoPor(String actorId) => {
  'id': 'pedido-1',
  'status': 'cancelado',
  'buyer_id': 'comprador-1',
  'seller_id': 'vendedor-1',
  'store_id': 'local-1',
  'store_name': 'Cafetería',
  'store_emoji': '☕',
  'buyer_name': 'Ana Compradora',
  'seller_name': 'Luis Vendedor',
  'subtotal': 20,
  'delivery_cost': 0,
  'total': 20,
  'items': <Map<String, dynamic>>[],
  'created_at': '2026-09-12T12:00:00Z',
  'expires_at': '2026-09-12T13:00:00Z',
  'cancelled_by': actorId,
};

void main() {
  test('el comprador ve cuando canceló el vendedor', () {
    final pedido = Pedido.desdeMapa(_pedidoCanceladoPor('vendedor-1'));

    expect(
      pedido.etiquetaPara(soyVendedor: false),
      'Cancelado por el vendedor',
    );
  });

  test('la etiqueta también distingue una cancelación propia', () {
    final pedido = Pedido.desdeMapa(_pedidoCanceladoPor('comprador-1'));

    expect(pedido.etiquetaPara(soyVendedor: false), 'Cancelado por ti');
    expect(
      pedido.etiquetaPara(soyVendedor: true),
      'Cancelado por el comprador',
    );
    expect(pedido.fueCanceladoPor('comprador-1'), isTrue);
    expect(pedido.fueCanceladoPor('vendedor-1'), isFalse);
  });
}
