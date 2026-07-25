/// Resultado inmutable de la validación del código institucional.
class EstadoAccesoUpsa {
  const EstadoAccesoUpsa({
    this.codigo = '',
    this.correo = '',
    this.error,
    this.esValido = false,
  });

  final String codigo;
  final String correo;
  final String? error;
  final bool esValido;
}
