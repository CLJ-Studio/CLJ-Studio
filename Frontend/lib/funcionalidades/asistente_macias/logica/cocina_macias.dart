import 'conversacion_macias.dart';
import 'lenguaje_macias.dart';

/// Una receta o un plato: como se lo nombra (ya normalizado) y lo que dice
/// MacIAs.
typedef _Entrada = (List<String>, String);

/// La cocina de MacIAs: recetas caseras, sobre todo bolivianas, y lo que es
/// cada plato.
///
/// Recetas de casa, con medidas de taza y cuchara: para cocinar en un
/// departamento de estudiante, no en un restaurante.
abstract final class CocinaMacias {
  /// La receta, la lista de recetas o "esa no la tengo". Null si no se
  /// hablaba de cocinar.
  static RespuestaCharla? responder(String t) {
    if (_queCocino.hasMatch(t)) {
      return const RespuestaCharla(
        'Fáciles y ricas: **majadito**, **bife** con arroz, **salchipapa**, '
        '**fideo con salsa**, **panqueques** o, si es para el antojo, '
        '**brownies** y un **frappé**. Pídeme cualquiera: **receta de** y el '
        'nombre.',
        intencion: 'saber:recetas',
      );
    }
    final pedido = _pideReceta.firstMatch(t);
    if (pedido == null) return null;
    final plato = pedido[2]!.trim();
    final receta = buscar(_indiceRecetas, plato);
    if (receta != null) {
      return RespuestaCharla(receta, intencion: 'saber:receta');
    }
    // "Receta de X", "¿sabes cocinar X?": se hablaba de cocina, aunque ese
    // plato no este. "¿Cómo se hace una tesis?" no: eso sigue de largo.
    if (!_soloCocina.hasMatch(pedido[1]!)) return null;
    return const RespuestaCharla(
      'Esa receta no la tengo todavía, perdón. Pídeme otra: tengo majadito, '
      'salteña, salchipapa, brownies, sushi y muchas más.',
      intencion: 'saber:receta_desconocida',
    );
  }

  static final _queCocino = RegExp(
    r'^(?:y )?(?:que (?:puedo cocinar|cocino|preparo|hago de comer|puedo '
    r'preparar)(?: hoy)?|dame una receta|una receta|recetas|recetas faciles|'
    r'receta facil|que recetas (?:sabes|tienes))$',
  );

  static final _pideReceta = RegExp(
    r'^(?:y |si |oye |y si )?'
    r'((?:me )?(?:sabes|puedes) (?:hacer|cocinar|preparar)|'
    r'como (?:se hace|se hacen|se prepara|se preparan|hago|hacer|preparo|'
    r'preparar|cocino|cocinar|se cocina)|'
    r'(?:dame |pasame |tienes )?(?:la |una )?receta (?:de|del|para)|'
    r'ensename a (?:hacer|preparar|cocinar)|'
    r'que (?:ingredientes )?lleva|ingredientes (?:de|del|para)) '
    r'(.+)$',
  );

  /// Las formas de preguntar que solo pueden ser de cocina.
  static final _soloCocina = RegExp(
    r'receta|ingredientes|lleva|cocinar|cocino|cocina|preparar|preparo|'
    r'prepara',
  );

  /// Busca con tolerancia: sin articulo, en singular o con una falta.
  static String? buscar(Map<String, String> indice, String nombre) {
    final limpio = nombre
        .replaceFirst(RegExp(r'^(?:el|la|los|las|un|una|unos|unas) '), '')
        .replaceFirst(RegExp(r' (?:por favor|porfa|nomas|pues|rico|rica)$'), '')
        .trim();
    if (limpio.isEmpty) return null;
    final exacto = indice[limpio];
    if (exacto != null) return exacto;
    if (limpio.endsWith('es')) {
      final singular = indice[limpio.substring(0, limpio.length - 2)];
      if (singular != null) return singular;
    }
    if (limpio.endsWith('s')) {
      final singular = indice[limpio.substring(0, limpio.length - 1)];
      if (singular != null) return singular;
    }
    if (limpio.length >= 6) {
      for (final MapEntry(key: clave, value: texto) in indice.entries) {
        if ((clave.length - limpio.length).abs() <= 1 &&
            clave.length >= 6 &&
            LenguajeMacias.distancia(clave, limpio) <= 1) {
          return texto;
        }
      }
    }
    return null;
  }

  static final Map<String, String> _indiceRecetas = {
    for (final (nombres, texto) in _recetas)
      for (final nombre in nombres) nombre: texto,
  };

  /// Todas las recetas y los platos. Para las pruebas.
  static Iterable<(List<String>, String)> get entradas => [
    ..._recetas,
    ...platos,
  ];

  // ================================================================ platos
  /// Que es cada plato que no estaba ya en la enciclopedia. Los usa la
  /// enciclopedia para "¿qué es un bife?".
  static const platos = <_Entrada>[
    (
      ['bife', 'bifes'],
      'Un **bife** es un filete de carne de res a la plancha o frito. En Bolivia se sirve con arroz, papas fritas y ensalada, y muchas veces con un huevo frito encima.',
    ),
    (
      ['salchipapa', 'salchipapas'],
      'La **salchipapa** es papas fritas con salchichas en rodajas, bañadas en salsas. Comida rápida de las más queridas en Bolivia y Perú.',
    ),
    (
      ['sushi'],
      'El **sushi** es un plato japonés de arroz con vinagre, alga nori y pescado crudo o verduras, en rollos o bocaditos.',
    ),
    (
      ['frappe', 'frappes', 'frape', 'frappuccino'],
      'Un **frappé** es una bebida helada licuada con hielo: de café, de chocolate o de frutas, muchas veces con crema encima.',
    ),
    (
      ['brownie', 'brownies'],
      'Un **brownie** es un pastelito de chocolate, denso y húmedo por dentro. Viene de Estados Unidos.',
    ),
    (
      ['llajua', 'llajwa'],
      'La **llajua** es la salsa picante boliviana: tomate, locoto y quirquiña molidos en batán. Va en la mesa con casi cualquier comida.',
    ),
    (
      ['fricase', 'fricace'],
      'El **fricasé** es un caldo paceño picante de cerdo con ají amarillo, mote y chuño. Famoso para reponerse después de una fiesta.',
    ),
    (
      ['plato paceno'],
      'El **plato paceño** lleva choclo, habas, papa y un trozo de queso frito, con llajua. Sencillo y bien andino.',
    ),
    (
      ['huminta', 'humintas', 'humita', 'humitas'],
      'La **huminta** es masa de choclo molido con queso, envuelta en chala y cocida al horno o al vapor. Ideal con café.',
    ),
    (
      ['bunuelo', 'bunuelos'],
      'Los **buñuelos** son masas fritas y crocantes que se comen con miel o jarabe; en Bolivia, junto a un api morado.',
    ),
    (
      ['chicharron'],
      'El **chicharrón** es cerdo cocido en su propia grasa hasta quedar dorado. En Bolivia va con mote y llajua.',
    ),
    (
      ['arroz chaufa', 'chaufa'],
      'El **arroz chaufa** es arroz frito al estilo chino-peruano, con huevo, pollo o carne y salsa de soya.',
    ),
    (
      ['ceviche', 'cebiche'],
      'El **ceviche** es pescado crudo "cocido" en jugo de limón, con cebolla y ají. Viene de la costa peruana y en Bolivia también se quiere mucho.',
    ),
    (
      ['flan'],
      'El **flan** es un postre de huevo y leche cocido a baño maría, con caramelo encima.',
    ),
    (
      ['milanesa', 'milanesas'],
      'La **milanesa** es un filete fino de carne o pollo, apanado y frito.',
    ),
    (
      ['sandwich de chola', 'sanduche de chola'],
      'El **sándwich de chola** es el clásico paceño: pan con chancho al horno, encurtido de cebolla, zanahoria y locoto, y un poco de llajua.',
    ),
    (
      ['helado de canela'],
      'El **helado de canela** es un helado de agua con canela y clavo de olor, rojo y bien refrescante. Típico de Sucre.',
    ),
    (
      ['guacamole'],
      'El **guacamole** es una salsa mexicana de palta pisada con cebolla, tomate, limón y cilantro.',
    ),
    (
      ['arroz con leche'],
      'El **arroz con leche** es un postre de arroz cocido en leche con azúcar y canela. Se come frío o tibio.',
    ),
  ];

  // =============================================================== recetas
  static const _recetas = <_Entrada>[
    // --------------------------------------------------------- bolivianas
    (
      ['saltena', 'saltenas'],
      'La **salteña** es de las difíciles, pero sale:\n'
          '1. **El jigote** (el relleno), de un día para otro: carne en '
          'cubitos, cebolla, ají colorado, comino, papa y arvejas cocidas, con '
          'caldo bien sazonado y gelatina para que cuaje. Al armar, huevo duro '
          'y una aceituna.\n'
          '2. **La masa**: harina, manteca derretida, azúcar, achiote para el '
          'color y agua tibia con sal.\n'
          '3. Rellena el disco con el jigote frío, ciérralo con el repulgue '
          'arriba y al horno bien caliente hasta que dore.\n\n'
          'El secreto: el jigote tiene que estar frío y cuajado; si no, se '
          'escapa todo el jugo.',
    ),
    (
      ['majadito'],
      '**Majadito** (para 4):\n'
          '1. Fríe cebolla y tomate con urucú (achiote) para el color.\n'
          '2. Agrega el charque desmenuzado y sofríe un poco.\n'
          '3. Echa 2 tazas de arroz, mezcla y cubre con unas 4 tazas de agua '
          'caliente. Sal, y a fuego bajo hasta que el arroz esté.\n'
          '4. Sirve con huevo frito, plátano frito y yuca.\n\n'
          'Se llama así porque el charque se majaba (se golpeaba) para '
          'desmenuzarlo.',
    ),
    (
      ['sonso', 'sonso de yuca', 'zonzo'],
      '**Sonso de yuca**:\n'
          '1. Cocina 1 kg de yuca pelada hasta que esté blandita y muélela '
          'caliente.\n'
          '2. Mézclala con unos 300 g de queso rallado, un poco de mantequilla '
          'o leche y sal.\n'
          '3. Arma en una fuente enmantequillada (o en palitos) y al horno o a '
          'la parrilla hasta que dore.',
    ),
    (
      ['cunape', 'cunapes'],
      '**Cuñapé** (unos 20):\n'
          '1. Mezcla 500 g de almidón de yuca con 500 g de queso fresco '
          'rallado.\n'
          '2. Agrega un huevo, una pizca de sal y leche de a poco, hasta tener '
          'una masa suave.\n'
          '3. Haz bolitas y al horno fuerte unos 15 a 20 minutos, hasta que '
          'doren.\n\n'
          'Se comen calentitos, con café.',
    ),
    (
      ['api', 'api morado'],
      '**Api morado**:\n'
          '1. Disuelve unas 4 cucharadas de harina de maíz morado en agua '
          'fría.\n'
          '2. Hierve 1 litro de agua con canela y clavo de olor, y agrega la '
          'mezcla moviendo sin parar para que no se hagan grumos.\n'
          '3. Cocina unos 10 minutos a fuego bajo y endulza a gusto.\n\n'
          'Va con buñuelos o con pastel.',
    ),
    (
      ['masaco'],
      '**Masaco**:\n'
          '1. Cocina o fríe plátano verde (o yuca).\n'
          '2. Machácalo caliente con queso rallado o con charque frito.\n'
          '3. Forma bolitas y dóralas un poquito.\n\n'
          'Perfecto con café o con un jugo.',
    ),
    (
      ['pique macho', 'pique'],
      '**Pique macho**:\n'
          '1. Corta carne en tiras y fríela con cebolla, tomate y locoto. Suma '
          'salchicha en rodajas.\n'
          '2. Sirve todo sobre papas fritas.\n'
          '3. Arriba, huevo duro y más locoto.\n\n'
          'Es de Cochabamba y se come entre varios.',
    ),
    (
      ['silpancho'],
      '**Silpancho**:\n'
          '1. Aplana la carne bien delgadita y apánala.\n'
          '2. Fríela.\n'
          '3. Sirve sobre arroz y papas en rodajas fritas, con un huevo frito '
          'encima y una ensalada de tomate, cebolla y locoto.',
    ),
    (
      ['sopa de mani'],
      '**Sopa de maní**:\n'
          '1. Licúa maní crudo con agua.\n'
          '2. Hierve carne (costilla o pollo) con verduras.\n'
          '3. Agrega el maní licuado, moviendo para que no se pegue, y fideo o '
          'arroz.\n'
          '4. Al servir, papas fritas encima y perejil.',
    ),
    (
      ['bife', 'bife de carne', 'bife a caballo'],
      '**Bife** a la boliviana:\n'
          '1. Corta filetes de carne (lomo o pulpa) de un dedo de grosor. '
          'Sal, pimienta y un poco de ajo.\n'
          '2. Sartén bien caliente con poquito aceite: 2 o 3 minutos por lado, '
          'sin moverlo mucho.\n'
          '3. Déjalo reposar un minuto antes de cortarlo, así no suelta el '
          'jugo.\n'
          '4. Sirve con arroz, papas fritas y ensalada. Con un huevo frito '
          'encima es "a caballo".',
    ),
    (
      ['salchipapa', 'salchipapas'],
      '**Salchipapa**:\n'
          '1. Corta papas en bastones, lávalas, sécalas y fríelas hasta que '
          'doren.\n'
          '2. Corta salchichas en rodajas y dóralas en la sartén.\n'
          '3. Junta todo y ponle salsas: mayonesa, kétchup, mostaza y llajua.\n\n'
          'Con huevo frito encima queda todavía mejor.',
    ),
    (
      ['tucumana', 'tucumanas'],
      '**Tucumana**:\n'
          '1. Relleno: carne o pollo picado con cebolla, papa en cubitos, '
          'arvejas, huevo duro y aceituna, bien sazonado con comino y ají '
          'colorado.\n'
          '2. Masa: harina, manteca, un huevo, sal y agua tibia; estírala en '
          'discos.\n'
          '3. Rellena, cierra con repulgue y fríela en aceite caliente hasta '
          'que dore.\n\n'
          'Se come con salsitas: ensalada de cebolla y tomate, llajua y '
          'mostaza.',
    ),
    (
      ['llajua', 'llajwa'],
      '**Llajua**:\n'
          '1. Muele (en batán si tienes; si no, en licuadora) 2 tomates y 1 o '
          '2 locotos sin pepas.\n'
          '2. Agrega quirquiña o perejil picado y sal.\n\n'
          'Va con casi todo. Si la quieres menos picante, usa menos locoto.',
    ),
    (
      ['anticucho', 'anticuchos'],
      '**Anticuchos**:\n'
          '1. Corta corazón de res en cubos y adóbalo varias horas con ají '
          'colorado, ajo, comino, vinagre y sal.\n'
          '2. Ensártalo en palitos.\n'
          '3. A la parrilla, pintándolo con el adobo, hasta que dore.\n'
          '4. Sirve con papa cocida y salsa de maní con ají.',
    ),
    (
      ['chicharron', 'chicharron de cerdo'],
      '**Chicharrón** de cerdo:\n'
          '1. Corta carne de cerdo con algo de grasa en trozos y sálala.\n'
          '2. Cocínala en una olla con un poco de agua y ajo, a fuego medio, '
          'hasta que el agua se evapore.\n'
          '3. Deja que se dore en su propia grasa, moviendo de vez en cuando.\n'
          '4. Sirve con mote, papa y llajua.',
    ),
    (
      ['locro', 'locro de gallina'],
      '**Locro** de gallina cruceño:\n'
          '1. Hierve la gallina (o pollo) en trozos con cebolla, ajo y sal.\n'
          '2. Agrega arroz y yuca en trozos, y cocina a fuego bajo moviendo '
          'para que espese.\n'
          '3. Al final, plátano maduro en rodajas y un poco de urucú para el '
          'color.\n\n'
          'Tiene que quedar espeso, no como sopa clara.',
    ),
    (
      ['fricase', 'fricace'],
      '**Fricasé**:\n'
          '1. Cocina carne de cerdo en trozos con cebolla, ajo, comino, '
          'orégano y ají amarillo molido, en bastante agua.\n'
          '2. Cuando esté blanda, espesa el caldo con un poco de pan molido.\n'
          '3. Sirve con mote, papa y chuño.',
    ),
    (
      ['huminta', 'humintas', 'humita', 'humitas'],
      '**Huminta**:\n'
          '1. Muele choclo tierno y mézclalo con queso rallado, un poco de '
          'manteca, azúcar, sal y anís.\n'
          '2. Envuelve porciones en chala (la hoja del choclo).\n'
          '3. Cocina al vapor o al horno hasta que esté firme, unos 40 '
          'minutos.',
    ),
    (
      ['bunuelo', 'bunuelos'],
      '**Buñuelos**:\n'
          '1. Mezcla 2 tazas de harina, 1 cucharadita de levadura, una pizca '
          'de sal, anís y agua tibia hasta tener una masa blandita. Déjala '
          'reposar una hora.\n'
          '2. Con las manos mojadas, estira porciones y fríelas en aceite bien '
          'caliente.\n'
          '3. Sirve con miel o jarabe de chancaca, junto a un api.',
    ),
    (
      ['arroz con leche'],
      '**Arroz con leche**:\n'
          '1. Cocina 1 taza de arroz en 2 tazas de agua con canela y clavo de '
          'olor.\n'
          '2. Cuando se consuma el agua, agrega 1 litro de leche y azúcar a '
          'gusto; cocina a fuego bajo, moviendo, hasta que espese.\n'
          '3. Sirve con canela en polvo, frío o tibio.',
    ),
    (
      ['mocochinchi'],
      '**Mocochinchi**:\n'
          '1. Lava los duraznos deshidratados y déjalos en remojo una hora.\n'
          '2. Hiérvelos 20 minutos en agua con canela y azúcar.\n'
          '3. Enfría y sirve bien helado, con un durazno en cada vaso.',
    ),
    (
      ['somo'],
      '**Somó**:\n'
          '1. Cocina maíz blanco pelado hasta que esté blando.\n'
          '2. Agrega leche, azúcar y canela, y hierve un poco más.\n'
          '3. Enfría y sirve bien frío.',
    ),
    (
      ['sandwich de chola', 'sanduche de chola'],
      '**Sándwich de chola**:\n'
          '1. Chancho al horno (pierna o lomo adobado con ajo, comino y sal), '
          'en láminas.\n'
          '2. Encurtido: cebolla, zanahoria y locoto en tiras, con vinagre y '
          'sal.\n'
          '3. Pan, chancho, encurtido y un poco de llajua.',
    ),
    (
      ['helado de canela'],
      '**Helado de canela**:\n'
          '1. Hierve agua con bastante canela, clavo de olor, azúcar y un '
          'poco de colorante rojo.\n'
          '2. Cuela y enfría.\n'
          '3. Congela, y cada media hora ráspalo con un tenedor para que '
          'quede granizado.',
    ),
    // -------------------------------------------------------- de todo el mundo
    (
      [
        'fideo',
        'fideos',
        'fideo con salsa',
        'fideos con salsa',
        'pasta',
        'tallarin',
        'tallarines',
        'espagueti',
        'espaguetis',
        'spaghetti',
      ],
      '**Fideo con salsa** (para 2):\n'
          '1. Hierve agua con sal: 1 litro por cada 100 g de fideo.\n'
          '2. Echa el fideo y cocínalo lo que diga el paquete (8 a 12 '
          'minutos), moviendo al inicio para que no se pegue.\n'
          '3. Salsa: fríe ajo y cebolla, suma tomate picado, sal y orégano, y '
          'deja 10 minutos a fuego bajo.\n'
          '4. Cuela el fideo, mézclalo con la salsa y, si hay, queso rallado '
          'encima.',
    ),
    (
      ['arroz', 'arroz blanco', 'arroz graneado'],
      '**Arroz blanco**:\n'
          '1. Fríe un diente de ajo picado en un poco de aceite.\n'
          '2. Agrega 1 taza de arroz y revuelve un minuto.\n'
          '3. Echa 2 tazas de agua caliente y sal.\n'
          '4. Cuando hierva, baja el fuego al mínimo, tapa y espera 15 a 18 '
          'minutos sin destapar.',
    ),
    (
      ['huevo frito', 'huevos fritos'],
      '**Huevo frito**: aceite caliente en la sartén, rompe el huevo con '
          'cuidado, sal, y báñale la clara con el aceite usando una cuchara. '
          'En dos minutos está; si te gusta la yema firme, dale vuelta.',
    ),
    (
      ['huevos revueltos', 'huevo revuelto'],
      '**Huevos revueltos**: bate 2 huevos con sal, échalos a la sartén con '
          'un poquito de mantequilla a fuego bajo y muévelos despacio con una '
          'espátula. Sácalos cuando estén cremosos: se terminan de cocinar '
          'solos.',
    ),
    (
      ['milanesa', 'milanesas', 'milanesa de pollo'],
      '**Milanesa**:\n'
          '1. Aplana filetes de carne (o pollo) bien finos. Sal y pimienta.\n'
          '2. Pásalos por harina, después por huevo batido y al final por pan '
          'rallado.\n'
          '3. Fríelos en aceite caliente, 2 o 3 minutos por lado.\n\n'
          'Va con arroz, papas fritas o puré, y limón.',
    ),
    (
      ['hamburguesa', 'hamburguesas'],
      '**Hamburguesa**:\n'
          '1. Mezcla 500 g de carne molida con sal, pimienta y un poco de ajo, '
          'y forma 4 discos.\n'
          '2. Plancha o sartén bien caliente: 3 o 4 minutos por lado. Al '
          'final, una lámina de queso encima.\n'
          '3. Arma el pan con lechuga, tomate, cebolla y tus salsas.',
    ),
    (
      ['pizza', 'pizzas'],
      '**Pizza** (para 2):\n'
          '1. Masa: 2 tazas de harina, 1 cucharadita de levadura, 1 de sal, 2 '
          'cucharadas de aceite y agua tibia hasta que no se pegue. Amasa 10 '
          'minutos y deja reposar una hora.\n'
          '2. Estírala en una bandeja aceitada.\n'
          '3. Salsa de tomate, queso mozzarella y lo que quieras arriba.\n'
          '4. Horno bien caliente (220 °C) unos 15 minutos.',
    ),
    (
      ['sushi', 'rollos de sushi', 'maki'],
      '**Sushi** en rollos:\n'
          '1. Lava arroz de grano corto hasta que el agua salga clara y '
          'cocínalo. Mézclalo tibio con vinagre de arroz, azúcar y sal.\n'
          '2. Sobre una esterilla, pon una hoja de alga nori y cúbrela con una '
          'capa fina de arroz.\n'
          '3. Relleno en una línea: salmón o kanikama, palta, pepino o queso '
          'crema.\n'
          '4. Enrolla apretando con la esterilla y corta con un cuchillo '
          'mojado.',
    ),
    (
      ['frappe', 'frappes', 'frape', 'frappuccino', 'frappe de cafe'],
      '**Frappé** de café:\n'
          '1. Prepara un café bien fuerte (o 2 cucharaditas de café '
          'instantáneo en un chorrito de agua) y déjalo enfriar.\n'
          '2. Licúalo con 1 taza de hielo, media taza de leche y azúcar a '
          'gusto.\n'
          '3. Si quieres, crema batida y chocolate encima.\n\n'
          'Sin café, con chocolate o con frutilla, también sale.',
    ),
    (
      ['brownie', 'brownies', 'browni', 'brownis'],
      '**Brownies**:\n'
          '1. Derrite 200 g de chocolate con 150 g de mantequilla.\n'
          '2. Mezcla con 200 g de azúcar, 3 huevos y una pizca de sal.\n'
          '3. Suma 100 g de harina, sin batir de más.\n'
          '4. Molde con papel, horno a 180 °C por 20 a 25 minutos: el centro '
          'tiene que quedar un poco húmedo.',
    ),
    (
      ['queque', 'torta', 'bizcochuelo', 'pastel', 'keke', 'torta casera'],
      '**Queque** (torta básica):\n'
          '1. Bate 3 huevos con 1 taza de azúcar hasta que esponje.\n'
          '2. Suma media taza de aceite y 1 taza de leche.\n'
          '3. Agrega 2 tazas de harina con 2 cucharaditas de polvo de hornear '
          'y mezcla suave.\n'
          '4. Molde enmantequillado, horno a 180 °C por 35 a 40 minutos: está '
          'listo cuando un palito sale limpio.',
    ),
    (
      ['panqueque', 'panqueques', 'pancakes', 'hotcakes', 'crepas', 'crepes'],
      '**Panqueques** (unos 8):\n'
          '1. Mezcla 1 taza de harina, 1 huevo, 1 taza de leche, 1 cucharada de '
          'azúcar y una pizca de sal hasta que no queden grumos.\n'
          '2. Sartén caliente apenas aceitada: echa un cucharón y mueve para '
          'que se extienda.\n'
          '3. Cuando se despegue el borde, dale vuelta.\n\n'
          'Con dulce de leche, miel o fruta.',
    ),
    (
      ['galletas', 'galleta', 'galletas con chispas', 'cookies'],
      '**Galletas** con chispas:\n'
          '1. Bate 125 g de mantequilla blanda con 1 taza de azúcar.\n'
          '2. Suma 1 huevo y un poco de vainilla.\n'
          '3. Agrega 2 tazas de harina, media cucharadita de bicarbonato y '
          'chispas de chocolate.\n'
          '4. Bolitas separadas en la bandeja, horno a 180 °C por 10 a 12 '
          'minutos. Salen blanditas y se endurecen al enfriar.',
    ),
    (
      ['flan'],
      '**Flan**:\n'
          '1. Caramelo: derrite media taza de azúcar en el molde hasta que se '
          'dore y cubre el fondo.\n'
          '2. Licúa 4 huevos, 1 lata de leche condensada, la misma medida de '
          'leche y vainilla.\n'
          '3. Vierte sobre el caramelo y hornea a baño maría a 180 °C unos 50 '
          'minutos.\n'
          '4. Enfría (mejor de un día para otro) y desmolda.',
    ),
    (
      ['papas fritas', 'papa frita'],
      '**Papas fritas** crocantes:\n'
          '1. Córtalas en bastones, lávalas y sécalas bien.\n'
          '2. Primera fritura a fuego medio, 5 minutos, sin que doren.\n'
          '3. Sácalas, sube el fuego y fríelas otra vez hasta que estén '
          'doradas.\n'
          '4. Sal al final.',
    ),
    (
      ['pollo frito', 'pollo broaster', 'broaster'],
      '**Pollo frito**:\n'
          '1. Marina las presas con sal, ajo, pimienta y un poco de limón, '
          'mínimo una hora.\n'
          '2. Pásalas por harina con sal y paprika, después por huevo y otra '
          'vez por harina.\n'
          '3. Fríelas a fuego medio unos 15 minutos, dando vuelta, hasta que '
          'estén doradas y cocidas por dentro.',
    ),
    (
      ['arroz chaufa', 'chaufa'],
      '**Arroz chaufa**:\n'
          '1. Usa arroz cocido frío (el del día anterior es ideal).\n'
          '2. En sartén bien caliente, saltea pollo en cubitos.\n'
          '3. Suma huevo revuelto, cebollín y el arroz, y mezcla rápido.\n'
          '4. Salsa de soya y, si hay, un toque de aceite de sésamo.',
    ),
    (
      ['ceviche', 'cebiche'],
      '**Ceviche**:\n'
          '1. Corta pescado blanco bien fresco en cubos.\n'
          '2. Cúbrelo con jugo de limón recién exprimido, sal, ají y cebolla '
          'morada en tiras.\n'
          '3. Espera 10 a 15 minutos y sirve con cilantro, camote y choclo.',
    ),
    (
      ['guacamole'],
      '**Guacamole**: pisa 2 paltas maduras y mézclalas con cebolla y tomate '
          'picaditos, jugo de limón, sal y cilantro. El limón evita que se '
          'ponga negro.',
    ),
    (
      ['limonada'],
      '**Limonada**: el jugo de 4 limones, 1 litro de agua fría, azúcar a '
          'gusto y mucho hielo. Si la licúas con un poco de cáscara y la '
          'cuelas, queda más aromática (y con un toque amargo).',
    ),
    (
      ['licuado', 'licuados', 'batido', 'smoothie', 'jugo con leche'],
      '**Licuado** de frutas: 1 taza de fruta (plátano, frutilla, papaya...), '
          '1 taza de leche, azúcar a gusto y hielo. Licúa un minuto y listo.',
    ),
    (
      ['milkshake', 'malteada', 'batido de helado'],
      '**Milkshake**: licúa 3 bochas de helado con media taza de leche fría. '
          'Con menos leche sale más espeso.',
    ),
  ];
}
