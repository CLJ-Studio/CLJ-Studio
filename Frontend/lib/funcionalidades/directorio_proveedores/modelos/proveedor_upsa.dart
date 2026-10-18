import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';

/// Un emprendimiento que se ofrece a la UPSA, tal como lo devuelve
/// `directorio_proveedores()`.
class ProveedorUpsa {
  const ProveedorUpsa({
    required this.localId,
    required this.nombre,
    required this.descripcion,
    required this.categoriaId,
    required this.categoria,
    required this.emoji,
    required this.colorHex,
    required this.dueno,
    required this.esEgresado,
    required this.whatsapp,
    this.oferta,
    this.logoPath,
    this.esPersonal = false,
    this.carrera,
    this.anioIngreso,
    this.calificacion = 0,
    this.calificaciones = 0,
    this.publicaciones = 0,
  });

  factory ProveedorUpsa.desdeMapa(Map<String, dynamic> fila) => ProveedorUpsa(
    localId: fila['local_id'] as String,
    nombre: (fila['nombre'] as String?)?.trim() ?? '',
    descripcion: (fila['descripcion'] as String?)?.trim() ?? '',
    oferta: (fila['oferta'] as String?)?.trim(),
    categoriaId: (fila['categoria_id'] as String?) ?? 'otros',
    categoria: (fila['categoria'] as String?) ?? 'Otros',
    emoji: (fila['emoji'] as String?) ?? '🏪',
    logoPath: fila['logo_path'] as String?,
    colorHex: (fila['color_hex'] as num?)?.toInt() ?? 0xFFFFE8D6,
    esPersonal: (fila['es_personal'] as bool?) ?? false,
    dueno: (fila['dueno'] as String?)?.trim() ?? '',
    carrera: fila['carrera'] as String?,
    esEgresado: (fila['es_egresado'] as bool?) ?? false,
    anioIngreso: (fila['anio_ingreso'] as num?)?.toInt(),
    whatsapp: (fila['whatsapp'] as String?) ?? '',
    calificacion: (fila['calificacion'] as num?)?.toDouble() ?? 0,
    calificaciones: (fila['calificaciones'] as num?)?.toInt() ?? 0,
    publicaciones: (fila['publicaciones'] as num?)?.toInt() ?? 0,
  );

  final String localId;
  final String nombre;
  final String descripcion;

  /// Lo que el dueño escribio para la UPSA ("catering para eventos").
  final String? oferta;
  final String categoriaId;
  final String categoria;
  final String emoji;
  final String? logoPath;
  final int colorHex;
  final bool esPersonal;
  final String dueno;
  final String? carrera;

  /// Verificado por un admin: la marca la pide el estudiante y la aprueban
  /// ellos.
  final bool esEgresado;

  /// Sale del numero de registro, que viene del correo institucional: no se
  /// puede inventar. Quien ingreso hace muchos años seguro ya egreso.
  final int? anioIngreso;

  /// Con codigo de pais, listo para wa.me. Solo lo ve la UPSA, y solo de
  /// quien eligio aparecer.
  final String whatsapp;
  final double calificacion;
  final int calificaciones;
  final int publicaciones;

  String? get logoUrl => ServicioImagenes.urlPublica(logoPath);

  /// Lo que le ofrece a la UPSA; si no lo escribio, la descripcion del local.
  String get queOfrece {
    final propia = oferta ?? '';
    return propia.isNotEmpty ? propia : descripcion;
  }

  String get tipo => esEgresado ? 'Egresado' : 'Estudiante';

  /// El chat de WhatsApp con el saludo ya escrito.
  Uri? get enlaceWhatsapp {
    if (whatsapp.isEmpty) return null;
    final mensaje =
        'Hola, te escribo de la UPSA por $nombre, que vi en el directorio '
        'de proveedores de U market.';
    return Uri.parse(
      'https://wa.me/$whatsapp?text=${Uri.encodeComponent(mensaje)}',
    );
  }

  /// Si aparece al buscar. Sin tildes ni mayusculas, y cada palabra buscada
  /// en cualquier parte: "catering egresado" encuentra al egresado que hace
  /// catering aunque las dos palabras esten en campos distintos.
  bool coincideCon(String busqueda) {
    final palabras = _plano(
      busqueda,
    ).split(' ').where((palabra) => palabra.isNotEmpty);
    if (palabras.isEmpty) return true;
    final texto = _plano(
      [
        nombre,
        oferta ?? '',
        descripcion,
        categoria,
        dueno,
        carrera ?? '',
        tipo,
      ].join(' '),
    );
    return palabras.every(texto.contains);
  }

  static const _conTilde = 'áéíóúüñ';
  static const _sinTilde = 'aeiouun';

  static String _plano(String texto) {
    final bajo = texto.toLowerCase();
    final buffer = StringBuffer();
    for (final letra in bajo.split('')) {
      final i = _conTilde.indexOf(letra);
      buffer.write(i < 0 ? letra : _sinTilde[i]);
    }
    return buffer.toString();
  }
}

/// Lo que el negocio propio elige mostrarle a la UPSA.
class OfertaUpsa {
  const OfertaUpsa({
    required this.localId,
    required this.activa,
    required this.texto,
  });

  final String localId;
  final bool activa;
  final String texto;
}
