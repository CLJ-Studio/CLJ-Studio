import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';

/// Perfil del estudiante autenticado, tal como lo devuelve `profiles`.
class UsuarioUpsa {
  const UsuarioUpsa({
    required this.nombre,
    required this.codigo,
    required this.correo,
    required this.carrera,
    required this.avatarEmoji,
    required this.whatsapp,
    required this.enCampus,
    this.avatarPath,
    this.muestraVistas = true,
    this.muestraFavoritos = false,
  });

  factory UsuarioUpsa.desdeMapa(Map<String, dynamic> fila) {
    // `careers` llega como objeto anidado por el join de PostgREST.
    final carrera = fila['careers'] as Map<String, dynamic>?;
    return UsuarioUpsa(
      nombre: (fila['full_name'] as String?) ?? '',
      codigo: (fila['student_code'] as String?) ?? '',
      correo: (fila['email'] as String?) ?? '',
      carrera: (carrera?['name'] as String?) ?? 'Sin carrera',
      avatarEmoji: (fila['avatar_emoji'] as String?) ?? '🎓',
      whatsapp: (fila['whatsapp'] as String?) ?? '',
      enCampus: (fila['is_on_campus'] as bool?) ?? false,
      avatarPath: fila['avatar_path'] as String?,
      muestraVistas: (fila['show_view_count'] as bool?) ?? true,
      muestraFavoritos: (fila['show_favorites'] as bool?) ?? false,
    );
  }

  final String nombre;
  final String codigo;
  final String correo;
  final String carrera;
  final String avatarEmoji;
  final String whatsapp;
  final bool enCampus;

  /// Foto de la persona. Si falta, la tarjeta cae a la inicial del nombre.
  final String? avatarPath;

  /// Si el resto puede ver cuanta gente miro sus publicaciones.
  final bool muestraVistas;

  /// Si el resto puede ver lo que guardo en favoritos.
  final bool muestraFavoritos;

  String? get avatarUrl => ServicioImagenes.urlPublica(avatarPath);

  /// Inicial para el avatar; evita reventar si el nombre llega vacio.
  String get inicial =>
      nombre.trim().isEmpty ? '?' : nombre.trim().substring(0, 1).toUpperCase();
}
