/// Destino que viaja dentro de una notificación del sistema.
///
/// Es el mismo contrato para Web Push, APNs en iPhone y avisos locales en
/// Android. La pantalla no necesita saber de qué plataforma vino.
class DestinoNotificacionSistema {
  const DestinoNotificacionSistema({
    this.pedidoId,
    this.localId,
    this.productoId,
  });

  factory DestinoNotificacionSistema.desdeMapa(Map<String, dynamic> datos) {
    String? leer(String clave) {
      final valor = datos[clave]?.toString().trim();
      return valor == null || valor.isEmpty || valor == 'null' ? null : valor;
    }

    return DestinoNotificacionSistema(
      pedidoId: leer('order_id') ?? leer('notif_pedido'),
      localId: leer('store_id') ?? leer('notif_local'),
      productoId: leer('product_id') ?? leer('notif_producto'),
    );
  }

  final String? pedidoId;
  final String? localId;
  final String? productoId;

  bool get tieneDestino =>
      pedidoId != null || localId != null || productoId != null;
}
