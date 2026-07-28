import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datos/servicio_instalacion.dart';

/// Decide si toca invitar a instalar la app, y lo recuerda.
///
/// El descarte se guarda en el dispositivo y no en la cuenta: instalar es
/// algo de este telefono concreto. Quien la instalo en el suyo y entra desde
/// el de un amigo tiene que volver a verlo.
class ControladorInstalacion extends ChangeNotifier {
  ControladorInstalacion._();

  static final ControladorInstalacion instancia = ControladorInstalacion._();

  static const _clave = 'instalacion_descartada';

  bool _descartado = false;
  bool _listo = false;

  /// Invitacion visible en el inicio. Se calla si ya esta instalada, si no
  /// hay nada que ofrecer o si ya dijeron que no.
  bool get mostrarAviso {
    if (!_listo || _descartado) return false;
    return ServicioInstalacion.puedeInstalar ||
        ServicioInstalacion.requiereGestoManual;
  }

  /// Para el acceso permanente desde Configuracion, que ignora el descarte:
  /// si alguien cambia de idea tiene que poder encontrarlo.
  bool get disponible =>
      ServicioInstalacion.puedeInstalar ||
      ServicioInstalacion.requiereGestoManual;

  bool get requiereGestoManual => ServicioInstalacion.requiereGestoManual;

  Future<void> cargar() async {
    ServicioInstalacion.iniciar();

    final prefs = await SharedPreferences.getInstance();
    _descartado = prefs.getBool(_clave) ?? false;
    _listo = true;
    notifyListeners();

    // Chrome puede tardar en validar el manifest, asi que el evento llega
    // despues de esta carga. Sin este segundo aviso el usuario tendria que
    // cambiar de pestaña para ver el boton.
    Future.delayed(const Duration(seconds: 3), () {
      if (mostrarAviso) notifyListeners();
    });
  }

  Future<bool> instalar() async {
    final acepto = await ServicioInstalacion.instalar();
    if (acepto) await descartar();
    return acepto;
  }

  Future<void> descartar() async {
    _descartado = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, true);
  }
}
