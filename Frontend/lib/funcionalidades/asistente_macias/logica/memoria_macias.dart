import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/mensaje_macias.dart';

/// Lo que MacIAs recuerda de quien le escribe.
///
/// Solo lo que la persona le cuenta en el chat, y solo en su telefono: no
/// viaja a ningun servidor. Con eso alcanza para que la conversacion se
/// sienta con alguien que se acuerda de ti y no con un formulario.
class MemoriaMacias {
  MemoriaMacias({
    this.nombre,
    this.carrera,
    List<String>? gustos,
    List<String>? disgustos,
    this.modoMeme = false,
  }) : gustos = gustos ?? [],
       disgustos = disgustos ?? [];

  factory MemoriaMacias.desdeJson(Map<String, dynamic> json) => MemoriaMacias(
    nombre: json['nombre'] as String?,
    carrera: json['carrera'] as String?,
    gustos: [for (final g in (json['gustos'] as List? ?? const [])) '$g'],
    disgustos: [for (final g in (json['disgustos'] as List? ?? const [])) '$g'],
    modoMeme: json['modoMeme'] as bool? ?? false,
  );

  /// Como quiere que le digan. Manda sobre el nombre del perfil.
  String? nombre;
  String? carrera;
  final List<String> gustos;
  final List<String> disgustos;

  /// Mas humor en las respuestas. Se recuerda entre visitas.
  bool modoMeme;

  /// Cuantas cosas se recuerdan de cada lista: las mas viejas se olvidan.
  static const _maximo = 12;

  bool get vacia =>
      nombre == null && carrera == null && gustos.isEmpty && disgustos.isEmpty;

  void anotarGusto(String cosa) {
    disgustos.remove(cosa);
    gustos.remove(cosa);
    gustos.add(cosa);
    if (gustos.length > _maximo) gustos.removeAt(0);
  }

  void anotarDisgusto(String cosa) {
    gustos.remove(cosa);
    disgustos.remove(cosa);
    disgustos.add(cosa);
    if (disgustos.length > _maximo) disgustos.removeAt(0);
  }

  /// Borra lo que sabe de la persona. El modo meme no es un dato suyo: queda.
  void olvidar() {
    nombre = null;
    carrera = null;
    gustos.clear();
    disgustos.clear();
  }

  Map<String, dynamic> aJson() => {
    if (nombre != null) 'nombre': nombre,
    if (carrera != null) 'carrera': carrera,
    if (gustos.isNotEmpty) 'gustos': gustos,
    if (disgustos.isNotEmpty) 'disgustos': disgustos,
    'modoMeme': modoMeme,
  };

  /// Las carreras de la UPSA, tal como estan en la base (tabla `careers`),
  /// con las formas cortas en que la gente las nombra. El orden importa: se
  /// prueba de arriba abajo, y "diseño industrial" tiene que ganarle a
  /// "industrial".
  static const carreras = <(String, List<String>)>[
    ('Diseño Industrial', ['diseno industrial']),
    ('Ingeniería Industrial y de Sistemas', ['industrial']),
    ('Ingeniería Informática Administrativa', ['informatica']),
    ('Ingeniería de Sistemas', ['sistemas']),
    ('Ingeniería Civil', ['civil']),
    ('Ingeniería Mecatrónica y Robótica', ['mecatronica', 'robotica']),
    ('Ingeniería de Energías Sostenibles', ['energias', 'energia']),
    ('Ingeniería Comercial', ['ingenieria comercial', 'comercial']),
    ('Ingeniería Económica', ['economica', 'economia']),
    ('Ingeniería Financiera', ['financiera']),
    ('Administración de Empresas', ['administracion', 'empresas']),
    ('Auditoría y Finanzas', ['auditoria', 'finanzas']),
    ('Comercio Internacional', ['comercio']),
    ('Marketing y Publicidad', ['marketing', 'publicidad', 'mercadotecnia']),
    ('Derecho', ['derecho', 'leyes', 'abogacia']),
    ('Comunicación Estratégica y Corporativa', ['comunicacion']),
    ('Diseño Gráfico', ['diseno grafico', 'grafico']),
    ('Diseño y Gestión de la Moda', ['moda']),
    ('Psicología', ['psicologia']),
    ('Arquitectura', ['arquitectura']),
  ];

  /// "sistemas", "ing. civil", "derecho": la carrera de la UPSA que nombra.
  static String? carreraDe(String textoNormalizado) {
    final relleno = ' $textoNormalizado ';
    for (final (nombre, formas) in carreras) {
      for (final forma in formas) {
        if (relleno.contains(' $forma ')) return nombre;
      }
    }
    return null;
  }
}

/// Donde queda la conversacion entre una visita y otra.
abstract class AlmacenMacias {
  Future<({List<MensajeMacias> mensajes, MemoriaMacias memoria})> cargar();

  Future<void> guardar(List<MensajeMacias> mensajes, MemoriaMacias memoria);
}

/// En el telefono, separado por cuenta.
///
/// Separado por cuenta porque en un mismo telefono se puede cambiar de
/// cuenta: la conversacion de una persona no puede aparecerle a otra.
class AlmacenMaciasLocal implements AlmacenMacias {
  AlmacenMaciasLocal(this.cuenta);

  final String cuenta;

  /// Los ultimos mensajes, no todos: es una consulta, no un archivo, y en la
  /// web el almacenamiento del navegador es chico.
  static const maximoMensajes = 150;

  String get _claveConversacion => 'macias.$cuenta.conversacion';
  String get _claveMemoria => 'macias.$cuenta.memoria';

  @override
  Future<({List<MensajeMacias> mensajes, MemoriaMacias memoria})>
  cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversacion = prefs.getString(_claveConversacion);
      final memoria = prefs.getString(_claveMemoria);
      return (
        mensajes: conversacion == null
            ? <MensajeMacias>[]
            : [
                for (final m in jsonDecode(conversacion) as List)
                  MensajeMacias.desdeJson(m as Map<String, dynamic>),
              ],
        memoria: memoria == null
            ? MemoriaMacias()
            : MemoriaMacias.desdeJson(
                jsonDecode(memoria) as Map<String, dynamic>,
              ),
      );
    } catch (_) {
      // Algo guardado por otra version y que ya no se entiende: se empieza
      // de cero antes que no poder abrir el chat.
      return (mensajes: <MensajeMacias>[], memoria: MemoriaMacias());
    }
  }

  @override
  Future<void> guardar(
    List<MensajeMacias> mensajes,
    MemoriaMacias memoria,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimos = mensajes.length > maximoMensajes
          ? mensajes.sublist(mensajes.length - maximoMensajes)
          : mensajes;
      await prefs.setString(
        _claveConversacion,
        jsonEncode([for (final m in ultimos) m.aJson()]),
      );
      await prefs.setString(_claveMemoria, jsonEncode(memoria.aJson()));
    } catch (_) {
      // Si no se pudo guardar, la conversacion sigue igual en pantalla.
    }
  }
}

/// Sin guardar nada: para pruebas, o si no hay donde guardar.
class AlmacenMaciasEnMemoria implements AlmacenMacias {
  List<MensajeMacias> _mensajes = [];
  MemoriaMacias _memoria = MemoriaMacias();

  @override
  Future<({List<MensajeMacias> mensajes, MemoriaMacias memoria})>
  cargar() async => (
    mensajes: [..._mensajes],
    memoria: MemoriaMacias.desdeJson(_memoria.aJson()),
  );

  @override
  Future<void> guardar(
    List<MensajeMacias> mensajes,
    MemoriaMacias memoria,
  ) async {
    _mensajes = [...mensajes];
    _memoria = MemoriaMacias.desdeJson(memoria.aJson());
  }
}
