import 'package:flutter/foundation.dart';

import '../modelos/publicacion_usuario.dart';

/// Conserva durante la sesión las publicaciones creadas por el usuario.
class ControladorMisPublicaciones extends ChangeNotifier {
  ControladorMisPublicaciones._();

  static final ControladorMisPublicaciones instancia =
      ControladorMisPublicaciones._();

  final List<PublicacionUsuario> _publicaciones = [];

  List<PublicacionUsuario> get publicaciones =>
      List.unmodifiable(_publicaciones.reversed);
  int get cantidad => _publicaciones.length;

  void publicar({
    required String tipo,
    required String nombre,
    required String descripcion,
    required String categoria,
    required double precio,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _publicaciones.add(
      PublicacionUsuario(
        id: id,
        tipo: tipo,
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        categoria: categoria,
        precio: precio,
      ),
    );
    notifyListeners();
  }

  void eliminar(String id) {
    _publicaciones.removeWhere((publicacion) => publicacion.id == id);
    notifyListeners();
  }
}
