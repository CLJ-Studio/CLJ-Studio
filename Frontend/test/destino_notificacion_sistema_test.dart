import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/notificaciones/datos/destino_notificacion_sistema.dart';

void main() {
  test('entiende el destino que entrega Web Push', () {
    final destino = DestinoNotificacionSistema.desdeMapa({
      'notif_pedido': 'pedido-1',
      'notif_local': 'local-1',
      'notif_producto': 'producto-1',
    });

    expect(destino.pedidoId, 'pedido-1');
    expect(destino.localId, 'local-1');
    expect(destino.productoId, 'producto-1');
    expect(destino.tieneDestino, isTrue);
  });

  test('entiende el destino de la notificación nativa de APNs', () {
    final destino = DestinoNotificacionSistema.desdeMapa({
      'order_id': 'pedido-2',
      'store_id': 'local-2',
      'product_id': 'producto-2',
    });

    expect(destino.pedidoId, 'pedido-2');
    expect(destino.localId, 'local-2');
    expect(destino.productoId, 'producto-2');
  });

  test('ignora valores vacíos del payload nativo', () {
    final destino = DestinoNotificacionSistema.desdeMapa({
      'order_id': '',
      'store_id': 'null',
      'product_id': null,
    });

    expect(destino.tieneDestino, isFalse);
  });
}
