import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    _zona = prefs.getString(_clave);
    notifyListeners();
  }

  Future<void> elegir(String nueva) async {
    _zona = nueva;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, nueva);
  }
}
