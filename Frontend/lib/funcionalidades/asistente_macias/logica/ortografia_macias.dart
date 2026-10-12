import 'conversacion_macias.dart';

/// Las dudas de ortografia de todos los dias: "hay, ahí o ay", "haber o a
/// ver", "porque o por qué", tildes, b o v. Corto y con ejemplo.
abstract final class OrtografiaMacias {
  static RespuestaCharla? responder(String t) {
    final texto = ' $t ';
    // Una duda nombra al menos dos de las palabras que se confunden, y se
    // nota que pregunta por la escritura: "ah, voy a la U" no es una duda.
    // Sin pedir la diferencia, el mensaje tiene que ser solo esas palabras:
    // "¿a ver o haber?".
    var resto = texto;
    for (final (palabras, _) in _dudas) {
      for (final palabra in palabras) {
        while (resto.contains(' $palabra ')) {
          resto = resto.replaceFirst(' $palabra ', ' ');
        }
      }
    }
    final preguntaPorEscritura =
        _pideDiferencia.hasMatch(t) ||
        resto.trim().split(' ').every((p) => p.isEmpty || _relleno.contains(p));
    if (preguntaPorEscritura) {
      for (final (palabras, explicacion) in _dudas) {
        final nombradas = palabras.where((p) => texto.contains(' $p ')).length;
        if (nombradas >= 2) {
          return RespuestaCharla(explicacion, intencion: 'saber:ortografia');
        }
      }
    }
    // "¿Cuándo se usa sino?": una sola, pero preguntada por su uso.
    final porUna = _comoSeUsa.firstMatch(t);
    if (porUna != null) {
      final palabra = porUna[1]!.replaceFirst(RegExp(r'^la palabra '), '');
      for (final (palabras, explicacion) in _dudas) {
        if (palabras.contains(palabra)) {
          return RespuestaCharla(explicacion, intencion: 'saber:ortografia');
        }
      }
    }
    for (final (claves, explicacion) in _reglas) {
      if (claves.any((clave) => texto.contains(' $clave '))) {
        return RespuestaCharla(explicacion, intencion: 'saber:ortografia');
      }
    }
    final palabra = _comoSeEscribe.firstMatch(t);
    if (palabra != null) {
      final buscada = palabra[1]!.trim();
      final escrita = _palabras[buscada];
      if (escrita != null) {
        return RespuestaCharla(
          'Se escribe **$escrita**.',
          intencion: 'saber:ortografia',
        );
      }
    }
    return null;
  }

  static final _pideDiferencia = RegExp(
    r'\b(?:diferencia|diferencias|cuando se usa|cuando uso|cuando va|'
    r'cuando se escribe|como se escribe|como se usa|cual es la correcta|'
    r'cual se usa|cual va|vs|versus|se diferencian)\b',
  );

  static const _relleno = {'o', 'y', 'e', 'entre', 'la', 'el', 'de', 'con'};

  static final _comoSeUsa = RegExp(
    r'^(?:y )?(?:cuando se usa|cuando uso|cuando va|cuando se escribe|'
    r'como se escribe|como se usa|cuando se pone|como uso) (.+)$',
  );

  static final _comoSeEscribe = RegExp(
    r'^(?:y )?(?:como se escribe|como escribo|se escribe con tilde|lleva tilde|'
    r'tiene tilde|va con tilde|se escribe) (?:la palabra )?([a-z]+)$',
  );

  /// Grupos de palabras que se confunden y como distinguirlas. Se responde
  /// si la pregunta nombra al menos dos.
  static const _dudas = <(List<String>, String)>[
    (
      ['hay', 'ahi', 'ay'],
      '• **Hay**: del verbo haber. "Hay salteñas en la cafetería".\n'
          '• **Ahí**: un lugar. "Déjalo ahí".\n'
          '• **Ay**: una queja. "¡Ay, me olvidé del examen!"',
    ),
    (
      ['haber', 'a ver'],
      '• **Haber**: el verbo. "Va a haber examen", "debe haber un error".\n'
          '• **A ver**: de "vamos a ver". "A ver, explícame otra vez".\n\n'
          'Truco: si puedes cambiarlo por "veamos", es **a ver**.',
    ),
    (
      ['porque', 'por que'],
      '• **Por qué**: para preguntar. "¿Por qué no viniste?"\n'
          '• **Porque**: para responder o explicar. "No vine porque llovía".\n'
          '• **Porqué**: un sustantivo, va con "el". "No sé el porqué".\n'
          '• **Por que**: "por el que" o "por la cual". "Esa es la razón por '
          'que me fui" (casi no se usa).',
    ),
    (
      ['sino', 'si no'],
      '• **Sino**: para contraponer. "No es rojo, sino azul".\n'
          '• **Si no**: una condición. "Si no estudias, repruebas".',
    ),
    (
      ['echo', 'hecho'],
      '• **Hecho**, con h: del verbo hacer ("ya lo he hecho") o algo que '
          'pasó ("un hecho histórico").\n'
          '• **Echo**, sin h: del verbo echar. "Le echo sal".',
    ),
    (
      ['haya', 'halla', 'alla', 'aya'],
      '• **Haya**: del verbo haber. "Ojalá haya clase".\n'
          '• **Halla**: del verbo hallar (encontrar). "Se halla en el bloque '
          'A".\n'
          '• **Allá**: un lugar lejano. "Nos vemos allá".\n'
          '• **Aya**: una niñera (casi no se usa).',
    ),
    (
      ['vaya', 'valla', 'baya'],
      '• **Vaya**: del verbo ir ("que te vaya bien") o sorpresa ("¡vaya!").\n'
          '• **Valla**: una cerca o un cartel grande.\n'
          '• **Baya**: un fruto pequeño, como la uva.',
    ),
    (
      ['tuvo', 'tubo'],
      '• **Tuvo**: del verbo tener. "Tuvo examen".\n'
          '• **Tubo**: un cilindro hueco. "El tubo de ensayo".',
    ),
    (
      ['a', 'ha', 'ah'],
      '• **A**: preposición. "Voy a la U".\n'
          '• **Ha**: del verbo haber. "Ha llegado tarde".\n'
          '• **Ah**: exclamación. "¡Ah, ya entendí!"\n\n'
          'Truco: si puedes cambiarlo por "había", es **ha**.',
    ),
    (
      ['actitud', 'aptitud'],
      '• **Actitud**: tu disposición o comportamiento. "Buena actitud".\n'
          '• **Aptitud**: tu capacidad para algo. "Aptitud para los números".',
    ),
    (
      ['asia', 'hacia'],
      '• **Hacia**: dirección. "Voy hacia la cafetería".\n'
          '• **Asia**: el continente.',
    ),
    (
      ['ves', 'vez'],
      '• **Vez**: una ocasión. "Otra vez", "a veces".\n'
          '• **Ves**: del verbo ver. "¿Ves la pizarra?"',
    ),
    (
      ['cien', 'sien'],
      '• **Cien**: el número 100.\n'
          '• **Sien**: el costado de la cabeza.',
    ),
  ];

  /// Reglas que se piden por su nombre.
  static const _reglas = <(List<String>, String)>[
    (
      [
        'reglas de acentuacion',
        'reglas de las tildes',
        'cuando lleva tilde',
        'cuando se pone tilde',
        'cuando va tilde',
        'agudas graves y esdrujulas',
        'palabras agudas',
        'palabras graves',
        'palabras llanas',
        'palabras esdrujulas',
      ],
      'Depende de dónde cae la sílaba fuerte:\n'
          '• **Agudas** (fuerza en la última): llevan tilde si terminan en '
          'n, s o vocal. Canción, café, compás. Pero: reloj, papel.\n'
          '• **Graves o llanas** (en la penúltima): llevan tilde si NO '
          'terminan en n, s o vocal. Árbol, lápiz, fácil. Pero: examen, '
          'casa.\n'
          '• **Esdrújulas** (en la antepenúltima): siempre. Música, rápido, '
          'exámenes.\n'
          '• **Sobresdrújulas**: siempre. Dígaselo.',
    ),
    (
      [
        'tilde diacritica',
        'tu o tu',
        'el o el',
        'mi o mi',
        'te o te',
        'de o de',
        'se o se',
        'mas o mas',
      ],
      'La **tilde diacrítica** distingue palabras que se escriben igual:\n'
          '• **tú** (persona) / **tu** (tu libro)\n'
          '• **él** (persona) / **el** (el libro)\n'
          '• **sí** (afirmación) / **si** (condición)\n'
          '• **mí** (para mí) / **mi** (mi casa)\n'
          '• **té** (bebida) / **te** (te llamo)\n'
          '• **más** (cantidad) / **mas** (pero)\n'
          '• **sé** (saber) / **se** (se fue)\n'
          '• **dé** (dar) / **de** (de Santa Cruz)',
    ),
    (
      ['solo o solo', 'solo lleva tilde', 'solo con tilde', 'solo tiene tilde'],
      'Hoy se escribe **solo**, sin tilde, aunque signifique "solamente". '
          'La RAE recomienda no ponérsela desde 2010.',
    ),
    (
      [
        'b o v',
        'b y v',
        'cuando va b',
        'cuando se escribe con b',
        'cuando se escribe con v',
      ],
      'Algunas reglas que sirven:\n'
          '• Después de **m** va **b**: también, cambio.\n'
          '• Después de **n** va **v**: enviar, invierno.\n'
          '• El pasado en **-aba** va con **b**: cantaba, estudiaba.\n'
          '• Los verbos en **-bir** van con **b**: escribir, recibir (menos '
          'hervir, servir y vivir).',
    ),
    (
      [
        'cuando va mayuscula',
        'cuando se usa mayuscula',
        'cuando se usan mayusculas',
        'cuando lleva mayuscula',
        'reglas de mayusculas',
        'uso de mayusculas',
        'mayuscula o minuscula',
        'los meses van con mayuscula',
        'los dias van con mayuscula',
      ],
      'Va **mayúscula** al empezar un texto, después de un punto y en los '
          'nombres propios: personas, ciudades, instituciones (Santa Cruz, la '
          'UPSA). Los días, los meses y los idiomas van en minúscula: lunes, '
          'octubre, español.',
    ),
  ];

  /// Palabras que se preguntan seguido, ya escritas bien.
  static const _palabras = {
    'tambien': 'también',
    'ademas': 'además',
    'despues': 'después',
    'jamas': 'jamás',
    'quizas': 'quizás',
    'asi': 'así',
    'aqui': 'aquí',
    'ahi': 'ahí',
    'alla': 'allá',
    'examen': 'examen (sin tilde: es grave y termina en n)',
    'examenes': 'exámenes (con tilde: es esdrújula)',
    'imagen': 'imagen (sin tilde)',
    'imagenes': 'imágenes',
    'joven': 'joven (sin tilde)',
    'jovenes': 'jóvenes',
    'exito': 'éxito',
    'facil': 'fácil',
    'dificil': 'difícil',
    'rapido': 'rápido',
    'algebra': 'álgebra',
    'calculo': 'cálculo (el sustantivo). "Calculo", sin tilde, es "yo calculo"',
    'ojala': 'ojalá',
    'arbol': 'árbol',
    'lapiz': 'lápiz',
    'telefono': 'teléfono',
    'musica': 'música',
    'dia': 'día',
    'cancion': 'canción',
    'informacion': 'información',
    'educacion': 'educación',
    'raiz': 'raíz',
    'pais': 'país',
    'paises': 'países',
    'oceano': 'océano',
    'ultimo': 'último',
    'numero': 'número',
    'tecnologia': 'tecnología',
    'psicologia': 'psicología',
    'economia': 'economía',
    'quimica': 'química',
    'fisica': 'física',
    'matematicas': 'matemáticas',
    'hipotesis': 'hipótesis',
    'analisis': 'análisis',
    'tesis': 'tesis (sin tilde)',
    'carrera': 'carrera (sin tilde)',
    'universidad': 'universidad (sin tilde)',
    'hacer': 'hacer (con h)',
    'haber': 'haber (con h y b)',
    'hecho': 'hecho (con h, del verbo hacer)',
    'excelente': 'excelente',
    'exelente': 'excelente (con xc)',
    'excepcion': 'excepción',
    'adios': 'adiós',
    'proposito': 'propósito',
    'metodo': 'método',
    'credito': 'crédito',
    'pagina': 'página',
    'parentesis': 'paréntesis',
  };
}
