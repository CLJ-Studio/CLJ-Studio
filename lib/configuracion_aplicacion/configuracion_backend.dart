/// URL única que deberá apuntar al backend cuando esté disponible.
abstract final class ConfiguracionBackend {
  static const String urlBase = String.fromEnvironment(
    'URL_BACKEND',
    defaultValue: 'http://localhost:3000/api',
  );
}
