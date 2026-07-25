import '../modelos/solicitud_acceso_upsa.dart';

/// Simulación local; aquí se conectará Google Sign-In más adelante.
class ServicioAutenticacionGoogle {
  const ServicioAutenticacionGoogle();

  Future<bool> simularAcceso(SolicitudAccesoUpsa solicitud) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return solicitud.correo.endsWith('@estudiantes.upsa.edu.bo');
  }
}
