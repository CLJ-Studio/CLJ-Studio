import 'dart:math';

import '../modelos/mensaje_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'lenguaje_macias.dart';

/// Un plato: como se lo nombra (ya normalizado) y que es.
typedef _Entrada = (List<String>, String);

/// Una receta, completa: como se la nombra, para cuantos rinde, cuanto
/// tarda, que lleva, como se hace y un consejo.
typedef Receta = ({
  List<String> nombres,
  String titulo,
  String rinde,
  String tiempo,
  List<String> ingredientes,
  List<String> pasos,
  String tip,
});

/// La cocina de MacIAs: recetas caseras, sobre todo bolivianas, ideas de
/// que cocinar, trucos de cocina y que es cada plato.
///
/// Recetas de casa, con tazas y cucharas: para cocinar en un departamento de
/// estudiante, no en un restaurante. Las cantidades son orientativas.
abstract final class CocinaMacias {
  /// La receta, un truco, unas ideas o "esa no la tengo". Null si no se
  /// hablaba de cocinar.
  static RespuestaCharla? responder(String t, ContextoMacias c) {
    // Las ideas, solo si son todo el mensaje: "¿qué desayuno?" pide una
    // idea; "¿qué desayuno venden hoy?" pregunta por la app.
    final solo = t.replaceFirst(RegExp(r'^(?:y|oye) '), '');
    final categoria = _ideasPorFrase[solo];
    if (categoria != null) return ideas(categoria, c);
    for (final (claves, explicacion) in _sueltas) {
      if (claves.contains(solo)) {
        return RespuestaCharla(explicacion, intencion: 'saber:cocina');
      }
    }

    // "Puedo vender una olla a presión", "me vendieron pan viejo": es de la
    // app, aunque nombre algo de cocina.
    if (!deLaApp.hasMatch(t)) {
      final texto = ' $t ';
      for (final (claves, explicacion) in _trucos) {
        if (claves.any((clave) => coincide(clave, t, texto))) {
          return RespuestaCharla(explicacion, intencion: 'saber:cocina');
        }
      }
    }

    final conLoQueHay =
        _conIngredientes.firstMatch(t) ?? _tengoIngredientes.firstMatch(t);
    if (conLoQueHay != null) {
      final respuesta = _conLoQueHay(conLoQueHay[1]!, c);
      if (respuesta != null) return respuesta;
    }
    // "Tengo pollo", "me quedan dos papas": solo comida, se le busca receta.
    final soloTengo = _soloTengo.firstMatch(t);
    if (soloTengo != null && _todoEsComida(soloTengo[1]!)) {
      final respuesta = _conLoQueHay(soloTengo[1]!, c);
      if (respuesta != null) return respuesta;
    }

    if (_otraReceta.hasMatch(t)) return otra(c);

    for (final patron in _cuantoTarda) {
      final pregunta = patron.firstMatch(t);
      if (pregunta == null) continue;
      final cosa = pregunta[1]!.trim();
      final receta = buscar(cosa);
      if (receta != null) {
        return RespuestaCharla(
          '**${receta.titulo}**: ${receta.tiempo}, más o menos '
          '(${receta.rinde}). Si quieres el paso a paso, escribe **receta de '
          '${receta.nombres.first}**.',
          intencion: 'saber:receta',
        );
      }
      if (_seHierve.contains(_canonica(_sinArticulo(cosa)))) {
        return const RespuestaCharla(
          _tiemposDeCoccion,
          intencion: 'saber:cocina',
        );
      }
    }

    final pedido = _pideReceta.firstMatch(t);
    if (pedido == null) return null;
    final forma = pedido[1]!;
    final plato = pedido[2]!.trim();
    final receta = buscar(plato);
    if (receta != null) {
      if (RegExp(r'lleva|ingredientes').hasMatch(forma)) {
        return RespuestaCharla(
          '**${receta.titulo}** (${receta.rinde}) lleva:\n'
          '${receta.ingredientes.map((i) => '• $i').join('\n')}\n\n'
          'Para el paso a paso, escribe **receta de ${receta.nombres.first}**.',
          intencion: 'saber:receta',
        );
      }
      return RespuestaCharla(_escrita(receta), intencion: 'saber:receta');
    }
    // "Receta de pollo": ninguna se llama asi, pero varias lo llevan.
    final conEso = _conLoQueHay(plato, c, nombrado: true);
    if (conEso != null) return conEso;
    // "Receta de X", "¿cómo cocino X?": se hablaba de cocina, aunque ese
    // plato no este. "¿Cómo se hace una tesis?" no: eso sigue de largo.
    if (!_soloCocina.hasMatch(forma)) return null;
    return const RespuestaCharla(
      'Esa receta no la tengo todavía, perdón. Pídeme otra: tengo majadito, '
      'salteñas, salchipapa, lasaña, brownies, sushi y muchas más.',
      intencion: 'saber:receta_desconocida',
    );
  }

  /// La receta que se nombra, ya escrita. Null si no esta.
  ///
  /// Con [exacta], el nombre tiene que ser el de una receta (sin faltas):
  /// para un mensaje suelto, donde una falta podria ser otra palabra.
  static RespuestaCharla? receta(String nombre, {bool exacta = false}) {
    final receta = exacta ? CocinaMacias.exacta(nombre) : buscar(nombre);
    return receta == null
        ? null
        : RespuestaCharla(_escrita(receta), intencion: 'saber:receta');
  }

  /// La receta que se llama asi, sin tolerar faltas. Null si no hay.
  static Receta? exacta(String nombre) =>
      _exacta(_sinArticulo(nombre.trim()).trim());

  /// Despues de "¿cuál te paso?": "el majadito", "la de pollo frito".
  static RespuestaCharla? elegida(String t) {
    final nombre = t.replaceFirst(
      RegExp(
        r'^(?:y |ok |ya |dale |bueno |mmm )?(?:pasame |dame |quiero |mejor |'
        r'prefiero |me quedo con |esa de |esa del |la de |la del |el de |'
        r'el del |la receta de |la receta del |receta de |receta del )*',
      ),
      '',
    );
    return receta(nombre);
  }

  /// Una receta que no se haya mostrado hace poco: "otra receta".
  static RespuestaCharla otra(ContextoMacias c) {
    final nuevas = [
      for (final r in recetas)
        if (!c.recientes.any((dicho) => dicho.contains('**${r.titulo}**'))) r,
    ];
    final lista = nuevas.isEmpty ? recetas : nuevas;
    return RespuestaCharla(
      _escrita(lista[c.sorteo % lista.length]),
      intencion: 'saber:receta',
    );
  }

  /// Unas cuantas recetas de una [categoria], para tocar la que se quiera.
  static RespuestaCharla ideas(String categoria, ContextoMacias c) {
    final nombres = List.of(_categorias[categoria] ?? _categorias['facil']!)
      ..shuffle(Random(c.sorteo));
    final elegidas = [for (final nombre in nombres.take(4)) buscar(nombre)!];
    final (entrada, despues) = switch (categoria) {
      'dulce' => (
        c.alguna(const [
          'Para el antojo dulce, estas salen bien en casa.',
          'Postres que no fallan.',
        ]),
        '',
      ),
      'boliviana' => (
        c.alguna(const ['Comida boliviana, de la buena.', 'De lo nuestro.']),
        '',
      ),
      'saludable' => (
        c.alguna(const [
          'Livianas y que igual llenan.',
          'Para comer sano sin aburrirte.',
        ]),
        '',
      ),
      'bebida' => (
        c.alguna(const [
          'Para tomar, fríos o calentitos según el día.',
          'Unas bebidas que salen fácil.',
        ]),
        '',
      ),
      'desayuno' => (
        c.alguna(const [
          'Desayunos que salen rápido.',
          'Para arrancar el día con energía.',
        ]),
        '\n\nY si no tienes ganas de cocinar, en la app seguro alguien vende '
            'algo para el desayuno.',
      ),
      'cena' => (
        c.alguna(const [
          'Cenas livianas y rápidas.',
          'Para la noche, algo liviano.',
        ]),
        '',
      ),
      'llevar' => (
        'Para llevar a la U, estas aguantan bien hasta el almuerzo.',
        '\n\nCiérralo bien y, si puedes, guárdalo en frío hasta la hora de '
            'comer.',
      ),
      'vender' => (
        'Para vender en el campus, estas salen bien: se hacen en cantidad, '
            'aguantan y se llevan fácil.',
        '\n\nCuando la tengas lista, publícala en U market: es gratis y no '
            'cobramos comisión.',
      ),
      'barata' => (
        'Baratas y que llenan.',
        '\n\nComprar en el mercado (no en el súper) y cocinar para varios días '
            'baja mucho el gasto.',
      ),
      _ => (
        c.alguna(const [
          'Fáciles y ricas, para salir del apuro.',
          'Cualquiera de estas sale sin drama.',
          'Te propongo estas, que salen fácil.',
        ]),
        '\n\nY si me dices qué tienes en la cocina (**tengo arroz y huevo, '
            '¿qué cocino?**), te digo qué sale.',
      ),
    };
    return RespuestaCharla(
      '$entrada ¿Cuál te paso?$despues',
      intencion: 'saber:recetas',
      espera: const EsperaReceta(),
      opciones: [for (final r in elegidas) _comoOpcion(r)],
    );
  }

  static OpcionMacias _comoOpcion(Receta r) =>
      OpcionMacias(id: 'r:${r.nombres.first}', texto: r.titulo);

  /// Comprar, vender, pedidos: eso es de la app.
  static final deLaApp = RegExp(
    r'\b(?:vend\w*|compr\w*|precio|precios|pedido|pedidos|publicar|publico|'
    r'publicacion|local|carrito|entrega)\b',
  );

  /// Una clave con "=" adelante tiene que ser el mensaje entero: "pan duro"
  /// solo es una duda de cocina; "me vendieron pan duro", no.
  static bool coincide(String clave, String t, String texto) =>
      clave.startsWith('=')
      ? t == clave.substring(1)
      : texto.contains(' $clave ');

  static final _soloTengo = RegExp(
    r'^(?:solo |nomas )?(?:tengo|me queda|me quedan|me sobro|me sobraron) (.+)$',
  );

  /// Si todo lo que nombra es comida: "pollo", "dos papas y un huevo".
  static bool _todoEsComida(String lista) {
    const relleno = {
      'y',
      'e',
      'o',
      'con',
      'un',
      'una',
      'unos',
      'unas',
      'poco',
      'de',
      'algo',
      'media',
      'medio',
      'el',
      'la',
      'los',
      'las',
      'mas',
      'tambien',
      'dos',
      'tres',
      'cuatro',
      'cinco',
      'kilo',
      'kilos',
      'lata',
      'latas',
      'bolsa',
    };
    var alguna = false;
    for (final palabra in lista.split(' ')) {
      if (relleno.contains(palabra) || RegExp(r'^\d+$').hasMatch(palabra)) {
        continue;
      }
      if (!_alimentos.contains(_canonica(palabra))) return false;
      alguna = true;
    }
    return alguna;
  }

  /// La receta como se muestra: ingredientes, pasos y el consejo.
  static String _escrita(Receta r) {
    final pasos = [
      for (final (i, paso) in r.pasos.indexed) '${i + 1}. $paso',
    ].join('\n');
    return '**${r.titulo}** · ${r.rinde} · ${r.tiempo}\n\n'
        '**Ingredientes**\n'
        '${r.ingredientes.map((i) => '• $i').join('\n')}\n\n'
        '**Paso a paso**\n$pasos'
        '${r.tip.isEmpty ? '' : '\n\n**Tip:** ${r.tip}'}';
  }

  static String _lista(List<String> cosas) {
    if (cosas.length <= 1) return cosas.join();
    return '${cosas.sublist(0, cosas.length - 1).join(', ')} y ${cosas.last}';
  }

  // ============================================================ entender
  static final _otraReceta = RegExp(
    r'^(?:dame |dime |pasame |una )?(?:otra receta|receta al azar|receta del dia|'
    r'una receta cualquiera|cualquier receta|sorprendeme con una receta)$',
  );

  static final _cuantoTarda = [
    RegExp(
      r'^(?:y )?cuanto (?:tiempo )?(?:tarda|tardan|demora|demoran|se demora|'
      r'se tarda|lleva|toma|se cocina|se cocinan|se hierve|se hierven|'
      r'se hornea|se frie|hierve|hierven) '
      r'(?:en )?(?:(?:hacer|hacerse|cocinar|cocinarse|preparar|hornear|'
      r'hervir|cocer|cocerse|freir|estar listo|estar lista) )?'
      r'(?:el |la |los |las |un |una |unos |unas )?(.+)$',
    ),
    RegExp(
      r'^(?:y )?en cuanto tiempo (?:se hace|se hacen|se cocina|se cocinan|'
      r'esta listo|esta lista|estan listos|se prepara|se preparan|hago|cocino) '
      r'(?:el |la |los |las |un |una |unos |unas )?(.+)$',
    ),
  ];

  static final _pideReceta = RegExp(
    r'^(?:y |si |oye |y si )?'
    r'((?:me )?(?:sabes|puedes|podrias) (?:hacer|cocinar|preparar)|'
    r'como (?:se hace|se hacen|se prepara|se preparan|hago|hacer|preparo|'
    r'preparar|cocino|cocinar|se cocina|se cocinan|hiervo|hervir|se hierve|'
    r'horneo|hornear|se hornea)|'
    r'(?:dame |pasame |tienes |me pasas |me das |sabes )?(?:la |una |tu )?'
    r'receta (?:de|del|para)|'
    r'ensename a (?:hacer|preparar|cocinar)|quiero (?:hacer|cocinar|preparar)|'
    r'(?:que )?(?:ingredientes )?lleva|ingredientes (?:de|del|para)) '
    r'(.+)$',
  );

  /// Las formas de preguntar que solo pueden ser de cocina.
  static final _soloCocina = RegExp(r'receta|ingredientes|cocinar|cocino');

  static final _conIngredientes = RegExp(
    r'^(?:y )?(?:(?:que|q) (?:puedo |se puede |podria )?(?:cocinar|hacer|'
    r'preparar|cocino|hago|preparo|hago de comer) con|'
    r'recetas? (?:con|que lleven?|que tengan?|que usen?)|'
    r'(?:algo|comida) (?:rico |rica |facil )?con) (.+)$',
  );
  static final _tengoIngredientes = RegExp(
    r'^(?:en (?:mi|la) (?:casa|cocina|heladera|refri|refrigerador|depa|'
    r'departamento) )?(?:solo |nomas )?(?:tengo|hay|me queda|me quedan|'
    r'me sobro|me sobraron|sobro|sobraron) (.+?) (?:que|q) '
    r'(?:puedo |se puede |podria )?(?:cocinar|hacer|preparar|cocino|hago|'
    r'preparo|comer|como|hago de comer)(?: con eso| con esto)?$',
  );

  // ======================================================== ingredientes
  /// "Tengo arroz y huevo": las recetas que mas de eso llevan. Con
  /// [nombrado], lo pidio como si fuera un plato ("receta de pollo").
  static RespuestaCharla? _conLoQueHay(
    String lista,
    ContextoMacias c, {
    bool nombrado = false,
  }) {
    final pedidos = <String>{
      for (final palabra in lista.split(' '))
        if (_canonica(palabra) case final alimento
            when _alimentos.contains(alimento))
          alimento,
    };
    if (pedidos.isEmpty) return null;
    final puntajes = <(int, int)>[];
    for (final (i, lleva) in _lleva.indexed) {
      final usa = pedidos.where(lleva.contains).length;
      if (usa == 0) continue;
      final enElNombre = pedidos.where(_enElTitulo[i].contains).length;
      puntajes.add((i, usa * 10 + enElNombre));
    }
    if (puntajes.isEmpty) {
      if (nombrado) return null;
      return const RespuestaCharla(
        'Con eso todavía no tengo recetas, perdón. Dime otra cosa que '
        'tengas, o pídeme ideas: **¿qué cocino hoy?**',
        intencion: 'saber:recetas',
      );
    }
    puntajes.sort(
      (a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1),
    );
    final mejores = [for (final (i, _) in puntajes.take(5)) recetas[i]];
    final dichos = [
      for (final palabra in lista.split(' '))
        if (_alimentos.contains(_canonica(palabra))) palabra,
    ];
    return RespuestaCharla(
      nombrado
          ? 'Con **${_lista(dichos)}** tengo estas. ¿Cuál te paso?'
          : c.alguna(const [
              'Con eso te salen estas. ¿Cuál te paso?',
              'Con eso hay para rato. Mira, ¿cuál te paso?',
            ]),
      intencion: 'saber:recetas',
      espera: const EsperaReceta(),
      opciones: [for (final r in mejores) _comoOpcion(r)],
    );
  }

  /// Las palabras de cada receta (titulo e ingredientes), ya en su forma
  /// comparable. En el mismo orden que [recetas].
  static final List<Set<String>> _lleva = [
    for (final r in recetas)
      {
        for (final p in LenguajeMacias.normalizar(
          '${r.titulo} ${r.ingredientes.join(' ')}',
        ).split(' '))
          _canonica(p),
      },
  ];

  /// Las palabras de sus nombres: "ensalada de lechuga" nombra la lechuga.
  static final List<Set<String>> _enElTitulo = [
    for (final r in recetas)
      {
        for (final p in LenguajeMacias.normalizar(
          '${r.titulo} ${r.nombres.join(' ')}',
        ).split(' '))
          _canonica(p),
      },
  ];

  /// Una palabra en singular y con su nombre de siempre: "papas" es "papa",
  /// "chancho" es "cerdo", "espagueti" es "fideo".
  static String _canonica(String palabra) {
    final singular = _sinonimos[palabra] ?? _singular(palabra);
    return _sinonimos[singular] ?? singular;
  }

  static String _singular(String palabra) {
    // "limones", "panes", "frejoles": consonante + es. "tomates": vocal + s.
    if (palabra.length > 4 &&
        palabra.endsWith('es') &&
        'lnrdj'.contains(palabra[palabra.length - 3])) {
      return palabra.substring(0, palabra.length - 2);
    }
    if (palabra.length > 3 && palabra.endsWith('s')) {
      return palabra.substring(0, palabra.length - 1);
    }
    return palabra;
  }

  static const _sinonimos = {
    'chancho': 'cerdo',
    'puerco': 'cerdo',
    'res': 'carne',
    'frijol': 'frejol',
    'poroto': 'frejol',
    'pasta': 'fideo',
    'tallarin': 'fideo',
    'espagueti': 'fideo',
    'spaghetti': 'fideo',
    'aguacate': 'palta',
    'banana': 'platano',
    'guineo': 'platano',
    'nueces': 'nuez',
    'fresa': 'frutilla',
    'elote': 'choclo',
    'pimiento': 'pimenton',
    'hongo': 'champinon',
    'tocineta': 'tocino',
    'panceta': 'tocino',
    'bacon': 'tocino',
    'pechuga': 'pollo',
    'presa': 'pollo',
    'huevito': 'huevo',
    'ajies': 'aji',
    'papita': 'papa',
  };

  /// Lo que cuenta como alimento al decir "tengo...". Lo demas ("tengo
  /// examen", "tengo tiempo") no se busca en las recetas.
  static const _alimentos = {
    'arroz',
    'fideo',
    'papa',
    'yuca',
    'platano',
    'huevo',
    'pollo',
    'carne',
    'cerdo',
    'charque',
    'salchicha',
    'jamon',
    'queso',
    'leche',
    'harina',
    'pan',
    'tomate',
    'cebolla',
    'ajo',
    'locoto',
    'aji',
    'zanahoria',
    'arveja',
    'haba',
    'choclo',
    'maiz',
    'mote',
    'chuno',
    'quinua',
    'mani',
    'avena',
    'manzana',
    'frutilla',
    'papaya',
    'pina',
    'naranja',
    'limon',
    'palta',
    'atun',
    'pescado',
    'salmon',
    'camote',
    'repollo',
    'lechuga',
    'pepino',
    'pimenton',
    'champinon',
    'chocolate',
    'cacao',
    'cafe',
    'azucar',
    'miel',
    'mantequilla',
    'manteca',
    'crema',
    'yogur',
    'galleta',
    'tortilla',
    'lenteja',
    'frejol',
    'zapallo',
    'apio',
    'coco',
    'canela',
    'durazno',
    'linaza',
    'gelatina',
    'helado',
    'nuez',
    'almidon',
    'mayonesa',
    'soya',
    'curry',
    'tocino',
    'gallina',
    'cordero',
    'totopo',
    'kanikama',
    'cebollin',
    'jengibre',
    'hielo',
    'mozzarella',
    'parmesano',
    'condensada',
  };

  /// Lo que la tabla de tiempos de coccion responde.
  static const _seHierve = {
    'arroz',
    'fideo',
    'papa',
    'yuca',
    'huevo',
    'pollo',
    'carne',
    'lenteja',
    'frejol',
    'garbanzo',
    'quinua',
    'choclo',
    'mote',
    'chuno',
    'zanahoria',
    'camote',
    'haba',
    'arveja',
  };

  static const _tiemposDeCoccion =
      'Tiempos de cocción, más o menos:\n'
      '• **Arroz**: 15 a 18 minutos desde que hierve.\n'
      '• **Fideo**: 8 a 12 minutos (lo que diga el paquete).\n'
      '• **Papa**: entera, 20 a 25 minutos; en cubos, 10 a 15.\n'
      '• **Yuca**: 20 a 30 minutos.\n'
      '• **Huevo duro**: 10 a 12 minutos.\n'
      '• **Pollo** en presas, hervido: 30 a 40 minutos.\n'
      '• **Pechuga** a la plancha: 5 a 7 minutos por lado.\n'
      '• **Carne de res** para guiso: 1 hora y media a 2 (en olla a presión, '
      'unos 40 minutos).\n'
      '• **Lentejas**: 25 a 35 minutos, sin remojo.\n'
      '• **Frejoles o garbanzos**: una noche en remojo y 1 a 2 horas de hervor.\n'
      '• **Quinua**: 15 minutos.\n'
      '• **Choclo**: 15 a 20 minutos.\n\n'
      'En La Paz o El Alto todo tarda un poco más: allá el agua hierve a '
      'menos temperatura.';

  static String _sinArticulo(String texto) => texto.replaceFirst(
    RegExp(r'^(?:el|la|los|las|un|una|unos|unas|un poco de) '),
    '',
  );

  /// La receta que se nombra, con tolerancia: sin articulo, en singular,
  /// sin "casera" ni "fácil", o con una falta.
  static Receta? buscar(String nombre) {
    final limpio = _sinArticulo(
      nombre.trim(),
    ).replaceFirst(RegExp(r' (?:por favor|porfa|nomas|pues)$'), '').trim();
    if (limpio.isEmpty) return null;
    final sinAdornos = limpio
        .replaceFirst(
          RegExp(r'^(?:buen|buena|buenos|buenas|rico|rica|ricos|ricas) '),
          '',
        )
        .replaceFirst(
          RegExp(
            r' (?:casero|casera|caseros|caseras|facil|faciles|rapido|rapida|'
            r'rapidos|rapidas|sencillo|sencilla|rico|rica|ricos|ricas|'
            r'boliviano|boliviana|bolivianos|bolivianas)$',
          ),
          '',
        );
    return _exacta(limpio) ?? _exacta(sinAdornos) ?? _parecida(limpio);
  }

  static Receta? _exacta(String nombre) {
    final exacta = _indice[nombre];
    if (exacta != null) return exacta;
    if (nombre.endsWith('es')) {
      final singular = _indice[nombre.substring(0, nombre.length - 2)];
      if (singular != null) return singular;
    }
    if (nombre.endsWith('s')) {
      return _indice[nombre.substring(0, nombre.length - 1)];
    }
    return null;
  }

  /// Con una falta, solo en nombres largos: "silpanco", "lasanya".
  static Receta? _parecida(String nombre) {
    if (nombre.length < 6) return null;
    for (final MapEntry(key: clave, value: receta) in _indice.entries) {
      if (clave.length >= 6 && LenguajeMacias.distancia(clave, nombre) <= 1) {
        return receta;
      }
    }
    return null;
  }

  static final Map<String, Receta> _indice = {
    for (final receta in recetas)
      for (final nombre in receta.nombres) nombre: receta,
  };

  // ================================================================ ideas
  /// Que recetas sugerir para cada pedido, por su primer nombre.
  static const _categorias = <String, List<String>>{
    'facil': [
      'majadito',
      'bife',
      'salchipapa',
      'fideo',
      'panqueque',
      'omelette',
      'quesadilla',
      'arroz chaufa',
      'tostadas francesas',
      'ramen',
      'avena',
      'frappe',
      'brownie',
      'wrap de pollo',
      'pure de papa',
      'tortilla espanola',
      'sandwich',
      'fideo con atun',
      'nuggets',
    ],
    'dulce': [
      'brownie',
      'flan',
      'cheesecake',
      'mousse de chocolate',
      'arroz con leche',
      'galletas',
      'queque',
      'torta de chocolate',
      'panqueque',
      'waffles',
      'gelatina',
      'bunuelo',
      'ensalada de frutas',
      'helado de canela',
    ],
    'boliviana': [
      'saltena',
      'majadito',
      'silpancho',
      'pique macho',
      'sopa de mani',
      'salchipapa',
      'picante de pollo',
      'sajta',
      'chairo',
      'falso conejo',
      'fricase',
      'sonso',
      'cunape',
      'plato paceno',
      'charquekan',
      'locro',
      'tucumana',
      'anticucho',
      'masaco',
      'huminta',
      'sopa de quinua',
      'aji de fideo',
      'empanada de queso',
      'chicharron',
      'sandwich de chola',
      'arroz con queso',
      'pan de arroz',
    ],
    'saludable': [
      'sopa de quinua',
      'sopa de verduras',
      'ensalada de frutas',
      'avena',
      'wrap de pollo',
      'ensalada cesar',
      'pollo al horno',
      'omelette',
      'ceviche',
      'licuado',
      'curry de pollo',
      'lentejas',
      'pollo a la plancha',
      'ensalada',
    ],
    'bebida': [
      'mocochinchi',
      'api',
      'somo',
      'refresco de linaza',
      'limonada',
      'frappe',
      'licuado',
      'milkshake',
      'chocolate caliente',
      'cafe',
      'te helado',
    ],
    'desayuno': [
      'avena',
      'tostadas francesas',
      'huevos revueltos',
      'panqueque',
      'licuado',
      'omelette',
      'waffles',
      'cunape',
    ],
    'cena': [
      'omelette',
      'quesadilla',
      'sopa de verduras',
      'wrap de pollo',
      'ramen',
      'tortilla espanola',
      'sopa de fideo',
    ],
    'llevar': [
      'wrap de pollo',
      'arroz chaufa',
      'tortilla espanola',
      'ensalada cesar',
      'fideo',
      'empanada de queso',
      'ensalada de atun',
    ],
    'vender': [
      'brownie',
      'galletas',
      'cunape',
      'empanada de queso',
      'saltena',
      'tucumana',
      'alitas',
      'gelatina',
      'cheesecake',
      'arroz con leche',
      'pipocas',
      'sandwich',
    ],
    'barata': [
      'majadito',
      'arroz chaufa',
      'fideo',
      'tortilla espanola',
      'sopa de verduras',
      'sopa de fideo',
      'huevos revueltos',
      'pure de papa',
      'lentejas',
      'fideo con atun',
      'arroz con queso',
    ],
  };

  /// Como se piden las ideas, mensaje entero.
  static const _frasesDeIdeas = <(String, List<String>)>[
    (
      'vender',
      [
        'receta para vender',
        'recetas para vender',
        'que puedo cocinar para vender',
        'que cocino para vender',
        'recetas faciles para vender',
        'que receta puedo vender',
        'que puedo hornear para vender',
      ],
    ),
    (
      'facil',
      [
        'que cocino',
        'que cocino hoy',
        'que puedo cocinar',
        'que puedo cocinar hoy',
        'que preparo',
        'que preparo hoy',
        'que puedo preparar',
        'que hago de comer',
        'que hago de comer hoy',
        'que cocinar',
        'que cocinar hoy',
        'dame una receta',
        'una receta',
        'recetas',
        'recetas faciles',
        'receta facil',
        'una receta facil',
        'recetas rapidas',
        'recetas sencillas',
        'que recetas sabes',
        'que recetas tienes',
        'recetas para estudiantes',
        'comida facil',
        'algo facil de cocinar',
        'algo rapido de cocinar',
        'quiero cocinar',
        'quiero cocinar algo',
        'quiero cocinar algo rico',
        'quiero cocinar algo facil',
        'quiero preparar algo',
        'ensename a cocinar',
        'ensename a cocinar algo',
        'ideas de comida',
        'ideas para cocinar',
        'que cocino para el almuerzo',
        'que cocino para la cena',
        'recomiendame una receta',
        'sabes recetas',
        'tienes recetas',
      ],
    ),
    (
      'dulce',
      [
        'un postre',
        'postre',
        'postres',
        'recetas de postres',
        'receta de postre',
        'que postre hago',
        'que postre puedo hacer',
        'que postre preparo',
        'quiero hacer un postre',
        'quiero cocinar algo dulce',
        'quiero hacer algo dulce',
        'postres faciles',
        'un postre facil',
        'ideas de postres',
        'algo dulce para hacer',
      ],
    ),
    (
      'boliviana',
      [
        'comida boliviana',
        'recetas bolivianas',
        'platos bolivianos',
        'algo boliviano',
        'comida tipica',
        'platos tipicos',
        'recetas tipicas',
        'comida tipica boliviana',
        'platos tipicos de bolivia',
        'comida de bolivia',
        'recetas de bolivia',
        'quiero cocinar algo boliviano',
      ],
    ),
    (
      'saludable',
      [
        'algo saludable',
        'comida saludable',
        'recetas saludables',
        'algo sano',
        'comida sana',
        'recetas sanas',
        'algo light',
        'recetas light',
        'comida fit',
        'recetas fit',
        'que cocino saludable',
        'quiero cocinar sano',
        'quiero cocinar saludable',
      ],
    ),
    (
      'bebida',
      [
        'algo para tomar',
        'una bebida',
        'bebidas',
        'recetas de bebidas',
        'un refresco',
        'refrescos',
        'recetas de refrescos',
        'refrescos bolivianos',
        'algo frio para tomar',
        'algo caliente para tomar',
        'que preparo para tomar',
      ],
    ),
    (
      'desayuno',
      [
        'desayuno rapido',
        'desayunos rapidos',
        'que desayuno',
        'que desayuno hoy',
        'que puedo desayunar',
        'que me hago de desayuno',
        'que hago de desayuno',
        'desayuno facil',
        'desayunos faciles',
        'ideas de desayuno',
        'ideas para el desayuno',
        'desayuno para la u',
        'desayunos',
        'recetas de desayuno',
        'desayuno saludable',
        'desayunos saludables',
      ],
    ),
    (
      'cena',
      [
        'cena facil',
        'cenas faciles',
        'que ceno',
        'que ceno hoy',
        'que puedo cenar',
        'que hago de cena',
        'que me hago de cena',
        'cena rapida',
        'cenas rapidas',
        'ideas de cena',
        'ideas para la cena',
        'cena liviana',
        'cena saludable',
        'recetas de cena',
        'algo para la cena',
      ],
    ),
    (
      'llevar',
      [
        'almuerzo para llevar',
        'almuerzos para llevar',
        'que llevo de almuerzo',
        'que llevo para almorzar',
        'comida para llevar a la u',
        'que llevo a la u',
        'que llevo de comer a la u',
        'ideas de lonchera',
        'lonchera',
        'que pongo en mi tupper',
        'tupper',
      ],
    ),
    (
      'barata',
      [
        'comida barata para cocinar',
        'recetas baratas',
        'receta barata',
        'cocinar barato',
        'que cocino barato',
        'comidas baratas para cocinar',
        'como comer barato cocinando',
        'recetas economicas',
        'comida economica para cocinar',
        'cocinar con poca plata',
        'cocinar con poco dinero',
        'recetas con poco dinero',
        'recetas con poca plata',
      ],
    ),
  ];

  static final Map<String, String> _ideasPorFrase = {
    for (final (categoria, frases) in _frasesDeIdeas)
      for (final frase in frases) frase: categoria,
  };

  /// Ideas sin receta, mensaje entero.
  static const _sueltas = <(List<String>, String)>[
    (
      [
        'snack',
        'snacks',
        'algo para picar',
        'snacks para estudiar',
        'snack saludable',
        'snacks saludables',
        'algo para comer mientras estudio',
        'que como mientras estudio',
        'que como para estudiar',
      ],
      'Para picar mientras estudias: maní, fruta, yogur con granola, palitos '
          'de zanahoria, **pipocas caseras** o un **licuado**. Mejor que las '
          'papitas de bolsa, que te dejan con sueño y con más hambre.',
    ),
  ];

  /// Todos los nombres y textos, para las pruebas.
  static Iterable<(List<String>, String)> get entradas => [
    for (final r in recetas) (r.nombres, _escrita(r)),
    ...platos,
    for (final (claves, texto) in _trucos)
      ([for (final clave in claves) clave.replaceFirst('=', '')], texto),
    ..._sueltas,
    (const ['tiempos de coccion'], _tiemposDeCoccion),
    for (final (_, frases) in _frasesDeIdeas) (frases, ''),
  ];

  /// Las recetas que sugiere cada categoria, para las pruebas.
  static Iterable<String> get sugeridas => [
    for (final nombres in _categorias.values) ...nombres,
  ];

  // ================================================================ trucos
  static const _trucos = <(List<String>, String)>[
    (
      [
        'huevo duro',
        'huevos duros',
        'cuanto hierve un huevo',
        'cuanto tiempo hierve un huevo',
        'cuanto se hierve un huevo',
        'cuanto tiempo se hierve un huevo',
        'huevo tibio',
        'huevo pasado por agua',
      ],
      'Desde que el agua hierve:\n'
          '• **Pasado por agua**: 3 minutos.\n'
          '• **Tibio** (yema cremosa): 6 minutos.\n'
          '• **Duro**: 10 a 12 minutos.\n\n'
          'Después, pásalos a agua fría: así no se ponen verdosos y se pelan '
          'más fácil.',
    ),
    (
      [
        'se me pega el arroz',
        'arroz pegado',
        'arroz sin que se pegue',
        'que no se pegue el arroz',
        'arroz quemado',
        'arroz sale pegajoso',
        'arroz me sale pegajoso',
        'arroz me sale aguado',
        'arroz sale aguado',
        'arroz suelto',
      ],
      'Para un arroz que salga suelto:\n'
          '1. Usa la medida 1 de arroz por 2 de agua.\n'
          '2. Fríe el arroz un minuto en aceite antes del agua.\n'
          '3. Cuando hierva: fuego mínimo, tapa y **no lo muevas ni lo '
          'destapes**.\n'
          '4. A los 15 o 18 minutos, apágalo y déjalo tapado 5 minutos más.',
    ),
    (
      [
        'lavar el arroz',
        'se lava el arroz',
        'hay que lavar el arroz',
        'lavo el arroz',
      ],
      'Lavarlo le saca el almidón de afuera y sale más suelto (para el chaufa '
          'o el sushi, sí o sí). Para algo cremoso, como el arroz con leche, '
          'no hace falta. La **quinua**, en cambio, se lava siempre: si no, '
          'queda amarga.',
    ),
    (
      [
        'aceite esta caliente',
        'aceite esta listo',
        'aceite listo para freir',
        'temperatura del aceite',
      ],
      'Mete el mango de una cuchara de madera (o un palito) en el aceite: si '
          'salen burbujitas alrededor, está listo para freír. Si no burbujea, '
          'espera; si humea, está demasiado caliente: baja el fuego.',
    ),
    (
      [
        'descongelar',
        'descongelo',
        'descongelar la carne',
        'descongelar pollo',
      ],
      'Lo más seguro, de mejor a peor:\n'
          '• En la heladera, de un día para otro.\n'
          '• En una bolsa cerrada, sumergida en agua fría (cambia el agua cada '
          'media hora).\n'
          '• En el microondas, y lo cocinas enseguida.\n\n'
          'Lo que no conviene: dejarlo horas en la mesada, a temperatura '
          'ambiente.',
    ),
    (
      [
        'cuanto dura la comida',
        'cuanto dura en la heladera',
        'cuanto dura en el refri',
        'cuanto dura la comida cocida',
        'cuantos dias dura la comida',
        'comida guardada',
        'cuanto dura la comida en la heladera',
        'cuanto dura el arroz cocido',
        'cuanto dura el pollo cocido',
      ],
      'La comida cocida dura unos **3 o 4 días** en la heladera, bien tapada. '
          'En el congelador, un par de meses. Guárdala apenas se enfríe (no '
          'más de dos horas afuera), y si huele o se ve rara, a la basura.',
    ),
    (
      [
        'medidas de cocina',
        'cuanto es una taza',
        'cuantos gramos tiene una taza',
        'cuanto es una cucharada',
        'equivalencias de cocina',
        'taza a gramos',
        'cuantos ml tiene una taza',
      ],
      'Equivalencias de cocina, aproximadas:\n'
          '• 1 taza = 240 ml\n'
          '• 1 cucharada = 15 ml\n'
          '• 1 cucharadita = 5 ml\n'
          '• 1 taza de harina ≈ 125 g\n'
          '• 1 taza de azúcar ≈ 200 g\n'
          '• 1 taza de arroz ≈ 190 g',
    ),
    (
      [
        'cuanto arroz por persona',
        'cuanta pasta por persona',
        'cuanto fideo por persona',
        'cuanta carne por persona',
        'cuanto cocino por persona',
        'cuanto se cocina por persona',
        'porciones por persona',
        'cuanto arroz para dos',
        'cuanto arroz para 2',
      ],
      'Por persona, más o menos:\n'
          '• **Arroz**: media taza cruda (unos 90 g).\n'
          '• **Fideo**: 100 g secos.\n'
          '• **Carne o pollo**: 150 a 200 g.\n'
          '• **Papa**: 1 o 2 medianas.\n'
          '• **Legumbres**: un tercio de taza crudas.',
    ),
    (
      [
        'sustituto del huevo',
        'reemplazar el huevo',
        'sin huevo',
        'reemplazo del huevo',
        'en vez de huevo',
      ],
      'Para reemplazar 1 huevo en repostería:\n'
          '• 1 cucharada de linaza molida + 3 de agua (déjala 5 minutos).\n'
          '• Medio plátano maduro pisado.\n'
          '• 3 cucharadas de yogur.',
    ),
    (
      [
        'sin mantequilla',
        'reemplazar la mantequilla',
        'en vez de mantequilla',
        'sustituto de la mantequilla',
      ],
      'En vez de mantequilla puedes usar aceite: más o menos 3/4 de la '
          'cantidad (para 100 g de mantequilla, unos 75 ml de aceite). En '
          'galletas cambia un poco la textura; en tortas y queques, casi nada.',
    ),
    (
      ['sin horno', 'no tengo horno', 'sin tener horno', 'cocinar sin horno'],
      'Sin horno igual se puede:\n'
          '• **Cheesecake**, **mousse**, **gelatina** y **flan** a baño María '
          'en olla tapada: no necesitan horno.\n'
          '• Un **queque** sale en olla gruesa tapada, a fuego mínimo, sobre '
          'una rejilla, en unos 40 minutos.\n'
          '• **Pizza** en sartén con tapa: la masa abajo, fuego bajo, y tapada '
          'para que se derrita el queso.',
    ),
    (
      ['punto de nieve', 'claras a punto de nieve'],
      '**Punto de nieve**: bate las claras (sin nada de yema y en un bol bien '
          'seco) hasta que estén blancas y firmes. Sabes que está cuando das '
          'vuelta el bol y no se caen.',
    ),
    (
      ['bano maria', 'a bano maria'],
      'El **baño María** es cocinar o derretir algo dentro de un recipiente '
          'puesto sobre otro con agua caliente, para que el calor sea suave '
          'y parejo. Se usa para derretir chocolate o para hacer flan.',
    ),
    (
      ['al dente', 'pasta al dente', 'fideo al dente'],
      '**Al dente** es la pasta cocida pero firme al morder, sin estar dura '
          'en el centro. Sácala 1 o 2 minutos antes de lo que dice el paquete '
          'y pruébala.',
    ),
    (
      [
        'diferencia entre freir y saltear',
        'que es saltear',
        'que es sofreir',
        'diferencia entre sofreir y freir',
        'que es un sofrito',
      ],
      '• **Freír**: cocinar en bastante aceite caliente.\n'
          '• **Saltear**: cocinar rápido, a fuego fuerte, con poco aceite y '
          'moviendo (como el chaufa).\n'
          '• **Sofreír**: cocinar a fuego suave, con poco aceite, la cebolla, '
          'el ajo o el tomate, como base de una comida.',
    ),
    (
      [
        'cortar cebolla sin llorar',
        'cebolla sin llorar',
        'lloro con la cebolla',
        'llorar con la cebolla',
      ],
      'Para no llorar con la cebolla: usa un cuchillo bien afilado (aplasta '
          'menos y suelta menos gas) y métela antes un rato a la heladera. '
          'Cortarla cerca de la hornalla prendida también ayuda.',
    ),
    (
      [
        'ablandar la carne',
        'como ablandar la carne',
        'carne blanda',
        'carne suave',
        'carne me queda dura',
        'carne me sale dura',
        'carne queda dura',
      ],
      'Para que la carne quede blanda:\n'
          '• Córtala contra la fibra (en contra de las líneas que se ven).\n'
          '• Márinala un rato con algo ácido: limón, vinagre o yogur.\n'
          '• No la cocines de más: la carne pasada se pone dura.\n'
          '• Los cortes duros piden cocción larga a fuego bajo, en guiso.',
    ),
    (
      [
        'se me paso la sal',
        'se me fue la sal',
        'le eche mucha sal',
        'le puse mucha sal',
        'quedo muy salado',
        'quedo muy salada',
        'me quedo salado',
        'me quedo salada',
        'quitar la sal',
      ],
      'Lo único que funciona de verdad es diluir: suma más líquido (agua, '
          'caldo sin sal) o más de los ingredientes sin sal. Lo de la papa '
          'cruda que "absorbe la sal" ayuda muy poquito.',
    ),
    (
      [
        'como se si el pollo esta cocido',
        'como saber si el pollo esta cocido',
        'pollo esta cocido',
        'pollo esta listo',
        'pollo quedo crudo',
        'pollo esta crudo por dentro',
      ],
      'El pollo está listo cuando por dentro no queda nada rosado y, al '
          'pincharlo, el jugo sale transparente. Con termómetro: 74 °C en la '
          'parte más gruesa. El pollo crudo no se arriesga.',
    ),
    (
      [
        'como se si un huevo esta fresco',
        'huevo esta fresco',
        'huevo esta bueno',
        'huevo esta malo',
        'huevo podrido',
      ],
      'Ponlo en un vaso con agua:\n'
          '• Se hunde y queda acostado: **fresco**.\n'
          '• Se hunde pero queda parado: está bien, úsalo pronto.\n'
          '• Flota: **viejo**, mejor no.',
    ),
    (
      [
        'usar el microondas',
        'calentar en el microondas',
        'metal en el microondas',
        'aluminio en el microondas',
        'plastico en el microondas',
      ],
      'Para el microondas:\n'
          '• Nada de metal ni papel aluminio: hace chispas.\n'
          '• Tapa la comida (con otro plato) para que no salpique.\n'
          '• Revuelve a la mitad: calienta de afuera hacia adentro.\n'
          '• Los envases de plástico, solo si dicen que son aptos.',
    ),
    (
      ['freidora de aire', 'air fryer', 'airfryer', 'freidora sin aceite'],
      'En la **freidora de aire**:\n'
          '• Precaliéntala 3 a 5 minutos.\n'
          '• No la llenes: el aire tiene que circular.\n'
          '• Sacude o da vuelta a la mitad.\n'
          '• Papas: 180 a 200 °C, 15 a 20 minutos. Milanesas o nuggets: '
          '180 °C, 10 a 12. Alitas: 200 °C, 20 a 25.\n'
          '• Un poquito de aceite en spray y quedan más crocantes.',
    ),
    (
      ['olla a presion', 'olla de presion', 'olla express'],
      'Con la **olla a presión**:\n'
          '• No la llenes más de 2/3 (con legumbres, hasta la mitad: hacen '
          'espuma).\n'
          '• Revisa que la válvula y el empaque estén limpios.\n'
          '• Cuenta el tiempo desde que empieza a silbar, y baja el fuego.\n'
          '• Nunca la abras con presión: espera a que baje sola.\n\n'
          'Tiempos: carne de res 30 a 40 minutos, frejoles remojados 25 a 30, '
          'pollo 10 a 15.',
    ),
    (
      [
        'cocinar en la altura',
        'cocinar en la paz',
        'cocinar en el alto',
        'hervir en la altura',
        'agua hierve en la paz',
        'el agua hierve en la paz',
        'tarda mas en la paz',
      ],
      'En la altura el agua hierve antes de llegar a 100 °C: en La Paz, a '
          'unos 88 °C. Por eso:\n'
          '• Lo hervido tarda más (papa, fideo, carne, legumbres).\n'
          '• La olla a presión es tu mejor amiga: devuelve la temperatura que '
          'falta.\n'
          '• En repostería, un poco menos de polvo de hornear y un poco más de '
          'líquido: las masas suben más rápido y se secan.',
    ),
    (
      [
        'precalentar',
        'precalentar el horno',
        'temperatura del horno',
        'horno sin numeros',
        'horno moderado',
        'horno fuerte',
        'horno medio',
        'horno bajo',
      ],
      'Si tu horno no tiene números:\n'
          '• **Bajo**: unos 150 °C (merengues, cosas que se secan despacio).\n'
          '• **Medio o moderado**: 180 °C (tortas, queques, galletas).\n'
          '• **Fuerte**: 200 a 220 °C (pizza, pan, salteñas).\n\n'
          'Y siempre precalentado: préndelo 10 o 15 minutos antes de meter '
          'nada.',
    ),
    (
      [
        'torta esta lista',
        'queque esta listo',
        'torta esta cocida',
        'queque esta cocido',
        'se hundio la torta',
        'se hundio el queque',
        'torta se hundio',
        'queque se hundio',
        'torta quedo cruda',
        'queque quedo crudo',
      ],
      'Para saber si una torta está lista, pincha el centro con un palito: '
          'si sale limpio, ya está. Si se hunde al medio, suele ser por abrir '
          'el horno antes de tiempo, por sacarla cruda o por exceso de polvo '
          'de hornear. Los primeros 20 o 25 minutos, el horno no se abre.',
    ),
    (
      [
        'madurar la palta',
        'madurar una palta',
        'como se si la palta esta madura',
        'palta esta madura',
        'madurar el platano',
        'madurar fruta',
        'madurar la fruta',
      ],
      'Para madurar fruta (palta, plátano, mango), envuélvela en papel junto '
          'a una manzana o un plátano maduro: sueltan un gas que la apura. '
          'Una palta está lista cuando cede un poquito al apretarla suave.',
    ),
    (
      [
        '=pan duro',
        '=pan viejo',
        'que hago con pan duro',
        'que hago con el pan duro',
        'que hago con pan viejo',
        'que hago con el pan de ayer',
        'revivir el pan',
      ],
      'Para revivir el pan del día anterior: mójalo apenas con agua y mételo '
          '5 minutos al horno caliente (o a la sartén tapada). Y si ya está '
          'muy duro: **tostadas francesas** o pan molido para milanesas.',
    ),
    (
      [
        'lavar las verduras',
        'lavar la lechuga',
        'desinfectar verduras',
        'desinfectar las verduras',
        'lavar la fruta',
        'lavar las frutas',
      ],
      'Lávalas bajo el chorro de agua, frotando; la lechuga, hoja por hoja. '
          'Si las vas a comer crudas, déjalas unos minutos en agua con '
          'desinfectante para verduras (se vende en el súper: sigue la '
          'etiqueta) y enjuágalas.',
    ),
    (
      [
        'comida para la semana',
        'cocinar para la semana',
        'meal prep',
        'preparar comida para la semana',
        'cocinar para toda la semana',
      ],
      'Para cocinar una vez y comer toda la semana:\n'
          '1. Elige una base (arroz, fideo o papa), una proteína (pollo, '
          'carne, huevo o legumbres) y verduras.\n'
          '2. Cocina todo el domingo y repártelo en recipientes.\n'
          '3. Guarda en la heladera lo de 3 o 4 días, y lo demás congélalo.\n'
          '4. Varía las salsas para no aburrirte.',
    ),
    (
      [
        'tiempos de coccion',
        'tiempo de coccion',
        'cuanto tiempo se cocina el pollo',
        'cuanto tarda el pollo',
        'cuanto tarda la papa',
        'cuanto tarda la carne',
      ],
      _tiemposDeCoccion,
    ),
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
    (
      ['picante de pollo'],
      'El **picante de pollo** es pollo en salsa de ají colorado, servido con chuño, arroz, papa y sarza. Clásico paceño.',
    ),
    (
      ['falso conejo'],
      'El **falso conejo** es carne apanada en salsa de ají amarillo con verduras, servida con chuño, arroz y papa. Plato paceño.',
    ),
    (
      ['charquekan'],
      'El **charquekan** es charque frito y desmenuzado con mote, papa, huevo duro, queso y llajua. Típico de Oruro.',
    ),
    (
      ['picana'],
      'La **picana** es la sopa de Nochebuena en muchas casas bolivianas: varias carnes, choclo, papa, zanahoria y a veces un toque de vino.',
    ),
    (
      ['lasana', 'lasagna'],
      'La **lasaña** es un plato italiano de capas de pasta, salsa de carne, salsa blanca (bechamel) y queso, gratinado al horno.',
    ),
    (
      ['carbonara'],
      'La **carbonara** es una pasta romana con huevo, queso, panceta y pimienta. La original no lleva crema.',
    ),
    (
      ['tacos', 'taco'],
      'Los **tacos** son tortillas de maíz o de harina rellenas, de México: carne, pollo, verduras, salsa y lo que quieras.',
    ),
    (
      ['quesadilla', 'quesadillas'],
      'Una **quesadilla** es una tortilla doblada con queso derretido adentro (y lo que quieras sumarle). Mexicana y rapidísima.',
    ),
    (
      ['cheesecake', 'tarta de queso'],
      'El **cheesecake** es una tarta de queso crema sobre una base de galleta, muchas veces con frutos rojos encima.',
    ),
  ];

  // =============================================================== recetas
  static const recetas = <Receta>[
    // ------------------------------------------------------------ bolivianas
    (
      nombres: ['saltena', 'saltenas'],
      titulo: 'Salteñas',
      rinde: 'unas 15',
      tiempo: '3 horas, más una noche de reposo',
      ingredientes: [
        '**Jigote:** 500 g de carne de res en cubitos chicos',
        '2 papas en cubitos y 1 taza de arvejas cocidas',
        '2 cebollas picadas',
        '2 cucharadas de ají colorado molido, 1 cucharadita de comino y 1 cucharada de azúcar',
        '2 tazas de caldo y 2 sobres de gelatina sin sabor',
        '2 huevos duros, aceitunas, sal y pimienta',
        '**Masa:** 1 kg de harina',
        '200 g de manteca derretida con 1 cucharada de achiote (urucú)',
        'media taza de azúcar y 1 huevo',
        '1 taza y media de agua tibia con sal',
      ],
      pasos: [
        'Jigote: sofríe la cebolla con el ají, el comino y el azúcar; suma la carne, la papa y las arvejas.',
        'Agrega el caldo con la gelatina disuelta, cocina 15 minutos y llévalo a la heladera toda la noche: tiene que cuajar.',
        'Masa: mezcla la harina con la manteca tibia, el azúcar y el huevo; suma el agua de a poco hasta que no se pegue. Reposo de 30 minutos.',
        'Estira discos, pon una cucharada de jigote frío, un trozo de huevo y una aceituna, y cierra con repulgue arriba.',
        'Horno bien caliente (220 °C) de 15 a 20 minutos, hasta que doren.',
      ],
      tip:
          'Si el jigote no está frío y cuajado, el jugo se escapa al armarlas.',
    ),
    (
      nombres: ['majadito'],
      titulo: 'Majadito',
      rinde: 'para 4',
      tiempo: '45 minutos',
      ingredientes: [
        '2 tazas de arroz',
        '200 g de charque (carne seca)',
        '1 cebolla y 2 tomates picados',
        '1 cucharadita de urucú (achiote)',
        '4 tazas de agua caliente y sal',
        '**Para servir:** 4 huevos, 2 plátanos maduros y yuca cocida',
      ],
      pasos: [
        'Si el charque es duro, hiérvelo 20 minutos, sécalo y desmenúzalo.',
        'Fríe la cebolla y el tomate con el urucú.',
        'Suma el charque, revuelve, agrega el arroz y el agua caliente con sal.',
        'Tapa y cocina a fuego bajo unos 20 minutos, hasta que el arroz esté.',
        'Sirve con huevo frito, plátano frito y yuca.',
      ],
      tip:
          'Se llama majadito porque el charque se majaba (se golpeaba) para desmenuzarlo.',
    ),
    (
      nombres: ['sonso', 'sonso de yuca', 'zonzo'],
      titulo: 'Sonso de yuca',
      rinde: 'para 4',
      tiempo: '1 hora',
      ingredientes: [
        '1 kg de yuca',
        '300 g de queso fresco rallado',
        '2 cucharadas de mantequilla',
        'media taza de leche',
        'sal',
      ],
      pasos: [
        'Pela la yuca y cocínala en agua con sal hasta que esté bien blanda, unos 25 minutos. Sácale la vena del centro.',
        'Muélela o písala en caliente hasta que quede una masa lisa.',
        'Mezcla con el queso, la mantequilla, la leche y sal.',
        'Ponla en una fuente enmantequillada (o en palitos, para la parrilla) y hornea a 200 °C unos 25 minutos, hasta que dore.',
      ],
      tip: 'Muélela en caliente: fría, la yuca se pone dura y chiclosa.',
    ),
    (
      nombres: ['cunape', 'cunapes'],
      titulo: 'Cuñapé',
      rinde: 'unos 20',
      tiempo: '35 minutos',
      ingredientes: [
        '500 g de almidón de yuca',
        '500 g de queso fresco rallado o molido',
        '1 huevo',
        'media taza de leche, más o menos',
        '1 pizca de sal',
      ],
      pasos: [
        'Mezcla el almidón con el queso y la sal.',
        'Agrega el huevo y la leche de a poco, amasando, hasta que la masa sea suave y no se pegue.',
        'Haz bolitas del tamaño de una nuez y ponlas en una bandeja.',
        'Horno caliente (200 °C) de 15 a 20 minutos, hasta que doren.',
      ],
      tip: 'Se comen calentitos, con café o con api.',
    ),
    (
      nombres: ['api', 'api morado'],
      titulo: 'Api morado',
      rinde: 'para 4',
      tiempo: '30 minutos',
      ingredientes: [
        '1 taza de harina de maíz morado',
        '1 litro y medio de agua',
        '2 ramas de canela y 4 clavos de olor',
        'la cáscara de 1 naranja (opcional)',
        'azúcar a gusto',
      ],
      pasos: [
        'Disuelve la harina en 2 tazas de agua fría, sin grumos.',
        'Hierve el resto del agua con la canela, el clavo y la cáscara.',
        'Baja el fuego y agrega la harina disuelta, moviendo sin parar.',
        'Cocina de 10 a 15 minutos hasta que espese, y endulza.',
      ],
      tip: 'Va con buñuelos o con pastel de queso.',
    ),
    (
      nombres: ['masaco'],
      titulo: 'Masaco',
      rinde: 'para 4',
      tiempo: '40 minutos',
      ingredientes: [
        '4 plátanos verdes',
        '200 g de charque frito y desmenuzado (o 200 g de queso rallado)',
        '2 cucharadas de manteca o aceite',
        'sal',
      ],
      pasos: [
        'Pela los plátanos y fríelos (o hiérvelos) hasta que estén blandos.',
        'Machácalos en caliente con la manteca y sal.',
        'Mezcla con el charque o el queso.',
        'Forma bolitas y dóralas un poco en la sartén.',
      ],
      tip: 'Perfecto con un café en la mañana.',
    ),
    (
      nombres: ['pique macho', 'pique'],
      titulo: 'Pique macho',
      rinde: 'para 3 o 4',
      tiempo: '40 minutos',
      ingredientes: [
        '500 g de carne de res en tiras',
        '4 salchichas en rodajas',
        '1 kg de papas para fritas',
        '2 cebollas en pluma y 2 tomates en gajos',
        '2 locotos en tiras',
        '2 huevos duros',
        'comino, sal, pimienta y aceite',
      ],
      pasos: [
        'Fríe las papas y resérvalas.',
        'Dora la carne con sal, pimienta y comino; suma las salchichas.',
        'Agrega la cebolla, el tomate y el locoto, y saltea un par de minutos.',
        'Sirve todo encima de las papas, con huevo duro en rodajas.',
      ],
      tip: 'Es de Cochabamba y se come al centro, entre varios.',
    ),
    (
      nombres: ['silpancho'],
      titulo: 'Silpancho',
      rinde: 'para 4',
      tiempo: '50 minutos',
      ingredientes: [
        '4 filetes finos de carne',
        '2 tazas de pan molido',
        '4 tazas de arroz cocido',
        '4 papas cocidas en rodajas',
        '4 huevos',
        '**Ensalada:** 2 tomates, 1 cebolla, 1 locoto y perejil',
        'aceite y sal',
      ],
      pasos: [
        'Sazona la carne y aplánala con la mano sobre el pan molido hasta que quede finísima y del tamaño del plato.',
        'Fríela un minuto por lado.',
        'Fríe las rodajas de papa.',
        'Arma: arroz, papas, la carne encima, un huevo frito y la ensalada picada arriba.',
      ],
      tip: 'La gracia es la carne bien delgada, casi transparente.',
    ),
    (
      nombres: ['sopa de mani'],
      titulo: 'Sopa de maní',
      rinde: 'para 6',
      tiempo: '1 hora 15 minutos',
      ingredientes: [
        '1 taza de maní crudo pelado',
        '500 g de costilla de res (o pollo)',
        '1 zanahoria en tiras y 1 taza de arvejas',
        '3 papas en cubos',
        'media taza de fideo corto o de arroz',
        '1 cebolla, ajo, comino, orégano y sal',
        '**Para servir:** papas fritas y perejil',
      ],
      pasos: [
        'Hierve la carne con la cebolla, el ajo y sal unos 40 minutos.',
        'Licúa el maní con 2 tazas de agua hasta que quede como leche.',
        'Agrega al caldo el maní licuado, la zanahoria, las arvejas y la papa, moviendo para que no se pegue.',
        'Suma el fideo y cocina hasta que todo esté blando.',
        'Sirve con papas fritas encima y perejil.',
      ],
      tip: 'Mueve seguido: el maní tiende a pegarse al fondo.',
    ),
    (
      nombres: ['bife', 'bife de carne', 'bife a caballo'],
      titulo: 'Bife a la boliviana',
      rinde: 'para 2',
      tiempo: '20 minutos',
      ingredientes: [
        '2 filetes de carne (lomo o pulpa) de un dedo de grosor',
        '1 diente de ajo',
        'sal y pimienta',
        '1 cucharada de aceite',
        '**Para acompañar:** arroz, papas fritas, ensalada y, si quieres, huevo frito',
      ],
      pasos: [
        'Sazona la carne con sal, pimienta y el ajo picado.',
        'Calienta muy bien la sartén con el aceite.',
        'Cocina el bife 2 o 3 minutos por lado, sin moverlo mucho.',
        'Déjalo reposar un minuto antes de cortarlo, así no suelta el jugo.',
      ],
      tip: 'Con un huevo frito encima es un bife "a caballo".',
    ),
    (
      nombres: ['salchipapa', 'salchipapas'],
      titulo: 'Salchipapa',
      rinde: 'para 2',
      tiempo: '30 minutos',
      ingredientes: [
        '4 papas',
        '4 salchichas',
        'aceite para freír y sal',
        'mayonesa, kétchup, mostaza y llajua',
      ],
      pasos: [
        'Corta las papas en bastones, lávalas y sécalas bien.',
        'Fríelas hasta que doren y sálalas.',
        'Corta las salchichas en rodajas y dóralas en la sartén.',
        'Mezcla todo y báñalo con las salsas.',
      ],
      tip: 'Con un huevo frito encima queda todavía mejor.',
    ),
    (
      nombres: ['tucumana', 'tucumanas'],
      titulo: 'Tucumanas',
      rinde: 'unas 12',
      tiempo: '1 hora 30 minutos',
      ingredientes: [
        '**Relleno:** 400 g de carne o pollo picado',
        '2 papas en cubitos y media taza de arvejas',
        '1 cebolla, 2 huevos duros y aceitunas',
        '1 cucharada de ají colorado, comino y sal',
        '**Masa:** 4 tazas de harina, 100 g de manteca, 1 huevo, 1 cucharadita de sal y agua tibia',
        'aceite para freír',
      ],
      pasos: [
        'Relleno: sofríe la cebolla con el ají y el comino, suma la carne, la papa y las arvejas, y cocina hasta que se seque. Deja enfriar y suma el huevo picado.',
        'Masa: mezcla la harina con la sal, la manteca y el huevo, y agrega agua tibia hasta que no se pegue.',
        'Estira discos, rellena y cierra con repulgue.',
        'Fríe en aceite caliente hasta que doren.',
      ],
      tip: 'Se comen con ensalada de cebolla y tomate, mostaza y llajua.',
    ),
    (
      nombres: ['llajua', 'llajwa'],
      titulo: 'Llajua',
      rinde: 'un platito',
      tiempo: '10 minutos',
      ingredientes: [
        '2 tomates maduros',
        '1 o 2 locotos',
        'unas hojas de quirquiña (o perejil)',
        'sal',
      ],
      pasos: [
        'Sácales las pepas a los locotos: ahí está lo más picante.',
        'Muele los tomates y el locoto en batán (o licúalos un poquito, sin que quede sopa).',
        'Agrega la quirquiña picada y sal.',
      ],
      tip:
          'La quirquiña le da el sabor de verdad; si no hay, perejil o cilantro.',
    ),
    (
      nombres: ['anticucho', 'anticuchos'],
      titulo: 'Anticuchos',
      rinde: 'para 4',
      tiempo: '3 horas (2 de adobo)',
      ingredientes: [
        '1 corazón de res en cubos',
        '3 cucharadas de ají colorado molido',
        '4 dientes de ajo y 1 cucharadita de comino',
        'media taza de vinagre y sal',
        'papas cocidas',
        '**Salsa de maní:** 1 taza de maní tostado, ají y agua',
      ],
      pasos: [
        'Limpia el corazón y córtalo en cubos.',
        'Adóbalo con el ají, el ajo, el comino, el vinagre y sal, mínimo 2 horas.',
        'Ensártalo en palitos.',
        'A la parrilla, pintando con el adobo, hasta que dore.',
        'Sirve con papa y salsa de maní (el maní licuado con ají y un poco de agua).',
      ],
      tip: 'Remoja los palitos en agua antes, así no se queman.',
    ),
    (
      nombres: ['chicharron', 'chicharron de cerdo'],
      titulo: 'Chicharrón de cerdo',
      rinde: 'para 4',
      tiempo: '1 hora 30 minutos',
      ingredientes: [
        '1 kg de carne de cerdo con algo de grasa (costilla o pierna)',
        '4 dientes de ajo',
        '1 cucharadita de comino y sal',
        'agua',
        '**Para servir:** mote, papa y llajua',
      ],
      pasos: [
        'Corta el cerdo en trozos medianos y sazónalo con ajo, comino y sal.',
        'Ponlo en una olla con agua hasta la mitad de la carne.',
        'Cocina a fuego medio hasta que el agua se evapore, una hora más o menos.',
        'Deja que se dore en su propia grasa, moviendo de vez en cuando.',
      ],
      tip: 'No le eches aceite: la grasa del cerdo hace todo el trabajo.',
    ),
    (
      nombres: ['locro', 'locro de gallina'],
      titulo: 'Locro de gallina cruceño',
      rinde: 'para 6',
      tiempo: '1 hora 30 minutos',
      ingredientes: [
        '1 gallina criolla (o pollo) en presas',
        '1 taza de arroz',
        '2 yucas en trozos',
        '2 plátanos maduros',
        '1 cebolla y 2 dientes de ajo',
        '1 cucharadita de urucú, comino y sal',
      ],
      pasos: [
        'Hierve la gallina con la cebolla, el ajo y sal hasta que esté blanda (con pollo tarda menos).',
        'Agrega el arroz, la yuca y el urucú, y cocina a fuego bajo moviendo para que espese.',
        'Al final suma el plátano en rodajas.',
      ],
      tip: 'Tiene que quedar espeso, no como sopa clara. Ideal para el surazo.',
    ),
    (
      nombres: ['fricase', 'fricace'],
      titulo: 'Fricasé',
      rinde: 'para 6',
      tiempo: '2 horas',
      ingredientes: [
        '1 kg de carne de cerdo en trozos',
        '3 cucharadas de ají amarillo molido',
        '1 cebolla y 4 dientes de ajo',
        'comino, orégano, pimienta y sal',
        'media taza de pan molido',
        '**Para servir:** mote, papa y chuño',
      ],
      pasos: [
        'Hierve el cerdo con la cebolla, el ajo y sal en bastante agua.',
        'Cuando esté blando, suma el ají amarillo, el comino, el orégano y la pimienta.',
        'Espesa el caldo con el pan molido, moviendo.',
        'Sirve en plato hondo con mote, papa y chuño.',
      ],
      tip:
          'Es picante y bien caliente: famoso para el día después de una fiesta.',
    ),
    (
      nombres: ['huminta', 'humintas', 'humita', 'humitas'],
      titulo: 'Humintas',
      rinde: 'unas 10',
      tiempo: '1 hora 15 minutos',
      ingredientes: [
        '10 choclos tiernos, con sus chalas',
        '200 g de queso fresco',
        '3 cucharadas de manteca',
        '2 cucharadas de azúcar y 1 cucharadita de anís',
        'sal',
      ],
      pasos: [
        'Desgrana los choclos y muélelos. Guarda las chalas limpias.',
        'Mezcla la masa con la manteca derretida, el azúcar, el anís, sal y el queso en trocitos.',
        'Pon porciones en las chalas y envuélvelas.',
        'Cocina al vapor (o al horno, en bandeja) de 40 a 50 minutos, hasta que estén firmes.',
      ],
      tip: 'Al horno quedan doraditas; al vapor, más suaves.',
    ),
    (
      nombres: ['bunuelo', 'bunuelos'],
      titulo: 'Buñuelos',
      rinde: 'unos 15',
      tiempo: '1 hora 30 minutos',
      ingredientes: [
        '2 tazas de harina',
        '1 cucharadita de levadura seca',
        '1 pizca de sal y 1 cucharadita de anís',
        '1 taza de agua tibia, más o menos',
        'aceite para freír',
        'miel o jarabe de chancaca',
      ],
      pasos: [
        'Mezcla la harina, la levadura, la sal y el anís, y suma el agua de a poco hasta tener una masa muy blanda.',
        'Déjala reposar una hora, tapada, hasta que crezca.',
        'Con las manos mojadas, toma porciones, estíralas finitas y fríelas en aceite bien caliente.',
        'Sirve con miel o jarabe, junto a un api.',
      ],
      tip: 'Las manos mojadas son el truco para que la masa no se pegue.',
    ),
    (
      nombres: ['arroz con leche'],
      titulo: 'Arroz con leche',
      rinde: 'para 6',
      tiempo: '50 minutos',
      ingredientes: [
        '1 taza de arroz',
        '2 tazas de agua',
        '1 litro de leche',
        '3/4 de taza de azúcar',
        '1 rama de canela y 3 clavos de olor',
        'canela en polvo',
      ],
      pasos: [
        'Cocina el arroz en el agua con la canela y el clavo hasta que se consuma el agua.',
        'Agrega la leche y el azúcar.',
        'Cocina a fuego bajo, moviendo seguido, unos 25 minutos, hasta que espese.',
        'Sirve con canela en polvo, frío o tibio.',
      ],
      tip:
          'Espesa más al enfriar: sácalo un poco antes de que esté como lo quieres.',
    ),
    (
      nombres: ['mocochinchi'],
      titulo: 'Mocochinchi',
      rinde: '2 litros',
      tiempo: '40 minutos, más enfriar',
      ingredientes: [
        '12 mocochinchis (duraznos deshidratados)',
        '2 litros de agua',
        '2 ramas de canela',
        'azúcar a gusto',
      ],
      pasos: [
        'Lava bien los mocochinchis y déjalos en remojo una hora.',
        'Hiérvelos de 20 a 30 minutos con la canela.',
        'Endulza y deja enfriar.',
        'Sirve bien helado, con un durazno en cada vaso.',
      ],
      tip: '',
    ),
    (
      nombres: ['somo'],
      titulo: 'Somó',
      rinde: '2 litros',
      tiempo: '2 horas, más una noche de remojo',
      ingredientes: [
        '2 tazas de maíz blanco pelado',
        '1 litro de leche y 1 litro de agua',
        '2 ramas de canela',
        'azúcar a gusto',
      ],
      pasos: [
        'Deja el maíz en remojo de un día para otro.',
        'Cocínalo en el agua con la canela hasta que esté blando, más de una hora.',
        'Agrega la leche y el azúcar, y hierve unos minutos más.',
        'Enfría y sirve bien frío.',
      ],
      tip: '',
    ),
    (
      nombres: ['sandwich de chola', 'sanduche de chola'],
      titulo: 'Sándwich de chola',
      rinde: 'para 6',
      tiempo: '3 horas',
      ingredientes: [
        '1 kg de pierna de cerdo',
        '4 dientes de ajo, 1 cucharadita de comino y sal',
        '6 panes',
        '**Encurtido:** 1 cebolla en pluma, 1 zanahoria en tiras, 1 locoto en tiras, vinagre y sal',
        'llajua',
      ],
      pasos: [
        'Adoba el cerdo con ajo, comino y sal, y hornéalo a 180 °C unas 2 horas y media, hasta que esté bien cocido y dorado.',
        'Encurtido: mezcla la cebolla, la zanahoria y el locoto con vinagre y sal; deja reposar 30 minutos.',
        'Arma: pan, chancho en láminas, encurtido y un poco de llajua.',
      ],
      tip: '',
    ),
    (
      nombres: ['helado de canela'],
      titulo: 'Helado de canela',
      rinde: 'para 6',
      tiempo: '30 minutos, más 4 horas de congelador',
      ingredientes: [
        '1 litro de agua',
        '4 ramas de canela y 6 clavos de olor',
        '1 taza de azúcar',
        'el jugo de 1 limón',
        'unas gotas de colorante rojo',
      ],
      pasos: [
        'Hierve el agua con la canela y el clavo 15 minutos.',
        'Agrega el azúcar, el limón y el colorante; cuela y enfría.',
        'Congela en un recipiente bajo.',
        'Cada media hora, ráspalo con un tenedor para que quede granizado.',
      ],
      tip: 'Típico de Sucre. Bien frío, en pleno calor, no tiene rival.',
    ),
    (
      nombres: ['sopa de quinua'],
      titulo: 'Sopa de quinua',
      rinde: 'para 6',
      tiempo: '1 hora',
      ingredientes: [
        '1 taza de quinua',
        '400 g de carne de res o pollo',
        '3 papas en cubos y 1 zanahoria',
        'media taza de arvejas',
        '1 cebolla y 2 dientes de ajo',
        'comino, orégano, sal y perejil',
      ],
      pasos: [
        'Lava muy bien la quinua frotándola bajo el agua hasta que no haga espuma: así se le va el amargor.',
        'Hierve la carne con la cebolla, el ajo y sal unos 30 minutos.',
        'Suma la quinua, la zanahoria y las arvejas; a los 10 minutos, la papa.',
        'Cocina hasta que todo esté blando y termina con perejil.',
      ],
      tip: 'Si no lavas bien la quinua, la sopa queda amarga.',
    ),
    (
      nombres: ['picante de pollo'],
      titulo: 'Picante de pollo',
      rinde: 'para 4',
      tiempo: '1 hora',
      ingredientes: [
        '4 presas de pollo',
        '4 cucharadas de ají colorado molido',
        '1 cebolla picada y 4 dientes de ajo',
        'comino, orégano y sal',
        '**Sarza:** 1 cebolla en pluma, 2 tomates, 1 locoto, perejil, aceite y vinagre',
        '**Para servir:** chuño, arroz y papa',
      ],
      pasos: [
        'Sofríe la cebolla y el ajo con el ají y los condimentos.',
        'Suma el pollo y agua hasta cubrirlo, y cocina a fuego medio hasta que esté blando y la salsa espese.',
        'Prepara la sarza mezclando todo.',
        'Sirve el pollo con su salsa, chuño, arroz, papa y la sarza encima.',
      ],
      tip: 'El chuño se deja en remojo desde la noche anterior.',
    ),
    (
      nombres: ['sajta', 'sajta de pollo'],
      titulo: 'Sajta de pollo',
      rinde: 'para 4',
      tiempo: '1 hora 15 minutos',
      ingredientes: [
        '4 presas de pollo',
        '3 cucharadas de ají amarillo molido',
        '1 cebolla y 2 dientes de ajo',
        '1 taza de arvejas',
        'comino y sal',
        '**Para servir:** chuño phuti (chuño cocido y revuelto con huevo), papa y sarza de cebolla, tomate y locoto',
      ],
      pasos: [
        'Cocina el pollo en agua con sal hasta que esté blando y guarda el caldo.',
        'Sofríe la cebolla y el ajo con el ají amarillo y el comino; suma un poco de caldo y las arvejas, y deja espesar.',
        'Pon el pollo en la salsa unos minutos.',
        'Sirve con chuño phuti, papa y sarza.',
      ],
      tip: '',
    ),
    (
      nombres: ['chairo'],
      titulo: 'Chairo',
      rinde: 'para 6',
      tiempo: '1 hora 30 minutos',
      ingredientes: [
        '300 g de carne de res (o charque)',
        '1 taza de chuño remojado y picado',
        '3 papas en cubos y 1 zanahoria',
        'media taza de habas y media de arvejas',
        'media taza de mote o trigo pelado',
        '1 cebolla, ají colorado, comino, orégano y sal',
        'hierbabuena',
      ],
      pasos: [
        'Hierve la carne con la cebolla y sal unos 40 minutos.',
        'Suma el chuño, el mote, las habas y la zanahoria.',
        'Agrega la papa, las arvejas, el ají y los condimentos, y cocina hasta que todo esté blando.',
        'Termina con hierbabuena picada.',
      ],
      tip: 'La sopa paceña del frío por excelencia.',
    ),
    (
      nombres: ['aji de fideo'],
      titulo: 'Ají de fideo',
      rinde: 'para 4',
      tiempo: '45 minutos',
      ingredientes: [
        '300 g de fideo (tallarín o espagueti)',
        '300 g de carne en cubitos (o pollo)',
        '3 cucharadas de ají colorado molido',
        '1 cebolla, 2 dientes de ajo y 1 tomate',
        'comino, orégano y sal',
        'papa cocida para acompañar',
      ],
      pasos: [
        'Sofríe la cebolla, el ajo y el tomate con el ají y los condimentos.',
        'Suma la carne y dórala; agrega 2 tazas de agua y cocina hasta que esté blanda.',
        'Cocina el fideo aparte, cuélalo y mézclalo con la salsa.',
      ],
      tip: '',
    ),
    (
      nombres: ['falso conejo'],
      titulo: 'Falso conejo',
      rinde: 'para 4',
      tiempo: '1 hora',
      ingredientes: [
        '4 filetes finos de carne',
        '1 taza de pan molido y 2 huevos',
        '3 cucharadas de ají amarillo molido',
        '1 cebolla, 1 zanahoria en cubitos y media taza de arvejas',
        'comino y sal',
        '**Para servir:** chuño, arroz y papa',
      ],
      pasos: [
        'Apana la carne pasándola por huevo batido y pan molido, y fríela.',
        'Salsa: sofríe la cebolla con el ají amarillo, suma la zanahoria, las arvejas y 1 taza de agua, y cocina hasta que espese.',
        'Pon la carne en la salsa unos minutos.',
        'Sirve con chuño, arroz y papa.',
      ],
      tip: '',
    ),
    (
      nombres: ['plato paceno'],
      titulo: 'Plato paceño',
      rinde: 'para 4',
      tiempo: '40 minutos',
      ingredientes: [
        '4 choclos',
        '2 tazas de habas',
        '4 papas con cáscara',
        '400 g de queso fresco en tajadas',
        'aceite, sal y llajua',
      ],
      pasos: [
        'Hierve los choclos, las habas y las papas por separado, con sal.',
        'Dora las tajadas de queso en la sartén.',
        'Sirve todo junto, con llajua.',
      ],
      tip: 'Hay quien le suma un trozo de carne asada.',
    ),
    (
      nombres: [
        'empanada de queso',
        'empanadas de queso',
        'empanada',
        'empanadas',
      ],
      titulo: 'Empanadas de queso',
      rinde: 'unas 12',
      tiempo: '1 hora',
      ingredientes: [
        '3 tazas de harina',
        '1 cucharadita de polvo de hornear',
        '1 pizca de sal y 1 cucharada de azúcar',
        '100 g de manteca o mantequilla',
        '1 huevo',
        'media taza de leche tibia, más o menos',
        '300 g de queso rallado',
        'azúcar flor para espolvorear',
      ],
      pasos: [
        'Mezcla la harina, el polvo de hornear, la sal y el azúcar; incorpora la manteca y el huevo.',
        'Suma la leche de a poco hasta tener una masa suave.',
        'Estira discos, pon queso al centro y cierra con repulgue.',
        'Hornea a 200 °C unos 20 minutos (o fríelas), y espolvorea azúcar flor.',
      ],
      tip: 'Con un api al lado es desayuno de domingo.',
    ),
    (
      nombres: ['charquekan'],
      titulo: 'Charquekan',
      rinde: 'para 4',
      tiempo: '1 hora',
      ingredientes: [
        '300 g de charque',
        '4 papas',
        '2 tazas de mote de maíz',
        '4 huevos duros',
        '200 g de queso fresco',
        'llajua',
      ],
      pasos: [
        'Hierve el charque 20 minutos, sécalo, fríelo hasta que esté crocante y desmenúzalo.',
        'Cocina las papas y calienta el mote.',
        'Sirve: mote, papa, charque, huevo duro, una tajada de queso y llajua.',
      ],
      tip: 'Típico de Oruro.',
    ),
    (
      nombres: ['picana'],
      titulo: 'Picana',
      rinde: 'para 8',
      tiempo: '3 horas',
      ingredientes: [
        '1 kg de carne de res',
        '1 pollo en presas',
        '500 g de cordero o cerdo',
        '4 choclos en trozos, 8 papas y 2 zanahorias',
        '2 cebollas y 2 tomates',
        '1 taza de vino tinto (opcional)',
        'comino, orégano, pimienta, laurel y sal',
      ],
      pasos: [
        'Hierve las carnes con la cebolla, el tomate, el laurel y los condimentos. El pollo entra después, porque se cocina antes.',
        'Cuando estén blandas, suma el choclo, la zanahoria y la papa.',
        'Agrega el vino al final y cocina unos minutos más.',
      ],
      tip: 'La sopa de Nochebuena en muchas casas bolivianas.',
    ),
    (
      nombres: ['refresco de linaza', 'linaza'],
      titulo: 'Refresco de linaza',
      rinde: '2 litros',
      tiempo: '30 minutos, más enfriar',
      ingredientes: [
        '3 cucharadas de linaza',
        '2 litros de agua',
        '1 rama de canela y 3 clavos de olor',
        'azúcar a gusto',
        'el jugo de 1 limón (opcional)',
      ],
      pasos: [
        'Hierve la linaza con la canela y el clavo unos 15 minutos, hasta que el agua espese un poco.',
        'Cuela, endulza y suma el limón.',
        'Enfría y sirve helado.',
      ],
      tip: '',
    ),
    (
      nombres: ['sopa de fideo'],
      titulo: 'Sopa de fideo',
      rinde: 'para 4',
      tiempo: '45 minutos',
      ingredientes: [
        '300 g de carne o pollo',
        '1 taza de fideo corto',
        '2 papas y 1 zanahoria',
        '1 cebolla y 1 diente de ajo',
        'sal, comino y perejil',
      ],
      pasos: [
        'Hierve la carne con la cebolla, el ajo y sal unos 30 minutos.',
        'Suma la papa y la zanahoria en cubos.',
        'Cuando estén casi listas, agrega el fideo y cocina de 8 a 10 minutos.',
        'Termina con perejil.',
      ],
      tip: 'La sopa que te salva cuando estás con gripe.',
    ),
    // ------------------------------------------------------ de todo el mundo
    (
      nombres: [
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
      titulo: 'Fideo con salsa',
      rinde: 'para 2',
      tiempo: '25 minutos',
      ingredientes: [
        '200 g de fideo',
        'agua: 1 litro por cada 100 g de fideo, con sal',
        '**Salsa:** 2 tomates maduros (o 1 lata de tomate), media cebolla, 1 diente de ajo, orégano, sal y 1 cucharada de aceite',
        'queso rallado (opcional)',
      ],
      pasos: [
        'Hierve el agua con sal y echa el fideo; cocínalo lo que diga el paquete (de 8 a 12 minutos), moviendo al principio.',
        'Salsa: fríe el ajo y la cebolla, suma el tomate picado, sal y orégano, y deja 10 minutos a fuego bajo.',
        'Cuela el fideo, mézclalo con la salsa y, si hay, queso rallado encima.',
      ],
      tip:
          'No hace falta echarle aceite al agua: lo que evita que se pegue es usar bastante agua y mover al principio.',
    ),
    (
      nombres: ['arroz', 'arroz blanco', 'arroz graneado'],
      titulo: 'Arroz blanco',
      rinde: 'para 3',
      tiempo: '25 minutos',
      ingredientes: [
        '1 taza de arroz',
        '2 tazas de agua caliente',
        '1 diente de ajo',
        '1 cucharada de aceite y sal',
      ],
      pasos: [
        'Fríe el ajo picado en el aceite.',
        'Agrega el arroz y revuelve un minuto.',
        'Echa el agua caliente y sal.',
        'Cuando hierva, baja el fuego al mínimo, tapa y espera de 15 a 18 minutos sin destapar.',
      ],
      tip: 'Al final, déjalo reposar 5 minutos tapado: sale suelto.',
    ),
    (
      nombres: ['huevo frito', 'huevos fritos'],
      titulo: 'Huevo frito',
      rinde: 'para 1',
      tiempo: '5 minutos',
      ingredientes: ['1 o 2 huevos', 'aceite', 'sal'],
      pasos: [
        'Calienta el aceite en la sartén.',
        'Rompe el huevo con cuidado y ponle sal.',
        'Báñale la clara con el aceite usando una cuchara, unos 2 minutos.',
        'Si te gusta la yema firme, dale vuelta.',
      ],
      tip: '',
    ),
    (
      nombres: ['huevos revueltos', 'huevo revuelto'],
      titulo: 'Huevos revueltos',
      rinde: 'para 1',
      tiempo: '5 minutos',
      ingredientes: ['2 huevos', '1 cucharadita de mantequilla', 'sal'],
      pasos: [
        'Bate los huevos con sal.',
        'Échalos a la sartén con la mantequilla, a fuego bajo.',
        'Muévelos despacio con una espátula.',
        'Sácalos cuando estén cremosos: se terminan de cocinar solos.',
      ],
      tip: '',
    ),
    (
      nombres: ['milanesa', 'milanesas', 'milanesa de pollo'],
      titulo: 'Milanesa',
      rinde: 'para 4',
      tiempo: '30 minutos',
      ingredientes: [
        '4 filetes finos de carne o pollo',
        'media taza de harina',
        '2 huevos batidos',
        '1 taza y media de pan rallado',
        'sal, pimienta y ajo',
        'aceite',
      ],
      pasos: [
        'Aplana los filetes bien finos y sazónalos.',
        'Pásalos por harina, después por huevo y al final por pan rallado.',
        'Fríelos en aceite caliente, 2 o 3 minutos por lado.',
      ],
      tip: 'Va con arroz, papas fritas o puré, y limón.',
    ),
    (
      nombres: ['hamburguesa', 'hamburguesas'],
      titulo: 'Hamburguesas',
      rinde: 'para 4',
      tiempo: '25 minutos',
      ingredientes: [
        '500 g de carne molida',
        'sal, pimienta y 1 diente de ajo',
        '4 panes de hamburguesa',
        '4 láminas de queso',
        'lechuga, tomate, cebolla y salsas',
      ],
      pasos: [
        'Mezcla la carne con sal, pimienta y el ajo, y forma 4 discos.',
        'Plancha o sartén bien caliente: 3 o 4 minutos por lado. Al final, el queso encima.',
        'Arma el pan con lechuga, tomate, cebolla y tus salsas.',
      ],
      tip:
          'Hazle un hundido con el dedo en el centro: así no se infla al cocinarse.',
    ),
    (
      nombres: ['pizza', 'pizzas'],
      titulo: 'Pizza casera',
      rinde: 'para 2',
      tiempo: '1 hora 45 minutos',
      ingredientes: [
        '2 tazas de harina',
        '1 cucharadita de levadura seca y 1 de sal',
        '2 cucharadas de aceite',
        'agua tibia (unos 3/4 de taza)',
        'salsa de tomate',
        '200 g de queso mozzarella',
        'lo que quieras arriba: jamón, champiñones, cebolla, pimentón',
      ],
      pasos: [
        'Mezcla la harina, la levadura, la sal y el aceite, y suma el agua hasta que no se pegue. Amasa 10 minutos.',
        'Deja reposar una hora, tapada, hasta que doble su tamaño.',
        'Estírala en una bandeja aceitada y ponle salsa, queso y lo demás.',
        'Horno bien caliente (220 °C) unos 15 minutos.',
      ],
      tip:
          'Precalienta bien el horno: la pizza pide calor fuerte desde el principio.',
    ),
    (
      nombres: ['sushi', 'rollos de sushi', 'maki'],
      titulo: 'Sushi en rollos',
      rinde: 'unos 4 rollos',
      tiempo: '1 hora',
      ingredientes: [
        '2 tazas de arroz de grano corto',
        'un cuarto de taza de vinagre de arroz, 2 cucharadas de azúcar y 1 cucharadita de sal',
        '4 hojas de alga nori',
        '**Relleno:** salmón o kanikama, palta, pepino y queso crema',
        'salsa de soya',
      ],
      pasos: [
        'Lava el arroz hasta que el agua salga clara y cocínalo.',
        'Mézclalo tibio con el vinagre, el azúcar y la sal.',
        'Sobre una esterilla, pon una hoja de nori y cúbrela con una capa fina de arroz.',
        'Pon el relleno en una línea, enrolla apretando con la esterilla y corta con un cuchillo mojado.',
      ],
      tip: 'Moja tus manos para manejar el arroz: así no se pega.',
    ),
    (
      nombres: ['frappe', 'frappes', 'frape', 'frappuccino', 'frappe de cafe'],
      titulo: 'Frappé de café',
      rinde: 'para 1',
      tiempo: '5 minutos',
      ingredientes: [
        '1 taza de café fuerte frío (o 2 cucharaditas de café instantáneo en un chorrito de agua)',
        '1 taza de hielo',
        'media taza de leche',
        '2 cucharadas de azúcar',
        'crema batida y chocolate (opcional)',
      ],
      pasos: [
        'Prepara el café y déjalo enfriar.',
        'Licúalo con el hielo, la leche y el azúcar hasta que quede espumoso.',
        'Si quieres, crema batida y chocolate encima.',
      ],
      tip: 'Sin café, con chocolate o con frutilla, también sale.',
    ),
    (
      nombres: ['brownie', 'brownies', 'browni', 'brownis'],
      titulo: 'Brownies',
      rinde: 'unos 16 cuadrados',
      tiempo: '40 minutos',
      ingredientes: [
        '200 g de chocolate semiamargo',
        '150 g de mantequilla',
        '200 g de azúcar',
        '3 huevos',
        '100 g de harina',
        '1 pizca de sal',
        'nueces picadas (opcional)',
      ],
      pasos: [
        'Derrite el chocolate con la mantequilla (a baño María o en el microondas, de a 30 segundos).',
        'Mezcla con el azúcar, los huevos y la sal.',
        'Suma la harina sin batir de más.',
        'Molde con papel, horno a 180 °C de 20 a 25 minutos.',
      ],
      tip: 'El centro tiene que quedar un poco húmedo: si sale seco, se pasó.',
    ),
    (
      nombres: [
        'queque',
        'torta',
        'bizcochuelo',
        'pastel',
        'keke',
        'torta casera',
      ],
      titulo: 'Queque básico',
      rinde: 'para 8',
      tiempo: '50 minutos',
      ingredientes: [
        '3 huevos',
        '1 taza de azúcar',
        'media taza de aceite',
        '1 taza de leche',
        '2 tazas de harina',
        '2 cucharaditas de polvo de hornear',
        'ralladura de limón o vainilla',
      ],
      pasos: [
        'Bate los huevos con el azúcar hasta que esponjen.',
        'Suma el aceite, la leche y la ralladura.',
        'Agrega la harina con el polvo de hornear y mezcla suave.',
        'Molde enmantequillado, horno a 180 °C de 35 a 40 minutos.',
      ],
      tip: 'Está listo cuando un palito pinchado al centro sale limpio.',
    ),
    (
      nombres: [
        'torta de chocolate',
        'queque de chocolate',
        'pastel de chocolate',
      ],
      titulo: 'Torta de chocolate',
      rinde: 'para 8',
      tiempo: '1 hora',
      ingredientes: [
        '2 tazas de harina',
        '1 taza y media de azúcar',
        '3/4 de taza de cacao en polvo',
        '2 cucharaditas de polvo de hornear y 1 de bicarbonato',
        '1 pizca de sal',
        '2 huevos',
        '1 taza de leche y media taza de aceite',
        '1 taza de agua caliente (o café)',
      ],
      pasos: [
        'Mezcla los ingredientes secos.',
        'Suma los huevos, la leche y el aceite, y bate 2 minutos.',
        'Agrega el agua caliente: la masa queda muy líquida, es normal.',
        'Molde enmantequillado, horno a 180 °C de 35 a 40 minutos.',
      ],
      tip: 'Con café en vez de agua, el chocolate sabe más intenso.',
    ),
    (
      nombres: [
        'panqueque',
        'panqueques',
        'pancakes',
        'hotcakes',
        'crepas',
        'crepes',
      ],
      titulo: 'Panqueques',
      rinde: 'unos 8',
      tiempo: '20 minutos',
      ingredientes: [
        '1 taza de harina',
        '1 huevo',
        '1 taza de leche',
        '1 cucharada de azúcar',
        '1 pizca de sal',
        'un poco de mantequilla o aceite para la sartén',
      ],
      pasos: [
        'Mezcla todo hasta que no queden grumos.',
        'Sartén caliente, apenas engrasada: echa un cucharón y mueve para que se extienda.',
        'Cuando se despegue el borde, dale vuelta.',
      ],
      tip:
          'Con dulce de leche, miel o fruta. El primero siempre sale feo: es tradición.',
    ),
    (
      nombres: ['waffles', 'waffle', 'gofres'],
      titulo: 'Waffles',
      rinde: 'unos 6',
      tiempo: '25 minutos',
      ingredientes: [
        '2 tazas de harina',
        '2 cucharaditas de polvo de hornear',
        '2 cucharadas de azúcar y 1 pizca de sal',
        '2 huevos',
        '1 taza y media de leche',
        'un tercio de taza de mantequilla derretida',
      ],
      pasos: [
        'Mezcla los secos por un lado y los líquidos por otro.',
        'Junta todo sin batir de más.',
        'Cocina en la wafflera caliente y engrasada hasta que doren.',
      ],
      tip: 'Sin wafflera, la misma masa sirve para panqueques gorditos.',
    ),
    (
      nombres: [
        'galletas',
        'galleta',
        'galletas con chispas',
        'cookies',
        'galletas de chocolate',
      ],
      titulo: 'Galletas con chispas',
      rinde: 'unas 24',
      tiempo: '30 minutos',
      ingredientes: [
        '125 g de mantequilla blanda',
        '1 taza de azúcar',
        '1 huevo y vainilla',
        '2 tazas de harina',
        'media cucharadita de bicarbonato',
        'chispas de chocolate',
      ],
      pasos: [
        'Bate la mantequilla con el azúcar.',
        'Suma el huevo y la vainilla.',
        'Agrega la harina, el bicarbonato y las chispas.',
        'Bolitas separadas en la bandeja, horno a 180 °C de 10 a 12 minutos.',
      ],
      tip: 'Salen blanditas y se endurecen al enfriar: no las dejes de más.',
    ),
    (
      nombres: ['flan'],
      titulo: 'Flan',
      rinde: 'para 8',
      tiempo: '1 hora 15 minutos, más enfriar',
      ingredientes: [
        'media taza de azúcar para el caramelo',
        '4 huevos',
        '1 lata de leche condensada',
        'la misma medida de leche',
        'vainilla',
      ],
      pasos: [
        'Caramelo: derrite el azúcar en el molde, a fuego bajo, hasta que se dore, y cubre el fondo.',
        'Licúa los huevos, la leche condensada, la leche y la vainilla.',
        'Vierte sobre el caramelo y hornea a baño María a 180 °C unos 50 minutos.',
        'Enfría (mejor de un día para otro) y desmolda.',
      ],
      tip: '',
    ),
    (
      nombres: ['cheesecake', 'tarta de queso', 'pay de queso'],
      titulo: 'Cheesecake sin horno',
      rinde: 'para 8',
      tiempo: '30 minutos, más 4 horas de heladera',
      ingredientes: [
        '200 g de galletas de vainilla',
        '80 g de mantequilla derretida',
        '400 g de queso crema',
        '1 lata de leche condensada',
        'el jugo de 2 limones',
        'mermelada de frutilla o frutos rojos',
      ],
      pasos: [
        'Muele las galletas, mézclalas con la mantequilla y aprieta la mezcla en el fondo de un molde.',
        'Bate el queso crema con la leche condensada y el limón hasta que quede liso.',
        'Viértelo sobre la base y lleva a la heladera mínimo 4 horas.',
        'Cubre con la mermelada.',
      ],
      tip: 'No necesita horno: el limón hace que la crema tome cuerpo.',
    ),
    (
      nombres: ['mousse de chocolate', 'mousse'],
      titulo: 'Mousse de chocolate',
      rinde: 'para 4',
      tiempo: '20 minutos, más 3 horas de heladera',
      ingredientes: [
        '200 g de chocolate',
        '1 taza de crema de leche para batir, bien fría',
        '2 cucharadas de azúcar',
      ],
      pasos: [
        'Derrite el chocolate a baño María y deja que se entibie.',
        'Bate la crema con el azúcar hasta que forme picos suaves.',
        'Mezcla el chocolate con la crema con movimientos envolventes, sin batir.',
        'Reparte en vasitos y llévalos a la heladera mínimo 3 horas.',
      ],
      tip:
          'Si el chocolate está muy caliente, baja la crema: espera a que se entibie.',
    ),
    (
      nombres: ['gelatina', 'gelatina con frutas'],
      titulo: 'Gelatina con frutas',
      rinde: 'para 6',
      tiempo: '15 minutos, más 4 horas',
      ingredientes: [
        '1 sobre de gelatina del sabor que quieras',
        '1 taza de agua hirviendo',
        '1 taza de agua fría',
        'fruta picada: durazno, plátano, frutilla',
      ],
      pasos: [
        'Disuelve el polvo en el agua hirviendo.',
        'Agrega el agua fría.',
        'Pon la fruta en vasitos, vierte la gelatina y llévala a la heladera hasta que cuaje.',
      ],
      tip:
          'La piña y la papaya frescas no dejan cuajar la gelatina: úsalas en lata o cocidas.',
    ),
    (
      nombres: ['ensalada de frutas', 'salpicon de frutas', 'coctel de frutas'],
      titulo: 'Ensalada de frutas',
      rinde: 'para 4',
      tiempo: '15 minutos',
      ingredientes: [
        '2 plátanos y 1 manzana',
        '1 taza de papaya o piña',
        '1 taza de frutillas',
        'el jugo de 1 naranja',
        'yogur, miel o leche condensada (opcional)',
      ],
      pasos: [
        'Pela y pica toda la fruta en cubitos.',
        'Mézclala con el jugo de naranja: así no se pone oscura.',
        'Sirve sola o con yogur y miel.',
      ],
      tip: '',
    ),
    (
      nombres: ['papas fritas', 'papa frita'],
      titulo: 'Papas fritas crocantes',
      rinde: 'para 2',
      tiempo: '30 minutos',
      ingredientes: ['4 papas', 'aceite para freír', 'sal'],
      pasos: [
        'Córtalas en bastones, lávalas y sécalas bien.',
        'Primera fritura a fuego medio, 5 minutos, sin que doren.',
        'Sácalas, sube el fuego y fríelas otra vez hasta que estén doradas.',
        'Sal al final.',
      ],
      tip: 'La doble fritura es el secreto de las papas crocantes.',
    ),
    (
      nombres: ['pure de papa', 'pure', 'pure de papas'],
      titulo: 'Puré de papa',
      rinde: 'para 4',
      tiempo: '30 minutos',
      ingredientes: [
        '1 kg de papas',
        '3 cucharadas de mantequilla',
        'media taza de leche caliente',
        'sal, pimienta y nuez moscada (opcional)',
      ],
      pasos: [
        'Pela las papas, córtalas y hiérvelas en agua con sal hasta que estén blandas.',
        'Cuélalas bien y písalas en caliente.',
        'Suma la mantequilla y la leche caliente de a poco, mezclando, hasta que quede cremoso.',
      ],
      tip: 'No uses licuadora: la papa se pone pegajosa como chicle.',
    ),
    (
      nombres: ['pollo frito', 'pollo broaster', 'broaster'],
      titulo: 'Pollo frito',
      rinde: 'para 4',
      tiempo: '1 hora 30 minutos (con la marinada)',
      ingredientes: [
        '8 presas de pollo',
        'sal, ajo, pimienta y el jugo de 1 limón',
        '2 tazas de harina con sal y paprika',
        '2 huevos batidos',
        'aceite para freír',
      ],
      pasos: [
        'Marina el pollo con sal, ajo, pimienta y limón, mínimo una hora.',
        'Pasa cada presa por harina, después por huevo y otra vez por harina.',
        'Fríe a fuego medio unos 15 minutos, dando vuelta, hasta que esté dorado y cocido por dentro.',
      ],
      tip:
          'Fuego medio, no fuerte: si no, se dora por fuera y queda crudo por dentro.',
    ),
    (
      nombres: ['pollo al horno'],
      titulo: 'Pollo al horno',
      rinde: 'para 4',
      tiempo: '1 hora 15 minutos',
      ingredientes: [
        '1 pollo en presas (o 6 piernas)',
        '4 papas en gajos',
        '4 dientes de ajo y el jugo de 1 limón',
        '2 cucharadas de aceite',
        'paprika, orégano, sal y pimienta',
      ],
      pasos: [
        'Adoba el pollo con el ajo, el limón, el aceite y los condimentos (si puedes, una hora antes).',
        'Ponlo en una fuente con las papas alrededor.',
        'Horno a 200 °C de 50 a 60 minutos, dando vuelta a la mitad, hasta que esté dorado y sin nada rosado por dentro.',
      ],
      tip: 'Si al pincharlo el jugo sale transparente, está listo.',
    ),
    (
      nombres: ['arroz con pollo'],
      titulo: 'Arroz con pollo',
      rinde: 'para 4',
      tiempo: '50 minutos',
      ingredientes: [
        '4 presas de pollo',
        '2 tazas de arroz',
        '1 cebolla, 1 pimentón y 2 dientes de ajo',
        '1 zanahoria y media taza de arvejas',
        '4 tazas de caldo o agua',
        '1 cucharadita de urucú o paprika, y sal',
      ],
      pasos: [
        'Dora el pollo con sal y sácalo.',
        'En la misma olla sofríe la cebolla, el ajo y el pimentón con el urucú.',
        'Suma el arroz, revuelve, agrega el caldo caliente, las verduras y el pollo.',
        'Tapa y cocina a fuego bajo unos 25 minutos.',
      ],
      tip: '',
    ),
    (
      nombres: ['arroz chaufa', 'chaufa', 'arroz chino', 'arroz frito'],
      titulo: 'Arroz chaufa',
      rinde: 'para 2',
      tiempo: '20 minutos',
      ingredientes: [
        '2 tazas de arroz cocido frío',
        '1 pechuga de pollo en cubitos',
        '2 huevos',
        '3 tallos de cebollín',
        '3 cucharadas de salsa de soya',
        '1 cucharadita de aceite de sésamo (opcional) y aceite',
      ],
      pasos: [
        'En sartén bien caliente, saltea el pollo con un poco de aceite.',
        'Suma los huevos y revuélvelos.',
        'Agrega el arroz y el cebollín, y mezcla rápido a fuego fuerte.',
        'Termina con la soya y el aceite de sésamo.',
      ],
      tip:
          'El arroz del día anterior es el ideal: el recién hecho se apelmaza.',
    ),
    (
      nombres: ['tortilla espanola', 'tortilla de papa', 'tortilla de papas'],
      titulo: 'Tortilla española',
      rinde: 'para 4',
      tiempo: '45 minutos',
      ingredientes: [
        '5 papas',
        '1 cebolla (opcional, pero recomendada)',
        '6 huevos',
        'aceite y sal',
      ],
      pasos: [
        'Pela y corta las papas en láminas finas, y la cebolla en pluma.',
        'Fríelas a fuego bajo en bastante aceite unos 20 minutos, hasta que estén blandas, no crocantes.',
        'Escúrrelas y mézclalas con los huevos batidos y sal.',
        'Cuaja en una sartén con poco aceite; dale vuelta con ayuda de un plato y dora el otro lado.',
      ],
      tip: 'El momento de darle vuelta con el plato asusta, pero sale.',
    ),
    (
      nombres: ['omelette', 'omelet', 'tortilla de huevo'],
      titulo: 'Omelette',
      rinde: 'para 1',
      tiempo: '10 minutos',
      ingredientes: [
        '2 o 3 huevos',
        'sal y pimienta',
        '1 cucharadita de mantequilla',
        'relleno a gusto: queso, jamón, tomate, cebolla o champiñones',
      ],
      pasos: [
        'Bate los huevos con sal y pimienta.',
        'Derrite la mantequilla en la sartén, a fuego medio, y echa el huevo.',
        'Cuando los bordes cuajen, pon el relleno en una mitad.',
        'Dobla y deja un minuto más.',
      ],
      tip: '',
    ),
    (
      nombres: ['tostadas francesas', 'tostada francesa', 'pan frances'],
      titulo: 'Tostadas francesas',
      rinde: 'para 2',
      tiempo: '15 minutos',
      ingredientes: [
        '4 rebanadas de pan (mejor si es del día anterior)',
        '2 huevos',
        'media taza de leche',
        '1 cucharada de azúcar y canela',
        'mantequilla',
        'miel o fruta para servir',
      ],
      pasos: [
        'Bate los huevos con la leche, el azúcar y la canela.',
        'Remoja el pan unos segundos por lado.',
        'Dóralo en la sartén con mantequilla.',
        'Sirve con miel o fruta.',
      ],
      tip: 'El pan un poco duro absorbe mejor y no se rompe.',
    ),
    (
      nombres: ['wrap de pollo', 'wrap', 'wraps'],
      titulo: 'Wrap de pollo',
      rinde: 'para 2',
      tiempo: '20 minutos',
      ingredientes: [
        '2 tortillas de harina grandes',
        '1 pechuga de pollo',
        'lechuga, tomate y queso',
        'mayonesa o tu salsa favorita',
        'sal y pimienta',
      ],
      pasos: [
        'Cocina el pollo a la plancha con sal y pimienta, y córtalo en tiras.',
        'Calienta las tortillas.',
        'Pon salsa, lechuga, tomate, queso y pollo, y enróllalas cerrando los extremos.',
      ],
      tip: 'Ideal para llevar a la U envuelto en papel aluminio.',
    ),
    (
      nombres: ['quesadilla', 'quesadillas'],
      titulo: 'Quesadillas',
      rinde: 'para 2',
      tiempo: '15 minutos',
      ingredientes: [
        '4 tortillas de harina',
        '150 g de queso que se derrita (mozzarella o menonita)',
        'opcional: pollo desmenuzado, jamón o champiñones',
      ],
      pasos: [
        'Pon una tortilla en la sartén a fuego medio, cubre la mitad con queso (y lo que quieras) y dóblala.',
        'Dora un par de minutos por lado, hasta que el queso se derrita.',
      ],
      tip: 'Con guacamole al lado, nivel experto.',
    ),
    (
      nombres: ['tacos', 'taco'],
      titulo: 'Tacos',
      rinde: 'para 4',
      tiempo: '30 minutos',
      ingredientes: [
        '8 tortillas de maíz o de harina',
        '500 g de carne molida o pollo desmenuzado',
        '1 cebolla y 1 tomate',
        '1 cucharadita de comino, 1 de paprika y sal',
        'lechuga, queso rallado, palta y salsa picante',
      ],
      pasos: [
        'Sofríe la cebolla, suma la carne y los condimentos, y cocina hasta que se dore.',
        'Calienta las tortillas en una sartén seca.',
        'Rellena con la carne, lechuga, tomate, queso y palta.',
      ],
      tip: '',
    ),
    (
      nombres: ['nachos'],
      titulo: 'Nachos',
      rinde: 'para 4',
      tiempo: '20 minutos',
      ingredientes: [
        '1 bolsa de totopos (nachos)',
        '200 g de queso rallado',
        '200 g de carne molida cocida con comino (opcional)',
        'tomate y cebolla picados',
        'locoto o jalapeño',
        'guacamole',
      ],
      pasos: [
        'Pon los totopos en una fuente, la carne y el queso encima.',
        'Horno a 180 °C unos 8 minutos (o microondas 1 minuto), hasta que el queso se derrita.',
        'Termina con tomate, cebolla, locoto y guacamole.',
      ],
      tip: '',
    ),
    (
      nombres: ['lasana', 'lasagna', 'lasanas'],
      titulo: 'Lasaña',
      rinde: 'para 6',
      tiempo: '1 hora 30 minutos',
      ingredientes: [
        '12 láminas de lasaña',
        '**Boloñesa:** 500 g de carne molida, 1 cebolla, 2 dientes de ajo, 1 zanahoria rallada, 500 g de salsa de tomate, orégano, sal y pimienta',
        '**Bechamel:** 50 g de mantequilla, 4 cucharadas de harina, 2 tazas de leche, sal y nuez moscada',
        '200 g de queso mozzarella',
        'queso parmesano rallado',
      ],
      pasos: [
        'Boloñesa: sofríe la cebolla, el ajo y la zanahoria; dora la carne, suma el tomate y los condimentos, y cocina 20 minutos.',
        'Bechamel: derrite la mantequilla, suma la harina y revuelve un minuto; agrega la leche de a poco, batiendo, hasta que espese. Sal y nuez moscada.',
        'Arma en una fuente: un poco de salsa, láminas, boloñesa, bechamel y queso, y repite en capas. Termina con bechamel y queso.',
        'Horno a 180 °C unos 40 minutos. Deja reposar 10 minutos antes de cortar.',
      ],
      tip:
          'Si las láminas son precocidas, no hace falta hervirlas; si no, dales unos minutos en agua hirviendo antes.',
    ),
    (
      nombres: ['bechamel', 'salsa bechamel', 'salsa blanca'],
      titulo: 'Salsa bechamel',
      rinde: '2 tazas',
      tiempo: '15 minutos',
      ingredientes: [
        '50 g de mantequilla',
        '4 cucharadas de harina',
        '2 tazas de leche',
        'sal y nuez moscada',
      ],
      pasos: [
        'Derrite la mantequilla a fuego medio.',
        'Suma la harina y revuelve un minuto, sin que se dore.',
        'Agrega la leche de a poco, batiendo para que no haga grumos.',
        'Cocina hasta que espese y sazona con sal y nuez moscada.',
      ],
      tip: 'Si se te hacen grumos, pásala por la licuadora unos segundos.',
    ),
    (
      nombres: ['carbonara', 'pasta carbonara', 'espagueti a la carbonara'],
      titulo: 'Pasta a la carbonara',
      rinde: 'para 2',
      tiempo: '20 minutos',
      ingredientes: [
        '200 g de espagueti',
        '100 g de panceta o tocino en cubitos',
        '2 yemas y 1 huevo',
        '50 g de queso parmesano rallado',
        'pimienta negra',
      ],
      pasos: [
        'Cocina la pasta en agua con sal.',
        'Dora la panceta en una sartén, sin aceite.',
        'Bate las yemas, el huevo, el queso y bastante pimienta.',
        'Fuera del fuego, mezcla la pasta caliente con la panceta y después con el huevo, revolviendo rápido; suma un chorrito del agua de la pasta para que quede cremosa.',
      ],
      tip:
          'La original no lleva crema: lo cremoso sale del huevo y el queso. Fuera del fuego, para que el huevo no se cuaje.',
    ),
    (
      nombres: ['ensalada cesar', 'ensalada caesar'],
      titulo: 'Ensalada César',
      rinde: 'para 2',
      tiempo: '20 minutos',
      ingredientes: [
        '1 lechuga romana',
        '1 pechuga de pollo',
        '1 taza de cubitos de pan tostado',
        'queso parmesano rallado',
        '**Aderezo:** 3 cucharadas de mayonesa, 1 de jugo de limón, 1 diente de ajo rallado, 1 cucharadita de mostaza, parmesano, sal y pimienta',
      ],
      pasos: [
        'Cocina el pollo a la plancha con sal y córtalo en tiras.',
        'Mezcla los ingredientes del aderezo.',
        'Junta la lechuga cortada con el aderezo, el pollo, el pan y el parmesano.',
      ],
      tip: 'Muchas versiones llevan anchoas en el aderezo; esta es la fácil.',
    ),
    (
      nombres: ['ramen', 'sopa instantanea', 'fideo instantaneo', 'maruchan'],
      titulo: 'Ramen mejorado',
      rinde: 'para 1',
      tiempo: '10 minutos',
      ingredientes: [
        '1 paquete de fideo instantáneo',
        '1 huevo',
        'un puñado de verduras: cebollín, zanahoria rallada, repollo',
        'un chorrito de salsa de soya',
        'opcional: pollo cocido desmenuzado',
      ],
      pasos: [
        'Hierve el agua y cocina el fideo con la mitad del sobre de condimento (el sobre entero tiene muchísima sal).',
        'Suma las verduras el último minuto.',
        'Rompe el huevo adentro y tapa 2 minutos (o agrega un huevo duro partido).',
        'Termina con soya y cebollín.',
      ],
      tip: 'Con huevo y verduras pasa de snack a comida de verdad.',
    ),
    (
      nombres: ['avena', 'avena con leche', 'avena nocturna', 'overnight oats'],
      titulo: 'Avena',
      rinde: 'para 1',
      tiempo: '5 minutos (o una noche en la heladera)',
      ingredientes: [
        'media taza de avena en hojuelas',
        'media taza de leche o yogur',
        '1 cucharadita de miel',
        'fruta picada y canela',
      ],
      pasos: [
        'En caliente: cocina la avena con la leche 5 minutos, moviendo.',
        'En frío: mézclala en un frasco con la leche y la miel, y déjala toda la noche en la heladera.',
        'Por la mañana, fruta y canela encima.',
      ],
      tip: 'Desayuno de examen: llena, es barato y no te da sueño.',
    ),
    (
      nombres: ['curry de pollo', 'pollo al curry', 'curry'],
      titulo: 'Pollo al curry',
      rinde: 'para 4',
      tiempo: '45 minutos',
      ingredientes: [
        '500 g de pechuga de pollo en cubos',
        '1 cebolla, 2 dientes de ajo y un trocito de jengibre',
        '2 cucharadas de curry en polvo',
        '1 lata de leche de coco (o crema de leche)',
        '1 tomate picado',
        'sal y arroz para acompañar',
      ],
      pasos: [
        'Sofríe la cebolla, el ajo y el jengibre picados.',
        'Suma el curry y revuelve un minuto para que suelte el aroma.',
        'Agrega el pollo y dóralo; suma el tomate y la leche de coco.',
        'Cocina de 15 a 20 minutos a fuego bajo y sirve con arroz.',
      ],
      tip: '',
    ),
    (
      nombres: ['sopa de verduras', 'crema de verduras'],
      titulo: 'Sopa de verduras',
      rinde: 'para 4',
      tiempo: '40 minutos',
      ingredientes: [
        '2 papas y 2 zanahorias',
        '1 zapallo chico',
        '1 cebolla y 1 tallo de apio',
        '1 taza de choclo o arvejas',
        '1 litro y medio de agua o caldo',
        'sal, pimienta y perejil',
      ],
      pasos: [
        'Pica todo en cubos.',
        'Sofríe la cebolla y el apio, suma el resto de las verduras y el agua.',
        'Cocina 25 minutos, hasta que todo esté blando.',
        'Sírvela así, o licúala y tienes una crema.',
      ],
      tip: '',
    ),
    (
      nombres: ['hot dog', 'hotdog', 'panchito', 'panchitos', 'perro caliente'],
      titulo: 'Hot dog',
      rinde: 'para 4',
      tiempo: '15 minutos',
      ingredientes: [
        '4 panes de hot dog',
        '4 salchichas',
        'cebolla picada',
        'papas al hilo',
        'kétchup, mostaza y mayonesa',
      ],
      pasos: [
        'Hierve las salchichas 5 minutos (o dóralas en la sartén).',
        'Calienta los panes.',
        'Arma con la salchicha, las salsas, la cebolla y las papas al hilo encima.',
      ],
      tip: '',
    ),
    (
      nombres: ['ceviche', 'cebiche'],
      titulo: 'Ceviche',
      rinde: 'para 4',
      tiempo: '30 minutos',
      ingredientes: [
        '500 g de pescado blanco bien fresco',
        'el jugo de 10 limones',
        '1 cebolla morada en tiras',
        '1 ají o locoto picado',
        'cilantro y sal',
        'camote y choclo cocidos para servir',
      ],
      pasos: [
        'Corta el pescado en cubos.',
        'Cúbrelo con el jugo de limón recién exprimido, sal, ají y la cebolla.',
        'Espera de 10 a 15 minutos y sirve con cilantro, camote y choclo.',
      ],
      tip:
          'El pescado tiene que ser bien fresco: es lo único que no se negocia.',
    ),
    (
      nombres: ['guacamole'],
      titulo: 'Guacamole',
      rinde: 'para 4',
      tiempo: '10 minutos',
      ingredientes: [
        '2 paltas maduras',
        'media cebolla y 1 tomate picaditos',
        'el jugo de 1 limón',
        'sal y cilantro',
      ],
      pasos: [
        'Pisa las paltas con un tenedor.',
        'Mezcla con la cebolla, el tomate, el limón, sal y cilantro.',
      ],
      tip: 'El limón evita que se ponga negro. Guárdalo con el carozo adentro.',
    ),
    (
      nombres: ['limonada'],
      titulo: 'Limonada',
      rinde: '1 litro',
      tiempo: '5 minutos',
      ingredientes: [
        'el jugo de 4 limones',
        '1 litro de agua fría',
        'azúcar a gusto',
        'mucho hielo',
      ],
      pasos: [
        'Mezcla el jugo con el agua y el azúcar hasta que se disuelva.',
        'Sirve con hielo.',
      ],
      tip:
          'Si la licúas con un poco de cáscara y la cuelas, queda más aromática (y con un toque amargo).',
    ),
    (
      nombres: ['licuado', 'licuados', 'batido', 'smoothie', 'jugo con leche'],
      titulo: 'Licuado de frutas',
      rinde: 'para 1',
      tiempo: '5 minutos',
      ingredientes: [
        '1 taza de fruta: plátano, frutilla o papaya',
        '1 taza de leche',
        'azúcar o miel a gusto',
        'hielo',
      ],
      pasos: ['Licúa todo un minuto y listo.'],
      tip: 'Con una cucharada de avena, aguanta hasta el almuerzo.',
    ),
    (
      nombres: ['milkshake', 'malteada', 'batido de helado'],
      titulo: 'Milkshake',
      rinde: 'para 1',
      tiempo: '5 minutos',
      ingredientes: ['3 bochas de helado', 'media taza de leche fría'],
      pasos: ['Licúa el helado con la leche hasta que quede cremoso.'],
      tip: 'Con menos leche sale más espeso.',
    ),
    (
      nombres: ['chocolate caliente', 'chocolate'],
      titulo: 'Chocolate caliente',
      rinde: 'para 2',
      tiempo: '10 minutos',
      ingredientes: [
        '2 tazas de leche',
        '50 g de chocolate en barra (o 2 cucharadas de cacao)',
        'azúcar a gusto',
        '1 rama de canela (opcional)',
      ],
      pasos: [
        'Calienta la leche con la canela, sin que hierva fuerte.',
        'Agrega el chocolate picado y mueve hasta que se derrita.',
        'Endulza.',
      ],
      tip: 'Para el surazo, con un cuñapé al lado.',
    ),
    (
      nombres: ['cafe', 'cafe pasado', 'cafe filtrado'],
      titulo: 'Café pasado',
      rinde: 'para 2',
      tiempo: '10 minutos',
      ingredientes: [
        '2 cucharadas colmadas de café molido',
        '2 tazas de agua',
        'azúcar a gusto',
      ],
      pasos: [
        'Hierve el agua y déjala reposar un minuto: no la uses hirviendo a borbotones.',
        'Con filtro: pon el café en el filtro y echa el agua de a poco.',
        'Sin filtro: mezcla el café con el agua caliente, espera 4 minutos y cuélalo con un colador fino.',
      ],
      tip:
          'Una cucharada de café por taza de agua es la medida base; de ahí, a tu gusto.',
    ),
    (
      nombres: ['te helado'],
      titulo: 'Té helado',
      rinde: '1 litro',
      tiempo: '10 minutos, más enfriar',
      ingredientes: [
        '4 bolsitas de té negro o verde',
        '1 litro de agua',
        'azúcar o miel',
        'el jugo de 1 limón',
        'hielo y menta (opcional)',
      ],
      pasos: [
        'Prepara el té con medio litro de agua caliente, 4 minutos, y saca las bolsitas.',
        'Endulza y suma el resto del agua fría y el limón.',
        'Enfría y sirve con hielo.',
      ],
      tip: '',
    ),
    (
      nombres: ['pan casero', 'pan'],
      titulo: 'Pan casero',
      rinde: '2 panes medianos',
      tiempo: '2 horas 30 minutos',
      ingredientes: [
        '500 g de harina',
        '10 g de levadura seca (1 sobre)',
        '1 cucharadita de sal y 1 cucharada de azúcar',
        '2 cucharadas de aceite',
        '300 ml de agua tibia',
      ],
      pasos: [
        'Mezcla la levadura con el agua tibia y el azúcar; espera 10 minutos a que haga espuma.',
        'Suma la harina, la sal y el aceite, y amasa 10 minutos hasta que esté lisa y elástica.',
        'Deja crecer tapada una hora, hasta que doble su tamaño.',
        'Forma los panes, deja crecer 30 minutos más y hornea a 200 °C unos 25 minutos.',
      ],
      tip: 'Si al golpearlo por debajo suena hueco, está listo.',
    ),
    (
      nombres: ['ensalada de atun', 'atun con papa'],
      titulo: 'Ensalada de atún',
      rinde: 'para 2',
      tiempo: '25 minutos',
      ingredientes: [
        '1 lata de atún escurrido',
        '3 papas cocidas en cubos',
        '2 huevos duros',
        '1 taza de choclo o arvejas cocidas',
        'media cebolla morada picadita',
        '3 cucharadas de mayonesa y el jugo de medio limón',
        'sal y pimienta',
      ],
      pasos: [
        'Cocina las papas y los huevos, y deja que se enfríen.',
        'Pica todo y mézclalo con el atún, el choclo y la cebolla.',
        'Suma la mayonesa, el limón, sal y pimienta, y revuelve suave.',
      ],
      tip: 'Fría, de la heladera, es todavía mejor. Ideal para llevar.',
    ),
    (
      nombres: ['fideo con atun', 'fideos con atun', 'pasta con atun'],
      titulo: 'Fideo con atún',
      rinde: 'para 2',
      tiempo: '20 minutos',
      ingredientes: [
        '200 g de fideo',
        '1 lata de atún',
        '1 lata de tomate picado (o 2 tomates)',
        '1 diente de ajo y media cebolla',
        'orégano, sal y aceite',
      ],
      pasos: [
        'Cocina el fideo en agua con sal.',
        'Mientras, fríe el ajo y la cebolla, suma el tomate y el orégano, y deja 5 minutos.',
        'Agrega el atún escurrido, calienta un minuto y mezcla con el fideo.',
      ],
      tip: 'Comida de fin de mes: barata, rápida y llena.',
    ),
    (
      nombres: [
        'lentejas',
        'lenteja',
        'lentejas guisadas',
        'guiso de lentejas',
        'sopa de lentejas',
      ],
      titulo: 'Lentejas guisadas',
      rinde: 'para 4',
      tiempo: '50 minutos',
      ingredientes: [
        '2 tazas de lentejas',
        '1 cebolla, 1 tomate y 2 dientes de ajo',
        '1 zanahoria y 1 papa en cubos',
        '1 cucharadita de comino y 1 de paprika',
        '1 hoja de laurel, sal y aceite',
        'arroz para acompañar',
      ],
      pasos: [
        'Lava las lentejas (no hace falta remojarlas).',
        'Sofríe la cebolla, el ajo y el tomate con el comino y la paprika.',
        'Suma las lentejas, la zanahoria, la papa, el laurel y agua hasta cubrir dos dedos por encima.',
        'Cocina de 30 a 40 minutos a fuego medio, hasta que estén blandas. La sal, al final.',
      ],
      tip:
          'Con arroz son una proteína completa. Y al día siguiente saben mejor.',
    ),
    (
      nombres: ['arroz con queso'],
      titulo: 'Arroz con queso',
      rinde: 'para 4',
      tiempo: '35 minutos',
      ingredientes: [
        '2 tazas de arroz',
        '4 tazas de agua (o mitad agua y mitad leche)',
        '250 g de queso fresco desmenuzado',
        '2 cucharadas de mantequilla',
        'sal',
      ],
      pasos: [
        'Cocina el arroz en el agua con sal hasta que esté casi seco.',
        'Suma la leche (si usas), la mantequilla y el queso, y revuelve a fuego bajo unos 5 minutos.',
        'Tiene que quedar cremoso, con el queso derretido.',
      ],
      tip: 'Acompaña perfecto a la carne o al pollo a la parrilla.',
    ),
    (
      nombres: ['pan de arroz'],
      titulo: 'Pan de arroz',
      rinde: 'unos 15',
      tiempo: '1 hora, más una noche de remojo',
      ingredientes: [
        '500 g de arroz (o 500 g de harina de arroz)',
        '1 taza de yuca cocida y molida',
        '300 g de queso fresco molido',
        '100 g de manteca o mantequilla',
        '1 huevo',
        'leche, la necesaria',
        'sal',
      ],
      pasos: [
        'Si usas arroz, déjalo en remojo una noche, escúrrelo y muélelo hasta que sea harina.',
        'Mezcla la harina de arroz con la yuca, el queso, la manteca, el huevo y sal.',
        'Suma leche de a poco hasta tener una masa suave.',
        'Forma panes chatos, ponlos sobre hojas de plátano o en una bandeja, y hornea a 200 °C unos 20 minutos.',
      ],
      tip: 'Típico de Santa Cruz y el Beni, con café a la tarde.',
    ),
    (
      nombres: [
        'pollo a la plancha',
        'pechuga a la plancha',
        'pechuga de pollo',
      ],
      titulo: 'Pollo a la plancha',
      rinde: 'para 2',
      tiempo: '20 minutos',
      ingredientes: [
        '2 pechugas de pollo',
        '1 diente de ajo y el jugo de medio limón',
        'orégano, paprika, sal y pimienta',
        '1 cucharada de aceite',
      ],
      pasos: [
        'Abre las pechugas en dos, como un libro, para que queden finas.',
        'Adóbalas con el ajo, el limón y los condimentos, aunque sea 10 minutos.',
        'Plancha o sartén bien caliente con el aceite: 4 o 5 minutos por lado, sin moverlas.',
        'Antes de servir, corta una: por dentro no tiene que quedar nada rosado.',
      ],
      tip: 'Si las aplanas, se cocinan parejo y no quedan secas.',
    ),
    (
      nombres: [
        'alitas',
        'alitas de pollo',
        'alitas bbq',
        'alitas al horno',
        'alas de pollo',
      ],
      titulo: 'Alitas al horno',
      rinde: 'para 3',
      tiempo: '50 minutos',
      ingredientes: [
        '1 kg de alitas de pollo',
        '2 cucharadas de aceite',
        '1 cucharadita de paprika, 1 de ajo en polvo, sal y pimienta',
        'media taza de salsa barbacoa (o miel con salsa de soya)',
      ],
      pasos: [
        'Sécalas bien con papel y mézclalas con el aceite y los condimentos.',
        'En una bandeja, separadas, al horno a 200 °C unos 40 minutos, dando vuelta a la mitad.',
        'Píntalas con la salsa y dales 5 minutos más.',
      ],
      tip: 'Secarlas bien es lo que las deja crocantes.',
    ),
    (
      nombres: ['nuggets', 'nuggets de pollo', 'nuggets caseros'],
      titulo: 'Nuggets caseros',
      rinde: 'para 3',
      tiempo: '35 minutos',
      ingredientes: [
        '2 pechugas de pollo en trozos',
        'sal, pimienta y ajo en polvo',
        'media taza de harina',
        '2 huevos batidos',
        '1 taza y media de pan rallado (u hojuelas de maíz molidas)',
        'aceite para freír (u horno)',
      ],
      pasos: [
        'Sazona el pollo y pásalo por harina, huevo y pan rallado.',
        'Fríelo en aceite caliente 4 o 5 minutos, hasta que dore.',
        'O al horno: 200 °C unos 20 minutos, dando vuelta a la mitad.',
      ],
      tip: 'Con hojuelas de maíz molidas quedan extra crocantes.',
    ),
    (
      nombres: [
        'ensalada',
        'ensalada mixta',
        'ensalada de lechuga',
        'ensalada de tomate',
      ],
      titulo: 'Ensalada mixta',
      rinde: 'para 2',
      tiempo: '10 minutos',
      ingredientes: [
        '1 lechuga',
        '2 tomates',
        'media cebolla',
        '1 zanahoria rallada (opcional)',
        'aceite, limón o vinagre, y sal',
      ],
      pasos: [
        'Lava bien la lechuga y sécala.',
        'Corta todo: la lechuga con la mano, el tomate en gajos y la cebolla en pluma.',
        'Aliña justo antes de servir: aceite, limón y sal.',
      ],
      tip: 'Si la aliñas antes, la lechuga se marchita.',
    ),
    (
      nombres: [
        'sandwich',
        'sandwich tostado',
        'sandwich de jamon y queso',
        'tostado',
        'tostado de jamon y queso',
      ],
      titulo: 'Sándwich tostado',
      rinde: 'para 1',
      tiempo: '10 minutos',
      ingredientes: [
        '2 rebanadas de pan de molde',
        '2 fetas de jamón',
        '2 láminas de queso',
        'mantequilla',
        'tomate u orégano (opcional)',
      ],
      pasos: [
        'Arma el sándwich con el jamón y el queso adentro.',
        'Unta un poquito de mantequilla por fuera.',
        'Sartén a fuego medio, 2 o 3 minutos por lado, apretando con una espátula, hasta que dore y el queso se derrita.',
      ],
      tip: '',
    ),
    (
      nombres: [
        'pipocas',
        'pipoca',
        'palomitas',
        'palomitas de maiz',
        'cabritas',
        'canchitas',
        'popcorn',
      ],
      titulo: 'Pipocas caseras',
      rinde: 'para 2',
      tiempo: '10 minutos',
      ingredientes: [
        'media taza de maíz para pipocas',
        '2 cucharadas de aceite',
        'sal o azúcar, a gusto',
      ],
      pasos: [
        'Calienta el aceite en una olla con 3 granos de maíz: cuando revientan, está listo.',
        'Echa el resto del maíz, tapa y mueve la olla de vez en cuando.',
        'Cuando pasen 2 o 3 segundos sin que reviente nada, apaga.',
        'Sal o azúcar mientras están calientes.',
      ],
      tip: 'Con tapa sí o sí, o vas a terminar juntando pipocas del piso.',
    ),
  ];
}
