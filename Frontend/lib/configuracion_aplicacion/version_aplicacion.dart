/// Versión que está corriendo de verdad en el dispositivo.
///
/// Existe porque una PWA sirve la copia que tenga en caché, y sin esto no hay
/// forma de distinguir "el arreglo no funciona" de "el arreglo todavía no
/// llegó a este teléfono". Nos costó varias vueltas de depuración creer lo
/// primero cuando era lo segundo.
abstract final class VersionAplicacion {
  /// Formato `día.mes.hora`: 2.10.1432 es lo que se publicó el 2 de octubre
  /// a las 14:32, hora de Bolivia.
  ///
  /// Se elige por fecha y no por semántica porque aquí no hay API pública que
  /// versionar: lo único que importa es saber de cuándo es lo que tienes
  /// delante y si es posterior al fallo que estás mirando.
  ///
  /// LA PONE NETLIFY AL COMPILAR, no una persona. Antes era un número escrito
  /// a mano que había que acordarse de cambiar en cada entrega, y nadie se
  /// acordaba: el 2 de octubre seguía diciendo 28.8.3, más de un mes y
  /// decenas de despliegues después. Un número de versión viejo es peor que
  /// no tenerlo, porque hace creer que lo que tienes delante es otra cosa.
  static String get numero =>
      _fechaDelBuild.isEmpty ? _numeroManual : _fechaDelBuild;

  /// Lo inyecta el build de Netlify (`netlify.toml`).
  static const _fechaDelBuild = String.fromEnvironment('FECHA_VERSION');

  /// Solo para compilaciones hechas a mano (Android, iOS, local), donde nadie
  /// inyecta la fecha.
  static const _numeroManual = '2.10.1';

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

  /// Lo que se enseña: `1.7.2 beta` era de Minecraft; aquí `2.10.1432 beta`.
  static String get etiqueta => '$numero $fase';

  /// Con el commit detrás, para cuando hay que rastrear un fallo concreto.
  static String get completa => '$etiqueta · $_commitCorto';
}
