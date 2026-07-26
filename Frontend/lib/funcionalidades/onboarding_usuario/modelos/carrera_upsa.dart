/// Carrera del catalogo institucional (tabla `careers`).
class CarreraUpsa {
  const CarreraUpsa({
    required this.id,
    required this.nombre,
    required this.facultad,
  });

  factory CarreraUpsa.desdeMapa(Map<String, dynamic> fila) => CarreraUpsa(
    id: fila['id'] as String,
    nombre: fila['name'] as String,
    facultad: fila['faculty'] as String,
  );

  final String id;
  final String nombre;
  final String facultad;
}
