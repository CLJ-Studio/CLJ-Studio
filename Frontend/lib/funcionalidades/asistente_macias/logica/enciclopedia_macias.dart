import 'cocina_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'lenguaje_macias.dart';

/// Una entrada: las formas en que se la nombra (ya normalizadas) y lo que
/// MacIAs dice de ella.
typedef _Entrada = (List<String>, String);

/// Un elemento de la tabla periodica.
typedef _Elemento = (String nombre, String simbolo, int numero, String dato);

/// Un pais: como se escribe, su moneda, su idioma y donde queda.
typedef _Pais = (String nombre, String moneda, String idioma, String donde);

/// Lo que MacIAs sabe del mundo, ademas de la app y sus materias.
///
/// Todo escrito a mano y comprobado: conceptos de las materias de la U,
/// personajes, lugares, cultura boliviana, la tabla periodica, formulas,
/// paises. Son datos que no cambian. Lo que si cambia (noticias, precios,
/// resultados) no esta, a proposito: sin internet, un dato viejo dicho con
/// seguridad seria peor que un "no sé".
abstract final class EnciclopediaMacias {
  /// Lo que sabe del tema del mensaje, o null.
  ///
  /// Con [soloPreguntas] solo contesta lo que se pregunto como pregunta de
  /// definicion ("¿qué es...?", "¿quién inventó...?", "¿fórmula de...?"): eso
  /// va antes que los temas de la app, porque "¿qué significa PIB?" no es
  /// una pregunta sobre los estados de un pedido. Sin [soloPreguntas]
  /// tambien reconoce el tema suelto ("fotosíntesis").
  static RespuestaCharla? responder(
    String junto,
    ContextoMacias c, {
    bool soloPreguntas = false,
  }) {
    final t = junto.trim();
    if (t.isEmpty) return null;
    return _elemento(t) ??
        _formula(t) ??
        _pais(t) ??
        _invento(t) ??
        CocinaMacias.responder(t) ??
        _pregunta(t) ??
        (soloPreguntas ? null : _palabraSuelta(t));
  }

  // ================================================================ inventos
  static const _inventos = <_Entrada>[
    (
      ['telefono'],
      'El **teléfono** lo patentó Alexander Graham Bell en 1876 (aunque Antonio Meucci había trabajado en algo parecido antes).',
    ),
    (
      ['celular', 'telefono celular', 'telefono movil'],
      'El primer **teléfono celular** lo presentó Martin Cooper, de Motorola, en 1973. Pesaba más de un kilo.',
    ),
    (
      ['bombilla', 'foco', 'bombillo', 'lampara electrica'],
      'La **bombilla** práctica se la debemos a Thomas Edison (1879), aunque otros ya habían hecho versiones antes.',
    ),
    (
      ['internet'],
      '**Internet** no tiene un solo inventor: nació de una red militar de EE. UU. en 1969, y Vint Cerf y Bob Kahn crearon el idioma con el que se comunica (TCP/IP).',
    ),
    (
      ['la web', 'world wide web', 'pagina web'],
      'La **web** la inventó Tim Berners-Lee en 1989, trabajando en el CERN.',
    ),
    (
      ['avion'],
      'El **avión**: los hermanos Wright hicieron el primer vuelo con motor en 1903.',
    ),
    (
      ['imprenta'],
      'La **imprenta** de tipos móviles la desarrolló Johannes Gutenberg hacia 1440.',
    ),
    (
      ['computadora', 'ordenador', 'computador'],
      'La **computadora** tiene muchos padres: Charles Babbage la imaginó en el siglo XIX, Ada Lovelace escribió el primer programa y Alan Turing puso las bases teóricas. Las electrónicas llegaron en los años 40.',
    ),
    (
      ['radio'],
      'La **radio**: Guglielmo Marconi hizo las primeras transmisiones a larga distancia, a fines del siglo XIX (Nikola Tesla también tuvo mucho que ver).',
    ),
    (
      ['television', 'tele'],
      'La **televisión**: John Logie Baird mostró la primera imagen en movimiento en 1926.',
    ),
    (
      ['penicilina'],
      'La **penicilina** la descubrió Alexander Fleming en 1928, casi por accidente: un hongo había contaminado sus cultivos.',
    ),
    (
      ['vacuna', 'vacunas', 'primera vacuna'],
      'La primera **vacuna** la desarrolló Edward Jenner en 1796, contra la viruela.',
    ),
    (
      ['dinamita'],
      'La **dinamita** la inventó Alfred Nobel en 1867. Con su fortuna creó los premios Nobel.',
    ),
    (
      ['calculo'],
      'El **cálculo** lo desarrollaron Isaac Newton y Gottfried Leibniz, cada uno por su lado, en el siglo XVII.',
    ),
    (
      ['algebra'],
      'El **álgebra** como disciplina viene de Al-Juarismi (siglo IX): la palabra sale del título de su libro.',
    ),
    (
      ['automovil', 'auto', 'carro', 'coche'],
      'El primer **automóvil** a motor de gasolina lo patentó Karl Benz en 1886.',
    ),
    (
      ['google'],
      '**Google** lo crearon Larry Page y Sergey Brin en 1998, cuando estudiaban en Stanford.',
    ),
    (['whatsapp'], '**WhatsApp** lo crearon Jan Koum y Brian Acton en 2009.'),
    (['facebook'], '**Facebook** lo creó Mark Zuckerberg en 2004, en Harvard.'),
    (
      ['apple'],
      '**Apple** la fundaron Steve Jobs, Steve Wozniak y Ronald Wayne en 1976.',
    ),
    (
      ['microsoft', 'windows'],
      '**Microsoft** la fundaron Bill Gates y Paul Allen en 1975.',
    ),
    (['linux'], '**Linux** lo creó Linus Torvalds en 1991.'),
    (['c', 'cpp'], '**C++** lo creó Bjarne Stroustrup a principios de los 80.'),
    (
      ['papel'],
      'El **papel** se inventó en China; a Cai Lun se le atribuye haber perfeccionado su fabricación, hacia el año 105.',
    ),
    (
      ['rueda'],
      'La **rueda** apareció en Mesopotamia, hace unos 5500 años. No se sabe quién fue.',
    ),
    (
      ['futbol'],
      'El **fútbol** moderno nació en Inglaterra: sus reglas se escribieron en 1863.',
    ),
    (
      ['ajedrez'],
      'El **ajedrez** viene de un juego de la India de hace unos 1500 años.',
    ),
    (
      ['gravedad', 'ley de la gravedad', 'gravitacion'],
      'La **ley de la gravitación** la formuló Isaac Newton en 1687. Lo de la manzana es casi seguro una exageración, pero buena historia.',
    ),
    (
      ['relatividad', 'teoria de la relatividad'],
      'La **relatividad** la formuló Albert Einstein: la especial en 1905 y la general en 1915.',
    ),
    (
      ['america'],
      '**Cristóbal Colón** llegó a América en 1492. Eso sí, acá ya vivían millones de personas desde mucho antes.',
    ),
    (
      ['mona lisa', 'gioconda', 'la gioconda'],
      'La **Mona Lisa** (o Gioconda) la pintó Leonardo da Vinci a principios del siglo XVI. Está en el Museo del Louvre, en París.',
    ),
    (
      ['ultima cena'],
      '**La última cena** la pintó Leonardo da Vinci, a fines del siglo XV, en una pared de un convento de Milán.',
    ),
    (
      ['noche estrellada'],
      '**La noche estrellada** la pintó Vincent van Gogh en 1889.',
    ),
    (
      ['guernica'],
      'El **Guernica** lo pintó Pablo Picasso en 1937, después del bombardeo de esa ciudad española.',
    ),
    (
      ['don quijote', 'el quijote', 'quijote'],
      '**Don Quijote de la Mancha** lo escribió Miguel de Cervantes; la primera parte salió en 1605.',
    ),
    (
      ['cien anos de soledad'],
      '**Cien años de soledad** la escribió Gabriel García Márquez, colombiano, en 1967.',
    ),
    (
      ['romeo y julieta', 'hamlet'],
      '**Romeo y Julieta** y **Hamlet** son de William Shakespeare, escritas en Inglaterra alrededor del año 1600.',
    ),
    (
      ['el principito', 'principito'],
      '**El principito** lo escribió Antoine de Saint-Exupéry, francés, en 1943.',
    ),
    (
      ['harry potter'],
      '**Harry Potter** lo escribió J. K. Rowling; el primer libro salió en 1997.',
    ),
    (
      ['novena sinfonia', 'himno a la alegria'],
      'La **Novena Sinfonía** (la del Himno a la Alegría) la compuso Ludwig van Beethoven, en 1824, cuando ya estaba sordo.',
    ),
    (
      ['himno nacional de bolivia', 'himno de bolivia', 'himno nacional'],
      'El **Himno Nacional de Bolivia** tiene letra de José Ignacio de Sanjinés y música de Leopoldo Benedetto Vincenti. Se estrenó en 1851.',
    ),
  ];

  static final Map<String, String> _indiceInventos = _indice(_inventos);

  static RespuestaCharla? _invento(String t) {
    final pedido = RegExp(
      r'^(?:y )?(?:sabes )?(?:quien|quienes) (?:invento|inventaron|creo|'
      r'crearon|descubrio|descubrieron|hizo|hicieron|fundo|fundaron|'
      r'desarrollo|pinto|escribio|compuso|compusieron) '
      r'(?:el |la |los |las |un |una )?(.+)$',
    ).firstMatch(t);
    if (pedido == null) return null;
    final texto = _buscar(_indiceInventos, pedido[1]!.trim());
    return texto == null ? null : _dicho(texto, 'saber:invento');
  }

  // ================================================================ buscar
  static final Map<String, String> _conceptos = _indice([
    ..._glosario,
    ..._cultura,
    ...CocinaMacias.platos,
  ]);
  static final Map<String, String> _personajes = _indice(_gente);
  static final Map<String, String> _sitios = _indice(_lugares);

  static Map<String, String> _indice(List<_Entrada> entradas) => {
    for (final (nombres, texto) in entradas)
      for (final nombre in nombres) nombre: texto,
  };

  /// Busca con tolerancia: sin articulo, en singular, o con una falta.
  static String? _buscar(Map<String, String> indice, String tema) {
    final limpio = tema
        .replaceFirst(RegExp(r'^(?:el|la|los|las|un|una|lo) '), '')
        .replaceFirst(
          RegExp(
            r' (?:en (?:fisica|matematica|matematicas|quimica|biologia|'
            r'economia|programacion|informatica|estadistica)|por favor|'
            r'porfa|nomas|pues)$',
          ),
          '',
        )
        .trim();
    if (limpio.isEmpty) return null;
    final exacto = indice[limpio] ?? indice[tema];
    if (exacto != null) return exacto;
    if (limpio.endsWith('es')) {
      final singular = indice[limpio.substring(0, limpio.length - 2)];
      if (singular != null) return singular;
    }
    if (limpio.endsWith('s')) {
      final singular = indice[limpio.substring(0, limpio.length - 1)];
      if (singular != null) return singular;
    }
    // Con una falta, solo en palabras largas: "fotosintecis".
    if (limpio.length >= 7) {
      for (final MapEntry(key: nombre, value: texto) in indice.entries) {
        if ((nombre.length - limpio.length).abs() <= 1 &&
            nombre.length >= 7 &&
            LenguajeMacias.distancia(nombre, limpio) <= 1) {
          return texto;
        }
      }
    }
    return null;
  }

  static final _queEs = [
    RegExp(
      r'^(?:y )?(?:me puedes decir |sabes |me dices |dime |oye )?(?:que|q) '
      r'(?:es|son|significa|significan|seria|era|eran) (.+)$',
    ),
    RegExp(
      r'^(?:me puedes |puedes |podrias )?(?:explicar|explicarme|explicame|'
      r'explica|definir|define|defineme|describe|describeme|ensename)'
      r'(?: que es| que son| lo que es| lo que son)? (.+)$',
    ),
    RegExp(r'^(?:definicion|significado|concepto) (?:de |del )(.+)$'),
    RegExp(
      r'^(?:hablame|cuentame|dime algo|dime|cuentame algo) '
      r'(?:de|del|sobre|acerca de|acerca del) (.+)$',
    ),
    RegExp(
      r'^(?:que sabes|sabes algo|que me puedes decir|que me dices) '
      r'(?:de|del|sobre|acerca de|acerca del) (.+)$',
    ),
    RegExp(
      r'^(?:para que sirve|para que sirven|como funciona|como funcionan) (.+)$',
    ),
    // "No entiendo las derivadas": se explica que son.
    RegExp(
      r'^(?:no entiendo|no le entiendo a|no le entiendo|me cuesta entender|'
      r'ayudame a entender|no me entra) (?:las |los |la |el |lo de )?(.+)$',
    ),
  ];

  /// Palabras que en la app son un estado de pedido: "¿qué significa
  /// pendiente?" pregunta por el pedido, no por la pendiente de una recta.
  static const _estadosDeLaApp = {
    'pendiente',
    'aceptado',
    'rechazado',
    'cancelado',
    'entregado',
    'vencido',
    'falta confirmar',
  };
  static final _quienEs = RegExp(
    r'^(?:y )?(?:sabes |me dices )?(?:quien|quienes) '
    r'(?:es|era|fue|fueron|invento|descubrio|creo) (.+)$',
  );
  static final _dondeQueda = RegExp(
    r'^(?:y )?(?:sabes )?(?:donde|en donde|en que parte) '
    r'(?:queda|esta|se encuentra|estan|quedan) (.+)$',
  );

  static RespuestaCharla? _pregunta(String t) {
    final quien = _quienEs.firstMatch(t);
    if (quien != null) {
      final texto = _buscar(_personajes, quien[1]!.trim());
      if (texto != null) return _dicho(texto, 'saber:persona');
      // "¿Quién es el Ekeko?": no es una persona, pero se sabe.
      final concepto = _buscar(_conceptos, quien[1]!.trim());
      if (concepto != null) return _dicho(concepto, 'saber:concepto');
    }
    final donde = _dondeQueda.firstMatch(t);
    if (donde != null) {
      final texto = _buscar(_sitios, donde[1]!.trim());
      if (texto != null) return _dicho(texto, 'saber:lugar');
    }
    for (final patron in _queEs) {
      final pedido = patron.firstMatch(t);
      if (pedido == null) continue;
      final tema = pedido[1]!.trim();
      if (t.contains('significa') && _estadosDeLaApp.contains(tema)) {
        return null;
      }
      final texto =
          _buscar(_conceptos, tema) ??
          _buscar(_sitios, tema) ??
          _buscar(_personajes, tema) ??
          _elementoPorNombre(tema);
      if (texto != null) return _dicho(texto, 'saber:concepto');
    }
    return null;
  }

  /// "fotosíntesis", "inflación", "Einstein": el tema solo, sin pregunta.
  static RespuestaCharla? _palabraSuelta(String t) {
    if (t.split(' ').length > 4) return null;
    final concepto =
        _conceptos[t] ?? _sitios[t] ?? _personajes[t] ?? _elementoPorNombre(t);
    return concepto == null ? null : _dicho(concepto, 'saber:concepto');
  }

  static RespuestaCharla _dicho(String texto, String intencion) =>
      RespuestaCharla(texto, intencion: intencion);

  /// Todos los nombres por los que se busca y todos los textos. Para las
  /// pruebas: que esten bien escritos y sin huecos.
  static Iterable<(List<String>, String)> get entradas => [
    ..._glosario,
    ..._cultura,
    ..._gente,
    ..._lugares,
    ..._inventos,
    ..._formulas,
    ...CocinaMacias.entradas,
  ];

  // ======================================================== tabla periodica
  static const _tabla = <_Elemento>[
    (
      'hidrógeno',
      'H',
      1,
      'Es el elemento más liviano y el más abundante del universo.',
    ),
    ('helio', 'He', 2, 'Es el de los globos y el que pone la voz finita.'),
    (
      'litio',
      'Li',
      3,
      'Va en las baterías de tu celular, y Bolivia tiene una de las reservas más grandes del mundo, en el Salar de Uyuni.',
    ),
    ('berilio', 'Be', 4, ''),
    ('boro', 'B', 5, ''),
    (
      'carbono',
      'C',
      6,
      'Es la base de la vida: está en todos los seres vivos, en el grafito de tu lápiz y en los diamantes.',
    ),
    ('nitrógeno', 'N', 7, 'Es cerca del 78 % del aire que respiras.'),
    ('oxígeno', 'O', 8, 'Lo respiras: es cerca del 21 % del aire.'),
    ('flúor', 'F', 9, 'Está en la pasta de dientes.'),
    ('neón', 'Ne', 10, 'Es el de los letreros luminosos.'),
    ('sodio', 'Na', 11, 'Junto con el cloro forma la sal de mesa (NaCl).'),
    ('magnesio', 'Mg', 12, ''),
    ('aluminio', 'Al', 13, 'Es el de las latas.'),
    ('silicio', 'Si', 14, 'Con él se hacen los chips de las computadoras.'),
    ('fósforo', 'P', 15, ''),
    ('azufre', 'S', 16, ''),
    ('cloro', 'Cl', 17, 'Se usa para limpiar el agua de las piscinas.'),
    ('argón', 'Ar', 18, ''),
    ('potasio', 'K', 19, 'El plátano tiene bastante.'),
    ('calcio', 'Ca', 20, 'Está en tus huesos y en la leche.'),
    (
      'titanio',
      'Ti',
      22,
      'Es liviano y muy resistente: se usa en aviones y prótesis.',
    ),
    ('cromo', 'Cr', 24, ''),
    ('manganeso', 'Mn', 25, ''),
    (
      'hierro',
      'Fe',
      26,
      'Está en tu sangre (en la hemoglobina) y en el acero.',
    ),
    ('cobalto', 'Co', 27, ''),
    ('níquel', 'Ni', 28, ''),
    ('cobre', 'Cu', 29, 'Es el de los cables eléctricos.'),
    ('zinc', 'Zn', 30, 'Bolivia es un gran productor.'),
    (
      'bromo',
      'Br',
      35,
      'Es uno de los pocos elementos líquidos a temperatura ambiente.',
    ),
    ('plata', 'Ag', 47, 'La del Cerro Rico de Potosí.'),
    ('estaño', 'Sn', 50, 'Bolivia fue de los mayores productores del mundo.'),
    ('yodo', 'I', 53, 'Se agrega a la sal para cuidar la tiroides.'),
    (
      'wolframio',
      'W',
      74,
      'También se llama tungsteno: es el metal con el punto de fusión más alto.',
    ),
    ('platino', 'Pt', 78, ''),
    ('oro', 'Au', 79, 'Su símbolo viene del latín aurum.'),
    ('mercurio', 'Hg', 80, 'Es el único metal líquido a temperatura ambiente.'),
    ('plomo', 'Pb', 82, 'Su símbolo viene del latín plumbum. Es tóxico.'),
    ('uranio', 'U', 92, 'Se usa como combustible en las centrales nucleares.'),
  ];

  static String _textoElemento(_Elemento e) {
    final (nombre, simbolo, numero, dato) = e;
    return 'El **$nombre** tiene símbolo **$simbolo** y número atómico $numero.'
        '${dato.isEmpty ? '' : ' $dato'}';
  }

  static _Elemento? _porNombre(String nombre) {
    final buscado = nombre
        .replaceFirst(RegExp(r'^(?:el|la|elemento) '), '')
        .trim();
    for (final e in _tabla) {
      if (LenguajeMacias.normalizar(e.$1) == buscado) return e;
    }
    if (buscado == 'tungsteno') return _tabla.firstWhere((e) => e.$2 == 'W');
    return null;
  }

  static String? _elementoPorNombre(String nombre) {
    final e = _porNombre(nombre);
    return e == null ? null : _textoElemento(e);
  }

  static RespuestaCharla? _elemento(String t) {
    final simbolo = RegExp(
      r'^(?:cual es el |que es el )?simbolo (?:quimico )?(?:del |de la |de el |de )(.+)$',
    ).firstMatch(t);
    if (simbolo != null) {
      final e = _porNombre(simbolo[1]!);
      if (e != null) return _dicho(_textoElemento(e), 'saber:elemento');
    }
    final numero = RegExp(
      r'^(?:cual es el )?numero atomico (?:del |de la |de )(.+)$',
    ).firstMatch(t);
    if (numero != null) {
      final e = _porNombre(numero[1]!);
      if (e != null) return _dicho(_textoElemento(e), 'saber:elemento');
    }
    final cual = RegExp(
      r'^(?:que elemento es|cual elemento es|que elemento quimico es|'
      r'a que elemento corresponde|elemento) (?:el )?([a-z]{1,2})$',
    ).firstMatch(t);
    if (cual != null) {
      for (final e in _tabla) {
        if (e.$2.toLowerCase() == cual[1]) {
          return _dicho(_textoElemento(e), 'saber:elemento');
        }
      }
    }
    return null;
  }

  // ================================================================ formulas
  static const _formulas = <(List<String>, String)>[
    (
      ['area del circulo', 'area de un circulo'],
      '**Área del círculo**: A = π · r²',
    ),
    (
      [
        'perimetro del circulo',
        'longitud de la circunferencia',
        'circunferencia',
        'perimetro de un circulo',
      ],
      '**Perímetro del círculo** (circunferencia): P = 2 · π · r',
    ),
    (
      ['area del triangulo', 'area de un triangulo'],
      '**Área del triángulo**: A = base · altura / 2',
    ),
    (
      ['area del rectangulo', 'area de un rectangulo'],
      '**Área del rectángulo**: A = base · altura',
    ),
    (
      ['area del cuadrado', 'area de un cuadrado'],
      '**Área del cuadrado**: A = lado²',
    ),
    (
      ['area del trapecio'],
      '**Área del trapecio**: A = (B + b) · h / 2, con B y b las dos bases',
    ),
    (
      ['area del rombo'],
      '**Área del rombo**: A = D · d / 2, con D y d las diagonales',
    ),
    (
      ['area de la esfera', 'superficie de la esfera'],
      '**Área de la esfera**: A = 4 · π · r²',
    ),
    (['volumen del cubo'], '**Volumen del cubo**: V = lado³'),
    (['volumen de la esfera'], '**Volumen de la esfera**: V = (4/3) · π · r³'),
    (['volumen del cilindro'], '**Volumen del cilindro**: V = π · r² · h'),
    (['volumen del cono'], '**Volumen del cono**: V = (1/3) · π · r² · h'),
    (
      ['volumen del prisma', 'volumen de un prisma'],
      '**Volumen del prisma**: V = área de la base · altura',
    ),
    (
      ['volumen de la piramide'],
      '**Volumen de la pirámide**: V = (1/3) · área de la base · altura',
    ),
    (
      ['pitagoras', 'teorema de pitagoras', 'hipotenusa'],
      '**Teorema de Pitágoras**: a² + b² = c², donde c es la hipotenusa',
    ),
    (
      ['velocidad', 'rapidez', 'mru'],
      '**Velocidad** (movimiento uniforme): v = d / t',
    ),
    (['aceleracion'], '**Aceleración**: a = (v − v0) / t'),
    (
      [
        'mruv',
        'movimiento uniformemente acelerado',
        'movimiento rectilineo uniformemente variado',
      ],
      '**MRUV**: v = v0 + a · t, y d = v0 · t + ½ · a · t²',
    ),
    (
      ['caida libre'],
      '**Caída libre**: v = g · t, y h = ½ · g · t², con g ≈ 9,81 m/s²',
    ),
    (
      ['fuerza', 'segunda ley de newton'],
      '**Fuerza** (segunda ley de Newton): F = m · a',
    ),
    (['peso'], '**Peso**: P = m · g'),
    (['energia cinetica'], '**Energía cinética**: Ec = ½ · m · v²'),
    (
      ['energia potencial', 'energia potencial gravitatoria'],
      '**Energía potencial**: Ep = m · g · h',
    ),
    (['trabajo'], '**Trabajo**: W = F · d (fuerza por distancia)'),
    (['potencia'], '**Potencia**: P = W / t (trabajo entre tiempo), en watts'),
    (['densidad'], '**Densidad**: d = m / V'),
    (['presion'], '**Presión**: P = F / A'),
    (
      ['ley de ohm', 'voltaje', 'corriente', 'resistencia'],
      '**Ley de Ohm**: V = I · R',
    ),
    (['potencia electrica'], '**Potencia eléctrica**: P = V · I'),
    (
      ['interes simple'],
      '**Interés simple**: I = C · i · t (capital, tasa y tiempo)',
    ),
    (['interes compuesto'], '**Interés compuesto**: M = C · (1 + i)^n'),
    (
      ['pendiente', 'pendiente de una recta'],
      '**Pendiente**: m = (y2 − y1) / (x2 − x1)',
    ),
    (
      ['distancia entre dos puntos'],
      '**Distancia entre dos puntos**: d = √((x2 − x1)² + (y2 − y1)²)',
    ),
    (['punto medio'], '**Punto medio**: M = ((x1 + x2) / 2, (y1 + y2) / 2)'),
    (
      ['ecuacion de la recta', 'recta'],
      '**Ecuación de la recta**: y = m · x + b (m es la pendiente, b donde corta al eje y)',
    ),
    (
      ['promedio', 'media'],
      '**Promedio**: la suma de los datos dividida entre cuántos son. Escríbeme **promedio de** y tus notas, y lo saco.',
    ),
    (
      ['porcentaje'],
      '**Porcentaje**: parte / total × 100. Escríbeme, por ejemplo, **15% de 200**.',
    ),
    (['imc', 'indice de masa corporal'], '**IMC**: peso (kg) / estatura² (m)'),
    (
      ['formula general', 'cuadratica', 'ecuacion cuadratica'],
      '**Fórmula general**: x = (−b ± √(b² − 4ac)) / 2a. Escríbeme la ecuación y la resuelvo paso a paso.',
    ),
  ];

  static final Map<String, String> _indiceFormulas = {
    for (final (nombres, texto) in _formulas)
      for (final nombre in nombres) nombre: texto,
  };

  static RespuestaCharla? _formula(String t) {
    final pedido =
        RegExp(
          r'^(?:cual es la |dame la |dime la )?(?:formula|ecuacion) '
          r'(?:de |del |de la |de los |para |para el |para la )'
          r'(?:calcular |sacar )?(?:el |la |los |las |un |una )?(.+)$',
        ).firstMatch(t) ??
        RegExp(
          r'^como (?:se calcula|calculo|se saca|saco|calcular|sacar|'
          r'se obtiene|obtengo) (?:el |la |los |las |un |una )?(.+)$',
        ).firstMatch(t);
    if (pedido == null) return null;
    final texto = _buscar(_indiceFormulas, pedido[1]!.trim());
    return texto == null ? null : _dicho(texto, 'saber:formula');
  }

  // =================================================================== paises
  static const _paises = <String, _Pais>{
    'argentina': (
      'Argentina',
      'el peso argentino',
      'el español',
      'en el sur de Sudamérica',
    ),
    'brasil': (
      'Brasil',
      'el real',
      'el portugués',
      'en Sudamérica: es el país más grande de la región',
    ),
    'chile': (
      'Chile',
      'el peso chileno',
      'el español',
      'en el oeste de Sudamérica, entre los Andes y el Pacífico',
    ),
    'colombia': (
      'Colombia',
      'el peso colombiano',
      'el español',
      'en el norte de Sudamérica',
    ),
    'ecuador': (
      'Ecuador',
      'el dólar estadounidense',
      'el español',
      'en el noroeste de Sudamérica, sobre la línea del ecuador',
    ),
    'paraguay': (
      'Paraguay',
      'el guaraní',
      'el español y el guaraní',
      'en el centro de Sudamérica, junto a Bolivia',
    ),
    'peru': (
      'Perú',
      'el sol',
      'el español (también el quechua y el aimara)',
      'en el oeste de Sudamérica, junto a Bolivia',
    ),
    'uruguay': (
      'Uruguay',
      'el peso uruguayo',
      'el español',
      'en el sureste de Sudamérica',
    ),
    'venezuela': (
      'Venezuela',
      'el bolívar',
      'el español',
      'en el norte de Sudamérica',
    ),
    'mexico': (
      'México',
      'el peso mexicano',
      'el español',
      'en Norteamérica, al sur de Estados Unidos',
    ),
    'cuba': ('Cuba', 'el peso cubano', 'el español', 'en el mar Caribe'),
    'panama': (
      'Panamá',
      'el balboa (y el dólar estadounidense)',
      'el español',
      'en Centroamérica, donde está el canal',
    ),
    'costa rica': ('Costa Rica', 'el colón', 'el español', 'en Centroamérica'),
    'guatemala': ('Guatemala', 'el quetzal', 'el español', 'en Centroamérica'),
    'honduras': ('Honduras', 'el lempira', 'el español', 'en Centroamérica'),
    'nicaragua': ('Nicaragua', 'el córdoba', 'el español', 'en Centroamérica'),
    'el salvador': (
      'El Salvador',
      'el dólar estadounidense',
      'el español',
      'en Centroamérica',
    ),
    'republica dominicana': (
      'República Dominicana',
      'el peso dominicano',
      'el español',
      'en el mar Caribe',
    ),
    'estados unidos': (
      'Estados Unidos',
      'el dólar',
      'el inglés',
      'en Norteamérica',
    ),
    'eeuu': ('Estados Unidos', 'el dólar', 'el inglés', 'en Norteamérica'),
    'usa': ('Estados Unidos', 'el dólar', 'el inglés', 'en Norteamérica'),
    'canada': (
      'Canadá',
      'el dólar canadiense',
      'el inglés y el francés',
      'en el norte de Norteamérica',
    ),
    'espana': ('España', 'el euro', 'el español', 'en el sur de Europa'),
    'francia': ('Francia', 'el euro', 'el francés', 'en Europa occidental'),
    'alemania': ('Alemania', 'el euro', 'el alemán', 'en el centro de Europa'),
    'italia': ('Italia', 'el euro', 'el italiano', 'en el sur de Europa'),
    'portugal': (
      'Portugal',
      'el euro',
      'el portugués',
      'en el suroeste de Europa',
    ),
    'reino unido': (
      'el Reino Unido',
      'la libra esterlina',
      'el inglés',
      'en el noroeste de Europa',
    ),
    'inglaterra': (
      'Inglaterra',
      'la libra esterlina',
      'el inglés',
      'en el Reino Unido, en el noroeste de Europa',
    ),
    'suiza': (
      'Suiza',
      'el franco suizo',
      'el alemán, el francés, el italiano y el romanche',
      'en el centro de Europa',
    ),
    'rusia': (
      'Rusia',
      'el rublo',
      'el ruso',
      'entre Europa y Asia: es el país más grande del mundo',
    ),
    'china': ('China', 'el yuan', 'el chino mandarín', 'en el este de Asia'),
    'japon': (
      'Japón',
      'el yen',
      'el japonés',
      'en el este de Asia, en unas islas del Pacífico',
    ),
    'corea del sur': (
      'Corea del Sur',
      'el won',
      'el coreano',
      'en el este de Asia',
    ),
    'india': (
      'India',
      'la rupia',
      'el hindi y el inglés, entre muchos otros',
      'en el sur de Asia',
    ),
    'australia': (
      'Australia',
      'el dólar australiano',
      'el inglés',
      'en Oceanía',
    ),
    'egipto': (
      'Egipto',
      'la libra egipcia',
      'el árabe',
      'en el noreste de África',
    ),
    'marruecos': (
      'Marruecos',
      'el dírham',
      'el árabe y el bereber',
      'en el norte de África',
    ),
    'sudafrica': (
      'Sudáfrica',
      'el rand',
      'once idiomas oficiales, entre ellos el inglés y el zulú',
      'en el sur de África',
    ),
    'turquia': ('Turquía', 'la lira turca', 'el turco', 'entre Europa y Asia'),
  };

  static RespuestaCharla? _pais(String t) {
    final moneda = RegExp(
      r'^(?:cual es la |que )?moneda (?:de |del |usa |usan |tiene |hay en |'
      r'se usa en |en |oficial de )(.+?)(?: usan| tiene)?$',
    ).firstMatch(t);
    if (moneda != null) {
      final pais = _paises[_sinArticulo(moneda[1]!)];
      if (pais != null) {
        return _dicho('En ${pais.$1} se usa **${pais.$2}**.', 'saber:pais');
      }
    }
    final idioma =
        RegExp(
          r'^(?:cual es el |que )?idiomas? (?:de |del |se habla en |se hablan en |'
          r'hablan en |habla |en |oficial de |oficiales de )(.+)$',
        ).firstMatch(t) ??
        RegExp(r'^que (?:se )?hablan? en (.+)$').firstMatch(t);
    if (idioma != null) {
      final pais = _paises[_sinArticulo(idioma[1]!)];
      if (pais != null) {
        return _dicho('En ${pais.$1} se habla **${pais.$3}**.', 'saber:pais');
      }
    }
    final donde = RegExp(
      r'^(?:donde|en donde|en que continente) (?:queda|esta) (.+)$',
    ).firstMatch(t);
    if (donde != null) {
      final pais = _paises[_sinArticulo(donde[1]!)];
      if (pais != null) {
        return _dicho(
          '${LenguajeMacias.conMayuscula(pais.$1)} está ${pais.$4}.',
          'saber:pais',
        );
      }
    }
    return null;
  }

  static String _sinArticulo(String texto) =>
      texto.trim().replaceFirst(RegExp(r'^(?:el|la|los|las) '), '');

  // ================================================================ glosario
  static const _glosario = <_Entrada>[
    // ----------------------------------------------------------- matematica
    (
      ['numero primo', 'numeros primos'],
      'Un **número primo** solo se divide exacto entre 1 y entre sí mismo: 2, 3, 5, 7, 11, 13... El 2 es el único primo par, y el 1 no cuenta como primo.',
    ),
    (
      ['numero par', 'numeros pares', 'numero impar', 'numeros impares'],
      'Un número es **par** si se divide exacto entre 2 (termina en 0, 2, 4, 6 u 8). Los **impares** no: terminan en 1, 3, 5, 7 o 9.',
    ),
    (
      ['fraccion', 'fracciones', 'quebrado', 'quebrados'],
      'Una **fracción** es una parte de un entero: a/b significa "a partes de un total dividido en b". El de arriba es el numerador y el de abajo, el denominador (que nunca puede ser 0).',
    ),
    (
      ['porcentaje', 'porcentajes', 'por ciento'],
      'Un **porcentaje** es una fracción sobre 100: 25 % es 25/100, o sea, la cuarta parte. El 15 % de 200 es 200 × 15 / 100 = 30. (Escríbeme **15% de 200** y lo calculo.)',
    ),
    (
      ['ecuacion', 'ecuaciones'],
      'Una **ecuación** es una igualdad con una incógnita que hay que encontrar: 2x + 3 = 11 solo se cumple si x = 4. Escríbeme una y la resuelvo paso a paso.',
    ),
    (
      ['inecuacion', 'inecuaciones', 'desigualdad', 'desigualdades'],
      'Una **inecuación** es como una ecuación pero con <, >, ≤ o ≥: la solución no es un valor sino un intervalo. Ojo: si multiplicas o divides por un negativo, el signo se da vuelta.',
    ),
    (
      ['dominio', 'dominio de una funcion'],
      'El **dominio** de una función son todos los valores de x que puedes meterle sin romper nada: sin dividir entre cero ni sacar raíz de un negativo (en los reales).',
    ),
    (
      ['rango', 'recorrido', 'imagen de una funcion', 'rango de una funcion'],
      'El **rango** (o recorrido) de una función son todos los valores que puede dar: lo que sale, no lo que entra.',
    ),
    (
      ['limite', 'limites', 'limite de una funcion', 'limite matematico'],
      'El **límite** es el valor al que se acerca una función cuando x se acerca a un número, aunque nunca llegue a tocarlo. Es la base del cálculo: con límites se definen la derivada y la integral.',
    ),
    (
      ['derivada', 'derivadas'],
      'La **derivada** mide qué tan rápido cambia una función: es la pendiente de la recta tangente en cada punto. La derivada de x² es 2x. Escríbeme **derivada de** y una función, y la calculo.',
    ),
    (
      ['regla de la cadena'],
      'La **regla de la cadena** sirve para derivar una función compuesta: si y = f(g(x)), entonces y\' = f\'(g(x)) · g\'(x). Ejemplo: (3x + 1)² se deriva como 2(3x + 1) · 3 = 6(3x + 1).',
    ),
    (
      ['calculo diferencial'],
      'El **cálculo diferencial** estudia cómo cambian las cosas: límites y derivadas. El cálculo integral (el de mis temas) es su compañero inseparable.',
    ),
    (
      ['matriz', 'matrices'],
      'Una **matriz** es una tabla de números en filas y columnas. Sirve para resolver sistemas de ecuaciones, transformar gráficos y mucho más. Una de 2 × 2 tiene 2 filas y 2 columnas.',
    ),
    (
      ['determinante', 'determinantes'],
      'El **determinante** es un número que sale de una matriz cuadrada. En una de 2 × 2, con filas (a, b) y (c, d), vale a·d − b·c. Si da 0, la matriz no tiene inversa.',
    ),
    (
      ['vector en fisica', 'vector matematico', 'vectores en fisica'],
      'Un **vector** es una cantidad con tamaño y dirección, como una flecha: la velocidad o la fuerza son vectores; la temperatura no.',
    ),
    (
      [
        'trigonometria',
        'seno',
        'coseno',
        'tangente',
        'funciones trigonometricas',
        'razones trigonometricas',
      ],
      'En un triángulo rectángulo: **seno** = opuesto / hipotenusa, **coseno** = adyacente / hipotenusa y **tangente** = opuesto / adyacente. El truco para no olvidarlo: "SOH-CAH-TOA".',
    ),
    (
      ['teorema de pitagoras'],
      'El **teorema de Pitágoras** dice que en un triángulo rectángulo a² + b² = c²: la suma de los cuadrados de los catetos es igual al cuadrado de la hipotenusa. Con catetos 3 y 4, la hipotenusa es 5.',
    ),
    (
      ['probabilidad', 'probabilidades'],
      'La **probabilidad** es qué tan posible es que pase algo, de 0 (imposible) a 1 (seguro): casos favorables / casos posibles. Sacar un 6 con un dado es 1/6, más o menos 0,17.',
    ),
    (
      ['estadistica'],
      'La **estadística** junta, ordena y analiza datos para sacar conclusiones: promedios, gráficos, tendencias y qué tan confiable es un resultado.',
    ),
    (
      ['media', 'promedio', 'media aritmetica'],
      'La **media** (o promedio) es la suma de los datos dividida entre cuántos son. Escríbeme **promedio de** y tus notas, y lo saco.',
    ),
    (
      ['mediana'],
      'La **mediana** es el dato del medio cuando los ordenas de menor a mayor. A diferencia del promedio, no se deja llevar por un valor extremo.',
    ),
    (
      ['moda', 'moda en estadistica'],
      'En estadística, la **moda** es el dato que más se repite. (Si hablabas de ropa, en U market hay toda una categoría.)',
    ),
    (
      ['desviacion estandar', 'desviacion tipica'],
      'La **desviación estándar** mide qué tan dispersos están los datos respecto al promedio: chica, todos cerca; grande, desparramados.',
    ),
    (
      ['varianza'],
      'La **varianza** es el promedio de las distancias al cuadrado de cada dato a la media. Su raíz cuadrada es la desviación estándar.',
    ),
    (
      ['factorial'],
      'El **factorial** de n (n!) es multiplicar todos los enteros de 1 a n: 5! = 5 · 4 · 3 · 2 · 1 = 120. Por definición, 0! = 1.',
    ),
    (
      [
        'permutacion',
        'permutaciones',
        'combinacion',
        'combinaciones',
        'combinatoria',
      ],
      'En una **permutación** importa el orden; en una **combinación**, no. De 5 personas puedes elegir 3 en 10 grupos distintos (combinaciones), pero ordenarlas de 60 formas (permutaciones).',
    ),
    (
      ['polinomio', 'polinomios', 'monomio', 'binomio', 'trinomio'],
      'Un **polinomio** es una suma de términos con potencias enteras de x, como 3x² − 5x + 2. Con un término es monomio, con dos binomio y con tres trinomio. Escríbeme **factoriza** y uno, y lo factorizo.',
    ),
    (
      ['raiz cuadrada'],
      'La **raíz cuadrada** de un número es otro que, multiplicado por sí mismo, da el primero: √49 = 7, porque 7 · 7 = 49.',
    ),
    (
      ['potencia'],
      'En matemática, una **potencia** es multiplicar un número por sí mismo varias veces: 2³ = 2 · 2 · 2 = 8. En física, potencia es cuánto trabajo se hace por segundo, y se mide en watts.',
    ),
    (
      ['numero irracional', 'numeros irracionales'],
      'Un **número irracional** no se puede escribir como fracción: sus decimales nunca terminan ni se repiten. Por ejemplo π, √2 y e.',
    ),
    (
      [
        'numero complejo',
        'numeros complejos',
        'numero imaginario',
        'numeros imaginarios',
      ],
      'Un **número complejo** tiene la forma a + bi, donde i es la unidad imaginaria: i² = −1. Aparecen, por ejemplo, cuando una ecuación de segundo grado tiene discriminante negativo.',
    ),
    (
      ['infinito'],
      'El **infinito** no es un número, es una idea: algo que no tiene fin. Y hay infinitos más grandes que otros: hay "más" números reales que naturales.',
    ),
    (
      ['angulo', 'angulos'],
      'Un **ángulo** es la abertura entre dos rectas que se cruzan. Se mide en grados (una vuelta son 360°) o en radianes (una vuelta son 2π).',
    ),
    (
      ['perimetro'],
      'El **perímetro** es la medida del borde de una figura: la suma de sus lados. En un círculo se llama circunferencia y vale 2πr.',
    ),
    (
      ['radio', 'diametro'],
      'El **radio** va del centro del círculo al borde; el **diámetro** lo cruza de lado a lado pasando por el centro, así que mide el doble.',
    ),
    (
      ['hipotenusa', 'cateto', 'catetos'],
      'En un triángulo rectángulo, la **hipotenusa** es el lado más largo, el que está frente al ángulo recto. Los otros dos son los **catetos**.',
    ),
    (
      ['pendiente', 'pendiente de una recta'],
      'La **pendiente** dice qué tan inclinada está una recta: m = (y2 − y1) / (x2 − x1). Positiva sube, negativa baja, cero es horizontal.',
    ),
    (
      ['plano cartesiano'],
      'El **plano cartesiano** son dos rectas que se cruzan en el (0, 0): el eje x (horizontal) y el eje y (vertical). Cada punto se ubica con un par (x, y).',
    ),
    (
      ['conjunto', 'conjuntos'],
      'Un **conjunto** es una colección de elementos, como {1, 2, 3}. Con conjuntos se hacen uniones, intersecciones y diferencias.',
    ),
    (
      ['geometria'],
      'La **geometría** es la rama de la matemática que estudia las formas: puntos, rectas, ángulos, figuras y cuerpos, con sus medidas.',
    ),
    (
      ['aritmetica'],
      'La **aritmética** es la parte más básica de la matemática: sumar, restar, multiplicar y dividir números.',
    ),
    // --------------------------------------------------------------- fisica
    (
      ['fuerza'],
      'Una **fuerza** es un empujón o un tirón: cambia el movimiento de algo. Se mide en newtons (N) y, según Newton, F = m · a.',
    ),
    (
      ['masa'],
      'La **masa** es la cantidad de materia de un cuerpo; se mide en kilos. No cambia aunque vayas a la Luna (el peso sí).',
    ),
    (
      ['peso'],
      'El **peso** es la fuerza con la que la gravedad atrae a un cuerpo: P = m · g. En la Luna pesarías la sexta parte, pero tu masa sería la misma.',
    ),
    (
      ['velocidad', 'rapidez'],
      'La **velocidad** es cuánta distancia recorres por unidad de tiempo (con dirección incluida): v = d / t. Por ejemplo, 100 km en 2 horas son 50 km/h.',
    ),
    (
      ['aceleracion'],
      'La **aceleración** es qué tan rápido cambia la velocidad: a = (v − v0) / t. Se mide en m/s².',
    ),
    (
      ['gravedad'],
      'La **gravedad** es la atracción entre cuerpos con masa: es lo que te mantiene en el piso. En la Tierra acelera las cosas a unos 9,81 m/s².',
    ),
    (
      ['energia'],
      'La **energía** es la capacidad de hacer un trabajo. No se crea ni se destruye: solo se transforma (de eléctrica a luz, de química a movimiento...). Se mide en joules.',
    ),
    (
      ['energia cinetica'],
      'La **energía cinética** es la del movimiento: Ec = ½ · m · v². Si duplicas la velocidad, la energía se cuadruplica.',
    ),
    (
      ['energia potencial'],
      'La **energía potencial** es la guardada por la posición. La gravitatoria es Ep = m · g · h: cuanto más alto, más energía.',
    ),
    (
      ['trabajo en fisica', 'trabajo mecanico', 'trabajo'],
      'En física, **trabajo** es fuerza por distancia: W = F · d, en joules. (Si buscabas trabajo de verdad, vender en U market es un buen comienzo.)',
    ),
    (
      ['presion'],
      'La **presión** es fuerza repartida en un área: P = F / A. Por eso un cuchillo afilado corta mejor: la misma fuerza en menos área.',
    ),
    (
      ['densidad'],
      'La **densidad** es cuánta masa hay en cierto volumen: d = m / V. El agua tiene 1 g/cm³, y lo que es menos denso que ella, flota.',
    ),
    (
      ['temperatura'],
      'La **temperatura** mide qué tan rápido se mueven las partículas de algo: más movimiento, más caliente. Se mide en °C, °F o kelvin.',
    ),
    (
      ['calor'],
      'El **calor** es energía que pasa de lo caliente a lo frío. No es lo mismo que temperatura: una piscina tibia tiene más calor total que una taza hirviendo.',
    ),
    (
      ['electricidad'],
      'La **electricidad** es el movimiento de cargas eléctricas (electrones) por un material. Con ella prendes la luz, cargas el celular y funciona todo lo demás.',
    ),
    (
      ['corriente electrica', 'intensidad de corriente', 'amperio', 'amperios'],
      'La **corriente eléctrica** es la cantidad de carga que pasa por un cable cada segundo. Se mide en amperios (A).',
    ),
    (
      [
        'voltaje',
        'tension electrica',
        'diferencia de potencial',
        'voltio',
        'voltios',
      ],
      'El **voltaje** es el "empuje" que mueve a los electrones por un circuito. Se mide en voltios (V).',
    ),
    (
      ['resistencia electrica', 'ohmio', 'ohmios'],
      'La **resistencia** es cuánto le cuesta a la corriente pasar por un material. Se mide en ohmios.',
    ),
    (
      ['ley de ohm'],
      'La **ley de Ohm**: V = I · R. El voltaje es igual a la corriente por la resistencia; si sabes dos, sacas la tercera.',
    ),
    (
      [
        'leyes de newton',
        'ley de newton',
        'primera ley de newton',
        'segunda ley de newton',
        'tercera ley de newton',
        'inercia',
        'accion y reaccion',
      ],
      'Las **leyes de Newton**:\n1. **Inercia**: un cuerpo sigue quieto o moviéndose en línea recta si nada lo empuja.\n2. **F = m · a**: más fuerza, más aceleración; más masa, menos.\n3. **Acción y reacción**: si empujas una pared, la pared te empuja igual.',
    ),
    (
      [
        'e mc',
        'e mc2',
        'e mc 2',
        'e igual mc',
        'relatividad',
        'teoria de la relatividad',
      ],
      '**E = mc²** (Einstein): la masa y la energía son lo mismo en distinto formato, y un poquito de masa equivale a muchísima energía, porque c, la velocidad de la luz, es enorme.',
    ),
    (
      ['luz'],
      'La **luz** es una onda electromagnética. En el vacío viaja a casi 300 000 km por segundo: del Sol a la Tierra tarda unos 8 minutos.',
    ),
    (
      ['sonido'],
      'El **sonido** es una vibración que viaja por el aire (o por el agua, o por los sólidos). En el aire va a unos 343 m/s, y en el vacío no se propaga.',
    ),
    (
      ['onda', 'ondas', 'frecuencia', 'hertz', 'hercio'],
      'Una **onda** transporta energía sin transportar materia. Su **frecuencia** es cuántas oscilaciones hace por segundo, y se mide en hertz (Hz).',
    ),
    (
      ['friccion', 'rozamiento'],
      'La **fricción** es la fuerza que frena cuando dos superficies se rozan. Sin ella no podrías ni caminar.',
    ),
    (
      ['cantidad de movimiento', 'momento lineal', 'impulso'],
      'La **cantidad de movimiento** es p = m · v. En un choque, la total se conserva: lo que pierde uno lo gana el otro.',
    ),
    (
      ['newton'],
      'El **newton** (N) es la unidad de fuerza: lo que hace falta para acelerar 1 kg a 1 m/s². Se llama así por Isaac Newton.',
    ),
    // -------------------------------------------------------------- quimica
    (
      ['atomo', 'atomos'],
      'El **átomo** es la pieza más chica de un elemento: un núcleo con protones y neutrones, y electrones alrededor. En un grano de sal hay trillones.',
    ),
    (
      ['molecula', 'moleculas'],
      'Una **molécula** son dos o más átomos unidos. El agua, por ejemplo, es H2O: dos de hidrógeno y uno de oxígeno.',
    ),
    (
      ['electron', 'electrones', 'proton', 'protones', 'neutron', 'neutrones'],
      'Los **protones** (carga +) y los **neutrones** (sin carga) forman el núcleo del átomo; los **electrones** (carga −) se mueven alrededor. El número de protones define qué elemento es.',
    ),
    (
      ['elemento quimico', 'elementos quimicos', 'elemento', 'elementos'],
      'Un **elemento** es una sustancia hecha de un solo tipo de átomo, como el oxígeno, el hierro o el oro. Hay 118 conocidos, ordenados en la tabla periódica. Pregúntame por uno: **símbolo del oro**.',
    ),
    (
      ['compuesto', 'compuesto quimico', 'compuestos'],
      'Un **compuesto** es una sustancia formada por dos o más elementos unidos químicamente, como el agua (H2O) o la sal de mesa (NaCl).',
    ),
    (
      ['tabla periodica'],
      'La **tabla periódica** ordena los 118 elementos por su número atómico, y los de una misma columna se comportan parecido. Pregúntame por uno: **símbolo del hierro** o **qué elemento es Au**.',
    ),
    (
      [
        'enlace quimico',
        'enlace ionico',
        'enlace covalente',
        'enlaces quimicos',
      ],
      'Un **enlace químico** es lo que mantiene unidos a los átomos. En el iónico, uno le pasa electrones al otro (como en la sal); en el covalente, los comparten (como en el agua).',
    ),
    (
      ['acido', 'acidos', 'base quimica', 'bases quimicas'],
      'Los **ácidos** tienen pH menor que 7 (el limón, el vinagre) y las **bases**, mayor que 7 (el jabón, la lejía). Al mezclarlos se neutralizan.',
    ),
    (
      ['ph'],
      'El **pH** mide qué tan ácido o básico es algo, en una escala de 0 a 14. El 7 es neutro, como el agua pura.',
    ),
    (
      ['reaccion quimica', 'reacciones quimicas'],
      'Una **reacción química** es cuando unas sustancias se transforman en otras nuevas: al quemar madera, al oxidarse un clavo o al cocinar.',
    ),
    (
      ['mol'],
      'El **mol** es una cantidad: 6,022 × 10^23 partículas (el número de Avogadro). Como decir "una docena", pero gigantesca.',
    ),
    (
      ['oxidacion'],
      'La **oxidación** es cuando una sustancia pierde electrones, muchas veces al reaccionar con el oxígeno. El óxido del hierro y una manzana cortada que se pone marrón son ejemplos.',
    ),
    (
      ['agua', 'h2o'],
      'El **agua** es H2O: dos átomos de hidrógeno y uno de oxígeno. A nivel del mar hierve a 100 °C y se congela a 0 °C (en Potosí, por la altura, hierve antes).',
    ),
    (
      ['co2', 'dioxido de carbono'],
      'El **CO2** (dióxido de carbono) es el gas que exhalas y que las plantas usan en la fotosíntesis. En exceso en la atmósfera, calienta el planeta.',
    ),
    // ------------------------------------------------------------- biologia
    (
      ['celula', 'celulas'],
      'La **célula** es la unidad básica de la vida: todo ser vivo está hecho de una o de muchas. Tiene membrana, citoplasma y material genético (ADN).',
    ),
    (
      ['adn', 'acido desoxirribonucleico'],
      'El **ADN** es la molécula que guarda las instrucciones de cada ser vivo, como un manual escrito con cuatro letras: A, T, C y G. Tiene forma de doble hélice.',
    ),
    (
      ['arn'],
      'El **ARN** es como una copia de trabajo del ADN: lleva las instrucciones al lugar donde se fabrican las proteínas.',
    ),
    (
      ['gen', 'genes'],
      'Un **gen** es un pedazo de ADN con las instrucciones para algo concreto, como fabricar una proteína. Los heredas de tus papás.',
    ),
    (
      ['cromosoma', 'cromosomas'],
      'Un **cromosoma** es ADN enrollado y ordenado. Los humanos tenemos 46 en cada célula (23 pares).',
    ),
    (
      ['fotosintesis'],
      'La **fotosíntesis** es el proceso con el que las plantas usan la luz del sol, el agua y el CO2 del aire para fabricar su alimento (glucosa) y soltar oxígeno. Gracias a eso respiramos.',
    ),
    (
      ['respiracion celular'],
      'La **respiración celular** es cómo las células sacan energía de la comida: usan glucosa y oxígeno, y sueltan CO2 y agua. Es como la fotosíntesis al revés.',
    ),
    (
      ['mitosis'],
      'La **mitosis** es la división de una célula en dos células hijas idénticas. Así creces y reparas tejidos.',
    ),
    (
      ['meiosis'],
      'La **meiosis** es la división que produce las células sexuales (óvulos y espermatozoides), con la mitad de los cromosomas. Por eso cada hijo mezcla genes de mamá y papá.',
    ),
    (
      ['evolucion', 'seleccion natural', 'teoria de la evolucion'],
      'La **evolución**: las especies cambian con el tiempo. Los que tienen rasgos que les ayudan a sobrevivir dejan más descendencia, y esos rasgos se vuelven comunes. Lo explicó Charles Darwin.',
    ),
    (
      ['ecosistema', 'ecosistemas'],
      'Un **ecosistema** es un conjunto de seres vivos y el lugar donde viven, con todo lo que se relacionan: un bosque, un lago, incluso un charco.',
    ),
    (
      ['virus'],
      'Un **virus** es un parásito diminuto que solo se multiplica dentro de una célula. Los antibióticos no le hacen nada: eso es para las bacterias.',
    ),
    (
      ['bacteria', 'bacterias'],
      'Las **bacterias** son seres vivos de una sola célula. Muchas son útiles (como las del yogur o las de tu intestino); algunas causan enfermedades, y contra esas sirven los antibióticos.',
    ),
    (
      ['antibiotico', 'antibioticos'],
      'Los **antibióticos** son medicamentos que matan bacterias o frenan su crecimiento. Contra los virus (como la gripe) no sirven, y siempre van con receta.',
    ),
    (
      ['proteina', 'proteinas'],
      'Las **proteínas** hacen casi todo el trabajo en tu cuerpo: músculos, enzimas, anticuerpos. Las armas con aminoácidos de la comida, como la carne, el huevo o las legumbres.',
    ),
    (
      ['enzima', 'enzimas'],
      'Las **enzimas** son proteínas que aceleran reacciones químicas en el cuerpo, como las de la digestión.',
    ),
    (
      ['metabolismo'],
      'El **metabolismo** son todas las reacciones químicas que hace tu cuerpo para sacar energía y construir lo que necesita.',
    ),
    (
      ['neurona', 'neuronas'],
      'Las **neuronas** son las células del sistema nervioso: se pasan mensajes eléctricos y químicos. Tu cerebro tiene unos 86 mil millones.',
    ),
    (
      ['sistema inmunologico', 'sistema inmune', 'defensas'],
      'El **sistema inmune** son tus defensas: células y anticuerpos que reconocen y atacan virus y bacterias.',
    ),
    (
      ['vacuna', 'vacunas'],
      'Una **vacuna** le enseña a tu sistema inmune a reconocer un virus o una bacteria sin que te enfermes, para que si llega de verdad, ya sepa cómo pelear.',
    ),
    (
      ['mitocondria', 'mitocondrias'],
      'La **mitocondria** es la central de energía de la célula: ahí se hace la respiración celular. Sí, la famosa "fuerza de la célula".',
    ),
    // ---------------------------------------------------------- informatica
    (
      ['algoritmo', 'algoritmos'],
      'Un **algoritmo** es una lista de pasos ordenados para resolver un problema, como una receta. Todo programa es, en el fondo, un algoritmo. La palabra viene de Al-Juarismi, el de la portada del Baldor.',
    ),
    (
      ['programa', 'software'],
      'Un **programa** (o software) es un conjunto de instrucciones que le dice a la computadora qué hacer. Las apps, como U market, son programas.',
    ),
    (
      ['hardware'],
      'El **hardware** son las partes físicas de una computadora, lo que puedes tocar: procesador, memoria, pantalla, teclado. El software es lo que corre encima.',
    ),
    (
      ['compilador'],
      'Un **compilador** traduce tu código (por ejemplo, en C++) a lenguaje de máquina, para que la computadora lo pueda ejecutar.',
    ),
    (
      ['interprete'],
      'Un **intérprete** ejecuta el código línea por línea, sin traducirlo todo antes. Python y JavaScript suelen funcionar así.',
    ),
    (
      ['recursion', 'recursividad', 'funcion recursiva'],
      'La **recursión** es cuando una función se llama a sí misma para resolver una versión más chica del problema. Necesita un caso base para cortar: si no, se repite hasta reventar.',
    ),
    (
      ['base de datos', 'bases de datos'],
      'Una **base de datos** es donde una app guarda su información ordenada para buscarla rápido. U market, por ejemplo, guarda ahí las publicaciones y los pedidos.',
    ),
    (
      ['sql'],
      '**SQL** es el lenguaje para pedirle cosas a una base de datos. Por ejemplo, SELECT nombre FROM productos WHERE precio < 10 trae los productos baratos.',
    ),
    (
      ['api'],
      'Depende: el **api** de Bolivia es una bebida caliente de maíz morado, perfecta con un pastel o un buñuelo. En programación, una **API** es la forma en que un programa le pide cosas a otro, como pedir un plato por la ventanilla sin entrar a la cocina.',
    ),
    (
      ['html'],
      '**HTML** es el lenguaje con el que se arma la estructura de una página web: títulos, párrafos, imágenes, botones. El estilo lo pone CSS, y el comportamiento, JavaScript.',
    ),
    (
      ['css'],
      '**CSS** es el lenguaje que le da estilo a una página web: colores, tamaños, posiciones y animaciones.',
    ),
    (
      ['javascript', 'js'],
      '**JavaScript** es el lenguaje de programación de las páginas web: hace que respondan a lo que tocas. No tiene nada que ver con Java, aunque el nombre confunda.',
    ),
    (
      ['python'],
      '**Python** es un lenguaje de programación famoso por ser fácil de leer. Se usa muchísimo en ciencia de datos, inteligencia artificial y automatización.',
    ),
    (
      ['java'],
      '**Java** es un lenguaje de programación orientado a objetos, muy usado en empresas y en apps de Android.',
    ),
    (
      ['dart', 'flutter'],
      '**Dart** es el lenguaje y **Flutter** la herramienta de Google para hacer apps para Android, iPhone y web con el mismo código. Yo estoy hecho con eso, igual que U market.',
    ),
    (
      ['git', 'github'],
      '**Git** guarda la historia de los cambios de un proyecto de código, para volver atrás o trabajar en equipo sin pisarse. **GitHub** es una página donde se suben esos proyectos.',
    ),
    (
      ['servidor', 'servidores'],
      'Un **servidor** es una computadora que atiende pedidos de otras: cuando abres una página, un servidor te manda lo que ves.',
    ),
    (
      ['la nube', 'nube', 'cloud'],
      '**La nube** son servidores de otras empresas donde guardas archivos o corres programas por internet, en vez de en tu compu. (Las nubes del cielo son vapor de agua, eso sí.)',
    ),
    (
      ['internet'],
      '**Internet** es una red mundial de computadoras conectadas que se pasan información. La web, el correo y WhatsApp funcionan sobre internet.',
    ),
    (
      ['direccion ip', 'ip'],
      'Una **dirección IP** es la dirección de un aparato en una red: como el número de casa de tu compu en internet.',
    ),
    (
      ['dns'],
      'El **DNS** es la agenda de internet: traduce nombres como google.com a la dirección IP del servidor.',
    ),
    (
      ['sistema operativo', 'sistemas operativos'],
      'El **sistema operativo** es el programa base que maneja la computadora o el celular y deja correr a los demás: Windows, Linux, macOS, Android, iOS.',
    ),
    (
      ['linux'],
      '**Linux** es un sistema operativo libre y gratuito. Corre en la mayoría de los servidores de internet, y Android está construido sobre su núcleo.',
    ),
    (
      ['android'],
      '**Android** es el sistema operativo de Google para celulares: el que usan Samsung, Xiaomi, Motorola y muchos más. (Si quieres instalar U market en Android, escribe **instalar en android**.)',
    ),
    (
      ['pwa', 'aplicacion web progresiva'],
      'Una **PWA** es una página web que se instala como app: ícono propio, pantalla completa y avisos, sin pasar por la tienda. U market se puede usar así.',
    ),
    (
      ['framework', 'frameworks'],
      'Un **framework** es un marco de trabajo: código ya hecho y reglas para construir algo sin empezar de cero. Por ejemplo, Flutter para apps (con él está hecha U market), React o Angular para páginas web y Django para servidores en Python.',
    ),
    (
      ['libreria', 'librerias', 'biblioteca de programacion'],
      'Una **librería** (o biblioteca), en programación, es código que otros escribieron para que lo uses. En C++, `<iostream>` y `<cmath>` son librerías.',
    ),
    (
      ['frontend', 'front end', 'backend', 'back end'],
      'El **frontend** es la parte de una app que ves y tocas; el **backend**, la que trabaja por detrás: guarda los datos, revisa las cuentas, manda los avisos.',
    ),
    (
      ['bug', 'error de programacion'],
      'Un **bug** es un error en un programa. Dicen que el nombre se popularizó por una polilla real que encontraron metida en una computadora en 1947.',
    ),
    (
      ['inteligencia artificial', 'ia'],
      'La **inteligencia artificial** son programas que aprenden de datos para hacer cosas que parecen inteligentes: reconocer caras, traducir, conversar. Yo, por cierto, no aprendo solo: mis respuestas las preparó el equipo.',
    ),
    (
      ['machine learning', 'aprendizaje automatico'],
      'El **machine learning** es una parte de la IA: en vez de programar cada regla, le muestras muchos ejemplos al programa y aprende el patrón solo.',
    ),
    (
      ['red neuronal', 'redes neuronales'],
      'Una **red neuronal** es un modelo de IA inspirado (de lejos) en el cerebro: capas de "neuronas" matemáticas que aprenden ajustando números. Así funcionan los reconocedores de imágenes y los chatbots grandes.',
    ),
    (
      ['chatgpt', 'chat gpt'],
      '**ChatGPT** es un chatbot de inteligencia artificial hecho por OpenAI. Yo no soy eso: soy MacIAs y funciono sin internet, con lo que me enseñó el equipo.',
    ),
    (
      ['chatbot', 'chat bot', 'bot'],
      'Un **chatbot** es un programa que conversa por chat. Como yo, pero yo soy uno con título de la UPSA.',
    ),
    (
      ['ciberseguridad'],
      'La **ciberseguridad** es proteger computadoras, redes y datos de ataques. Lo básico: contraseñas largas y distintas, verificación en dos pasos y desconfiar de links raros.',
    ),
    (
      ['contrasena', 'contrasena segura', 'contrasenas'],
      'Una buena **contraseña** es larga (12 caracteres o más), distinta para cada cuenta y difícil de adivinar. Mejor una frase rara que una palabra con números.',
    ),
    (
      ['hacker', 'hackers'],
      'Un **hacker** es alguien que sabe mucho de computadoras y busca cómo funcionan por dentro. Los éticos encuentran fallas para arreglarlas; los otros, para aprovecharlas.',
    ),
    (
      ['bit', 'bits', 'byte', 'bytes'],
      'Un **bit** es un 0 o un 1, lo mínimo que guarda una computadora. Un **byte** son 8 bits: con eso entra una letra.',
    ),
    (
      ['ram', 'memoria ram'],
      'La **RAM** es la memoria de trabajo de la computadora: guarda lo que está usando ahora y se borra al apagar. Más RAM, más cosas abiertas a la vez sin que se trabe.',
    ),
    (
      ['cpu', 'procesador'],
      'La **CPU** (procesador) es el cerebro de la computadora: ejecuta las instrucciones de los programas.',
    ),
    (
      ['gpu', 'tarjeta grafica', 'tarjeta de video'],
      'La **GPU** es el procesador de gráficos: hace muchísimas cuentas chiquitas a la vez. Por eso también se usa para entrenar inteligencia artificial.',
    ),
    (
      ['ssd', 'disco duro'],
      'El **disco** es donde la computadora guarda los archivos aunque se apague. Un SSD es mucho más rápido que un disco duro clásico, que tiene partes que giran.',
    ),
    (
      ['blockchain', 'cadena de bloques'],
      'Una **blockchain** es un registro compartido entre muchas computadoras, donde lo que se anota no se puede cambiar fácil. Es la base de bitcoin.',
    ),
    (
      ['bitcoin', 'criptomoneda', 'criptomonedas'],
      'Las **criptomonedas**, como bitcoin, son monedas digitales que no emite ningún banco central. Su precio sube y baja muchísimo: ojo con invertir lo que no puedes perder.',
    ),
    // ------------------------------------------------------------- economia
    (
      [
        'oferta y demanda',
        'ley de la oferta y la demanda',
        'oferta',
        'demanda',
      ],
      'La **oferta y la demanda**: si mucha gente quiere algo y hay poco, el precio sube; si sobra, baja. Por eso las salteñas se acaban antes del mediodía.',
    ),
    (
      ['inflacion'],
      'La **inflación** es cuando los precios suben en general y tu plata alcanza para menos. Se mide en porcentaje al año.',
    ),
    (
      ['pib', 'producto interno bruto'],
      'El **PIB** es el valor de todo lo que produce un país en un año. Sirve para medir el tamaño de su economía.',
    ),
    (
      ['interes'],
      'El **interés** es lo que pagas por usar plata prestada (o lo que te pagan por prestarla). El simple se calcula sobre el monto inicial; el compuesto, también sobre los intereses que se van sumando.',
    ),
    (
      ['interes compuesto'],
      'El **interés compuesto** se suma al capital y genera más interés: M = C · (1 + i)^n. A largo plazo, la diferencia con el simple es enorme.',
    ),
    (
      ['interes simple'],
      'El **interés simple** es I = C · i · t: capital por tasa por tiempo, siempre sobre el monto inicial.',
    ),
    (
      ['presupuesto'],
      'Un **presupuesto** es un plan de cuánto vas a ganar y gastar. Para estudiantes: anota lo que entra, separa lo fijo (pasajes, fotocopias) y reparte lo que sobra con cabeza.',
    ),
    (
      ['marketing', 'mercadotecnia'],
      'El **marketing** es todo lo que haces para que la gente conozca, quiera y compre tu producto: el precio, cómo lo muestras, dónde lo vendes y cómo lo comunicas.',
    ),
    (
      ['foda', 'dafo', 'analisis foda'],
      'El **análisis FODA**: Fortalezas y Debilidades (de adentro) y Oportunidades y Amenazas (de afuera). Sirve para planear un negocio, o hasta tu semestre.',
    ),
    (
      ['plan de negocios'],
      'Un **plan de negocios** explica tu negocio: qué vendes, a quién, cuánto cuesta, cuánto vas a ganar y cómo lo vas a hacer.',
    ),
    (
      ['startup', 'startups'],
      'Una **startup** es una empresa nueva que busca crecer rápido con una idea innovadora, casi siempre con tecnología.',
    ),
    (
      ['costo fijo', 'costos fijos', 'costo variable', 'costos variables'],
      'Los **costos fijos** no cambian aunque vendas más (alquiler, sueldos); los **variables** suben con cada unidad (los ingredientes de cada empanada).',
    ),
    (
      ['punto de equilibrio'],
      'El **punto de equilibrio** es cuánto tienes que vender para no ganar ni perder: costos fijos / (precio − costo variable por unidad).',
    ),
    (
      ['iva'],
      'El **IVA** es el Impuesto al Valor Agregado. En Bolivia es del 13 %.',
    ),
    (
      ['factura', 'facturas'],
      'Una **factura** es el documento que respalda una venta, con el detalle de lo que se cobró y los impuestos.',
    ),
    (
      ['activo', 'pasivo', 'patrimonio'],
      '**Activo**: lo que la empresa tiene (plata, mercadería, equipos). **Pasivo**: lo que debe. **Patrimonio**: activo menos pasivo, lo que de verdad es de los dueños.',
    ),
    (
      ['balance general'],
      'El **balance general** es una foto de la empresa en una fecha: lo que tiene, lo que debe y su patrimonio. Siempre cumple que activo = pasivo + patrimonio.',
    ),
    (
      ['estado de resultados'],
      'El **estado de resultados** muestra si en un periodo la empresa ganó o perdió: ingresos menos costos y gastos.',
    ),
    (
      ['flujo de caja'],
      'El **flujo de caja** es la plata que entra y sale de verdad en un periodo. Se puede tener ganancias en el papel y quedarse sin efectivo; por eso se mira aparte.',
    ),
    (
      ['roi', 'retorno de inversion', 'retorno de la inversion'],
      'El **ROI** mide cuánto ganaste por cada boliviano invertido: (ganancia − inversión) / inversión × 100.',
    ),
    (
      ['nicho', 'nicho de mercado'],
      'Un **nicho de mercado** es un grupo chico de clientes con una necesidad específica: por ejemplo, postres sin azúcar para la gente del campus.',
    ),
    (
      ['tipo de cambio', 'dolar'],
      'El **tipo de cambio** es cuántos bolivianos cuesta un dólar. Cambia según el mercado, y yo no tengo internet para saber el de hoy: míralo en una fuente actualizada.',
    ),
    (
      ['contabilidad'],
      'La **contabilidad** registra y ordena todo el movimiento de plata de una empresa, para saber cómo le va y tomar decisiones.',
    ),
    // ------------------------------------------------------------ sociedad
    (
      ['constitucion'],
      'La **Constitución** es la ley más importante de un país: organiza el Estado y garantiza los derechos de la gente. La de Bolivia es de 2009.',
    ),
    (
      ['democracia'],
      'La **democracia** es un sistema donde el poder viene del pueblo, que elige a sus autoridades con el voto.',
    ),
    (
      ['estado plurinacional'],
      'Así se define Bolivia desde la Constitución de 2009: un **Estado Plurinacional**, que reconoce a las distintas naciones y pueblos indígenas que lo forman.',
    ),
    (
      ['derechos humanos'],
      'Los **derechos humanos** son los que tiene toda persona por el solo hecho de serlo: a la vida, a la libertad, a la educación, a no ser discriminada.',
    ),
    (
      ['ley', 'leyes'],
      'Una **ley** es una regla obligatoria para todos, que dicta la autoridad que corresponde. En Bolivia las aprueba la Asamblea Legislativa Plurinacional.',
    ),
    (
      ['plagio'],
      'El **plagio** es presentar como tuyo el trabajo de otro. En la U es falta grave: cita siempre tus fuentes.',
    ),
    (
      ['normas apa', 'apa', 'citar en apa', 'formato apa'],
      'Las **normas APA** sirven para citar fuentes. En el texto: (Apellido, año). En la bibliografía: Apellido, Inicial. (año). Título. Editorial.',
    ),
    (
      ['tesis'],
      'Una **tesis** es la investigación grande con la que te titulas: planteas un problema, lo investigas con método y defiendes los resultados ante un tribunal. Si estás por empezar la tuya, pregúntame **cómo hago una tesis**.',
    ),
    (
      ['proyecto de grado', 'trabajo de grado'],
      'El **proyecto de grado** es una forma de titularse resolviendo un problema práctico (un sistema, un plan, un producto) en vez de una investigación de tesis. Las modalidades exactas las define tu carrera.',
    ),
    (
      ['monografia', 'monografias'],
      'Una **monografía** es un trabajo escrito que investiga a fondo un tema concreto, con fuentes citadas. Es más corta y menos formal que una tesis.',
    ),
    (
      ['ensayo', 'ensayos'],
      'Un **ensayo** es un texto en el que defiendes una idea con argumentos: introducción, desarrollo y conclusión.',
    ),
    (
      ['pasantia', 'pasantias'],
      'Una **pasantía** es trabajar un tiempo en una empresa mientras estudias (o al terminar) para aprender en la práctica. Suma muchísimo en el currículum.',
    ),
    (
      ['curriculum', 'cv'],
      'El **currículum** (o CV, u hoja de vida) es el resumen de tu formación y tu experiencia que mandas al buscar trabajo. Para armar el tuyo, pregúntame **cómo hago un CV**.',
    ),
    (
      ['defensa', 'defensa de tesis'],
      'La **defensa** es la presentación final de tu tesis o proyecto ante un tribunal: expones y respondes preguntas. Si te toca, pregúntame **cómo preparo mi defensa**.',
    ),
    // ----------------------------------------------------------- psicologia
    (
      ['estres'],
      'El **estrés** es la reacción del cuerpo ante una presión: te pone alerta. Un poco ayuda a rendir; mucho y por mucho tiempo, te agota.',
    ),
    (
      ['ansiedad'],
      'La **ansiedad** es una preocupación intensa por lo que puede pasar, que también se siente en el cuerpo (corazón acelerado, nervios). Si te pasa seguido, vale la pena hablarlo con un profesional.',
    ),
    (
      ['procrastinacion', 'procrastinar'],
      '**Procrastinar** es dejar para después lo que tienes que hacer, aunque sepas que te va a complicar. Truco: empieza solo 5 minutos, que lo difícil es arrancar.',
    ),
    (
      ['memoria'],
      'La **memoria** es la capacidad de guardar y recordar información. Se fortalece repasando de a poco y durmiendo bien. (La mía guarda lo que me cuentas, solo en tu teléfono.)',
    ),
    (
      ['habito', 'habitos'],
      'Un **hábito** es algo que haces casi en automático por repetirlo. Para crear uno: empieza muy chiquito y engánchalo a algo que ya haces.',
    ),
    (
      ['resiliencia'],
      'La **resiliencia** es la capacidad de levantarse después de un golpe: reprobar, fallar, empezar de nuevo y salir más fuerte.',
    ),
    (
      ['inteligencia emocional'],
      'La **inteligencia emocional** es saber reconocer y manejar tus emociones y entender las de los demás. Ayuda tanto como las notas.',
    ),
    (
      ['pomodoro', 'tecnica pomodoro'],
      'La **técnica Pomodoro**: 25 minutos de estudio sin distracciones y 5 de descanso; cada cuatro, un descanso largo. Funciona porque es más fácil empezar algo corto.',
    ),
    // ---------------------------------------------------------------- lengua
    (
      ['sustantivo', 'sustantivos'],
      'Un **sustantivo** es la palabra que nombra cosas, personas, lugares o ideas: mesa, Ana, Santa Cruz, amor.',
    ),
    (
      ['verbo', 'verbos'],
      'Un **verbo** es la palabra que dice una acción o un estado: correr, estudiar, ser.',
    ),
    (
      ['adjetivo', 'adjetivos'],
      'Un **adjetivo** describe al sustantivo: casa grande, profe exigente.',
    ),
    (
      ['adverbio', 'adverbios'],
      'Un **adverbio** modifica a un verbo, a un adjetivo o a otro adverbio: corre rápido, muy bien.',
    ),
    (
      ['sinonimo', 'sinonimos'],
      'Los **sinónimos** son palabras que significan lo mismo o casi: rápido y veloz.',
    ),
    (
      ['antonimo', 'antonimos'],
      'Los **antónimos** son palabras que significan lo contrario: frío y calor.',
    ),
    (
      ['metafora', 'metaforas'],
      'Una **metáfora** es decir que algo es otra cosa para describirlo: "el examen fue una montaña".',
    ),
    (
      [
        'agudas',
        'palabras agudas',
        'graves',
        'palabras graves',
        'llanas',
        'esdrujulas',
        'palabras esdrujulas',
        'acentuacion',
        'tilde',
        'tildes',
        'reglas de acentuacion',
      ],
      '**Agudas**: la fuerza va en la última sílaba, y llevan tilde si terminan en n, s o vocal (camión). **Graves**: en la penúltima, y llevan tilde si NO terminan en n, s o vocal (árbol). **Esdrújulas**: en la antepenúltima, y siempre llevan tilde (cálculo).',
    ),
    (
      ['sujeto', 'predicado', 'sujeto y predicado'],
      'El **sujeto** es de quién se habla y el **predicado**, lo que se dice de él: "Ana (sujeto) estudia cálculo (predicado)".',
    ),
    // ------------------------------------------------------------ geografia
    (
      ['continente', 'continentes'],
      'Los **continentes** son las grandes masas de tierra. Según cómo se cuenten son 5, 6 o 7; en Latinoamérica se suele enseñar América como uno solo.',
    ),
    (
      ['oceano', 'oceanos'],
      'Hay 5 **océanos**: el Pacífico (el más grande), el Atlántico, el Índico, el Antártico y el Ártico.',
    ),
    (
      ['ecuador', 'linea del ecuador'],
      'El **ecuador** es la línea imaginaria que divide la Tierra en hemisferio norte y sur. (Y también es un país, con capital en Quito.)',
    ),
    (
      ['latitud', 'longitud', 'coordenadas'],
      'La **latitud** dice qué tan al norte o al sur está un punto, y la **longitud**, qué tan al este o al oeste. Con las dos ubicas cualquier lugar del planeta.',
    ),
    // ------------------------------------------------------------ universo
    (
      ['universo'],
      'El **universo** es todo lo que existe: espacio, tiempo, materia y energía. Tiene unos 13 800 millones de años.',
    ),
    (
      ['galaxia', 'galaxias', 'via lactea'],
      'Una **galaxia** es un montón enorme de estrellas, gas y polvo unidos por la gravedad. La nuestra es la Vía Láctea, con más de 100 mil millones de estrellas.',
    ),
    (
      ['estrella', 'estrellas'],
      'Una **estrella** es una bola gigante de gas que brilla por la fusión nuclear en su centro. El Sol es una estrella mediana.',
    ),
    (
      ['sol', 'el sol'],
      'El **Sol** es nuestra estrella: está a unos 150 millones de km y su luz tarda unos 8 minutos en llegar. Le entrarían más de un millón de Tierras.',
    ),
    (
      ['luna', 'la luna'],
      'La **Luna** es el satélite natural de la Tierra, a unos 384 000 km. Siempre nos muestra la misma cara.',
    ),
    (
      ['eclipse', 'eclipses'],
      'En un **eclipse**, un astro tapa a otro: en el solar, la Luna tapa al Sol; en el lunar, la Tierra le hace sombra a la Luna.',
    ),
    (
      ['ano luz', 'anos luz'],
      'Un **año luz** no es tiempo, es distancia: lo que recorre la luz en un año, unos 9,46 billones de km.',
    ),
    (
      ['agujero negro', 'agujeros negros'],
      'Un **agujero negro** es una zona donde la gravedad es tan fuerte que ni la luz puede escapar. Se forma cuando una estrella muy grande colapsa.',
    ),
    (
      ['big bang'],
      'El **Big Bang** es la teoría de cómo empezó el universo: hace unos 13 800 millones de años todo estaba concentrado y muy caliente, y desde entonces se expande.',
    ),
    (
      ['planeta', 'planetas'],
      'Un **planeta** es un cuerpo grande que gira alrededor de una estrella y despejó su órbita. En el sistema solar hay 8: Mercurio, Venus, la Tierra, Marte, Júpiter, Saturno, Urano y Neptuno.',
    ),
    (
      ['cambio climatico', 'calentamiento global'],
      'El **cambio climático** es el calentamiento del planeta por los gases (como el CO2) que soltamos al quemar combustibles y bosques. Trae más sequías, incendios e inundaciones.',
    ),
  ];

  // ================================================================= cultura
  static const _cultura = <_Entrada>[
    (
      ['saltena', 'saltenas'],
      'La **salteña** es una empanada jugosa al horno con caldo adentro (de carne o pollo, con papa, arveja y huevo). Se come a media mañana, y con cuidado, que se chorrea.',
    ),
    (
      ['majadito'],
      'El **majadito** es un plato cruceño de arroz con charque, con huevo frito y plátano frito.',
    ),
    (
      ['sonso', 'sonso de yuca'],
      'El **sonso** es de yuca y queso, asado o a la sartén. Bien del oriente.',
    ),
    (
      ['cunape', 'cunapes'],
      'El **cuñapé** es un panecito de almidón de yuca y queso. Va perfecto con un café.',
    ),
    (
      ['pique macho'],
      'El **pique macho** es un plato cochabambino para compartir: trozos de carne, salchicha, papas fritas, cebolla, tomate, locoto y huevo.',
    ),
    (
      ['silpancho'],
      'El **silpancho** es de Cochabamba: arroz, papa, una milanesa finita encima, huevo frito y una salsa de tomate y cebolla.',
    ),
    (
      ['sopa de mani'],
      'La **sopa de maní** es cremosa, con papas fritas encima. Un clásico boliviano.',
    ),
    (
      ['mocochinchi'],
      'El **mocochinchi** es un refresco de durazno deshidratado con canela, bien helado.',
    ),
    (
      ['somo'],
      'El **somó** es una bebida cruceña de maíz blanco cocido con leche, azúcar y canela, que se toma bien fría.',
    ),
    (
      ['locro', 'locro de gallina'],
      'El **locro** cruceño es una sopa espesa de arroz con gallina criolla, que suele llevar yuca y plátano. Ideal para el surazo.',
    ),
    (
      ['todos santos', 'dia de los difuntos', 'dia de los muertos'],
      '**Todos Santos** (1 y 2 de noviembre): en Bolivia se recibe a las almas de los difuntos con mesas llenas de **tantawawas** (panes con forma de bebé), masitas, frutas y lo que le gustaba a la persona. El 2 se las despide, muchas veces en el cementerio.',
    ),
    (
      ['tantawawa', 'tantawawas', 'tanta wawa', 'tanta wawas'],
      'Las **tantawawas** son panes con forma de bebé (wawa, en aymara y quechua) que se hacen para Todos Santos y se ponen en la mesa de los difuntos.',
    ),
    (
      ['alasita', 'feria de la alasita', 'feria de alasitas', 'alasitas'],
      'La **Alasita** es la feria de las miniaturas de La Paz, cada 24 de enero: se compran en chiquito las cosas que uno desea (una casa, un título, billetitos) para que el Ekeko las haga realidad.',
    ),
    (
      ['ekeko'],
      'El **Ekeko** es el dios andino de la abundancia: un hombrecito sonriente cargado de cosas, el protagonista de la Alasita.',
    ),
    (
      ['urkupina', 'virgen de urkupina'],
      'La fiesta de la **Virgen de Urkupiña** es en Quillacollo, Cochabamba, a mediados de agosto: una de las fiestas religiosas más grandes de Bolivia.',
    ),
    (
      ['pachamama'],
      'La **Pachamama** es la Madre Tierra en la tradición andina. En agosto, sobre todo, se le hacen ofrendas para agradecer y pedir.',
    ),
    (
      ['challa'],
      'La **ch\'alla** es la costumbre de bendecir algo (la casa, el auto, el negocio) rociando alcohol o chicha y adornando con serpentinas. Se hace mucho en carnaval.',
    ),
    (
      ['masaco'],
      'El **masaco** es plátano verde (o yuca) machacado con charque o queso. Ideal en el desayuno cruceño.',
    ),
    (
      ['keperi'],
      'El **keperí** es un corte de res cocido lento y después dorado, típico de Santa Cruz y el Beni.',
    ),
    (
      ['chairo'],
      'El **chairo** es una sopa paceña de chuño, carne, verduras y trigo. Abriga en el frío de La Paz.',
    ),
    (
      ['sajta', 'sajta de pollo'],
      'La **sajta** es pollo en salsa de ají amarillo, con chuño y papa. Típica de La Paz.',
    ),
    (
      ['tucumana', 'tucumanas'],
      'La **tucumana** es una empanada frita rellena de carne, papa y huevo, que se come con salsas.',
    ),
    (
      ['anticucho', 'anticuchos'],
      'Los **anticuchos** son brochetas de corazón de res a la parrilla, con papa y salsa de maní. Comida de noche.',
    ),
    (
      ['charque'],
      'El **charque** es carne secada al sol y salada. Es la base del majadito y del masaco.',
    ),
    (
      ['chicha'],
      'La **chicha** es una bebida tradicional de maíz fermentado, sobre todo de Cochabamba.',
    ),
    (
      ['singani'],
      'El **singani** es el destilado de uva de Bolivia, sobre todo de Tarija.',
    ),
    (
      ['caporales'],
      'Los **caporales** son una danza boliviana de saltos y mucha energía, inspirada en los capataces de la época colonial.',
    ),
    (
      ['morenada'],
      'La **morenada** es una danza del altiplano con trajes pesados y matracas, estrella del Gran Poder y del Carnaval de Oruro.',
    ),
    (
      ['diablada'],
      'La **diablada** es la danza emblema del Carnaval de Oruro: la lucha entre el bien y el mal, con máscaras espectaculares.',
    ),
    (
      ['tinku'],
      'El **tinku** es una danza y un ritual del norte de Potosí, de origen guerrero, con pasos fuertes y trajes coloridos.',
    ),
    (
      ['taquirari'],
      'El **taquirari** es un ritmo alegre del oriente boliviano, de Santa Cruz y el Beni.',
    ),
    (
      ['cueca'],
      'La **cueca** es una danza de pañuelo y zapateo; la boliviana tiene versiones paceña, chuquisaqueña, tarijeña y más.',
    ),
    (
      ['gran poder'],
      'El **Gran Poder** es la fiesta del Señor del Gran Poder, en La Paz: una entrada folclórica enorme, con miles de bailarines.',
    ),
    (
      ['carnaval de oruro'],
      'El **Carnaval de Oruro** es Obra Maestra del Patrimonio Oral e Inmaterial de la Humanidad desde 2001: días de danzas como la Diablada y la Morenada.',
    ),
    (
      ['carnaval cruceno', 'carnaval de santa cruz', 'carnaval'],
      'El **Carnaval** en Bolivia es la fiesta grande: en Santa Cruz hay comparsas, precarnavales, reina y mucho chapuzón; en Oruro, la entrada más famosa del país. (Pregúntame **cuánto falta para carnaval**.)',
    ),
    (
      ['surazo'],
      'El **surazo** es el viento frío del sur que llega de golpe a Santa Cruz: un día estás a 35 °C y al siguiente sacas la chamarra.',
    ),
    (
      ['camba', 'cambas'],
      'Así se le dice a la gente del oriente boliviano, sobre todo de Santa Cruz: **camba**.',
    ),
    (
      ['colla', 'collas'],
      'Así se le dice a la gente del occidente andino de Bolivia: **colla**.',
    ),
    (
      ['chapaco', 'chapacos'],
      'Así se le dice a la gente de Tarija: **chapaco**.',
    ),
    (
      ['upsa', 'la upsa'],
      'La **UPSA** es la Universidad Privada de Santa Cruz de la Sierra. Y la casa de U market: solo se entra con su correo institucional.',
    ),
  ];

  // ================================================================= gente
  static const _gente = <_Entrada>[
    (
      ['einstein', 'albert einstein'],
      '**Albert Einstein** (1879–1955), físico alemán. Creó la teoría de la relatividad (E = mc²) y ganó el Nobel de Física en 1921.',
    ),
    (
      ['newton', 'isaac newton'],
      '**Isaac Newton** (1643–1727), físico y matemático inglés. Formuló las leyes del movimiento y la gravitación universal, y es uno de los padres del cálculo.',
    ),
    (
      ['leibniz', 'gottfried leibniz'],
      '**Gottfried Leibniz** (1646–1716), filósofo y matemático alemán. Inventó el cálculo al mismo tiempo que Newton; el símbolo ∫ de la integral es suyo.',
    ),
    (
      ['pitagoras'],
      '**Pitágoras** (siglo VI a. C.), filósofo y matemático griego. Su teorema: en todo triángulo rectángulo, a² + b² = c².',
    ),
    (
      ['euclides'],
      '**Euclides** (siglo III a. C.), matemático griego, el "padre de la geometría". Su libro Elementos se usó para enseñar durante más de 2000 años.',
    ),
    (
      ['arquimedes'],
      '**Arquímedes** (siglo III a. C.), matemático e inventor griego. Dicen que gritó "¡Eureka!" en la bañera al descubrir cómo medir el volumen de un cuerpo.',
    ),
    (
      ['gauss', 'carl friedrich gauss'],
      '**Carl Friedrich Gauss** (1777–1855), el "príncipe de las matemáticas". De niño sumó del 1 al 100 en segundos: 50 pares que suman 101, o sea, 5050.',
    ),
    (
      ['euler', 'leonhard euler'],
      '**Leonhard Euler** (1707–1783), matemático suizo, de los más productivos de la historia. Le debemos la notación f(x) y el uso del número e.',
    ),
    (
      ['al juarismi', 'al khwarizmi', 'juarismi', 'al jwarizmi'],
      '**Al-Juarismi** (siglo IX), matemático persa. De su libro viene la palabra "álgebra", y de su nombre, "algoritmo". Es el de la portada del Baldor.',
    ),
    (
      ['baldor', 'aurelio baldor'],
      '**Aurelio Baldor** (1906–1978), profesor y matemático cubano. Su Álgebra, publicada en 1941, sigue en las mochilas de media Latinoamérica.',
    ),
    (
      ['galileo', 'galileo galilei'],
      '**Galileo Galilei** (1564–1642), astrónomo y físico italiano. Mejoró el telescopio, descubrió lunas de Júpiter y defendió que la Tierra gira alrededor del Sol.',
    ),
    (
      ['copernico', 'nicolas copernico'],
      '**Nicolás Copérnico** (1473–1543), astrónomo polaco. Propuso que la Tierra gira alrededor del Sol, y no al revés.',
    ),
    (
      ['marie curie', 'curie'],
      '**Marie Curie** (1867–1934), física y química polaca-francesa, pionera de la radiactividad. Fue la primera persona en ganar dos premios Nobel (Física y Química).',
    ),
    (
      ['nikola tesla', 'tesla'],
      '**Nikola Tesla** (1856–1943), inventor serbio-estadounidense, clave en la corriente alterna, la que llega a los enchufes. (La marca de autos se llama así por él.)',
    ),
    (
      ['edison', 'thomas edison'],
      '**Thomas Edison** (1847–1931), inventor estadounidense. Patentó más de mil inventos, entre ellos una bombilla eléctrica práctica y el fonógrafo.',
    ),
    (
      ['darwin', 'charles darwin'],
      '**Charles Darwin** (1809–1882), naturalista inglés. Explicó la evolución por selección natural en El origen de las especies (1859).',
    ),
    (
      ['mendel', 'gregor mendel'],
      '**Gregor Mendel** (1822–1884), monje y científico. Con plantas de arvejas descubrió las leyes de la herencia: es el padre de la genética.',
    ),
    (
      ['alan turing', 'turing'],
      '**Alan Turing** (1912–1954), matemático británico, padre de la computación. Ayudó a descifrar la máquina Enigma en la Segunda Guerra Mundial.',
    ),
    (
      ['ada lovelace', 'lovelace'],
      '**Ada Lovelace** (1815–1852), matemática británica. Escribió el primer programa de la historia, para la máquina analítica de Babbage.',
    ),
    (
      ['grace hopper'],
      '**Grace Hopper** (1906–1992), pionera de la computación. Ayudó a crear el lenguaje COBOL y popularizó la palabra "bug" para los errores.',
    ),
    (
      ['bjarne stroustrup', 'stroustrup'],
      '**Bjarne Stroustrup**, informático danés, creó C++ a principios de los 80. Al principio lo llamó "C con clases".',
    ),
    (
      ['dennis ritchie'],
      '**Dennis Ritchie** (1941–2011) creó el lenguaje C en los años 70, en los Laboratorios Bell.',
    ),
    (
      ['linus torvalds'],
      '**Linus Torvalds**, programador finlandés, creó Linux en 1991 y, más tarde, Git.',
    ),
    (
      ['bill gates'],
      '**Bill Gates** cofundó Microsoft en 1975, la empresa de Windows.',
    ),
    (
      ['steve jobs'],
      '**Steve Jobs** (1955–2011) cofundó Apple. Impulsó la Mac, el iPod y el iPhone.',
    ),
    (
      ['mark zuckerberg', 'zuckerberg'],
      '**Mark Zuckerberg** creó Facebook en 2004, cuando estudiaba en Harvard.',
    ),
    (
      ['elon musk'],
      '**Elon Musk** es un empresario al frente de compañías como Tesla y SpaceX.',
    ),
    (
      ['simon bolivar', 'bolivar'],
      '**Simón Bolívar** (1783–1830), el Libertador. Lideró la independencia de varios países sudamericanos, y Bolivia lleva su nombre.',
    ),
    (
      ['antonio jose de sucre', 'mariscal sucre', 'sucre'],
      '**Antonio José de Sucre** (1795–1830), Gran Mariscal de Ayacucho, héroe de la independencia y de los primeros presidentes de Bolivia. La capital lleva su nombre.',
    ),
    (
      ['juana azurduy', 'juana azurduy de padilla'],
      '**Juana Azurduy de Padilla** (1780–1862), heroína de la independencia nacida en Chuquisaca. Peleó contra los españoles al mando de guerrillas.',
    ),
    (
      ['tupac katari', 'julian apaza'],
      '**Túpac Katari** (Julián Apaza), líder aymara que en 1781 cercó La Paz en una rebelión contra el dominio español.',
    ),
    (
      ['bartolina sisa'],
      '**Bartolina Sisa**, líder aymara y compañera de Túpac Katari en la rebelión de 1781. Cada 5 de septiembre se recuerda en su honor el Día Internacional de la Mujer Indígena.',
    ),
    (
      ['nuflo de chavez'],
      '**Ñuflo de Chávez**, conquistador español que fundó Santa Cruz de la Sierra en 1561.',
    ),
    (
      ['jaime escalante'],
      '**Jaime Escalante** (1930–2010), profesor de matemáticas boliviano. En Los Ángeles llevó a estudiantes de un barrio difícil a aprobar cálculo avanzado, y su historia se volvió película: Stand and Deliver.',
    ),
    (
      ['gabriel garcia marquez', 'garcia marquez', 'gabo'],
      '**Gabriel García Márquez** (1927–2014), escritor colombiano, autor de Cien años de soledad. Nobel de Literatura en 1982.',
    ),
    (
      ['cervantes', 'miguel de cervantes'],
      '**Miguel de Cervantes** (1547–1616), escritor español, autor de Don Quijote de la Mancha.',
    ),
    (
      ['pablo neruda', 'neruda'],
      '**Pablo Neruda** (1904–1973), poeta chileno, Nobel de Literatura en 1971.',
    ),
    (
      ['gabriela mistral'],
      '**Gabriela Mistral** (1889–1957), poeta chilena, la primera persona de Latinoamérica en ganar el Nobel de Literatura (1945).',
    ),
    (
      ['shakespeare', 'william shakespeare'],
      '**William Shakespeare** (1564–1616), dramaturgo inglés, autor de Romeo y Julieta y Hamlet.',
    ),
    (
      ['leonardo da vinci', 'da vinci'],
      '**Leonardo da Vinci** (1452–1519), genio del Renacimiento italiano: pintó la Mona Lisa y diseñó máquinas siglos antes de que existieran.',
    ),
    (
      ['picasso', 'pablo picasso'],
      '**Pablo Picasso** (1881–1973), pintor español, uno de los creadores del cubismo.',
    ),
    (
      ['cristobal colon', 'colon'],
      '**Cristóbal Colón** llegó a América en 1492, financiado por los reyes de España.',
    ),
    (
      ['messi', 'lionel messi'],
      '**Lionel Messi**, futbolista argentino, campeón del mundo en Qatar 2022 y ganador de varios Balones de Oro.',
    ),
    (
      ['cristiano ronaldo', 'cristiano', 'cr7'],
      '**Cristiano Ronaldo**, futbolista portugués, cinco veces Balón de Oro y máximo goleador de la historia en selecciones.',
    ),
    (
      ['marcelo martins', 'marcelo moreno martins', 'marcelo moreno'],
      '**Marcelo Martins Moreno**, delantero boliviano, máximo goleador histórico de la Selección.',
    ),
  ];

  // ================================================================ lugares
  static const _lugares = <_Entrada>[
    (
      ['salar de uyuni', 'uyuni'],
      'El **Salar de Uyuni** está en Potosí, en el suroeste de Bolivia. Es el desierto de sal más grande del mundo: en época de lluvias se vuelve un espejo gigante.',
    ),
    (
      ['lago titicaca', 'titicaca'],
      'El **lago Titicaca** está entre Bolivia y Perú, a unos 3800 metros de altura: el lago navegable más alto del mundo. Ahí están la Isla del Sol y Copacabana.',
    ),
    (
      ['tiwanaku', 'tiahuanaco'],
      '**Tiwanaku** es un sitio arqueológico cerca del lago Titicaca, en La Paz, centro de una civilización andina muy antigua. Su Puerta del Sol es lo más famoso, y es Patrimonio de la Humanidad.',
    ),
    (
      ['samaipata', 'fuerte de samaipata', 'el fuerte de samaipata'],
      '**Samaipata** está a unas tres horas de Santa Cruz. Su Fuerte es una gran roca tallada por pueblos antiguos, Patrimonio de la Humanidad.',
    ),
    (
      ['misiones jesuiticas', 'misiones de chiquitos', 'chiquitania'],
      'Las **Misiones Jesuíticas de Chiquitos** están en la Chiquitanía de Santa Cruz: pueblos con iglesias del siglo XVIII, Patrimonio de la Humanidad y famosos por su música barroca.',
    ),
    (
      ['noel kempff', 'noel kempff mercado', 'parque noel kempff'],
      'El **Parque Nacional Noel Kempff Mercado** está en el norte de Santa Cruz: cascadas, selva y mesetas. Es Patrimonio de la Humanidad por su naturaleza.',
    ),
    (
      ['madidi', 'parque madidi'],
      'El **Parque Nacional Madidi** está en La Paz, y es de los lugares con más especies del planeta.',
    ),
    (
      ['amboro', 'parque amboro'],
      'El **Parque Nacional Amboró** está cerca de Santa Cruz, entre los Andes y la llanura, con bosques nublados y muchísima biodiversidad.',
    ),
    (
      ['cerro rico'],
      'El **Cerro Rico** de Potosí dio toneladas de plata durante la Colonia. De ahí viene la expresión "vale un Potosí".',
    ),
    (
      ['cristo redentor', 'el cristo'],
      'En Santa Cruz, el **Cristo Redentor** está en el segundo anillo, y es un clásico punto de encuentro. (El más famoso del mundo está en Río de Janeiro.)',
    ),
    (
      ['cristo de la concordia'],
      'El **Cristo de la Concordia** está en el cerro San Pedro de Cochabamba, y es más alto que el Cristo Redentor de Río.',
    ),
    (
      ['plaza 24 de septiembre', 'plaza principal'],
      'La **plaza 24 de Septiembre** es la principal de Santa Cruz, frente a la Catedral. Se llama así por el grito libertario cruceño del 24 de septiembre de 1810.',
    ),
    (
      ['santa cruz', 'santa cruz de la sierra'],
      '**Santa Cruz de la Sierra** fue fundada en 1561 por Ñuflo de Chávez. Es la ciudad más poblada de Bolivia y su motor económico. Y la casa de la UPSA.',
    ),
    (
      ['la paz'],
      '**La Paz** es la sede de gobierno de Bolivia, a más de 3600 metros de altura. Tiene la red de teleféricos urbanos más grande del mundo.',
    ),
    (
      ['cochabamba'],
      '**Cochabamba**, en el centro del país, es la "ciudad de la eterna primavera" y la capital gastronómica de Bolivia. Ahí está el Cristo de la Concordia.',
    ),
    (
      ['sucre'],
      '**Sucre** es la capital constitucional de Bolivia, la "ciudad blanca". Ahí se firmó la independencia en 1825, en la Casa de la Libertad.',
    ),
    (
      ['oruro'],
      '**Oruro** es famosa por su Carnaval, Patrimonio de la Humanidad, donde la Diablada es la danza estrella.',
    ),
    (
      ['potosi'],
      '**Potosí** es una de las ciudades más altas del mundo, a más de 4000 metros, famosa por la plata del Cerro Rico. Su centro es Patrimonio de la Humanidad.',
    ),
    (
      ['tarija'],
      '**Tarija**, en el sur de Bolivia, es tierra de vinos y singani, y de los chapacos.',
    ),
    (
      ['beni', 'trinidad'],
      'El **Beni** está en la Amazonía boliviana: ríos, llanuras y mucha naturaleza. Su capital es Trinidad.',
    ),
    (
      ['pando', 'cobija'],
      '**Pando** está en el extremo norte, en plena Amazonía; su capital es Cobija, en la frontera con Brasil.',
    ),
    (
      ['el alto'],
      '**El Alto** está pegado a La Paz, sobre el altiplano: es de las ciudades grandes más altas del mundo.',
    ),
    (
      ['machu picchu'],
      '**Machu Picchu** está en Cusco, Perú: la ciudadela inca más famosa, una de las siete maravillas del mundo moderno.',
    ),
    (
      ['torre eiffel'],
      'La **Torre Eiffel** está en París, Francia. Se construyó para la Exposición Universal de 1889 y mide unos 330 metros.',
    ),
    (
      ['gran muralla china', 'muralla china'],
      'La **Gran Muralla** está en el norte de China: miles de kilómetros de murallas construidas durante siglos para defenderse de invasiones.',
    ),
    (
      ['coliseo', 'coliseo romano'],
      'El **Coliseo** está en Roma, Italia: el gran anfiteatro del Imperio Romano, terminado en el año 80, donde luchaban los gladiadores.',
    ),
    (
      ['piramides de egipto', 'piramides', 'giza', 'gran piramide'],
      'Las **pirámides de Giza** están cerca de El Cairo, Egipto. La Gran Pirámide tiene unos 4500 años y es la única maravilla del mundo antiguo que sigue en pie.',
    ),
    (
      ['estatua de la libertad'],
      'La **Estatua de la Libertad** está en Nueva York. Fue un regalo de Francia a Estados Unidos en 1886.',
    ),
    (
      ['amazonas', 'amazonia', 'rio amazonas'],
      'La **Amazonía** es la selva tropical más grande del planeta, repartida entre nueve países, Bolivia incluida. Su río, el Amazonas, es el más caudaloso del mundo.',
    ),
    (
      ['everest', 'monte everest'],
      'El **Everest** está en el Himalaya, entre Nepal y China, y mide unos 8849 metros: la montaña más alta del mundo.',
    ),
    (
      ['sajama', 'nevado sajama'],
      'El **Sajama**, en Oruro, es la montaña más alta de Bolivia: unos 6542 metros.',
    ),
    (
      ['illimani'],
      'El **Illimani** es el nevado que cuida La Paz: más de 6400 metros, y sale en todas las postales.',
    ),
  ];
}
