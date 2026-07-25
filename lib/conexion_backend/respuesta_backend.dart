/// Envoltorio tipado que normalizará las respuestas del backend.
class RespuestaBackend<T> {
  const RespuestaBackend({required this.datos, this.mensaje});

  final T datos;
  final String? mensaje;
}
