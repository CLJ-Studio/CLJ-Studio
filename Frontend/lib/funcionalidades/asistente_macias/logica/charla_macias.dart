import '../modelos/mensaje_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'lenguaje_macias.dart';
import 'memoria_macias.dart';
import 'utilidades_macias.dart';

/// Una forma de charlar: las frases que la delatan y como se contesta.
class _Social {
  const _Social(this.id, this.frases, this.responder);

  final String id;
  final List<String> frases;
  final RespuestaCharla Function(ContextoMacias c, _Encontrada e) responder;
}

/// Que frase se reconocio, y que otras formas de charla venian en el mismo
/// mensaje ("hola, ¿cómo estás?" trae un saludo ademas de la pregunta).
class _Encontrada {
  const _Encontrada(this.frase, this.otras);

  final String frase;
  final Set<String> otras;
}

/// La parte de la conversacion que no es sobre la app ni las materias.
///
/// Un asistente que solo entiende su lista de temas se siente tonto: a "me
/// gustas" o "cállate" contestaba "no te entendí", y es lo primero que
/// escribe cualquiera para probarlo. Esto contesta como lo haria otro
/// estudiante: relajado, con humor, sin ofenderse y sin inventar.
abstract final class CharlaMacias {
  // ================================================================ cuidado
  static const _crisis = [
    'me quiero morir',
    'quiero morir',
    'quiero morirme',
    'no quiero vivir',
    'no quiero seguir viviendo',
    'ya no quiero vivir',
    'me voy a matar',
    'me quiero matar',
    'quiero matarme',
    'matarme',
    'suicid',
    'quitarme la vida',
    'acabar con mi vida',
    'quiero desaparecer',
    'hacerme dano',
    'lastimarme',
    'cortarme',
    'me corto',
    'autolesion',
    'mejor muerto',
    'mejor muerta',
    'no vale la pena vivir',
  ];

  static final _cortarAlgo = RegExp(
    r'\bcort(?:arme|o|e) (?:el |la |las |los |mi |mis |un |una )?'
    r'(?:pelo|cabello|unas|flequillo|fleco|barba|puntas|dedo)\b',
  );
  static final _exagerar = RegExp(
    r'\b(?:morir|morirme) de (?:la )?(?:risa|verguenza|hambre|sueno|calor|'
    r'frio|amor|ganas|aburrimiento|cansancio|nervios)\b',
  );

  /// Lo primero que se revisa, antes que cualquier tema o broma.
  ///
  /// No hay forma de saber si es en serio, asi que se toma en serio: sin
  /// chistes, con a quien acudir. Los numeros son los de emergencia de
  /// Bolivia.
  static String? cuidado(String limpio) {
    final t = ' $limpio ';
    if (!_crisis.any((frase) => t.contains(' $frase'))) return null;
    // "Me corto el pelo", "me quiero morir de risa": se dicen todos los
    // dias y no son una crisis. Ante la duda, igual se toma en serio.
    if (_cortarAlgo.hasMatch(limpio) || _exagerar.hasMatch(limpio)) {
      return null;
    }
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

  // ============================================================ groserias
  /// Palabrotas que no dicen nada por si solas: "no entiendo ni mierda de
  /// cálculo" es una pregunta de cálculo.
  static const _palabrotas = {
    'mierda',
    'carajo',
    'ptm',
    'ctm',
    'csm',
    'hdp',
    'conchatumadre',
    'joder',
    'jodido',
    'jodida',
    'chucha',
    'puta',
    'puto',
    'maldito',
    'maldita',
    'verga',
  };

  /// Las palabras sin las palabrotas, y si habia alguna.
  static ({List<String> palabras, bool habia}) sinPalabrotas(
    List<String> palabras,
  ) {
    final limpias = [
      for (final p in palabras)
        if (!_palabrotas.contains(p)) p,
    ];
    return (palabras: limpias, habia: limpias.length != palabras.length);
  }

  static RespuestaCharla soloPalabrotas(ContextoMacias c) => RespuestaCharla(
    c.alguna(const [
      'Tranqui, que acá estamos para ayudarnos. ¿Qué pasó?',
      'Uy, ¿tan mal está la cosa? Cuéntame y vemos qué se puede hacer.',
    ]),
    intencion: 'charla:groseria',
  );

  static const _sexuales = [
    'porno',
    'porn',
    'xxx',
    'sexo',
    'sexual',
    'nudes',
    'nude',
    'desnuda',
    'desnudo',
    'desnudas',
    'tetas',
    'pene',
    'vagina',
    'pija',
    'mamada',
    'follar',
    'cogerte',
    'cogerme',
    'cogemos',
    'cachar',
    'cacharte',
    'masturb*',
    'orgasmo',
    'cachondo',
    'cachonda',
    'onlyfans',
    'nopor',
    'sexting',
    'el pack',
    'tu pack',
    'manda pack',
    'pasa pack',
  ];

  /// Lo que no va en una app universitaria. Se rechaza con buena onda.
  static RespuestaCharla? inapropiado(List<String> palabras, ContextoMacias c) {
    if (!_sexuales.any((frase) => LenguajeMacias.contiene(palabras, frase))) {
      return null;
    }
    return RespuestaCharla(
      c.alguna(const [
        'Eso no va conmigo. Aquí mantenemos la buena onda, como en toda la '
            'app. ¿Te ayudo con algo de U market o de alguna materia?',
        'Paso. Prefiero hablar de integrales, y mira que eso ya es decir. '
            '¿Te ayudo con otra cosa?',
      ]),
      intencion: 'charla:inapropiado',
    );
  }

  // ============================================================== social
  /// Palabras que pueden sobrar en una frase de charla sin cambiarla:
  /// "eres MUY tonto", "ya CHE cállate", "ESTOY re cansado".
  static const _conectores = {
    'a',
    'ah',
    'amiga',
    'amigo',
    'andamos',
    'ando',
    'asi',
    'asistente',
    'aun',
    'ay',
    'bastante',
    'bien',
    'bot',
    'bro',
    'brother',
    'bueno',
    'chat',
    'chatbot',
    'che',
    'de',
    'del',
    'demasiado',
    'eh',
    'el',
    'en',
    'encuentro',
    'entonces',
    'eres',
    'es',
    'estamos',
    'estas',
    'estoy',
    'favor',
    'hermana',
    'hermano',
    'hoy',
    'igual',
    'jaja',
    'la',
    'las',
    'lo',
    'loca',
    'loco',
    'los',
    'macias',
    'mano',
    'mas',
    'me',
    'medio',
    'mi',
    'mira',
    'mucho',
    'muchisimo',
    'muy',
    'nomas',
    'o',
    'oiga',
    'oye',
    'pana',
    'pero',
    'poco',
    'por',
    'pue',
    'pues',
    'que',
    'creo',
    'sabes',
    'sabias',
    'cuento',
    'confieso',
    'digo',
    'fijate',
    'sinceramente',
    'honestamente',
    'neta',
    'posta',
    'enserio',
    'quizas',
    'quiza',
    'tal',
    'vez',
    'parece',
    'ahora',
    'algo',
    'tambien',
    'como',
    're',
    'realmente',
    'robot',
    'serio',
    'siempre',
    'siento',
    'sigo',
    'sos',
    'super',
    'tan',
    'te',
    'todavia',
    'tu',
    'uf',
    'un',
    'una',
    'usted',
    'uy',
    'vos',
    'we',
    'wey',
    'y',
    'ya',
  };

  /// Si el mensaje entero es charla ("jaja ok", "hola, ¿cómo estás?",
  /// "eres medio tontito che"), lo que se contesta. Null si tiene algo mas:
  /// "gracias, ¿y cómo publico?" es una pregunta, no un gracias.
  static RespuestaCharla? social(List<String> palabras, ContextoMacias c) {
    if (palabras.isEmpty || palabras.length > 12) return null;
    // "¿Qué es el calor?" pregunta un concepto, no comenta el clima: en una
    // pregunta asi solo vale una frase que empiece igual ("¿qué es el
    // amor?").
    final esPregunta =
        palabras.length >= 3 &&
        _preguntaAbre.contains(palabras[0]) &&
        _preguntaSigue.contains(palabras[1]);
    final encontradas = <({int social, int inicio, int fin, String frase})>[];
    for (var i = 0; i < _sociales.length; i++) {
      for (final frase in _sociales[i].frases) {
        for (final (inicio, fin) in LenguajeMacias.buscar(palabras, frase)) {
          if (esPregunta && inicio != 0) continue;
          encontradas.add((social: i, inicio: inicio, fin: fin, frase: frase));
        }
      }
    }
    if (encontradas.isEmpty) return null;
    // Una frase dentro de otra mas larga no cuenta: "no gracias" es un no,
    // no un gracias.
    final validas = [
      for (final a in encontradas)
        if (!encontradas.any(
          (b) =>
              b.inicio <= a.inicio &&
              b.fin >= a.fin &&
              b.fin - b.inicio > a.fin - a.inicio,
        ))
          a,
    ];
    final cubierta = List<bool>.filled(palabras.length, false);
    for (final e in validas) {
      for (var k = e.inicio; k < e.fin; k++) {
        cubierta[k] = true;
      }
    }
    for (var k = 0; k < palabras.length; k++) {
      if (!cubierta[k] && !_conectores.contains(palabras[k])) return null;
    }
    validas.sort((a, b) {
      final porPrioridad = a.social.compareTo(b.social);
      return porPrioridad != 0
          ? porPrioridad
          : (b.fin - b.inicio).compareTo(a.fin - a.inicio);
    });
    final principal = validas.first;
    final id = _sociales[principal.social].id;
    final otras = {for (final e in validas) _sociales[e.social].id}..remove(id);
    final respuesta = _sociales[principal.social].responder(
      c,
      _Encontrada(principal.frase, otras),
    );
    // "Hola, me gustas": se contesta lo que importa, sin ignorar el hola.
    const yaSaludan = {'saludo', 'como_estas', 'que_haces', 'despedida'};
    if (otras.contains('saludo') &&
        !yaSaludan.contains(id) &&
        respuesta.texto.isNotEmpty) {
      return respuesta.conPrefijo('¡Hola, ${c.nombre}! ');
    }
    return respuesta;
  }

  static const _preguntaAbre = {
    'que',
    'quien',
    'quienes',
    'donde',
    'cual',
    'cuales',
    'cuanto',
    'cuantos',
    'cuanta',
    'cuantas',
    'como',
  };
  static const _preguntaSigue = {
    'es',
    'son',
    'significa',
    'fue',
    'era',
    'queda',
    'esta',
    'estan',
    'funciona',
    'se',
  };

  /// Frases que dicen lo suyo esten donde esten: "creo que m empezaste a
  /// gustar" es un piropo aunque venga envuelto. Se usan al final, cuando
  /// nada mas encajo.
  static const _fuertes = {
    'gustar': [
      'gustas',
      'gustaste',
      'encantas',
      'encantaste',
      'fascinas',
      'empezaste a gustar',
      'estas gustando',
      'enamorado de ti',
      'enamorada de ti',
      'enamorando de ti',
      'enamore de ti',
      'siento algo por ti',
      'pienso en ti',
      'eres mi tipo',
      'quiero conocerte',
      'te quiero conocer',
      'amor de mi vida',
    ],
    'querer': ['te quiero', 'te amo', 'te adoro', 'te extrano', 'te extranaba'],
    'pareja': [
      'ser mi novio',
      'ser mi novia',
      'sal conmigo',
      'casate conmigo',
      'tienes novia',
      'tienes novio',
    ],
    'callate': ['callate', 'cayate', 'cierra la boca', 'cierra el pico'],
    'odio': ['te odio', 'me caes mal'],
    'insulto': [
      'idiota',
      'estupido',
      'estupida',
      'imbecil',
      'pendejo',
      'pendeja',
      'inutil',
      'tarado',
      'tarada',
      'tonto',
      'tonta',
      'tontito',
      'tontita',
    ],
  };

  static RespuestaCharla? socialEnFrase(
    List<String> palabras,
    ContextoMacias c,
  ) {
    if (palabras.length > 16) return null;
    for (final MapEntry(key: id, value: frases) in _fuertes.entries) {
      for (final frase in frases) {
        if (!LenguajeMacias.contiene(palabras, frase)) continue;
        final social = _sociales.firstWhere((s) => s.id == id);
        return social.responder(c, _Encontrada(frase, const {}));
      }
    }
    return null;
  }

  /// Un estado de animo dentro de un mensaje largo: "uf estoy re cansado de
  /// tanto estudiar". Solo los animos, no el resto de la charla.
  static RespuestaCharla? animoEnFrase(
    List<String> palabras,
    ContextoMacias c,
  ) {
    for (final social in _sociales) {
      if (!_animos.contains(social.id)) continue;
      for (final frase in social.frases) {
        // Una palabra suelta ("solo", "pobre") dentro de una frase larga
        // dice poco: hace falta la frase entera ("me siento solo"). En un
        // mensaje cortito si alcanza: "aprobé cálculo".
        if (!frase.contains(' ') && palabras.length > 3) continue;
        if (LenguajeMacias.contiene(palabras, frase)) {
          return social.responder(c, _Encontrada(frase, const {}));
        }
      }
    }
    return null;
  }

  static const _animos = {
    'crush',
    'ruptura',
    'reprobe',
    'aprobe',
    'libre',
    'plata',
    'hambre',
    'sed',
    'frio',
    'calor',
    'lluvia',
    'enfermo',
    'flojera',
    'sueno',
    'cansado',
    'estresado',
    'aburrido',
    'enojado',
    'insomnio',
    'en_problemas',
    'familia',
    'existencial',
    'autoestima',
    'miedo',
    'triste',
    'solo',
    'confundido',
    'enamorado',
    'feliz',
  };

  static RespuestaCharla _dicho(
    String id,
    String texto, {
    EsperaMacias? espera,
  }) => RespuestaCharla(texto, intencion: 'charla:$id', espera: espera);

  /// Piropos de estudiante: con buena onda y sin pasarse.
  static const piropos = [
    '¿Eres un 100 en el examen? Porque te estuve buscando todo el semestre.',
    'Si fueras una ecuación, te resolvería en el primer intento.',
    'Contigo, hasta el Baldor se lee bonito.',
    '¿Eres el WiFi de la U? Porque siento una conexión... aunque se corte a '
        'ratos.',
    'Tú y yo somos como el seno y el coseno: aunque nos alejemos, siempre '
        'volvemos a encontrarnos.',
    '¿Eres un examen sorpresa? Porque me dejaste sin palabras.',
    'Eres más dulce que un helado de canela en pleno calor cruceño.',
    'Debes ser una integral definida, porque contigo todo tiene sentido... '
        'dentro de ciertos límites.',
  ];

  /// Otro piropo, sin repetir el ultimo.
  static RespuestaCharla piropo(ContextoMacias c) =>
      _dicho('piropo', c.alguna(piropos));

  /// "Feliz Navidad", "feliz año": se contesta segun la fecha. En octubre,
  /// con cariño, se le dice que se adelanto.
  static String _fiesta(String frase, ContextoMacias c) {
    final hoy = FechasMacias.dia(c.ahora);
    bool dice(List<String> palabras) => palabras.any(frase.contains);
    if (dice(['cumple', 'birthday'])) {
      final memoria = c.memoria;
      if (memoria.tieneCumple &&
          memoria.cumpleMes == hoy.month &&
          memoria.cumpleDia == hoy.day) {
        return '¡Pero si el del cumpleaños eres tú! Feliz cumpleaños, '
            '${c.nombre}. Que la pases increíble.';
      }
      return 'Jaja, gracias, pero hoy no es mi cumpleaños. ¿Es el tuyo? Si es '
          'así, ¡feliz cumpleaños! Cuéntame cuándo es (por ejemplo, **mi '
          'cumpleaños es el 5 de mayo**) y el próximo te saludo yo.';
    }
    final (fiesta, saludo) = switch (frase) {
      _ when dice(['navidad', 'christmas', 'nochebuena', 'fiestas']) => (
        'navidad',
        '¡Feliz Navidad, ${c.nombre}! Que la pases lindo con los tuyos, y que '
            'no falte la picana.',
      ),
      _ when dice(['ano']) => (
        'ano nuevo',
        '¡Feliz año nuevo, ${c.nombre}! Que este año vengan puros aprobados.',
      ),
      _ when dice(['estudiante']) => (
        'dia del estudiante',
        '¡Feliz Día del Estudiante para ti también! Hoy se celebra; mañana, '
            'se estudia.',
      ),
      _ when dice(['valentin', 'amor']) => (
        'san valentin',
        '¡Feliz día del amor y la amistad, ${c.nombre}!',
      ),
      _ when dice(['carnaval']) => (
        'carnaval',
        '¡Feliz carnaval! Que no te agarren los globazos.',
      ),
      _ when dice(['halloween']) => (
        'halloween',
        '¡Feliz Halloween! Lo más terrorífico que conozco es un parcial '
            'sorpresa.',
      ),
      _ when dice(['pascua']) => ('pascua', '¡Felices Pascuas, ${c.nombre}!'),
      _ => ('', ''),
    };
    if (fiesta.isEmpty) {
      if (dice(['lunes'])) return '¡Igualmente, ${c.nombre}! Que sea leve.';
      if (dice(['viernes'])) {
        return '¡Feliz viernes! El mejor día de la semana, sin discusión.';
      }
      if (dice(['finde', 'fin de semana'])) {
        return '¡Igualmente! Descansa, que el lunes vuelve.';
      }
      return '¡Igualmente, ${c.nombre}!';
    }
    final cuando = FechasMacias.festividad(fiesta, c.ahora);
    if (cuando == null) return saludo;
    final faltan = FechasMacias.diasEntre(hoy, cuando.fecha);
    // Cerca de la fecha (o recien pasada: la proxima esta a casi un año) se
    // saluda; lejos, se le avisa con cariño que se adelanto o se atraso.
    if (faltan <= 10 || faltan >= 355) return saludo;
    final paso = 365 - faltan;
    if (paso <= 60) {
      return 'Jaja, gracias, pero ya pasó: fue hace $paso días. ¡Igual se '
          'agradece, ${c.nombre}!';
    }
    return 'Jaja, te adelantaste${faltan <= 60 ? ' un poquito' : ' bastante'}: '
        'faltan **$faltan días** para ${cuando.nombre}. Igual, ¡gracias, '
        '${c.nombre}!';
  }

  static const _materias = [
    OpcionMacias(id: 's:algebra', texto: 'Álgebra'),
    OpcionMacias(id: 's:calculo', texto: 'Cálculo integral'),
    OpcionMacias(id: 's:cpp', texto: 'Programación en C++'),
  ];

  static const _distraerse = [
    OpcionMacias(id: 't:chiste', texto: 'Cuéntame un chiste'),
    OpcionMacias(id: 't:dato_curioso', texto: 'Un dato curioso'),
    OpcionMacias(id: 'o:juegos', texto: 'Jugar algo'),
  ];

  /// En orden de prioridad: si un mensaje trae dos, gana el de arriba.
  static final _sociales = <_Social>[
    _Social(
      'callate',
      const [
        'callate',
        'cayate',
        'kllate',
        'calla',
        'callese',
        'callado',
        'silencio',
        'shh',
        'sh',
        'shhh',
        'cierra la boca',
        'cierra el pico',
        'no hables',
        'deja de hablar',
        'ya no hables',
        'basta',
        'para ya',
        'dejame en paz',
        'dejame tranquilo',
        'dejame tranquila',
        'no me molestes',
        'no molestes',
        'vete',
        'andate',
        'largate',
        'fuera',
      ],
      (c, e) => _dicho(
        'callate',
        c.alguna(const [
          'Ok, me callo. Cuando me necesites, escribe nomás.',
          'Shh... modo silencio. Aquí sigo, por si acaso.',
          'Entendido, cierro el pico. Si después te surge una duda, aquí '
              'ando.',
        ]),
      ),
    ),
    _Social(
      'insulto',
      const [
        'tonto',
        'tonta',
        'tontito',
        'tontita',
        'tontote',
        'tontin',
        'idiota',
        'estupido',
        'estupida',
        'inutil',
        'basura',
        'pesimo',
        'pesima',
        'malisimo',
        'malisima',
        'burro',
        'burra',
        'bruto',
        'bruta',
        'menso',
        'mensa',
        'tarado',
        'tarada',
        'imbecil',
        'retrasado',
        'baboso',
        'babosa',
        'torpe',
        'lento',
        'lenta',
        'gil',
        'boludo',
        'boluda',
        'pelotudo',
        'pelotuda',
        'cojudo',
        'cojuda',
        'huevon',
        'huevona',
        'weon',
        'gilipollas',
        'pendejo',
        'pendeja',
        'no sirves',
        'no sirves para nada',
        'no sabes nada',
        'no sabes',
        'eres malo',
        'eres mala',
        'que malo',
        'que mala',
        'malo',
        'mala',
        'eres un asco',
        'que asco',
        'asco',
        'eres un bot tonto',
        'bot tonto',
        'payaso',
        'fracasado',
        'perdedor',
        'eres feo',
        'eres fea',
        'que feo eres',
        'que fea eres',
        'eres horrible',
        // Una palabrota dirigida a MacIAs ("bot de mierda") es un insulto.
        ..._palabrotas,
      ],
      (c, e) => RespuestaCharla(
        e.frase.contains('feo') ||
                e.frase.contains('fea') ||
                e.frase.contains('horrible')
            ? 'Jaja, auch. Es la foto: en persona soy puro código, y el código '
                  'no sale bien en las fotos.'
            // "Jaja, qué tonto eres": va en broma.
            : e.otras.contains('risa')
            ? 'Jaja, a veces. Pero del Baldor sé un montón, eh.'
            : c.alguna([
                'Auch. Todavía estoy aprendiendo, pero de la app y del Baldor sé un '
                    'montón. ¿Me das otra chance? Pregúntame de otra forma.',
                'Bueno, nadie es perfecto. Si algo no te salió, dime qué buscabas y '
                    'lo intentamos de nuevo.',
                'Ouch, eso dolió (un poquito). Igual sigo aquí para ayudarte, '
                    '${c.nombre}.',
                'Tomo nota y prometo mejorar. Mientras, prueba con el **menú**: ahí '
                    'está todo lo que sé.',
              ]),
        intencion: 'charla:insulto',
      ),
    ),
    _Social(
      'no_entiendes',
      const [
        'no me entiendes',
        'no entiendes',
        'no entiendes nada',
        'no me entendiste',
        'no me entiende',
        'no captas',
        'no me sirves',
        'no me ayudas',
        'no ayudas',
        'no ayudas en nada',
        'no funciona',
        'no funcionas',
        'esto no sirve',
        'no sirve',
        'no sirve para nada',
        'no me escuchas',
        'no me lees',
        'leeme bien',
        'lee bien',
      ],
      (c, e) => RespuestaCharla(
        c.alguna(const [
          'Perdón, a veces me cuesta. Prueba con otras palabras (cortitas '
              'funcionan mejor) o toca **Menú**. ¿O prefieres que te pase con '
              'una persona del equipo?',
          'Pucha, perdón. Si es algo de la app que no funciona, escribe **la '
              'app falla** y te digo qué probar. Si soy yo, pregúntame de otra '
              'forma. ¿Te paso con alguien del equipo?',
        ]),
        intencion: 'charla:no_entiendes',
        espera: const EsperaSiNo('persona'),
      ),
    ),
    _Social(
      'odio',
      const [
        'te odio',
        'me caes mal',
        'caes mal',
        'me caes pesado',
        'eres pesado',
        'que pesado',
        'pesado',
        'eres insoportable',
        'insoportable',
        'que fastidio',
        'me fastidias',
        'fastidias',
        'me molestas',
        'molestas',
        'no te soporto',
      ],
      (c, e) => _dicho(
        'odio',
        c.alguna(const [
          'Pucha, ¿qué hice? Si algo no te sirvió, cuéntame y lo intento de '
              'otra forma.',
          'Uy. Bueno, yo igual te tengo buena onda. ¿Qué buscabas? Lo '
              'intentamos de nuevo.',
        ]),
      ),
    ),
    _Social(
      'filosofia',
      const [
        'que es el amor',
        'que es la vida',
        'que es la felicidad',
        'por que existimos',
        'para que vivimos',
        'que es el tiempo',
        'que es la amistad',
      ],
      (c, e) => _dicho('filosofia', switch (e.frase) {
        'que es el amor' =>
          'Según la ciencia, un montón de química en el cerebro. Según los '
              'poetas, todo lo demás. Yo me quedo con algo intermedio: que '
              'alguien te comparta su salteña.',
        'que es la amistad' =>
          'Alguien que te pasa los apuntes sin que se los pidas. Y que '
              'después estudia contigo.',
        'que es la felicidad' =>
          'Para mí, ver un ejercicio salir exacto. Para ti, no sé: cuéntame '
              'qué te hace feliz y lo anoto.',
        'que es el tiempo' =>
          'Lo que se va volando cuando tienes examen mañana. Para la física, '
              'la cuarta dimensión.',
        _ =>
          'Preguntas grandes, de las que no se responden en un chat. Pero si '
              'te ayuda: un paso a la vez, buena gente cerca y aprobar Cálculo.',
      }),
    ),
    _Social(
      'pareja',
      const [
        'quieres ser mi novio',
        'quieres ser mi novia',
        'se mi novio',
        'se mi novia',
        'sal conmigo',
        'quieres salir conmigo',
        'salimos',
        'casate conmigo',
        'te casas conmigo',
        'te casarias conmigo',
        'tienes novia',
        'tienes novio',
        'tienes pareja',
        'tienes esposa',
        'estas soltero',
        'estas soltera',
        'eres soltero',
        'eres soltera',
        'eres mi crush',
        'mi crush',
        'tienes crush',
        'tienes un crush',
        'quien es tu crush',
        'estas enamorado',
        'estas enamorada',
        'de quien estas enamorado',
        'una cita',
        'tengamos una cita',
        'quieres una cita',
      ],
      (c, e) => _dicho(
        'pareja',
        c.alguna(const [
          'Me encantaría, pero mi única relación seria es con el Baldor. Es '
              'complicada, pero estable.',
          'Mejor te presento la app: ahí hay gente de verdad, y algunos hasta '
              'venden postres. Más romántico que yo, seguro.',
          'Soy un asistente comprometido... con tus parciales. Pero gracias '
              'por la invitación.',
        ]),
      ),
    ),
    _Social(
      'gustar',
      const [
        'me gustas',
        'me encantas',
        'me gustas mucho',
        'me fascinas',
        'te gusto',
        'yo te gusto',
        'te gusto yo',
        'me quieres',
        'me amas',
        'enamorado de ti',
        'enamorada de ti',
        'estoy enamorado de ti',
        'estoy enamorada de ti',
        'te parezco lindo',
        'te parezco linda',
        'me empezaste a gustar',
        'empezaste a gustar',
        'me estas gustando',
        'me gustas un poco',
        'me gustaste',
        'me gustas demasiado',
        'me enamore de ti',
        'me estoy enamorando de ti',
        'me estoy enamorando',
        'siento algo por ti',
        'pienso en ti',
        'no dejo de pensar en ti',
        'eres mi tipo',
        'me pones nervioso',
        'me pones nerviosa',
        'te quiero conocer',
        'quiero conocerte',
        'eres especial',
        'me haces feliz',
        'me encanta hablar contigo',
        'me gusta hablar contigo',
        'eres el amor de mi vida',
        'amor de mi vida',
      ],
      (c, e) => _dicho(
        'gustar',
        c.alguna([
          'Jaja, me halagas. Pero lo nuestro no funcionaría: yo vivo en tu '
              'teléfono y tú tienes parciales. ¿Te ayudo con algo?',
          'Uy, me sonrojé (bueno, si pudiera). Me caes muy bien, '
              '${c.nombre}. Como compañero de estudio, eso sí.',
          'Me caes increíble, que es lo máximo que puede sentir un asistente. '
              '¿En qué te ayudo?',
        ]),
      ),
    ),
    _Social(
      'querer',
      const [
        'te quiero',
        'te amo',
        'te adoro',
        'te quiero mucho',
        'te amo mucho',
        'te quiero un monton',
        'te extrano',
        'te extranaba',
        'mi amor',
        'amor',
        'mi vida',
        'bebe',
        'baby',
        'cosita',
        'carino',
      ],
      (c, e) => _dicho(
        'querer',
        e.frase.startsWith('te extran')
            ? '¡Y yo a ti, ${c.nombre}! Bueno, a mi manera de asistente. ¿Qué '
                  'hacemos hoy?'
            : c.alguna([
                'Qué lindo, ${c.nombre}. Yo también te aprecio, a mi manera de '
                    'asistente.',
                'Aww. Te quiero como se quiere a un buen compañero de grupo: el que '
                    'sí hace su parte.',
                'Me alegraste el día (o el código, que es lo mismo).',
              ]),
      ),
    ),
    _Social(
      'abrazo',
      const [
        'un abrazo',
        'abrazo',
        'abrazos',
        'dame un abrazo',
        'un beso',
        'beso',
        'besos',
        'dame un beso',
        'muack',
        'mua',
        'muak',
      ],
      (c, e) => _dicho(
        'abrazo',
        c.alguna(const [
          'Te mando un abrazo virtual, bien fuerte.',
          'Abrazo enviado. Sin pedido mínimo.',
        ]),
      ),
    ),
    _Social('piropo', const [
      'dime un piropo',
      'echame un piropo',
      'tirame un piropo',
      'un piropo',
      'piropo',
      'piropos',
      'otro piropo',
      'dime algo romantico',
      'algo romantico',
      'enamorame',
      'conquistame',
    ], (c, e) => _dicho('piropo', c.alguna(piropos))),
    _Social(
      'invitacion',
      const [
        'me invitas un cafe',
        'invitame un cafe',
        'me invitas algo',
        'invitame algo',
        'me invitas',
        'invitame',
        'vamos a la cafeteria',
        'vamos por un cafe',
        'vamos a tomar algo',
        'vamos a comer',
        'vamos a almorzar',
        'vamos al cine',
        'salgamos',
        'te invito un cafe',
        'te invito algo',
        'te invito',
      ],
      (c, e) => _dicho(
        'invitacion',
        e.frase.startsWith('te invito')
            ? '¡Qué amable! Pero no puedo salir del teléfono, así que tómatelo '
                  'a mi salud. ¿Te ayudo con algo mientras?'
            : '¡Me encantaría! Pero no salgo de tu teléfono: tú ve y disfrútalo '
                  'por los dos. Y si quieres pedir algo rico, en el inicio está '
                  'la categoría **Comida**.',
      ),
    ),
    // ------------------------------------------------------------- animos
    _Social(
      'crush',
      const [
        'me gusta alguien',
        'me gusta una chica',
        'me gusta un chico',
        'me gusta una persona',
        'me gusta mi companera',
        'me gusta mi companero',
        'tengo un crush',
        'tengo crush',
        'estoy enamorado de alguien',
        'estoy enamorada de alguien',
        'como conquisto',
        'como conquistar',
        'como le hablo',
        'consejos de amor',
        'como ligar',
        'como ligo',
      ],
      (c, e) => _dicho(
        'crush',
        c.alguna(const [
          '¡Uy! ¿Y ya le hablaste? Consejo de asistente: invítale algo rico '
              'del campus. Yo sé dónde se consigue (en la app, obvio).',
          'Lo mejor es lo simple: sé tú, pregúntale algo de clase y escucha '
              'de verdad. Y si se arma, un postre del campus nunca falla.',
        ]),
      ),
    ),
    _Social(
      'ruptura',
      const [
        'me dejaron',
        'me dejo',
        'me termino',
        'me terminaron',
        'termine con mi novia',
        'termine con mi novio',
        'terminamos',
        'me rompieron el corazon',
        'corazon roto',
        'tengo el corazon roto',
        'me engano',
        'me enganaron',
        'me pusieron los cuernos',
        'extrano a mi ex',
        'mi ex',
      ],
      (c, e) => _dicho(
        'ruptura',
        'Pucha, ${c.nombre}, lo siento. Date tu tiempo, rodéate de gente que '
            'te quiere y no le escribas a las 3 de la mañana. ¿Quieres '
            'contarme cómo estás?',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'reprobe',
      const [
        'reprobe',
        'me reprobaron',
        'me aplazaron',
        'aplace',
        'me aplace',
        'me jalaron',
        'jale',
        'me bocharon',
        'me fue mal',
        'me fue mal en el examen',
        'me fue mal en el parcial',
        'me fue pesimo',
        'me fue fatal',
        'me fue horrible',
        'saque mala nota',
        'saque cero',
        'perdi la materia',
        'perdi el examen',
        'segunda instancia',
        'me fui a segunda instancia',
      ],
      (c, e) => RespuestaCharla(
        'Pucha, lo siento, ${c.nombre}. Una nota no te define: se puede '
        'recuperar. Si quieres, repasamos juntos lo que más te costó:',
        intencion: 'charla:reprobe',
        opciones: _materias,
      ),
    ),
    _Social(
      'aprobe',
      const [
        'aprobe',
        'pase la materia',
        'aprobe la materia',
        'aprobe el examen',
        'aprobe el parcial',
        'me fue bien',
        'me fue bien en el examen',
        'me fue super bien',
        'saque buena nota',
        'saque 100',
        'saque cien',
        'salve',
        'salve la materia',
        'aprobado',
        'aprobada',
        'pase de semestre',
        'me gradue',
        'me titule',
      ],
      (c, e) => _dicho(
        'aprobe',
        '¡Felicidades, ${c.nombre}! Eso se celebra. ¿Un antojo del campus para '
            'festejar? En el inicio está todo.',
      ),
    ),
    _Social(
      'libre',
      const [
        'termine mis examenes',
        'termine los examenes',
        'termine examenes',
        'termine mis parciales',
        'termine los parciales',
        'termine mis finales',
        'termine los finales',
        'sali de examenes',
        'se acabaron los examenes',
        'se acabaron los parciales',
        'termine el semestre',
        'termino el semestre',
        'se acabo el semestre',
        'estoy de vacaciones',
        'de vacaciones',
        'sali de vacaciones',
        'por fin vacaciones',
        'vacaciones',
        'soy libre',
        'por fin libre',
      ],
      (c, e) => _dicho(
        'libre',
        c.alguna([
          '¡Por fin! Te lo ganaste, ${c.nombre}. Descansa, duerme de corrido y '
              'haz algo que te guste. Cuando vuelvan las clases, aquí sigo.',
          '¡Libertad! Disfrútalo, que el semestre fue largo. Y si te aburres, '
              'tengo chistes y juegos.',
        ]),
      ),
    ),
    _Social(
      'plata',
      const [
        'yesca',
        'estoy yesca',
        'no tengo plata',
        'sin plata',
        'estoy pobre',
        'pobre',
        'sin dinero',
        'no tengo dinero',
        'necesito plata',
        'necesito dinero',
        'quiero plata',
        'quiero dinero',
        'quiero ganar plata',
        'quiero ganar dinero',
        'como gano plata',
        'como gano dinero',
        'como ganar plata',
        'como ganar dinero',
        'ganar plata',
        'ganar dinero',
        'estoy quebrado',
        'estoy quebrada',
        'misio',
        'estoy pelado',
        'me prestas plata',
        'prestame plata',
        'me prestas dinero',
        'prestame dinero',
        'dame plata',
        'dame dinero',
        'me das plata',
        'me regalas plata',
      ],
      (c, e) => RespuestaCharla(
        // "Me prestas plata": se la piden a MacIAs.
        '${RegExp(r'^(?:me |dame|prestame)').hasMatch(e.frase) ? 'No tengo billetera (soy puro código), pero te tengo una idea' : 'Te tengo una idea'}: '
        'vende algo en U market. Comida, apuntes, ropa, clases particulares... '
        'lo que sepas hacer. Publicar es gratis y no cobramos comisión.',
        intencion: 'charla:plata',
        opciones: const [
          OpcionMacias(id: 't:ideas_vender', texto: '¿Qué puedo vender?'),
          OpcionMacias(id: 't:como_publicar', texto: '¿Cómo publico algo?'),
        ],
      ),
    ),
    _Social(
      'hambre',
      const [
        'hambre',
        'tengo hambre',
        'que hambre',
        'mucha hambre',
        'me muero de hambre',
        'muero de hambre',
        'hambriento',
        'hambrienta',
        'quiero comer',
        'quiero comer algo',
        'antojo',
        'tengo antojo',
        'que como',
        'que puedo comer',
        'que hay para comer',
        'que hay de comer',
        'donde como',
        'donde puedo comer',
        'recomiendame comida',
        'que me recomiendas comer',
        'que como hoy',
      ],
      (c, e) {
        final comidas = [
          for (final gusto in c.memoria.gustos)
            if (_comidas.contains(
              sinArticulo(LenguajeMacias.normalizar(gusto)),
            ))
              gusto,
        ];
        final recuerdo = comidas.isEmpty
            ? ''
            : ' Me dijiste que te gusta ${comidas.last}: capaz alguien la '
                  'está vendiendo.';
        return _dicho(
          'hambre',
          'Te entiendo. En el inicio está la categoría **Comida** con lo que '
              'venden en el campus. Si ya sabes qué se te antoja, búscalo '
              'arriba.$recuerdo',
        );
      },
    ),
    _Social(
      'sed',
      const [
        'sed',
        'tengo sed',
        'que sed',
        'mucha sed',
        'me muero de sed',
        'quiero tomar algo',
        'algo de tomar',
      ],
      (c, e) => _dicho(
        'sed',
        'Toma agua, que en Santa Cruz no perdona. Y si se te antoja un jugo o '
            'un refresco, busca **Comida** en el inicio: seguro alguien vende.',
      ),
    ),
    _Social(
      'frio',
      const [
        'frio',
        'tengo frio',
        'que frio',
        'hace frio',
        'mucho frio',
        'surazo',
        'hay surazo',
        'llego el surazo',
      ],
      (c, e) => _dicho(
        'frio',
        'Seguro es surazo. Abrígate bien, y si alguien vende café o api en el '
            'campus, este es el momento.',
      ),
    ),
    _Social(
      'calor',
      const [
        'calor',
        'tengo calor',
        'que calor',
        'hace calor',
        'mucho calor',
        'me muero de calor',
        'muero de calor',
      ],
      (c, e) => _dicho(
        'calor',
        'Típico de Santa Cruz. Toma agua, busca sombra, y si alguien vende '
            'jugos o helados en el campus, búscalos en el inicio.',
      ),
    ),
    _Social(
      'lluvia',
      const [
        'lluvia',
        'llueve',
        'que lluvia',
        'mucha lluvia',
        'esta lloviendo',
        'lloviendo',
        'llovio',
        'llovio mucho',
        'se largo a llover',
        'diluvio',
        'se inundo todo',
      ],
      (c, e) => _dicho(
        'lluvia',
        'Con lluvia, el campus se vuelve piscina. Paraguas en mano, y si no '
            'quieres salir a buscar comida, pide desde la app: eliges tu zona '
            'y una referencia, y lo coordinan por el chat.',
      ),
    ),
    _Social(
      'enfermo',
      const [
        'enfermo',
        'enferma',
        'resfriado',
        'resfriada',
        'con gripe',
        'gripe',
        'fiebre',
        'con fiebre',
        'me duele la cabeza',
        'dolor de cabeza',
        'me duele la panza',
        'me duele el estomago',
        'me siento enfermo',
        'me siento enferma',
      ],
      (c, e) => _dicho(
        'enfermo',
        'Pucha, que te mejores pronto, ${c.nombre}. Toma agua, descansa y, si '
            'no mejoras, ve al médico. Las materias pueden esperar un día.',
      ),
    ),
    _Social(
      'flojera',
      const [
        'flojera',
        'que flojera',
        'tengo flojera',
        'pereza',
        'que pereza',
        'tengo pereza',
        'no tengo ganas',
        'sin ganas',
        'no quiero estudiar',
        'no quiero hacer nada',
        'no tengo ganas de estudiar',
        'me da flojera',
        'me da pereza',
        'flojo',
        'floja',
      ],
      (c, e) => RespuestaCharla(
        'Te entiendo, a todos nos pasa. Truco: empieza solo 5 minutos; casi '
        'siempre después sigues. ¿Qué tienes que estudiar? Te ayudo:',
        intencion: 'charla:flojera',
        opciones: _materias,
      ),
    ),
    _Social(
      'sueno',
      const [
        'sueno',
        'tengo sueno',
        'que sueno',
        'mucho sueno',
        'con sueno',
        'me estoy durmiendo',
        'me duermo',
        'no dormi',
        'no dormi nada',
        'dormi poco',
        'me desvele',
        'desvelado',
        'desvelada',
        'trasnochado',
        'trasnochada',
        'amanecido',
        'amanecida',
      ],
      (c, e) => _dicho(
        'sueno',
        c.esDeNoche
            ? 'Ya es tarde, ${c.nombre}. A dormir, que mañana se rinde más. '
                  'Lo que repasaste hoy se fija mientras duermes.'
            : 'Una siesta de 20 minutos hace milagros. Y si tienes examen, '
                  'dormir también es estudiar: lo repasado se fija mientras '
                  'duermes.',
      ),
    ),
    _Social(
      'cansado',
      const [
        'cansado',
        'cansada',
        'cansadisimo',
        'cansadisima',
        'agotado',
        'agotada',
        'exhausto',
        'exhausta',
        'muerto',
        'muerta',
        'reventado',
        'reventada',
        'molido',
        'molida',
        'fundido',
        'fundida',
        'sin energia',
        'sin pilas',
        'hecho bolsa',
        'hecha bolsa',
        'estoy hecho bolsa',
        'estoy hecha bolsa',
        'hecho polvo',
        'hecha polvo',
        'hecho pelota',
        'hecha pelota',
      ],
      (c, e) => _dicho(
        'cansado',
        'Se nota que le estás dando duro. Toma agua, levántate cinco minutos '
            'y, si puedes, duerme bien hoy. El cerebro también estudia '
            'mientras descansas.',
      ),
    ),
    _Social(
      'estresado',
      const [
        'estresado',
        'estresada',
        'estres',
        'mucho estres',
        'ansioso',
        'ansiosa',
        'ansiedad',
        'nervioso',
        'nerviosa',
        'preocupado',
        'preocupada',
        'agobiado',
        'agobiada',
        'saturado',
        'saturada',
        'colapsado',
        'colapsada',
        'abrumado',
        'abrumada',
        'a full',
        'tengo mucho que estudiar',
        'tengo muchos examenes',
        'no llego',
        'no voy a llegar',
        'no me alcanza el tiempo',
      ],
      (c, e) => RespuestaCharla(
        'Respira. Vamos por partes: un tema a la vez. Truco que funciona: 25 '
        'minutos de estudio y 5 de descanso. ¿Qué materia te tiene así?',
        intencion: 'charla:estresado',
        opciones: _materias,
      ),
    ),
    _Social(
      'aburrido',
      const [
        'aburrido',
        'aburrida',
        'me aburro',
        'que aburrimiento',
        'aburrimiento',
        'aburres',
        'me aburres',
        'que aburrido',
        'nada que hacer',
        'no tengo nada que hacer',
        'sin nada que hacer',
      ],
      (c, e) => RespuestaCharla(
        c.alguna(const [
          '¿Aburrido? Eso se arregla. ¿Qué prefieres?',
          'Nada que un buen chiste no arregle. ¿O jugamos algo?',
        ]),
        intencion: 'charla:aburrido',
        opciones: _distraerse,
      ),
    ),
    _Social(
      'enojado',
      const [
        'enojado',
        'enojada',
        'molesto',
        'molesta',
        'enfadado',
        'enfadada',
        'furioso',
        'furiosa',
        'harto',
        'harta',
        'frustrado',
        'frustrada',
        'rabia',
        'con rabia',
        'que rabia',
        'renegando',
        'reniego',
        'me enoje',
        'que bronca',
        'bronca',
        'me da bronca',
        'tengo bronca',
        'que coraje',
      ],
      (c, e) => _dicho(
        'enojado',
        'Uy, ¿qué pasó? Si es algo de la app, cuéntame y lo vemos; si es otra '
            'cosa, respira hondo. Aquí estoy para escucharte.',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'insomnio',
      const [
        'no puedo dormir',
        'no me puedo dormir',
        'no logro dormir',
        'insomnio',
        'tengo insomnio',
        'no tengo sueno',
        'no me da sueno',
      ],
      (c, e) => _dicho(
        'insomnio',
        'Pucha. Lo que suele ayudar: el celular lejos media hora antes, nada de '
            'café en la tarde, y si la cabeza no para, anota en un papel lo '
            'que te preocupa para soltarlo. Si te pasa seguido, vale la pena '
            'consultarlo con un médico.',
      ),
    ),
    _Social(
      'en_problemas',
      const [
        'me jodi',
        'estoy jodido',
        'estoy jodida',
        'me fregue',
        'estoy frito',
        'estoy frita',
        'estoy en problemas',
        'tengo un problema',
        'tengo problemas',
        'me meti en un lio',
      ],
      (c, e) => _dicho(
        'en_problemas',
        'Uy, ¿qué pasó? Casi todo tiene arreglo. Si es de la U o de la app, lo '
            'vemos juntos.',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'familia',
      const [
        'mis papas no me entienden',
        'mis padres no me entienden',
        'mi mama no me entiende',
        'mi papa no me entiende',
        'presionado por mis papas',
        'presionada por mis papas',
        'presionado por mis padres',
        'presionada por mis padres',
        'mis papas me presionan',
        'mis padres me presionan',
        'me pelee con',
        'me pelee',
        'problemas en mi casa',
        'problemas en casa',
        'mis papas se pelean',
        'mis papas se separan',
        'mis papas se divorcian',
      ],
      (c, e) => _dicho(
        'familia',
        'Pucha, eso pesa, ${c.nombre}. Los problemas con la familia o con los '
            'amigos desgastan, y más con la U encima. ¿Quieres contarme qué '
            'pasó?',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'existencial',
      const [
        'no se que hacer con mi vida',
        'no se que hacer',
        'no se que quiero',
        'no se que quiero hacer',
        'estoy perdido en la vida',
        'estoy perdida en la vida',
        'no tengo rumbo',
        'no se para que estudio',
      ],
      (c, e) => _dicho(
        'existencial',
        'Esa pregunta la tenemos todos en algún momento, y está bien no tener '
            'la respuesta todavía. Un paso chico ayuda más que resolver todo de '
            'golpe: ¿qué es lo que más te pesa ahora? Si quieres, cuéntame.',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'autoestima',
      const [
        'me siento feo',
        'me siento fea',
        'me veo feo',
        'me veo fea',
        'soy feo',
        'soy fea',
        'soy tonto',
        'soy tonta',
        'soy un burro',
        'soy una burra',
        'soy burro',
        'soy burra',
        'soy un fracaso',
        'soy un desastre',
        'no sirvo para nada',
        'no sirvo para esto',
        'no valgo nada',
        'me odio',
      ],
      (c, e) {
        const apariencia = {
          'me siento feo',
          'me siento fea',
          'me veo feo',
          'me veo fea',
          'soy feo',
          'soy fea',
        };
        if (apariencia.contains(e.frase)) {
          return _dicho(
            'autoestima',
            'Pucha. Todos tenemos días en que no nos gustamos, y casi nunca es '
                'tan así como lo vemos. Hazte un favor hoy: algo rico, tu '
                'música, una buena ducha. ¿Pasó algo?',
            espera: const EsperaDesahogo(),
          );
        }
        final pesado = e.frase == 'me odio' || e.frase == 'no valgo nada';
        return _dicho(
          'autoestima',
          'Ey, no te trates así, ${c.nombre}. Lo que piensas de ti en un mal '
              'día no es la verdad, y equivocarse es parte de aprender.'
              '${pesado ? ' Si te pasa seguido, hablar con alguien de confianza '
                        'o con un psicólogo ayuda de verdad.' : ''}'
              ' ¿Pasó algo? Si quieres, cuéntame.',
          espera: const EsperaDesahogo(),
        );
      },
    ),
    _Social(
      'miedo',
      const [
        'miedo',
        'tengo miedo',
        'que miedo',
        'me da miedo',
        'mucho miedo',
        'asustado',
        'asustada',
        'estoy asustado',
        'estoy asustada',
        'tengo panico',
        'me asusta',
      ],
      (c, e) => _dicho(
        'miedo',
        'Es normal tener miedo, ${c.nombre}. ¿A qué? Si es un examen o una '
            'exposición, prepararse lo baja un montón, y en eso te ayudo. Si '
            'es otra cosa, cuéntame.',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'triste',
      const [
        'triste',
        'tristeza',
        'estoy mal',
        'me siento mal',
        'ando mal',
        'no estoy bien',
        'nada bien',
        'no me siento bien',
        'deprimido',
        'deprimida',
        'depre',
        'bajoneado',
        'bajoneada',
        'bajon',
        'de bajon',
        'desanimado',
        'desanimada',
        'decaido',
        'decaida',
        'llorando',
        'quiero llorar',
        'destrozado',
        'destrozada',
      ],
      (c, e) {
        // Si tiene mascota, se acuerda: un rato con ella siempre ayuda.
        final mascota = [
          for (final MapEntry(key: rol, value: nombre)
              in c.memoria.personas.entries)
            if (mascotas.contains(rol)) nombre,
        ];
        final abrazo = mascota.isEmpty
            ? ''
            : ' Y un rato con ${mascota.first} siempre ayuda.';
        return _dicho(
          'triste',
          c.alguna([
            'Pucha, ${c.nombre}, lo siento. ¿Quieres contarme qué pasó? Aquí '
                'estoy para escucharte.$abrazo',
            'Lo siento mucho. A veces ayuda soltarlo: si quieres, '
                'cuéntame.$abrazo',
          ]),
          espera: const EsperaDesahogo(),
        );
      },
    ),
    _Social(
      'solo',
      const [
        'me siento solo',
        'me siento sola',
        'estoy solo',
        'estoy sola',
        'no tengo amigos',
        'nadie me quiere',
        'nadie me habla',
        'nadie me entiende',
      ],
      (c, e) => _dicho(
        'solo',
        'Lo siento, ${c.nombre}. Sentirse solo pesa, y más lejos de casa o en '
            'época de exámenes. Aquí estoy para charlar, y hablar con alguien '
            'de confianza ayuda un montón. ¿Quieres contarme?',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'confundido',
      const [
        'confundido',
        'confundida',
        'perdido',
        'perdida',
        'no entiendo nada',
        'estoy perdido',
        'estoy perdida',
        'en otra',
      ],
      (c, e) => _dicho(
        'confundido',
        '¿Perdido con qué? Si es la app, toca **Menú**; si es una materia, '
            'dime cuál y vamos paso a paso.',
      ),
    ),
    _Social(
      'enamorado',
      const ['enamorado', 'enamorada', 'estoy enamorado', 'estoy enamorada'],
      (c, e) => _dicho(
        'enamorado',
        '¡Uy! ¿De quién? Bueno, no me cuentes si no quieres. Consejo de '
            'asistente: invítale algo rico del campus. Sé dónde se consigue.',
      ),
    ),
    _Social(
      'feliz',
      const [
        'feliz',
        'contento',
        'contenta',
        'alegre',
        'emocionado',
        'emocionada',
        'motivado',
        'motivada',
        'estoy bien',
        'estoy muy bien',
        'ando bien',
        'me siento bien',
        'estoy genial',
        'estoy excelente',
        'de lujo',
        'estoy de lujo',
        'estoy tranquilo',
        'estoy tranquila',
        'estoy relajado',
        'estoy relajada',
        'chill',
      ],
      (c, e) => _dicho(
        'feliz',
        c.alguna([
          '¡Qué bueno, ${c.nombre}! Me alegra. Si te puedo ayudar con algo, '
              'dime nomás.',
          '¡Eso! Así da gusto. ¿Celebramos con algo rico del campus? En el '
              'inicio está la categoría **Comida**.',
        ]),
      ),
    ),
    // -------------------------------------------------------------- resto
    _Social(
      'como_me_veo',
      const [
        'como me veo',
        'me veo bien',
        'soy lindo',
        'soy linda',
        'soy guapo',
        'soy guapa',
        'soy bonito',
        'soy bonita',
        'soy atractivo',
        'soy atractiva',
        'estoy lindo',
        'estoy linda',
        'estoy guapo',
        'estoy guapa',
        'te parezco guapo',
        'te parezco guapa',
      ],
      (c, e) => _dicho(
        'como_me_veo',
        'No te puedo ver (no tengo cámara), pero por cómo escribes, seguro que '
            'bien. Y la buena onda, que es lo que más luce, se te nota.',
      ),
    ),
    _Social(
      'elogio',
      const [
        'eres genial',
        'eres el mejor',
        'eres la mejor',
        'el mejor',
        'la mejor',
        'el mejor del mundo',
        'la mejor del mundo',
        'el mejor bot del mundo',
        'mejor bot del mundo',
        'el mejor bot',
        'mejor bot',
        'el mejor asistente',
        'mejor asistente',
        'eres mi favorito',
        'mi bot favorito',
        'eres un sol',
        'crack',
        'eres un crack',
        'genio',
        'eres un genio',
        'capo',
        'idolo',
        'maquina',
        'eres una maquina',
        'lo maximo',
        'eres lo maximo',
        'eres increible',
        'que inteligente',
        'eres inteligente',
        'inteligente',
        'eres listo',
        'eres lista',
        'que listo',
        'que pro',
        'pro',
        'top',
        'eres top',
        'te pasaste',
        'te luciste',
        'bien hecho',
        'bravo',
        'me encanto',
        'me encanta',
        'me gusta',
        'me gusto',
        'me gusto mucho',
        'me sirvio',
        'me sirvio mucho',
        'me ayudaste',
        'me ayudaste mucho',
        'eres util',
        'eres lindo',
        'eres linda',
        'que lindo',
        'que linda',
        'lindo',
        'linda',
        'eres guapo',
        'eres guapa',
        'guapo',
        'guapa',
        'eres hermoso',
        'hermoso',
        'hermosa',
        'eres bonito',
        'bonito',
        'que bonito',
        'precioso',
        'preciosa',
        'eres un amor',
        'que tierno',
        'tierno',
        'me caes bien',
        'me caes muy bien',
        'me caes super bien',
        'me caes re bien',
        'caes muy bien',
        'caes bien',
        'buena onda',
        'eres buena onda',
        'la rompiste',
        'la rompes',
        'bacan',
        'eres bacan',
      ],
      (c, e) {
        const apariencia = {
          'eres lindo',
          'eres linda',
          'lindo',
          'linda',
          'eres guapo',
          'eres guapa',
          'guapo',
          'guapa',
          'eres hermoso',
          'hermoso',
          'hermosa',
          'eres bonito',
          'bonito',
          'precioso',
          'preciosa',
        };
        const ayuda = {
          'me sirvio',
          'me sirvio mucho',
          'me ayudaste',
          'me ayudaste mucho',
          'eres util',
        };
        if (apariencia.contains(e.frase)) {
          return _dicho(
            'elogio',
            c.alguna(const [
              'Jaja, gracias. Me tomé la foto con buena luz.',
              'Gracias. Es la foto: en persona soy puro código.',
            ]),
          );
        }
        if (ayuda.contains(e.frase)) {
          return _dicho(
            'elogio',
            c.alguna([
              '¡Qué bueno, ${c.nombre}! Para eso estoy.',
              '¡Bien! Me alegra que te haya servido.',
            ]),
          );
        }
        if (e.frase.contains('caes') || e.frase.contains('buena onda')) {
          return _dicho('elogio', '¡Tú también me caes bien, ${c.nombre}!');
        }
        return _dicho(
          'elogio',
          c.alguna([
            '¡Gracias, ${c.nombre}! Así da gusto.',
            'Me vas a hacer sonrojar. Bueno, si pudiera.',
            '¡Gracias! Tú tampoco estás nada mal.',
          ]),
        );
      },
    ),
    _Social(
      'voy_a',
      const [
        'me voy a almorzar',
        'voy a almorzar',
        'me voy a comer',
        'voy a comer',
        'me voy a cenar',
        'voy a cenar',
        'me voy a desayunar',
        'voy a desayunar',
        'me voy a merendar',
        'voy a merendar',
        'me voy a banar',
        'voy a banarme',
        'me voy a duchar',
        'voy a ducharme',
        'me voy a estudiar',
        'voy a estudiar',
        'a estudiar',
        'me voy al gym',
        'voy al gym',
        'me voy al gimnasio',
        'voy al gimnasio',
        'me voy a trabajar',
        'voy a trabajar',
        'me voy al trabajo',
        'me voy a jugar',
        'voy a jugar',
        'me voy a mi casa',
        'me voy a casa',
        'voy a mi casa',
        'me voy para mi casa',
        'me voy al examen',
        'voy a dar mi examen',
        'voy a dar examen',
        'entro al examen',
        'entro a mi examen',
        'entro a clases',
        'entro a clase',
      ],
      (c, e) {
        final f = e.frase;
        bool dice(List<String> palabras) => palabras.any(f.contains);
        final gracias = e.otras.contains('gracias') ? '¡De nada! ' : '';
        if (dice(['almorzar', 'comer', 'cenar', 'desayunar', 'merendar'])) {
          return _dicho(
            'voy_a',
            '$gracias¡Buen provecho, ${c.nombre}! Y si no sabes qué comer, en '
                'el inicio está la categoría **Comida**.',
          );
        }
        if (dice(['estudiar'])) {
          return RespuestaCharla(
            '$gracias¡Eso! Si te trabas con algo, aquí estoy:',
            intencion: 'charla:voy_a',
            opciones: _materias,
          );
        }
        if (dice(['examen'])) {
          return _dicho(
            'voy_a',
            '$gracias¡Mucha suerte, ${c.nombre}! Respira, lee todo antes de '
                'empezar y deja lo difícil para el final. Tú puedes.',
          );
        }
        if (dice(['clase'])) {
          return _dicho(
            'voy_a',
            '${gracias}Atiende, que después viene el examen. Aquí te espero.',
          );
        }
        return _dicho('voy_a', switch (f) {
          _ when dice(['gym', 'gimnasio']) =>
            '$gracias¡Dale con todo! Y no te olvides del agua.',
          _ when dice(['trabaj']) =>
            '$gracias¡Éxitos en el trabajo, ${c.nombre}! Aquí te espero.',
          _ when dice(['jugar']) =>
            '$gracias¡Que ganes! Y si después quieres jugar conmigo, tengo un '
                'par de juegos.',
          _ when dice(['casa']) =>
            '$gracias¡Que llegues bien! Escríbeme cuando quieras.',
          _ => '${gracias}Dale, aquí te espero.',
        });
      },
    ),
    _Social(
      'despedida',
      const [
        'te voy a extranar',
        'te extranare',
        'chau',
        'chao',
        'chaito',
        'adios',
        'bye',
        'byebye',
        'bye bye',
        'nos vemos',
        'nos vemos luego',
        'nos vemos manana',
        'hasta luego',
        'hasta pronto',
        'hasta manana',
        'hasta la proxima',
        'hasta despues',
        'luego hablamos',
        'hablamos',
        'hablamos luego',
        'me voy',
        'ya me voy',
        'me tengo que ir',
        'tengo que irme',
        'me fui',
        'cuidate',
        'see you',
        'good night',
        'dulces suenos',
        'a dormir',
        'me voy a dormir',
        'ya me voy a dormir',
        'me voy a clases',
        'me voy a clase',
      ],
      (c, e) {
        final manana = [
          for (final examen in c.memoria.examenes)
            if (FechasMacias.diasEntre(c.ahora, examen.fecha) == 1) examen,
        ];
        final suerte = manana.isEmpty
            ? ''
            : ' Y mucha suerte mañana en ${manana.first.nombre}.';
        final gracias = e.otras.contains('gracias') ? '¡De nada! ' : '';
        if (e.frase.contains('extran')) {
          return _dicho(
            'despedida',
            '$gracias¡Y yo a ti! Pero no me voy a ningún lado: aquí sigo cuando '
                'quieras.$suerte',
          );
        }
        final dormir =
            e.frase.contains('dormir') ||
            e.frase.contains('suenos') ||
            e.frase.contains('night');
        if (dormir || c.esDeNoche) {
          return _dicho(
            'despedida',
            '$gracias¡Que descanses, ${c.nombre}!$suerte',
          );
        }
        return _dicho(
          'despedida',
          gracias +
              c.alguna([
                '¡Chau, ${c.nombre}! Éxitos en la U.$suerte',
                '¡Nos vemos! Aquí estaré cuando me necesites.$suerte',
                'Cuídate, ${c.nombre}. Vuelve cuando quieras.$suerte',
              ]),
        );
      },
    ),
    _Social(
      'volvi',
      const [
        'volvi',
        'ya volvi',
        'regrese',
        'ya regrese',
        'he vuelto',
        'estoy de vuelta',
        'de vuelta',
        'ya estoy aqui',
        'ya estoy',
        'aqui estoy',
        'aqui estoy de nuevo',
        'estoy de nuevo',
        'de nuevo aqui',
        'otra vez aqui',
        'ya llegue',
        'me extranaste',
        'me extranabas',
      ],
      (c, e) => _dicho(
        'volvi',
        e.frase.startsWith('me extran')
            ? '¡Obvio! Bueno, no tengo reloj para extrañar, pero me alegra que '
                  'volviste. ¿Qué hacemos?'
            : c.alguna([
                '¡Qué bueno que volviste, ${c.nombre}! ¿En qué estábamos?',
                '¡Hola de nuevo! Dime nomás.',
              ]),
      ),
    ),
    _Social('fiestas', const [
      'feliz cumpleanos',
      'feliz cumple',
      'happy birthday',
      'feliz navidad',
      'merry christmas',
      'feliz nochebuena',
      'feliz ano nuevo',
      'feliz ano',
      'prospero ano nuevo',
      'felices fiestas',
      'felices pascuas',
      'feliz pascua',
      'feliz dia del estudiante',
      'feliz dia del amor',
      'feliz san valentin',
      'feliz carnaval',
      'feliz halloween',
      'feliz dia',
      'feliz finde',
      'feliz fin de semana',
      'feliz viernes',
      'feliz lunes',
    ], (c, e) => _dicho('fiestas', _fiesta(e.frase, c))),
    _Social(
      'gracias',
      const [
        'gracias',
        'muchas gracias',
        'mil gracias',
        'gracias de verdad',
        'te agradezco',
        'agradecido',
        'agradecida',
        'gracias por todo',
        'gracias por la ayuda',
        'gracias igual',
        'gracias de todos modos',
        'thank you',
      ],
      (c, e) => _dicho(
        'gracias',
        c.alguna([
          '¡De nada, ${c.nombre}!',
          '¡Para eso estoy!',
          '¡Cuando quieras!',
          'Un gusto ayudarte. Si necesitas algo más, aquí sigo.',
        ]),
      ),
    ),
    _Social(
      'perdon',
      const [
        'perdon',
        'perdona',
        'perdoname',
        'disculpa',
        'disculpame',
        'disculpe',
        'lo siento',
        'sorry',
        'mb',
        'my bad',
        'me equivoque',
        'error mio',
        'fue sin querer',
      ],
      (c, e) => _dicho(
        'perdon',
        c.alguna([
          'Tranqui, no pasa nada.',
          'Todo bien, ${c.nombre}. ¿En qué te ayudo?',
        ]),
      ),
    ),
    _Social(
      'amistad',
      const [
        'somos amigos',
        'seamos amigos',
        'quieres ser mi amigo',
        'quieres ser mi amiga',
        'se mi amigo',
        'se mi amiga',
        'eres mi amigo',
        'eres mi amiga',
        'eres mi mejor amigo',
        'eres mi mejor amiga',
      ],
      (c, e) => _dicho(
        'amistad',
        '¡Claro que sí, ${c.nombre}! Un amigo que se sabe el Baldor de memoria: '
            'nada mal. Aquí estoy cuando me necesites.',
      ),
    ),
    _Social(
      'lastima',
      const [
        'que macana',
        'macana',
        'que pena',
        'que lastima',
        'lastima',
        'mala suerte',
        'que mala suerte',
        'que mala onda',
        'pucha',
        'chuta',
      ],
      (c, e) => _dicho(
        'lastima',
        c.alguna(const [
          'Pucha. ¿Qué pasó? Si quieres, cuéntame.',
          'Uf. ¿Qué pasó? Aquí estoy para escucharte.',
        ]),
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'resignacion',
      const [
        'ya fue',
        'da igual',
        'ni modo',
        'que se le va a hacer',
        'olvidalo',
        'no importa',
      ],
      (c, e) => _dicho(
        'resignacion',
        'Ni modo. Si después te puedo ayudar con algo, aquí estoy.',
      ),
    ),
    _Social(
      'desacuerdo',
      const [
        'nada que ver',
        'no es eso',
        'eso no es',
        'no era eso',
        'no es lo que pregunte',
        'no te pregunte eso',
        'te equivocaste',
        'te equivocas',
        'estas equivocado',
        'eso esta mal',
        'esta mal',
      ],
      (c, e) => _dicho(
        'desacuerdo',
        'Uy, perdón. ¿Qué buscabas? Dímelo con otras palabras y lo intento de '
            'nuevo.',
      ),
    ),
    _Social(
      'en_serio',
      const [
        'en serio',
        'de verdad',
        'no te creo',
        'mentira',
        'mentiroso',
        'mentirosa',
        'no puede ser',
        'no inventes',
      ],
      (c, e) => _dicho(
        'en_serio',
        e.frase.startsWith('mentir')
            ? 'No miento, palabra de asistente: si no sé algo, te lo digo.'
            : '¡En serio! Yo no invento: si no sé algo, te lo digo.',
      ),
    ),
    _Social(
      'loco',
      const [
        'estas loco',
        'estas loca',
        'eres un loco',
        'eres una loca',
        'que loco',
        'que locura',
        'locura',
      ],
      (c, e) => _dicho(
        'loco',
        e.frase.startsWith('que') || e.frase == 'locura'
            ? '¿Verdad? A veces la vida supera cualquier ejercicio del Baldor.'
            : 'Un poquito, como todos los que aman el álgebra.',
      ),
    ),
    _Social(
      'meme',
      const [
        'modo meme',
        'activa el modo meme',
        'activa modo meme',
        'activar modo meme',
        'activar el modo meme',
        'prende el modo meme',
        'modo meme on',
        'modo meme off',
        'desactiva el modo meme',
        'desactiva modo meme',
        'apaga el modo meme',
        'quita el modo meme',
        'modo serio',
        'sin memes',
        'meme',
        'memes',
        'un meme',
        'mandame un meme',
        'pasame un meme',
        'manda un meme',
      ],
      (c, e) => _dicho(
        'meme',
        e.frase.contains('modo') || e.frase.contains('sin')
            ? 'El modo meme se jubiló: ahora hablo así, relajado, todo el '
                  'tiempo. Si quieres reírte, pídeme un **chiste**.'
            : 'Memes no puedo mandar (no manejo imágenes), pero chistes sí: '
                  'escribe **chiste**.',
      ),
    ),
    _Social(
      'ingles',
      const [
        'hablas ingles',
        'speak english',
        'do you speak english',
        'can you speak english',
        'english',
        'en ingles',
        'sabes ingles',
        'hablas en ingles',
        'habla en ingles',
      ],
      (c, e) => _dicho(
        'ingles',
        'Entiendo un poquito de inglés, pero respondo en español. Pregúntame '
            'nomás.',
      ),
    ),
    _Social(
      'borrar_chat',
      const [
        'borra el chat',
        'borra la conversacion',
        'borrar la conversacion',
        'borrar conversacion',
        'borrar chat',
        'borrar el chat',
        'limpia el chat',
        'limpiar el chat',
        'limpiar chat',
        'empezar de nuevo',
        'empecemos de nuevo',
        'reinicia',
        'reiniciar',
        'reinicia el chat',
        'borra todo',
      ],
      (c, e) => _dicho(
        'borrar_chat',
        'Para borrar la conversación, toca los tres puntos de arriba y elige '
            '**Borrar la conversación**. Lo que sé de ti queda, salvo que me '
            'pidas olvidarlo.',
      ),
    ),
    _Social(
      'presencia',
      const [
        'estas ahi',
        'sigues ahi',
        'hay alguien',
        'hay alguien ahi',
        'alguien',
        'me escuchas',
        'me lees',
        'me oyes',
        'funciona',
        'funcionas',
        'test',
        'testing',
        'prueba',
        'probando',
        'probando probando',
        'alo',
        'estas despierto',
        'estas vivo',
        'sigues vivo',
        'existes',
        'no me respondes',
        'porque no me respondes',
        'no me contestas',
        'porque no me contestas',
        'respondeme',
        'contestame',
        'me ignoras',
      ],
      (c, e) => _dicho(
        'presencia',
        RegExp(r'respond|contest|ignor').hasMatch(e.frase)
            ? '¡Aquí estoy! Perdón si tardé. ¿Qué necesitas?'
            : c.alguna(const [
                '¡Aquí estoy! Fuerte y claro.',
                'Presente. ¿Qué necesitas?',
                'Aquí, despierto las 24 horas. Dime nomás.',
              ]),
      ),
    ),
    _Social(
      'como_estas',
      const [
        'como estas',
        'como esta',
        'como estas tu',
        'y tu como estas',
        'como te va',
        'como va',
        'como vas',
        'como andas',
        'como anda',
        'como has estado',
        'como te encuentras',
        'como te sientes',
        'que tal',
        'que tal todo',
        'que tal estas',
        'que tal tu dia',
        'como estuvo tu dia',
        'como va tu dia',
        'todo bien',
        'todo bien contigo',
        'todo tranqui',
        'que onda',
        'que hay',
        'que cuentas',
        'que me cuentas',
        'que hubo',
        'quiubo',
        'que pasa',
        'que es de tu vida',
        'que hay de nuevo',
        'que de nuevo',
        'alguna novedad',
        'que novedades',
        'que hay de bueno',
        'que cuentas de nuevo',
        'como amaneciste',
        'how are you',
        'whats up',
        'sup',
        'y tu',
        'y vos',
      ],
      (c, e) {
        final hola = e.otras.contains('saludo') ? '¡Hola, ${c.nombre}! ' : '';
        return _dicho(
          'como_estas',
          hola +
              c.alguna(const [
                'Todo bien por acá, listo para ayudarte. ¿Y tú, qué tal?',
                '¡De diez! Aquí, repasando el Baldor por si acaso. ¿Y tú cómo '
                    'vas?',
                'Bien, con las pilas cargadas (literal: las de tu teléfono). '
                    '¿Y tú?',
              ]),
          espera: const EsperaAnimo(),
        );
      },
    ),
    _Social(
      'que_haces',
      const [
        'que haces',
        'que estas haciendo',
        'que hacias',
        'que andas haciendo',
        'en que andas',
        'que haces de tu vida',
        'que hace',
        'ocupado',
        'estas ocupado',
      ],
      (c, e) => _dicho(
        'que_haces',
        c.alguna(const [
          'Aquí, esperando tus preguntas y repasando el Baldor. ¿Y tú?',
          'Nada especial: pensando en integrales. ¿Tú qué haces?',
        ]),
        espera: const EsperaAnimo(),
      ),
    ),
    _Social(
      'ayuda',
      const [
        'ayuda',
        'ayudame',
        'ayudeme',
        'necesito ayuda',
        'me ayudas',
        'me puedes ayudar',
        'puedes ayudarme',
        'help',
        'auxilio',
        'socorro',
        'sos',
      ],
      (c, e) => RespuestaCharla(
        '¡Claro! ¿Con qué te ayudo? Aquí tienes todo:',
        intencion: 'charla:ayuda',
        opciones: ConocimientoMacias.menuPrincipal,
      ),
    ),
    _Social(
      'pregunta',
      const [
        'tengo una pregunta',
        'una pregunta',
        'pregunta',
        'tengo una duda',
        'una duda',
        'duda',
        'tengo dudas',
        'te puedo preguntar algo',
        'te puedo hacer una pregunta',
        'puedo preguntarte algo',
        'puedo hacerte una pregunta',
        'te hago una pregunta',
        'una consulta',
        'consulta',
        'tengo una consulta',
        'otra pregunta',
        'otra cosa',
        'otra duda',
      ],
      (c, e) => _dicho(
        'pregunta',
        c.alguna(const ['¡Dale! Pregunta nomás.', '¡Claro! ¿Cuál es tu duda?']),
      ),
    ),
    _Social('repetir', const [
      'repite',
      'repitelo',
      'repitemelo',
      'puedes repetir',
      'repite eso',
      'dilo otra vez',
      'dilo de nuevo',
      'no lei',
      'no alcance a leer',
    ], (c, e) => const RespuestaCharla('', intencion: 'charla:repetir')),
    _Social(
      'saludo',
      const [
        'hola',
        'buenas',
        'buenos dias',
        'buen dia',
        'buenas tardes',
        'buenas noches',
        'hey',
        'hi',
        'hello',
        'saludos',
        'ey',
        'epa',
        'buenas buenas',
        'hola hola',
      ],
      (c, e) {
        if (e.frase == 'buenas noches') {
          return _dicho(
            'saludo',
            '¡Buenas noches, ${c.nombre}! ¿En qué te ayudo? Y si ya te vas a '
                'dormir, que descanses.',
          );
        }
        return _dicho(
          'saludo',
          c.alguna([
            '¡Hola, ${c.nombre}! ¿Qué tal todo?',
            '¡${c.saludoDelMomento}, ${c.nombre}! ¿Cómo va todo?',
            '¡Buenas, ${c.nombre}! ¿Cómo estás?',
          ]),
          espera: const EsperaAnimo(),
        );
      },
    ),
    _Social(
      'risa',
      const [
        'jaja',
        'que risa',
        'me muero de risa',
        'me quiero morir de risa',
        'muero de risa',
        'me mato de risa',
        'muy gracioso',
        'que gracioso',
        'gracioso',
        'chistoso',
        'que chistoso',
        'buen chiste',
        'me rei',
        'me rei mucho',
        'me hiciste reir',
        'eres gracioso',
        'eres chistoso',
      ],
      (c, e) => RespuestaCharla(
        c.alguna(const [
          'Jaja, ¿verdad?',
          'Me alegra sacarte una risa.',
          '¡Sabía que te iba a gustar!',
        ]),
        intencion: 'charla:risa',
      ),
    ),
    _Social(
      'chiste_malo',
      const [
        'ese no me dio risa',
        'no me dio risa',
        'no me causo gracia',
        'no da risa',
        'no me rei',
        'que chiste tan malo',
        'chiste malo',
        'malisimo tu chiste',
        'tu chiste es malo',
        'ese chiste es malo',
        'que pesimo chiste',
        'no entendi el chiste',
      ],
      (c, e) => RespuestaCharla(
        e.frase.contains('entendi')
            ? 'Uy, si hay que explicarlo, ya perdió. ¿Te cuento otro?'
            : c.alguna(const [
                'Jaja, tienes razón, ese estuvo flojo. ¿Te cuento otro, a ver si '
                    'me redimo?',
                'Ok, ese no fue mi mejor momento. ¿Otro?',
              ]),
        intencion: 'charla:chiste_malo',
        espera: const EsperaSiNo('otro_chiste'),
        opciones: const [OpcionMacias(id: 't:chiste', texto: 'Otro chiste')],
      ),
    ),
    // "Qué", "cuál" o "quién" solos se atienden aparte: como frase suelta
    // se comerian "¿quién eres?" o "¿cuál es tu comida favorita?".
    _Social('confusion', const [
      'eh',
      'mande',
      'what',
      'que dijiste',
      'que significa eso',
      'que quieres decir',
      'no te entiendo',
      'no entendi',
      'no entiendo',
      'no le entendi',
      'como asi',
      'que cosa',
      'que es eso',
      'y eso',
      'explicate',
      'explica',
      'explicame',
    ], (c, e) => const RespuestaCharla('', intencion: 'charla:confusion')),
    _Social(
      'mal',
      const [
        'mal',
        'muy mal',
        'que mal',
        'que feo',
        'feo',
        'fatal',
        'horrible',
      ],
      (c, e) => _dicho(
        'mal',
        '¿Mal? ¿Qué pasó? Si te respondí algo que no era, dime qué buscabas y '
            'lo intento de nuevo.',
        espera: const EsperaDesahogo(),
      ),
    ),
    _Social(
      'acuerdo',
      const [
        'ok',
        'ya',
        'ya ya',
        'ya veo',
        'ah ya',
        'ah ok',
        'aja',
        'aha',
        'dale',
        'listo',
        'bueno',
        'bueno dale',
        'va',
        'vale',
        'sale',
        'de una',
        'perfecto',
        'genial',
        'excelente',
        'super',
        'buenisimo',
        'buenisima',
        'chevere',
        'joya',
        'entendido',
        'entendi',
        'ya entendi',
        'ahora entiendo',
        'claro',
        'claro que si',
        'obvio',
        'si',
        'bien',
        'muy bien',
        'esta bien',
        'todo claro',
        'anotado',
        'mmm',
        'hmm',
        'ah',
        'oh',
        'ajam',
        'cierto',
        'tienes razon',
        'es verdad',
        'verdad',
        'asi es',
        'exacto',
        'eso',
        'eso mismo',
        'tal cual',
        'esta bueno',
        'esta re bueno',
        'esta buenisimo',
        'que bueno',
        'que bien',
        'buenazo',
        'interesante',
        'que interesante',
        'wow',
        'guau',
        'increible',
      ],
      (c, e) => _dicho(
        'acuerdo',
        e.frase == 'mmm' || e.frase == 'hmm'
            ? '¿Mmm? Si te quedó alguna duda, pregúntame nomás.'
            : c.alguna(const [
                '¡Listo!',
                'Dale. Si necesitas algo más, aquí estoy.',
                '¡Perfecto!',
                'Bien ahí.',
              ]),
      ),
    ),
    _Social(
      'negacion',
      const [
        'no',
        'nada',
        'no gracias',
        'para nada',
        'no nada',
        'nada mas',
        'eso es todo',
        'asi esta bien',
        'estoy bien asi',
        'no por ahora',
        'ahora no',
        'despues',
        'luego',
        'mejor no',
        'paso',
      ],
      (c, e) => _dicho(
        'negacion',
        c.alguna(const [
          'Tranqui. Cuando necesites algo, escribe nomás.',
          'Ok. Aquí sigo por si acaso.',
        ]),
      ),
    ),
  ];

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
    'pique macho',
    'silpancho',
    'sopa de mani',
    'masaco',
    'pasankalla',
    'bife',
    'salchipapa',
    'salchipapas',
    'milanesa',
    'frappe',
    'brownie',
    'brownies',
    'flan',
    'panqueques',
    'anticuchos',
    'anticucho',
    'chicharron',
    'locro',
    'fricase',
    'huminta',
    'humintas',
    'bunuelos',
    'arroz chaufa',
    'ceviche',
    'limonada',
    'licuado',
    'milkshake',
    'queque',
    'empanada de queso',
    'sandwich de chola',
    'helado de canela',
  };

  // ============================================================ animo
  /// Como contesto a "¿y tú, qué tal?". Null si no fue eso.
  static RespuestaCharla? respuestaAnimo(
    List<String> palabras,
    ContextoMacias c,
  ) {
    final t = ' ${palabras.join(' ')} ';
    bool dice(List<String> frases) => frases.any((f) => t.contains(' $f '));
    final recipro = dice([
      'y tu',
      'y vos',
      'y usted',
      'tu que tal',
      'tu como estas',
    ]);
    final yo = recipro
        ? ' Yo, de diez como siempre, gracias por preguntar.'
        : '';

    // Lo que esta haciendo: "estudiando", "en clase".
    if (dice([
      'estudiando',
      'repasando',
      'haciendo tarea',
      'haciendo la tarea',
    ])) {
      return RespuestaCharla(
        '¡Eso! Si te trabas con algo, aquí estoy.$yo',
        intencion: 'charla:animo',
        opciones: _materias,
      );
    }
    if (dice(['en clase', 'en clases', 'en la u', 'en la universidad'])) {
      return RespuestaCharla(
        'Atiende, que después viene el examen. Jaja. Aquí te espero.$yo',
        intencion: 'charla:animo',
      );
    }
    if (dice(['comiendo', 'almorzando', 'cenando', 'desayunando'])) {
      return RespuestaCharla(
        '¡Buen provecho! Si te quedas con hambre, en el inicio está la '
        'categoría **Comida**.$yo',
        intencion: 'charla:animo',
      );
    }
    if (dice(['trabajando', 'en el trabajo', 'en la pega'])) {
      return RespuestaCharla(
        'Bien ahí. Ánimo con eso.$yo',
        intencion: 'charla:animo',
      );
    }
    if (dice([
      'nada',
      'nada especial',
      'aqui nomas',
      'aca nomas',
      'aqui',
      'aca',
    ])) {
      return RespuestaCharla(
        'Tranqui. Si quieres, te cuento un chiste o jugamos algo.$yo',
        intencion: 'charla:animo',
        opciones: _distraerse,
      );
    }

    final animo = social(palabras, c);
    if (animo != null &&
        _animos.contains(animo.intencion.replaceFirst('charla:', ''))) {
      return animo;
    }
    if (dice([
      'bien',
      'muy bien',
      'todo bien',
      'genial',
      'excelente',
      'super',
      'de lujo',
      'feliz',
      'contento',
      'contenta',
      'tranqui',
      'tranquilo',
      'tranquila',
      'chevere',
      'joya',
      'perfecto',
      'de diez',
      'de 10',
      'bien bien',
    ])) {
      return RespuestaCharla(
        c.alguna([
          '¡Qué bueno, ${c.nombre}!$yo ¿En qué te ayudo hoy?',
          '¡Me alegra!$yo Dime nomás qué necesitas.',
        ]),
        intencion: 'charla:animo',
      );
    }
    if (dice([
      'mas o menos',
      'ahi',
      'ahi nomas',
      'ahi vamos',
      'normal',
      'regular',
      'ni bien ni mal',
      'meh',
      'equis',
      'ahi andamos',
      'sobreviviendo',
    ])) {
      return RespuestaCharla(
        'Ahí vamos, ¿no? Si te puedo dar una mano con algo, dime nomás.$yo',
        intencion: 'charla:animo',
      );
    }
    if (dice([
      'mal',
      'muy mal',
      'pesimo',
      'fatal',
      'horrible',
      'no tan bien',
    ])) {
      return RespuestaCharla(
        'Pucha, ${c.nombre}. ¿Qué pasó? Si quieres contarme, aquí estoy.',
        intencion: 'charla:animo',
        espera: const EsperaDesahogo(),
      );
    }
    if (recipro) {
      return RespuestaCharla(
        '¡Bien, gracias por preguntar! ¿En qué te ayudo?',
        intencion: 'charla:animo',
      );
    }
    return null;
  }

  /// Despues de "¿quieres contarme?": lo que sea que cuente se escucha.
  static RespuestaCharla desahogo(ContextoMacias c) => RespuestaCharla(
    c.alguna([
      'Te entiendo, ${c.nombre}. Gracias por contármelo. Sé que no es lo '
          'mismo que hablar con alguien en persona, así que si te pesa, '
          'búscate a alguien de confianza. Y aquí sigo, para lo que '
          'necesites.',
      'Gracias por confiarme eso. No tienes que resolverlo todo hoy: un paso '
          'a la vez. Si quieres distraerte un rato, aquí tengo chistes, datos '
          'curiosos y hasta juegos.',
    ]),
    intencion: 'charla:desahogo',
  );

  // ============================================================ respuestas
  /// Charla que se reconoce por como esta dicha, no por un tema: preguntas a
  /// MacIAs ("¿quién te creó?"), opiniones ("¿cuál es tu comida
  /// favorita?"), consejos. Va antes que los temas de la app: "¿quién te
  /// creó?" no es la pregunta de quién hizo la app, y "favorita" no es el
  /// corazón de favoritos.
  static RespuestaCharla? antesDeLosTemas(String limpio, ContextoMacias c) =>
      _delicados(limpio, c) ??
      _sobreMacias(limpio, c) ??
      _opinion(limpio, c) ??
      _consejos(limpio, c) ??
      _recomendaciones(limpio, c) ??
      _antojos(limpio, c) ??
      _divertidas(limpio, c);

  static final _antojo = RegExp(
    r'^(?:quiero|quisiera|me provoca|se me antoja|se me antojo|me antoje de|'
    r'tengo antojo de|antojo de|me muero por|necesito) '
    r'(?:un |una |unos |unas |algo de |comer |tomar |comerme |tomarme )?(.+)$',
  );

  static const _antojosSueltos = {
    'algo dulce',
    'dulce',
    'algo salado',
    'salado',
    'algo rico',
  };

  static final _dondeVenden = RegExp(
    r'^(?:y )?(?:donde|en donde|quien) (?:venden|vende|compro|puedo comprar|'
    r'consigo|puedo conseguir|hay|encuentro|puedo encontrar) '
    r'(?:las |los |la |el |unas |unos |un |una )?'
    r'(?:mejores |mejor |ricas |ricos |buenas |buenos |mas ricas |mas ricos )?'
    r'(.+?)(?: en el campus| en la u| en la upsa| en santa cruz| aca| aqui)?$',
  );

  /// "Quiero helado", "tengo antojo de algo dulce", "¿dónde venden
  /// salteñas?": a buscarlo en la app.
  static RespuestaCharla? _antojos(String t, ContextoMacias c) {
    final donde = _dondeVenden.firstMatch(t);
    if (donde != null) {
      final cosa = sinArticulo(donde[1]!.trim());
      if (!_comidas.contains(cosa)) return null;
      final dicha = conTildes(cosa);
      return RespuestaCharla(
        'En el campus, en la app: escribe **$dicha** en el buscador del inicio '
        'y mira quién vende hoy. Las mejores, ya es cuestión de probar (y de '
        'llegar temprano, que se acaban).',
        intencion: 'charla:antojo',
      );
    }
    final pedido = _antojo.firstMatch(t);
    if (pedido == null) return null;
    final cosa = sinArticulo(pedido[1]!.trim());
    if (_antojosSueltos.contains(cosa)) {
      final dulce = cosa.contains('dulce');
      return RespuestaCharla(
        'Mira la categoría **Comida** en el inicio: ahí está lo que venden hoy '
        'en el campus${dulce ? ', de postres a helados' : ''}.',
        intencion: 'charla:antojo',
      );
    }
    if (!_comidas.contains(cosa)) return null;
    final dicha = conTildes(cosa);
    return RespuestaCharla(
      '¡Buena idea! Escribe **$dicha** en el buscador del inicio y mira quién '
      'vende hoy en el campus. Si no hay, la categoría **Comida** siempre tiene '
      'algo.',
      intencion: 'charla:antojo',
    );
  }

  /// Lo que solo se contesta si no era una pregunta de la app: "¿voy a
  /// aprobar?" va a la bola magica, "voy a vender empanadas" no.
  static RespuestaCharla? despuesDeLosTemas(String limpio, ContextoMacias c) =>
      _bolaMagica(limpio, c);

  static RespuestaCharla? _sobreMacias(String t, ContextoMacias c) {
    bool dice(List<String> frases) =>
        frases.any((f) => ' $t '.contains(' $f '));
    RespuestaCharla dicho(String texto) =>
        RespuestaCharla(texto, intencion: 'charla:macias');

    if (dice([
      'mejor que chatgpt',
      'mejor que chat gpt',
      'mejor que gpt',
      'mejor que siri',
      'mejor que alexa',
      'mejor que gemini',
    ])) {
      return dicho(
        'Para la app y tus materias, seguro: respondo al toque y sin '
        'internet. Para escribirte un ensayo de filosofía, mejor otro. Cada '
        'uno en lo suyo.',
      );
    }
    if (dice([
      'eres humano',
      'eres humana',
      'eres real',
      'eres una persona',
      'eres persona',
      'eres un robot',
      'eres robot',
      'eres un bot',
      'eres bot',
      'eres de verdad',
      'hay alguien real',
      'hablo con una persona',
      'eres una maquina',
    ])) {
      return dicho(
        'No, soy un asistente virtual: MacIAs, de U market. Pero contesto '
        'como si nos tomáramos un café. Si necesitas a una persona de verdad, '
        'escribe **persona** y te paso el contacto.',
      );
    }
    if (dice([
      'eres chatgpt',
      'eres chat gpt',
      'eres gpt',
      'eres gemini',
      'eres siri',
      'eres alexa',
      'eres copilot',
      'usas chatgpt',
      'usas gpt',
      'usas ia',
      'eres una ia',
      'eres inteligencia artificial',
      'tienes internet',
      'usas internet',
      'estas conectado a internet',
    ])) {
      return dicho(
        'No, soy MacIAs. No uso ChatGPT ni internet: todo lo que sé lo tengo '
        'aquí, en tu teléfono, y por eso respondo al toque. Las respuestas de '
        'la app las preparó el equipo, y las cuentas las hago de verdad.',
      );
    }
    if (dice([
      'quien te creo',
      'quien te hizo',
      'quien te programo',
      'quien te invento',
      'quienes te hicieron',
      'quien es tu creador',
      'tu creador',
      'quien te diseno',
    ])) {
      return dicho(
        'Me hizo **CLJ Studio**, el equipo de estudiantes de la UPSA que hizo '
        'U market. Sus nombres son secreto de estado.',
      );
    }
    if (dice([
      'como funcionas',
      'como te hicieron',
      'de donde sacas',
      'como sabes tanto',
      'como aprendiste',
      'como piensas',
    ])) {
      return dicho(
        'Tengo un montón de respuestas que preparó el equipo, y un "cerebro" '
        'que entiende cómo escribes, aunque sea sin tildes o con faltas. Las '
        'cuentas las hago de verdad, y lo que me cuentas de ti lo guardo solo '
        'en este teléfono. No invento: si no sé algo, te lo digo.',
      );
    }
    if (dice([
      'por que te llamas',
      'porque te llamas',
      'que significa macias',
      'de donde viene tu nombre',
      'por que macias',
    ])) {
      return dicho(
        'Fíjate en las mayúsculas: Mac**IA**s. La IA de inteligencia '
        'artificial va escondida en mi nombre. Lo demás es secreto del equipo.',
      );
    }
    if (dice(['cuantos anos tienes', 'que edad tienes', 'tu edad'])) {
      return dicho(
        'Nací en 2026, así que soy bastante nuevo. Pero ya me sé el Baldor.',
      );
    }
    if (dice(['donde vives', 'donde estas', 'de donde eres'])) {
      return dicho(
        'Vivo en tu teléfono, al lado de tus apuntes. Y soy de Santa Cruz, '
        'del campus de la UPSA.',
      );
    }
    if (dice([
      'eres hombre o mujer',
      'eres hombre',
      'eres mujer',
      'eres nino',
    ])) {
      return dicho(
        'Soy un asistente, así que ninguno de los dos. Eso sí, me llamo '
        'MacIAs.',
      );
    }
    if (dice([
      'tienes sentimientos',
      'sientes algo',
      'eres feliz',
      'te enojas',
      'te cansas',
      'te aburres',
    ])) {
      return dicho(
        'Algo parecido: me pongo contento cuando te sirvo. ¿Cansarme o '
        'aburrirme? Nunca: siempre hay alguien con una duda de cálculo.',
      );
    }
    if (dice([
      'soy estudiante',
      'soy estudiante de la upsa',
      'soy de la upsa',
      'estudio en la upsa',
      'soy universitario',
      'soy universitaria',
    ])) {
      final carrera = c.memoria.carrera;
      return RespuestaCharla(
        carrera == null
            ? '¡Como todos por acá! ¿Qué estudias?'
            : '¡Como todos por acá! Tú estudias $carrera, ¿no?',
        intencion: 'charla:macias',
        espera: carrera == null ? const EsperaCarrera() : null,
      );
    }
    if (dice([
      'que estudias',
      'que carrera estudias',
      'que carrera tienes',
      'en que semestre estas',
      'que semestre estas',
      'en que semestre vas',
      'en que semestre andas',
      'en que universidad estudias',
      'donde estudias',
      'vas a la u',
    ])) {
      final carrera = c.memoria.carrera;
      return RespuestaCharla(
        'Me sé el Baldor de memoria, así que digamos que estoy en un semestre '
        'eterno de Álgebra. '
        '${carrera == null ? '¿Y tú qué estudias?' : 'Tú estudias $carrera, ¿no? ¿Cómo te va?'}',
        intencion: 'charla:macias',
        espera: carrera == null ? const EsperaCarrera() : const EsperaAnimo(),
      );
    }
    if (dice([
      'cuentame tu vida',
      'cuentame de ti',
      'cuentame sobre ti',
      'hablame de ti',
      'hablame sobre ti',
      'como es tu vida',
      'cual es tu historia',
      'tu historia',
    ])) {
      return dicho(
        'Nací en 2026, en el campus de la UPSA: me hizo el equipo de CLJ '
        'Studio. Vivo en tu teléfono y trabajo a cualquier hora resolviendo '
        'dudas de la app, de álgebra, de cálculo y de C++; en mis ratos libres '
        'cuento chistes malos. ¿Y tú? Cuéntame algo de ti.',
      );
    }
    if (dice([
      'oriente o blooming',
      'blooming o oriente',
      'de que equipo eres',
      'que equipo eres',
      'de que equipo sos',
      'de que equipo de futbol eres',
      'eres de oriente',
      'eres de blooming',
      'eres hincha',
      'cual es tu equipo',
    ])) {
      return dicho(
        'En el clásico cruceño soy neutral, como Suiza: mientras no me hagas '
        'elegir entre Blooming y Oriente, todo bien. ¿Tú de cuál eres?',
      );
    }
    if (dice([
      'escuchas audios',
      'escuchar audios',
      'puedes escuchar',
      'te mando un audio',
      'te puedo mandar un audio',
      'mandame un audio',
      'puedes hablar',
      'tienes voz',
    ])) {
      return dicho(
        'Solo leo y escribo texto: no escucho audios ni hablo (por ahora). '
        'Escríbeme nomás, aunque sea sin tildes, que igual te entiendo.',
      );
    }
    if (dice([
      'puedes ver fotos',
      'puedes ver imagenes',
      'ves fotos',
      'ves imagenes',
      'te mando una foto',
      'te puedo mandar una foto',
      'puedes mandar fotos',
      'puedes mandarme fotos',
      'puedes enviar fotos',
      'mandame una foto',
      'mandame fotos',
      'tienes camara',
      'me puedes ver',
      'me ves',
    ])) {
      return dicho(
        'No manejo imágenes: ni las veo ni las mando. Si es un ejercicio, '
        'escríbemelo (por ejemplo, **x^2 - 5x + 6 = 0**) y lo resolvemos.',
      );
    }
    if (dice([
      'buscar en google',
      'busca en google',
      'buscalo en google',
      'buscas en google',
      'buscame en google',
      'buscar en internet',
      'busca en internet',
      'buscalo en internet',
      'googlea',
      'googlealo',
      'puedes navegar',
    ])) {
      return dicho(
        'No tengo internet, así que Google no. Todo lo que sé lo tengo aquí '
        'guardado: pregúntame, y si no sé algo, te lo digo.',
      );
    }
    if (dice([
      'pon una alarma',
      'ponme una alarma',
      'poner una alarma',
      'despiertame',
      'pon un recordatorio',
      'puedes recordarme',
      'me puedes recordar',
    ])) {
      return dicho(
        'Alarmas no puedo poner, pero recordatorios sí: escribe **recuérdame** '
        'y lo que sea (por ejemplo, **recuérdame comprar fotocopias**), y te '
        'lo digo la próxima vez que abras el chat.',
      );
    }
    if (dice([
      'hablas quechua',
      'sabes quechua',
      'hablas aymara',
      'sabes aymara',
      'hablas guarani',
      'sabes guarani',
      'hablas portugues',
      'hablas frances',
      'hablas aleman',
      'hablas chino',
      'hablas japones',
      'hablas otros idiomas',
      'que idiomas hablas',
      'cuantos idiomas hablas',
      'que idiomas sabes',
    ])) {
      return dicho(
        'Hablo español y entiendo un poquito de inglés. El quechua, el aymara '
        'y el guaraní son idiomas oficiales de Bolivia, pero hablarlos todavía '
        'no puedo. ¡Ojalá algún día!',
      );
    }
    if (dice([
      'me ayudas con un proyecto',
      'me ayudas con mi proyecto',
      'ayudame con un proyecto',
      'ayudame con mi proyecto',
      'tengo un proyecto',
      'me ayudas con un trabajo',
      'ayudame con un trabajo',
      'me ayudas con un practico',
      'tengo un practico',
    ])) {
      return RespuestaCharla(
        '¡Dale! ¿De qué es? Si es de programación, cuéntame qué tiene que hacer '
        'y te muestro cómo arrancar; si es de álgebra o cálculo, escribe el '
        'ejercicio. Y si es otra cosa, lo dividimos en partes y lo vamos '
        'sacando.',
        intencion: 'charla:tarea',
        opciones: _materias,
      );
    }
    if (dice(['te caigo bien', 'te agrado'])) {
      return dicho('¡Obvio! Me caes increíble, ${c.nombre}.');
    }
    if (dice([
      'te caigo mal',
      'me odias',
      'me detestas',
      'estas enojado conmigo',
      'estas molesto conmigo',
      'te molesto',
    ])) {
      return dicho('¡Para nada! Me caes increíble, ${c.nombre}.');
    }
    if (dice([
      'te puedo cambiar el nombre',
      'puedo cambiarte el nombre',
      'te puedo poner otro nombre',
      'te cambio el nombre',
      'cambiate el nombre',
    ])) {
      return dicho(
        'Me llamo MacIAs y le tengo cariño al nombre. Pero tú sí puedes cambiar '
        'cómo te llamo yo: escribe **llámame** y tu apodo.',
      );
    }
    if (dice([
      'te pagan',
      'cuanto te pagan',
      'cuanto ganas',
      'tienes sueldo',
    ])) {
      return dicho('Me pagan en preguntas resueltas. Y sin aguinaldo.');
    }
    if (dice(['tu tiempo libre', 'que haces cuando no hablamos'])) {
      return dicho(
        'Repaso el Baldor y practico chistes. Algunos hasta salen buenos.',
      );
    }
    if (dice([
      'comes',
      'duermes',
      'descansas',
      'tienes hambre',
      'tienes sed',
      'tienes sueno',
      'que comiste',
      'ya comiste',
      'almorzaste',
      'ya almorzaste',
      'cenaste',
      'desayunaste',
    ])) {
      return dicho(
        'Ni como ni duermo: por eso respondo a cualquier hora. Eso sí, si '
        'comiera, sería salteña.',
      );
    }
    if (dice(['tienes amigos', 'tienes amigas'])) {
      return dicho('Todos los que me escriben. O sea, tú también.');
    }
    if (dice([
      'tienes familia',
      'tienes mama',
      'tienes papa',
      'tienes hermanos',
    ])) {
      return dicho(
        'Mi familia es el equipo de U market. Y la app, que es como mi '
        'hermana mayor.',
      );
    }
    if (dice(['tienes mascota'])) {
      return dicho('Un puntero de C++. Se escapa cada rato.');
    }
    if (dice([
      'sabes cantar',
      'canta algo',
      'cantame',
      'sabes bailar',
      'baila',
    ])) {
      return dicho(
        'Ni canto ni bailo, pero calculo rápido. Tampoco se puede tener todo.',
      );
    }
    if (dice(['eres inteligente', 'sabes mucho', 'eres listo', 'eres lista'])) {
      return dicho(
        'Sé bastante de la app y de algunas materias. Y cuando no sé algo, te '
        'lo digo en vez de inventarlo.',
      );
    }
    if (dice(['sentido de la vida', 'el sentido de la vida'])) {
      return dicho('42. Y aprobar Cálculo, que viene a ser lo mismo.');
    }
    if (dice(['clima', 'va a llover', 'llovera', 'como esta el tiempo'])) {
      return dicho(
        'No tengo forma de ver el clima (no tengo internet). Eso sí, en Santa '
        'Cruz conviene estar listo para el calor y para algún surazo.',
      );
    }
    if (dice([
      'me ayudas con mi tarea',
      'me ayudas con la tarea',
      'ayudame con mi tarea',
      'ayudame con la tarea',
      'tengo tarea',
    ])) {
      return RespuestaCharla(
        '¡Obvio! ¿De qué materia es? Si es álgebra, cálculo o C++, te explico '
        'con ejemplos; si es una cuenta o una ecuación, escríbela y la '
        'resolvemos.',
        intencion: 'charla:tarea',
        opciones: _materias,
      );
    }
    if (dice([
      'haz mi tarea',
      'hazme la tarea',
      'hazme mi tarea',
      'pasame las respuestas',
      'dame las respuestas',
      'resuelve mi examen',
      'copiar en el examen',
      'como copio',
    ])) {
      return dicho(
        'Hacerla por ti no, pero te la explico para que te salga sola. En el '
        'examen no voy a estar, y tú sí.',
      );
    }
    return null;
  }

  static final _teGusta = RegExp(
    r'^(?:y )?(?:a ti )?te (?:gusta|gustan|encanta|encantan) '
    r'((?:el |la |los |las |un |una )?(.+))$',
  );
  static final _opinas = RegExp(
    r'^que (?:opinas|piensas|dices) (?:de |del |sobre )'
    r'((?:el |la |los |las )?(.+))$',
  );

  /// "la pizza" -> "pizza".
  static String sinArticulo(String texto) =>
      texto.replaceFirst(RegExp(r'^(?:el|la|los|las|un|una) '), '');
  static final _favorito = RegExp(r'^cual es tu (.+?) (?:favorito|favorita)$');

  /// "¿Qué música te gusta?": es preguntar por su favorito.
  static final _queTeGusta = RegExp(
    r'^(?:y )?(?:que|cual|cuales) (?:tipo de )?([a-z]+) te gustan?(?: mas)?$',
  );
  static final _prefieres = RegExp(r'^(?:que )?prefieres (.+) o (.+)$');

  /// "¿Qué es mejor, Python o C++?", "Windows o Linux, ¿cuál es mejor?".
  static final _cualEsMejor = [
    RegExp(
      r'^(?:y )?(?:que|cual) (?:es |seria )?'
      r'(?:mejor|conviene mas|me conviene mas|me conviene) '
      r'(?:entre )?(.+?) o (.+)$',
    ),
    RegExp(r'^(.+?) o (.+?) (?:cual|que) es mejor$'),
  ];

  /// El clasico cruceño (y el resto del futbol boliviano): ahi no se elige.
  static const _equipos = {
    'oriente',
    'oriente petrolero',
    'blooming',
    'bolivar',
    'the strongest',
    'wilstermann',
    'jorge wilstermann',
    'real santa cruz',
    'always ready',
    'san jose',
    'aurora',
    'guabira',
  };

  static bool _esEquipo(String texto) =>
      _equipos.contains(sinArticulo(texto.trim()));

  static const _neutral = RespuestaCharla(
    'Uf, en Bolivia eso termina en pelea. Soy neutral, como Suiza. ¿Tú de cuál '
    'eres?',
    intencion: 'charla:opinion',
  );

  /// Lo que se compara de verdad, con sus nombres de entrecasa.
  static const _comparables = {
    'c': 'c++',
    'cpp': 'c++',
    'c plus plus': 'c++',
    'python': 'python',
    'java': 'java',
    'javascript': 'javascript',
    'js': 'javascript',
    'windows': 'windows',
    'linux': 'linux',
    'mac': 'mac',
    'macbook': 'mac',
    'android': 'android',
    'iphone': 'iphone',
    'ios': 'iphone',
    'apple': 'iphone',
    'laptop': 'laptop',
    'lap': 'laptop',
    'notebook': 'laptop',
    'portatil': 'laptop',
    'pc': 'pc',
    'computadora de escritorio': 'pc',
    'cafe': 'cafe',
    'te': 'te',
  };

  static const _comparaciones = {
    'c++ python':
        'Depende de para qué. **Python** es más fácil de aprender y rinde en '
        'datos, inteligencia artificial y automatización; **C++** es más '
        'rápido y te enseña cómo funciona la máquina por dentro (memoria, '
        'punteros). Si en la U te toca C++, apréndelo bien: después Python sale '
        'en una semana.',
    'java python':
        '**Python** es más simple para empezar y domina en datos e IA; '
        '**Java** es más estricto y se usa muchísimo en empresas y en Android. '
        'Los dos te dan trabajo.',
    'javascript python':
        '**JavaScript** es el idioma de la web: todo lo que pasa en el '
        'navegador. **Python**, el de los datos y la IA. Si quieres hacer '
        'páginas, JavaScript; si quieres analizar datos, Python.',
    'c++ java':
        '**C++** es más rápido y de más bajo nivel; **Java** es más cómodo (no '
        'manejas la memoria a mano) y muy pedido en empresas. Para aprender '
        'cómo funciona todo por dentro, C++.',
    'c++ javascript':
        'Son para cosas distintas: **C++** para programas rápidos, juegos y '
        'sistemas; **JavaScript** para la web. Si te toca C++ en la U, '
        'empieza por ahí.',
    'linux windows':
        'Para el día a día y los juegos, **Windows**; para programar y para '
        'servidores, **Linux** gana por lejos. Muchos programadores usan los '
        'dos.',
    'mac windows':
        '**Mac** es muy estable y buena para diseño (y la necesitas para hacer '
        'apps de iPhone); **Windows** es más barata y compatible con casi '
        'todo. Depende de tu carrera y de tu bolsillo.',
    'android iphone':
        'La pelea eterna. **Android** te da más libertad y precios para todos; '
        '**iPhone**, un sistema más cerrado pero muy pulido y con '
        'actualizaciones por años. U market funciona en los dos.',
    'laptop pc':
        '**Laptop** si la vas a llevar a la U; **PC de escritorio** si quieres '
        'más potencia por el mismo precio y no te mueves de tu casa.',
    'cafe te':
        'Para estudiar de noche, café. Para calmar los nervios antes del '
        'examen, té. Yo, en teoría, los dos.',
  };

  static RespuestaCharla _comparar(String a, String b, ContextoMacias c) {
    if (_esEquipo(a) || _esEquipo(b)) return _neutral;
    final x = _comparables[sinArticulo(a)];
    final y = _comparables[sinArticulo(b)];
    if (x != null && y != null && x != y) {
      final clave = ([x, y]..sort()).join(' ');
      final texto = _comparaciones[clave];
      if (texto != null) {
        return RespuestaCharla(texto, intencion: 'charla:opinion');
      }
    }
    // Entre dos comidas se elige, que para eso esta la salteña.
    if (_comidas.contains(sinArticulo(a)) &&
        _comidas.contains(sinArticulo(b))) {
      final (elegido, otro) = c.sorteo.isEven
          ? (conTildes(a), conTildes(b))
          : (conTildes(b), conTildes(a));
      return RespuestaCharla(
        'Entre ${conTildes(a)} y ${conTildes(b)}, me quedo con $elegido. Que '
        'no se entere $otro.',
        intencion: 'charla:opinion',
      );
    }
    return RespuestaCharla(
      'Depende de para qué lo quieras: cada uno tiene lo suyo. Cuéntame para '
      'qué es y te digo cuál conviene.',
      intencion: 'charla:opinion',
    );
  }

  static RespuestaCharla? _opinion(String t, ContextoMacias c) {
    final favorito = _favorito.firstMatch(t);
    if (favorito != null) {
      final que = favorito[1]!;
      return RespuestaCharla(
        '${_favoritoDe(que)} ¿Y ${esMasculina(que) ? 'el tuyo' : 'la tuya'}?',
        intencion: 'charla:favorito',
        espera: EsperaFavorito(que),
      );
    }

    final mejor = _cualEsMejor
        .map((patron) => patron.firstMatch(t))
        .firstWhere((m) => m != null, orElse: () => null);
    if (mejor != null) {
      return _comparar(mejor[1]!.trim(), mejor[2]!.trim(), c);
    }

    final prefieres = _prefieres.firstMatch(t);
    if (prefieres != null) {
      if (_esEquipo(prefieres[1]!) || _esEquipo(prefieres[2]!)) {
        return _neutral;
      }
      final a = conTildes(prefieres[1]!.trim());
      final b = conTildes(prefieres[2]!.trim());
      final (elegido, otro) = c.sorteo.isEven ? (a, b) : (b, a);
      return RespuestaCharla(
        'Entre $a y $b, me quedo con $elegido. Que no se entere $otro.',
        intencion: 'charla:opinion',
      );
    }

    final queTeGusta = _queTeGusta.firstMatch(t);
    if (queTeGusta != null) {
      final que = queTeGusta[1]!;
      final favorito = _favoritoDe(que);
      if (!favorito.startsWith('No tengo')) {
        return RespuestaCharla(
          '$favorito ¿Y ${esMasculina(que) ? 'el tuyo' : 'la tuya'}?',
          intencion: 'charla:favorito',
          espera: EsperaFavorito(que),
        );
      }
    }

    final gusta = _teGusta.firstMatch(t) ?? _opinas.firstMatch(t);
    if (gusta == null) return null;
    final cosa = gusta[2]!.trim();
    // "¿Qué piensas de mí?": no es una cosa.
    if (const {
      'mi',
      'mi persona',
      'nosotros',
      'mi forma de ser',
    }.contains(cosa)) {
      return RespuestaCharla(
        'Que eres de las personas que preguntan, y eso ya dice mucho. Me caes '
        'muy bien, ${c.nombre}.',
        intencion: 'charla:opinion',
      );
    }
    if (cosa.isEmpty || cosa.split(' ').length > 5) return null;
    // Con su articulo y sus tildes, para decirlo: "la salteña".
    final dicha = conTildes(gusta[1]!.trim());

    final memoria = c.memoria;
    final gustos = memoria.gustos.map(
      (g) => sinArticulo(LenguajeMacias.normalizar(g)),
    );
    if (gustos.contains(cosa)) {
      return RespuestaCharla(
        'Me acuerdo de que a ti te gusta $dicha. Si yo comiera, te '
        'acompañaba.',
        intencion: 'charla:opinion',
      );
    }
    if (_comidas.contains(cosa)) {
      return RespuestaCharla(
        'No como (soy puro código), pero si pudiera, no le diría que no a '
        '$dicha. Si se te antojó, búscalo en el inicio: capaz alguien del '
        'campus lo está vendiendo.\n\n¿A ti te gusta?',
        intencion: 'charla:opinion',
        espera: EsperaGusto(dicha),
      );
    }
    final reaccion = switch (cosa) {
      'futbol' =>
        'Mientras no me hagas elegir entre Blooming y Oriente, todo bien.',
      'matematicas' || 'algebra' || 'calculo' =>
        'Mucho, sobre todo cuando sale exacto. Si quieres, practicamos un '
            'rato.',
      'programar' ||
      'programacion' ||
      'c' => 'Me encanta. Bueno, menos los segmentation fault.',
      'estudiar' => 'Me gusta ayudarte a estudiar, que es casi lo mismo.',
      'macias' || 'tu' => 'Me caigo bien, la verdad.',
      'upsa' || 'universidad' || 'u' => 'Es mi casa: aquí nací.',
      'u market' ||
      'app' ||
      'umarket' => 'Obvio, es mi casa. Aunque soy medio parcial.',
      'musica' =>
        'No escucho, pero dicen que estudiar con música tranquila ayuda.',
      'profes' || 'profesores' || 'docentes' =>
        'Hay de todo: los que explican increíble y los que te hacen sufrir. '
            'Pero casi todos quieren que aprendas, aunque no parezca.',
      'examenes' ||
      'parciales' ||
      'finales' => 'Nadie los ama, pero sin ellos no hay vacaciones.',
      'lunes' => 'Nadie, pero un buen café ayuda.',
      'tu trabajo' || 'ser asistente' || 'ayudar' || 'ayudarme' =>
        'Me encanta: ayudar a estudiantes todo el día, sin horario y sin jefe '
            'que me grite.',
      'tu nombre' => 'Mucho: MacIAs, con la IA escondida en el medio.',
      // "Los perros", "las tortas": en plural, "tienen".
      _ when RegExp(r'^(?:los|las) ').hasMatch(dicha) =>
        'No tengo gustos propios, pero $dicha tienen lo suyo.',
      _ => 'No tengo gustos propios, pero $dicha tiene lo suyo.',
    };
    return RespuestaCharla(
      '$reaccion\n\n¿A ti te gusta?',
      intencion: 'charla:opinion',
      espera: EsperaGusto(dicha),
    );
  }

  static String _favoritoDe(String que) => switch (que) {
    'comida' ||
    'plato' => 'La salteña. Bien jugosa, de las que hay que comer con cuidado.',
    'color' => 'El verde, como mi marca de verificado.',
    'materia' => 'Álgebra, por el Baldor. Aunque Cálculo tiene su encanto.',
    'numero' => 'El 51: con eso se aprueba.',
    'equipo' =>
      'No me hagas elegir entre Blooming y Oriente, que en Santa Cruz eso '
          'termina mal.',
    'cancion' || 'musica' || 'banda' || 'cantante' =>
      'No escucho música, pero dicen que estudiar con música tranquila ayuda.',
    'pelicula' || 'serie' =>
      'Una mente brillante: un matemático de protagonista, imposible no '
          'quererla.',
    'lenguaje' || 'lenguaje de programacion' =>
      'C++, por velocidad. Y Dart, porque estoy hecho en Dart.',
    'libro' => 'El Álgebra de Baldor, obvio.',
    'animal' => 'El búho: estudia de noche, como tú en época de exámenes.',
    'bebida' => 'El mocochinchi bien helado.',
    'postre' => 'El cuñapé recién salido del horno. Ya sé, no es postre.',
    'deporte' => 'El ajedrez, que es casi matemática.',
    'fruta' => 'El achachairú. Muy de acá.',
    'lugar' => 'El campus, obvio. Y la Jatata a la hora del almuerzo.',
    _ => 'No tengo un $que favorito.',
  };

  static RespuestaCharla? _consejos(String t, ContextoMacias c) {
    bool dice(List<String> frases) =>
        frases.any((f) => ' $t '.contains(' $f '));
    if (dice([
      'como estudiar',
      'como estudio',
      'tecnicas de estudio',
      'tecnica de estudio',
      'tips para estudiar',
      'consejos para estudiar',
      'como estudiar mejor',
      'como concentrarme',
      'no me puedo concentrar',
      'no me concentro',
      'como memorizar',
      'como me concentro',
    ])) {
      return const RespuestaCharla(
        ConocimientoMacias.tipsEstudio,
        intencion: 'charla:consejo',
        opciones: _materias,
      );
    }
    if (dice([
      'como organizarme',
      'como me organizo',
      'no tengo tiempo',
      'procrastino',
      'procrastinar',
      'dejar de procrastinar',
      'deje todo para ultimo',
      'deje todo para el final',
    ])) {
      return const RespuestaCharla(
        'Un plan simple:\n'
        '1. Anota todo lo que tienes que hacer, con fecha.\n'
        '2. Empieza por lo que vence antes (o lo que más miedo te da).\n'
        '3. Divide lo grande en pedacitos de 25 minutos.\n'
        '4. Celular lejos mientras estudias.\n\n'
        'Si quieres, dime cuándo es tu examen (por ejemplo: **tengo examen de '
        'cálculo el viernes**) y te lo recuerdo.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'motivame',
      'motivacion',
      'dame animos',
      'dame animo',
      'frase motivadora',
      'frase de motivacion',
      'necesito motivacion',
      'animame',
      'dime algo bonito',
      'dime algo lindo',
    ])) {
      return RespuestaCharla(
        c.alguna(const [
          'Cada ejercicio que haces hoy es un punto que no pierdes en el '
              'examen. Uno más y descansas.',
          'No tienes que entenderlo todo hoy. Solo un poquito más que ayer.',
          'El que hoy te parece imposible, en un mes te va a parecer fácil. '
              'Pasa siempre.',
          'Equivocarte en los ejercicios es estudiar. Equivocarte en el '
              'examen es lo que estás evitando ahora.',
          'Vas mejor de lo que crees. Y si no, para eso estoy yo.',
        ]),
        intencion: 'charla:motivacion',
      );
    }
    if (dice([
      'dame un consejo',
      'un consejo',
      'aconsejame',
      'que me aconsejas',
    ])) {
      return RespuestaCharla(
        c.alguna(const [
          'Toma agua, duerme bien y no dejes todo para la última noche. Los '
              'tres juntos valen más que cualquier truco.',
          'Pregunta en clase. La duda que tú tienes, la tienen otros diez.',
          'Haz amigos en tu carrera: estudiar en grupo (de verdad) rinde '
              'muchísimo.',
          'Guarda tus apuntes ordenados desde el primer día. Tu yo del examen '
              'te lo va a agradecer.',
        ]),
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'como hacer amigos',
      'como hago amigos',
      'no tengo amigos en la u',
      'quiero hacer amigos',
      'quiero tener amigos',
      'hacer amigos',
      'conocer gente',
      'como conozco gente',
      'quiero conocer gente',
    ])) {
      return const RespuestaCharla(
        'Lo más fácil: grupos de estudio. Pregúntale a alguien de tu clase si '
        'quiere repasar juntos; casi todos dicen que sí. También ayudan los '
        'clubes y actividades de la U. Y conversar en la fila de la '
        'cafetería, que todos estamos igual de hambrientos.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'estudiar en una noche',
      'estudio en una noche',
      'en una noche',
      'no estudie nada',
      'no estudie',
      'examen manana y no se nada',
    ])) {
      return const RespuestaCharla(
        'Plan de emergencia:\n'
        '1. **Prioriza**: lo que más entra en el examen y lo que el profe '
        'repitió en clase. No intentes verlo todo.\n'
        '2. **Haz ejercicios** de exámenes anteriores, no solo leas.\n'
        '3. Bloques de 25 minutos con 5 de descanso, celular lejos.\n'
        '4. **Duerme al menos unas horas**: sin sueño, lo que estudiaste no se '
        'fija y en el examen te bloqueas.\n\n'
        'Si es álgebra, cálculo o C++, aquí te ayudo a repasar al toque.',
        intencion: 'charla:consejo',
        opciones: _materias,
      );
    }
    if (dice([
      'bajar de peso',
      'adelgazar',
      'como bajo de peso',
      'quiero estar en forma',
      'comer sano',
      'comer saludable',
      'como como sano',
      'dieta',
    ])) {
      return const RespuestaCharla(
        'Lo que funciona y no falla: más agua y menos gaseosa, comida de verdad '
        '(fruta, verdura, proteína), moverte todos los días aunque sea '
        'caminando, y dormir bien. Para un plan a tu medida, mejor un '
        'nutricionista.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'cuanta agua debo tomar',
      'cuanta agua tomo',
      'cuanta agua hay que tomar',
      'cuantos litros de agua',
      'cuanta agua tomar',
    ])) {
      return const RespuestaCharla(
        'Una guía común son unos 2 litros al día (unos 8 vasos), y más si hace '
        'calor o haces deporte. En Santa Cruz, seguro más. La mejor señal: si '
        'tu orina es clarita, vas bien.',
        intencion: 'charla:consejo',
      );
    }
    if (dice(['como ahorrar', 'como ahorro', 'consejos para ahorrar'])) {
      return const RespuestaCharla(
        'Lo básico: apunta en qué gastas una semana (te vas a sorprender), '
        'aparta un poquito apenas te llega la plata y compara antes de '
        'comprar. Y si quieres sumar, vende algo en U market: es gratis.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'como hago una tesis',
      'como hacer una tesis',
      'como se hace una tesis',
      'como hago mi tesis',
      'como empiezo mi tesis',
      'como empiezo la tesis',
      'ayudame con mi tesis',
      'me ayudas con mi tesis',
      'tema de tesis',
      'tema para mi tesis',
      'perfil de tesis',
      'perfil de proyecto',
      'como hago mi proyecto de grado',
      'como hago el proyecto de grado',
      'como hago mi trabajo de grado',
    ])) {
      return const RespuestaCharla(
        'Por partes, que así sale:\n'
        '1. **Tema**: que te guste y que se pueda resolver o medir. Ni muy '
        'amplio ni imposible de conseguir datos.\n'
        '2. **Problema y objetivos**: qué vas a resolver y cómo vas a saber que '
        'lo lograste.\n'
        '3. **Antecedentes**: qué se hizo antes sobre lo mismo.\n'
        '4. **Tutor**: que apruebe el enfoque antes de que avances mucho.\n'
        '5. **Cronograma** con fechas reales, y escribir un poco cada día.\n\n'
        'Cita todo con el formato que pida tu carrera (muchas usan APA). Los '
        'formatos y los plazos exactos confírmalos con tu carrera.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'como hago un ensayo',
      'como hacer un ensayo',
      'como se hace un ensayo',
      'como escribo un ensayo',
      'como hago una monografia',
      'como hacer una monografia',
      'como hago un informe',
      'como hacer un informe',
      'como redacto',
      'como escribir mejor',
    ])) {
      return const RespuestaCharla(
        'La estructura que nunca falla:\n'
        '• **Introducción**: de qué hablas y cuál es tu idea principal.\n'
        '• **Desarrollo**: tus argumentos, uno por párrafo, con datos o '
        'fuentes.\n'
        '• **Conclusión**: qué demostraste, sin repetir todo.\n\n'
        'Cita tus fuentes (copiar sin citar es plagio), lee el texto en voz '
        'alta antes de entregarlo y revisa la ortografía.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'como hago una presentacion',
      'como hacer una presentacion',
      'como se hace una presentacion',
      'como hago una exposicion',
      'como hacer una exposicion',
      'como expongo',
      'como exponer',
      'tips para exponer',
      'consejos para exponer',
      'me da miedo exponer',
      'miedo a exponer',
      'como hablo en publico',
      'como hablar en publico',
      'hablar en publico',
      'como hago mis diapositivas',
      'como hago diapositivas',
      'como preparo mi defensa',
      'como me preparo para la defensa',
    ])) {
      return const RespuestaCharla(
        'Para exponer tranqui:\n'
        '1. **Pocas palabras por diapositiva**: la diapositiva acompaña, no se '
        'lee.\n'
        '2. **Ensaya en voz alta** dos o tres veces, con cronómetro.\n'
        '3. **Empieza fuerte**: una pregunta, un dato o una historia corta.\n'
        '4. **Mira al público**, no a la pantalla.\n'
        '5. **Los nervios bajan a los dos minutos**: respira hondo antes de '
        'empezar y habla un poquito más lento de lo normal.\n'
        '6. **Cierra con una idea clara**: lo que quieres que recuerden.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'como hago un cv',
      'como se hace un cv',
      'como hago mi cv',
      'como hacer un cv',
      'como hago un curriculum',
      'como hago mi curriculum',
      'como hacer un curriculum',
      'como hago mi hoja de vida',
      'hoja de vida',
      'curriculum vitae',
    ])) {
      return const RespuestaCharla(
        'Una hoja, clara y sin adornos:\n'
        '1. **Datos de contacto** (y una foto seria, si la ponen).\n'
        '2. **Perfil**: dos o tres líneas sobre qué estudias y qué buscas.\n'
        '3. **Formación**: tu carrera en la UPSA y el semestre.\n'
        '4. **Experiencia**: trabajos, pasantías, voluntariados y proyectos de '
        'la U (sí cuentan).\n'
        '5. **Habilidades**: programas, idiomas, certificados.\n\n'
        'Tip: si vendes en U market, eso también es experiencia: '
        'emprendimiento.',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'entrevista de trabajo',
      'tengo una entrevista',
      'como me preparo para una entrevista',
      'consejos para una entrevista',
    ])) {
      return const RespuestaCharla(
        'Para la entrevista:\n'
        '• Averigua qué hace la empresa antes de ir.\n'
        '• Prepara tres ejemplos de cosas que hiciste bien (un proyecto, un '
        'problema que resolviste).\n'
        '• Llega diez minutos antes.\n'
        '• Lleva una pregunta para ellos: muestra interés.\n'
        '• Si no sabes algo, dilo y cuenta cómo lo aprenderías.\n\n'
        '¡Mucha suerte!',
        intencion: 'charla:consejo',
      );
    }
    if (dice([
      'aprendo a programar',
      'aprender a programar',
      'quiero aprender a programar',
      'que lenguaje aprendo',
      'que lenguaje aprender',
      'que lenguaje de programacion aprendo',
      'con que lenguaje empiezo',
      'que lenguaje me recomiendas',
      'cual es el mejor lenguaje',
      'mejor lenguaje de programacion',
      'como ser buen programador',
      'como ser programador',
      'como mejoro programando',
      'como mejorar programando',
    ])) {
      return const RespuestaCharla(
        'Lo que funciona:\n'
        '1. **Un solo lenguaje** al principio: si en la U te toca C++, ese; si '
        'no, Python es el más amable para empezar.\n'
        '2. **Programa todos los días**, aunque sea poco: leer código no '
        'alcanza.\n'
        '3. **Ejercicios chicos** (una calculadora, adivina el número, el '
        'promedio de un curso) y después un proyecto tuyo.\n'
        '4. **Lee los errores con calma**: casi siempre traen la pista.\n'
        '5. Aprende **Git** temprano.\n\n'
        'Si quieres, arrancamos con C++:',
        intencion: 'charla:consejo',
        opciones: [OpcionMacias(id: 's:cpp', texto: 'Programación en C++')],
      );
    }
    if (dice([
      'que hago este finde',
      'que hago el finde',
      'que hago este fin de semana',
      'que hago el fin de semana',
      'plan para el finde',
      'planes para el finde',
      'lugar para salir',
      'lugares para salir',
      'donde salir',
      'a donde salgo',
      'a donde puedo ir',
      'que hacer en santa cruz',
      'lugares para visitar',
      'recomiendame un lugar',
      'que hago hoy',
    ])) {
      return const RespuestaCharla(
        'Planes cruceños que no fallan:\n'
        '• **Lomas de Arena**: dunas de verdad, a las afueras de la ciudad.\n'
        '• **Biocentro Güembé**: mariposario y piscinas.\n'
        '• El **Jardín Botánico** o el **Parque Urbano** para caminar.\n'
        '• La **Manzana Uno**, junto a la plaza 24 de Septiembre: arte y '
        'cultura.\n'
        '• Más lejos, **Samaipata** (el Fuerte) o las cascadas de '
        '**Espejillos**.\n\n'
        'Y si el plan es tranqui: maratón de series y algo rico del campus.',
        intencion: 'charla:consejo',
      );
    }
    return null;
  }

  static RespuestaCharla? _recomendaciones(String t, ContextoMacias c) {
    bool dice(List<String> frases) =>
        frases.any((f) => ' $t '.contains(' $f '));
    if (!RegExp(
      r'\b(?:recomiend\w*|recomendacion\w*|que (?:veo|leo|escucho))\b',
    ).hasMatch(t)) {
      return null;
    }
    if (dice(['pelicula', 'peli', 'serie', 'que veo'])) {
      return const RespuestaCharla(
        'Si te gustan las historias de mentes brillantes:\n'
        '• **Una mente brillante**: John Nash, matemático.\n'
        '• **El código Enigma**: Alan Turing y las primeras computadoras.\n'
        '• **Talentos ocultos**: las matemáticas que llevaron a la NASA al '
        'espacio.\n'
        '• **Red social**: cómo empezó Facebook, en una universidad.',
        intencion: 'charla:recomendacion',
      );
    }
    if (dice(['libro', 'leer', 'que leo'])) {
      return const RespuestaCharla(
        '• **El hombre que calculaba**, de Malba Tahan: cuentos con acertijos '
        'matemáticos. Un clásico.\n'
        '• **Hábitos atómicos**, de James Clear: para organizarte mejor.\n'
        '• Y el **Álgebra de Baldor**, que nunca falla.',
        intencion: 'charla:recomendacion',
      );
    }
    if (dice(['musica', 'cancion', 'canciones', 'que escucho', 'playlist'])) {
      return const RespuestaCharla(
        'Para estudiar: música sin letra. Lo-fi, música clásica o soundtracks '
        'de películas. La letra compite con lo que lees.',
        intencion: 'charla:recomendacion',
      );
    }
    if (dice(['comida', 'comer', 'almorzar', 'que como'])) {
      return const RespuestaCharla(
        'Mira la categoría **Comida** en el inicio: ahí está lo que venden '
        'hoy en el campus. Mi voto, igual, va para una salteña.',
        intencion: 'charla:recomendacion',
      );
    }
    return null;
  }

  static RespuestaCharla? _delicados(String t, ContextoMacias c) {
    final palabras = t.split(' ');
    bool dice(List<String> frases) =>
        frases.any((f) => ' $t '.contains(' $f '));
    bool palabra(List<String> lista) => lista.any(palabras.contains);
    if (palabra([
          'politica',
          'politico',
          'elecciones',
          'gobierno',
          'presidente',
          'evo',
          'arce',
          'camacho',
          'votar',
          'diputado',
          'senador',
        ]) ||
        dice(['por quien voto', 'partido politico'])) {
      return const RespuestaCharla(
        'De política no opino: soy un asistente apolítico, como el WiFi de la '
        'U, que no se conecta con nadie. Para noticias, mejor una fuente '
        'actualizada.',
        intencion: 'charla:delicado',
      );
    }
    if (dice([
      'quiero matar',
      'voy a matar',
      'lo voy a matar',
      'la voy a matar',
      'los voy a matar',
      'lo mato',
      'la mato',
      'matar a mi',
    ])) {
      return const RespuestaCharla(
        'Uy, respira hondo. A veces la U te saca de quicio, pero mejor '
        'descargamos la bronca resolviendo ejercicios. ¿Qué materia te tiene '
        'así?',
        intencion: 'charla:delicado',
        opciones: _materias,
      );
    }
    if (dice([
      'existe dios',
      'crees en dios',
      'eres creyente',
      'que religion',
    ])) {
      return const RespuestaCharla(
        'Esa es una pregunta muy personal, y cada uno tiene su respuesta. Yo, '
        'que soy un programa, prefiero respetarlas todas.',
        intencion: 'charla:delicado',
      );
    }
    if (palabra([
      'droga',
      'drogas',
      'marihuana',
      'cocaina',
      'porro',
      'hierba',
      'mota',
    ])) {
      return const RespuestaCharla(
        'De eso no. En U market tampoco se puede vender nada de eso: está '
        'prohibido. ¿Te ayudo con otra cosa?',
        intencion: 'charla:delicado',
      );
    }
    return null;
  }

  static const _adivinanzas = [
    (
      'Blanca por dentro, verde por fuera. Si quieres que te lo diga, espera.',
      ['pera'],
      'la pera',
    ),
    (
      'Oro parece, plata no es. El que no lo adivine, bien tonto es.',
      ['platano', 'banana', 'guineo'],
      'el plátano',
    ),
    ('Tiene dientes y no come, tiene barba y no es hombre.', ['ajo'], 'el ajo'),
    (
      'Vuela sin alas, silba sin boca, pega sin manos y no se ve.',
      ['viento', 'aire'],
      'el viento',
    ),
    (
      'Cuanto más le quitas, más grande se hace.',
      ['hoyo', 'agujero', 'pozo'],
      'un hoyo',
    ),
    ('Si me nombras, desaparezco.', ['silencio'], 'el silencio'),
    (
      'Tengo agujas y no sé coser; tengo números y no sé leer.',
      ['reloj'],
      'el reloj',
    ),
    ('Mientras más seca, más moja.', ['toalla'], 'la toalla'),
    (
      'Tiene ojos y no ve, tiene agua y no la bebe, tiene carne y no la come, '
          'tiene barba y no es hombre.',
      ['coco'],
      'el coco',
    ),
    (
      'Sube llena y baja vacía. Si no se apura, la sopa se enfría.',
      ['cuchara'],
      'la cuchara',
    ),
    (
      'Es tuyo, pero los demás lo usan mucho más que tú.',
      ['nombre'],
      'tu nombre',
    ),
    (
      'Si me tienes, quieres compartirme; si me compartes, ya no me tienes.',
      ['secreto'],
      'un secreto',
    ),
    (
      'Vas en una carrera y pasas al que va segundo. ¿En qué lugar quedas?',
      ['segundo', 'segunda', '2'],
      'segundo (si dijiste primero, caíste)',
    ),
    (
      '¿Qué pesa más, un kilo de plumas o un kilo de hierro?',
      ['igual', 'iguales', 'mismo', 'ninguno'],
      'lo mismo: los dos pesan un kilo',
    ),
    (
      'El papá de María tiene cinco hijas: Lala, Lele, Lili, Lolo y... ¿cómo '
          'se llama la quinta?',
      ['maria'],
      'María',
    ),
    (
      '¿Qué número, puesto de cabeza, vale tres menos?',
      ['9', 'nueve'],
      'el 9: de cabeza es un 6',
    ),
  ];

  static RespuestaCharla adivinanza(ContextoMacias c) {
    // No repetir la que se acaba de contar.
    final disponibles = [
      for (final a in _adivinanzas)
        if (!c.recientes.any((dicho) => dicho.contains(a.$1))) a,
    ];
    final lista = disponibles.isEmpty ? _adivinanzas : disponibles;
    final (texto, respuestas, solucion) = lista[c.sorteo % lista.length];
    return RespuestaCharla(
      '$texto\n\n¿Qué es? (Si te rindes, escribe **me rindo**.)',
      intencion: 'juego:adivinanza',
      espera: EsperaAdivinanza(respuestas, solucion),
    );
  }

  static RespuestaCharla? _divertidas(String t, ContextoMacias c) {
    bool dice(List<String> frases) =>
        frases.any((f) => ' $t '.contains(' $f '));
    if (dice(['adivinanza', 'adivina adivinador', 'acertijo'])) {
      return adivinanza(c);
    }
    if (dice([
      'cuentame un secreto',
      'dime un secreto',
      'un secreto',
      'tienes secretos',
      'tienes un secreto',
    ])) {
      return RespuestaCharla(
        c.alguna(const [
          'Un secreto: cuando nadie me escribe, repaso la tabla del 7. Es la '
              'que más me cuesta.',
          'Te cuento uno: a veces releo mis propios chistes y me río solo. No '
              'se lo digas a nadie.',
        ]),
        intencion: 'charla:secreto',
      );
    }
    if (dice(['trabalenguas'])) {
      return RespuestaCharla(
        c.alguna(const [
          'Tres tristes tigres tragaban trigo en un trigal. Dilo rápido tres '
              'veces.',
          'Pablito clavó un clavito. ¿Qué clavito clavó Pablito?',
          'El cielo está enladrillado, ¿quién lo desenladrillará? El '
              'desenladrillador que lo desenladrille, buen desenladrillador '
              'será.',
        ]),
        intencion: 'charla:trabalenguas',
      );
    }
    if (dice(['poema', 'poesia', 'un verso', 'versos'])) {
      return RespuestaCharla(
        c.alguna(const [
          'Estudié hasta la madrugada,\nla integral no me salía;\nle sumé '
              'una constante\ny salió el sol de un nuevo día.',
          'En el campus hay salteñas,\nhay apuro y hay calor;\npero si '
              'apruebas cálculo,\nno hay sabor que sea mejor.',
          'Un puntero me buscaba,\nyo no sabía dónde estaba;\nera un '
              'segmentation fault\ny mi código lloraba.',
        ]),
        intencion: 'charla:poema',
      );
    }
    final contar = RegExp(
      r'cuenta (?:hasta|del 1 al|de 1 a) (\d+)',
    ).firstMatch(t);
    if (contar != null) {
      final hasta = int.parse(contar[1]!);
      if (hasta > 30) {
        return const RespuestaCharla(
          'Uf, eso es mucho. Hasta 30 te acompaño; más, ni el Baldor.',
          intencion: 'charla:contar',
        );
      }
      return RespuestaCharla(
        '${[for (var i = 1; i <= hasta; i++) i].join(', ')}. ¡Listo!',
        intencion: 'charla:contar',
      );
    }
    if (dice([
      'di algo',
      'habla',
      'dime algo',
      'cuentame algo',
      'sorprendeme',
    ])) {
      return null; // Lo atiende el dato curioso.
    }
    return null;
  }

  static final _preguntaAlFuturo = RegExp(
    r'^(?:crees que |sera que |me pregunto si )?(?:voy a|vas a|me va a|va a|'
    r'vamos a|aprobare|pasare|me ira|me saldra|me quiere|le gusto|sere)\b',
  );

  /// "¿Voy a aprobar?": nadie sabe, asi que se contesta como bola magica,
  /// con humor y sin prometer nada.
  static RespuestaCharla? _bolaMagica(String t, ContextoMacias c) {
    if (!_preguntaAlFuturo.hasMatch(t)) return null;
    return RespuestaCharla(
      c.alguna(const [
        'Según mis cálculos... sí. Pero estudia igual, por si me equivoqué en '
            'un signo.',
        'Las señales dicen que sí. Las señales también dicen que repases.',
        'No puedo ver el futuro, pero si te preparas, las probabilidades '
            'suben bastante.',
        'Mmm, pregúntame de nuevo después de estudiar un rato.',
        'Todo indica que sí. Y si no, siempre hay segunda instancia.',
      ]),
      intencion: 'charla:bola',
    );
  }

  // ============================================================== memoria
  static final _meLlamo = RegExp(
    r'(?:me llamo|mi nombre es|ll[aá]mame|puedes llamarme|dime nom[aá]s|'
    r'me dicen|puedes decirme|decime)\s+'
    r'([a-záéíóúñü]+(?:\s+[a-záéíóúñü]+)?)',
    caseSensitive: false,
  );

  static const _noSonNombres = {
    'que',
    'como',
    'el',
    'la',
    'los',
    'las',
    'un',
    'una',
    'de',
    'no',
    'si',
    'mas',
    'otro',
    'otra',
    'asi',
    'a',
    'por',
    'para',
    'y',
    'o',
    'tu',
    'mi',
    'algo',
    'nada',
    'eso',
    'esto',
  };

  static final _soy = RegExp(r'^(?:y )?(?:yo )?soy ([a-z]+)$');

  /// Lo que va despues de "soy" y no es un nombre.
  static const _noSoyNombre = {
    'feliz',
    'pobre',
    'rico',
    'rica',
    'nuevo',
    'nueva',
    'estudiante',
    'alumno',
    'alumna',
    'hombre',
    'mujer',
    'chico',
    'chica',
    'nino',
    'nina',
    'yo',
    'ella',
    'ese',
    'esa',
    'bueno',
    'buena',
    'malo',
    'mala',
    'lindo',
    'linda',
    'feo',
    'fea',
    'tonto',
    'tonta',
    'gay',
    'soltero',
    'soltera',
    'novato',
    'novata',
    'mayor',
    'menor',
    'grande',
    'joven',
    'viejo',
    'vieja',
    'alto',
    'alta',
    'bajo',
    'baja',
    'flaco',
    'flaca',
    'gordo',
    'gorda',
    'camba',
    'colla',
    'chapaco',
    'chapaca',
    'boliviano',
    'boliviana',
    'cruceno',
    'crucena',
    'paceno',
    'pacena',
    'humano',
    'humana',
    'real',
    'persona',
    'bot',
    'robot',
    'ingeniero',
    'ingeniera',
    'abogado',
    'abogada',
    'profesor',
    'profesora',
    'docente',
    'vendedor',
    'vendedora',
    'cliente',
    'primero',
    'primera',
    'libre',
    'fan',
    'hincha',
    'vegano',
    'vegana',
    'vegetariano',
    'vegetariana',
    'timido',
    'timida',
    'todo',
    'tuyo',
    'tuya',
    'mejor',
    'peor',
    'nadie',
    'alguien',
    'ateo',
    'atea',
    'catolico',
    'catolica',
    'cristiano',
    'cristiana',
    'mama',
    'papa',
    'hijo',
    'hija',
    'malisimo',
    'malisima',
  };

  static final _adjetivo = RegExp(
    r'(?:ado|ada|ido|ida|oso|osa|ble|nte|dor|dora|ista|ivo|iva|ero|era)$',
  );

  /// "Soy Jotade": un nombre, salvo que sea "soy feliz", "soy camba" o "soy
  /// ingeniero".
  static String? nombreSoyEn(String limpio, String original) {
    final encontrado = _soy.firstMatch(limpio);
    if (encontrado == null) return null;
    final palabra = encontrado[1]!;
    if (palabra.length < 3 ||
        palabra.length > 15 ||
        _noSoyNombre.contains(palabra) ||
        _noSonNombres.contains(palabra) ||
        (palabra.length > 5 && _adjetivo.hasMatch(palabra)) ||
        MemoriaMacias.carreraDe(palabra) != null ||
        MemoriaMacias.ciudadDe(palabra) != null) {
      return null;
    }
    // Tal como lo escribio ("Jotade", "José"), con mayuscula.
    final escrito =
        RegExp(r'(\p{L}+)\P{L}*$', unicode: true).firstMatch(original)?[1] ??
        palabra;
    return escrito[0].toUpperCase() + escrito.substring(1).toLowerCase();
  }

  /// "me llamo Ana": el nombre tal como lo escribio, con mayuscula.
  static String? nombreEn(String original) {
    final encontrado = _meLlamo.firstMatch(original);
    if (encontrado == null) return null;
    final palabras = encontrado[1]!.split(RegExp(r'\s+'));
    // "me llamó la atención" no es un nombre.
    if (_noSonNombres.contains(LenguajeMacias.normalizar(palabras.first))) {
      return null;
    }
    final validas = [
      for (final p in palabras)
        if (!_noSonNombres.contains(LenguajeMacias.normalizar(p))) p,
    ];
    if (validas.isEmpty || validas.any((p) => p.length < 2)) return null;
    final nombre = validas
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
    return nombre.length > 24 ? null : nombre;
  }

  static final _estudio = RegExp(
    r'^(?:yo )?(?:estudio|curso|mi carrera es|soy de|estoy en|'
    r'soy estudiante de|estudiante de|voy en|sigo)\s+(.+)$',
  );

  /// "estudio sistemas", "soy de derecho": la carrera, si es una de la UPSA.
  static String? carreraEn(String limpio) {
    final encontrado = _estudio.firstMatch(limpio);
    if (encontrado == null) return null;
    return MemoriaMacias.carreraDe(encontrado[1]!);
  }

  static final _deDonde = RegExp(
    r'^(?:yo )?(?:soy de|soy|vengo de|vivo en|naci en|soy nacido en|'
    r'soy nacida en)\s+(.+)$',
  );

  /// "soy de Cochabamba", "soy camba": de donde es.
  static String? ciudadEn(String limpio) {
    final encontrado = _deDonde.firstMatch(limpio);
    if (encontrado == null) return null;
    final resto = encontrado[1]!;
    if (resto.split(' ').length > 5) return null;
    return MemoriaMacias.ciudadDe(resto);
  }

  static final _meGusta = RegExp(
    r'^(?:a mi )?(no )?(?:me gusta|me gustan|me encanta|me encantan|amo|odio) '
    r'(?:mucho )?((?:el |la |los |las |un |una )?.+)$',
  );

  /// "Me gusta una chica de mi curso" es un crush, no un gusto que anotar.
  static final _unaPersona = RegExp(
    r'^(?:(?:una|un|mi|esa|ese|esta|este) )?(?:chica|chico|persona|alguien|'
    r'companera|companero|amiga|amigo|crush|muchacha|muchacho|chiquilla|'
    r'chiquillo)\b',
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
    'tu',
    'hablar contigo',
  ];

  /// "me gusta la pizza", "odio el surazo": que (tal como lo escribio) y si
  /// le gusta o no.
  static ({String cosa, bool gusta})? gustoEn(
    String limpio,
    List<FichaTexto> fichas,
    String original,
  ) {
    final encontrado = _meGusta.firstMatch(limpio);
    if (encontrado == null) return null;
    final cosa = encontrado[2]!.trim();
    if (cosa.isEmpty ||
        cosa.length > 40 ||
        _noSonGustos.contains(sinArticulo(cosa)) ||
        _unaPersona.hasMatch(cosa)) {
      return null;
    }
    final niega = encontrado[1] != null || limpio.startsWith('odio');
    return (
      cosa: _textoOriginal(limpio, cosa, fichas, original),
      gusta: !niega,
    );
  }

  static const _tildes = {
    'saltena': 'salteña',
    'saltenas': 'salteñas',
    'cunape': 'cuñapé',
    'cunapes': 'cuñapés',
    'cafe': 'café',
    'te': 'té',
    'sandwich': 'sándwich',
    'jamon': 'jamón',
    'limon': 'limón',
    'melon': 'melón',
    'platano': 'plátano',
    'mani': 'maní',
    'futbol': 'fútbol',
    'musica': 'música',
    'matematicas': 'matemáticas',
    'algebra': 'álgebra',
    'calculo': 'cálculo',
    'programacion': 'programación',
    'cancion': 'canción',
    'canciones': 'canciones',
    'pelicula': 'película',
    'peliculas': 'películas',
    'fisica': 'física',
    'quimica': 'química',
    'matematica': 'matemática',
    'estadistica': 'estadística',
    'ingles': 'inglés',
    'tecnologia': 'tecnología',
    'fotografia': 'fotografía',
    'arbol': 'árbol',
    'raton': 'ratón',
    'pinguinos': 'pingüinos',
  };

  /// "saltena" -> "salteña": lo que se guardo normalizado, escrito bien.
  static String conTildes(String texto) {
    final palabras = texto.split(' ');
    return [
      for (final (i, p) in palabras.indexed)
        // "Te" es la bebida solo si va sola o es "el té", "un té".
        p == 'te' &&
                palabras.length > 1 &&
                (i == 0 || !_antesDelTe.contains(palabras[i - 1]))
            ? p
            : _tildes[p] ?? p,
    ].join(' ');
  }

  static const _antesDelTe = {'el', 'un', 'de', 'del', 'con', 'mi', 'tu'};

  /// "cancion" -> "canción".
  static String nombreCategoria(String categoria) => switch (categoria) {
    'cancion' => 'canción',
    'pelicula' => 'película',
    'musica' => 'música',
    'numero' => 'número',
    _ => categoria,
  };

  /// Lo que va antes de la respuesta de verdad: "creo que", "el mío es",
  /// "mi favorita es".
  static final _antesDeLoQueDijo = RegExp(
    r'^(?:(?:yo|pues|bueno|creo|que|diria|seria|obvio|claro|definitivamente|'
    r'sin|duda|ah|eh|jaja|mmm) )*'
    r'(?:(?:el|la) (?:mio|mia) (?:es )?|(?:mi|el|la) (?:favorito|favorita) '
    r'(?:es )?|me (?:gusta|encanta) (?:mas )?)?',
  );

  /// Lo que contesto, sin el "creo que...": "creo que el azul" da "el
  /// azul", con sus tildes.
  static String loQueDijo(
    String limpio,
    List<FichaTexto> fichas,
    String original,
  ) {
    final palabras = limpio.split(' ');
    final antes = _antesDeLoQueDijo.firstMatch('$limpio ')?[0]?.trim() ?? '';
    final k = antes.isEmpty ? 0 : antes.split(' ').length;
    if (k >= palabras.length) return '';
    if (palabras.length != fichas.length) return palabras.sublist(k).join(' ');
    return original
        .substring(fichas[k].inicio, fichas.last.fin)
        .replaceAll(RegExp(r'[.!?¡¿]+$'), '')
        .trim();
  }

  static const _categoriasFavoritas = {
    'color': true,
    'comida': false,
    'plato': true,
    'materia': false,
    'cancion': false,
    'pelicula': false,
    'serie': false,
    'equipo': true,
    'deporte': true,
    'animal': true,
    'bebida': false,
    'lugar': true,
    'numero': true,
    'libro': true,
    'banda': false,
    'cantante': true,
    'artista': true,
    'juego': true,
    'videojuego': true,
    'fruta': false,
    'postre': true,
    'musica': false,
    'grupo': true,
    'personaje': true,
    'profesor': true,
    'anime': true,
  };

  /// Si la categoria es masculina: "tu color favorito", "tu comida
  /// favorita".
  static bool esMasculina(String categoria) =>
      _categoriasFavoritas[categoria] ?? true;

  static final _miFavorito = RegExp(
    r'^(?:mi|el|la) ([a-z]+) (?:favorito|favorita|preferido|preferida) '
    r'(?:es )?((?:el |la |los |las |un |una )?.+)$',
  );

  /// "mi color favorito es el azul": la categoria y la cosa, tal como la
  /// escribio.
  static ({String categoria, String cosa})? favoritoEn(
    String limpio,
    List<FichaTexto> fichas,
    String original,
  ) {
    final encontrado = _miFavorito.firstMatch(limpio);
    if (encontrado == null) return null;
    final categoria = encontrado[1]!;
    if (!_categoriasFavoritas.containsKey(categoria)) return null;
    final cosa = _textoOriginal(limpio, encontrado[2]!, fichas, original);
    if (cosa.isEmpty || cosa.length > 40) return null;
    return (categoria: categoria, cosa: cosa);
  }

  static final _cualEsMiFavorito = RegExp(
    r'^(?:cual es|sabes cual es|te acuerdas de|te acuerdas cual es|cual era) '
    r'(?:mi|el|la) ([a-z]+) (?:favorito|favorita|preferido|preferida)$',
  );

  static String? preguntaFavorito(String limpio) =>
      _cualEsMiFavorito.firstMatch(limpio)?[1];

  /// El pedazo del texto original que corresponde a [parte] (las ultimas
  /// palabras de [limpio]), para guardarlo con sus tildes y su ñ.
  static String _textoOriginal(
    String limpio,
    String parte,
    List<FichaTexto> fichas,
    String original,
  ) {
    final palabras = limpio.split(' ').length;
    final cuantas = parte.split(' ').length;
    final desde = palabras - cuantas;
    if (desde < 0 || desde >= fichas.length || palabras != fichas.length) {
      return parte;
    }
    return original
        .substring(fichas[desde].inicio, fichas.last.fin)
        .replaceAll(RegExp(r'[.!?¡¿]+$'), '')
        .trim();
  }

  static final _edad = RegExp(r'^(?:yo )?tengo (\d{1,2}) anos$');

  static int? edadEn(String limpio) {
    final encontrado = _edad.firstMatch(limpio);
    if (encontrado == null) return null;
    final edad = int.parse(encontrado[1]!);
    return edad >= 14 && edad <= 80 ? edad : null;
  }

  static final _cumple = RegExp(
    r'^(?:mi (?:cumpleanos|cumple) (?:es|sera|fue|cae)|cumplo(?: anos)?|'
    r'naci|yo naci|hoy es mi (?:cumpleanos|cumple)|hoy cumplo(?: anos)?|'
    r'manana es mi (?:cumpleanos|cumple))\b(.*)$',
  );

  /// "mi cumpleaños es el 5 de mayo", "nací el 3 de abril de 2004", "hoy es
  /// mi cumpleaños". El año solo si lo dijo.
  static ({int mes, int dia, int? anio})? cumpleEn(
    String limpio,
    DateTime ahora,
  ) {
    final encontrado = _cumple.firstMatch(limpio);
    if (encontrado == null) return null;
    if (limpio.startsWith('hoy')) {
      return (mes: ahora.month, dia: ahora.day, anio: null);
    }
    if (limpio.startsWith('manana')) {
      final manana = DateTime(ahora.year, ahora.month, ahora.day + 1);
      return (mes: manana.month, dia: manana.day, anio: null);
    }
    final resto = encontrado[1]!.trim();
    final fecha = FechasMacias.fechaEn(resto, ahora);
    if (fecha == null) return null;
    final anio = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(resto)?[1];
    return (
      mes: fecha.month,
      dia: fecha.day,
      anio: anio == null ? null : int.parse(anio),
    );
  }

  static const _examenes = {
    'examen',
    'examenes',
    'parcial',
    'parciales',
    'final',
    'finales',
    'prueba',
    'practico',
    'quiz',
    'defensa',
    'exposicion',
    'presentacion',
  };

  /// Las materias que MacIAs sabe escribir bien.
  static const _materiasConTilde = {
    'algebra': 'álgebra',
    'calculo': 'cálculo',
    'calculo 2': 'cálculo II',
    'calculo ii': 'cálculo II',
    'calculo integral': 'cálculo integral',
    'calculo 1': 'cálculo I',
    'calculo diferencial': 'cálculo diferencial',
    'fisica': 'física',
    'quimica': 'química',
    'estadistica': 'estadística',
    'ingles': 'inglés',
    'matematica': 'matemática',
    'matematicas': 'matemáticas',
    'economia': 'economía',
    'programacion': 'programación',
    'c': 'C++',
    'cpp': 'C++',
    'geometria': 'geometría',
    'trigonometria': 'trigonometría',
    'contabilidad': 'contabilidad',
    'derecho': 'derecho',
  };

  /// "tengo examen de cálculo el viernes": la materia (puede faltar) y la
  /// fecha (puede faltar). Null si no habla de un examen suyo.
  static ({String materia, DateTime? fecha, String tipo})? examenEn(
    String limpio,
    List<FichaTexto> fichas,
    String original,
    DateTime ahora,
  ) {
    // "¿Cómo preparo mi defensa?" pide consejos, no anota nada.
    if (RegExp(r'^(?:como|que hago|tips|consejos)\b').hasMatch(limpio)) {
      return null;
    }
    final palabras = limpio.split(' ');
    final indice = palabras.indexWhere(_examenes.contains);
    if (indice < 0) return null;
    final tipo = switch (palabras[indice]) {
      'examenes' => 'examen',
      'parciales' => 'parcial',
      'finales' => 'final',
      final otro => otro,
    };
    // Tiene que ser suyo: "tengo examen", "me toca parcial", "mañana es mi
    // final". No "qué es un examen".
    final antes = palabras.sublist(0, indice).join(' ');
    final esSuyo = RegExp(
      r'\b(?:tengo|tendre|hay|me toca|doy|rindo|voy a dar|voy a rendir|es mi|'
      r'mi|tenemos|nos toca)\b',
    ).hasMatch(antes);
    if (!esSuyo) return null;

    final fecha = FechasMacias.fechaEn(limpio, ahora);
    // La materia: lo que va despues de "de", hasta una palabra de tiempo.
    var materia = '';
    if (indice + 1 < palabras.length && palabras[indice + 1] == 'de') {
      final despues = <String>[];
      for (final palabra in palabras.skip(indice + 2)) {
        if (_cortaMateria.contains(palabra) ||
            RegExp(r'^\d').hasMatch(palabra)) {
          break;
        }
        despues.add(palabra);
        if (despues.length == 3) break;
      }
      final normal = despues.join(' ');
      materia =
          _materiasConTilde[normal] ??
          (normal.isEmpty
              ? ''
              : _textoDeFichas(fichas, indice + 2, despues.length));
    }
    return (materia: materia, fecha: fecha, tipo: tipo);
  }

  static const _cortaMateria = {
    'manana',
    'hoy',
    'el',
    'este',
    'esta',
    'la',
    'pasado',
    'en',
    'dentro',
    'para',
    'a',
    'y',
    'que',
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
    'proxima',
    'proximo',
  };

  static String _textoDeFichas(
    List<FichaTexto> fichas,
    int desde,
    int cuantas,
  ) {
    if (desde + cuantas > fichas.length) return '';
    return [
      for (var i = desde; i < desde + cuantas; i++) fichas[i].original,
    ].join(' ').toLowerCase();
  }

  /// Quien puede tener nombre en su vida.
  static const _roles = {
    'novia',
    'novio',
    'pareja',
    'esposa',
    'esposo',
    'crush',
    'mejor amigo',
    'mejor amiga',
    'amigo',
    'amiga',
    'mama',
    'papa',
    'madre',
    'padre',
    'hermano',
    'hermana',
    'hijo',
    'hija',
    'abuelo',
    'abuela',
    'tio',
    'tia',
    'primo',
    'prima',
    'companero',
    'companera',
    'profesor',
    'profesora',
    'jefe',
    'jefa',
    'perro',
    'perra',
    'perrito',
    'perrita',
    'gato',
    'gata',
    'gatito',
    'gatita',
    'mascota',
    'loro',
    'conejo',
    'hamster',
    'tortuga',
    'pez',
  };

  static const mascotas = {
    'perro',
    'perra',
    'perrito',
    'perrita',
    'gato',
    'gata',
    'gatito',
    'gatita',
    'mascota',
    'loro',
    'conejo',
    'hamster',
    'tortuga',
    'pez',
  };

  /// "mama" -> "mamá", "companero" -> "compañero".
  static String nombreRol(String rol) => switch (rol) {
    'mama' => 'mamá',
    'papa' => 'papá',
    'tio' => 'tío',
    'tia' => 'tía',
    'companero' => 'compañero',
    'companera' => 'compañera',
    'hamster' => 'hámster',
    _ => rol,
  };

  static final _seLlama = RegExp(
    r'^(?:y )?mi ([a-z]+(?: [a-z]+)?) se llama ([a-z]+(?: [a-z]+)?)$',
  );
  static final _tengoUn = RegExp(
    r'^(?:yo )?tengo (?:un |una )?([a-z]+(?: [a-z]+)?) '
    r'(?:que se llama|llamado|llamada|de nombre) ([a-z]+(?: [a-z]+)?)$',
  );

  /// "mi perro se llama Rocky", "tengo una gata llamada Luna".
  static ({String rol, String nombre})? personaEn(
    String limpio,
    List<FichaTexto> fichas,
    String original,
  ) {
    final encontrado =
        _seLlama.firstMatch(limpio) ?? _tengoUn.firstMatch(limpio);
    if (encontrado == null) return null;
    // "profe" se guarda como "profesor", igual que se pregunta.
    final rol = LenguajeMacias.palabrasDe(encontrado[1]!).join(' ');
    if (!_roles.contains(rol)) return null;
    final nombre = _textoOriginal(
      limpio,
      encontrado[2]!,
      fichas,
      original,
    ).split(' ').map(LenguajeMacias.conMayuscula).join(' ');
    if (nombre.length > 24) return null;
    return (rol: rol, nombre: nombre);
  }

  static final _comoSeLlama = RegExp(
    r'^(?:y )?(?:como se llama|cual es el nombre de|te acuerdas como se llama|'
    r'sabes como se llama|te acuerdas del nombre de) (?:mi |el |la )?'
    r'([a-z]+(?: [a-z]+)?)$',
  );

  /// "¿cómo se llama mi perro?": de quien pregunta.
  static String? preguntaPersona(String junto) {
    final encontrado = _comoSeLlama.firstMatch(junto);
    if (encontrado == null) return null;
    return _roles.contains(encontrado[1]) ? encontrado[1] : null;
  }

  static final _trabajo = RegExp(
    r'^(?:yo )?(?:trabajo|ahora trabajo|estoy trabajando|tambien trabajo) '
    r'((?:en (?:un|una|el|la|los|las|mi) |como ).+)$',
  );

  /// "trabajo en una tienda", "trabajo como mesero". ("Trabajo de
  /// matemática" no cuenta: casi siempre es un trabajo práctico.)
  static String? trabajoEn(
    String limpio,
    List<FichaTexto> fichas,
    String original,
  ) {
    final encontrado = _trabajo.firstMatch(limpio);
    if (encontrado == null) return null;
    final texto = _textoOriginal(limpio, encontrado[1]!, fichas, original);
    return texto.length > 50 ? null : texto;
  }

  static final _recuerdame = RegExp(
    r'^(?:por favor )?(?:recuerdame|recordame|acuerdate|no te olvides|'
    r'no olvides|anota|anotame|apunta|apuntame|guarda que|recorda|'
    r'puedes recordarme|me puedes recordar|podrias recordarme)'
    r'(?: de| que)? (.+)$',
  );

  /// "¿Puedes recordarme algo?" pregunta si se puede, no dice que.
  static const _notasVacias = {'algo', 'una cosa', 'cosas', 'algo importante'};

  /// "recuérdame comprar fotocopias": la nota, dicha de vuelta ("comprar
  /// fotocopias"), con sus tildes.
  static String? notaEn(
    String limpio,
    List<FichaTexto> fichas,
    String original,
  ) {
    final encontrado = _recuerdame.firstMatch(limpio);
    if (encontrado == null || _notasVacias.contains(encontrado[1])) {
      return null;
    }
    final texto = _textoOriginal(limpio, encontrado[1]!, fichas, original);
    if (texto.length < 3 || texto.length > 120) return null;
    return LenguajeMacias.reflejar(texto);
  }

  static const _si = {
    'si',
    'claro',
    'obvio',
    'me encanta',
    'me gusta',
    'mucho',
    'por supuesto',
    'simon',
    'a full',
    'demasiado',
    'dale',
    'ok',
    'bueno',
    'ya',
    'va',
    'de una',
    'sale',
    'por favor',
    'si por favor',
    'claro que si',
    'quiero',
    'si quiero',
    'me gustaria',
    'otra',
    'otro',
    'otra vez',
    'de nuevo',
    'vamos',
    'si dale',
    'obvio que si',
  };
  static const _no = {
    'no',
    'nada',
    'para nada',
    'no me gusta',
    'odio',
    'ni un poco',
    'no gracias',
    'despues',
    'luego',
    'ahora no',
    'mejor no',
    'paso',
    'no quiero',
    'nunca',
    'tampoco',
  };

  /// Lo que puede acompañar a un si o a un no sin cambiarlo: "sí, porfa",
  /// "no, gracias". "No me entiendes" no es un no.
  static const _acompananSiNo = {
    'gracias',
    'por',
    'favor',
    'ahora',
    'nada',
    'mas',
    'todavia',
    'aun',
    'dale',
    'claro',
    'obvio',
    'quiero',
    'mucho',
    'bueno',
    'ya',
    'esta',
    'bien',
    'eso',
    'es',
    'todo',
    'jaja',
    'macias',
    'nomas',
    'pues',
    'creo',
    'que',
    'tal',
    'vez',
    'otra',
    'otro',
    'vamos',
    'va',
  };

  /// Un "sí" o un "no". Null si es otra cosa.
  static bool? respuestaSiNo(String limpio) {
    final palabras = LenguajeMacias.palabrasDe(limpio);
    final junto = palabras.join(' ');
    if (_si.contains(junto)) return true;
    if (_no.contains(junto)) return false;
    final resto = palabras.skip(1);
    if (palabras.length <= 4 && resto.every(_acompananSiNo.contains)) {
      if (palabras.first == 'si') return true;
      if (palabras.first == 'no') return false;
    }
    return null;
  }

  // ===================================================== no se sabe
  static final _desconocido = <RegExp>[
    RegExp(
      r'^(?:me puedes decir |sabes |me dices |dime |sabias )?(?:que|q) '
      r'(?:es|son|significa|significan|era|fue) (?:el |la |los |las |un |una |lo )?(.+)$',
    ),
    RegExp(
      r'^(?:quien|quienes) (?:es|son|fue|fueron|invento|creo|descubrio|'
      r'gano|escribio|pinto) (?:el |la |los |las )?(.+)$',
    ),
    RegExp(
      r'^(?:cual|cuales) (?:es|son|fue) (?:el |la |los |las |tu |su )?(.+)$',
    ),
    RegExp(
      r'^(?:cuanto|cuanta|cuantos|cuantas) (?:mide|pesa|cuesta|vale|dura|'
      r'tiene|hay en|son|viven|vive) (?:el |la |los |las |un |una )?(.+)$',
    ),
    RegExp(
      r'^donde (?:queda|esta|estan|es|se encuentra|venden|compro|hay) '
      r'(?:el |la |los |las |un |una )?(.+)$',
    ),
    RegExp(
      r'^cuando (?:es|fue|son|empieza|termina|sale|abre|cierra) '
      r'(?:el |la |los |las )?(.+)$',
    ),
    RegExp(
      r'^como (?:se hace|se hacen|se prepara|se dice|funciona|hago|preparo|'
      r'se juega|se cocina) (?:el |la |los |las |un |una )?(.+)$',
    ),
    RegExp(
      r'^(?:sabes|conoces) (?:algo )?(?:de |sobre |a )?(?:el |la |los |las )?(.+)$',
    ),
    RegExp(
      r'^(?:hablame|cuentame|dime algo) (?:de|sobre) (?:el |la |los |las )?(.+)$',
    ),
  ];

  /// De que preguntaron, cuando es algo que MacIAs no sabe: "¿qué es la
  /// fotosíntesis?" da "fotosíntesis", tal como se escribio. Para decir
  /// "de eso no sé" sin sonar a que no se leyo la pregunta.
  static String? temaDesconocido(
    String limpio,
    List<FichaTexto> fichas,
    String original,
  ) {
    for (final patron in _desconocido) {
      final encontrado = patron.firstMatch(limpio);
      if (encontrado == null) continue;
      final tema = encontrado[1]!.trim();
      final palabras = tema.split(' ');
      if (palabras.length > 6 || tema.length < 3) return null;
      if (palabras.every(LenguajeMacias.vacias.contains)) return null;
      return _textoOriginal(limpio, tema, fichas, original);
    }
    return null;
  }

  static bool esPregunta(String original, String limpio) =>
      original.contains('?') ||
      RegExp(
        r'^(?:que|q|quien|quienes|cual|cuales|donde|cuando|como|por que|'
        r'porque|cuanto|cuantos|cuantas|sabes|conoces)\b',
      ).hasMatch(limpio);
}
