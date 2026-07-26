/// Modelo del formulario listo para convertirse en una solicitud HTTP.
class BorradorPublicacion {
  const BorradorPublicacion({
    this.tipo = 'Producto',
    this.nombre = '',
    this.descripcion = '',
    this.categoria = 'Tecnologia',
    this.precio = 0,
  });
  final String tipo;
  final String nombre;
  final String descripcion;
  final String categoria;
  final double precio;
}
