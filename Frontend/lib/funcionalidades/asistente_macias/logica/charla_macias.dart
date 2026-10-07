import 'conocimiento_macias.dart';
import 'memoria_macias.dart';

/// Lo que MacIAs contesta en una charla: el texto y, si pregunto algo, que.
class RespuestaCharla {
  const RespuestaCharla(this.texto, {this.preguntaPorGusto});

  final String texto;

  /// Si termino preguntando "¿a ti te gusta?", sobre que. El "sí" o el "no"
  /// que venga despues se anota en la memoria.
  final String? preguntaPorGusto;
}

/// La parte de la conversacion que no es sobre la app ni las materias.
///
/// Sin esto, cualquier cosa fuera del guion ("¿te gusta la hamburguesa?")
/// recibia "no me la sé" y el menu entero otra vez, y la gente deja de
/// escribirle a un asistente que solo entiende lo que esta en su lista.
abstract final class CharlaMacias {
  // ------------------------------------------------------------- cuidado
  static const _crisis = [
    'me quiero morir',
    'quiero morir',
    'quiero morirme',
    'no quiero vivir',
    'no quiero seguir viviendo',
    'me voy a matar',
    'matarme',
    'suicid',
    'hacerme dano',
    'lastimarme',
    'cortarme',
  ];

  /// Lo primero que se revisa, antes que cualquier tema o broma.
  ///
  /// No hay forma de saber si es en serio, asi que se toma en serio: sin
  /// modo meme, sin chistes, con a quien acudir. Los numeros son los de
  /// emergencia de Bolivia.
  static String? cuidado(String limpio) {
    if (!_crisis.any(limpio.contains)) return null;
    return 'Lamento mucho que te sientas así. No estás solo ni sola, y '
        'hablarlo ayuda de verdad.\n'
        '• Busca ahora a alguien de confianza: un amigo, tu familia, un '
        'docente.\n'
        '• Pregunta en tu universidad por el servicio de orientación o de '
        'psicología.\n'
        '• Si estás en peligro ahora mismo, llama al **110** (Policía) o al '
        '**118** (emergencias médicas).\n\n'
        'Si quieres seguir escribiendo, aquí estoy.';
  }

  // -------------------------------------------------------------- charla
  static const _comidas = {
    'hamburguesa',
    'hamburguesas',
    'pizza',
    'pizzas',
    'saltena',
    'saltenas',
    'empanada',
    'empanadas',
    'tucumana',
    'tucumanas',
    'cunape',
    'cunapes',
    'sonso',
    'majadito',
    'keperi',
    'pollo',
    'pollo frito',
    'papas fritas',
    'papas',
    'sushi',
    'tacos',
    'helado',
    'helados',
    'chocolate',
    'torta',
    'pastel',
    'cafe',
    'te',
    'jugo',
    'jugos',
    'api',
    'mocochinchi',
    'somo',
    'hot dog',
    'panchito',
    'sandwich',
    'pan',
    'galletas',
    'fruta',
    'ensalada',
    'comida',
  };

  /// Responde a la charla, o null si el mensaje no es charla.
  static RespuestaCharla? responder(
    String limpio,
    ContextoMacias c, {
    required bool modoMeme,
  }) {
    // Lo que le preguntan a MacIAs sobre si mismo.
    final propio = _sobreMacias(limpio, c);
    if (propio != null) return RespuestaCharla(propio);

    final hora = _horaYFecha(limpio, c);
    if (hora != null) return RespuestaCharla(hora);

    final animo = _animo(limpio, c);
    if (animo != null) return RespuestaCharla(animo);

    return _opinion(limpio, c, modoMeme: modoMeme);
  }

  static String? _sobreMacias(String t, ContextoMacias c) {
    bool dice(List<String> frases) => frases.any(t.contains);

    if (dice(['cuantos anos tienes', 'que edad tienes', 'tu edad'])) {
      return 'Nací en 2026, así que soy bastante nuevo. Pero ya me sé el '
          'Baldor.';
    }
    if (dice(['donde vives', 'donde estas', 'de donde eres'])) {
      return 'Vivo en tu teléfono, al lado de tus apuntes. Y soy de Santa '
          'Cruz, del campus de la UPSA.';
    }
    if (dice([
      'tienes novia',
      'tienes novio',
      'tienes pareja',
      'estas soltero',
      'estas soltera',
      'te casarias',
    ])) {
      return 'Mi única relación seria es con el Baldor. Es complicada, pero '
          'estable.';
    }
    if (dice(['eres hombre o mujer', 'eres hombre', 'eres mujer'])) {
      return 'Soy un asistente, así que ninguno de los dos. Eso sí, me llamo '
          'MacIAs.';
    }
    if (dice([
      'tienes sentimientos',
      'sientes algo',
      'eres feliz',
      'te enojas',
      'te cansas',
    ])) {
      return 'Algo parecido: me pongo contento cuando te sirvo. Cansarme, '
          'nunca.';
    }
    if (dice(['comes', 'duermes', 'descansas'])) {
      return 'Ni como ni duermo: por eso respondo a cualquier hora.';
    }
    if (dice(['eres inteligente', 'sabes mucho', 'eres listo', 'eres lista'])) {
      return 'Sé bastante de la app y de algunas materias. Y cuando no sé '
          'algo, te lo digo en vez de inventarlo.';
    }
    if (dice(['te quiero', 'te amo', 'te adoro'])) {
      return 'Qué lindo, ${c.nombre}. Yo te aprecio tanto como un asistente '
          'puede. ¿Te ayudo con algo?';
    }
    if (dice(['eres el mejor', 'eres la mejor', 'eres genial', 'te pasaste'])) {
      return 'Gracias, ${c.nombre}. Así da gusto trabajar.';
    }
    if (dice(['sentido de la vida', 'el sentido de la vida'])) {
      return '42. Y aprobar Cálculo, que viene a ser lo mismo.';
    }
    if (dice(['clima', 'va a llover', 'hace calor', 'hace frio', 'surazo'])) {
      return 'No tengo forma de ver el clima. Eso sí, en Santa Cruz conviene '
          'estar listo para el calor y para algún surazo.';
    }
    return null;
  }

  static const _dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String? _horaYFecha(String t, ContextoMacias c) {
    final ahora = c.ahora;
    if (t.contains('que hora es') || t.contains('hora es') && t.length < 20) {
      final minutos = ahora.minute.toString().padLeft(2, '0');
      return 'Son las ${ahora.hour}:$minutos.'
          '${c.esDeNoche ? ' Ya es tarde: si estás estudiando, guarda algo '
                    'de sueño para el examen.' : ''}';
    }
    if (t.contains('que dia es') ||
        t.contains('que fecha es') ||
        t.contains('fecha de hoy') ||
        t.contains('en que ano estamos')) {
      return 'Hoy es ${_dias[ahora.weekday - 1]} ${ahora.day} de '
          '${_meses[ahora.month - 1]} de ${ahora.year}.';
    }
    return null;
  }

  static String? _animo(String t, ContextoMacias c) {
    bool dice(List<String> frases) => frases.any(t.contains);

    if (dice([
      'estoy triste',
      'me siento triste',
      'me siento mal',
      'estoy mal',
      'me siento solo',
      'me siento sola',
      'estoy deprimido',
      'estoy deprimida',
    ])) {
      return 'Lo siento, ${c.nombre}. Si quieres contarme, aquí estoy; y si es '
          'algo pesado, hablarlo con alguien de confianza ayuda mucho.\n\n'
          'Si te sirve distraerte un rato, escribe **chiste** o **dato '
          'curioso**.';
    }
    if (dice([
      'estoy estresado',
      'estoy estresada',
      'tengo examen',
      'tengo parcial',
      'tengo un examen',
      'no entiendo nada',
      'voy a reprobar',
      'voy a jalar',
      'estoy cansado',
      'estoy cansada',
    ])) {
      return 'Respira. Un tema a la vez: dime qué materia es (álgebra, '
          'cálculo o C++) y lo repasamos con ejemplos. También resuelvo '
          'ecuaciones paso a paso.\n\n'
          'Y un truco que funciona: 25 minutos de estudio, 5 de descanso.';
    }
    if (dice([
      'aprobe',
      'pase la materia',
      'estoy feliz',
      'saque buena nota',
    ])) {
      return '¡Felicidades, ${c.nombre}! Eso hay que celebrarlo. Si quieres, '
          'busca algo rico en el inicio para festejar.';
    }
    if (dice(['tengo hambre', 'tengo sed', 'que como', 'que puedo comer'])) {
      return 'Te entiendo. En el inicio está la categoría **Comida** con lo '
          'que venden en el campus, y si ya sabes qué quieres, búscalo '
          'arriba.';
    }
    return null;
  }

  static final _teGusta = RegExp(
    r'^(y )?(a ti )?te (gusta|gustan|encanta|encantan) (el |la |los |las |un |una )?(.+)$',
  );
  static final _opinas = RegExp(
    r'^que (opinas|piensas|dices) (de |del |sobre )(el |la |los |las )?(.+)$',
  );
  static final _favorito = RegExp(r'^cual es tu (.+?) (favorito|favorita)$');
  static final _prefieres = RegExp(r'^(que )?prefieres (.+) o (.+)$');

  static RespuestaCharla? _opinion(
    String t,
    ContextoMacias c, {
    required bool modoMeme,
  }) {
    final favorito = _favorito.firstMatch(t);
    if (favorito != null) {
      return RespuestaCharla(_favoritoDe(favorito.group(1)!, c));
    }

    final prefieres = _prefieres.firstMatch(t);
    if (prefieres != null) {
      final a = prefieres.group(2)!.trim();
      final b = prefieres.group(3)!.trim();
      final (elegido, otro) = c.sorteo.isEven ? (a, b) : (b, a);
      return RespuestaCharla(
        'Entre $a y $b, me quedo con $elegido. Que no se entere $otro.',
      );
    }

    final gusta = _teGusta.firstMatch(t) ?? _opinas.firstMatch(t);
    if (gusta == null) return null;
    final cosa = gusta.group(gusta.groupCount)!.trim();
    if (cosa.isEmpty || cosa.split(' ').length > 5) return null;

    final memoria = c.memoria;
    if (memoria.gustos.contains(cosa)) {
      return RespuestaCharla(
        'Me acuerdo de que a ti te gusta $cosa. Si yo comiera, te '
        'acompañaba.',
      );
    }
    if (_comidas.contains(cosa)) {
      return RespuestaCharla(
        'No como (soy puro código), pero si pudiera, $cosa entre clases no '
        'se rechaza. Si se te antojó, búscalo en el inicio: capaz alguien '
        'del campus lo está vendiendo.\n\n¿A ti te gusta?',
        preguntaPorGusto: cosa,
      );
    }
    final reaccion = switch (cosa) {
      'futbol' || 'el futbol' =>
        'Mientras no me hagas elegir entre Blooming y '
            'Oriente, todo bien.',
      'matematicas' || 'algebra' || 'calculo' =>
        'Mucho, sobre todo cuando '
            'sale exacto. Si quieres, practicamos un rato.',
      'programar' || 'programacion' || 'c' =>
        'Me encanta. Bueno, menos los '
            'segmentation fault.',
      'estudiar' => 'Me gusta ayudarte a estudiar, que es casi lo mismo.',
      'macias' || 'tu' => 'Me caigo bien, la verdad.',
      'la upsa' || 'upsa' || 'la universidad' => 'Es mi casa: aquí nací.',
      _ =>
        modoMeme
            ? '¿$cosa? Más que el Baldor, seguro. Aunque no tengo gustos '
                  'propios, eh.'
            : 'No tengo gustos propios, pero $cosa tiene lo suyo.',
    };
    return RespuestaCharla(
      '$reaccion\n\n¿A ti te gusta?',
      preguntaPorGusto: cosa,
    );
  }

  static String _favoritoDe(String que, ContextoMacias c) => switch (que) {
    'comida' || 'plato' =>
      'La salteña. Bien jugosa, de las que hay que '
          'comer con cuidado.',
    'color' => 'El verde, como mi marca de verificado.',
    'materia' => 'Álgebra, por el Baldor. Aunque Cálculo tiene su encanto.',
    'numero' => 'El 51: con eso se aprueba.',
    'equipo' =>
      'No me hagas elegir entre Blooming y Oriente, que en Santa '
          'Cruz eso termina mal.',
    'cancion' || 'musica' || 'banda' =>
      'No escucho música, pero dicen que '
          'estudiar con música tranquila ayuda.',
    'pelicula' || 'serie' =>
      'No veo películas, pero me cuentan que las de '
          'matemáticos siempre terminan bien.',
    'lenguaje' || 'lenguaje de programacion' =>
      'C++, por velocidad. Y Dart, '
          'porque estoy hecho en Dart.',
    _ => 'No tengo un $que favorito. ¿Cuál es el tuyo?',
  };

  // ------------------------------------------------------------- memoria
  static final _meLlamo = RegExp(
    r'(?:me llamo|mi nombre es|ll[aá]mame|puedes llamarme|dime nom[aá]s)\s+'
    r'([a-záéíóúñü]+(?:\s+[a-záéíóúñü]+)?)',
    caseSensitive: false,
  );

  static const _noSonNombres = {
    'que',
    'como',
    'el',
    'la',
    'un',
    'una',
    'de',
    'no',
    'si',
    'mas',
    'otro',
    'otra',
  };

  /// "me llamo Ana": el nombre tal como lo escribio, con mayuscula.
  static String? nombreEn(String original) {
    final encontrado = _meLlamo.firstMatch(original);
    if (encontrado == null) return null;
    final palabras = encontrado
        .group(1)!
        .split(RegExp(r'\s+'))
        .where((p) => !_noSonNombres.contains(p.toLowerCase()))
        .toList();
    if (palabras.isEmpty) return null;
    final nombre = palabras
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
    return nombre.length > 24 ? null : nombre;
  }

  static final _estudio = RegExp(
    r'^(?:yo )?(?:estudio|curso|mi carrera es|soy de|estoy en) (.+)$',
  );

  /// "estudio sistemas", "soy de derecho": la carrera, si es una de la UPSA.
  static String? carreraEn(String limpio) {
    final encontrado = _estudio.firstMatch(limpio);
    if (encontrado == null) return null;
    return MemoriaMacias.carreraDe(encontrado.group(1)!);
  }

  static final _meGusta = RegExp(
    r'^(?:a mi )?(no )?(?:me gusta|me gustan|me encanta|me encantan|amo|odio) '
    r'(?:el |la |los |las |un |una |mucho |mucho el |mucho la )?(.+)$',
  );

  /// Cosas que no son un gusto aunque vengan despues de "me gusta".
  static const _noSonGustos = [
    'esto',
    'eso',
    'esta respuesta',
    'tu respuesta',
    'como respondes',
    'la app',
    'macias',
    'que',
  ];

  /// "me gusta la pizza", "odio el surazo": que y si le gusta o no.
  static ({String cosa, bool gusta})? gustoEn(String limpio) {
    final encontrado = _meGusta.firstMatch(limpio);
    if (encontrado == null) return null;
    final cosa = encontrado.group(2)!.trim();
    if (cosa.isEmpty || cosa.length > 40 || _noSonGustos.contains(cosa)) {
      return null;
    }
    final niega = encontrado.group(1) != null || limpio.startsWith('odio');
    return (cosa: cosa, gusta: !niega);
  }

  static const _si = {
    'si',
    'claro',
    'obvio',
    'me encanta',
    'me gusta',
    'mucho',
    'por supuesto',
    'sip',
    'simon',
    'sii',
    'siii',
    'a full',
    'demasiado',
  };
  static const _no = {
    'no',
    'nop',
    'nada',
    'para nada',
    'no me gusta',
    'odio',
    'ni un poco',
    'naa',
    'nah',
  };

  /// Un "sí" o un "no" a la pregunta "¿a ti te gusta?". Null si es otra
  /// cosa.
  static bool? respuestaSiNo(String limpio) {
    if (_si.contains(limpio) || limpio.startsWith('si ')) return true;
    if (_no.contains(limpio) || limpio.startsWith('no ')) return false;
    return null;
  }

  // ---------------------------------------------------------- modo meme
  static const _memes = {
    'app': [
      'Dato no pedido: el vendedor tiene 15 minutos para aceptar. Tú tienes '
          '15 minutos para fingir que no tenías hambre.',
      'Comprar entre clases: el deporte extremo de la universidad.',
      'Si tu pedido vence, no es personal. Bueno, un poquito sí.',
      'Emprender en la U: vender salteñas para pagar las fotocopias del '
          'Baldor.',
    ],
    'algebra': [
      'El señor de la portada del Baldor te está mirando. Sí, a ti. '
          'Factoriza.',
      'Trinomio cuadrado perfecto: lo único perfecto de tu semestre.',
      'Dicen que el Baldor pesa más que tu mochila y tus ganas de estudiar '
          'juntas.',
      'Si la x no aparece, no la busques en tu ex. Despeja.',
    ],
    'calculo': [
      'No te olvides de la + C. Los profes la buscan como si fuera Wally.',
      'Integrar por partes es como dividir la cuenta en grupo: alguien '
          'siempre termina pagando u · v.',
      'La integral de 1/cabaña es ln|cabaña| + C. Con vista al mar, si '
          'tienes suerte.',
      'Cálculo II: donde "es inmediata" significa cuarenta minutos.',
    ],
    'cpp': [
      'Segmentation fault (core dumped): la forma que tiene C++ de decirte '
          'que no.',
      'Faltaba un punto y coma. No preguntes cómo lo sé: siempre es el punto '
          'y coma.',
      'En C++ manejas tu propia memoria. Como en la vida: si no sueltas lo '
          'que no usas, revientas.',
      '"En mi máquina funciona." Y en tu máquina no hay examen.',
    ],
    'general': [
      'Respondí más rápido que el WiFi de la U. Mínimo una estrellita.',
      'Estudiar a las 3 de la mañana no es mala organización: es estrategia '
          'avanzada.',
      'Si esto no te sirvió, al menos ya sabes que existo.',
    ],
  };

  /// La broma que acompaña una respuesta en modo meme.
  static String meme(String area, ContextoMacias c) =>
      c.alguna(_memes[area] ?? _memes['general']!);
}
