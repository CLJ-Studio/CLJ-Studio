import '../modelos/mensaje_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'memoria_macias.dart';

/// La vida en la U: tramites, el campus, los profes, la carrera.
///
/// De los tramites de la UPSA (fechas, costos, requisitos) MacIAs no sabe
/// los datos: cambian cada semestre y no tiene internet. Asi que no los
/// inventa: dice donde preguntar. Lo que si sabe, lo dice: como hablar con
/// un profe, que hacer si llegaste tarde, de que va cada carrera.
abstract final class UniversidadMacias {
  static const _materias = [
    OpcionMacias(id: 's:algebra', texto: 'Álgebra'),
    OpcionMacias(id: 's:calculo', texto: 'Cálculo integral'),
    OpcionMacias(id: 's:cpp', texto: 'Programación en C++'),
  ];

  /// Lo que se contesta, o null si no es de la U.
  static RespuestaCharla? responder(String limpio, ContextoMacias c) {
    final t = ' $limpio ';
    return _campus(t) ??
        _tarde(t) ??
        _profes(t) ??
        _tramites(t) ??
        _carrera(limpio, t) ??
        _dondeEstudiar(t);
  }

  static bool _dice(String t, List<String> frases) =>
      frases.any((f) => t.contains(' $f '));

  static RespuestaCharla _dicho(String texto, String tipo) =>
      RespuestaCharla(texto, intencion: 'universidad:$tipo');

  // ================================================================ campus
  /// Las zonas que usa la app para encontrarse.
  static const _zonas = {
    'jatata': 'Jatata',
    'la jatata': 'Jatata',
    'pascana': 'Pascana',
    'la pascana': 'Pascana',
    'mozza': 'Mozza',
    'la mozza': 'Mozza',
    'cafeteria': 'Cafetería',
    'la cafeteria': 'Cafetería',
    'bloque a': 'Bloque A',
    'el bloque a': 'Bloque A',
    'bloque b': 'Bloque B',
    'el bloque b': 'Bloque B',
    'ingenieria': 'Ingeniería',
    'el bloque de ingenieria': 'Ingeniería',
  };

  /// Lugares del campus que no son zonas de la app.
  static const _lugaresDelCampus = {
    'biblioteca',
    'bano',
    'banos',
    'rectorado',
    'auditorio',
    'cancha',
    'coliseo',
    'enfermeria',
    'secretaria',
    'cajas',
    'caja',
    'registros',
    'laboratorio',
    'laboratorios',
    'aula',
    'mi aula',
    'mi curso',
    'fotocopiadora',
    'las fotocopias',
    'parqueo',
    'estacionamiento',
  };

  static final _dondeQueda = RegExp(
    r' (?:(?:donde|en donde|en que parte) '
    r'(?:queda|quedan|esta|estan|se encuentra|hay)|como llego a|como llego al) '
    r'(?:el |la |los |las |un |una )?(.+?) $',
  );

  static RespuestaCharla? _campus(String t) {
    final pregunta = _dondeQueda.firstMatch(t);
    if (pregunta == null) return null;
    final lugar = pregunta[1]!.replaceFirst(
      RegExp(r' (?:de la u|del campus|de la upsa|en la u|en el campus)$'),
      '',
    );
    final zona = _zonas[lugar];
    if (zona != null) {
      return _dicho(
        '**$zona** es una de las zonas del campus que usa la app para '
            'encontrarse. No tengo el mapa, así que si no la ubicas, pregúntale a '
            'cualquiera por ahí: todos la conocen. Y en la app, cada local dice '
            '**Te encuentran en…** con su zona.',
        'campus',
      );
    }
    if (const {'upsa', 'la upsa', 'u', 'la u', 'universidad'}.contains(lugar)) {
      return _dicho(
        'La UPSA está en Santa Cruz de la Sierra. Para llegar, lo más fácil es '
            'buscar **UPSA** en el mapa de tu celular: te arma la ruta.',
        'campus',
      );
    }
    if (_lugaresDelCampus.contains(lugar)) {
      return _dicho(
        'No tengo el mapa del campus, pero cualquiera por ahí te orienta (los '
            'de seguridad saben todo). Y si es para encontrarte con alguien de la '
            'app, usen las zonas: Jatata, Pascana, Mozza, Cafetería, Bloque A, '
            'Bloque B o Ingeniería.',
        'campus',
      );
    }
    return null;
  }

  // ================================================================= tarde
  static RespuestaCharla? _tarde(String t) {
    final dormido = _dice(t, [
      'me quede dormido',
      'me quede dormida',
      'se me paso la hora',
      'no escuche la alarma',
    ]);
    final examen = _dice(t, ['examen', 'parcial', 'final', 'prueba']);
    if (dormido && examen) {
      return _dicho(
        'Pucha. Habla con tu profe hoy mismo y cuéntale qué pasó: según la '
            'materia, puede haber examen de recuperación o segunda instancia. Y '
            'para la próxima, dos alarmas.',
        'tarde',
      );
    }
    if (_dice(t, ['voy tarde', 'voy a llegar tarde', 'estoy llegando tarde'])) {
      return _dicho(
        '¡Corre! Y si ya no llegas, pídele a alguien de tu curso que te pase '
            'lo que vieron.',
        'tarde',
      );
    }
    if (dormido ||
        _dice(t, [
          'llegue tarde',
          'se me hizo tarde',
          'falte a clases',
          'falte a clase',
          'falte a la clase',
          'no fui a clases',
          'no fui a clase',
          'me perdi la clase',
          'me perdi las clases',
        ])) {
      return _dicho(
        'Pasa. Pídele los apuntes a alguien de tu curso y ponte al día hoy '
            'mismo, que mañana se acumula. Y para la próxima: alarma diez minutos '
            'antes y la mochila lista desde la noche.',
        'tarde',
      );
    }
    return null;
  }

  // ================================================================ profes
  static final _profe = RegExp(
    r' (?:profe|profesor|profesora|profesores|docente|docentes|licenciado|'
    r'licenciada|lic|ingeniero|ingeniera|inge) ',
  );

  static RespuestaCharla? _profes(String t) {
    if (!_profe.hasMatch(t)) return null;
    if (_dice(t, [
      'me odia',
      'me tiene bronca',
      'me tiene mania',
      'me tiene en la mira',
      'la tiene contra mi',
      'la agarro conmigo',
      'no me quiere',
      'me tiene rabia',
    ])) {
      return _dicho(
        'Uf. Casi nunca es personal, aunque se sienta así. Lo que sirve: '
            'acércate después de clase o en su horario de consulta, pregúntale '
            'algo de la materia (les gusta ver interés) y entrega todo a tiempo. '
            'Si de verdad hay un problema, habla con tu director de carrera.',
        'profe',
      );
    }
    if (_dice(t, [
      'explica mal',
      'no explica',
      'no explica bien',
      'no le entiendo',
      'no entiendo a mi',
      'no entiendo al',
      'no entiendo a la',
      'no se le entiende',
      'habla muy rapido',
      'es aburrido',
      'es aburrida',
    ])) {
      return RespuestaCharla(
        'Pasa más de lo que crees. Pregúntale en clase (tu duda la tienen '
        'otros diez), busca el mismo tema en otro lado (un libro, un video, un '
        'compañero que le entienda) y, si es álgebra, cálculo o C++, '
        'pregúntame a mí: te lo explico con ejemplos.',
        intencion: 'universidad:profe',
        opciones: _materias,
      );
    }
    if (_dice(t, [
      'es muy exigente',
      'es exigente',
      'es estricto',
      'es estricta',
      'reprueba a todos',
      'aplaza a todos',
      'jala a todos',
      'es muy dificil',
      'toma examenes dificiles',
    ])) {
      return _dicho(
        'Los exigentes suelen ser los que más enseñan, aunque duela. Pídele '
            'ejemplos de examen, practica con sus ejercicios (no con los de otro '
            'profe) y no dejes nada para la última semana.',
        'profe',
      );
    }
    return null;
  }

  // ============================================================== tramites
  static RespuestaCharla? _tramites(String t) {
    bool dice(List<String> frases) => _dice(t, frases);
    // Lo de la app tiene sus propias respuestas: "el horario de mi local".
    if (dice(['app', 'u market', 'umarket', 'local'])) return null;

    if (dice([
          'horario',
          'mi horario',
          'a que hora tengo',
          'a que hora entro',
        ]) &&
        !dice(['biblioteca'])) {
      return _dicho(
        'Tu horario de clases lo ves en el sistema de la UPSA, con tu cuenta '
            'de estudiante; yo no lo tengo. Si quieres, cuéntame cuándo tienes un '
            'examen (**tengo examen de cálculo el viernes**) y te lo recuerdo.',
        'tramite',
      );
    }
    if (dice(['biblioteca']) &&
        dice(['hora', 'horario', 'abre', 'cierra', 'abierta', 'cuando'])) {
      return _dicho(
        'No tengo el horario de la biblioteca y no quiero inventarte uno: '
            'pregunta en la entrada o mira la página de la U. Eso sí, es el mejor '
            'lugar del campus para estudiar en silencio.',
        'tramite',
      );
    }
    if (dice(['vacaciones']) &&
        dice([
          'cuando',
          'fecha',
          'fechas',
          'empiezan',
          'empieza',
          'terminan',
          'cuanto duran',
          'hasta cuando',
        ])) {
      return _dicho(
        'Las fechas exactas están en el **calendario académico** de la UPSA y '
            'cambian cada año, así que no te voy a inventar una. Míralo en la '
            'página de la U o pregúntalo en tu facultad. Y cuando lleguen, '
            'descansa de verdad.',
        'tramite',
      );
    }
    if (dice(['semestre', 'clases', 'gestion']) &&
        dice([
          'empieza',
          'empiezan',
          'comienza',
          'comienzan',
          'inicia',
          'inician',
          'inicio',
          'termina',
          'terminan',
          'acaba',
          'vuelven',
          'vuelvo',
        ])) {
      return _dicho(
        'El inicio y el fin de cada semestre están en el **calendario '
            'académico** de la UPSA. No lo tengo (cambia cada año y no uso '
            'internet): míralo en la página de la U o pregúntalo en tu facultad.',
        'tramite',
      );
    }
    if (dice([
      'inscribo',
      'inscribirme',
      'inscribir',
      'inscripcion',
      'inscripciones',
      'matricula',
      'matricularme',
      'matriculo',
      'agregar materias',
      'cargar materias',
      'elegir materias',
      'tomar materias',
    ])) {
      return _dicho(
        'Las inscripciones son con la universidad, no con la app: las fechas y '
            'los pasos los publica la UPSA en su sistema y en tu facultad. Si es tu '
            'primera vez, pregunta en tu carrera, que te lo explican al toque.',
        'tramite',
      );
    }
    if (dice([
      'mensualidad',
      'mensualidades',
      'cuota',
      'cuotas',
      'pension',
      'colegiatura',
      'arancel',
      'aranceles',
      'cuanto cuesta la carrera',
      'cuanto cuesta estudiar',
      'cuanto cuesta la u',
      'cuanto cuesta la upsa',
      'cuanto se paga en la u',
      'costo de la carrera',
    ])) {
      return _dicho(
        'Los costos los define la UPSA y cambian con el tiempo, así que no te '
            'doy un número que puede estar viejo. Pregúntalo en la universidad o '
            'míralo en su página oficial.',
        'tramite',
      );
    }
    if (dice(['beca', 'becas', 'becado', 'becada', 'media beca'])) {
      return _dicho(
        'Las universidades suelen tener becas por rendimiento, por deporte o '
            'por convenios. Las de la UPSA, con sus requisitos, pregúntalas directo '
            'en la U: lo peor que te pueden decir es que no.',
        'tramite',
      );
    }
    if (dice([
      'carnet universitario',
      'carnet de la u',
      'carnet de estudiante',
      'credencial',
      'saco mi carnet',
      'sacar mi carnet',
      'sacar el carnet',
      'tramitar mi carnet',
      'perdi mi carnet',
    ])) {
      return _dicho(
        'Eso se tramita en la U, no en la app. Pregunta en tu facultad dónde se '
            'saca y qué te piden.',
        'tramite',
      );
    }
    if (dice([
      'ver mis notas',
      'veo mis notas',
      'donde salen mis notas',
      'mis calificaciones',
      'mi promedio',
      'kardex',
      'record academico',
      'historial academico',
    ])) {
      return _dicho(
        'Tus notas oficiales las publica la UPSA en su sistema; la app no las '
            'tiene. Si quieres sacar tu promedio, dame las notas: por ejemplo, '
            '**promedio de 70, 85 y 90**.',
        'tramite',
      );
    }
    if (dice([
      'retirar una materia',
      'retirar materia',
      'retiro una materia',
      'retiro la materia',
      'retirarme de una materia',
      'retirarme de la materia',
      'retiro de materias',
      'dar de baja una materia',
      'abandonar una materia',
      'dejar una materia',
      'congelar',
      'congelar el semestre',
      'congelar la carrera',
    ])) {
      return _dicho(
        'Eso depende del reglamento de la UPSA y tiene fechas límite: '
            'pregúntalo en tu facultad cuanto antes, que fuera de plazo se '
            'complica.',
        'tramite',
      );
    }
    if (dice([
      'titularme',
      'titulacion',
      'como me titulo',
      'modalidades de titulacion',
      'modalidad de graduacion',
      'como me gradue',
      'graduarme',
    ])) {
      return _dicho(
        'Las modalidades (tesis, proyecto de grado, examen de grado y otras) y '
            'sus requisitos los define tu carrera: pregunta en tu dirección de '
            'carrera cuáles hay y desde qué semestre puedes empezar. Y si es '
            'tesis, te doy tips: escribe **cómo hago una tesis**.',
        'tramite',
      );
    }
    if (dice(['wifi', 'internet de la u', 'internet del campus'])) {
      return _dicho(
        'Clásico. Prueba en otro bloque o pregunta en la U por la red para '
            'estudiantes. Mientras tanto, yo funciono sin internet: conmigo no hay '
            'drama.',
        'tramite',
      );
    }
    if (dice([
      'parqueo',
      'estacionamiento',
      'donde estaciono',
      'donde parqueo',
    ])) {
      return _dicho(
        'No tengo el mapa del parqueo, pero en la entrada te orientan al '
            'toque.',
        'tramite',
      );
    }
    if (dice([
      'cuanto dura la carrera',
      'cuantos semestres',
      'cuantos anos dura',
      'cuanto dura mi carrera',
    ])) {
      return _dicho(
        'Depende de la carrera: las licenciaturas y las ingenierías suelen '
            'durar entre cuatro y cinco años. La duración exacta de la tuya está '
            'en su plan de estudios, en la página de la UPSA.',
        'tramite',
      );
    }
    return null;
  }

  // =============================================================== carrera
  /// De que va cada carrera de la UPSA, en una o dos frases.
  static const _deQueVa = {
    'Ingeniería de Sistemas':
        'Mucha demanda: casi toda empresa necesita software. Eso sí, hay que '
        'aprender siempre, porque la tecnología cambia rápido.',
    'Ingeniería Informática Administrativa':
        'Mezcla sistemas con empresa: muy pedida para manejar la tecnología de '
        'los negocios.',
    'Ingeniería Industrial y de Sistemas':
        'De las más versátiles: procesos, producción, calidad, logística y '
        'algo de sistemas. Hay trabajo en casi cualquier industria.',
    'Ingeniería Civil':
        'Construcción e infraestructura, y Santa Cruz no para de crecer. Mucha '
        'matemática, mucha física y trabajo de campo.',
    'Ingeniería Mecatrónica y Robótica':
        'Mecánica, electrónica y programación juntas: robots y '
        'automatización. Exigente y con mucho futuro.',
    'Ingeniería de Energías Sostenibles':
        'Energía solar, eficiencia y transición energética: un área que va a '
        'crecer muchísimo.',
    'Ingeniería Comercial':
        'Negocios con base de ingeniería: ventas, finanzas, emprendimiento. '
        'Abre muchas puertas.',
    'Ingeniería Económica':
        'Economía con números en serio: análisis, proyectos, bancos y '
        'consultoras.',
    'Ingeniería Financiera':
        'Inversiones, bancos, riesgo: si te gustan los números y la plata, '
        'tiene mucho campo.',
    'Administración de Empresas':
        'Sirve para todo: empresas, emprendimiento, gestión. Combinada con '
        'práctica real, rinde muchísimo.',
    'Auditoría y Finanzas':
        'Control, impuestos y finanzas: toda empresa necesita a alguien que '
        'sepa de eso.',
    'Comercio Internacional':
        'Importar, exportar, logística: con un país que comercia con todos sus '
        'vecinos, hay campo.',
    'Marketing y Publicidad':
        'Marcas, redes, campañas: creatividad con números. Y vender en U '
        'market ya es práctica.',
    'Derecho':
        'Mucha lectura y argumentación. Hay campo en lo corporativo, lo penal, '
        'lo laboral y más.',
    'Comunicación Estratégica y Corporativa':
        'Redes, prensa, comunicación de empresas: cada vez más importante.',
    'Diseño Gráfico':
        'Creatividad con técnica: arma tu portafolio desde el primer semestre.',
    'Diseño Industrial':
        'Diseñar objetos que se usan de verdad: creatividad, materiales y '
        'producción.',
    'Diseño y Gestión de la Moda':
        'Diseño y negocio de la moda: portafolio, tendencias y emprendimiento.',
    'Psicología':
        'Clínica, organizacional, educativa: el bienestar mental importa cada '
        'vez más.',
    'Arquitectura':
        'Diseño, técnica y muchas noches con maquetas. Muy linda si te '
        'apasiona.',
  };

  static final _sueldo = RegExp(
    r'\b(?:cuanto|que) (?:gana|ganan|cobra|cobran|se gana|pagan|paga)\b|'
    r'\b(?:sueldo|sueldos|salario|salarios)\b',
  );

  static final _profesion = RegExp(
    r'\b(?:ingeniero|ingeniera|ingenieros|abogado|abogada|abogados|psicologo|'
    r'psicologa|arquitecto|arquitecta|programador|programadora|programadores|'
    r'disenador|disenadora|contador|contadora|administrador|administradora|'
    r'economista|auditor|auditora|profesional|profesionales)\b',
  );

  static RespuestaCharla? _carrera(String limpio, String t) {
    bool dice(List<String> frases) => _dice(t, frases);
    if (_sueldo.hasMatch(limpio) &&
        !dice(['app', 'u market']) &&
        (_profesion.hasMatch(limpio) ||
            MemoriaMacias.carreraDe(limpio) != null ||
            dice(['sueldo', 'sueldos', 'salario', 'salarios']))) {
      return _dicho(
        'No tengo datos de sueldos al día, y en Bolivia cambian muchísimo según '
            'la empresa, la ciudad y la experiencia: no te voy a tirar un número '
            'inventado. Para una idea real, pregunta a alguien que ya trabaje de '
            'eso o mira ofertas de trabajo del rubro. Lo que sí sube el sueldo: '
            'idiomas, pasantías y proyectos propios.',
        'carrera',
      );
    }

    if (dice([
          'busco trabajo',
          'buscar trabajo',
          'necesito trabajo',
          'necesito un trabajo',
          'quiero trabajar',
          'conseguir trabajo',
          'consigo trabajo',
          'primer trabajo',
          'trabajo de medio tiempo',
          'medio tiempo',
          'pasantia',
          'pasantias',
          'hacer pasantias',
        ]) &&
        !dice(['app', 'u market', 'umarket', 'ustedes'])) {
      return _dicho(
        'Para arrancar:\n'
            '1. **La U**: pregunta en tu carrera por pasantías y convenios con '
            'empresas; suelen tener ofertas.\n'
            '2. **LinkedIn** y los grupos de empleo de Santa Cruz.\n'
            '3. **Tu gente**: profes y compañeros saben de oportunidades antes que '
            'nadie.\n'
            '4. Un CV de una hoja, claro (pregúntame **cómo hago un CV**).\n\n'
            'Y mientras tanto, vender algo en U market también es experiencia.',
        'carrera',
      );
    }
    if (dice([
      'cambiarme de carrera',
      'cambiar de carrera',
      'me quiero cambiar de carrera',
      'no me gusta mi carrera',
      'odio mi carrera',
      'dejar la carrera',
      'abandonar la carrera',
      'dejar la u',
      'abandonar la u',
    ])) {
      return _dicho(
        'No es fracaso: mucha gente se cambia y le va mejor. Antes de decidir, '
            'piensa si es la carrera o es una materia, un profe o un mal semestre. '
            'Habla con alguien que estudie la carrera que te llama y pregunta en la '
            'U qué materias te convalidan. Si es por plata o por cansancio, '
            'cuéntame y lo vemos.',
        'carrera',
      );
    }

    if (dice([
      'que carrera me recomiendas',
      'que carrera elegir',
      'que carrera elijo',
      'que carrera estudiar',
      'que carrera estudio',
      'no se que estudiar',
      'no se que carrera',
      'ayudame a elegir carrera',
      'ayudame a elegir una carrera',
      'test vocacional',
      'orientacion vocacional',
    ])) {
      return _dicho(
        'Elegir carrera es grande. Tres preguntas que ayudan:\n'
            '• ¿Qué materias te salían sin esfuerzo?\n'
            '• ¿En qué trabajo te imaginas un martes cualquiera?\n'
            '• ¿Qué problema te gustaría resolver?\n\n'
            'Habla con gente que ya la estudia (en el campus sobran) y, si puedes, '
            'haz un test vocacional. En la UPSA hay ingenierías (sistemas, '
            'industrial, civil, mecatrónica, energías...), negocios '
            '(administración, comercial, finanzas, marketing...), diseño, '
            'arquitectura, derecho, comunicación y psicología.',
        'carrera',
      );
    }

    final pregunta =
        dice([
          'vale la pena',
          'conviene estudiar',
          'me conviene estudiar',
          'es buena carrera',
          'es buena la carrera',
          'que tal es la carrera',
          'es la carrera de',
          'como es la carrera',
          'como es estudiar',
          'tiene futuro',
          'tiene trabajo',
          'hay trabajo',
          'tiene campo',
        ]) &&
        (dice(['estudiar', 'carrera', 'futuro', 'trabajo', 'campo']));
    if (!pregunta) return null;
    final carrera = MemoriaMacias.carreraDe(limpio);
    if (carrera == null) {
      if (!dice(['estudiar', 'carrera'])) return null;
      return _dicho(
        'Si te gusta y le pones ganas, casi cualquier carrera vale la pena: a '
            'la larga, rinde más quien disfruta lo que hace. ¿Cuál tienes en '
            'mente?',
        'carrera',
      );
    }
    return _dicho(
      '**$carrera**\n${_deQueVa[carrera] ?? 'Tiene su campo, como todas.'}\n\n'
          'Pero lo que más pesa es que te guste: a la larga, rinde más quien '
          'disfruta lo que hace.',
      'carrera',
    );
  }

  // ======================================================= donde estudiar
  static RespuestaCharla? _dondeEstudiar(String t) {
    if (!_dice(t, [
      'donde puedo estudiar',
      'lugar para estudiar',
      'lugar tranquilo para estudiar',
      'donde estudiar',
      'donde me pongo a estudiar',
      'un lugar tranquilo',
    ])) {
      return null;
    }
    return _dicho(
      'La **biblioteca** es lo más tranquilo del campus. Para estudiar en grupo, '
          'cualquier mesa fuera de la hora del almuerzo, y con audífonos se estudia '
          'en cualquier lado. Si es en casa: el celular lejos y una mesa que no sea '
          'tu cama.',
      'estudiar',
    );
  }
}
