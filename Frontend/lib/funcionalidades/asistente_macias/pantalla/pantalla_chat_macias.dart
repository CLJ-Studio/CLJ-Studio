import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../configuracion_aplicacion/version_aplicacion.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../configuracion_usuario/datos/contacto_soporte.dart';
import '../../configuracion_usuario/pantalla/pantalla_acerca_de.dart';
import '../../configuracion_usuario/pantalla/pantalla_editar_perfil.dart';
import '../../configuracion_usuario/pantalla/pantalla_privacidad.dart';
import '../../favoritos/pantalla/pantalla_favoritos.dart';
import '../../instalacion_app/diseno/aviso_instalacion.dart';
import '../../pedidos/pantalla/pantalla_chats.dart';
import '../../pedidos/pantalla/pantalla_pedidos_completa.dart';
import '../../publicar_producto/pantalla/pantalla_mis_publicaciones.dart';
import '../diseno/burbujas_macias.dart';
import '../diseno/identidad_macias.dart';
import '../logica/cerebro_macias.dart';
import '../logica/conocimiento_macias.dart';
import '../logica/controlador_chat_macias.dart';
import '../logica/memoria_macias.dart';
import '../modelos/mensaje_macias.dart';

/// El chat con MacIAs, el asistente virtual de U market.
///
/// Se abre desde Ayuda. Responde al instante sobre la app y sobre algunas
/// materias, hace cuentas, y cuando hace falta lleva directo a la pantalla de
/// la que habla. La conversacion queda en el telefono para seguirla despues.
class PantallaChatMacias extends StatefulWidget {
  const PantallaChatMacias({this.ritmo, this.almacen, super.key});

  /// Cuanto tarda en "escribir". Sin indicarlo, a ritmo de conversacion, o
  /// al instante si el telefono pide reducir el movimiento.
  final RitmoMacias? ritmo;

  /// Donde se guarda la conversacion. Sin indicarlo, en el telefono y
  /// separada por cuenta.
  final AlmacenMacias? almacen;

  @override
  State<PantallaChatMacias> createState() => _PantallaChatMaciasState();
}

class _PantallaChatMaciasState extends State<PantallaChatMacias> {
  ControladorChatMacias? _controlador;
  final _campo = TextEditingController();
  final _foco = FocusNode();
  final _desplazamiento = ScrollController();

  /// Los mensajes que ya hicieron su entrada. Ver `AparicionMensaje`.
  final _yaAparecieron = <int>{};
  bool _sinMovimiento = false;
  bool _restauradosVistos = false;
  int _cuantosHabia = 0;
  bool _escribiaAntes = false;

  ControladorChatMacias get controlador => _controlador!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controlador != null) return;
    // Se arma aca y no en initState porque necesita saber si el telefono
    // pide reducir el movimiento, y eso vive en el MediaQuery.
    _sinMovimiento = MediaQuery.disableAnimationsOf(context);
    final sesion = SesionUsuario.instancia;
    final controlador = ControladorChatMacias(
      cerebro: CerebroMacias(
        contexto: () => ContextoMacias(
          nombre: sesion.primerNombre,
          ahora: DateTime.now(),
          version: VersionAplicacion.etiqueta,
          esWeb: kIsWeb,
        ),
      ),
      almacen: widget.almacen ?? AlmacenMaciasLocal(_cuenta()),
      ritmo: widget.ritmo ?? RitmoMacias(inmediato: _sinMovimiento),
    );
    // Primero se guarda y despues se escucha y se arranca: el saludo avisa
    // en el acto, y el aviso tiene que encontrar el controlador ya puesto.
    _controlador = controlador;
    controlador
      ..addListener(_alCambiar)
      ..iniciar();
  }

  /// De quien es esta conversacion. Sin sesion (no deberia pasar dentro de
  /// la app) queda en un cajon comun.
  static String _cuenta() {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? 'sin_sesion';
    } catch (_) {
      return 'sin_sesion';
    }
  }

  @override
  void dispose() {
    _controlador?.dispose();
    _campo.dispose();
    _foco.dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  void _alCambiar() {
    // Lo que vino de una visita anterior ya se vio: no se anima otra vez.
    if (!_restauradosVistos && !controlador.cargando) {
      _restauradosVistos = true;
      for (final mensaje in controlador.mensajes.take(
        controlador.restaurados,
      )) {
        _yaAparecieron.add(mensaje.id);
      }
      if (controlador.restaurados > 0) _irAlFinal(animado: false);
    }
    final cuantos = controlador.mensajes.length;
    final escribe = controlador.escribiendo;
    if (cuantos != _cuantosHabia || escribe != _escribiaAntes) {
      _cuantosHabia = cuantos;
      _escribiaAntes = escribe;
      _irAlFinal();
    }
  }

  /// Se hace despues de pintar: antes, la lista todavia no tiene la altura
  /// del mensaje nuevo y el salto quedaria corto.
  void _irAlFinal({bool animado = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_desplazamiento.hasClients) return;
      final fondo = _desplazamiento.position.maxScrollExtent;
      if (_sinMovimiento || !animado) {
        _desplazamiento.jumpTo(fondo);
      } else {
        _desplazamiento.animateTo(
          fondo,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _enviar() {
    final texto = _campo.text.trim();
    if (texto.isEmpty) return;
    controlador.escribir(texto);
    _campo.clear();
    // En una conversacion se manda una linea detras de otra: perder el
    // teclado en cada envio la corta entera.
    _foco.requestFocus();
  }

  void _elegir(OpcionMacias opcion) => controlador.elegir(opcion);

  /// Lleva a la pantalla de la que habla la respuesta.
  ///
  /// Cada una se abre encima del chat, asi que al volver la conversacion
  /// sigue donde estaba. Ninguna lleva a Ayuda: desde ahi se llego aca, y
  /// volver a abrirla armaria un bucle.
  void _abrir(DestinoMacias destino) {
    final navegador = Navigator.of(context);
    final pantalla = switch (destino) {
      DestinoMacias.pedidos => const PantallaPedidosCompleta(),
      DestinoMacias.chats => const PantallaChats(),
      DestinoMacias.favoritos => const PantallaFavoritos(),
      DestinoMacias.misPublicaciones => const PantallaMisPublicaciones(),
      DestinoMacias.editarPerfil => const PantallaEditarPerfil(),
      DestinoMacias.privacidad => const PantallaPrivacidad(),
      DestinoMacias.acercaDe => const PantallaAcercaDe(),
      _ => null,
    };
    if (pantalla != null) {
      navegador.push(MaterialPageRoute<void>(builder: (_) => pantalla));
      return;
    }
    switch (destino) {
      case DestinoMacias.carrito:
        navegador.pushNamed(ConfiguracionRutas.carrito);
      case DestinoMacias.instalar:
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 32),
            child: TarjetaInstalacion(),
          ),
        );
      case DestinoMacias.whatsappSoporte:
        ContactoSoporte.abrirWhatsapp(
          context,
          mensaje: 'Hola, vengo de MacIAs y necesito ayuda con U market.',
        );
      case DestinoMacias.correoSoporte:
        ContactoSoporte.abrirCorreo(context);
      default:
        break;
    }
  }

  Future<void> _borrarConversacion() async {
    final borrar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Borrar la conversación?'),
        content: const Text(
          'Se borran los mensajes de este chat. MacIAs sigue recordando lo '
          'que le contaste de ti, salvo que también se lo pidas.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (borrar != true || !mounted) return;
    _yaAparecieron.clear();
    controlador.borrarConversacion();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controlador,
    builder: (context, _) {
      final mensajes = controlador.mensajes;
      final escribiendo = controlador.escribiendo || controlador.cargando;
      return Scaffold(
        backgroundColor: ColoresChatMacias.fondo(context),
        appBar: _Cabecera(
          escribiendo: escribiendo,
          modoMeme: controlador.modoMeme,
          alAlternarMeme: controlador.alternarModoMeme,
          alBorrarConversacion: _borrarConversacion,
          alOlvidar: controlador.olvidarLoQueSabe,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _desplazamiento,
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                itemCount: 1 + mensajes.length + (escribiendo ? 1 : 0),
                itemBuilder: (context, indice) {
                  if (indice == 0) return const _InicioConversacion();
                  final posicion = indice - 1;
                  if (posicion == mensajes.length) {
                    return const AparicionMensaje(
                      animar: true,
                      desdeLaDerecha: false,
                      child: EscribiendoMacias(),
                    );
                  }
                  return _mensaje(mensajes, posicion, escribiendo);
                },
              ),
            ),
            _Sugerencias(opciones: controlador.sugerencias, alElegir: _elegir),
            _Redaccion(
              campo: _campo,
              foco: _foco,
              alEnviar: _enviar,
              alVerMenu: () => _elegir(CerebroMacias.chipMenu),
            ),
          ],
        ),
      );
    },
  );

  Widget _mensaje(List<MensajeMacias> mensajes, int posicion, bool escribe) {
    final mensaje = mensajes[posicion];
    final anterior = posicion > 0 ? mensajes[posicion - 1] : null;
    final siguiente = posicion + 1 < mensajes.length
        ? mensajes[posicion + 1]
        : null;
    final primera = anterior?.autor != mensaje.autor;
    // Si MacIAs sigue escribiendo, los puntos son su ultima "burbuja".
    final ultima = siguiente == null
        ? !(mensaje.esDeMacias && escribe)
        : siguiente.autor != mensaje.autor;

    final animar = !_sinMovimiento && _yaAparecieron.add(mensaje.id);
    return AparicionMensaje(
      key: ValueKey(mensaje.id),
      animar: animar,
      desdeLaDerecha: !mensaje.esDeMacias,
      child: mensaje.esDeMacias
          ? BurbujaDeMacias(
              mensaje: mensaje,
              primeraDelGrupo: primera,
              ultimaDelGrupo: ultima,
              alElegir: _elegir,
              alAccion: _abrir,
            )
          : BurbujaPropia(
              mensaje: mensaje,
              primeraDelGrupo: primera,
              ultimaDelGrupo: ultima,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cabecera
// ---------------------------------------------------------------------------
enum _OpcionCabecera { meme, borrar, olvidar }

class _Cabecera extends StatelessWidget implements PreferredSizeWidget {
  const _Cabecera({
    required this.escribiendo,
    required this.modoMeme,
    required this.alAlternarMeme,
    required this.alBorrarConversacion,
    required this.alOlvidar,
  });

  final bool escribiendo;
  final bool modoMeme;
  final VoidCallback alAlternarMeme;
  final VoidCallback alBorrarConversacion;
  final VoidCallback alOlvidar;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final secundario = Theme.of(context).textTheme.bodySmall?.color;
    final estado = escribiendo
        ? 'escribiendo…'
        : modoMeme
        ? 'Modo meme activado'
        : 'Asistente virtual de U market';
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: ColoresChatMacias.cabecera(context),
      titleSpacing: 0,
      // La cabecera tiene su propia superficie y una raya fina: sin eso, el
      // nombre parecia el primer mensaje del hilo (igual que en el chat de
      // los pedidos).
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: ColoresChatMacias.separador(context),
        ),
      ),
      title: Semantics(
        button: true,
        label: 'Ver el perfil de MacIAs',
        child: InkWell(
          onTap: () => mostrarPerfilMacias(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const AvatarMacias(tamano: 40, enLinea: true),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NombreMacias(
                        estilo: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          estado,
                          key: ValueKey(estado),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: escribiendo || modoMeme
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: escribiendo
                                ? ConfiguracionTema.interruptorActivo
                                : modoMeme
                                ? ConfiguracionTema.moradoPromocional
                                : secundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<_OpcionCabecera>(
          tooltip: 'Más opciones',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (opcion) => switch (opcion) {
            _OpcionCabecera.meme => alAlternarMeme(),
            _OpcionCabecera.borrar => alBorrarConversacion(),
            _OpcionCabecera.olvidar => alOlvidar(),
          },
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
              value: _OpcionCabecera.meme,
              checked: modoMeme,
              child: const Text('Modo meme'),
            ),
            const PopupMenuItem(
              value: _OpcionCabecera.borrar,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_sweep_outlined),
                title: Text('Borrar la conversación'),
              ),
            ),
            const PopupMenuItem(
              value: _OpcionCabecera.olvidar,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.psychology_alt_outlined),
                title: Text('Olvidar lo que sabe de mí'),
              ),
            ),
          ],
        ),
        const SizedBox(width: 2),
      ],
    );
  }
}

/// Quien es MacIAs, al tocar su nombre en la cabecera.
Future<void> mostrarPerfilMacias(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // En un telefono bajo, o con la letra grande, no entra entera.
      isScrollControlled: true,
      builder: (hoja) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AvatarMacias(tamano: 96, enLinea: true),
              const SizedBox(height: 12),
              const NombreMacias(
                estilo: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Asistente virtual de U market',
                style: TextStyle(
                  color: Theme.of(hoja).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const _DatoPerfil(
                icono: Icons.bolt_rounded,
                titulo: 'Responde al instante',
                detalle: 'A cualquier hora, sin esperar a nadie.',
              ),
              const _DatoPerfil(
                icono: Icons.school_outlined,
                titulo: 'Te ayuda a estudiar',
                detalle:
                    'Álgebra, cálculo integral y C++, con ejemplos. Hace '
                    'cuentas y resuelve ecuaciones paso a paso.',
              ),
              const _DatoPerfil(
                icono: Icons.verified_outlined,
                titulo: 'Verificado',
                detalle:
                    'Es el asistente oficial de U market: sus respuestas las '
                    'prepara el equipo, y no inventa.',
              ),
              const _DatoPerfil(
                icono: Icons.phone_android_rounded,
                titulo: 'Tu conversación queda en tu teléfono',
                detalle:
                    'Se guarda solo aquí, para que se acuerde de ti. La '
                    'borras desde el menú de los tres puntos.',
              ),
              const _DatoPerfil(
                icono: Icons.support_agent_rounded,
                titulo: 'Te pasa con una persona',
                detalle: 'Si lo necesitas, escribe "persona".',
              ),
            ],
          ),
        ),
      ),
    );

class _DatoPerfil extends StatelessWidget {
  const _DatoPerfil({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icono),
    title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(detalle),
  );
}

// ---------------------------------------------------------------------------
// Cuerpo
// ---------------------------------------------------------------------------
/// El aviso de como funciona este chat, como el que abre un chat de empresa
/// en WhatsApp.
class _InicioConversacion extends StatelessWidget {
  const _InicioConversacion();

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final texto = ColoresChatMacias.suTexto(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ConfiguracionTema.amarilloDorado.withValues(
              alpha: oscuro ? .14 : .16,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: texto.withValues(alpha: .8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MacIAs responde al instante con información verificada de '
                  'U market. La conversación se guarda solo en este teléfono.',
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: texto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los atajos de abajo: menu, materias, una persona, "me sirvio".
class _Sugerencias extends StatelessWidget {
  const _Sugerencias({required this.opciones, required this.alElegir});

  final List<OpcionMacias> opciones;
  final ValueChanged<OpcionMacias> alElegir;

  static IconData _iconoDe(OpcionMacias opcion) => switch (opcion.id) {
    'o:menu' => Icons.grid_view_rounded,
    's:extra' => Icons.school_outlined,
    'o:util' => Icons.thumb_up_alt_outlined,
    'o:no_util' => Icons.thumb_down_alt_outlined,
    'o:ampliar' => Icons.lightbulb_outline_rounded,
    'o:meme' => Icons.theater_comedy_outlined,
    't:${ConocimientoMacias.humano}' => Icons.support_agent_rounded,
    _ => Icons.chevron_right_rounded,
  };

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    alignment: Alignment.bottomCenter,
    child: opciones.isEmpty
        ? const SizedBox(width: double.infinity)
        : SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              itemCount: opciones.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, indice) {
                final opcion = opciones[indice];
                return ActionChip(
                  onPressed: () => alElegir(opcion),
                  avatar: Icon(_iconoDe(opcion), size: 16),
                  label: Text(
                    opcion.texto,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: ColoresChatMacias.cabecera(context),
                  side: BorderSide(color: ColoresChatMacias.separador(context)),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                );
              },
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
    required this.alEnviar,
    required this.alVerMenu,
  });

  final TextEditingController campo;
  final FocusNode foco;
  final VoidCallback alEnviar;
  final VoidCallback alVerMenu;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    );
    return Container(
      decoration: BoxDecoration(
        color: ColoresChatMacias.cabecera(context),
        border: Border(
          top: BorderSide(color: ColoresChatMacias.separador(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Ver el menú',
                onPressed: alVerMenu,
                icon: const Icon(Icons.grid_view_rounded),
              ),
              Expanded(
                child: TextField(
                  controller: campo,
                  focusNode: foco,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 300,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => alEnviar(),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu pregunta o un número',
                    filled: true,
                    fillColor: oscuro
                        ? const Color(0xFF474646)
                        : ConfiguracionTema.crema,
                    isDense: true,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    border: borde,
                    enabledBorder: borde,
                    focusedBorder: borde,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: ConfiguracionTema.grafito,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: alEnviar,
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(
                      Icons.send_rounded,
                      color: ConfiguracionTema.crema,
                      size: 22,
                      semanticLabel: 'Enviar',
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
