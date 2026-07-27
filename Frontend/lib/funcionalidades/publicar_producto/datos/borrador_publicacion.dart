import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Publicacion a medias, guardada en el dispositivo.
class BorradorPublicacion {
  const BorradorPublicacion({
    this.tipo = 'Producto',
    this.nombre = '',
    this.descripcion = '',
    this.precio = '',
    this.stock = '1',
    this.emoji = '🛍️',
    this.galeria = const [],
  });

  factory BorradorPublicacion.desdeJson(Map<String, dynamic> json) =>
      BorradorPublicacion(
        tipo: (json['tipo'] as String?) ?? 'Producto',
        nombre: (json['nombre'] as String?) ?? '',
        descripcion: (json['descripcion'] as String?) ?? '',
        precio: (json['precio'] as String?) ?? '',
        stock: (json['stock'] as String?) ?? '1',
        emoji: (json['emoji'] as String?) ?? '🛍️',
        galeria: ((json['galeria'] as List?) ?? const []).cast<String>(),
      );

  final String tipo;
  final String nombre;
  final String descripcion;
  final String precio;
  final String stock;
  final String emoji;
  final List<String> galeria;

  Map<String, dynamic> aJson() => {
    'tipo': tipo,
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'stock': stock,
    'emoji': emoji,
    'galeria': galeria,
  };

  /// Un borrador sin nada escrito no merece recuperarse.
  bool get tieneContenido =>
      nombre.trim().isNotEmpty ||
      descripcion.trim().isNotEmpty ||
      precio.trim().isNotEmpty ||
      galeria.isNotEmpty;

  /// Resumen para el aviso de "tienes una publicacion sin terminar".
  String get resumen {
    if (nombre.trim().isNotEmpty) return nombre.trim();
    if (galeria.isNotEmpty) {
      return '${galeria.length} ${galeria.length == 1 ? 'foto' : 'fotos'}';
    }
    return 'Publicación sin título';
  }
}

/// Guarda el borrador en el dispositivo.
///
/// Va en local y no en el servidor a proposito: es un formulario a medias,
/// no un dato del marketplace. Ademas asi sobrevive aunque no haya conexion,
/// que es justo cuando mas duele perder lo escrito.
abstract final class AlmacenBorrador {
  static const _clave = 'borrador_publicacion';

  static Future<BorradorPublicacion?> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(_clave);
    if (crudo == null) return null;

    try {
      final borrador = BorradorPublicacion.desdeJson(
        jsonDecode(crudo) as Map<String, dynamic>,
      );
      return borrador.tieneContenido ? borrador : null;
    } catch (_) {
      // Formato viejo o corrupto: se descarta sin molestar al usuario.
      await borrar();
      return null;
    }
  }

  static Future<void> guardar(BorradorPublicacion borrador) async {
    final prefs = await SharedPreferences.getInstance();
    if (!borrador.tieneContenido) {
      await prefs.remove(_clave);
      return;
    }
    await prefs.setString(_clave, jsonEncode(borrador.aJson()));
  }

  static Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
