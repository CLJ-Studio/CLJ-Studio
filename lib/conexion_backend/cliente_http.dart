import '../configuracion_aplicacion/configuracion_backend.dart';
import 'respuesta_backend.dart';

/// Contrato mínimo del cliente futuro; no realiza conexiones en esta versión.
class ClienteHttp {
  const ClienteHttp({this.urlBase = ConfiguracionBackend.urlBase});

  final String urlBase;

  Future<RespuestaBackend<T>> obtener<T>(String ruta) {
    throw UnimplementedError(
      'Conectar $urlBase$ruta cuando el backend esté disponible.',
    );
  }
}
