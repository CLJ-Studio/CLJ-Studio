/// Perfil mínimo del estudiante autenticado.
class UsuarioUpsa {
  const UsuarioUpsa({
    required this.nombre,
    required this.codigo,
    required this.correo,
    required this.carrera,
  });

  final String nombre;
  final String codigo;
  final String correo;
  final String carrera;
}
