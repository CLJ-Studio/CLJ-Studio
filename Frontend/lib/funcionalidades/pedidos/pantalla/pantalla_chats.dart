import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import '../datos/repositorio_chat_pedido.dart';
import '../modelos/resumen_chat.dart';
import 'pantalla_chat_pedido.dart';

/// Bandeja con las conversaciones abiertas.
///
/// Antes solo se llegaba al chat desde el pedido o desde una notificación, y
/// quien descartaba la notificación se quedaba sin puerta. Aquí están todas,
/// que es donde la gente las busca.
///
/// No es una lista de contactos: solo aparece lo que tiene un pedido vivo
/// detrás, y desaparece cuando la venta se cierra.
class PantallaChats extends StatefulWidget {
  const PantallaChats({super.key});

  @override
  State<PantallaChats> createState() => _PantallaChatsState();
}

class _PantallaChatsState extends State<PantallaChats> {
  static const _repositorio = RepositorioChatPedido();

  List<ResumenChat> _chats = const [];
  bool _cargando = true;
  String? _error;

  /// Un mensaje nuevo tiene que mover la bandeja sin que nadie recargue.
  late final _escucha = EscuchaTabla(
    tabla: 'mensajes_pedido',
    alCambiar: _recargarEnSilencio,
  );

  @override
  void initState() {
    super.initState();
    _cargar();
    _escucha.iniciar();
  }

  @override
  void dispose() {
    _escucha.detener();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final chats = await _repositorio.listarChats();
      if (mounted) {
        setState(() {
          _chats = chats;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar tus chats.';
          _cargando = false;
        });
      }
    }
  }

  /// Refresca sin el indicador, para que la lista no parpadee con cada
  /// mensaje que llega.
  Future<void> _recargarEnSilencio() async {
    try {
      final chats = await _repositorio.listarChats();
      if (mounted) setState(() => _chats = chats);
    } catch (_) {
      // Se reintenta en el siguiente evento.
    }
  }

  Future<void> _abrir(ResumenChat chat) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaChatPedido(
          pedidoId: chat.pedidoId,
          contraparte: chat.contraparte,
        ),
      ),
    );
    // Al volver, lo leído ya no debe seguir contando.
    await _recargarEnSilencio();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.w900)),
    ),
    body: switch (this) {
      _ when _cargando => const Center(child: IndicadorCarga()),
      _ when _error != null => MensajeCatalogo(
        mensaje: _error!,
        alReintentar: _cargar,
      ),
      _ when _chats.isEmpty => const _SinChats(),
      _ => RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
          children: [
            ContenidoCentrado(
              anchoMaximo: 620,
              child: Column(
                children: [
                  for (final chat in _chats)
                    _FilaChat(chat: chat, alAbrir: () => _abrir(chat)),
                ],
              ),
            ),
          ],
        ),
      ),
    },
  );
}

class _FilaChat extends StatelessWidget {
  const _FilaChat({required this.chat, required this.alAbrir});

  final ResumenChat chat;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final sinLeer = chat.sinLeer > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: oscuro ? const Color(0xFF171A17) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alAbrir,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                _Foto(chat: chat),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.contraparte,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chat.cuando,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: sinLeer
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: sinLeer
                                  ? const Color(0xFF138A5B)
                                  : const Color(0xFF858985),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        chat.local,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF858985),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.vistaPrevia,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                // Lo pendiente pesa más que lo ya visto: es lo
                                // único que distingue una bandeja de una lista.
                                fontWeight: sinLeer
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                fontStyle: chat.tieneMensajes
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                                color: sinLeer
                                    ? Theme.of(context).colorScheme.onSurface
                                    : const Color(0xFF858985),
                              ),
                            ),
                          ),
                          if (sinLeer) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF138A5B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${chat.sinLeer}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  const _Foto({required this.chat});

  final ResumenChat chat;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final url = chat.fotoUrl;

    return SizedBox(
      width: 52,
      height: 52,
      child: url == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: oscuro
                    ? const Color(0xFF242824)
                    : const Color(0xFFF1F5F2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(chat.emoji, style: const TextStyle(fontSize: 24)),
              ),
            )
          : ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                // Si la foto no carga, el emoji del local es mejor que un
                // hueco roto en mitad de la lista.
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: oscuro
                        ? const Color(0xFF242824)
                        : const Color(0xFFF1F5F2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      chat.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SinChats extends StatelessWidget {
  const _SinChats();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 48, color: Color(0xFFB8BDB8)),
          const SizedBox(height: 16),
          Text(
            'Ninguna conversación abierta',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los chats aparecen cuando un pedido se acepta, y se cierran '
            'cuando la entrega queda confirmada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF858585), height: 1.4),
          ),
        ],
      ),
    ),
  );
}
