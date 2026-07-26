/// Error legible que evita filtrar detalles HTTP hacia la interfaz.
class ErrorBackend implements Exception {
  const ErrorBackend(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
