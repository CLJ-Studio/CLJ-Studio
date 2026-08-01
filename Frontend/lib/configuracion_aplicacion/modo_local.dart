/// Permite activar explícitamente herramientas locales de desarrollo.
/// La aplicación siempre usa el backend salvo que el desarrollador lo pida.
abstract final class ModoLocal {
  static const activo = bool.fromEnvironment('MODO_LOCAL', defaultValue: false);
}
