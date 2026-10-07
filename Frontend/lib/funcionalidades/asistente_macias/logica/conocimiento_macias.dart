import '../../../elementos_compartidos/marca/marca_u_market.dart';
import '../modelos/mensaje_macias.dart';
import 'conocimiento_estudio.dart';
import 'memoria_macias.dart';

const _app = MarcaUMarket.nombre;

/// Lo que MacIAs sabe del momento, para que la respuesta suene a
/// conversacion y no a folleto.
class ContextoMacias {
  ContextoMacias({
    required this.nombre,
    required this.ahora,
    required this.version,
    this.esWeb = true,
    this.sorteo = 0,
    MemoriaMacias? memoria,
    this.recientes = const [],
  }) : memoria = memoria ?? MemoriaMacias();

  /// Como llamar a quien escribe: lo que pidio en el chat, o su primer nombre.
  final String nombre;
  final DateTime ahora;
  final String version;

  /// Si la app corre en el navegador (PWA) o instalada desde una tienda.
  final bool esWeb;

  /// Un numero al azar por respuesta, para variar frases y chistes.
  final int sorteo;

  /// Lo que se sabe de la persona: su carrera, lo que le gusta.
  final MemoriaMacias memoria;

  /// Lo ultimo que dijo MacIAs, para no repetir la misma frase dos veces
  /// seguidas: nada delata tanto a un robot como contestar igual.
  final List<String> recientes;

  bool get esDeNoche => ahora.hour >= 22 || ahora.hour < 6;

  String get saludoDelMomento => ahora.hour < 12
      ? 'Buenos días'
      : ahora.hour < 19
      ? 'Buenas tardes'
      : 'Buenas noches';

  /// Elige una de varias frases: al azar, pero no una que se dijo hace poco.
  String alguna(List<String> frases) {
    for (var k = 0; k < frases.length; k++) {
      final frase = frases[(sorteo + k) % frases.length];
      if (!recientes.any((dicho) => dicho.contains(frase))) return frase;
    }
    return frases[sorteo % frases.length];
  }
}

/// Una pregunta que MacIAs sabe responder.
class TemaMacias {
  const TemaMacias({
    required this.id,
    required this.pregunta,
    required this.claves,
    required this.respuesta,
    this.ampliacion,
    this.acciones = const [],
    this.relacionados = const [],
    this.enMenu = true,
  });

  final String id;

  /// Como aparece en los menus.
  final String pregunta;

  /// Palabras y frases que la delatan, ya normalizadas: minusculas, sin
  /// tildes. Un `*` final acepta cualquier terminacion (`public*` reconoce
  /// publicar, publico, publicacion...). Ver `CerebroMacias`.
  final List<String> claves;

  final String Function(ContextoMacias contexto) respuesta;

  /// Lo que se dice si despues piden "otro ejemplo" o "explícame más".
  final String Function(ContextoMacias contexto)? ampliacion;

  final List<AccionMacias> acciones;

  /// Otros temas que se ofrecen despues de responder.
  final List<String> relacionados;

  /// Los temas que ya estan en Preguntas frecuentes se entienden si alguien
  /// los escribe, pero no se ofrecen en los menus: repetirlos ahi seria
  /// mostrar dos veces lo mismo en la misma pantalla de Ayuda.
  final bool enMenu;

  OpcionMacias get comoOpcion => OpcionMacias(id: 't:$id', texto: pregunta);
}

/// Un grupo de temas: cada linea de un menu.
class SeccionMacias {
  const SeccionMacias({
    required this.id,
    required this.titulo,
    required this.intro,
    required this.temas,
    this.claves = const [],
    this.padre,
    this.area = 'app',
  });

  final String id;
  final String titulo;

  /// Lo que dice MacIAs al abrir la seccion.
  final String intro;

  /// Lo que lista la seccion. Un id suelto es un tema; `s:` es otra seccion
  /// y `o:` una orden de la conversacion, como empezar un juego.
  final List<String> temas;

  /// Si alguien escribe exactamente esto ("pedidos", "mi cuenta"), se abre
  /// la seccion entera en vez de adivinar una pregunta.
  final List<String> claves;

  /// La seccion de la que cuelga, para "volver" un nivel y no al principio.
  final String? padre;

  /// De que trata: app, algebra, calculo, cpp o general.
  final String area;

  OpcionMacias get comoOpcion => OpcionMacias(id: 's:$id', texto: titulo);
}

/// Todo lo que MacIAs sabe: la app, las materias y quien es.
///
/// Lo de la app salio de revisar como funciona de verdad (las pantallas, la
/// base de datos), no de como se supone que funciona. Si algo cambia en la
/// app, hay que cambiarlo aqui tambien: una respuesta vieja de un asistente
/// "verificado" confunde mas que no tener asistente.
abstract final class ConocimientoMacias {
  static const humano = 'humano';

  /// La linea de "Sobre MacIAs" que abre los juegos.
  static const ordenJuegos = 'o:juegos';

  static const secciones = <SeccionMacias>[
    SeccionMacias(
      id: 'compras',
      titulo: 'Comprar paso a paso',
      intro: 'Comprar en $_app es fácil. ¿Qué quieres saber?',
      temas: [
        'como_comprar',
        'buscar',
        'varios_locales',
        'no_responde_vendedor',
        'repetir_pedido',
        'favoritos',
      ],
      claves: ['comprar', 'compras', 'compra'],
    ),
    SeccionMacias(
      id: 'pedidos',
      titulo: 'Mis pedidos y entregas',
      intro: 'Hablemos de tus pedidos y las entregas:',
      temas: [
        'donde_pedidos',
        'estados',
        'confirmar_entrega',
        'chat_vendedor',
        'chat_sin_respuesta',
      ],
      claves: ['pedidos', 'pedido', 'entregas', 'entrega'],
    ),
    SeccionMacias(
      id: 'publicar',
      titulo: 'Publicar para vender',
      intro: '¿Vas a vender algo? Esto es lo que más se pregunta:',
      temas: [
        'como_publicar',
        'sabores',
        'fotos',
        'stock',
        'editar_publicacion',
        'limite_publicaciones',
        'borrador',
      ],
      claves: ['publicar', 'publicaciones', 'vender', 'venta'],
    ),
    SeccionMacias(
      id: 'local',
      titulo: 'Mi propio local',
      intro: 'Tener tu propio local tiene lo suyo:',
      temas: [
        'que_es_local',
        'crear_local',
        'ubicacion_local',
        'aceptar_pedidos',
        'ventas',
        'eliminar_local',
      ],
      claves: ['local', 'locales', 'mi local', 'tienda', 'negocio'],
    ),
    SeccionMacias(
      id: 'vender_mas',
      titulo: 'Vender más',
      intro: 'Para vender más, esto es lo que funciona:',
      temas: ['tips_vender', 'ranking', 'visitas', 'ideas_vender'],
      claves: ['vender mas', 'consejos', 'tips'],
    ),
    SeccionMacias(
      id: 'ubicacion',
      titulo: 'Ubicación y encuentros',
      intro: 'Sobre dónde encontrarse en el campus:',
      temas: ['entrega_en', 'punto_encuentro', 'zonas', 'donde_local'],
      claves: ['ubicacion', 'ubicaciones', 'encuentros', 'lugares'],
    ),
    SeccionMacias(
      id: 'cuenta',
      titulo: 'Mi cuenta y perfil',
      intro: 'Sobre tu cuenta y tu perfil:',
      temas: [
        'como_entrar',
        'editar_perfil',
        'completar_perfil',
        'verificada',
        'cerrar_sesion',
        'borrar_cuenta',
      ],
      claves: ['cuenta', 'perfil', 'mi cuenta', 'mi perfil'],
    ),
    SeccionMacias(
      id: 'privacidad',
      titulo: 'Privacidad y seguridad',
      intro: 'Tu privacidad y tu seguridad, sin letra chica:',
      temas: [
        'que_datos',
        'perfil_publico',
        'chats_guardados',
        'seguridad_encuentro',
      ],
      claves: ['privacidad', 'seguridad'],
    ),
    SeccionMacias(
      id: 'app',
      titulo: 'La app: instalar, avisos y fallas',
      intro: 'Sobre la app, instalarla y los avisos:',
      temas: [
        'que_es_app',
        'instalar_iphone',
        'instalar_android',
        'notificaciones_avisos',
        'problemas_app',
        'version',
      ],
      claves: ['instalar', 'app', 'aplicacion', 'notificaciones', 'avisos'],
    ),
    SeccionMacias(
      id: 'reglas',
      titulo: 'Reglas de la comunidad',
      intro: 'Las reglas de la comunidad, en corto:',
      temas: ['reglas_publicar', 'comision', 'oficial', 'sugerencias'],
      claves: ['reglas', 'normas'],
    ),
    SeccionMacias(
      id: 'extra',
      titulo: 'Materias, calculadora y más',
      intro:
          'Además de la app, te ayudo a estudiar (y a distraerte un rato). '
          'Elige:',
      temas: [
        's:algebra',
        's:calculo',
        's:cpp',
        'calculadora',
        'consejos_estudio',
        's:macias',
      ],
      claves: ['materias', 'estudiar', 'estudio', 'mas', 'extra'],
      area: 'general',
    ),
    SeccionMacias(
      id: 'algebra',
      titulo: 'Álgebra',
      intro: 'Álgebra, en el orden del Baldor. ¿Qué tema te toca?',
      temas: ConocimientoEstudio.algebra,
      claves: ['algebra', 'baldor', 'el baldor'],
      padre: 'extra',
      area: 'algebra',
    ),
    SeccionMacias(
      id: 'calculo',
      titulo: 'Cálculo integral',
      intro: 'Cálculo integral. ¿Con qué tema le damos?',
      temas: ConocimientoEstudio.calculo,
      claves: ['calculo', 'calculo integral', 'calculo 2', 'calculo ii'],
      padre: 'extra',
      area: 'calculo',
    ),
    SeccionMacias(
      id: 'cpp',
      titulo: 'Programación en C++',
      intro: 'C++. ¿Por dónde empezamos?',
      temas: ConocimientoEstudio.cpp,
      claves: ['c', 'cpp', 'c plus plus', 'programacion', 'programar'],
      padre: 'extra',
      area: 'cpp',
    ),
    SeccionMacias(
      id: 'macias',
      titulo: 'Sobre MacIAs',
      intro: 'Todo sobre mí (bueno, casi todo):',
      temas: [
        'quien_eres',
        'que_sabes',
        'que_sabes_de_mi',
        'chiste',
        'dato_curioso',
        ordenJuegos,
      ],
      claves: ['macias'],
      padre: 'extra',
      area: 'general',
    ),
  ];

  static final temas = <TemaMacias>[
    ..._temasDeLaApp,
    ...ConocimientoEstudio.temas,
    ..._temasDeMacias,
    ..._temasDeAyuda,
    ..._temasSueltos,
  ];

  static final _porId = {for (final tema in temas) tema.id: tema};

  static TemaMacias? tema(String id) => _porId[id];

  static SeccionMacias? seccion(String id) {
    for (final seccion in secciones) {
      if (seccion.id == id) return seccion;
    }
    return null;
  }

  /// La seccion a la que pertenece un tema, para poder "volver".
  static SeccionMacias? seccionDe(String temaId) {
    for (final seccion in secciones) {
      if (seccion.temas.contains(temaId)) return seccion;
    }
    return null;
  }

  /// De que trata un tema: app, algebra, calculo, cpp o general.
  static String areaDe(String temaId) =>
      seccionDe(temaId)?.area ??
      (temaId.startsWith('faq_') || temaId.startsWith('app_')
          ? 'app'
          : 'general');

  /// Las doce lineas del menu principal: diez de la app, las materias, y
  /// hablar con una persona como ultima opcion, como en cualquier menu de
  /// atencion.
  static List<OpcionMacias> get menuPrincipal => [
    for (final seccion in secciones)
      if (seccion.padre == null) seccion.comoOpcion,
    tema(humano)!.comoOpcion,
  ];

  // =====================================================================
  // La app
  // =====================================================================
  static final _temasDeLaApp = <TemaMacias>[
    // ------------------------------------------------------------ compras
    TemaMacias(
      id: 'como_comprar',
      pregunta: '¿Cómo hago un pedido?',
      claves: [
        'hacer pedido',
        'hago pedido',
        'como compro',
        'como pido',
        'quiero comprar',
        'quiero pedir',
        'compr*',
        'encargar',
        'encargo',
      ],
      respuesta: (c) =>
          'Fácil, en cuatro pasos:\n'
          '1. Toca la publicación que te interesa. Si tiene sabores o '
          'tamaños, elige uno.\n'
          '2. Toca **Agregar al carrito**.\n'
          '3. En el carrito (arriba, en el inicio) elige **¿Dónde te lo '
          'entregan?**: una zona del campus y una referencia, como mesa, '
          'piso o puerta.\n'
          '4. Toca **Contactar con el vendedor**. Tiene **15 minutos** para '
          'aceptar.\n\n'
          'Cuando acepta, se abre el chat del pedido para que coordinen.',
      acciones: [AccionMacias('Ver mi carrito', DestinoMacias.carrito)],
      relacionados: ['varios_locales', 'no_responde_vendedor', 'buscar'],
    ),
    TemaMacias(
      id: 'buscar',
      pregunta: '¿Cómo encuentro algo rápido?',
      claves: [
        'buscar',
        'busco',
        'buscador',
        'busqueda',
        'encontrar',
        'encuentro algo',
        'categoria*',
        'filtrar',
      ],
      respuesta: (c) =>
          'Tienes tres atajos:\n'
          '• **El buscador** de arriba: busca por producto, local o persona.\n'
          '• **Las categorías** del inicio: Comida, Tecnología, Ropa, Clases '
          'y tutorías y muchas más.\n'
          '• **Lo que todos quieren en el campus**: lo más visto, en el '
          'carrusel morado.',
      relacionados: ['favoritos', 'como_comprar'],
    ),
    TemaMacias(
      id: 'varios_locales',
      pregunta: '¿Puedo pedir a dos locales a la vez?',
      claves: [
        'dos locales',
        'varios locales',
        'distintos locales',
        'otro local',
        'dos vendedores',
        'varios vendedores',
        'mezclar',
      ],
      respuesta: (c) =>
          'Cada pedido es para **un solo vendedor**. Si tu carrito tiene '
          'cosas de dos, la app te pide hacer **un pedido por cada local**.\n\n'
          'Así cada uno recibe solo lo suyo y coordinas con cada quien por '
          'separado.',
      relacionados: ['como_comprar', 'buscar'],
    ),
    TemaMacias(
      id: 'no_responde_vendedor',
      pregunta: '¿Qué pasa si el vendedor no responde?',
      claves: [
        'no responde',
        'no contesta',
        'nadie responde',
        'nadie me responde',
        'nadie contesta',
        'nadie me contesta',
        'no acepta',
        'no acepto',
        'venci*',
        'esperando',
        'cuanto tarda',
        'tarda',
        'demora',
        '15 minutos',
        'quince minutos',
      ],
      respuesta: (c) =>
          'Tranqui: tu solicitud espera **15 minutos**. Si en ese tiempo no la '
          'acepta, queda como **Vencido**: no se te cobra ni se reserva nada, '
          'y puedes pedir de nuevo más tarde o probar con otro local.\n\n'
          'Mientras estás en la pantalla de espera, también puedes tocar '
          '**Cancelar solicitud**.'
          '${c.esDeNoche ? '\n\nA esta hora es normal que algunos vendedores '
                    'tarden más.' : ''}',
      relacionados: ['estados', 'como_comprar'],
    ),
    TemaMacias(
      id: 'repetir_pedido',
      pregunta: '¿Puedo repetir un pedido anterior?',
      claves: [
        'repetir pedido',
        'repetir',
        'repito',
        'otra vez',
        'de nuevo',
        'volver a pedir',
        'mismo pedido',
        'pedir igual',
      ],
      respuesta: (c) =>
          '¡Sí! En **Mis pedidos** busca uno que ya hiciste y toca '
          '**Repetir**: tu carrito se arma con lo mismo.\n\n'
          'Si ya tenías otras cosas, te pregunta si quieres reemplazarlas. Lo '
          'que ya no esté disponible no se agrega.',
      acciones: [AccionMacias('Abrir mis pedidos', DestinoMacias.pedidos)],
      relacionados: ['donde_pedidos', 'como_comprar'],
    ),
    TemaMacias(
      id: 'favoritos',
      pregunta: '¿Para qué sirve el corazón?',
      claves: [
        'corazon',
        'favorito*',
        'guardar',
        'guardo',
        'guardados',
        'me gusta publicacion',
      ],
      respuesta: (c) =>
          'Guarda la publicación en tus **Favoritos** para encontrarla '
          'después. Los ves en tu **Perfil**, en la pestaña del corazón.\n\n'
          'Por defecto **solo los ves tú**. Si quieres mostrarlos en tu '
          'perfil público, actívalo en **Configuración > Privacidad**.',
      acciones: [AccionMacias('Ver mis favoritos', DestinoMacias.favoritos)],
      relacionados: ['perfil_publico', 'buscar'],
    ),

    // ------------------------------------------------------------ pedidos
    TemaMacias(
      id: 'donde_pedidos',
      pregunta: '¿Dónde veo mis pedidos?',
      claves: [
        'mis pedidos',
        'ver pedidos',
        'veo pedidos',
        'donde pedidos',
        'historial',
        'boleta',
        'recibo',
      ],
      respuesta: (c) =>
          'Toca el ícono de la **boleta** arriba en el inicio. Ahí están tus '
          'compras y, si vendes, también los pedidos que recibes.\n\n'
          'Cada uno muestra su estado y su detalle.',
      acciones: [AccionMacias('Abrir mis pedidos', DestinoMacias.pedidos)],
      relacionados: ['estados', 'confirmar_entrega'],
    ),
    TemaMacias(
      id: 'estados',
      pregunta: '¿Qué significa cada estado?',
      claves: [
        'estado*',
        'pendiente',
        'aceptado',
        'rechazado',
        'cancelado',
        'entregado',
        'falta confirmar',
        'significa',
      ],
      respuesta: (c) =>
          'Así se lee tu pedido:\n'
          '• **Pendiente**: el vendedor todavía no responde (tiene 15 '
          'minutos).\n'
          '• **Aceptado**: ya pueden coordinar por el chat del pedido.\n'
          '• **Falta confirmar**: uno marcó la entrega y falta que el otro la '
          'confirme.\n'
          '• **Entregado**: listo, la entrega quedó confirmada.\n'
          '• **Vencido**: pasaron los 15 minutos sin respuesta.\n'
          '• **Rechazado** o **Cancelado**: no se pudo atender o alguien lo '
          'canceló.',
      relacionados: ['confirmar_entrega', 'no_responde_vendedor'],
    ),
    TemaMacias(
      id: 'confirmar_entrega',
      pregunta: '¿Cómo confirmo que me lo entregaron?',
      claves: [
        'confirmar',
        'confirmo',
        'confirmacion',
        'recibi',
        'recibido',
        'marcar entregado',
        'marcar recibido',
        'marco entregado',
        'marco recibido',
        'marco',
        'marcar',
        'entregaron',
      ],
      respuesta: (c) =>
          'Cuando se encuentren, uno de los dos toca **Marcar como '
          'recibido** (o **Marcar como entregado**, si vende). Al otro le '
          'llega un aviso para confirmarlo con **Sí, lo recibí** o **Sí, lo '
          'entregué**.\n\n'
          'Si nadie confirma, el pedido se cierra solo a las **24 horas**. Y '
          'si algo no cuadra, háblenlo por el chat antes de confirmar.',
      relacionados: ['estados', 'chat_vendedor'],
    ),
    TemaMacias(
      id: 'chat_vendedor',
      pregunta: '¿Cómo hablo con el vendedor?',
      claves: [
        'chat',
        'chats',
        'hablar vendedor',
        'hablo vendedor',
        'escribir vendedor',
        'escribirle',
        'coordinar',
        'conversacion*',
        'mensaje*',
      ],
      respuesta: (c) =>
          'Cuando acepta tu pedido, en su detalle aparece **Coordinar '
          'con…**: ahí se abre el chat del pedido. Todas tus conversaciones '
          'están en **Configuración > Chats**.\n\n'
          'Arriba del chat queda fijo el punto de entrega que elegiste, para '
          'que no se pierdan.',
      acciones: [AccionMacias('Abrir mis chats', DestinoMacias.chats)],
      relacionados: ['chat_sin_respuesta', 'confirmar_entrega'],
    ),
    TemaMacias(
      id: 'chat_sin_respuesta',
      pregunta: 'El vendedor no contesta en el chat',
      claves: [
        'no contesta chat',
        'no responde chat',
        'no me escribe',
        'no me contesta',
        'no lee',
        'ignora',
        'sin respuesta',
        'seguir whatsapp',
        'pasar whatsapp',
      ],
      respuesta: (c) =>
          'Dale unos minutos. Si pasan **2 minutos** sin respuesta a tu '
          'último mensaje, en el chat aparece la opción de seguir por '
          '**WhatsApp**, solo entre ustedes dos y solo para ese pedido.\n\n'
          'Así nadie se queda esperando, aunque la otra persona no tenga los '
          'avisos activados.',
      relacionados: ['chat_vendedor', 'notificaciones_avisos'],
    ),

    // ----------------------------------------------------------- publicar
    TemaMacias(
      id: 'como_publicar',
      pregunta: '¿Cómo publico algo?',
      claves: [
        'public*',
        'subir producto',
        'subir algo',
        'anunciar',
        'poner venta',
        'vender algo',
        'quiero vender',
        'como vendo',
        'como vender',
        'como puedo vender',
        'vendo',
        'ofrecer',
      ],
      respuesta: (c) =>
          'Toca **Publicar** en la barra de abajo:\n'
          '1. Elige si es un **Producto** (algo físico) o un **Servicio** '
          '(tu talento).\n'
          '2. Ponle un nombre claro, una descripción y el precio en Bs.\n'
          '3. Elige la categoría y suma fotos (hasta **12**).\n'
          '4. Toca **Publicar ahora** y aparece en el inicio con tu nombre.',
      relacionados: ['sabores', 'fotos', 'stock'],
    ),
    TemaMacias(
      id: 'sabores',
      pregunta: '¿Cómo pongo sabores o tamaños?',
      claves: [
        'sabor*',
        'tamano*',
        'variante*',
        'talla*',
        'versiones',
        'precio distinto',
        'precios distintos',
      ],
      respuesta: (c) =>
          'En **Sabores o tamaños** agrega cada versión: queso, carne, '
          'pollo…\n\n'
          'Cada una puede tener **su propio precio**; si la dejas sin precio, '
          'vale lo mismo que el producto. Quien compra elige la versión antes '
          'de pedir, y si los precios varían, la tarjeta muestra **desde '
          'Bs…** con el más barato.',
      relacionados: ['como_publicar', 'stock'],
    ),
    TemaMacias(
      id: 'fotos',
      pregunta: '¿Qué fotos funcionan mejor?',
      claves: ['foto*', 'imagen*', 'portada', 'encuadre', 'camara'],
      respuesta: (c) =>
          'La primera foto es la **portada** y se ve igual en todo el '
          'catálogo, en formato **4:3**. Al subirla puedes ajustar el '
          'encuadre.\n\n'
          'Lo que mejor funciona:\n'
          '• Luz natural, cerca de una ventana.\n'
          '• Fondo limpio y el producto al centro.\n'
          '• Sin texto encima: el nombre y el precio ya se muestran.\n'
          '• Fotos de detalle además de la portada: tienes hasta 12.',
      relacionados: ['como_publicar', 'tips_vender'],
    ),
    TemaMacias(
      id: 'stock',
      pregunta: '¿Para qué sirve la cantidad disponible?',
      claves: [
        'stock',
        'cantidad',
        'unidades',
        'inventario',
        'agotado',
        'existencias',
        'cuantos tengo',
      ],
      respuesta: (c) =>
          'Es opcional. Si indicas cuántas tienes, la cantidad baja sola '
          'cada vez que aceptas un pedido. En **cero** ya no se puede pedir, '
          'pero la publicación sigue ahí: cuando repongas, usa **Ajustar '
          'unidades** en el menú de la publicación.\n\n'
          'Los servicios no llevan cantidad: siempre se pueden solicitar.',
      relacionados: ['editar_publicacion', 'sabores'],
    ),
    TemaMacias(
      id: 'editar_publicacion',
      pregunta: '¿Cómo edito o borro una publicación?',
      claves: [
        'editar',
        'edito',
        'edit* public*',
        'modific* public*',
        'borr* public*',
        'elimin* public*',
        'modificar',
        'cambiar precio',
        'cambi* precio',
        'borro',
        'elimino',
        'mis publicaciones',
      ],
      respuesta: (c) =>
          'En tu **Perfil**, toca el botón **⋮** de la publicación (o '
          'mantenla presionada). Ahí puedes:\n'
          '• **Editar** sus datos.\n'
          '• **Ajustar unidades**.\n'
          '• **Ocultar** sin borrar, y volver a mostrarla.\n'
          '• **Volver a publicar** para subirla al inicio del catálogo.\n'
          '• **Eliminar** para siempre.\n\n'
          'Si tienes local, lo mismo está en tu inventario.',
      acciones: [
        AccionMacias('Ver mis publicaciones', DestinoMacias.misPublicaciones),
      ],
      relacionados: ['stock', 'limite_publicaciones'],
    ),
    TemaMacias(
      id: 'limite_publicaciones',
      pregunta: '¿Cuántas cosas puedo publicar?',
      claves: [
        'cuantas publicaciones',
        'cuantas cosas',
        'cuantos productos',
        // "Límite" solo no: "¿qué es un límite?" es de cálculo.
        'limite publicaciones',
        'limite publicar',
        'limite de publicaciones',
        'maximo',
        'tope',
        'cupo',
      ],
      respuesta: (c) =>
          'Hasta **20 publicaciones nuevas por hora** y **40 por día**. Es '
          'para que nadie llene el catálogo de golpe.\n\n'
          'Borrar y volver a subir **no devuelve cupo**, así que si quieres '
          'cambiar algo, mejor edítalo.',
      relacionados: ['editar_publicacion', 'como_publicar'],
    ),
    TemaMacias(
      id: 'borrador',
      pregunta: 'Dejé una publicación a medias',
      claves: [
        'a medias',
        'medias',
        'borrador',
        'sin terminar',
        'se cerro',
        'perdi lo que escribi',
      ],
      respuesta: (c) =>
          'Tranqui, no se perdió: la app guarda lo que ibas escribiendo. La '
          'próxima '
          'vez que entres a **Publicar** te pregunta si quieres '
          '**continuarla** donde la dejaste.',
      relacionados: ['como_publicar', 'fotos'],
    ),

    // -------------------------------------------------------------- local
    TemaMacias(
      id: 'que_es_local',
      pregunta: '¿Qué gano teniendo un local?',
      claves: [
        'que gano',
        'ventaja*',
        'beneficio*',
        'para que local',
        'que es un local',
        'vitrina',
        'marca',
      ],
      respuesta: (c) =>
          'Un local es tu **vitrina con marca**: nombre, logo y descripción '
          'propios, y aparece en la sección **Locales**. Los más visitados '
          'salen en **Los mejores del campus**.\n\n'
          'Además tienes tu inventario y tus ventas en un solo lugar. Lo que '
          'publicas por tu cuenta sigue funcionando igual.',
      relacionados: ['crear_local', 'ventas'],
    ),
    TemaMacias(
      id: 'crear_local',
      pregunta: '¿Cómo abro mi local?',
      claves: [
        'abrir local',
        'abro local',
        'crear local',
        'creo local',
        'nuevo local',
        'abrir tienda',
        'abrir negocio',
        'emprendimiento',
      ],
      respuesta: (c) =>
          'Ve a **Locales** en la barra de abajo y toca **Crear mi local**. '
          'Te pide:\n'
          '• Un nombre (mínimo 3 letras).\n'
          '• La categoría.\n'
          '• Una descripción corta (opcional).\n'
          '• Tu logo.\n\n'
          'Después lo administras desde ahí mismo.',
      relacionados: ['ubicacion_local', 'que_es_local'],
    ),
    TemaMacias(
      id: 'ubicacion_local',
      pregunta: '¿Cómo aviso dónde estoy vendiendo?',
      claves: [
        'donde estoy',
        'donde vendo',
        'mi ubicacion',
        'ubicacion local',
        'cambi* ubicacion',
        'te encuentran',
        'me movi',
      ],
      respuesta: (c) =>
          'En tu local toca donde dice **Te encuentran en…** (o **Sin '
          'ubicación**) y elige la zona donde estás.\n\n'
          'Así quienes te compran saben a dónde ir. Cuando te muevas, '
          'cámbiala con un toque.',
      relacionados: ['zonas', 'aceptar_pedidos'],
    ),
    TemaMacias(
      id: 'aceptar_pedidos',
      pregunta: '¿Cómo acepto un pedido que me llega?',
      claves: [
        'aceptar',
        'acepto',
        'rechazar',
        'rechazo',
        'nuevo pedido',
        'me llego pedido',
        'recibi pedido',
        'atender',
      ],
      respuesta: (c) =>
          'Te llega el aviso **Nuevo pedido**. Ábrelo desde **Mis pedidos** '
          'y toca **Aceptar pedido** o **Rechazar**.\n\n'
          'Tienes **15 minutos**: si no respondes, vence solo. Al aceptarlo '
          'se abre el chat con quien compra para coordinar la entrega.',
      acciones: [AccionMacias('Abrir mis pedidos', DestinoMacias.pedidos)],
      relacionados: ['confirmar_entrega', 'ventas'],
    ),
    TemaMacias(
      id: 'ventas',
      pregunta: '¿Dónde veo cuánto vendí?',
      claves: [
        'cuanto vendi',
        'cuanto gane',
        'mis ventas',
        'vendi',
        'ganancia*',
        'ingresos',
        'finanzas',
        'estadistica*',
        'rendimiento',
      ],
      respuesta: (c) =>
          'En tu local entra a **Ventas, rendimiento y visitas**: tus '
          'ingresos totales, las ventas de hoy, los últimos 7 días, tu mejor '
          'día y lo que mejor funciona.',
      relacionados: ['visitas', 'tips_vender'],
    ),
    TemaMacias(
      id: 'eliminar_local',
      pregunta: '¿Qué pasa si elimino mi local?',
      claves: [
        'eliminar local',
        'elimino local',
        'borrar local',
        'cerrar local',
        'quitar local',
      ],
      respuesta: (c) =>
          'El local y sus publicaciones dejan de aparecer en el catálogo, y '
          'los pedidos activos se cancelan. El historial de lo ya entregado '
          'se conserva, y lo que publicaste por tu cuenta sigue donde está.\n\n'
          '**No se puede deshacer**, así que piénsalo dos veces.',
      relacionados: ['que_es_local', 'editar_publicacion'],
    ),

    // --------------------------------------------------------- vender mas
    TemaMacias(
      id: 'tips_vender',
      pregunta: 'Consejos para vender más',
      claves: [
        'vender mas',
        'mas ventas',
        'promocionar',
        'promociono',
        'hacer publicidad',
        'dar a conocer',
        'consejo*',
        'tips',
        'tip',
        'truco*',
        'no vendo',
        'nadie compra',
        'mejorar ventas',
      ],
      respuesta: (c) =>
          '${c.nombre}, esto es lo que más ayuda:\n'
          '1. **Una portada que antoje**: buena luz y el producto al centro.\n'
          '2. **Un nombre que diga qué es**: "Empanada de queso al horno" '
          'vende más que "Rica empanada".\n'
          '3. **Precio claro**: si tienes versiones, usa sabores con su propio '
          'precio.\n'
          '4. **Responder rápido**: el pedido vence en 15 minutos.\n'
          '5. **La ubicación al día**: si te encuentran fácil, te vuelven a '
          'comprar.',
      relacionados: ['ranking', 'fotos', 'visitas'],
    ),
    TemaMacias(
      id: 'ranking',
      pregunta: '¿Cómo salgo en "Lo que todos quieren"?',
      claves: [
        'ranking',
        'populares',
        'popular',
        'lo que todos quieren',
        'mejores del campus',
        'destacado*',
        'salir arriba',
        'aparecer primero',
      ],
      respuesta: (c) =>
          '**Lo que todos quieren en el campus** junta las publicaciones más '
          'vistas, y **Los mejores del campus** los locales más visitados. No '
          'se compra ni se elige a mano: se gana con visitas.\n\n'
          'Buenas fotos, buen precio y un nombre claro hacen que más gente '
          'entre.',
      relacionados: ['tips_vender', 'visitas'],
    ),
    TemaMacias(
      id: 'visitas',
      pregunta: '¿Qué son las visitas?',
      claves: [
        'visitas',
        'vistas',
        'cuanta gente',
        'quien vio',
        'quien ve mis publicaciones',
        'contador',
      ],
      respuesta: (c) =>
          'Cuentan cuánta gente vio tus publicaciones y tu local. Las ves en '
          'tu perfil y en tu local.\n\n'
          'Si prefieres que los demás no vean el número, apágalo en '
          '**Privacidad > Vistas de mis publicaciones**: se siguen contando, '
          'solo dejan de mostrarse.',
      acciones: [AccionMacias('Abrir Privacidad', DestinoMacias.privacidad)],
      relacionados: ['ranking', 'ventas'],
    ),
    TemaMacias(
      id: 'ideas_vender',
      pregunta: '¿Qué puedo vender en el campus?',
      claves: [
        'que vender',
        'que puedo vender',
        'que se vende',
        'idea de negocio',
        'ideas de negocio',
        'emprender',
      ],
      respuesta: (c) =>
          'De todo: comida casera y snacks, ropa y accesorios, apuntes y '
          'libros, tecnología, clases y tutorías, diseño, fotografía, '
          'belleza, música, eventos… y cada cosa tiene su categoría.\n\n'
          'Un buen truco: fíjate qué falta en tu facultad y llena ese hueco.',
      relacionados: ['como_publicar', 'reglas_publicar'],
    ),

    // ---------------------------------------------------------- ubicacion
    TemaMacias(
      id: 'entrega_en',
      pregunta: '¿Para qué sirve "Entrega en"?',
      claves: [
        'entrega en',
        'mi zona',
        'elegir zona',
        'elegir ubicacion',
        'campus upsa',
      ],
      respuesta: (c) =>
          'Arriba en el inicio eliges **dónde estás tú** dentro del campus. '
          'Se guarda en tu teléfono y en tu perfil, así no te lo vuelve a '
          'preguntar cada vez que entras.',
      relacionados: ['zonas', 'punto_encuentro'],
    ),
    TemaMacias(
      id: 'punto_encuentro',
      pregunta: '¿Dónde me encuentro con el vendedor?',
      claves: [
        'punto encuentro',
        'punto entrega',
        'lugar entrega',
        'encontrarnos',
        'nos encontramos',
        'me encuentro',
        'encuentro vendedor',
        'donde me lo dan',
        'donde me entregan',
      ],
      respuesta: (c) =>
          'En el carrito eliges la zona y una referencia (mesa, piso, '
          'puerta…). Ese punto queda fijo **arriba del chat** del pedido para '
          'que nadie se pierda.\n\n'
          'Elijan siempre lugares concurridos del campus.',
      relacionados: ['zonas', 'seguridad_encuentro'],
    ),
    TemaMacias(
      id: 'zonas',
      pregunta: '¿Qué zonas del campus hay?',
      claves: [
        'zonas',
        'que zonas',
        'jatata',
        'pascana',
        'mozza',
        'cafeteria',
        'bloque',
        'bloques',
        'bloque a',
        'bloque b',
      ],
      respuesta: (c) =>
          'Estas son las zonas de $_app:\n'
          '• Jatata\n• Pascana\n• Mozza\n• Cafetería\n'
          '• Bloque A\n• Bloque B\n• Ingeniería\n\n'
          'Son las mismas para quien compra y para quien vende, así siempre '
          'hablan del mismo lugar.',
      relacionados: ['entrega_en', 'ubicacion_local'],
    ),
    TemaMacias(
      id: 'donde_local',
      pregunta: '¿Cómo sé dónde está un local?',
      claves: [
        'donde esta local',
        'donde queda',
        'encontrar local',
        'donde esta vendedor',
        'ubicacion vendedor',
        'sin ubicacion',
      ],
      respuesta: (c) =>
          'Cada local muestra **Te encuentran en…** con la zona que confirmó '
          'su dueño. Si dice **Sin ubicación**, pregúntale por el chat cuando '
          'acepte tu pedido.',
      relacionados: ['punto_encuentro', 'zonas'],
    ),

    // ------------------------------------------------------------- cuenta
    TemaMacias(
      id: 'como_entrar',
      pregunta: '¿Cómo entro a $_app?',
      claves: [
        'entrar',
        'entro',
        'ingresar',
        'ingreso',
        'llega codigo',
        'no me llega codigo',
        'no llega codigo',
        'iniciar sesion',
        'login',
        'codigo',
        'numero registro',
        'registro',
        'acceder',
        'correo',
        'contrasena',
        'olvide mi contrasena',
        'password',
      ],
      respuesta: (c) =>
          'Con tu **número de registro** de la UPSA (8 dígitos). Te llega un '
          '**código** a tu correo **@estudiantes.upsa.edu.bo**: lo escribes y '
          'listo. No hay contraseña que recordar.\n\n'
          'Si caducó, pide uno nuevo. Y si pediste varios seguidos, espera '
          'un minuto antes de volver a intentar.',
      relacionados: ['completar_perfil', 'verificada'],
    ),
    TemaMacias(
      id: 'editar_perfil',
      pregunta: '¿Qué puedo cambiar de mi perfil?',
      claves: [
        'editar perfil',
        'cambi* foto',
        'foto perfil',
        'cambi* carrera',
        'cambi* whatsapp',
        'pongo mi whatsapp',
        'poner mi whatsapp',
        'agreg* whatsapp',
        'cambi* numero',
        'cambi* nombre',
        'descripcion perfil',
        'biografia',
      ],
      respuesta: (c) =>
          'Desde **Editar perfil** cambias tu foto, tu carrera, tu WhatsApp '
          'y una descripción corta (hasta 160 caracteres).\n\n'
          'Tu **nombre no se puede cambiar**: es con el que te buscan quienes '
          'te compran o te venden.',
      acciones: [AccionMacias('Editar mi perfil', DestinoMacias.editarPerfil)],
      relacionados: ['completar_perfil', 'perfil_publico'],
    ),
    TemaMacias(
      id: 'completar_perfil',
      pregunta: '¿Por qué me pide completar el perfil?',
      claves: [
        'completar perfil',
        'completa tu perfil',
        'ya casi estas',
        'me pide datos',
        'pide carrera',
        'nombre real',
      ],
      respuesta: (c) =>
          'Para **publicar y pedir** necesitas tu nombre real, tu carrera y '
          'tu WhatsApp: es lo que da confianza entre quienes compran y '
          'venden.\n\n'
          'Tu WhatsApp no es público: solo se comparte con la otra persona '
          'de un pedido aceptado.',
      relacionados: ['editar_perfil', 'que_datos'],
    ),
    TemaMacias(
      id: 'verificada',
      pregunta: '¿Qué significa la cuenta verificada?',
      claves: ['verificad*', 'institucional', 'check verde', 'insignia'],
      respuesta: (c) =>
          'Que entraste con tu correo de la UPSA. Solo estudiantes con '
          'correo institucional pueden usar $_app, así sabes que compras y '
          'vendes dentro de tu comunidad.',
      relacionados: ['como_entrar', 'oficial'],
    ),
    TemaMacias(
      id: 'cerrar_sesion',
      pregunta: '¿Cómo cierro sesión o cambio de cuenta?',
      claves: [
        'cerrar sesion',
        'cierro sesion',
        'cambiar cuenta',
        'cambiar de cuenta',
        'otra cuenta',
        'salir cuenta',
        'logout',
      ],
      respuesta: (c) =>
          'En **Configuración**, al final, toca **Cerrar sesión**. Al volver '
          'a entrar puedes elegir otra cuenta.',
      relacionados: ['borrar_cuenta', 'como_entrar'],
    ),
    TemaMacias(
      id: 'borrar_cuenta',
      pregunta: 'Quiero borrar mi cuenta',
      claves: [
        'borrar cuenta',
        'borrar mi cuenta',
        'borr* cuenta',
        'elimin* cuenta',
        'eliminar cuenta',
        'eliminar mi cuenta',
        'dar baja',
        'darme baja',
        'borrar mis datos',
        'eliminar mis datos',
      ],
      respuesta: (c) =>
          'Pucha, qué pena que te vayas, ${c.nombre}. Escríbenos y borramos tu '
          'cuenta con todo lo asociado:',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['que_datos', 'cerrar_sesion'],
    ),

    // --------------------------------------------------------- privacidad
    TemaMacias(
      id: 'que_datos',
      pregunta: '¿Qué datos guarda la app?',
      claves: [
        'que datos',
        'mis datos',
        'datos guardan',
        'que guardan',
        'informacion personal',
        'privacidad',
      ],
      respuesta: (c) =>
          'Solo lo necesario:\n'
          '• Tu correo institucional, para entrar.\n'
          '• Tu carrera y tu WhatsApp, que escribes tú.\n'
          '• Lo que publicas, tus pedidos, favoritos y notificaciones.\n\n'
          '$_app **no procesa pagos** ni guarda datos bancarios.',
      acciones: [AccionMacias('Abrir Privacidad', DestinoMacias.privacidad)],
      relacionados: ['perfil_publico', 'chats_guardados'],
    ),
    TemaMacias(
      id: 'perfil_publico',
      pregunta: '¿Qué ven los demás de mi perfil?',
      claves: [
        'perfil publico',
        'que ven',
        'que ve',
        'quien ve mi perfil',
        'otros ven',
        'demas ven',
      ],
      respuesta: (c) =>
          'Tu nombre, tu foto, tu carrera, tu descripción y lo que '
          'publicas.\n\n'
          'Tú decides si se ven tus **favoritos** y el número de **visitas**, '
          'desde **Privacidad**. Tu WhatsApp nunca aparece en tu perfil.',
      acciones: [AccionMacias('Abrir Privacidad', DestinoMacias.privacidad)],
      relacionados: ['que_datos', 'visitas'],
    ),
    TemaMacias(
      id: 'chats_guardados',
      pregunta: '¿Se guardan mis chats?',
      claves: [
        'se guardan chats',
        'guardan mensajes',
        'guardan chats',
        'chat privado',
        'leen chats',
        'leen mensajes',
      ],
      respuesta: (c) =>
          'La conversación de un pedido se guarda en $_app por si hay algún '
          'problema con ese pedido.\n\n'
          'Lo que me escribes a mí queda **solo en este teléfono**, para que '
          'pueda acordarme de ti: no se envía a ningún servidor. Lo borras '
          'cuando quieras desde el menú de este chat (los tres puntos de '
          'arriba).',
      relacionados: ['que_datos', 'seguridad_encuentro'],
    ),
    TemaMacias(
      id: 'seguridad_encuentro',
      pregunta: 'Consejos para un encuentro seguro',
      claves: [
        'seguro',
        'es seguro',
        'seguro comprar',
        'segura',
        'seguridad',
        'confianza',
        'peligro',
        'cuidado',
      ],
      respuesta: (c) =>
          'Lo básico:\n'
          '• Encuéntrense en lugares concurridos del campus.\n'
          '• Revisa el producto antes de pagar.\n'
          '• Coordina por el chat del pedido: queda registrado si hay algún '
          'problema.\n'
          '• No pagues por adelantado a alguien que no conoces.\n\n'
          'Si algo te parece raro, escríbenos.',
      relacionados: ['punto_encuentro', 'chats_guardados'],
    ),

    // ---------------------------------------------------------------- app
    TemaMacias(
      id: 'que_es_app',
      pregunta: '¿Qué es $_app?',
      claves: [
        'que es u market',
        'que es umarket',
        'que es la app',
        'que es esta app',
        'para que sirve la app',
        'para que sirve u market',
        'como funciona la app',
        'como funciona u market',
        'que hace la app',
        'que puedo hacer en la app',
        'de que se trata la app',
      ],
      respuesta: (c) =>
          '$_app es el mercado del campus: compras y vendes entre estudiantes '
          'de la UPSA. Comida, ropa, apuntes, clases, tecnología... lo que '
          'sea.\n\n'
          'Así funciona: pides, el vendedor acepta, coordinan por el chat del '
          'pedido y se encuentran en el campus. Sin comisiones, y solo con '
          'correo institucional.',
      acciones: [AccionMacias('Acerca de $_app', DestinoMacias.acercaDe)],
      relacionados: ['como_comprar', 'como_publicar', 'oficial'],
    ),
    TemaMacias(
      id: 'problemas_app',
      pregunta: 'La app falla o no carga',
      claves: [
        'falla',
        'fallas',
        'la app falla',
        'app falla',
        'no carga',
        'no abre',
        'no funciona la app',
        'la app no funciona',
        'se cuelga',
        'se traba',
        'se cierra',
        'se cierra sola',
        'pantalla blanca',
        'pantalla crema',
        'se queda cargando',
        'esta lenta',
        'muy lenta',
        'no anda',
        'error en la app',
        'bug en la app',
      ],
      respuesta: (c) =>
          'Pucha. Prueba esto, en orden:\n'
          '1. Revisa tu conexión a internet.\n'
          '2. Cierra la app del todo (también desde las apps recientes) y '
          'ábrela de nuevo.\n'
          '${c.esWeb ? '3. Si la usas instalada desde el navegador, ciérrala '
                    'y ábrela una vez más: así toma la última versión.\n' : '3. Fíjate si hay una actualización en la tienda.\n'}'
          '4. Si sigue igual, escríbenos con una captura y lo arreglamos.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['version', 'notificaciones_avisos'],
    ),
    TemaMacias(
      id: 'instalar_iphone',
      pregunta: '¿Cómo la instalo en iPhone?',
      claves: [
        'iphone',
        'ios',
        'safari',
        'apple',
        'ipad',
        'instalar',
        'instalo',
        'descargar',
        'descargo',
      ],
      respuesta: (c) =>
          'En iPhone hace falta para recibir avisos:\n'
          '1. Abre $_app en **Safari**.\n'
          '2. Toca **Compartir** (abajo).\n'
          '3. Elige **Añadir a pantalla de inicio**.\n'
          '4. Abre $_app desde el ícono nuevo.',
      acciones: [
        AccionMacias('Ver la guía de instalación', DestinoMacias.instalar),
      ],
      relacionados: ['instalar_android', 'notificaciones_avisos'],
    ),
    TemaMacias(
      id: 'instalar_android',
      pregunta: '¿Y en Android?',
      claves: [
        'android',
        'chrome',
        'samsung',
        'xiaomi',
        'motorola',
        'apk',
        'play store',
        'instalar',
        'instalo',
        'descargar',
        'descargo',
      ],
      respuesta: (c) =>
          'Abre $_app en **Chrome**. Cuando aparezca **Instala $_app**, '
          'acéptalo; o abre el menú ⋮ y elige **Instalar aplicación** (en '
          'algunos teléfonos dice **Agregar a la pantalla principal**).\n\n'
          'Queda como una app más.',
      acciones: [
        AccionMacias('Ver la guía de instalación', DestinoMacias.instalar),
      ],
      relacionados: ['instalar_iphone', 'notificaciones_avisos'],
    ),
    TemaMacias(
      id: 'notificaciones_avisos',
      pregunta: '¿Qué avisos me llegan?',
      claves: [
        'que avisos',
        'avisos',
        'notificacion*',
        'alertas',
        'activar notificaciones',
        'desactiv* notificaciones',
        'apag* notificaciones',
        'quit* notificaciones',
      ],
      respuesta: (c) =>
          'Solo lo importante:\n'
          '• Nuevo pedido, si vendes.\n'
          '• Tu pedido fue aceptado, rechazado, venció o se canceló.\n'
          '• Te marcaron una entrega para confirmar.\n'
          '• Mensajes del chat de tus pedidos.\n'
          '• Abrió un local nuevo en el campus.\n\n'
          'Se activan y se apagan en **Configuración > Notificaciones**.',
      relacionados: ['instalar_iphone', 'instalar_android'],
    ),
    TemaMacias(
      id: 'version',
      pregunta: '¿Qué versión tengo?',
      claves: [
        'version',
        'que version',
        'actualizacion',
        'actualizar',
        'nueva version',
        'ultima version',
        'novedades',
        'que hay de nuevo',
      ],
      respuesta: (c) =>
          'Tienes $_app **${c.version}**.\n\n'
          '${c.esWeb ? 'Las novedades llegan solas: si la usas instalada, '
                    'ciérrala y vuelve a abrirla para tener lo último.' : 'Las novedades llegan con las actualizaciones de la '
                    'tienda de aplicaciones.'}',
      acciones: [AccionMacias('Acerca de $_app', DestinoMacias.acercaDe)],
      relacionados: ['notificaciones_avisos', 'oficial'],
    ),

    // ------------------------------------------------------------- reglas
    TemaMacias(
      id: 'reglas_publicar',
      pregunta: '¿Qué no se puede publicar?',
      claves: [
        'que no se puede',
        'no se puede publicar',
        'prohibid*',
        'no permitido',
        'reglas',
        'normas',
        'filtro automatico',
      ],
      respuesta: (c) =>
          'En $_app no se permite:\n'
          '• Contenido ofensivo, sexual o discriminatorio.\n'
          '• Sustancias prohibidas.\n\n'
          'Un **filtro automático** revisa títulos, descripciones, notas de '
          'los pedidos y mensajes del chat. Lo que incumpla puede eliminarse '
          'sin aviso.',
      relacionados: ['comision', 'oficial'],
    ),
    TemaMacias(
      id: 'comision',
      pregunta: '¿$_app cobra comisión?',
      claves: [
        'comision*',
        'cobra*',
        'gratis',
        'cuesta app',
        'cuesta usar',
        'costo app',
        'pagar app',
        'cobran',
      ],
      respuesta: (c) =>
          'No. $_app **no cobra comisiones** ni procesa pagos: lo que vendes '
          'es todo tuyo. Usar la app es gratis.',
      relacionados: ['reglas_publicar', 'oficial'],
    ),
    TemaMacias(
      id: 'oficial',
      pregunta: '¿$_app es de la universidad?',
      claves: [
        'oficial',
        'de la universidad',
        'quien hizo',
        'quienes hicieron',
        'creadores',
        'quien creo',
        'dueno app',
        'duenos app',
        'quien es el dueno',
        'de quien es la app',
        'es de la upsa',
        'es oficial',
      ],
      respuesta: (c) =>
          'No es un producto oficial de la UPSA: lo hizo un equipo de '
          'estudiantes de la universidad, **hecho por estudiantes, para '
          'estudiantes**.\n\n'
          'Eso sí, solo pueden entrar cuentas con correo institucional.',
      acciones: [AccionMacias('Acerca de $_app', DestinoMacias.acercaDe)],
      relacionados: ['comision', 'quien_eres'],
    ),
    TemaMacias(
      id: 'sugerencias',
      pregunta: 'Tengo una idea para la app',
      claves: [
        'sugerencia',
        'sugerencias',
        'sugerir',
        'idea para la app',
        'tengo una idea',
        'deberian agregar',
        'deberian poner',
        'estaria bueno que',
        'me gustaria que la app',
        'agreguen',
        'feedback',
        'opinion sobre la app',
        'mejorar la app',
      ],
      respuesta: (c) =>
          '¡Buenísimo! Las ideas de quienes usan la app son las que más '
          'sirven. Mándasela al equipo por WhatsApp o por correo: la leen de '
          'verdad.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['oficial', 'comision'],
    ),

    // ------------------------------------------------------------- humano
    TemaMacias(
      id: humano,
      pregunta: 'Hablar con una persona',
      claves: [
        'persona',
        'humano',
        'asesor',
        'agente',
        'soporte',
        'hablar alguien',
        'hablar con alguien',
        'atencion cliente',
        'contactar',
        'contacto',
        'enviar correo',
        'mandar correo',
        'escribir correo',
        'reclamo',
        'queja',
        'equipo',
      ],
      respuesta: (c) =>
          '¡Claro, ${c.nombre}! Te paso con el equipo de $_app (personas de '
          'verdad). Escríbeles por WhatsApp o por correo y te responden lo '
          'antes posible.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
    ),
  ];

  // =====================================================================
  // MacIAs
  // =====================================================================
  static final _temasDeMacias = <TemaMacias>[
    TemaMacias(
      id: 'quien_eres',
      pregunta: '¿Quién es MacIAs?',
      claves: [
        'quien eres',
        'que eres',
        'macias',
        'eres bot',
        'eres ia',
        'eres real',
        'eres humano',
        'eres persona',
        'como te llamas',
        'tu nombre',
        'robot',
        'inteligencia artificial',
      ],
      respuesta: (c) =>
          'Soy **MacIAs**, el asistente de $_app. Respondo al toque, a '
          'cualquier hora: sobre la app, y también te ayudo con álgebra, '
          'cálculo integral y C++. Hago cuentas, resuelvo ecuaciones, me '
          'acuerdo de lo que me cuentas y, si estás aburrido, hasta jugamos.'
          '\n\n'
          'No soy una persona: si necesitas una, escribe **persona** y te '
          'paso el contacto.',
      relacionados: ['que_sabes', 'chiste'],
    ),
    TemaMacias(
      id: 'que_sabes',
      pregunta: '¿En qué me puedes ayudar?',
      claves: [
        'que sabes',
        'que puedes hacer',
        'en que ayudas',
        'en que me ayudas',
        'que sabes hacer',
        'para que sirves',
      ],
      respuesta: (c) =>
          'En casi todo lo de $_app: comprar, tus pedidos, publicar, tu '
          'local, tu cuenta, privacidad, instalar la app y las reglas.\n\n'
          'Para estudiar: álgebra (al estilo Baldor), cálculo integral y C++, '
          'con ejemplos. Hago cuentas, resuelvo ecuaciones, derivo, integro, '
          'factorizo, convierto unidades y saco porcentajes y promedios.\n\n'
          'Y además charlamos: me acuerdo de tus exámenes, te recuerdo cosas '
          '(**recuérdame comprar fotocopias**), te digo cuánto falta para '
          'Carnaval y jugamos un rato. Escríbeme con tus palabras o toca '
          '**menú**.',
      relacionados: ['quien_eres', 'calculadora'],
    ),
    TemaMacias(
      id: 'que_sabes_de_mi',
      pregunta: '¿Qué sabes de mí?',
      claves: [
        'que sabes de mi',
        'que recuerdas',
        'te acuerdas de mi',
        'mi memoria',
        'que sabes sobre mi',
      ],
      respuesta: _loQueSeDeTi,
      relacionados: ['quien_eres', 'que_sabes'],
    ),
    TemaMacias(
      id: 'chiste',
      pregunta: 'Cuéntame un chiste',
      claves: [
        'chiste*',
        'hazme reir',
        'algo gracioso',
        'broma',
        'otro chiste',
      ],
      respuesta: (c) => c.alguna(const [
        '¿Por qué el libro de álgebra estaba triste?\n\nPorque tenía '
            'demasiados problemas.',
        'Le pregunté a una integral cómo estaba. Me dijo: "depende de la '
            'constante".',
        '¿Qué le dijo un 0 a un 8?\n\nLindo cinturón.',
        'En C++ todo es fácil hasta que aparece un puntero. Después también, '
            'pero con segmentation fault.',
        'Mi relación con el Baldor es como la de x con una ecuación: él '
            'siempre tratando de despejarme.',
        'El WiFi de la universidad es como un límite que tiende a cero: '
            'cuanto más lo necesitas, menos hay.',
        '—Profe, ¿me puede sancionar por algo que no hice?\n—No, claro que '
            'no.\n—Qué bueno, porque no hice la tarea.',
        'Un SQL entra a un bar, se acerca a dos mesas y les pregunta: '
            '"¿Puedo unirme?"',
        '¿Cuántos programadores hacen falta para cambiar un foco? Ninguno: '
            'es un problema de hardware.',
        'Hay 10 tipos de personas: las que entienden binario y las que no.',
        '¿Qué le dijo la x a la y?\n\n—Despéjate, que te veo muy complicada.',
        '¿Por qué el ángulo recto es tan confiable? Porque siempre va '
            'derecho.',
        'El profe: "Esto es inmediato". El curso, cuarenta minutos después: '
            '"¿Inmediato para quién?"',
        'Mi código no funcionaba y no sabía por qué. Ahora funciona... y '
            'tampoco sé por qué.',
        '¿Qué le dice un bit a otro?\n\nNos vemos en el bus.',
        '—¿Ya estudiaste para el examen?\n—Sí, estudié la posibilidad de no '
            'ir.',
        '—¿Va a tomar asistencia, profe?\n—Sí.\n—Ah, entonces me quedo.',
        'Llega el surazo y medio campus saca chamarra, gorro y bufanda. La '
            'otra mitad sigue en chinelas.',
        '¿Qué le dijo una salteña a otra?\n\n—No te derrames, que nos están '
            'mirando.',
        '—¿Cuál es tu plato favorito?\n—El hondo, que entra más.',
        'Error 404: motivación para estudiar no encontrada. Reintentando en '
            '5 minutos...',
        '¿Por qué el libro de cálculo fue al psicólogo? Porque sentía que '
            'nadie lo integraba.',
        '¿Qué hace una abeja en el gimnasio?\n\nZumba.',
        '—Mamá, en la U me dijeron que soy un genio.\n—¿Quién?\n—El profe de '
            'cálculo. Creo que con sarcasmo.',
        '¿Cuál es el colmo de un matemático? Que su esposa le diga: "Tú y '
            'yo tenemos que hablar de nuestros problemas".',
        'Estudiar a las 3 de la mañana no es mala organización: es '
            'estrategia avanzada.',
        '¿Por qué los programadores confunden Halloween con Navidad? Porque '
            'OCT 31 = DEC 25.',
        'Puse "contraseña incorrecta" como contraseña. Ahora, cuando me '
            'equivoco, me la recuerda.',
        '¿Qué le dijo el 3 al 30?\n\nPara ser como yo, tienes que ser '
            'sincero.',
      ]),
      relacionados: ['chiste', 'dato_curioso'],
    ),
    TemaMacias(
      id: 'dato_curioso',
      pregunta: 'Cuéntame un dato curioso',
      claves: [
        'dato curioso',
        'datos curiosos',
        'curiosidad',
        'algo interesante',
        'cuentame algo',
        'dime algo',
        'sabias que',
        'sorprendeme',
        'dime algo que no sepa',
      ],
      respuesta: (c) => c.alguna(const [
        'El señor de la portada del Álgebra de Baldor es Al-Juarismi, un '
            'matemático persa del siglo IX. De su nombre viene la palabra '
            '"algoritmo".',
        'La palabra "álgebra" viene del árabe al-jabr, que aparece en el '
            'título de un libro de Al-Juarismi.',
        'El símbolo ∫ de la integral es una S alargada, de "summa". Lo '
            'inventó Leibniz en el siglo XVII.',
        'C++ lo creó Bjarne Stroustrup a principios de los años 80. Al '
            'comienzo se llamaba "C con clases".',
        '0,999… (con nueves infinitos) es exactamente igual a 1. No casi: '
            'igual.',
        'Hay tantos números pares como números naturales, aunque parezca '
            'que los pares son la mitad.',
        'El Álgebra de Baldor se publicó por primera vez en 1941 y todavía '
            'se usa en colegios y universidades de media Latinoamérica.',
        'Bolivia tiene dos capitales: Sucre, la constitucional, y La Paz, '
            'sede de gobierno.',
        'El Salar de Uyuni es el desierto de sal más grande del mundo. En '
            'época de lluvias se vuelve un espejo gigante.',
        'Un pulpo tiene tres corazones y sangre azul.',
        'Ada Lovelace escribió el primer programa de la historia en el siglo '
            'XIX, para una máquina que nunca se terminó de construir: la '
            'máquina analítica de Charles Babbage.',
        'Las abejas pueden aprender a reconocer caras humanas.',
        'Si doblaras una hoja de papel 42 veces, su grosor llegaría a la '
            'Luna. En la práctica, no pasarás de unos 7 dobleces.',
        'Tu corazón late unas 100 000 veces al día.',
        'La miel no se echa a perder: se encontró miel comestible en tumbas '
            'egipcias de miles de años.',
        'Un día en Venus dura más que un año en Venus: tarda más en girar '
            'sobre sí mismo que en dar la vuelta al Sol.',
        'Los flamencos son rosados por lo que comen: algas y camarones con '
            'pigmentos.',
        'Un adulto tiene 206 huesos, pero un bebé nace con unos 300 que '
            'después se van uniendo.',
        'El Salar de Uyuni es tan plano que se usa para calibrar satélites.',
        'Bolivia y Paraguay son los dos países de Sudamérica sin salida al '
            'mar.',
        'Bolivia tiene una de las reservas de litio más grandes del planeta: '
            'el metal de la batería de tu celular.',
        'Los aztecas usaban el cacao como moneda.',
        'Las jirafas tienen las mismas vértebras en el cuello que tú: '
            'siete.',
        'Un rayo es unas cinco veces más caliente que la superficie del Sol.',
        'La Gran Muralla China no se ve a simple vista desde la Luna. Es un '
            'mito.',
        'Tu cerebro pesa cerca del 2 % de tu cuerpo, pero gasta alrededor '
            'del 20 % de tu energía.',
        'Un "googol" es un 1 seguido de cien ceros. De ahí sacaron el nombre '
            'de Google.',
        'El primer mensaje entre dos computadoras de la red que dio origen a '
            'internet (1969) fue "LO": iban a escribir "LOGIN" y el sistema '
            'se colgó.',
        'Hay más formas de ordenar un mazo de 52 cartas que átomos en la '
            'Tierra. Cada vez que barajas bien, casi seguro creas un orden que '
            'nunca existió.',
        'En ciertas condiciones, el agua caliente se congela más rápido que '
            'la fría: se llama efecto Mpemba.',
        'Los tiburones existen desde antes que los árboles.',
        'La Torre Eiffel crece unos 15 centímetros en verano: el calor dilata '
            'el metal.',
        'El corazón de la ballena azul es del tamaño de un auto pequeño.',
        'La Paz tiene la red de teleféricos urbanos más grande del mundo.',
        'Jaime Escalante, profesor boliviano de matemáticas, tiene una '
            'película sobre su vida: llevó a un curso entero a aprobar cálculo '
            'avanzado en Los Ángeles.',
        'El número π ya se calculó con más de 100 billones de decimales. '
            'Para casi todo, con 3,1416 alcanza.',
        'En tu cuerpo viven unos 38 billones de bacterias: muchísimas más que '
            'las estrellas de la Vía Láctea.',
      ]),
      relacionados: ['dato_curioso', 'chiste'],
    ),
    TemaMacias(
      id: 'consejos_estudio',
      pregunta: 'Tips para estudiar mejor',
      claves: [
        'tips para estudiar',
        'consejos para estudiar',
        'tecnicas de estudio',
        'tecnica de estudio',
        'como estudiar mejor',
        'estudiar mejor',
        'pomodoro',
        'como concentrarme',
        'como memorizar',
      ],
      respuesta: (c) => tipsEstudio,
      relacionados: ['calculadora', 'chiste'],
    ),
  ];

  /// Lo que mejor funciona para estudiar. Tambien lo dice la charla.
  static const tipsEstudio =
      'Lo que mejor funciona, según los que saben:\n'
      '• **Pomodoro**: 25 minutos de estudio sin el celular, 5 de descanso.\n'
      '• **Practica, no solo leas**: haz ejercicios y explícalo en voz alta, '
      'como si le enseñaras a alguien.\n'
      '• **Repasa espaciado**: un poquito cada día rinde más que todo la '
      'noche anterior.\n'
      '• **Duerme**: lo que estudias se fija mientras duermes.\n\n'
      'Y si es álgebra, cálculo o C++, aquí te explico con ejemplos.';

  /// "¿Qué sabes de mí?": lo que la persona le conto, o como contarselo.
  static String _loQueSeDeTi(ContextoMacias c) {
    final memoria = c.memoria;
    if (memoria.vacia) {
      return 'Todavía no me contaste nada de ti. Puedes decirme cosas como '
          '**me llamo Ana**, **estudio sistemas**, **me gusta la pizza**, '
          '**tengo examen de cálculo el viernes** o **recuérdame comprar '
          'fotocopias**, y me acuerdo la próxima vez.\n\n'
          'Lo que me cuentas queda solo en este teléfono.';
    }
    const meses = [
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
    final hoy = DateTime(c.ahora.year, c.ahora.month, c.ahora.day);
    final proximos = [
      for (final e in memoria.examenes)
        if (!e.fecha.isBefore(hoy)) e,
    ];
    final datos = <String>[
      if (memoria.nombre != null) '• Te llamo **${memoria.nombre}**.',
      if (memoria.carrera != null) '• Estudias **${memoria.carrera}**.',
      if (memoria.edad != null) '• Tienes **${memoria.edad} años**.',
      if (memoria.ciudad != null) '• Eres de **${memoria.ciudad}**.',
      if (memoria.tieneCumple)
        '• Tu cumpleaños es el **${memoria.cumpleDia} de '
            '${meses[memoria.cumpleMes! - 1]}**.',
      if (memoria.gustos.isNotEmpty)
        '• Te gusta: ${memoria.gustos.join(', ')}.',
      if (memoria.disgustos.isNotEmpty)
        '• No te gusta: ${memoria.disgustos.join(', ')}.',
      for (final MapEntry(key: que, value: cual) in memoria.favoritos.entries)
        '• Tu $que favorit${_esFemenino(que) ? 'a' : 'o'}: $cual.',
      for (final e in proximos)
        '• Tienes ${e.nombre} el ${e.fecha.day} de ${meses[e.fecha.month - 1]}.',
      if (memoria.notas.isNotEmpty)
        '• Me pediste recordarte: ${memoria.notas.join('; ')}.',
      if (memoria.trabajo != null) '• Trabajas ${memoria.trabajo}.',
      for (final MapEntry(key: rol, value: nombre) in memoria.personas.entries)
        '• Tu ${_rolEscrito(rol)} se llama $nombre.',
    ];
    return 'Esto es lo que sé de ti:\n${datos.join('\n')}\n\n'
        'Queda solo en este teléfono. Para que lo olvide, escribe **olvida '
        'lo que sabes de mí**.';
  }

  static const _femeninos = {
    'comida',
    'materia',
    'cancion',
    'pelicula',
    'serie',
    'bebida',
    'banda',
    'fruta',
    'musica',
  };

  static bool _esFemenino(String categoria) => _femeninos.contains(categoria);

  static String _rolEscrito(String rol) => switch (rol) {
    'mama' => 'mamá',
    'papa' => 'papá',
    'tio' => 'tío',
    'tia' => 'tía',
    'companero' => 'compañero',
    'companera' => 'compañera',
    'hamster' => 'hámster',
    _ => rol,
  };

  // =====================================================================
  // Ya respondidas en Preguntas frecuentes: se entienden, no se ofrecen.
  // =====================================================================
  static final _temasDeAyuda = <TemaMacias>[
    TemaMacias(
      id: 'faq_pago',
      pregunta: '¿Cómo se paga?',
      enMenu: false,
      claves: [
        'pago',
        'pagar',
        'pagos',
        'pago*',
        'qr',
        'efectivo',
        'tarjeta',
        'transferencia',
        'cobrar',
      ],
      respuesta: (c) =>
          'La app no procesa pagos: cuando el vendedor acepta tu pedido, lo '
          'acuerdan en el chat (efectivo, QR o como prefieran).\n\n'
          'También está en **Preguntas frecuentes**.',
      relacionados: ['chat_vendedor', 'seguridad_encuentro'],
    ),
    TemaMacias(
      id: 'faq_cancelar',
      pregunta: '¿Cómo cancelo un pedido?',
      enMenu: false,
      claves: ['cancelar', 'cancelo', 'anular', 'ya no quiero', 'me arrepenti'],
      respuesta: (c) =>
          'Mientras esperas la respuesta del vendedor, toca **Cancelar '
          'solicitud** en la pantalla de espera. Si ya saliste de ahí, no '
          'pasa nada: si no la acepta en 15 minutos, vence sola.\n\n'
          'Si ya la aceptó, háblalo en el chat del pedido: quien vende puede '
          'cancelarlo.',
      relacionados: ['estados', 'chat_vendedor'],
    ),
    TemaMacias(
      id: 'faq_whatsapp',
      pregunta: '¿Quién ve mi número de WhatsApp?',
      enMenu: false,
      claves: [
        'quien ve mi numero',
        'mi numero',
        'mi whatsapp',
        'numero publico',
        'telefono',
        'celular',
      ],
      respuesta: (c) =>
          'Nadie ve tu número mientras navega la app. Solo si alguien deja '
          'de responder en el chat de un pedido aceptado aparece la opción de '
          'seguir por WhatsApp, y únicamente entre quien compra y quien vende '
          'ese pedido.',
      relacionados: ['perfil_publico', 'chat_sin_respuesta'],
    ),
    TemaMacias(
      id: 'faq_relanzar',
      pregunta: 'Mi publicación quedó muy abajo',
      enMenu: false,
      claves: [
        'relanzar',
        'relanzo',
        'muy abajo',
        'quedo abajo',
        'enterrada',
        'subir publicacion',
        'volver a publicar',
        'nadie ve mi publicacion',
      ],
      respuesta: (c) =>
          'Usa **Relanzar** (en tu local) o **Volver a publicar** (en tu '
          'Perfil): vuelve al inicio del catálogo sin perder sus favoritos ni '
          'su historial.',
      relacionados: ['tips_vender', 'ranking'],
    ),
    TemaMacias(
      id: 'faq_ocultar',
      pregunta: '¿Puedo ocultar algo sin borrarlo?',
      enMenu: false,
      claves: [
        'ocultar',
        'oculto',
        'ocult* public*',
        'esconder',
        'pausar',
        'sin borrar',
        'no mostrar',
      ],
      respuesta: (c) =>
          'Sí: en el menú de la publicación toca **Ocultar**. Sale del '
          'catálogo pero no se borra, y la vuelves a mostrar cuando quieras.',
      relacionados: ['editar_publicacion', 'stock'],
    ),
    TemaMacias(
      id: 'faq_necesito_local',
      pregunta: '¿Necesito abrir un local para vender?',
      enMenu: false,
      claves: [
        'necesito local',
        'necesito un local',
        'sin local',
        'obligatorio local',
        'tengo que abrir',
      ],
      respuesta: (c) =>
          'No hace falta. Publica directo desde **Publicar** y aparece en el '
          'inicio con tu nombre. El local es para quien vende con una marca y '
          'quiere su propia vitrina.',
      relacionados: ['como_publicar', 'que_es_local'],
    ),
    TemaMacias(
      id: 'faq_no_llegan',
      pregunta: 'No me llegan las notificaciones',
      enMenu: false,
      claves: [
        'no me llegan',
        'no llegan',
        'no recibo',
        'no me avisa',
        'no suena',
        'no me notifica',
      ],
      respuesta: (c) =>
          'Revisa que estén activadas en **Configuración > Notificaciones**. '
          'En iPhone solo llegan si instalaste la app en la pantalla de '
          'inicio.',
      relacionados: ['instalar_iphone', 'notificaciones_avisos'],
    ),
    TemaMacias(
      id: 'faq_reportar',
      pregunta: 'Alguien publicó algo ofensivo',
      enMenu: false,
      claves: [
        'ofensivo',
        'ofensiva',
        'algo ofensivo',
        'publico ofensivo',
        'reportar',
        'reporto',
        'denunciar',
        'denuncio',
        'report* public*',
        'denunci* public*',
        'report* producto',
        'inapropiado',
        'banderita',
      ],
      respuesta: (c) =>
          'Gracias por avisar. Abre la publicación y toca la **banderita** de '
          'arriba (**Reportar publicación**): eliges el motivo y lo revisa '
          'una persona del equipo. Reportar no la oculta al instante, así que '
          'dale un tiempito.\n\n'
          'Si es otra cosa (una persona, un mensaje), escríbenos.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['reglas_publicar', 'seguridad_encuentro'],
    ),
  ];

  // =====================================================================
  // Preguntas puntuales: se entienden si alguien las escribe, pero no se
  // ofrecen en los menus. Cada una salio de algo que alguien pregunto.
  // =====================================================================
  static final _temasSueltos = <TemaMacias>[
    TemaMacias(
      id: 'app_no_puedo_publicar',
      pregunta: 'No puedo publicar',
      enMenu: false,
      claves: [
        'no puedo publicar',
        'no me deja publicar',
        'error al publicar',
        'error publicar',
        'no se publica',
        'falla al publicar',
      ],
      respuesta: (c) =>
          'Casi siempre es una de estas:\n'
          '1. **Tu perfil está incompleto**: para publicar necesitas tu nombre '
          'real, tu carrera y tu WhatsApp.\n'
          '2. **Llegaste al límite**: 20 publicaciones nuevas por hora y 40 por '
          'día.\n'
          '3. **El filtro**: si te sale **Revisa el texto: tiene palabras que '
          'no se permiten**, cambia esa palabra.\n'
          '4. **La conexión**: revisa tu internet y prueba de nuevo.\n\n'
          'Si no es nada de eso, escríbenos con una captura.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
      ],
      relacionados: ['completar_perfil', 'limite_publicaciones'],
    ),
    TemaMacias(
      id: 'app_foto_no_sube',
      pregunta: 'Mi foto no se sube',
      enMenu: false,
      claves: [
        'foto no se sube',
        'no se sube la foto',
        'no sube la foto',
        'no puedo subir foto*',
        'no se suben las fotos',
        'foto no carga',
        'no carga la foto',
        'error foto*',
      ],
      respuesta: (c) =>
          'Prueba esto:\n'
          '1. Revisa tu conexión: las fotos son lo más pesado de subir.\n'
          '2. Intenta con otra foto (una tomada con la cámara o una captura).\n'
          '3. Cierra la app, ábrela de nuevo y vuelve a intentar.\n\n'
          'Si sigue sin subir, escríbenos con una captura y lo vemos.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
      ],
      relacionados: ['fotos', 'problemas_app'],
    ),
    TemaMacias(
      id: 'app_pedir_para_otro',
      pregunta: '¿Puedo pedir para otra persona?',
      enMenu: false,
      claves: [
        'para otra persona',
        'para un amigo',
        'para una amiga',
        'para alguien mas',
        'de regalo',
        'regalar',
      ],
      respuesta: (c) =>
          'Sí. El pedido sale a tu nombre: en **¿Dónde te lo entregan?** pon la '
          'zona y una referencia de dónde va a estar esa persona, y avísale al '
          'vendedor por el chat del pedido.',
      relacionados: ['como_comprar', 'punto_encuentro'],
    ),
    TemaMacias(
      id: 'app_problema_pedido',
      pregunta: 'Tuve un problema con un pedido',
      enMenu: false,
      claves: [
        'estafa*',
        'me estafo',
        'fraude',
        'robo',
        'me robaron',
        'robaron',
        'no me entrego',
        'no me entregaron',
        'nunca llego',
        'no llego mi pedido',
        'pague y no',
        'me cobro de mas',
        'me cobraron de mas',
        'llego mal',
        'vino mal',
        'en mal estado',
        'devolucion',
        'devolver pedido',
        'devolver producto',
        'devolver plata',
        'devuelvan',
        'reembolso',
        'cobraron por error',
        'cobro por error',
      ],
      respuesta: (c) =>
          'Pucha, lo siento, ${c.nombre}. Así lo vemos:\n'
          '1. Si el pedido sigue abierto, háblalo por el chat del pedido: '
          'queda registrado.\n'
          '2. Si no lo recibiste, **no confirmes la entrega**.\n'
          '3. Escríbenos con el nombre de quien vendió y qué pasó: lo '
          'revisamos.\n\n'
          'Si fue un robo dentro del campus, avisa también a seguridad de la '
          'universidad.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['seguridad_encuentro', 'confirmar_entrega'],
    ),
    TemaMacias(
      id: 'app_bloquear',
      pregunta: 'Alguien me molesta',
      enMenu: false,
      claves: [
        'bloquear',
        'bloqueo',
        'bloquearlo',
        'bloquearla',
        'me acosa',
        'me acosan',
        'acosa*',
        'acoso',
        'bloqueo a',
        'spam',
        'mensajes raros',
        'me manda cosas raras',
        'me escribe cosas raras',
        'me molesta un vendedor',
      ],
      respuesta: (c) =>
          'Todavía no hay un botón para bloquear. Si alguien te molesta o te '
          'manda cosas raras, no le sigas el juego, no aceptes sus pedidos y '
          'escríbenos con su nombre: lo revisamos.\n\n'
          'Si es una publicación (spam, repetida u ofensiva), repórtala con '
          'la **banderita** de arriba.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['seguridad_encuentro', 'reglas_publicar'],
    ),
    TemaMacias(
      id: 'app_resenas',
      pregunta: '¿Puedo calificar a un vendedor?',
      enMenu: false,
      claves: [
        'resena*',
        'calificar',
        'califico',
        'calificacion vendedor',
        'puntuar',
        'estrellas',
        'valorar',
        'opinion vendedor',
        'comentario vendedor',
      ],
      respuesta: (c) =>
          'Por ahora la app no tiene calificaciones ni reseñas. Si te fue '
          'bien, lo mejor es volver a pedirle (y contarle a tus amigos). Si te '
          'fue mal, cuéntanos qué pasó y lo revisamos.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
      ],
      relacionados: ['repetir_pedido', 'sugerencias'],
    ),
    TemaMacias(
      id: 'app_delivery',
      pregunta: '¿Hay delivery?',
      enMenu: false,
      claves: [
        'delivery',
        'domicilio',
        'envio*',
        'mandan a mi casa',
        'llevan a mi casa',
        'a mi casa',
        'fuera del campus',
        'costo de entrega',
        'costo entrega',
        'entrega gratis',
      ],
      respuesta: (c) =>
          'Las entregas son dentro del campus: en el carrito eliges tu zona y '
          'una referencia (mesa, piso o puerta) y lo coordinan por el chat del '
          'pedido. Algunos locales cobran un **costo de entrega**: lo ves en su '
          'página antes de pedir.\n\n'
          'Fuera del campus depende de cada vendedor: pregúntale por el chat.',
      relacionados: ['punto_encuentro', 'zonas'],
    ),
    TemaMacias(
      id: 'app_descuentos',
      pregunta: '¿Hay descuentos?',
      enMenu: false,
      claves: [
        'descuento*',
        'oferta*',
        'promo',
        'promos',
        'promocion',
        'promociones',
        'cupon*',
        'rebaja*',
        'mas barato',
        'precio especial',
      ],
      respuesta: (c) =>
          'La app no tiene cupones propios: cada vendedor pone sus precios. Si '
          'compras varias cosas, pregúntale por el chat si te hace precio; '
          'muchos aceptan.',
      relacionados: ['buscar', 'chat_vendedor'],
    ),
    TemaMacias(
      id: 'app_permitido',
      pregunta: '¿Qué puedo vender y qué no?',
      enMenu: false,
      claves: [
        'puedo vender',
        'se puede vender',
        'permiten vender',
        'permitido vender',
        'esta permitido',
        'permiso para vender',
        'necesito permiso',
        'comida casera',
        'dar clases',
        'puedo dar clases',
        'clases particulares',
        'vender servicios',
        'ofrecer servicios',
        'ropa usada',
        'cosas usadas',
        'segunda mano',
      ],
      respuesta: (c) =>
          'Casi todo lo legal se puede: comida casera, ropa nueva o usada, '
          'apuntes, tecnología, servicios… Y para publicar no necesitas ningún '
          'permiso, solo tu cuenta.\n\n'
          'Lo que **no**: alcohol, drogas, armas y cualquier cosa prohibida, ni '
          'contenido ofensivo o sexual. Si vendes comida, cuida la higiene y '
          'escribe bien qué lleva.',
      relacionados: ['ideas_vender', 'reglas_publicar'],
    ),
    TemaMacias(
      id: 'app_prohibido',
      pregunta: '¿Puedo vender alcohol?',
      enMenu: false,
      claves: [
        'vender alcohol',
        'puedo vender alcohol',
        'se puede vender alcohol',
        'vender cerveza',
        'puedo vender cerveza',
        'se puede vender cerveza',
        'puedo vender trago',
        'puedo vender licor',
        'puedo vender armas',
        'vender trago',
        'vender tragos',
        'vender licor',
        'vender singani',
        'bebidas alcoholicas',
        'vender armas',
        'vender un arma',
      ],
      respuesta: (c) =>
          'No: alcohol, drogas y armas no se pueden vender en la app, igual '
          'que cualquier otra cosa prohibida. Si ves que alguien lo hace, '
          'repórtalo con la **banderita** de la publicación.',
      relacionados: ['reglas_publicar', 'ideas_vender'],
    ),
    TemaMacias(
      id: 'app_no_aparece',
      pregunta: 'Mi publicación no aparece',
      enMenu: false,
      claves: [
        'aparec* public*',
        'aparec* producto',
        'no veo mi producto',
        'no sale mi public*',
        'no veo mi public*',
        'no se ve mi public*',
        'donde esta mi public*',
        'tarda* public*',
        'demora* public*',
        'desaparecio public*',
      ],
      respuesta: (c) =>
          'Aparece al toque: apenas tocas **Publicar ahora** ya está en el '
          'inicio, y la lista se actualiza sola. Si no la ves:\n'
          '1. Revisa en tu **Perfil** que no esté **oculta**.\n'
          '2. Si al publicar te salió **Revisa el texto: tiene palabras que no '
          'se permiten**, el filtro la frenó: cambia esa palabra y prueba de '
          'nuevo.\n'
          '3. Si sigue sin aparecer, cierra la app, ábrela otra vez, y si '
          'nada, escríbenos.',
      relacionados: ['editar_publicacion', 'reglas_publicar'],
    ),
    TemaMacias(
      id: 'app_borre_sin_querer',
      pregunta: 'Borré algo sin querer',
      enMenu: false,
      claves: [
        'sin querer',
        'por error',
        'por accidente',
        'borr* sin querer',
        'elimin* sin querer',
        'borr* por error',
        'elimin* por error',
        'deshacer',
        'recuper* public*',
      ],
      respuesta: (c) =>
          'Pucha: una publicación eliminada no se puede recuperar. Toca '
          'subirla de nuevo (y ojo, eso usa cupo).\n\n'
          'Para la próxima, si no estás seguro, usa **Ocultar**: sale del '
          'catálogo sin borrarse.',
      relacionados: ['editar_publicacion', 'limite_publicaciones'],
    ),
    TemaMacias(
      id: 'app_tema_oscuro',
      pregunta: '¿Hay modo oscuro?',
      enMenu: false,
      claves: [
        'modo oscuro',
        'tema oscuro',
        'dark mode',
        'modo noche',
        'modo nocturno',
        'fondo negro',
        'fondo oscuro',
      ],
      respuesta: (c) =>
          'Por ahora no: la app va solo en tema claro. Si te gustaría el '
          'oscuro, cuéntaselo al equipo, que las ideas se leen de verdad.',
      relacionados: ['sugerencias'],
    ),
    TemaMacias(
      id: 'app_idioma',
      pregunta: '¿Está en otros idiomas?',
      enMenu: false,
      claves: [
        'cambi* idioma',
        'idioma app',
        'idiomas app',
        'otro idioma',
        'otros idiomas',
        'app ingles',
        'app espanol',
        'poner en ingles',
        'disponible ingles',
        'version en ingles',
      ],
      respuesta: (c) =>
          'Por ahora la app está solo en español. Y yo igual: entiendo un '
          'poquito de inglés, pero respondo en español.',
      relacionados: ['sugerencias'],
    ),
    TemaMacias(
      id: 'app_peso',
      pregunta: '¿Cuánto espacio ocupa?',
      enMenu: false,
      claves: [
        'pesa app',
        'peso app',
        'app pesada',
        'espacio app',
        'ocupa app',
        'megas app',
        'almacenamiento',
      ],
      respuesta: (c) => c.esWeb
          ? 'Casi nada: como la instalas desde el navegador, no es una '
                'descarga pesada como las de la tienda. Si tu teléfono anda '
                'lleno, lo que más ocupa suelen ser las fotos y los videos.'
          : 'Es liviana. Si tu teléfono anda lleno, lo que más ocupa suelen '
                'ser las fotos y los videos.',
      relacionados: ['problemas_app', 'version'],
    ),
    TemaMacias(
      id: 'app_sin_internet',
      pregunta: '¿Funciona sin internet?',
      enMenu: false,
      claves: [
        'sin internet',
        'necesito internet',
        'necesita internet',
        'internet para usar',
        'sin conexion',
        'offline',
        'sin datos',
        'sin wifi',
        'modo avion',
      ],
      respuesta: (c) =>
          'Para comprar, vender y chatear necesitas internet: todo pasa en '
          'vivo. Yo sí te respondo sin conexión, porque todo lo que sé está en '
          'tu teléfono.',
      relacionados: ['problemas_app'],
    ),
    TemaMacias(
      id: 'app_usuarios',
      pregunta: '¿Cuánta gente usa la app?',
      enMenu: false,
      claves: [
        'cuantos usuarios',
        'cuantas personas usan',
        'cuanta gente usa',
        'quien usa la app',
        'quienes usan',
        'quien mas usa',
        'cuantos vendedores',
        'cuantas personas venden',
        'cuantos venden',
      ],
      respuesta: (c) =>
          'Ese número no lo tengo: no veo la base de datos. Lo que sí sé es '
          'quiénes la usan: solo estudiantes de la UPSA con correo '
          'institucional. Para ver quién vende, date una vuelta por '
          '**Locales** y el inicio.',
      relacionados: ['que_es_app', 'verificada'],
    ),
    TemaMacias(
      id: 'app_como_se_hizo',
      pregunta: '¿Con qué está hecha la app?',
      enMenu: false,
      claves: [
        'esta hecha',
        'en que esta hecha',
        'hecha con',
        'con que la hicieron',
        'con que hicieron',
        'como hicieron app',
        'programaron app',
        'programaron la app',
        'que tecnologia',
        'hacer una app',
        'hago una app',
        'crear una app',
        'creo una app',
        'app como esta',
        'cuanto cuesta hacer una app',
      ],
      respuesta: (c) =>
          'Está hecha con **Flutter**, el framework de Google que usa el '
          'lenguaje **Dart** (yo también estoy hecho en Dart), y los datos '
          'viven en un servidor en la nube.\n\n'
          'Si quieres hacer una así: aprende lo básico de programación (el C++ '
          'de la U ya te sirve), después Dart y Flutter con la documentación '
          'oficial, y empieza por una app chiquita. Publicarla en Play Store '
          'cuesta un pago único de 25 dólares; en la App Store, 99 dólares al '
          'año. Como página web instalable, desde el navegador, sale gratis.',
      relacionados: ['oficial', 'sugerencias'],
    ),
    TemaMacias(
      id: 'app_ganancias',
      pregunta: '¿Cómo gana plata la app?',
      enMenu: false,
      claves: [
        'cuanto ganan',
        'como ganan',
        'como gana',
        'gana dinero',
        'gana plata',
        'ganan dinero',
        'ganan plata',
        'ganan con la app',
        'de que viven',
        'como se financia',
        'modelo de negocio',
      ],
      respuesta: (c) =>
          'Usar la app es gratis y no cobramos comisión por lo que vendes. De '
          'las cuentas del equipo no sé nada (no me pasan esa info): si te '
          'interesa, pregúntales directo.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
      ],
      relacionados: ['comision', 'oficial'],
    ),
    TemaMacias(
      id: 'app_equipo',
      pregunta: '¿Puedo trabajar con ustedes?',
      enMenu: false,
      claves: [
        'trabajar con ustedes',
        'trabajo con ustedes',
        'trabajar en u market',
        'trabajar en umarket',
        'trabajar en la app',
        'unirme al equipo',
        'ser parte del equipo',
        'formar parte del equipo',
        'estan contratando',
        'contratan',
        'buscan gente',
        'colaborar con ustedes',
      ],
      respuesta: (c) =>
          '¡Qué buena onda! Escríbele al equipo y cuéntales qué sabes hacer: '
          'diseño, programación, redes, lo que sea. Son estudiantes como tú.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['oficial', 'sugerencias'],
    ),
  ];
}
