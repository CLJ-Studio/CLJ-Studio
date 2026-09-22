import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/imagenes/foto_red.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../datos/repositorio_chat_pedido.dart';
import '../datos/repositorio_pedidos.dart';
import '../modelos/mensaje_pedido.dart';

/// Conversación de un pedido.
///
/// Se entra desde el pedido y solo mientras siga vivo. No hay lista de chats
/// ni forma de escribirle a alguien porque sí: el hilo existe porque hay una
/// venta en curso, y se cierra cuando esa venta termina.
class PantallaChatPedido extends StatefulWidget {
  const PantallaChatPedido({
    required this.pedidoId,
    required this.contraparte,
    this.fotoUrl,
    super.key,
  });

  final String pedidoId;

  /// Nombre de la otra persona, para el encabezado.
  final String contraparte;

  /// Su foto de perfil, si la bandeja la trae. Sin ella van las iniciales.
  final String? fotoUrl;

  @override
  State<PantallaChatPedido> createState() => _PantallaChatPedidoState();
}

class _PantallaChatPedidoState extends State<PantallaChatPedido> {
  static const _repositorio = RepositorioChatPedido();
  static const _pedidos = RepositorioPedidos();

  /// Cuanto se espera antes de ofrecer WhatsApp.
  ///
  /// El chat es el camino normal y el telefono el ultimo recurso, asi que la
  /// salida no puede estar ahi desde el principio: si esta, se usa siempre y
  /// la conversacion vuelve a irse de la aplicacion. Pero tampoco puede no
  /// estar: en iPhone las notificaciones solo llegan con la aplicacion
  /// instalada en la pantalla de inicio, o sea que la otra persona puede no
  /// haberse enterado de nada.
  static const _esperaAntesDeWhatsapp = Duration(minutes: 2);

  late final Stream<List<MensajePedido>> _mensajes = _repositorio.escuchar(
    widget.pedidoId,
  );
  final _campo = TextEditingController();
  final _foco = FocusNode();
  final _desplazamiento = ScrollController();

  bool _enviando = false;
  bool _abriendoWhatsapp = false;
  int _cuantosHabia = 0;

  /// Dónde quedaron en encontrarse. Es lo que se está coordinando, así que
  /// tenerlo a la vista ahorra la mitad de los mensajes.
  String? _puntoEntrega;

  /// Si lo ultimo que se dijo es mio y ya lleva rato sin respuesta.
  ///
  /// Se recalcula en cada emision del hilo, que llega cada pocos segundos por
  /// el sondeo de respaldo: no hace falta un temporizador aparte.
  bool _esperaLarga(List<MensajePedido> mensajes) {
    if (mensajes.isEmpty) return false;
    final ultimo = mensajes.last;
    if (!ultimo.mio) return false;
    return DateTime.now().difference(ultimo.creadoEn) > _esperaAntesDeWhatsapp;
  }

  Future<void> _abrirWhatsapp() async {
    setState(() => _abriendoWhatsapp = true);
    try {
      final contacto = await _pedidos.obtenerContacto(widget.pedidoId);
      if (!await launchUrl(
        Uri.parse(contacto.enlace),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('No se pudo abrir WhatsApp');
      }
    } catch (_) {
      if (mounted) _avisar('No se pudo abrir WhatsApp.');
    } finally {
      if (mounted) setState(() => _abriendoWhatsapp = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Entrar ya cuenta como haber visto lo que llegó antes.
    _repositorio.marcarLeidos(widget.pedidoId).catchError((_) {});
    _cargarPuntoEntrega();
  }

  Future<void> _cargarPuntoEntrega() async {
    try {
      final pedido = await _pedidos.obtener(widget.pedidoId);
      if (mounted && pedido?.puntoEncuentro != null) {
        setState(() => _puntoEntrega = pedido!.puntoEncuentro);
      }
    } catch (_) {
      // Sin punto la conversación funciona igual: es un dato de apoyo.
    }
  }

  @override
  void dispose() {
    _campo.dispose();
    _foco.dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  /// Baja del todo cuando llega algo nuevo.
  ///
  /// Se hace tras pintar y no durante: en ese momento la lista todavía no
  /// tiene la altura del mensaje recién añadido, y el salto quedaría corto.
  void _irAlFinal({bool animado = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_desplazamiento.hasClients) return;
      final fondo = _desplazamiento.position.maxScrollExtent;
      if (animado) {
        _desplazamiento.animateTo(
          fondo,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      } else {
        _desplazamiento.jumpTo(fondo);
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _campo.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    try {
      await _repositorio.enviar(widget.pedidoId, texto);
      _campo.clear();
      // Sin esto hay que volver a tocar el campo para escribir otra vez: en
      // una conversacion se manda una linea detras de otra, y perder el
      // teclado en cada envio la corta entera.
      if (mounted) _foco.requestFocus();
      _irAlFinal();
    } catch (error) {
      if (mounted) _avisar(_mensajeDeError(error));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _mensajeDeError(Object error) {
    final texto = error.toString();
    if (texto.contains('CONTENIDO_NO_PERMITIDO')) {
      return 'Ese mensaje tiene palabras que no se permiten.';
    }
    if (texto.contains('CHAT_CERRADO')) {
      return 'El pedido ya terminó. La conversación se cerró.';
    }
    if (texto.contains('MENSAJE_MUY_LARGO')) {
      return 'El mensaje es demasiado largo.';
    }
    return 'No se pudo enviar. Intenta de nuevo.';
  }

  void _avisar(String texto) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
    // El fondo de la conversacion, distinto del de la cabecera a proposito.
    backgroundColor: _ColoresChat.fondo(context),
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: _ColoresChat.cabecera(context),
      titleSpacing: 0,
      // La cabecera se apoyaba en el mismo color que los mensajes y no habia
      // linea entre una cosa y otra: el nombre de la otra persona parecia el
      // primer mensaje del hilo. Ahora tiene su propia superficie, su foto y
      // una raya fina que marca donde empieza la conversacion.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _ColoresChat.separador(context)),
      ),
      title: Row(
        children: [
          _AvatarContraparte(
            nombre: widget.contraparte,
            fotoUrl: widget.fotoUrl,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.contraparte,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'Sobre tu pedido',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    ),
    // Un solo StreamBuilder para todo el cuerpo. Con dos sobre el mismo
    // stream, el segundo lo encontraria ya escuchado y la pantalla reventaria
    // al abrirse: `escuchar()` no emite en difusion, y no tiene por que.
    body: StreamBuilder<List<MensajePedido>>(
      stream: _mensajes,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _ChatCerrado();
        if (!snapshot.hasData) return const Center(child: IndicadorCarga());

        final mensajes = snapshot.data!;
        if (mensajes.length != _cuantosHabia) {
          final primeraCarga = _cuantosHabia == 0;
          _cuantosHabia = mensajes.length;
          _irAlFinal(animado: !primeraCarga);
          // Lo que llega con la pantalla abierta ya esta visto.
          _repositorio.marcarLeidos(widget.pedidoId).catchError((_) {});
        }

        return Column(
          children: [
            if (_puntoEntrega case final punto?) _PuntoEntrega(punto: punto),
            Expanded(
              child: mensajes.isEmpty
                  ? _ChatVacio(contraparte: widget.contraparte)
                  : ListView.builder(
                      controller: _desplazamiento,
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                      itemCount: mensajes.length,
                      itemBuilder: (_, indice) => _Burbuja(
                        mensaje: mensajes[indice],
                        anterior: indice == 0 ? null : mensajes[indice - 1],
                      ),
                    ),
            ),
            if (_esperaLarga(mensajes))
              _RespaldoWhatsapp(
                contraparte: widget.contraparte,
                ocupado: _abriendoWhatsapp,
                alPresionar: _abrirWhatsapp,
              ),
            _Redaccion(
              campo: _campo,
              foco: _foco,
              enviando: _enviando,
              alEnviar: _enviar,
            ),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Burbuja
// ---------------------------------------------------------------------------
/// Los cuatro colores del chat, juntos porque solo tienen sentido entre ellos.
///
/// En tema oscuro las dos burbujas eran grafito y el fondo tambien: la
/// conversacion entera era un solo bloque del mismo color y no se distinguia
/// quien decia que. Lo que importa aqui no es cada color por separado, sino
/// que los cuatro se separen entre si.
abstract final class _ColoresChat {
  static bool _oscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Detras de los mensajes. Mas apagado que la cabecera.
  static Color fondo(BuildContext context) => _oscuro(context)
      ? const Color(0xFF383737)
      : ConfiguracionTema.cremaSuperficie;

  /// La barra con el perfil, un escalon por encima del fondo.
  static Color cabecera(BuildContext context) =>
      _oscuro(context) ? ConfiguracionTema.grafito : Colors.white;

  static Color separador(BuildContext context) =>
      _oscuro(context) ? const Color(0xFF2E2D2D) : const Color(0xFFE3E0D8);

  /// Lo que escribo yo.
  static Color miBurbuja(BuildContext context) =>
      _oscuro(context) ? const Color(0xFF6E7260) : ConfiguracionTema.grafito;

  /// Lo que escribe la otra persona.
  static Color suBurbuja(BuildContext context) =>
      _oscuro(context) ? const Color(0xFF565454) : ConfiguracionTema.crema;
}

/// La foto de la otra persona en la cabecera.
class _AvatarContraparte extends StatelessWidget {
  const _AvatarContraparte({required this.nombre, required this.fotoUrl});

  final String nombre;
  final String? fotoUrl;

  String get _iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'))
      ..removeWhere((parte) => parte.isEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((parte) => parte[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final respaldo = ColoredBox(
      color: ConfiguracionTema.salviaClara,
      child: Center(
        child: Text(
          _iniciales,
          style: const TextStyle(
            color: ConfiguracionTema.grafito,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: 38,
        child: switch (fotoUrl) {
          final String url when url.isNotEmpty => FotoRed(
            url: url,
            anchoVisible: 38,
            alFallar: respaldo,
          ),
          _ => respaldo,
        },
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje, required this.anterior});

  final MensajePedido mensaje;
  final MensajePedido? anterior;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final seguido = mensaje.continuaA(anterior);

    final fondo = mensaje.mio
        ? _ColoresChat.miBurbuja(context)
        : _ColoresChat.suBurbuja(context);
    final color = mensaje.mio || oscuro
        ? ConfiguracionTema.crema
        : ConfiguracionTema.grafito;

    return Padding(
      padding: EdgeInsets.only(top: seguido ? 3 : 12),
      child: Row(
        mainAxisAlignment: mensaje.mio
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: fondo,
                // La esquina del lado de quien escribe se recorta: es lo que
                // hace que un hilo se lea de un vistazo sin leer los nombres.
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mensaje.mio ? 18 : 5),
                  bottomRight: Radius.circular(mensaje.mio ? 5 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mensaje.cuerpo,
                    style: TextStyle(color: color, fontSize: 15, height: 1.35),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mensaje.hora,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: color.withValues(alpha: .65),
                        ),
                      ),
                      if (mensaje.mio) ...[
                        const SizedBox(width: 4),
                        Icon(
                          mensaje.leido
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 13,
                          color: Color(0xFFE6E1D5).withValues(alpha: .75),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados sin mensajes
// ---------------------------------------------------------------------------
class _ChatVacio extends StatelessWidget {
  const _ChatVacio({required this.contraparte});

  final String contraparte;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 46, color: Color(0xFFBBBCA7)),
          const SizedBox(height: 14),
          Text(
            'Ponte de acuerdo con ${contraparte.split(' ').first}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'La hora y el lugar exacto. Esta conversación se cierra cuando '
            'los dos confirmen la entrega.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF848381), height: 1.4),
          ),
          const SizedBox(height: 14),
          // Se dice claro: el hilo se conserva y alguien puede leerlo si hay
          // una disputa por ese pedido. Dejar creer que es privado seria
          // mentir, y es justo lo que haria que alguien escribiera algo que
          // no escribiria sabiendolo.
          const Text(
            'Se guarda por si hay algún problema con el pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA09A),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChatCerrado extends StatelessWidget {
  const _ChatCerrado();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 44,
            color: Color(0xFFBBBCA7),
          ),
          const SizedBox(height: 14),
          Text(
            'Conversación cerrada',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'El pedido terminó, así que el chat se cerró.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF848381), height: 1.4),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Barra de escritura
// ---------------------------------------------------------------------------
class _Redaccion extends StatelessWidget {
  const _Redaccion({
    required this.campo,
    required this.foco,
    required this.enviando,
    required this.alEnviar,
  });

  final TextEditingController campo;
  final FocusNode foco;
  final bool enviando;
  final VoidCallback alEnviar;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    // La barra de escribir tambien es superficie, no conversacion: lleva el
    // color de la cabecera y su propia raya, para que el hilo de mensajes
    // quede enmarcado arriba y abajo.
    return Container(
      decoration: BoxDecoration(
        color: _ColoresChat.cabecera(context),
        border: Border(top: BorderSide(color: _ColoresChat.separador(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: campo,
                  focusNode: foco,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => alEnviar(),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje',
                    filled: true,
                    fillColor: oscuro
                        ? const Color(0xFF474646)
                        : const Color(0xFFE6E1D5),
                    isDense: true,
                    // El contador de 1000 caracteres en un chat solo estorba.
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFF474646),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enviando ? null : alEnviar,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: enviando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: IndicadorCarga(tamanio: 22),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Color(0xFFE6E1D5),
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Respaldo por WhatsApp
// ---------------------------------------------------------------------------
/// Aparece solo cuando la otra persona lleva dos minutos sin contestar.
///
/// Antes estaba siempre a la vista, en el detalle del pedido, y eso hacia que
/// se usara de primera: la conversacion volvia a irse de la aplicacion sin
/// haberle dado una oportunidad al chat.
class _RespaldoWhatsapp extends StatelessWidget {
  const _RespaldoWhatsapp({
    required this.contraparte,
    required this.ocupado,
    required this.alPresionar,
  });

  final String contraparte;
  final bool ocupado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: oscuro ? const Color(0xFF474646) : const Color(0xFFE6E1D5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${contraparte.split(' ').first} no responde hace un rato.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: oscuro
                      ? const Color(0xFFBBBCA7)
                      : const Color(0xFF474646),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: ocupado ? null : alPresionar,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF474646),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.phone_outlined, size: 17),
              label: const Text(
                'WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Punto de entrega
// ---------------------------------------------------------------------------
/// Recuerda dónde quedaron, sin tener que subir a buscarlo al pedido.
///
/// Es lo que más se pregunta en estos chats — "¿dónde estás?", "¿qué bloque?"
/// — así que tenerlo fijo arriba ahorra la mitad de la conversación.
class _PuntoEntrega extends StatelessWidget {
  const _PuntoEntrega({required this.punto});

  final String punto;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: oscuro ? const Color(0xFF16261C) : const Color(0xFFEBF7EF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.place_outlined,
            size: 15,
            color: oscuro ? const Color(0xFF7FC79C) : const Color(0xFF2F7A50),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              punto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: oscuro
                    ? const Color(0xFFA9C9B5)
                    : const Color(0xFF2F7A50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
