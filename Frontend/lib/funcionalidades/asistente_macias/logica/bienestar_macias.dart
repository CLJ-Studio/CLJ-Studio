import '../modelos/mensaje_macias.dart';
import 'cocina_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';

/// Consejos para la vida de estudiante: la cabeza (autoestima, ansiedad,
/// disciplina, decir que no), el estudio (apuntes, resúmenes, orales) y
/// primeros auxilios de todos los dias.
///
/// Son consejos generales, de los que se dan entre amigos con algo de
/// ciencia detras. Lo que pesa de verdad se manda a una persona y a un
/// profesional, y lo que es salud, a un medico.
abstract final class BienestarMacias {
  static const _materias = [
    OpcionMacias(id: 's:algebra', texto: 'Álgebra'),
    OpcionMacias(id: 's:calculo', texto: 'Cálculo integral'),
  ];

  /// El consejo que se pidio, o null.
  static RespuestaCharla? responder(String t, ContextoMacias c) {
    // "¿Cómo me calmo si el vendedor no responde?" es de la app.
    if (CocinaMacias.deLaApp.hasMatch(t)) return null;
    final texto = ' $t ';
    for (final (claves, consejo, intencion) in _consejos) {
      if (claves.any((clave) => CocinaMacias.coincide(clave, t, texto))) {
        return RespuestaCharla(
          consejo,
          intencion: intencion,
          opciones: intencion == 'consejo:matematicas' ? _materias : const [],
        );
      }
    }
    return null;
  }

  /// Todos los textos, para las pruebas.
  static Iterable<(List<String>, String)> get entradas => [
    for (final (claves, consejo, _) in _consejos)
      ([for (final clave in claves) clave.replaceFirst('=', '')], consejo),
  ];

  static const _consejos = <(List<String>, String, String)>[
    // --------------------------------------------------------------- cabeza
    (
      [
        'como subir mi autoestima',
        'como mejorar mi autoestima',
        'como subo mi autoestima',
        'como mejoro mi autoestima',
        'tengo baja autoestima',
        'tengo la autoestima baja',
        'autoestima baja',
        'baja autoestima',
        'como quererme',
        'como quererme mas',
        'como tener confianza',
        'como tener mas confianza',
        'como tener confianza en mi',
        'como ser mas seguro',
        'como ser mas segura',
        'soy inseguro',
        'soy insegura',
        'como dejar de ser inseguro',
        'como dejar de ser insegura',
      ],
      'Cosas que ayudan de verdad:\n'
          '• Háblate como le hablarías a un amigo: sin insultos.\n'
          '• Anota cada noche una cosa que hiciste bien, aunque sea chica.\n'
          '• Cumple pequeñas promesas contigo (dormir a tu hora, ir al gym): '
          'la confianza se construye cumpliendo.\n'
          '• Compárate con tu yo de ayer, no con el Instagram de otros.\n'
          '• Rodéate de gente que te sume.\n\n'
          'Y si pesa mucho, hablarlo con un psicólogo es de valientes, no de '
          'débiles.',
      'consejo:autoestima',
    ),
    (
      [
        'como calmar la ansiedad',
        'como controlar la ansiedad',
        'como bajar la ansiedad',
        'como manejar la ansiedad',
        'como quitar la ansiedad',
        '=como me calmo',
        '=como calmarme',
        '=ayudame a calmarme',
        '=necesito calmarme',
        'nervios antes del examen',
        'nervios del examen',
        'ansiedad por el examen',
        'ansiedad antes del examen',
        'tecnica de respiracion',
        'tecnicas de respiracion',
        'ejercicio de respiracion',
        'como respirar para calmarme',
        'me da un ataque de ansiedad',
      ],
      'Prueba esto ahora mismo:\n'
          '1. Inhala por la nariz contando hasta 4.\n'
          '2. Aguanta el aire contando hasta 4.\n'
          '3. Suéltalo lento por la boca contando hasta 6.\n'
          '4. Repite cinco veces.\n\n'
          'También ayuda nombrar 5 cosas que ves, 4 que puedes tocar y 3 que '
          'escuchas: te trae al presente. Si la ansiedad es seguida o te frena '
          'el día a día, habla con un profesional: tiene tratamiento y '
          'funciona.',
      'consejo:ansiedad',
    ),
    (
      [
        'dejar el celular',
        'adicto al celular',
        'adicta al celular',
        'adiccion al celular',
        'paso mucho tiempo en el celular',
        'paso todo el dia en el celular',
        'no puedo dejar el celular',
        'dejar las redes',
        'dejar las redes sociales',
        'dejar tiktok',
        'mucho tiempo en tiktok',
        'paso mucho tiempo en tiktok',
        'como usar menos el celular',
        'usar menos el celular',
      ],
      'Trucos que funcionan:\n'
          '• Mientras estudias, el celular en otro cuarto (boca abajo no '
          'alcanza).\n'
          '• Apaga las notificaciones de todo menos lo importante.\n'
          '• Pon la pantalla en blanco y negro: se vuelve aburrida, y eso es '
          'lo que quieres.\n'
          '• Ponle límite de tiempo a las apps que más te comen.\n'
          '• Reemplaza, no solo quites: un libro, salir a caminar, el gym.',
      'consejo:celular',
    ),
    (
      [
        'como ser productivo',
        'como ser productiva',
        'como ser mas productivo',
        'como ser mas productiva',
        'como ser disciplinado',
        'como ser disciplinada',
        'como ser mas disciplinado',
        'como ser mas disciplinada',
        'como tener disciplina',
        'no tengo disciplina',
        'falta de disciplina',
        'como ser constante',
        'no soy constante',
        'como armar una rutina',
        'como hacer una rutina',
        'como tener una rutina',
        'rutina de estudio',
        'como crear habitos',
        'como crear un habito',
        'como formar habitos',
      ],
      'La disciplina se entrena:\n'
          '• Empieza ridículamente chico: 10 minutos diarios valen más que 5 '
          'horas un domingo.\n'
          '• Mismo lugar y misma hora: el cerebro se acostumbra.\n'
          '• Regla de los 2 minutos: si cuesta empezar, comprométete solo a 2 '
          'minutos. Casi siempre sigues.\n'
          '• No esperes la motivación: aparece después de empezar, no antes.\n'
          '• Marca en un calendario cada día que cumples, y no rompas la '
          'cadena.',
      'consejo:disciplina',
    ),
    (
      [
        '=como priorizar',
        '=como priorizo',
        'priorizar tareas',
        'matriz de eisenhower',
        'tengo muchas cosas que hacer',
        'tengo demasiadas cosas',
        'tengo mil cosas que hacer',
      ],
      'Ordénalo con la **matriz de Eisenhower**:\n'
          '• **Urgente e importante**: hazlo ya.\n'
          '• **Importante, no urgente**: ponle fecha en tu agenda.\n'
          '• **Urgente, no importante**: hazlo rápido o pide ayuda.\n'
          '• **Ni urgente ni importante**: bórralo de la lista.\n\n'
          'Y después, de a una: hacer varias cosas a la vez es hacerlas todas '
          'peor.',
      'consejo:priorizar',
    ),
    (
      [
        'como decir que no',
        'no se decir que no',
        'no puedo decir que no',
        'me cuesta decir que no',
        '=como poner limites',
        '=poner limites',
        'poner limites a mi familia',
        'poner limites a mis amigos',
        'poner limites en una relacion',
        'como digo que no',
      ],
      'Decir que no es cuidarte, no ser malo:\n'
          '• Corto y amable: "Esta vez no puedo, gracias por pensar en mí".\n'
          '• No hace falta justificarte de más.\n'
          '• Si dudas, gana tiempo: "Déjame ver y te aviso".\n'
          '• Ofrece otra cosa solo si de verdad quieres.\n\n'
          'La gente que te respeta lo entiende.',
      'consejo:limites',
    ),
    (
      [
        'como superar a mi ex',
        'como olvidar a mi ex',
        'no puedo olvidar a mi ex',
        'no supero a mi ex',
        'extrano a mi ex',
        'como superar una ruptura',
        'como superar a alguien',
        'como olvidar a alguien',
        'como superar una relacion',
        'deberia volver con mi ex',
        'quiero volver con mi ex',
        'le hablo a mi ex',
        'le escribo a mi ex',
      ],
      'Lo que ayuda (de verdad):\n'
          '• Contacto cero por un tiempo: dejar de mirar sus redes también '
          'cuenta.\n'
          '• Permítete estar triste; no tienes que estar bien en una semana.\n'
          '• Llena el tiempo: amigos, deporte, algo nuevo que siempre '
          'quisiste hacer.\n'
          '• Escribe lo que no funcionaba: la nostalgia idealiza.\n\n'
          'Y si la duda es volver: pregúntate si cambió lo que hizo que '
          'terminaran. Si no cambió nada, va a terminar igual.',
      'consejo:ex',
    ),
    (
      [
        'como pedir perdon',
        'como pido perdon',
        'como pedir disculpas',
        'como pido disculpas',
        'como me disculpo',
        'meti la pata',
        '=como arreglo las cosas',
        'como arreglo las cosas con',
      ],
      'Una disculpa que sirve tiene tres partes:\n'
          '1. Reconoce lo que hiciste, sin "pero": "Me equivoqué al...".\n'
          '2. Reconoce cómo le afectó: "Entiendo que te dolió porque...".\n'
          '3. Di qué vas a hacer distinto.\n\n'
          'Después, dale su tiempo: perdonar no es instantáneo.',
      'consejo:perdon',
    ),
    (
      [
        'como dormir mejor',
        'como dormir bien',
        'como me duermo',
        'como dormir rapido',
        'como quedarme dormido',
        'como quedarme dormida',
        'como conciliar el sueno',
        'duermo mal',
        'tips para dormir',
        'consejos para dormir',
        'como mejorar mi sueno',
      ],
      'Para dormir mejor:\n'
          '• Misma hora para acostarte y levantarte, también el finde.\n'
          '• Pantallas fuera media hora antes (o al menos con el brillo al '
          'mínimo).\n'
          '• Nada de café después de las 4 de la tarde.\n'
          '• Cuarto oscuro, fresco y en silencio.\n'
          '• Si a los 20 minutos no te duermes, levántate, haz algo tranquilo '
          'y vuelve cuando tengas sueño.',
      'consejo:dormir',
    ),
    (
      [
        'como tomar una decision',
        'como tomo una decision',
        '=como decido',
        'no se que decidir',
        '=no puedo decidir',
        'no puedo decidirme',
        'tengo que tomar una decision',
        'estoy indeciso',
        'estoy indecisa',
        'soy indeciso',
        'soy indecisa',
      ],
      'Para decidir sin volverte loco:\n'
          '• Escribe pros y contras, y dale peso a cada uno: no todos valen lo '
          'mismo.\n'
          '• Pregúntate qué elegirías si no tuvieras miedo.\n'
          '• Regla 10-10-10: ¿cómo te vas a sentir con esto en 10 minutos, 10 '
          'meses y 10 años?\n'
          '• Si las dos opciones son buenas, no hay forma de perder: elige y '
          'sigue.\n\n'
          'Y si es algo chico, puedo lanzar una moneda por ti.',
      'consejo:decidir',
    ),
    (
      [
        'como controlar mi enojo',
        'como controlar el enojo',
        'como controlar la ira',
        'como controlar mi ira',
        'me enojo facil',
        'me enojo muy facil',
        'como no enojarme',
        'tengo mal genio',
        'tengo mal caracter',
      ],
      'Cuando sube el enojo:\n'
          '• Pausa antes de responder: respira hondo y cuenta hasta diez '
          '(funciona más de lo que parece).\n'
          '• Si puedes, sal un rato del lugar.\n'
          '• Di lo que sientes en primera persona: "me molestó que..." en vez '
          'de "tú siempre...".\n'
          '• El ejercicio ayuda a soltar la tensión acumulada.',
      'consejo:enojo',
    ),
    (
      [
        'soy celoso',
        'soy celosa',
        'soy muy celoso',
        'soy muy celosa',
        'como dejar de ser celoso',
        'como dejar de ser celosa',
        'como controlar los celos',
        'tengo celos',
        'siento celos',
      ],
      'Los celos suelen hablar más de inseguridad que de la otra persona. '
          'Ayuda hablarlo con calma (sin revisar su celular), trabajar tu '
          'confianza y preguntarte si hay hechos o solo miedos. Si los celos '
          'controlan (revisar, prohibir, alejar de los amigos), eso ya es una '
          'red flag.',
      'consejo:celos',
    ),
    (
      [
        'que hago con mi vida',
        'no se que hacer con mi vida',
        'no se que quiero hacer con mi vida',
        'no se que quiero en la vida',
        'no tengo proposito',
        'cual es mi proposito',
        'como encontrar mi proposito',
        'como encontrar mi pasion',
        'no se cual es mi pasion',
      ],
      'Pregunta grande, y está bien no tener la respuesta todavía (casi nadie '
          'la tiene, aunque lo parezca). Algo que ayuda: en vez de buscar "la '
          'pasión de tu vida", fíjate en qué cosas te hacen perder la noción '
          'del tiempo, y prueba cosas chicas en esa dirección. El camino se '
          'aclara caminando, no pensando desde la cama.',
      'consejo:proposito',
    ),
    // --------------------------------------------------------------- estudio
    (
      [
        'como tomar apuntes',
        'como tomo apuntes',
        '=como hago apuntes',
        '=como hacer apuntes',
        'como hacer buenos apuntes',
        'metodo cornell',
        'apuntes cornell',
      ],
      'El **método Cornell**: divide la hoja en tres. A la derecha, los '
          'apuntes de clase. A la izquierda, una columna angosta con preguntas '
          'y palabras clave. Abajo, un resumen de dos o tres líneas. Para '
          'repasar, tapas la derecha y te respondes las preguntas de la '
          'izquierda.',
      'consejo:estudio',
    ),
    (
      [
        'como hacer un mapa mental',
        'como hago un mapa mental',
        'como hacer un mapa conceptual',
        'como hago un mapa conceptual',
        'que es un mapa mental',
        'que es un mapa conceptual',
        'diferencia entre mapa mental y mapa conceptual',
        'mapa mental',
        'mapas mentales',
        'mapa conceptual',
        'mapas conceptuales',
      ],
      '**Mapa mental**: el tema al centro, ramas con las ideas principales y '
          'ramitas con detalles. Pocas palabras, colores y dibujitos: así se '
          'recuerda más.\n\n'
          '**Mapa conceptual**: más ordenado, de arriba abajo, y une los '
          'conceptos con palabras de enlace ("produce", "se divide en", '
          '"por ejemplo").',
      'consejo:estudio',
    ),
    (
      [
        'como hacer un resumen',
        'como hago un resumen',
        'como resumir',
        'como resumo',
        'como hacer una sintesis',
      ],
      'Para resumir bien:\n'
          '1. Lee todo una vez, sin subrayar.\n'
          '2. En la segunda lectura, marca solo la idea principal de cada '
          'párrafo.\n'
          '3. Escríbelo con tus palabras, sin copiar frases enteras.\n'
          '4. Que quede en una cuarta parte del original, más o menos.',
      'consejo:estudio',
    ),
    (
      [
        'examen oral',
        'un oral',
        'como prepararme para un oral',
        'como me preparo para un oral',
        'leccion oral',
      ],
      'Para un oral:\n'
          '• Practica en voz alta, explicándole a alguien (o al espejo).\n'
          '• Arma un esquema de cada tema: idea principal, puntos clave y un '
          'ejemplo.\n'
          '• Si te quedas en blanco, empieza por lo que sí sabes y conecta '
          'desde ahí.\n'
          '• Si no entendiste la pregunta, pide que te la repitan: está '
          'permitido.',
      'consejo:estudio',
    ),
    (
      [
        'examen de opcion multiple',
        'examen tipo test',
        'opcion multiple',
        'examen de marcar',
        'preguntas de opcion multiple',
      ],
      'En un examen de opción múltiple:\n'
          '• Lee la pregunta entera antes de mirar las opciones.\n'
          '• Descarta primero las que sabes que están mal.\n'
          '• Ojo con "siempre" y "nunca": suelen ser falsas.\n'
          '• Si no restan puntos, no dejes ninguna en blanco.\n'
          '• Cambia tu primera respuesta solo si encontraste un motivo, no por '
          'nervios.',
      'consejo:estudio',
    ),
    (
      [
        'como leer rapido',
        'como leer mas rapido',
        'leer mas rapido',
        'lectura rapida',
        'como leo mas rapido',
      ],
      'Lo que sí funciona: no volver atrás con la vista a cada rato, guiarte '
          'con el dedo o un lápiz, y mirar primero títulos y conclusiones para '
          'saber qué buscas. Lo de leer mil palabras por minuto entendiendo '
          'todo es más marketing que ciencia: para estudiar, mejor entender '
          'que correr.',
      'consejo:estudio',
    ),
    (
      [
        'como memorizar formulas',
        'memorizar formulas',
        'no me acuerdo las formulas',
        'no me acuerdo de las formulas',
        'como me aprendo las formulas',
      ],
      'Para las fórmulas: entiende de dónde salen (se recuerda lo que tiene '
          'sentido), úsalas en ejercicios en vez de solo leerlas, y arma una '
          'hoja con todas para repasar unos minutos cada día. Escribirlas de '
          'memoria y después comprobar es lo que más las fija.',
      'consejo:estudio',
    ),
    (
      [
        'como aprender ingles',
        'como aprendo ingles',
        'quiero aprender ingles',
        'como mejorar mi ingles',
        'como mejoro mi ingles',
        'aprender ingles rapido',
        'como aprender un idioma',
        'como aprendo un idioma',
      ],
      'Para un idioma:\n'
          '• Un poco todos los días gana a mucho una vez por semana.\n'
          '• Series y videos en ese idioma, con subtítulos en ese idioma.\n'
          '• Vocabulario con repetición espaciada (apps como Anki o Duolingo).\n'
          '• Habla aunque te equivoques: con alguien, con un tutor o '
          'grabándote.\n'
          '• Cambia el idioma del celular: aprendes sin darte cuenta.',
      'consejo:estudio',
    ),
    (
      [
        'como estudiar matematicas',
        'como estudio matematicas',
        'como aprender matematicas',
        'soy malo en matematicas',
        'soy mala en matematicas',
        'soy malo para las matematicas',
        'soy mala para las matematicas',
        'no entiendo nada de matematicas',
      ],
      'Las matemáticas se aprenden haciendo, no leyendo:\n'
          '• Muchos ejercicios, de fáciles a difíciles.\n'
          '• Cuando te trabes, mira un solo paso de la solución y sigue tú.\n'
          '• Repite al día siguiente los que te salieron mal.\n'
          '• Pregunta pronto: son una escalera, y un escalón flojo arrastra '
          'todo lo demás.\n\n'
          'Y aquí te ayudo a practicar:',
      'consejo:matematicas',
    ),
    (
      [
        'como preparo mi examen',
        'como preparo el examen',
        'como me preparo para el examen',
        'como me preparo para un examen',
        'como prepararme para un examen',
        'como prepararme para el examen',
        'como preparo un examen',
      ],
      'Para llegar bien al examen:\n'
          '1. Junta lo que entra: temas, exámenes pasados y lo que el profe '
          'repitió.\n'
          '2. Repasa en sesiones cortas varios días antes, no todo la última '
          'noche.\n'
          '3. Haz ejercicios sin mirar la solución, como si fuera el examen.\n'
          '4. Explícale un tema a alguien: donde te trabas, ahí falta.\n'
          '5. La noche anterior, duerme. Lo que no fijaste durmiendo, se '
          'borra.\n\n'
          'Si me dices cuándo es (**tengo examen de cálculo el viernes**), te '
          'lo recuerdo.',
      'consejo:estudio',
    ),
    (
      [
        'que lleva un cv',
        'que poner en mi cv',
        'que pongo en mi cv',
        'que lleva un curriculum',
        'que pongo en mi curriculum',
        'cv sin experiencia',
        'curriculum sin experiencia',
      ],
      'Un CV de estudiante, en una hoja:\n'
          '1. **Datos de contacto**.\n'
          '2. **Perfil**: dos o tres líneas sobre qué estudias y qué buscas.\n'
          '3. **Formación**: tu carrera y el semestre.\n'
          '4. **Experiencia**: trabajos, pasantías, voluntariados y proyectos '
          'de la U (sí cuentan, también sin experiencia "formal").\n'
          '5. **Habilidades**: programas, idiomas, certificados.\n\n'
          'Si vendes en U market, eso también suma: es emprendimiento.',
      'consejo:cv',
    ),
    // --------------------------------------------------------------- salud
    (
      [
        'me queme con',
        'me queme la mano',
        'me queme el dedo',
        'me queme cocinando',
        'me queme con aceite',
        'que hago si me quemo',
        'como curar una quemadura',
        'tengo una quemadura',
        'me cayo aceite',
      ],
      'Pon la quemadura bajo el agua fría del grifo (no helada) unos 20 '
          'minutos. Nada de hielo, pasta dental, mantequilla ni aceite. Tápala '
          'con una gasa limpia, sin apretar.\n\n'
          'Si es grande, tiene ampollas, es en la cara, las manos o una '
          'articulación, o duele muchísimo: al médico.',
      'consejo:salud',
    ),
    (
      [
        'me corte el dedo',
        'me corte la mano',
        'me corte con un cuchillo',
        'me corte con el cuchillo',
        'me corte con un vidrio',
        'me corte cocinando',
        'me hice un corte',
        'tengo una cortada',
        'como curar un corte',
        'como curar una herida',
        'como curo una herida',
      ],
      'Lava el corte con agua y jabón, presiónalo con una gasa o un trapo '
          'limpio unos minutos hasta que deje de sangrar, y tápalo con una '
          'curita. Si es profundo, no para de sangrar después de 10 minutos '
          'apretando o fue con algo oxidado: al médico.\n\n'
          'Y si no fue un accidente y te estás haciendo daño, háblalo con '
          'alguien de confianza: no tienes que pasarlo solo.',
      'consejo:salud',
    ),
    (
      [
        'tengo gripe',
        'estoy con gripe',
        'estoy resfriado',
        'estoy resfriada',
        'tengo resfrio',
        'como curar la gripe',
        'como se cura la gripe',
        'como quitar la gripe',
      ],
      'Para la gripe: descanso, mucho líquido (sopas y té calentito cuentan) '
          'y taparte la boca al toser. Si tienes fiebre alta varios días, te '
          'falta el aire o empeoras, al médico. Y avísale al profe: con '
          'certificado, muchos te dejan recuperar.',
      'consejo:salud',
    ),
    (
      [
        'tengo chaqui',
        'estoy con chaqui',
        'tengo resaca',
        'estoy con resaca',
        'como quitar el chaqui',
        'como quitar la resaca',
        'como se quita el chaqui',
        'remedio para el chaqui',
      ],
      'Agua, mucha agua, algo liviano de comer y dormir. La tradición paceña '
          'dice fricasé; la ciencia dice hidratación. Y para la próxima: un '
          'vaso de agua entre trago y trago.',
      'consejo:salud',
    ),
  ];
}
