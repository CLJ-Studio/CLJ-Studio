/// Quien dice cada cosa en la conversacion con MacIAs.
enum AutorMensaje { macias, persona }

/// A que parte de la app puede llevar un boton de MacIAs.
///
/// Son destinos y no pantallas: la pantalla del chat decide como abrir cada
/// uno. Asi el cerebro de MacIAs no depende de Flutter y se prueba solo.
///
/// No hay destino hacia Ayuda ni hacia el propio chat a proposito: MacIAs se
/// abre desde Ayuda, y llevar de vuelta ahi armaria un bucle de pantallas.
enum DestinoMacias {
  carrito,
  pedidos,
  chats,
  favoritos,
  misPublicaciones,
  editarPerfil,
  privacidad,
  instalar,
  acercaDe,
  whatsappSoporte,
  correoSoporte,
}

/// Un boton dentro de una respuesta, como "Abrir mis pedidos".
class AccionMacias {
  const AccionMacias(this.etiqueta, this.destino);

  factory AccionMacias.desdeJson(Map<String, dynamic> json) => AccionMacias(
    json['etiqueta'] as String,
    DestinoMacias.values.byName(json['destino'] as String),
  );

  final String etiqueta;
  final DestinoMacias destino;

  Map<String, dynamic> aJson() => {
    'etiqueta': etiqueta,
    'destino': destino.name,
  };
}

/// Algo que se puede elegir tocandolo o escribiendo su numero.
class OpcionMacias {
  const OpcionMacias({required this.id, required this.texto});

  factory OpcionMacias.desdeJson(Map<String, dynamic> json) =>
      OpcionMacias(id: json['id'] as String, texto: json['texto'] as String);

  /// Que se pide al elegirla: `s:` abre una seccion, `t:` responde un tema y
  /// `o:` es una orden de la conversacion (menu, volver...).
  final String id;
  final String texto;

  Map<String, dynamic> aJson() => {'id': id, 'texto': texto};

  @override
  bool operator ==(Object other) =>
      other is OpcionMacias && other.id == id && other.texto == texto;

  @override
  int get hashCode => Object.hash(id, texto);
}

/// Una burbuja que MacIAs quiere decir, antes de tener hora ni lugar.
///
/// El texto admite **negritas**, `codigo` y bloques de codigo entre tres
/// acentos graves, como en WhatsApp y en cualquier editor.
class BurbujaMacias {
  const BurbujaMacias(
    this.texto, {
    this.opciones = const [],
    this.acciones = const [],
  });

  final String texto;

  /// Lista numerada dentro de la burbuja. Escribir su numero la elige.
  final List<OpcionMacias> opciones;

  final List<AccionMacias> acciones;
}

/// Todo lo que MacIAs contesta a un mensaje.
class RespuestaMacias {
  const RespuestaMacias(
    this.burbujas, {
    this.sugerencias = const [],
    this.temaId,
  });

  final List<BurbujaMacias> burbujas;

  /// El tema que se respondio, si fue uno. Sirve para saber que entendio
  /// MacIAs sin leer el texto.
  final String? temaId;

  /// Atajos que quedan sobre el campo de escribir hasta la proxima respuesta.
  final List<OpcionMacias> sugerencias;
}

/// Una burbuja ya dicha: con autor, hora y un numero que la identifica.
class MensajeMacias {
  MensajeMacias({
    required this.id,
    required this.autor,
    required this.texto,
    this.opciones = const [],
    this.acciones = const [],
    DateTime? hora,
  }) : hora = hora ?? DateTime.now();

  factory MensajeMacias.desdeJson(Map<String, dynamic> json) => MensajeMacias(
    id: json['id'] as int,
    autor: AutorMensaje.values.byName(json['autor'] as String),
    texto: json['texto'] as String,
    opciones: [
      for (final opcion in (json['opciones'] as List? ?? const []))
        OpcionMacias.desdeJson(opcion as Map<String, dynamic>),
    ],
    acciones: [
      for (final accion in (json['acciones'] as List? ?? const []))
        AccionMacias.desdeJson(accion as Map<String, dynamic>),
    ],
    hora: DateTime.fromMillisecondsSinceEpoch(json['hora'] as int),
  );

  final int id;
  final AutorMensaje autor;
  final String texto;
  final List<OpcionMacias> opciones;
  final List<AccionMacias> acciones;
  final DateTime hora;

  bool get esDeMacias => autor == AutorMensaje.macias;

  /// "14:05".
  String get horaTexto =>
      '${hora.hour.toString().padLeft(2, '0')}:'
      '${hora.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> aJson() => {
    'id': id,
    'autor': autor.name,
    'texto': texto,
    if (opciones.isNotEmpty) 'opciones': [for (final o in opciones) o.aJson()],
    if (acciones.isNotEmpty) 'acciones': [for (final a in acciones) a.aJson()],
    'hora': hora.millisecondsSinceEpoch,
  };
}
