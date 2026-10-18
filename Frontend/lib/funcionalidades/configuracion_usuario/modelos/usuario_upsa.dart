import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';

/// En que punto esta la marca de egresado. La pide el estudiante y la
/// verifica un admin: marcarse solo dejaba a cualquiera decir que se graduo.
enum EstadoEgresado { sinPedir, enRevision, rechazado, verificado }

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
    this.biografia = '',
    this.tipoCuenta = 'estudiante',
    this.estadoEgresado,
    this.areaUpsa,
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
      biografia: (fila['bio'] as String?) ?? '',
      tipoCuenta: (fila['tipo_cuenta'] as String?) ?? 'estudiante',
      estadoEgresado: _estadoEgresado(fila),
      areaUpsa: fila['area_upsa'] as String?,
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

  /// Linea breve que escribe la propia persona. El nombre y la carrera los
  /// pone la universidad; esto es lo unico suyo.
  final String biografia;

  /// 'estudiante' (los egresados tambien) o 'upsa', el personal que entra
  /// con su correo @upsa.edu.bo.
  final String tipoCuenta;

  /// Null si el servidor todavia no sabe verificar egresados (sin la
  /// migracion 56): entonces la opcion no se ofrece.
  final EstadoEgresado? estadoEgresado;

  static EstadoEgresado? _estadoEgresado(Map<String, dynamic> fila) {
    if (!fila.containsKey('egresado_pedido_en')) return null;
    if (fila['es_egresado'] == true) return EstadoEgresado.verificado;
    if (fila['egresado_pedido_en'] != null) return EstadoEgresado.enRevision;
    if (fila['egresado_rechazado_en'] != null) {
      return EstadoEgresado.rechazado;
    }
    return EstadoEgresado.sinPedir;
  }

  /// Area o unidad del personal de la UPSA ("Incubadora de Empresas").
  final String? areaUpsa;

  bool get esCuentaUpsa => tipoCuenta == 'upsa';

  String? get avatarUrl => ServicioImagenes.urlPublica(avatarPath);

  /// Inicial para el avatar; evita reventar si el nombre llega vacio.
  String get inicial =>
      nombre.trim().isEmpty ? '?' : nombre.trim().substring(0, 1).toUpperCase();
}
