/// En una app descargada no existe el flujo de instalación de una PWA.
abstract final class ServicioInstalacion {
  static void iniciar() {}
  static bool get yaInstalada => true;
  static bool get puedeInstalar => false;
  static bool get esIOS => false;
  static bool get requiereGestoManual => false;
  static Future<bool> instalar() async => false;
}
