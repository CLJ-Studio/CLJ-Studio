/// Versión que está corriendo de verdad en el dispositivo.
///
/// Existe porque una PWA sirve la copia que tenga en caché, y sin esto no hay
/// forma de distinguir "el arreglo no funciona" de "el arreglo todavía no
/// llegó a este teléfono". Nos costó varias vueltas de depuración creer lo
/// primero cuando era lo segundo.
abstract final class VersionAplicacion {
  /// Formato `día.mes.entrega`: 29.7.1 es la primera entrega del 29 de julio.
  ///
  /// Se elige por fecha y no por semántica porque aquí no hay API pública que
  /// versionar: lo único que importa es saber de cuándo es lo que tienes
  /// delante y si es posterior al fallo que estás mirando.
  ///
  /// Al subir varias veces el mismo día solo cambia el último número.
  static const numero = '29.7.6';

  /// Mientras la aplicación no esté abierta a todo el campus.
  static const fase = 'beta';

  /// Commit exacto, para rastrear el cambio en el repositorio. Lo inyecta
  /// Netlify durante el build; en local queda como 'local'.
  static const _commit = String.fromEnvironment(
    'VERSION_APP',
    defaultValue: 'local',
  );

  static String get _commitCorto =>
      _commit.length > 7 ? _commit.substring(0, 7) : _commit;

  /// Lo que se enseña: `1.7.2 beta` era de Minecraft; aquí `29.7.1 beta`.
  static String get etiqueta => '$numero $fase';

  /// Con el commit detrás, para cuando hay que rastrear un fallo concreto.
  static String get completa => '$etiqueta · $_commitCorto';
}
