import 'servicio_autenticacion_correo.dart';

/// Abstrae el acceso institucional detras del servicio de autenticacion.
///
/// Se entra con el correo de la universidad y un codigo de un solo uso, sin
/// salir de la aplicacion. Antes se redirigia a Google: el dominio permitido
/// es exactamente el mismo, lo que cambia es que la identidad se comprueba
/// contra el buzon institucional en vez de contra una pestaña externa.
class RepositorioAccesoUpsa {
  const RepositorioAccesoUpsa([
    this.servicio = const ServicioAutenticacionCorreo(),
  ]);

  final ServicioAutenticacionCorreo servicio;

  /// Devuelve el motivo del fallo, o null si el codigo salio.
  Future<String?> enviarCodigo(String correo) => servicio.enviarCodigo(correo);

  /// Devuelve el motivo del fallo, o null si la sesion quedo abierta.
  Future<String?> verificarCodigo({
    required String correo,
    required String codigo,
  }) => servicio.verificarCodigo(correo: correo, codigo: codigo);

  Future<void> cerrarSesion() => servicio.cerrarSesion();
}
