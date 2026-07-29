/// Identifica la versión que está corriendo de verdad en el dispositivo.
///
/// Existe porque una PWA sirve la copia que tenga en caché, y sin esto no
/// hay forma de distinguir "el arreglo no funciona" de "el arreglo todavía
/// no llegó a este teléfono". Nos costó varias vueltas de depuración creer
/// lo primero cuando era lo segundo.
///
/// Netlify inyecta el commit en el build; en local queda como 'local'.
abstract final class VersionAplicacion {
  static const _commit = String.fromEnvironment(
    'VERSION_APP',
    defaultValue: 'local',
  );

  /// Los siete primeros caracteres bastan para identificarlo en GitHub.
  static String get corta =>
      _commit.length > 7 ? _commit.substring(0, 7) : _commit;
}
