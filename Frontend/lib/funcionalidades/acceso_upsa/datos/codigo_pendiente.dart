import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda que hay un código esperando a ser escrito.
///
/// Sin esto, salir de la aplicación a leer el correo la devolvía al primer
/// paso: el estado vivía solo en memoria y una PWA en segundo plano puede
/// descartarse en cualquier momento. Al volver parecía que el código había
/// caducado, cuando lo que se había perdido era la pantalla.
///
/// Solo se guarda el correo y la hora del envío. El código jamás: llega al
/// buzón y lo escribe la persona; guardarlo aquí no ahorraría nada y dejaría
/// una llave de la cuenta en el dispositivo.
class CodigoPendiente {
  const CodigoPendiente({required this.correo, required this.enviadoEn});

  final String correo;
  final DateTime enviadoEn;

  static const _claveCorreo = 'codigo_pendiente_correo';
  static const _claveEnvio = 'codigo_pendiente_enviado';

  /// Cuánto se da por vivo un código en el dispositivo.
  ///
  /// Generoso a propósito: quien manda de verdad es el servidor, que lo
  /// rechaza si caducó. Cortar antes aquí solo serviría para mandar de vuelta
  /// al primer paso a alguien que todavía tenía un código bueno.
  static const _vigencia = Duration(minutes: 15);

  /// Segundos que faltan para poder pedir otro, contados desde el envío.
  ///
  /// Se calcula con la hora guardada y no con un contador en memoria: si no,
  /// minimizar la aplicación reiniciaba la espera desde cero.
  int esperaRestante(int segundosEntreCodigos) {
    final pasados = DateTime.now().difference(enviadoEn).inSeconds;
    final faltan = segundosEntreCodigos - pasados;
    return faltan > 0 ? faltan : 0;
  }

  static Future<CodigoPendiente?> leer() async {
    final prefs = await SharedPreferences.getInstance();
    final correo = prefs.getString(_claveCorreo);
    final marca = prefs.getInt(_claveEnvio);
    if (correo == null || marca == null) return null;

    final enviadoEn = DateTime.fromMillisecondsSinceEpoch(marca);
    if (DateTime.now().difference(enviadoEn) > _vigencia) {
      await olvidar();
      return null;
    }

    return CodigoPendiente(correo: correo, enviadoEn: enviadoEn);
  }

  static Future<void> guardar(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveCorreo, correo);
    await prefs.setInt(_claveEnvio, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> olvidar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveCorreo);
    await prefs.remove(_claveEnvio);
  }
}
