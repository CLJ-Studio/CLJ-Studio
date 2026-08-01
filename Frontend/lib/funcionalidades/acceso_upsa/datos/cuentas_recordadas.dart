import 'package:shared_preferences/shared_preferences.dart';

/// Correos que ya entraron en este dispositivo.
///
/// Se guardan solo en el teléfono, nunca en el servidor: son de este aparato
/// concreto, no de la cuenta. Y se guarda únicamente el correo, jamás un
/// código ni una sesión: quien vuelva a entrar recibe un código nuevo igual,
/// así que la lista ahorra teclear pero no salta ninguna comprobación.
abstract final class CuentasRecordadas {
  static const _clave = 'cuentas_usadas';
  static const _prefijoAvatar = 'avatar_cuenta_';

  /// Un teléfono compartido no debería acumular una lista interminable.
  static const _maximo = 5;

  static Future<List<String>> leer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_clave) ?? const [];
  }

  /// La más reciente encabeza: es casi siempre la que se vuelve a usar.
  static Future<void> recordar(String correo) async {
    final normalizado = correo.trim().toLowerCase();
    if (normalizado.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final actuales = prefs.getStringList(_clave) ?? const [];

    final nuevas = [
      normalizado,
      ...actuales.where((cuenta) => cuenta != normalizado),
    ].take(_maximo).toList();

    await prefs.setStringList(_clave, nuevas);
  }

  static Future<void> olvidar(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizado = correo.trim().toLowerCase();
    final actuales = prefs.getStringList(_clave) ?? const [];
    await prefs.setStringList(
      _clave,
      actuales.where((cuenta) => cuenta != normalizado).toList(),
    );
    await prefs.remove('$_prefijoAvatar$normalizado');
  }

  /// Conserva la foto pública del perfil para mostrarla antes de iniciar sesión.
  static Future<void> guardarAvatar(String correo, String? avatarUrl) async {
    final normalizado = correo.trim().toLowerCase();
    if (normalizado.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final clave = '$_prefijoAvatar$normalizado';
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      await prefs.remove(clave);
    } else {
      await prefs.setString(clave, avatarUrl.trim());
    }
  }

  static Future<String?> leerAvatar(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefijoAvatar${correo.trim().toLowerCase()}');
  }
}
