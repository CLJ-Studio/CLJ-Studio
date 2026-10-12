import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'lenguaje_macias.dart';

/// Una entrada: como se la nombra (ya normalizado) y lo que dice MacIAs.
typedef _Entrada = (List<String>, String);

/// Filosofia, psicologia, historia, arte y algo mas de ciencia: lo que se
/// pregunta en la U fuera de las materias de numeros.
///
/// Escrito para que se entienda a la primera, con un ejemplo cuando ayuda.
/// Lo de salud mental es informativo: cuando algo pesa de verdad, se
/// recomienda hablar con alguien y con un profesional.
abstract final class HumanidadesMacias {
  /// "Una frase célebre", "frase de Séneca", "un refrán", "¿qué significa
  /// camarón que se duerme...?". Null si no es eso.
  static RespuestaCharla? responder(String t, ContextoMacias c) {
    final deQuien = _fraseDe.firstMatch(t);
    if (deQuien != null) {
      final autor = (deQuien[1] ?? deQuien[2])!.trim().replaceFirst(
        RegExp(r'^(?:el|la) '),
        '',
      );
      final suyas = [
        for (final (autores, frase, quien) in _frases)
          if (autores.contains(autor)) (frase, quien),
      ];
      if (suyas.isNotEmpty) {
        final (frase, quien) = suyas[c.sorteo % suyas.length];
        return RespuestaCharla('"$frase"\n— $quien', intencion: 'saber:frase');
      }
    }
    if (_pideFrase.hasMatch(t)) {
      final disponibles = [
        for (final f in _frases)
          if (!c.recientes.any((dicho) => dicho.contains(f.$2))) f,
      ];
      final lista = disponibles.isEmpty ? _frases : disponibles;
      final (_, frase, quien) = lista[c.sorteo % lista.length];
      return RespuestaCharla('"$frase"\n— $quien', intencion: 'saber:frase');
    }

    final significa = _queSignifica.firstMatch(t);
    if (significa != null) {
      final buscado = significa[1]!.trim();
      for (final (refran, sentido) in _refranes) {
        if (buscado.length < 10) break;
        final normal = LenguajeMacias.normalizar(refran);
        if (normal.startsWith(buscado) || buscado.startsWith(normal)) {
          return RespuestaCharla(
            '"$refran": $sentido',
            intencion: 'saber:refran',
          );
        }
      }
    }
    if (_pideRefran.hasMatch(t)) {
      final disponibles = [
        for (final r in _refranes)
          if (!c.recientes.any((dicho) => dicho.contains(r.$1))) r,
      ];
      final lista = disponibles.isEmpty ? _refranes : disponibles;
      final (refran, sentido) = lista[c.sorteo % lista.length];
      return RespuestaCharla(
        '"$refran"\nQuiere decir que $sentido',
        intencion: 'saber:refran',
      );
    }

    if (_pideCuento.hasMatch(t)) {
      final disponibles = [
        for (final f in _fabulas)
          if (!c.recientes.any((dicho) => dicho.contains(f))) f,
      ];
      final lista = disponibles.isEmpty ? _fabulas : disponibles;
      return RespuestaCharla(
        lista[c.sorteo % lista.length],
        intencion: 'charla:cuento',
      );
    }
    return null;
  }

  static final _fraseDe = RegExp(
    r'^(?:dime |dame |una |alguna )?(?:frase|frases|cita|citas) (?:celebre |famosa )?'
    r'(?:de|del) (.+)$|^que (?:dijo|decia) (.+)$',
  );
  static final _pideFrase = RegExp(
    r'^(?:dime |dame |cuentame |comparteme |sabes |tienes )?'
    r'(?:una |otra |alguna |algunas |unas )?(?:frase|frases|cita|citas)'
    r'(?: celebre| celebres| famosa| famosas| del dia| inspiradora| bonita| '
    r'sabia| de un filosofo| filosofica| para pensar)?$',
  );
  static final _pideRefran = RegExp(
    r'^(?:dime |dame |cuentame |sabes |tienes |conoces )?'
    r'(?:un |otro |algun |unos )?(?:refran|refranes|dicho|dichos|proverbio)'
    r'(?: popular| populares| boliviano| bolivianos| sabio)?$',
  );
  static final _queSignifica = RegExp(
    r'^(?:que (?:significa|quiere decir)|significado de) (?:el refran |el dicho )?'
    r'(.+)$',
  );
  static final _pideCuento = RegExp(
    r'^(?:cuentame |dime |contame |relatame )?(?:un |una |otro |otra )?'
    r'(?:cuento|fabula|historia|historia corta|cuento corto)'
    r'(?: corto| corta| con moraleja| para dormir| bonito| bonita)?$',
  );

  /// Todo lo que se busca por nombre. Para las pruebas.
  static Iterable<(List<String>, String)> get entradas => [
    ...conceptos,
    ...personas,
  ];

  // ============================================================= conceptos
  static const conceptos = <_Entrada>[
    // ------------------------------------------------------------ filosofia
    (
      ['filosofia'],
      'La **filosofía** es pensar a fondo las preguntas grandes: qué es la verdad, qué podemos conocer, cómo deberíamos vivir. La palabra viene del griego y significa "amor a la sabiduría".',
    ),
    (
      ['etica', 'moral', 'etica y moral'],
      'La **moral** son las normas sobre lo que está bien y mal que una persona o una sociedad sigue en la práctica. La **ética** es la reflexión sobre esas normas: por qué algo estaría bien o mal.',
    ),
    (
      ['metafisica'],
      'La **metafísica** estudia lo más básico de la realidad: qué existe, qué es el tiempo, si hay alma, qué es una causa. Lo que está "más allá de la física".',
    ),
    (
      ['epistemologia'],
      'La **epistemología** estudia el conocimiento: qué significa saber algo, cómo se distingue una creencia verdadera de una opinión y qué hace confiable a la ciencia.',
    ),
    (
      ['logica'],
      'La **lógica** estudia cómo razonar bien: qué conclusiones se siguen de qué premisas. Ejemplo clásico: todos los humanos son mortales; Sócrates es humano; por lo tanto, Sócrates es mortal.',
    ),
    (
      ['estoicismo', 'estoico', 'estoicos'],
      'El **estoicismo** es una filosofía griega y romana (Zenón, Séneca, Epicteto, Marco Aurelio). Su idea central: separa lo que depende de ti (tus juicios y tus actos) de lo que no, y pon tu energía solo en lo primero. Muy útil la noche antes de un examen.',
    ),
    (
      ['existencialismo', 'existencialista'],
      'El **existencialismo** (Kierkegaard, Sartre, Simone de Beauvoir) dice que primero existimos y después nos definimos con lo que hacemos: no hay un manual de quién eres, lo construyes con tus elecciones. Libertad total, y responsabilidad total.',
    ),
    (
      ['nihilismo', 'nihilista'],
      'El **nihilismo** sostiene que la vida no trae un sentido ni unos valores dados de antemano. Nietzsche lo vio como una crisis de su época y propuso salir de ahí creando valores propios.',
    ),
    (
      ['absurdo', 'el absurdo'],
      'Para Albert Camus, el **absurdo** es el choque entre nuestra necesidad de sentido y un universo que no responde. Su salida no es rendirse sino vivir a fondo, con rebeldía: "hay que imaginar a Sísifo feliz".',
    ),
    (
      ['utilitarismo'],
      'El **utilitarismo** (Jeremy Bentham, John Stuart Mill) dice que lo correcto es lo que produce la mayor felicidad para el mayor número de personas. Una acción se juzga por sus consecuencias.',
    ),
    (
      ['imperativo categorico'],
      'El **imperativo categórico** de Kant dice: actúa solo según una regla que podrías querer que siguieran todos. Si un mundo donde todos mienten no funciona, no mientas. Y otra versión: trata a las personas siempre como fines, nunca solo como medios.',
    ),
    (
      ['cogito', 'cogito ergo sum', 'pienso luego existo'],
      '"**Pienso, luego existo**" (cogito, ergo sum) es de Descartes. Dudando de todo, encontró algo de lo que no podía dudar: si estoy dudando, estoy pensando, y si pienso, existo.',
    ),
    (
      [
        'mito de la caverna',
        'alegoria de la caverna',
        'la caverna de platon',
        'caverna de platon',
      ],
      'En el **mito de la caverna**, Platón imagina prisioneros que desde siempre solo ven sombras en una pared y creen que eso es la realidad. Uno se libera, sale, ve el sol y entiende. Es una imagen de la educación: pasar de las apariencias a la verdad, aunque al principio encandile.',
    ),
    (
      ['dilema del tranvia', 'problema del tranvia'],
      'El **dilema del tranvía**: un tranvía sin frenos va a atropellar a cinco personas; si mueves una palanca, se desvía y mata a una. ¿La mueves? Sirve para discutir si solo importan las consecuencias o también lo que tú haces con tus propias manos.',
    ),
    (
      ['libre albedrio'],
      'El **libre albedrío** es la idea de que elegimos de verdad, y no que todo está decidido por causas anteriores (los genes, la crianza, la química del cerebro). Es uno de los debates más viejos y más abiertos de la filosofía.',
    ),
    (
      ['determinismo'],
      'El **determinismo** dice que todo lo que pasa, incluidas nuestras decisiones, está fijado por causas anteriores. Choca con el libre albedrío, aunque hay filósofos (los compatibilistas) que creen que pueden convivir.',
    ),
    (
      ['empirismo', 'empirista'],
      'El **empirismo** (Locke, Hume) sostiene que todo conocimiento viene de la experiencia, de los sentidos. Su rival histórico es el racionalismo.',
    ),
    (
      ['racionalismo', 'racionalista'],
      'El **racionalismo** (Descartes, Spinoza, Leibniz) sostiene que la razón, por sí sola, puede llegar a verdades seguras, como pasa en las matemáticas.',
    ),
    (
      ['hedonismo'],
      'El **hedonismo** pone el placer como el bien principal. Su versión más famosa, la de Epicuro, buscaba en realidad la tranquilidad: placeres simples, buenos amigos y ningún exceso que después duela.',
    ),
    (
      ['relativismo'],
      'El **relativismo** dice que la verdad o lo correcto dependen de cada cultura o persona. La objeción clásica: si todo es relativo, esa misma frase también lo sería.',
    ),
    (
      ['navaja de ockham', 'navaja de occam'],
      'La **navaja de Ockham**: entre dos explicaciones que explican lo mismo, quédate con la más simple. No dice que lo simple sea siempre verdad, sino que no conviene inventar más de lo necesario.',
    ),
    (
      ['barco de teseo', 'paradoja de teseo'],
      'El **barco de Teseo**: si a un barco le cambias todas las tablas, una por una, ¿sigue siendo el mismo barco? Es una pregunta sobre la identidad, y también vale para ti: tus células se renuevan y sigues siendo tú.',
    ),
    (
      ['paradoja', 'paradojas'],
      'Una **paradoja** es un razonamiento que parece correcto pero termina en algo contradictorio. Ejemplo: "esta frase es falsa". Si es verdad, es falsa; si es falsa, es verdad.',
    ),
    (
      ['falacia', 'falacias'],
      'Una **falacia** es un razonamiento que parece válido pero no lo es. Las más comunes: atacar a la persona en vez del argumento (ad hominem), deformar lo que dijo el otro (hombre de paja), "si todos lo hacen debe estar bien" (ad populum) y "si permites esto, terminaremos en lo peor" (pendiente resbaladiza).',
    ),
    (
      ['ad hominem', 'falacia ad hominem'],
      'La falacia **ad hominem** ataca a la persona en vez de a su argumento: "no le hagas caso, si ni aprobó cálculo". Cómo sea alguien no hace falso lo que dice.',
    ),
    (
      ['hombre de paja', 'falacia del hombre de paja'],
      'La falacia del **hombre de paja** deforma lo que dijo el otro para atacar una versión más fácil. Decir "quiero estudiar menos horas" no es decir "quiero no estudiar".',
    ),
    (
      ['pendiente resbaladiza'],
      'La **pendiente resbaladiza** es una falacia: "si permites esto, después vendrá aquello, y al final será un desastre", sin mostrar por qué un paso llevaría al otro.',
    ),
    (
      ['dialectica'],
      'La **dialéctica** es avanzar en el conocimiento a través de la contradicción: una idea, su opuesta y algo nuevo que surge de las dos. Viene de los diálogos de Sócrates y la desarrolló mucho Hegel.',
    ),
    (
      ['mayeutica'],
      'La **mayéutica** era el método de Sócrates: en vez de dar respuestas, hacía preguntas hasta que el otro "daba a luz" la verdad por sí mismo. Su madre era partera, de ahí el nombre.',
    ),
    (
      ['eudaimonia', 'felicidad segun aristoteles'],
      'Para Aristóteles, la **eudaimonía** (felicidad o vida plena) no es un placer pasajero, sino vivir desarrollando lo mejor de uno con virtud, a lo largo de toda la vida.',
    ),
    (
      ['virtud', 'virtudes'],
      'Para Aristóteles, la **virtud** es el punto medio entre dos excesos: la valentía está entre la cobardía y la temeridad; la generosidad, entre la tacañería y el derroche.',
    ),
    (
      ['contrato social'],
      'El **contrato social** (Hobbes, Locke, Rousseau) es la idea de que las personas aceptan ciertas reglas y un gobierno a cambio de seguridad y convivencia.',
    ),
    (
      ['tabula rasa'],
      'La **tabula rasa** ("tablilla en blanco") es la idea de John Locke de que nacemos sin ideas, y que todo lo que sabemos lo vamos escribiendo con la experiencia.',
    ),
    (
      ['superhombre', 'ubermensch'],
      'El **superhombre** de Nietzsche no tiene superpoderes: es quien crea sus propios valores en vez de seguir los heredados, y le dice "sí" a la vida con todo lo que trae.',
    ),
    (
      ['eterno retorno'],
      'El **eterno retorno** de Nietzsche es un experimento mental: ¿vivirías tu vida exactamente igual, una y otra vez, para siempre? Si la respuesta es sí, la estás viviendo como quieres.',
    ),
    (
      ['carpe diem'],
      '**Carpe diem** ("aprovecha el día") viene del poeta romano Horacio: disfruta el presente sin confiar demasiado en el mañana.',
    ),
    (
      ['memento mori'],
      '**Memento mori** ("recuerda que vas a morir") era un recordatorio de los estoicos: no para deprimirse, sino para no gastar la vida en lo que no importa.',
    ),
    (
      ['amor fati'],
      '**Amor fati** ("amor al destino") es la actitud de aceptar, e incluso abrazar, todo lo que pasa, lo bueno y lo malo. La usaron los estoicos y la retomó Nietzsche.',
    ),
    (
      ['budismo'],
      'El **budismo** nace con Siddhartha Gautama, el Buda, hace unos 2500 años. Enseña que el sufrimiento viene del apego y que se puede superar con un camino de equilibrio, ética y meditación.',
    ),
    (
      ['zen', 'budismo zen'],
      'El **zen** es una escuela del budismo que busca despertar con la meditación y la atención total al momento presente, más que con teorías.',
    ),
    (
      ['taoismo', 'yin y yang', 'tao'],
      'El **taoísmo** (Lao Tsé) busca vivir en armonía con el Tao, el orden natural de las cosas. El **yin y el yang** son dos fuerzas opuestas que se complementan: la noche y el día, el frío y el calor.',
    ),
    // ---------------------------------------------------------- psicologia
    (
      ['psicologia'],
      'La **psicología** estudia la mente y el comportamiento: cómo pensamos, sentimos, aprendemos y nos relacionamos. Una cosa es la psicología como ciencia y otra la terapia, que es una de sus aplicaciones.',
    ),
    (
      ['autoestima'],
      'La **autoestima** es cómo te valoras a ti mismo. No es creerse perfecto: es tratarte con respeto, reconocer tus logros y aceptar tus errores sin destruirte por ellos.',
    ),
    (
      ['depresion'],
      'La **depresión** es un trastorno de salud mental, no una tristeza pasajera: dura semanas, quita las ganas de casi todo y afecta el sueño, el apetito y la energía. Tiene tratamiento. Si te reconoces ahí, habla con alguien de confianza y busca a un profesional.',
    ),
    (
      ['sindrome del impostor', 'sindrome de impostor'],
      'El **síndrome del impostor** es sentir que no mereces tus logros y que en cualquier momento "te van a descubrir". Es muy común en estudiantes buenos: casi siempre, el que lo siente sí se lo ganó.',
    ),
    (
      ['burnout', 'sindrome de burnout', 'sindrome del quemado'],
      'El **burnout** es el agotamiento por exigencia sostenida: un cansancio que no se va con dormir, desmotivación y sensación de no rendir. Se previene con descansos de verdad, límites claros y no cargar todo a la vez.',
    ),
    (
      ['sesgo cognitivo', 'sesgos cognitivos', 'sesgo', 'sesgos'],
      'Un **sesgo cognitivo** es un atajo mental que nos hace equivocarnos de forma predecible. El más famoso es el sesgo de confirmación: fijarnos solo en lo que confirma lo que ya creemos.',
    ),
    (
      ['sesgo de confirmacion'],
      'El **sesgo de confirmación** es buscar y recordar solo lo que confirma lo que ya pensamos, e ignorar lo que lo contradice. El antídoto: buscar a propósito argumentos en contra.',
    ),
    (
      ['efecto dunning kruger', 'dunning kruger'],
      'El **efecto Dunning-Kruger**: quien sabe poco de algo tiende a sobreestimar lo que sabe, y quien sabe mucho tiende a subestimarse. Por eso el que recién empieza suele hablar con más seguridad que el experto.',
    ),
    (
      ['disonancia cognitiva'],
      'La **disonancia cognitiva** es la incomodidad de tener ideas o actos que chocan entre sí (saber que no estudiar es mala idea y no estudiar). Para aliviarla, a veces cambiamos la conducta... y a veces solo nos inventamos excusas.',
    ),
    (
      ['piramide de maslow', 'jerarquia de necesidades'],
      'La **pirámide de Maslow** ordena las necesidades humanas: primero las fisiológicas (comer, dormir), luego la seguridad, después la pertenencia (amigos, pareja), el reconocimiento y, en la punta, la autorrealización. Es un modelo clásico, aunque hoy se discute que sea tan escalonado.',
    ),
    (
      ['condicionamiento clasico', 'perro de pavlov'],
      'El **condicionamiento clásico** (Pavlov): si a un perro le suenas una campana cada vez que le das comida, al final saliva solo con oír la campana. Aprendemos a asociar estímulos.',
    ),
    (
      ['condicionamiento operante', 'refuerzo positivo'],
      'El **condicionamiento operante** (Skinner): una conducta que trae recompensa tiende a repetirse, y una que trae castigo tiende a desaparecer. Así se forman muchos hábitos... y así te enganchan las notificaciones.',
    ),
    (
      ['apego', 'teoria del apego', 'estilos de apego'],
      'La **teoría del apego** (John Bowlby, Mary Ainsworth) dice que el vínculo que formamos de bebés con quienes nos cuidan influye en cómo nos relacionamos de adultos: con seguridad, con ansiedad o con distancia. No es una condena: se puede trabajar.',
    ),
    (
      ['empatia'],
      'La **empatía** es la capacidad de ponerte en el lugar del otro: entender lo que siente, aunque no estés de acuerdo con él.',
    ),
    (
      ['asertividad', 'ser asertivo', 'asertivo'],
      'La **asertividad** es decir lo que piensas y lo que necesitas con claridad y respeto, sin agredir y sin quedarte callado. Ejemplo: "Hoy no puedo prestarte mis apuntes; mañana sí".',
    ),
    (
      ['motivacion intrinseca', 'motivacion extrinseca'],
      'La **motivación intrínseca** viene de adentro: haces algo porque te gusta o te interesa. La **extrínseca** viene de afuera: una nota, plata o un premio. La intrínseca suele durar más.',
    ),
    (
      ['flow', 'estado de flujo'],
      'El **flow** (estado de flujo, de Mihály Csíkszentmihályi) es cuando estás tan metido en algo que se te pasa el tiempo volando. Aparece cuando el reto es un poco más alto que tu nivel, ni mucho más ni mucho menos.',
    ),
    (
      ['mindfulness', 'atencion plena', 'meditacion'],
      'El **mindfulness** (atención plena) es entrenar la atención en el momento presente, sin juzgar lo que pasa. Con unos minutos al día de notar tu respiración ya se nota menos estrés.',
    ),
    (
      ['efecto placebo', 'placebo'],
      'El **efecto placebo** es cuando alguien mejora con un tratamiento sin efecto real (una pastilla de azúcar) solo porque espera mejorar. Por eso los medicamentos se prueban comparándolos con un placebo.',
    ),
    (
      ['efecto pigmalion'],
      'El **efecto Pigmalión**: lo que otros esperan de nosotros influye en cómo rendimos. Si un profe cree que un alumno va a brillar, suele tratarlo distinto, y el alumno termina rindiendo más.',
    ),
    (
      ['introvertido', 'extrovertido', 'introversion', 'extroversion'],
      'Un **introvertido** recarga energía estando solo o con poca gente; un **extrovertido**, rodeado de gente. No tiene que ver con ser tímido o no, y la mayoría estamos en algún punto del medio.',
    ),
    (
      ['personalidad', 'big five', 'cinco grandes'],
      'El modelo de **personalidad** con más respaldo científico son los "cinco grandes": apertura a la experiencia, responsabilidad, extraversión, amabilidad y estabilidad emocional.',
    ),
    (
      ['mbti', '16 personalidades', 'test de personalidad'],
      'El **MBTI** (los 16 tipos, como INTJ o ENFP) es popular y divertido, pero en psicología se considera poco confiable: el mismo test puede darte otro tipo a las pocas semanas. El modelo de los cinco grandes tiene más evidencia.',
    ),
    (
      ['ataque de panico', 'crisis de panico', 'ataque de ansiedad'],
      'Un **ataque de pánico** es una ola de miedo intenso con taquicardia, falta de aire y la sensación de que algo terrible va a pasar. Asusta mucho, pero suele pasar en minutos. Respirar lento y largo ayuda; si se repite, consúltalo con un profesional.',
    ),
    (
      ['duelo'],
      'El **duelo** es el proceso de adaptarse a una pérdida: alguien que murió, una relación, una etapa. No tiene un orden fijo ni un tiempo exacto, y está bien pedir ayuda para atravesarlo.',
    ),
    (
      ['inteligencias multiples'],
      'La teoría de las **inteligencias múltiples** (Howard Gardner) propone que no hay una sola inteligencia: está la lingüística, la lógico-matemática, la musical, la espacial, la corporal, la interpersonal, la intrapersonal y la naturalista.',
    ),
    (
      ['neuroplasticidad'],
      'La **neuroplasticidad** es la capacidad del cerebro de cambiar y crear conexiones nuevas toda la vida. Por eso se puede aprender a cualquier edad: practicar, literalmente, te cambia el cerebro.',
    ),
    (
      ['dopamina'],
      'La **dopamina** es un mensajero químico del cerebro ligado a la motivación y la recompensa. Las redes sociales están diseñadas para darte pequeñas dosis seguidas, y por eso cuesta tanto soltarlas.',
    ),
    (
      ['serotonina'],
      'La **serotonina** es un mensajero químico del cerebro que influye en el ánimo, el sueño y el apetito.',
    ),
    (
      ['curva del olvido', 'curva de ebbinghaus'],
      'La **curva del olvido** (Ebbinghaus) muestra que olvidamos rapidísimo lo que aprendemos si no lo repasamos. Repasar al día siguiente, y después cada vez más espaciado, lo fija.',
    ),
    (
      ['repeticion espaciada'],
      'La **repetición espaciada** es repasar en intervalos cada vez más largos: al día, a los tres días, a la semana. Es de las técnicas de estudio con más evidencia científica.',
    ),
    (
      ['recuerdo activo', 'active recall'],
      'El **recuerdo activo** es estudiar intentando recordar sin mirar (con preguntas, tarjetas o explicándolo en voz alta) en vez de releer. Cuesta más, y justamente por eso funciona mejor.',
    ),
    (
      ['tecnica feynman', 'metodo feynman'],
      'La **técnica Feynman**: explica el tema como si se lo enseñaras a un niño. Donde te trabas, ahí está lo que no entendiste: vuelves a estudiar esa parte y lo explicas otra vez.',
    ),
    (
      ['zona de confort'],
      'La **zona de confort** es lo que ya sabes hacer sin esfuerzo ni miedo. Crecer pasa justo afuera: no tan lejos como para paralizarte, pero un poco más allá.',
    ),
    (
      ['gaslighting', 'luz de gas'],
      'El **gaslighting** (luz de gas) es una manipulación en la que alguien te hace dudar de tu memoria o de tu percepción: "eso nunca pasó", "estás exagerando". Si te pasa seguido con alguien, es una señal de alerta.',
    ),
    (
      ['red flag', 'red flags', 'banderas rojas'],
      'Una **red flag** es una señal de alerta en una relación o una amistad: celos que controlan, mentiras repetidas, que te alejen de tu gente o que te hagan sentir culpable de todo.',
    ),
    (
      ['ghosting', 'ghostear', 'me ghostearon'],
      'El **ghosting** es cuando alguien desaparece sin explicación y deja de responder. Duele, pero dice más de esa persona que de ti.',
    ),
    // ------------------------------------------------------------- historia
    (
      ['imperio inca', 'incas', 'los incas', 'tawantinsuyu'],
      'El **Imperio inca** (Tawantinsuyu) fue el más grande de la América precolombina: iba de Ecuador hasta Chile y Argentina, con Cusco como capital. Parte del occidente boliviano estaba en él. La conquista española empezó en 1532.',
    ),
    (
      ['mayas', 'los mayas', 'cultura maya'],
      'Los **mayas** vivieron en el sur de México y Centroamérica. Tenían escritura, calendarios muy precisos y usaban el cero en sus cuentas. Sus grandes ciudades florecieron entre los años 250 y 900.',
    ),
    (
      ['aztecas', 'los aztecas', 'mexicas'],
      'Los **aztecas** (mexicas) fundaron Tenochtitlan, donde hoy está Ciudad de México, en 1325. Cayeron ante Hernán Cortés y sus aliados indígenas en 1521.',
    ),
    (
      ['antiguo egipto', 'egipcios', 'los egipcios'],
      'El **antiguo Egipto** duró unos 3000 años a orillas del río Nilo. Sus faraones construyeron las pirámides de Giza hace unos 4500 años, y escribían con jeroglíficos.',
    ),
    (
      ['antigua grecia', 'griegos', 'los griegos'],
      'La **antigua Grecia** nos dejó la democracia (en Atenas), la filosofía de Sócrates, Platón y Aristóteles, el teatro y los Juegos Olímpicos.',
    ),
    (
      ['imperio romano', 'romanos', 'los romanos', 'roma antigua'],
      'El **Imperio romano** dominó el Mediterráneo durante siglos. Nos dejó el latín (de donde viene el castellano), el derecho romano, acueductos y caminos. Su parte occidental cayó en el año 476.',
    ),
    (
      ['edad media'],
      'La **Edad Media** va, más o menos, del año 476 (caída de Roma) a 1492 (llegada de Colón a América). Época de reinos, castillos, una Iglesia muy poderosa y las primeras universidades.',
    ),
    (
      ['renacimiento'],
      'El **Renacimiento** (siglos XV y XVI, desde Italia) volvió a mirar el arte y el saber de Grecia y Roma, con el ser humano en el centro. Leonardo da Vinci y Miguel Ángel son de esa época.',
    ),
    (
      ['ilustracion', 'la ilustracion'],
      'La **Ilustración** (siglo XVIII) defendió la razón, la ciencia y los derechos de las personas frente al poder absoluto de los reyes. Inspiró la Revolución Francesa y las independencias americanas.',
    ),
    (
      ['revolucion industrial'],
      'La **Revolución Industrial** empezó en Inglaterra a fines del siglo XVIII: la máquina de vapor, las fábricas y el tren cambiaron para siempre cómo se trabaja y se vive.',
    ),
    (
      ['guerra fria'],
      'La **Guerra Fría** (1947-1991) fue la rivalidad entre Estados Unidos y la Unión Soviética: sin guerra directa entre ellos, pero con carrera armamentista, carrera espacial y conflictos en otros países. Terminó con la caída de la URSS.',
    ),
    (
      ['epoca colonial', 'la colonia en bolivia', 'colonia espanola'],
      'La **época colonial** en lo que hoy es Bolivia va de la conquista española, en el siglo XVI, a la independencia de 1825. Potosí, con la plata del Cerro Rico, llegó a ser una de las ciudades más grandes y ricas del mundo.',
    ),
    // ------------------------------------------------------------ arte
    (
      ['impresionismo'],
      'El **impresionismo** (Francia, siglo XIX: Monet, Renoir) pintaba la luz y el instante, con pinceladas sueltas y muchas veces al aire libre.',
    ),
    (
      ['cubismo'],
      'El **cubismo** (Picasso, Braque) descompone los objetos en formas geométricas y los muestra desde varios ángulos a la vez.',
    ),
    (
      ['surrealismo'],
      'El **surrealismo** (Dalí, Magritte) pinta como en los sueños: relojes que se derriten, escenas imposibles.',
    ),
    (
      ['barroco', 'barroco mestizo'],
      'El **barroco** (siglos XVII y XVIII) es un estilo recargado y dramático. En Bolivia está el barroco mestizo, que mezcla lo europeo con lo andino, como en las iglesias de Potosí y de las misiones de Chiquitos.',
    ),
    (
      ['rock'],
      'El **rock** nació en Estados Unidos en los años 50, mezclando blues, country y rhythm and blues. Chuck Berry y Elvis Presley fueron de los primeros.',
    ),
    (
      ['jazz'],
      'El **jazz** nació entre fines del siglo XIX y principios del XX en Nueva Orleans, en comunidades afroamericanas. Su sello es la improvisación.',
    ),
    (
      ['reggaeton', 'regueton'],
      'El **reguetón** nació entre Puerto Rico y Panamá en los años 90, mezclando reggae en español, hip hop y ritmos caribeños. Su base rítmica se llama dembow.',
    ),
    (
      ['cumbia'],
      'La **cumbia** nació en la costa caribeña de Colombia y se extendió por toda Latinoamérica, con versiones propias en cada país, Bolivia incluida.',
    ),
    // ------------------------------------------------------------- ciencia
    (
      ['ciclo del agua'],
      'El **ciclo del agua**: el sol evapora el agua de mares y ríos, el vapor se enfría y se condensa en nubes, cae como lluvia o nieve y vuelve a ríos, suelos y mares. Y otra vez.',
    ),
    (
      ['efecto invernadero'],
      'El **efecto invernadero** es cuando ciertos gases (como el CO2 y el metano) atrapan parte del calor del sol en la atmósfera. Sin él la Tierra sería helada; con demasiado, se calienta de más.',
    ),
    (
      ['placas tectonicas', 'tectonica de placas'],
      'La corteza terrestre está dividida en **placas tectónicas** que se mueven unos centímetros al año. Donde chocan o se separan hay terremotos, volcanes y cordilleras, como los Andes.',
    ),
    (
      ['terremoto', 'terremotos', 'sismo', 'sismos'],
      'Un **terremoto** o sismo es un temblor de la tierra causado sobre todo por el movimiento brusco de las placas tectónicas.',
    ),
    (
      ['volcan', 'volcanes'],
      'Un **volcán** es una abertura de la Tierra por donde salen magma, gases y ceniza. En Bolivia hay varios en la cordillera occidental, como el Licancabur, en la frontera con Chile.',
    ),
    (
      ['capas de la tierra'],
      'La Tierra tiene capas: la **corteza** (donde vivimos), el **manto** (roca caliente que fluye muy lento), el **núcleo externo** (metal líquido) y el **núcleo interno** (metal sólido, a más de 5000 °C).',
    ),
    (
      ['mecanica cuantica', 'fisica cuantica', 'cuantica'],
      'La **mecánica cuántica** describe el mundo de lo muy pequeño: átomos y partículas. Ahí todo se comporta raro: una partícula puede estar en varios estados a la vez hasta que se la mide. Gracias a ella existen los láseres y los chips.',
    ),
    (
      ['biodiversidad'],
      'La **biodiversidad** es la variedad de seres vivos de un lugar. Bolivia es de los países con más biodiversidad del mundo, con parques como el Madidi y el Noel Kempff Mercado.',
    ),
    (
      ['energia renovable', 'energias renovables'],
      'Las **energías renovables** vienen de fuentes que no se agotan: el sol, el viento, el agua de los ríos y el calor de la tierra. Contaminan mucho menos que el petróleo o el carbón.',
    ),
    // ------------------------------------------------------------ sociedad
    (
      [
        'oferta y demanda',
        'oferta y la demanda',
        'ley de oferta y demanda',
        'ley de la oferta y la demanda',
        'ley de la oferta y demanda',
      ],
      'La ley de **oferta y demanda**: si mucha gente quiere algo y hay poco, el precio sube; si hay mucho y pocos lo quieren, baja. Por eso las salteñas se acaban antes del mediodía.',
    ),
    (
      ['capitalismo'],
      'El **capitalismo** es un sistema económico donde los medios de producción son mayormente privados y los precios se fijan sobre todo en el mercado.',
    ),
    (
      ['socialismo'],
      'El **socialismo** es un conjunto de ideas que busca que los medios de producción sean sociales o del Estado, para repartir mejor la riqueza. Hay muchas versiones, de moderadas a radicales.',
    ),
    (
      ['globalizacion'],
      'La **globalización** es la conexión cada vez mayor entre países: comercio, internet, cultura y viajes. Tu celular, por ejemplo, tiene piezas fabricadas en varios continentes.',
    ),
    (
      ['networking'],
      'El **networking** es crear y cuidar una red de contactos: compañeros, profes, gente de tu área. Muchas oportunidades de trabajo llegan por ahí, no por los anuncios.',
    ),
  ];

  // ============================================================== personas
  static const personas = <_Entrada>[
    // ---------------------------------------------------------- filosofos
    (
      ['socrates'],
      '**Sócrates** (c. 470-399 a. C.), filósofo de Atenas. No escribió nada: lo conocemos por su discípulo Platón. Preguntaba sin parar para que la gente examinara lo que creía saber. Fue condenado a muerte y bebió cicuta.',
    ),
    (
      ['platon'],
      '**Platón** (c. 427-347 a. C.), discípulo de Sócrates y maestro de Aristóteles. Fundó la Academia en Atenas. Habló del mundo de las ideas y del mito de la caverna, y escribió "La República".',
    ),
    (
      ['aristoteles'],
      '**Aristóteles** (384-322 a. C.), discípulo de Platón y maestro de Alejandro Magno. Escribió de casi todo: lógica, ética (la virtud como punto medio), política, biología y física.',
    ),
    (
      ['descartes', 'rene descartes'],
      '**René Descartes** (1596-1650), filósofo y matemático francés. "Pienso, luego existo". Es considerado el padre de la filosofía moderna, y el plano cartesiano lleva su nombre.',
    ),
    (
      ['kant', 'immanuel kant'],
      '**Immanuel Kant** (1724-1804), filósofo alemán. Escribió la "Crítica de la razón pura" y propuso el imperativo categórico. Dicen que era tan puntual en sus paseos que los vecinos ajustaban sus relojes con él.',
    ),
    (
      ['nietzsche', 'friedrich nietzsche'],
      '**Friedrich Nietzsche** (1844-1900), filósofo alemán. Anunció que "Dios ha muerto" como diagnóstico de su época, y habló del superhombre y del eterno retorno. Suya es "lo que no me mata me hace más fuerte".',
    ),
    (
      ['marx', 'karl marx'],
      '**Karl Marx** (1818-1883), filósofo y economista alemán. Escribió "El capital" y, con Engels, el "Manifiesto comunista". Analizó el capitalismo y la lucha de clases.',
    ),
    (
      ['sartre', 'jean paul sartre'],
      '**Jean-Paul Sartre** (1905-1980), filósofo francés, figura del existencialismo: "el ser humano está condenado a ser libre". Rechazó el Premio Nobel de Literatura en 1964.',
    ),
    (
      ['camus', 'albert camus'],
      '**Albert Camus** (1913-1960), escritor francés nacido en Argelia. Escribió "El extranjero" y "El mito de Sísifo", sobre el absurdo. Ganó el Nobel de Literatura en 1957.',
    ),
    (
      ['simone de beauvoir', 'beauvoir'],
      '**Simone de Beauvoir** (1908-1986), filósofa francesa. En "El segundo sexo" (1949) escribió "no se nace mujer: se llega a serlo", base del feminismo moderno.',
    ),
    (
      ['confucio'],
      '**Confucio** (551-479 a. C.), pensador chino. Enseñó el respeto, la familia, la educación y la virtud como base de una buena sociedad.',
    ),
    (
      ['buda', 'siddhartha gautama', 'siddharta'],
      '**Buda** (Siddhartha Gautama) fue un príncipe que, según la tradición, dejó todo para buscar el fin del sufrimiento, hace unos 2500 años. Nació en lo que hoy es Nepal y enseñó en la India: así nació el budismo.',
    ),
    (
      ['epicuro'],
      '**Epicuro** (341-270 a. C.), filósofo griego. Para él la felicidad es la tranquilidad: placeres simples, amistad y vivir sin miedo.',
    ),
    (
      ['seneca'],
      '**Séneca** (c. 4 a. C.-65 d. C.), filósofo estoico romano. En "Sobre la brevedad de la vida" dice que la vida no es corta: la desperdiciamos.',
    ),
    (
      ['marco aurelio'],
      '**Marco Aurelio** (121-180), emperador romano y filósofo estoico. Sus notas personales, las "Meditaciones", se siguen leyendo hoy.',
    ),
    (
      ['epicteto'],
      '**Epicteto** (c. 50-135), filósofo estoico que había sido esclavo. Enseñó a distinguir lo que depende de nosotros de lo que no.',
    ),
    (
      ['spinoza', 'baruch spinoza'],
      '**Baruch Spinoza** (1632-1677), filósofo neerlandés. Identificó a Dios con la naturaleza y escribió la "Ética".',
    ),
    (
      ['hume', 'david hume'],
      '**David Hume** (1711-1776), filósofo escocés y empirista. Mostró que muchas de nuestras certezas, como que el sol saldrá mañana, se basan en la costumbre más que en la lógica.',
    ),
    (
      ['locke', 'john locke'],
      '**John Locke** (1632-1704), filósofo inglés. Habló de la mente como tabula rasa y de los derechos naturales (vida, libertad y propiedad), base del liberalismo.',
    ),
    (
      ['rousseau', 'jean jacques rousseau'],
      '**Jean-Jacques Rousseau** (1712-1778), filósofo nacido en Ginebra. Escribió "El contrato social" y sostuvo que el ser humano nace bueno y la sociedad lo corrompe.',
    ),
    (
      ['hegel'],
      '**Georg Hegel** (1770-1831), filósofo alemán. Desarrolló la dialéctica y entendió la historia como un proceso en el que la razón se va realizando.',
    ),
    (
      ['maquiavelo', 'nicolas maquiavelo'],
      '**Nicolás Maquiavelo** (1469-1527), pensador italiano. En "El príncipe" describió la política como es, no como debería ser. Se le atribuye "el fin justifica los medios", aunque no lo escribió así.',
    ),
    (
      ['hannah arendt', 'arendt'],
      '**Hannah Arendt** (1906-1975), filósofa alemana. Estudió el totalitarismo y acuñó la idea de la "banalidad del mal": personas comunes que hacen daño enorme por obedecer sin pensar.',
    ),
    (
      ['lao tse', 'lao tzu'],
      '**Lao Tsé**, sabio chino al que la tradición atribuye el "Tao Te Ching", el libro base del taoísmo. Suya es "un viaje de mil millas comienza con un solo paso".',
    ),
    (
      ['diogenes'],
      '**Diógenes** (c. 412-323 a. C.), filósofo cínico que vivía en una tinaja. Cuenta la historia que Alejandro Magno le ofreció lo que quisiera, y él le pidió que se corriera porque le tapaba el sol.',
    ),
    (
      ['heraclito'],
      '**Heráclito** (c. 540-480 a. C.), filósofo griego. Pensaba que todo fluye y cambia: "nadie se baña dos veces en el mismo río".',
    ),
    // ---------------------------------------------------------- psicologos
    (
      ['freud', 'sigmund freud'],
      '**Sigmund Freud** (1856-1939), médico austriaco, padre del psicoanálisis. Habló del inconsciente, de los sueños y del ello, el yo y el superyó. Muchas de sus ideas hoy se discuten, pero cambió para siempre la forma de pensar la mente.',
    ),
    (
      ['jung', 'carl jung'],
      '**Carl Jung** (1875-1961), psiquiatra suizo. Habló del inconsciente colectivo y de los arquetipos, y popularizó las ideas de introversión y extraversión.',
    ),
    (
      ['piaget', 'jean piaget'],
      '**Jean Piaget** (1896-1980), psicólogo suizo. Describió las etapas del desarrollo del pensamiento en los niños.',
    ),
    (
      ['vygotsky', 'lev vygotsky'],
      '**Lev Vygotsky** (1896-1934), psicólogo ruso. Propuso la zona de desarrollo próximo: lo que alguien todavía no puede hacer solo, pero sí con ayuda. Por eso estudiar en grupo funciona.',
    ),
    (
      ['maslow', 'abraham maslow'],
      '**Abraham Maslow** (1908-1970), psicólogo estadounidense, conocido por su pirámide de necesidades.',
    ),
    (
      ['skinner', 'b f skinner'],
      '**B. F. Skinner** (1904-1990), psicólogo estadounidense del conductismo. Estudió el condicionamiento operante: cómo los premios y castigos moldean la conducta.',
    ),
    (
      ['pavlov', 'ivan pavlov'],
      '**Iván Pávlov** (1849-1936), fisiólogo ruso. Descubrió el condicionamiento clásico con sus perros, y ganó el Nobel de Medicina en 1904 por sus estudios sobre la digestión.',
    ),
    (
      ['kahneman', 'daniel kahneman'],
      '**Daniel Kahneman** (1934-2024), psicólogo que ganó el Nobel de Economía en 2002. En "Pensar rápido, pensar despacio" explica nuestros dos modos de pensar: uno rápido e intuitivo, y otro lento y cuidadoso.',
    ),
    // --------------------------------------------------------------- otros
    (
      ['stephen hawking', 'hawking'],
      '**Stephen Hawking** (1942-2018), físico británico. Estudió los agujeros negros y el origen del universo, y siguió trabajando décadas pese a la ELA, que lo dejó casi sin poder moverse.',
    ),
    (
      ['van gogh', 'vincent van gogh'],
      '**Vincent van Gogh** (1853-1890), pintor neerlandés. "La noche estrellada" y "Los girasoles" son suyos. En vida casi no vendió cuadros; hoy valen fortunas.',
    ),
    (
      ['frida kahlo', 'frida'],
      '**Frida Kahlo** (1907-1954), pintora mexicana famosa por sus autorretratos, llenos de color y de dolor: pintó gran parte de su obra después de un grave accidente.',
    ),
    (
      ['mozart', 'wolfgang amadeus mozart'],
      '**Wolfgang Amadeus Mozart** (1756-1791), compositor austriaco. Niño prodigio: componía desde los cinco años. Escribió más de 600 obras en solo 35 años de vida.',
    ),
    (
      ['beethoven', 'ludwig van beethoven'],
      '**Ludwig van Beethoven** (1770-1827), compositor alemán. Compuso algunas de sus obras más grandes, como la Novena Sinfonía, cuando ya estaba sordo.',
    ),
    (
      ['borges', 'jorge luis borges'],
      '**Jorge Luis Borges** (1899-1986), escritor argentino. Sus cuentos de "Ficciones" y "El Aleph" juegan con laberintos, espejos e infinitos.',
    ),
    (
      ['vargas llosa', 'mario vargas llosa'],
      '**Mario Vargas Llosa**, escritor peruano, Premio Nobel de Literatura en 2010. Autor de "La ciudad y los perros" y "Conversación en La Catedral".',
    ),
    (
      ['gandhi', 'mahatma gandhi'],
      '**Mahatma Gandhi** (1869-1948) lideró la independencia de la India con la resistencia no violenta.',
    ),
    (
      ['mandela', 'nelson mandela'],
      '**Nelson Mandela** (1918-2013) pasó 27 años preso por luchar contra el apartheid y después fue el primer presidente negro de Sudáfrica, en 1994. Ganó el Nobel de la Paz en 1993.',
    ),
    (
      ['martin luther king'],
      '**Martin Luther King** (1929-1968) lideró la lucha por los derechos civiles de los afroamericanos en Estados Unidos, sin violencia. Su discurso más famoso: "Tengo un sueño".',
    ),
    (
      ['napoleon', 'napoleon bonaparte'],
      '**Napoleón Bonaparte** (1769-1821), militar y emperador francés. Conquistó buena parte de Europa y dejó el Código Civil, base de muchas leyes modernas.',
    ),
    (
      ['cleopatra'],
      '**Cleopatra** fue la última reina del Egipto ptolemaico. Murió en el año 30 a. C., y después Egipto pasó a ser parte del Imperio romano.',
    ),
    (
      ['che guevara', 'ernesto guevara', 'el che', 'ernesto che guevara'],
      '**Ernesto "Che" Guevara** (1928-1967), guerrillero de origen argentino que participó en la Revolución cubana. Murió en Bolivia, en La Higuera (Santa Cruz), en 1967.',
    ),
  ];

  // ================================================================ frases
  /// (formas de nombrar al autor, la frase, como se lo escribe).
  static const _frases = <(List<String>, String, String)>[
    (['socrates'], 'Solo sé que no sé nada.', 'Sócrates'),
    (['socrates'], 'Una vida sin examen no merece ser vivida.', 'Sócrates'),
    (
      ['platon'],
      'El comienzo es la parte más importante del trabajo.',
      'Platón',
    ),
    (
      ['aristoteles'],
      'El ser humano es, por naturaleza, un animal político.',
      'Aristóteles',
    ),
    (
      ['descartes', 'rene descartes'],
      'Pienso, luego existo.',
      'René Descartes',
    ),
    (
      ['nietzsche', 'friedrich nietzsche'],
      'Lo que no me mata me hace más fuerte.',
      'Friedrich Nietzsche',
    ),
    (
      ['nietzsche', 'friedrich nietzsche'],
      'Quien tiene un porqué para vivir puede soportar casi cualquier cómo.',
      'Friedrich Nietzsche',
    ),
    (
      ['seneca'],
      'No es que tengamos poco tiempo, sino que perdemos mucho.',
      'Séneca',
    ),
    (['seneca'], 'Mientras se espera vivir, la vida pasa.', 'Séneca'),
    (
      ['epicteto'],
      'No nos perturban las cosas, sino las opiniones que tenemos de ellas.',
      'Epicteto',
    ),
    (
      ['sartre', 'jean paul sartre'],
      'El ser humano está condenado a ser libre.',
      'Jean-Paul Sartre',
    ),
    (
      ['camus', 'albert camus'],
      'En medio del invierno descubrí que había en mí un verano invencible.',
      'Albert Camus',
    ),
    (
      ['simone de beauvoir', 'beauvoir'],
      'No se nace mujer: se llega a serlo.',
      'Simone de Beauvoir',
    ),
    (
      ['confucio'],
      'Aprender sin pensar es inútil; pensar sin aprender es peligroso.',
      'Confucio',
    ),
    (
      ['lao tse', 'lao tzu'],
      'Un viaje de mil millas comienza con un solo paso.',
      'Lao Tsé',
    ),
    (
      ['epicuro'],
      'No arruines lo que tienes deseando lo que no tienes.',
      'Epicuro',
    ),
    (['heraclito'], 'Nadie se baña dos veces en el mismo río.', 'Heráclito'),
    (
      ['kant', 'immanuel kant'],
      '¡Ten el valor de servirte de tu propio entendimiento!',
      'Immanuel Kant',
    ),
    (
      ['einstein', 'albert einstein'],
      'La imaginación es más importante que el conocimiento.',
      'Albert Einstein',
    ),
    (
      ['newton', 'isaac newton'],
      'Si he visto más lejos, es porque estoy sentado sobre los hombros de '
          'gigantes.',
      'Isaac Newton',
    ),
    (
      ['mandela', 'nelson mandela'],
      'La educación es el arma más poderosa que puedes usar para cambiar el '
          'mundo.',
      'Nelson Mandela',
    ),
    (
      ['frida kahlo', 'frida'],
      'Pies, ¿para qué los quiero si tengo alas para volar?',
      'Frida Kahlo',
    ),
    (
      ['cervantes', 'miguel de cervantes'],
      'El que lee mucho y anda mucho, ve mucho y sabe mucho.',
      'Miguel de Cervantes',
    ),
    (
      ['borges', 'jorge luis borges'],
      'Yo, que me figuraba el Paraíso bajo la especie de una biblioteca.',
      'Jorge Luis Borges',
    ),
    (
      ['steve jobs'],
      'Sigue hambriento, sigue alocado.',
      'Steve Jobs, en su discurso de Stanford (2005)',
    ),
  ];

  // ============================================================== refranes
  /// (el refran, lo que quiere decir).
  static const _refranes = <(String, String)>[
    (
      'Camarón que se duerme se lo lleva la corriente',
      'si te descuidas, pierdes la oportunidad. Válido para inscripciones y '
          'para las últimas salteñas.',
    ),
    ('Al que madruga, Dios lo ayuda', 'empezar temprano rinde más.'),
    (
      'No por mucho madrugar amanece más temprano',
      'hay cosas que llevan su tiempo, por más apuro que tengas.',
    ),
    ('Más vale tarde que nunca', 'es mejor hacer algo tarde que no hacerlo.'),
    (
      'Dime con quién andas y te diré quién eres',
      'tus amistades dicen mucho de ti.',
    ),
    ('En boca cerrada no entran moscas', 'a veces es mejor quedarse callado.'),
    (
      'A caballo regalado no se le miran los dientes',
      'lo que te regalan se agradece, sin ponerle peros.',
    ),
    (
      'Más vale pájaro en mano que cien volando',
      'mejor algo seguro que mucho incierto.',
    ),
    ('Perro que ladra no muerde', 'quien amenaza mucho rara vez cumple.'),
    ('Ojos que no ven, corazón que no siente', 'lo que no sabes no te duele.'),
    (
      'Del dicho al hecho hay mucho trecho',
      'una cosa es decirlo y otra hacerlo.',
    ),
    (
      'No hay mal que por bien no venga',
      'de algo malo puede salir algo bueno.',
    ),
    ('Al mal tiempo, buena cara', 'ante los problemas, buena actitud.'),
    (
      'Poco a poco se anda lejos',
      'con constancia se llega lejos, aunque sea despacio. Perfecto para '
          'estudiar.',
    ),
    (
      'Quien mucho abarca poco aprieta',
      'si quieres hacer demasiadas cosas a la vez, ninguna te sale bien.',
    ),
    (
      'El que no arriesga no gana',
      'para conseguir algo, a veces hay que animarse.',
    ),
    (
      'Agua que no has de beber, déjala correr',
      'no te metas en lo que no te sirve o no te corresponde.',
    ),
    (
      'Cría cuervos y te sacarán los ojos',
      'a veces quien recibió tu ayuda termina volviéndose en tu contra.',
    ),
  ];

  // ================================================================ fabulas
  static const _fabulas = [
    '**La liebre y la tortuga**\n'
        'La liebre se burlaba de lo lenta que era la tortuga, así que la '
        'tortuga la retó a una carrera. La liebre salió disparada y, segura '
        'de ganar, se echó una siesta. La tortuga siguió paso a paso, sin '
        'parar, y cuando la liebre despertó, ya había cruzado la meta.\n\n'
        'Moraleja: la constancia le gana al talento que se confía. (Como '
        'estudiar un poquito cada día.)',
    '**La cigarra y la hormiga**\n'
        'Todo el verano la cigarra cantó mientras la hormiga guardaba comida. '
        'Llegó el invierno, la cigarra no tenía nada y fue a pedirle a la '
        'hormiga. "¿Qué hiciste en verano?", le preguntó. "Cantar". "Entonces '
        'ahora baila".\n\n'
        'Moraleja: hay que prepararse antes de que haga falta. Versión U: '
        'estudiar antes de la semana de exámenes.',
    '**El pastorcito mentiroso**\n'
        'Un pastor gritaba "¡viene el lobo!" para reírse de la gente del '
        'pueblo, que corría a ayudarlo. Lo hizo tantas veces que, cuando el '
        'lobo vino de verdad, nadie le creyó.\n\n'
        'Moraleja: al mentiroso no le creen ni cuando dice la verdad.',
    '**La lechera**\n'
        'Una joven iba al mercado con un cántaro de leche, soñando: con la '
        'plata compraría huevos, de los huevos saldrían pollitos, vendería '
        'los pollitos y compraría un vestido... Tan distraída iba que '
        'tropezó, y la leche se derramó entera.\n\n'
        'Moraleja: no cuentes con lo que todavía no tienes. Paso a paso.',
    '**El león y el ratón**\n'
        'Un león atrapó a un ratón, que le rogó que lo soltara: "algún día te '
        'ayudaré". El león, divertido, lo dejó ir. Tiempo después el león '
        'cayó en una red de cazadores, y el ratón royó las cuerdas hasta '
        'liberarlo.\n\n'
        'Moraleja: nadie es tan pequeño como para no poder ayudar.',
    '**La zorra y las uvas**\n'
        'Una zorra vio unas uvas muy apetitosas colgando de una parra, pero '
        'por más que saltó, no las alcanzó. Al final se fue diciendo: "Bah, '
        'seguro estaban verdes".\n\n'
        'Moraleja: es fácil despreciar lo que no podemos conseguir.',
  ];
}
