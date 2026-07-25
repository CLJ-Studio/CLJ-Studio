/// Datos que se enviarán al proveedor de autenticación en una versión futura.
class SolicitudAccesoUpsa {
  const SolicitudAccesoUpsa({required this.codigo, required this.correo});
  final String codigo;
  final String correo;
}
