import 'servicio_autenticacion_google.dart';

/// Abstrae el acceso institucional detras del servicio de autenticacion.
class RepositorioAccesoUpsa {
  const RepositorioAccesoUpsa(this.servicio);
  final ServicioAutenticacionGoogle servicio;

  Future<void> iniciarSesionConGoogle({String? correoSugerido}) =>
      servicio.iniciarSesion(correoSugerido: correoSugerido);

  Future<void> cerrarSesion() => servicio.cerrarSesion();
}
