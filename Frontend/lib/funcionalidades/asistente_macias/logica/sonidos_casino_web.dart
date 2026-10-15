import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'sonidos_casino.dart';

SonidosMesa crearSonidos(Set<SonidoMesa> cuales) => _SonidosWeb(cuales);

/// En la web (la PWA): Web Audio. Cada sonido se decodifica una vez y
/// despues se dispara al instante, todas las veces que haga falta a la vez.
/// Un `<audio>` comun tardaba en arrancar y la ficha sonaba despues de caer.
class _SonidosWeb implements SonidosMesa {
  _SonidosWeb(this._cuales);

  final Set<SonidoMesa> _cuales;
  final _azar = Random();
  final _limite = LimitadorDeSonidos();
  final _sonidos = <String, web.AudioBuffer>{};

  /// Lo que esta sonando de cada sonido, para poder apagarlo.
  final _sonando =
      <SonidoMesa, List<(web.AudioBufferSourceNode, web.GainNode)>>{};
  web.AudioContext? _contexto;
  Future<void>? _preparando;
  JSFunction? _alTocar;

  /// Los toques que destraban el audio. Safari (el del iPhone) solo deja
  /// arrancarlo dentro de uno: un sonido que sale de un temporizador no
  /// alcanza.
  static const _gestos = ['pointerup', 'touchend', 'keydown'];

  @override
  Future<void> preparar() => _preparando ??= _cargar();

  Future<void> _cargar() async {
    try {
      final contexto = _contexto = web.AudioContext();
      final alTocar = _alTocar = ((web.Event _) => _despertar()).toJS;
      for (final gesto in _gestos) {
        web.window.addEventListener(gesto, alTocar);
      }
      await Future.wait([
        for (final sonido in _cuales)
          for (final archivo in sonido.archivos) _cargarUno(contexto, archivo),
      ]);
    } catch (_) {
      // Un navegador sin Web Audio: la mesa se juega en silencio.
    }
  }

  Future<void> _cargarUno(web.AudioContext contexto, String archivo) async {
    try {
      final url = ui_web.assetManager.getAssetUrl(
        'assets/audio/casino/$archivo.wav',
      );
      final respuesta = await web.window.fetch(url.toJS).toDart;
      final datos = await respuesta.arrayBuffer().toDart;
      _sonidos[archivo] = await contexto.decodeAudioData(datos).toDart;
    } catch (_) {}
  }

  /// El navegador arranca el audio en pausa hasta que se toca la pagina, y
  /// el iPhone lo vuelve a pausar si entra una llamada.
  void _despertar() {
    final contexto = _contexto;
    if (contexto == null || contexto.state == 'running') return;
    unawaited(
      contexto.resume().toDart.then<void>(
        (_) {},
        // Sin permiso todavia: lo intenta el proximo toque.
        onError: (Object _) {},
      ),
    );
  }

  @override
  void tocar(SonidoMesa sonido, {double volumen = 1}) {
    final contexto = _contexto;
    if (contexto == null) return;
    // Igual que en el telefono: una rafaga suena como una tanda, no como
    // diez sonidos pegados.
    if (!_limite.dejaPasar(sonido)) return;
    _despertar();
    // Con el audio todavia dormido (el iPhone espera el primer toque), un
    // sonido pedido ahora se quedaria en cola y saldria tarde, y todos
    // juntos, apenas despierte: mejor perder ese y no oir un golpe de
    // sonidos viejos.
    if (contexto.state != 'running') return;
    final archivo = sonido.archivos[_azar.nextInt(sonido.archivos.length)];
    final buffer = _sonidos[archivo];
    if (buffer == null) return;
    try {
      final fuente = contexto.createBufferSource()..buffer = buffer;
      final ganancia = contexto.createGain();
      ganancia.gain.value = volumen.clamp(0.0, 1.0);
      fuente.connect(ganancia);
      ganancia.connect(contexto.destination);
      fuente.start();
      final lista = _sonando[sonido] ??= [];
      lista.add((fuente, ganancia));
      // Solo se recuerdan los ultimos: los viejos ya terminaron.
      if (lista.length > 6) lista.removeAt(0);
    } catch (_) {}
  }

  @override
  void detener(SonidoMesa sonido) {
    final contexto = _contexto;
    final lista = _sonando.remove(sonido);
    if (contexto == null || lista == null) return;
    final ahora = contexto.currentTime;
    for (final (fuente, ganancia) in lista) {
      try {
        ganancia.gain
          ..setValueAtTime(ganancia.gain.value, ahora)
          ..linearRampToValueAtTime(0, ahora + .14);
        fuente.stop(ahora + .16);
      } catch (_) {}
    }
  }

  @override
  Future<void> liberar() async {
    final contexto = _contexto;
    _contexto = null;
    _sonidos.clear();
    final alTocar = _alTocar;
    _alTocar = null;
    if (alTocar != null) {
      for (final gesto in _gestos) {
        web.window.removeEventListener(gesto, alTocar);
      }
    }
    try {
      await contexto?.close().toDart;
    } catch (_) {}
  }
}
