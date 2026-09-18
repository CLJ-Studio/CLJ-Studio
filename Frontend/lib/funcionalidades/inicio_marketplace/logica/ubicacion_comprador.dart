import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../configuracion_aplicacion/modo_local.dart';
import '../../mi_local/logica/controlador_mi_local.dart';

/// Dónde está quien mira el catálogo.
///
/// Antes vivía en un `ValueNotifier` suelto dentro del encabezado: se perdía
/// al recargar, así que había que elegirla en cada visita y no servía para
/// nada. Se guarda en el dispositivo y no en la cuenta porque es de este
/// momento y este aparato, no un dato del perfil.
///
/// No la confundas con la ubicación del local: aquella la publica quien
/// vende para que le encuentren; esta solo la usa quien compra.
class UbicacionComprador extends ChangeNotifier {
  UbicacionComprador._();

  static final UbicacionComprador instancia = UbicacionComprador._();

  static const _clave = 'ubicacion_comprador';

  /// Las mismas zonas que elige el vendedor: si fueran dos listas, comprador
  /// y vendedor hablarían de sitios que no coinciden.
  static const zonas = ControladorMiLocal.ubicacionesCampus;

  String? _zona;

  String? get zona => _zona;

  bool get elegida => _zona != null && _zona!.isNotEmpty;

  /// Texto del encabezado.
  String get etiqueta => elegida ? _zona! : 'Elige tu ubicación';

  /// El dispositivo manda; el perfil es el respaldo.
  ///
  /// En la PWA lo del dispositivo es el almacenamiento del navegador, y eso
  /// se va solo: al limpiar datos del sitio, en ventana privada, o porque
  /// Safari lo descarta tras unos dias sin entrar. Por eso la zona se copia
  /// tambien al perfil y se recupera de ahi cuando el navegador llega vacio.
  ///
  /// El orden importa: primero lo local, que es instantaneo y es donde estas
  /// ahora; el viaje al servidor solo ocurre si no habia nada guardado.
  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardada = prefs.getString(_clave);
    if (guardada != null && guardada.isNotEmpty) {
      _zona = guardada;
      notifyListeners();
      return;
    }

    final delPerfil = await _leerDelPerfil();
    if (delPerfil == null || delPerfil.isEmpty) return;

    _zona = delPerfil;
    notifyListeners();
    // Se deja en el dispositivo para que la proxima vez no haya que preguntar.
    await prefs.setString(_clave, delPerfil);
  }

  Future<void> elegir(String nueva) async {
    _zona = nueva;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, nueva);
    await _guardarEnPerfil(nueva);
  }

  static Future<String?> _leerDelPerfil() async {
    if (ModoLocal.activo) return null;
    final cliente = Supabase.instance.client;
    final usuario = cliente.auth.currentUser;
    if (usuario == null) return null;

    try {
      final fila = await cliente
          .from('profiles')
          .select('campus_zone')
          .eq('id', usuario.id)
          .maybeSingle();
      return (fila?['campus_zone'] as String?)?.trim();
    } catch (_) {
      // Sin red, o con la migracion 50 aun sin aplicar. Quedarse sin zona es
      // molesto; romper el arranque de la aplicacion por eso, mucho peor.
      return null;
    }
  }

  static Future<void> _guardarEnPerfil(String zona) async {
    if (ModoLocal.activo) return;
    final cliente = Supabase.instance.client;
    final usuario = cliente.auth.currentUser;
    if (usuario == null) return;

    try {
      await cliente
          .from('profiles')
          .update({'campus_zone': zona})
          .eq('id', usuario.id);
    } catch (_) {
      // El respaldo es un extra: lo del dispositivo ya se guardo, que es lo
      // que hace falta para que la eleccion surta efecto ahora mismo.
    }
  }
}
