import '../modelos/solicitud_acceso_upsa.dart';
import 'servicio_autenticacion_google.dart';

/// Abstrae el acceso para sustituir la simulación por OAuth real.
class RepositorioAccesoUpsa {
  const RepositorioAccesoUpsa(this.servicio);
  final ServicioAutenticacionGoogle servicio;

  Future<bool> acceder(SolicitudAccesoUpsa solicitud) =>
      servicio.simularAcceso(solicitud);
}
