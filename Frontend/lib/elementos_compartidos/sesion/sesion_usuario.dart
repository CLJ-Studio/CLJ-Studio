import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../configuracion_aplicacion/modo_local.dart';
import '../../funcionalidades/configuracion_usuario/datos/repositorio_configuracion.dart';
import '../../funcionalidades/configuracion_usuario/modelos/usuario_upsa.dart';

/// Perfil del usuario autenticado, cargado una sola vez y compartido.
///
/// Evita que cada pantalla consulte `profiles` por su cuenta: el saludo del
/// inicio y la pantalla de configuracion leen la misma fuente, asi que si el
/// perfil cambia se refleja en ambos sitios.
class SesionUsuario extends ChangeNotifier {
  SesionUsuario._();

  static final SesionUsuario instancia = SesionUsuario._();

  static const _repositorio = RepositorioConfiguracion();

  UsuarioUpsa? perfil;
  bool cargando = false;

  /// Primer nombre para saludos; cae a un generico mientras carga.
  String get primerNombre {
    final nombre = perfil?.nombre.trim() ?? '';
    if (nombre.isEmpty) return 'estudiante';
    return nombre.split(' ').first;
  }

  Future<void> cargar({bool forzar = false}) async {
    if (cargando) return;
    if (perfil != null && !forzar) return;
    if (ModoLocal.activo) {
      perfil = const UsuarioUpsa(
        nombre: 'Estudiante UPSA',
        codigo: 'LOCAL',
        correo: 'estudiante@upsa.edu.bo',
        carrera: 'Modo de diseño',
        avatarEmoji: '🎓',
        whatsapp: '',
        enCampus: true,
      );
      notifyListeners();
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) return;

    cargando = true;
    notifyListeners();
    try {
      perfil = await _repositorio.cargarPerfil();
    } catch (_) {
      // El saludo cae al generico; la pantalla de configuracion muestra
      // su propio mensaje de error si la consulta falla.
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Se llama al cerrar sesion para no filtrar datos al siguiente usuario.
  void limpiar() {
    perfil = null;
    notifyListeners();
  }
}
