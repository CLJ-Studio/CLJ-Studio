import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';

/// Local tipado, independiente de la fuente que entregue sus datos.
class LocalUniversitario {
  const LocalUniversitario({
    required this.id,
    required this.nombre,
    required this.categoriaId,
    required this.categoria,
    required this.descripcion,
    required this.calificacion,
    required this.tiempoEstimado,
    required this.estaAbierto,
    required this.costoEntrega,
    required this.emoji,
    required this.colorHexadecimal,
    this.esPersonal = false,
    this.logoPath,
    this.portadaPath,
    this.vendedorNombre = '',
    this.vendedorAvatarPath,
    this.vistas = 0,
    this.muestraVistas = true,
  });

  /// Mapea una fila de `stores` o de la vista `locales_publicos`, que ademas
  /// trae el vendedor y una portada tomada de sus productos.
  factory LocalUniversitario.desdeMapa(Map<String, dynamic> fila) {
    final categoria = fila['categories'] as Map<String, dynamic>?;
    return LocalUniversitario(
      id: fila['id'] as String,
      nombre: fila['name'] as String,
      categoriaId: (fila['category_id'] as String?) ?? '',
      categoria:
          (categoria?['name'] as String?) ??
          (fila['categoria_nombre'] as String?) ??
          '',
      descripcion: (fila['description'] as String?) ?? '',
      calificacion: (fila['rating_average'] as num?)?.toDouble() ?? 0,
      tiempoEstimado: (fila['estimated_time'] as String?) ?? '',
      estaAbierto: (fila['is_open'] as bool?) ?? false,
      costoEntrega: (fila['delivery_cost'] as num?)?.toDouble() ?? 0,
      emoji: (fila['emoji'] as String?) ?? '🍽️',
      // color_hex es bigint en Postgres: 0xFFFFE8D6 desborda un int32.
      colorHexadecimal: (fila['color_hex'] as num?)?.toInt() ?? 0xFFF1F6F0,
      esPersonal: (fila['is_personal'] as bool?) ?? false,
      logoPath: fila['logo_path'] as String?,
      portadaPath: fila['portada_path'] as String?,
      vendedorNombre: (fila['vendedor_nombre'] as String?) ?? '',
      vendedorAvatarPath: fila['vendedor_avatar'] as String?,
      vistas: (fila['view_count'] as num?)?.toInt() ?? 0,
      muestraVistas: (fila['vendedor_muestra_vistas'] as bool?) ?? true,
    );
  }

  final String id;
  final String nombre;
  final String categoriaId;
  final String categoria;
  final String descripcion;
  final double calificacion;
  final String tiempoEstimado;
  final bool estaAbierto;
  final double costoEntrega;
  final String emoji;
  final int colorHexadecimal;

  /// Espacio creado automaticamente al publicar sin abrir un local formal.
  final bool esPersonal;
  final String? logoPath;

  /// Primera foto de sus productos: sirve de vitrina cuando no hay logo.
  final String? portadaPath;

  final String vendedorNombre;
  final String? vendedorAvatarPath;
  final int vistas;

  /// Si quien vende deja que el resto vea su contador. Se decide en
  /// Privacidad y viaja con el local para no consultar el perfil aparte.
  final bool muestraVistas;

  String? get logoUrl => ServicioImagenes.urlPublica(logoPath);
  String? get vendedorAvatarUrl =>
      ServicioImagenes.urlPublica(vendedorAvatarPath);

  /// Imagen de la tarjeta: el logo manda; si no hay, una foto de producto.
  String? get portadaUrl =>
      ServicioImagenes.urlPublica(logoPath ?? portadaPath);
}
