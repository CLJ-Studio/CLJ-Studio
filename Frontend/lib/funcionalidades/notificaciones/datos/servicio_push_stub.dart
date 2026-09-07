import 'destino_notificacion_sistema.dart';
import '../modelos/notificacion.dart';

/// Implementación segura para plataformas sin Web Push ni FCM.
abstract final class ServicioPush {
  static bool get soportado => false;
  static bool get yaConcedido => false;
  static bool get denegado => false;
  static String? ultimoError;

  static Stream<DestinoNotificacionSistema> get destinosAbiertos =>
      const Stream.empty();

  static Future<void> inicializar() async {}

  static Future<DestinoNotificacionSistema?> consumirDestinoInicial() async =>
      null;

  static Future<bool> estaActivo() async => false;
  static Future<bool> activar() async => false;
  static Future<bool> desactivar() async => true;
  static Future<void> mostrar(Notificacion notificacion) async {}
}
