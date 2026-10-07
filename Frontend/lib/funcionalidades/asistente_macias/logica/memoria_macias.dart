import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/mensaje_macias.dart';

/// Un examen que la persona le conto a MacIAs: para desearle suerte antes y
/// preguntarle como le fue despues.
class ExamenMacias {
  ExamenMacias({
    required this.materia,
    required DateTime fecha,
    this.tipo = 'examen',
    this.preguntado = false,
    this.avisado,
  }) : fecha = DateTime(fecha.year, fecha.month, fecha.day);

  factory ExamenMacias.desdeJson(Map<String, dynamic> json) => ExamenMacias(
    materia: json['materia'] as String? ?? '',
    fecha: DateTime.parse(json['fecha'] as String),
    tipo: json['tipo'] as String? ?? 'examen',
    preguntado: json['preguntado'] as bool? ?? false,
    avisado: json['avisado'] as String?,
  );

  /// Como la escribio: "cálculo", "física". Vacio si no dijo.
  final String materia;
  final DateTime fecha;

  /// Como lo llamo: examen, parcial, final, prueba, defensa...
  final String tipo;

  /// Si ya se le pregunto como le fue: se pregunta una sola vez.
  bool preguntado;

  /// El dia (aaaa-mm-dd) en que ya se le deseo suerte, para no repetirlo
  /// cada vez que abre el chat.
  String? avisado;

  /// "el parcial de cálculo", "la prueba de física", o "tu examen" si no
  /// dijo de que.
  String get nombre => nombrar(tipo, materia);

  static const _femeninos = {'prueba', 'defensa', 'exposicion', 'presentacion'};

  static String nombrar(String tipo, String materia) {
    final escrito = switch (tipo) {
      'exposicion' => 'exposición',
      'presentacion' => 'presentación',
      'practico' => 'práctico',
      _ => tipo,
    };
    if (materia.isEmpty) return 'tu $escrito';
    return '${_femeninos.contains(tipo) ? 'la' : 'el'} $escrito de $materia';
  }

  Map<String, dynamic> aJson() => {
    'materia': materia,
    'fecha': diaTexto(fecha),
    if (tipo != 'examen') 'tipo': tipo,
    if (preguntado) 'preguntado': true,
    if (avisado != null) 'avisado': avisado,
  };

  /// "2026-10-07": una fecha sin hora, como se guarda.
  static String diaTexto(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
}

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
    Map<String, String>? favoritos,
    this.edad,
    this.cumpleMes,
    this.cumpleDia,
    this.ciudad,
    List<ExamenMacias>? examenes,
    List<String>? notas,
    Map<String, String>? personas,
    this.trabajo,
    this.cumpleFelicitado,
    this.notasRecordadas,
  }) : gustos = gustos ?? [],
       disgustos = disgustos ?? [],
       favoritos = favoritos ?? {},
       examenes = examenes ?? [],
       notas = notas ?? [],
       personas = personas ?? {};

  /// Lo guardado por cualquier version: lo que no se entiende se ignora (el
  /// viejo "modoMeme", por ejemplo), en vez de perder todo lo demas.
  factory MemoriaMacias.desdeJson(Map<String, dynamic> json) {
    List<String> lista(String clave) => [
      for (final g in (json[clave] as List? ?? const [])) '$g',
    ];
    return MemoriaMacias(
      nombre: json['nombre'] as String?,
      carrera: json['carrera'] as String?,
      gustos: lista('gustos'),
      disgustos: lista('disgustos'),
      favoritos: {
        for (final MapEntry(:key, :value)
            in (json['favoritos'] as Map? ?? const {}).entries)
          '$key': '$value',
      },
      edad: json['edad'] as int?,
      cumpleMes: json['cumpleMes'] as int?,
      cumpleDia: json['cumpleDia'] as int?,
      ciudad: json['ciudad'] as String?,
      examenes: [
        for (final e in (json['examenes'] as List? ?? const []))
          if (e is Map<String, dynamic>) ExamenMacias.desdeJson(e),
      ],
      notas: lista('notas'),
      personas: {
        for (final MapEntry(:key, :value)
            in (json['personas'] as Map? ?? const {}).entries)
          '$key': '$value',
      },
      trabajo: json['trabajo'] as String?,
      cumpleFelicitado: json['cumpleFelicitado'] as int?,
      notasRecordadas: json['notasRecordadas'] as String?,
    );
  }

  /// Como quiere que le digan. Manda sobre el nombre del perfil.
  String? nombre;
  String? carrera;
  final List<String> gustos;
  final List<String> disgustos;

  /// "color" -> "azul", "comida" -> "salteña".
  final Map<String, String> favoritos;
  int? edad;
  int? cumpleMes;
  int? cumpleDia;

  /// De donde es: "Santa Cruz", "Cochabamba".
  String? ciudad;
  final List<ExamenMacias> examenes;

  /// Lo que pidio que le recuerde, ya dicho de vuelta ("tienes que...").
  final List<String> notas;

  /// Quien es quien en su vida: "perro" -> "Rocky", "mejor amiga" -> "Ana".
  final Map<String, String> personas;

  /// Donde o de que trabaja, como lo dijo: "en una tienda", "de mesero".
  String? trabajo;

  /// El año en que ya se le saludo por su cumpleaños.
  int? cumpleFelicitado;

  /// El dia (aaaa-mm-dd) en que ya se le recordaron las notas.
  String? notasRecordadas;

  /// Cuantas cosas se recuerdan de cada lista: las mas viejas se olvidan.
  static const _maximo = 12;
  static const _maximoExamenes = 6;
  static const _maximoNotas = 8;

  bool get tieneCumple => cumpleMes != null && cumpleDia != null;

  bool get vacia =>
      nombre == null &&
      carrera == null &&
      gustos.isEmpty &&
      disgustos.isEmpty &&
      favoritos.isEmpty &&
      edad == null &&
      !tieneCumple &&
      ciudad == null &&
      examenes.isEmpty &&
      notas.isEmpty &&
      personas.isEmpty &&
      trabajo == null;

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

  void anotarFavorito(String categoria, String cosa) {
    favoritos.remove(categoria);
    favoritos[categoria] = cosa;
    if (favoritos.length > _maximo) favoritos.remove(favoritos.keys.first);
  }

  /// Un examen nuevo reemplaza al de la misma materia y el mismo dia.
  void anotarExamen(ExamenMacias examen) {
    examenes.removeWhere(
      (e) =>
          e.materia.toLowerCase() == examen.materia.toLowerCase() &&
          e.fecha == examen.fecha,
    );
    examenes
      ..add(examen)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    while (examenes.length > _maximoExamenes) {
      examenes.removeAt(0);
    }
  }

  void anotarNota(String nota) {
    notas.remove(nota);
    notas.add(nota);
    if (notas.length > _maximoNotas) notas.removeAt(0);
  }

  /// Pasa a esta memoria todo lo de [otra]: lo que se leyo del telefono
  /// entra en la memoria que ya usa el cerebro.
  void copiarDe(MemoriaMacias otra) {
    olvidar();
    nombre = otra.nombre;
    carrera = otra.carrera;
    gustos.addAll(otra.gustos);
    disgustos.addAll(otra.disgustos);
    favoritos.addAll(otra.favoritos);
    edad = otra.edad;
    cumpleMes = otra.cumpleMes;
    cumpleDia = otra.cumpleDia;
    ciudad = otra.ciudad;
    examenes.addAll(otra.examenes);
    notas.addAll(otra.notas);
    personas.addAll(otra.personas);
    trabajo = otra.trabajo;
    cumpleFelicitado = otra.cumpleFelicitado;
    notasRecordadas = otra.notasRecordadas;
  }

  /// Borra todo lo que sabe de la persona.
  void olvidar() {
    nombre = null;
    carrera = null;
    gustos.clear();
    disgustos.clear();
    favoritos.clear();
    edad = null;
    cumpleMes = null;
    cumpleDia = null;
    ciudad = null;
    examenes.clear();
    notas.clear();
    personas.clear();
    trabajo = null;
    cumpleFelicitado = null;
    notasRecordadas = null;
  }

  Map<String, dynamic> aJson() => {
    if (nombre != null) 'nombre': nombre,
    if (carrera != null) 'carrera': carrera,
    if (gustos.isNotEmpty) 'gustos': gustos,
    if (disgustos.isNotEmpty) 'disgustos': disgustos,
    if (favoritos.isNotEmpty) 'favoritos': favoritos,
    if (edad != null) 'edad': edad,
    if (cumpleMes != null) 'cumpleMes': cumpleMes,
    if (cumpleDia != null) 'cumpleDia': cumpleDia,
    if (ciudad != null) 'ciudad': ciudad,
    if (examenes.isNotEmpty) 'examenes': [for (final e in examenes) e.aJson()],
    if (notas.isNotEmpty) 'notas': notas,
    if (personas.isNotEmpty) 'personas': personas,
    if (trabajo != null) 'trabajo': trabajo,
    if (cumpleFelicitado != null) 'cumpleFelicitado': cumpleFelicitado,
    if (notasRecordadas != null) 'notasRecordadas': notasRecordadas,
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
  static String? carreraDe(String textoNormalizado) =>
      _primeraQueNombra(carreras, textoNormalizado);

  /// Ciudades y paises, con sus gentilicios: "soy camba" tambien es Santa
  /// Cruz.
  static const ciudades = <(String, List<String>)>[
    (
      'Santa Cruz',
      ['santa cruz', 'scz', 'cruceno', 'crucena', 'camba', 'cambita'],
    ),
    ('El Alto', ['el alto', 'alteno', 'altena']),
    ('La Paz', ['la paz', 'lpz', 'paceno', 'pacena']),
    (
      'Cochabamba',
      [
        'cochabamba',
        'cbba',
        'cocha',
        'cochabambino',
        'cochabambina',
        'cochala',
      ],
    ),
    ('Sucre', ['sucre', 'sucrense']),
    ('Chuquisaca', ['chuquisaca', 'chuquisaqueno', 'chuquisaquena']),
    ('Oruro', ['oruro', 'orureno', 'orurena']),
    ('Potosí', ['potosi', 'potosino', 'potosina']),
    ('Tarija', ['tarija', 'tarijeno', 'tarijena', 'chapaco', 'chapaca']),
    ('Trinidad', ['trinidad']),
    ('Beni', ['beni', 'beniano', 'beniana']),
    ('Cobija', ['cobija']),
    ('Pando', ['pando', 'pandino', 'pandina']),
    ('Montero', ['montero']),
    ('Warnes', ['warnes']),
    ('Cotoca', ['cotoca']),
    ('La Guardia', ['la guardia']),
    ('Camiri', ['camiri']),
    ('Yapacaní', ['yapacani']),
    ('Vallegrande', ['vallegrande']),
    ('Riberalta', ['riberalta']),
    ('Yacuiba', ['yacuiba']),
    ('Quillacollo', ['quillacollo']),
    ('Puerto Suárez', ['puerto suarez']),
    ('Argentina', ['argentina', 'argentino']),
    ('Brasil', ['brasil', 'brasileno', 'brasilena']),
    ('Perú', ['peru', 'peruano', 'peruana']),
    ('Chile', ['chile', 'chileno', 'chilena']),
    ('Paraguay', ['paraguay', 'paraguayo', 'paraguaya']),
    ('Colombia', ['colombia', 'colombiano', 'colombiana']),
    ('Venezuela', ['venezuela', 'venezolano', 'venezolana']),
    ('Ecuador', ['ecuador', 'ecuatoriano', 'ecuatoriana']),
    ('Uruguay', ['uruguay', 'uruguayo', 'uruguaya']),
    ('México', ['mexico', 'mexicano', 'mexicana']),
    ('España', ['espana', 'espanol', 'espanola']),
    ('Estados Unidos', ['estados unidos', 'eeuu', 'usa', 'gringo', 'gringa']),
  ];

  static String? ciudadDe(String textoNormalizado) =>
      _primeraQueNombra(ciudades, textoNormalizado);

  static String? _primeraQueNombra(
    List<(String, List<String>)> lista,
    String textoNormalizado,
  ) {
    final relleno = ' $textoNormalizado ';
    for (final (nombre, formas) in lista) {
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
