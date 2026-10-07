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

  bool get esDeNoche => ahora.hour >= 22 || ahora.hour < 6;

  String get saludoDelMomento => ahora.hour < 12
      ? 'Buenos días'
      : ahora.hour < 19
      ? 'Buenas tardes'
      : 'Buenas noches';

  /// Elige una de varias frases, la misma durante toda esta respuesta.
  String alguna(List<String> frases) => frases[sorteo % frases.length];
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
  /// y `o:` una orden de la conversacion, como prender el modo meme.
  final List<String> temas;

  /// Si alguien escribe exactamente esto ("pedidos", "mi cuenta"), se abre
  /// la seccion entera en vez de adivinar una pregunta.
  final List<String> claves;

  /// La seccion de la que cuelga, para "volver" un nivel y no al principio.
  final String? padre;

  /// De que trata: elige el tipo de broma del modo meme.
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
  static const ordenMeme = 'o:meme';

  static const secciones = <SeccionMacias>[
    SeccionMacias(
      id: 'compras',
      titulo: 'Comprar paso a paso',
      intro: 'Sobre comprar en $_app:',
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
      intro: 'Sobre tus pedidos y las entregas:',
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
      intro: 'Sobre publicar lo que vendes:',
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
      intro: 'Sobre tener tu propio local:',
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
      intro: 'Para vender más:',
      temas: ['tips_vender', 'ranking', 'visitas', 'ideas_vender'],
      claves: ['vender mas', 'consejos', 'tips'],
    ),
    SeccionMacias(
      id: 'ubicacion',
      titulo: 'Ubicación y encuentros',
      intro: 'Sobre ubicaciones y encuentros en el campus:',
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
      intro: 'Sobre privacidad y seguridad:',
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
      titulo: 'Instalar la app y avisos',
      intro: 'Sobre instalar la app y los avisos:',
      temas: [
        'instalar_iphone',
        'instalar_android',
        'notificaciones_avisos',
        'version',
      ],
      claves: ['instalar', 'app', 'aplicacion', 'notificaciones', 'avisos'],
    ),
    SeccionMacias(
      id: 'reglas',
      titulo: 'Reglas de la comunidad',
      intro: 'Sobre las reglas de la comunidad:',
      temas: ['reglas_publicar', 'comision', 'oficial'],
      claves: ['reglas', 'normas'],
    ),
    SeccionMacias(
      id: 'extra',
      titulo: 'Materias, calculadora y más',
      intro:
          'Además de la app, te ayudo a estudiar. Elige una materia, '
          'prueba la calculadora o cámbiame el humor:',
      temas: [
        's:algebra',
        's:calculo',
        's:cpp',
        'calculadora',
        's:macias',
        ordenMeme,
      ],
      claves: ['materias', 'estudiar', 'estudio', 'mas', 'extra'],
      area: 'general',
    ),
    SeccionMacias(
      id: 'algebra',
      titulo: 'Álgebra',
      intro:
          'Álgebra, con el orden de siempre (el del Baldor). '
          'Elige un tema:',
      temas: ConocimientoEstudio.algebra,
      claves: ['algebra', 'baldor', 'el baldor'],
      padre: 'extra',
      area: 'algebra',
    ),
    SeccionMacias(
      id: 'calculo',
      titulo: 'Cálculo integral',
      intro: 'Cálculo integral. Elige un tema:',
      temas: ConocimientoEstudio.calculo,
      claves: ['calculo', 'calculo integral', 'calculo 2', 'calculo ii'],
      padre: 'extra',
      area: 'calculo',
    ),
    SeccionMacias(
      id: 'cpp',
      titulo: 'Programación en C++',
      intro: 'Programación en C++. Elige un tema:',
      temas: ConocimientoEstudio.cpp,
      claves: ['c', 'cpp', 'c plus plus', 'programacion', 'programar'],
      padre: 'extra',
      area: 'cpp',
    ),
    SeccionMacias(
      id: 'macias',
      titulo: 'Sobre MacIAs',
      intro: 'Sobre mí:',
      temas: [
        'quien_eres',
        'que_sabes',
        'que_sabes_de_mi',
        'chiste',
        'dato_curioso',
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
      (temaId.startsWith('faq_') ? 'app' : 'general');

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
          'Así:\n'
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
          'Tu solicitud espera **15 minutos**. Si en ese tiempo no la '
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
          'Sí. En **Mis pedidos** busca uno que ya hiciste y toca '
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
        'limite',
        'maximo',
        'tope',
        'cupo',
        'no me deja publicar',
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
          'No se perdió: la app guarda lo que ibas escribiendo. La próxima '
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
        'bloque*',
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
      ],
      respuesta: (c) =>
          'Con tu **número de registro** de la UPSA (8 dígitos). Te llega un '
          '**código** a tu correo **@estudiantes.upsa.edu.bo**: lo escribes y '
          'listo.\n\n'
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
        'eliminar cuenta',
        'eliminar mi cuenta',
        'dar baja',
        'darme baja',
        'borrar mis datos',
        'eliminar mis datos',
      ],
      respuesta: (c) =>
          'Entendido, ${c.nombre}. Escríbenos y borramos tu cuenta junto con '
          'todo lo asociado. Aquí tienes el contacto:',
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
        'segura',
        'seguridad',
        'confianza',
        'peligro',
        'cuidado',
        'robo',
        'fraude',
        'estafa*',
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
      ],
      respuesta: (c) =>
          'Solo lo importante:\n'
          '• Nuevo pedido, si vendes.\n'
          '• Tu pedido fue aceptado, rechazado, venció o se canceló.\n'
          '• Te marcaron una entrega para confirmar.\n'
          '• Mensajes del chat de tus pedidos.\n'
          '• Abrió un local nuevo en el campus.\n\n'
          'Se activan en **Configuración > Notificaciones**.',
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
      ],
      respuesta: (c) =>
          'No es un producto oficial de la UPSA: lo hizo un equipo de '
          'estudiantes de la universidad, **hecho por estudiantes, para '
          'estudiantes**.\n\n'
          'Eso sí, solo pueden entrar cuentas con correo institucional.',
      acciones: [AccionMacias('Acerca de $_app', DestinoMacias.acercaDe)],
      relacionados: ['comision', 'quien_eres'],
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
          'Claro, ${c.nombre}. Te paso con el equipo de $_app: escríbenos '
          'por WhatsApp o por correo y te respondemos lo antes posible.',
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
          'Soy **MacIAs**, el asistente virtual de $_app. Respondo al '
          'instante, a cualquier hora: sobre la app, y también sobre álgebra, '
          'cálculo integral y C++. Además hago cuentas y resuelvo '
          'ecuaciones.\n\n'
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
        'que haces',
      ],
      respuesta: (c) =>
          'En casi todo lo de $_app: comprar, tus pedidos, publicar, tu '
          'local, tu cuenta, privacidad, instalar la app y las reglas.\n\n'
          'Y para estudiar: álgebra (al estilo Baldor), cálculo integral y '
          'C++, con ejemplos. Hago cuentas (**calcula 3*(4+5)**) y resuelvo '
          'ecuaciones de primer y segundo grado (**resuelve x^2 - 5x + 6 = '
          '0**).\n\n'
          'Escríbeme con tus palabras o escribe **menú**.',
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
        'aburrido',
        'aburrida',
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
      ]),
      relacionados: ['dato_curioso', 'chiste'],
    ),
  ];

  /// "¿Qué sabes de mí?": lo que la persona le conto, o como contarselo.
  static String _loQueSeDeTi(ContextoMacias c) {
    final memoria = c.memoria;
    if (memoria.vacia) {
      return 'Todavía no me contaste nada de ti. Puedes decirme cosas como '
          '**me llamo Ana**, **estudio sistemas** o **me gusta la pizza**, y '
          'me acuerdo la próxima vez.\n\n'
          'Lo que me cuentas queda solo en este teléfono.';
    }
    final datos = <String>[
      if (memoria.nombre != null) '• Te llamo **${memoria.nombre}**.',
      if (memoria.carrera != null) '• Estudias **${memoria.carrera}**.',
      if (memoria.gustos.isNotEmpty)
        '• Te gusta: ${memoria.gustos.join(', ')}.',
      if (memoria.disgustos.isNotEmpty)
        '• No te gusta: ${memoria.disgustos.join(', ')}.',
    ];
    return 'Esto es lo que sé de ti:\n${datos.join('\n')}\n\n'
        'Queda solo en este teléfono. Para que lo olvide, escribe **olvida '
        'lo que sabes de mí**.';
  }

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
        'inapropiado',
        'acoso',
        'me estafaron',
      ],
      respuesta: (c) =>
          'Gracias por avisar. Escríbenos con el nombre de la publicación y '
          'la revisamos. Hay un filtro automático, pero no atrapa todo.',
      acciones: [
        AccionMacias('Escribir por WhatsApp', DestinoMacias.whatsappSoporte),
        AccionMacias('Enviar un correo', DestinoMacias.correoSoporte),
      ],
      relacionados: ['reglas_publicar', 'seguridad_encuentro'],
    ),
  ];
}
