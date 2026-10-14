import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'sonidos_blackjack.dart';

SonidosMesa crearSonidos() => _SonidosWeb();

/// En la web (la PWA): Web Audio. Cada sonido se decodifica una vez y
/// despues se dispara al instante, todas las veces que haga falta a la vez.
/// Un `<audio>` comun tardaba en arrancar y la ficha sonaba despues de caer.
class _SonidosWeb implements SonidosMesa {
  final _azar = Random();
  final _sonidos = <String, web.AudioBuffer>{};
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
        for (final sonido in SonidoMesa.values)
          for (final archivo in sonido.archivos) _cargarUno(contexto, archivo),
      ]);
    } catch (_) {
      // Un navegador sin Web Audio: la mesa se juega en silencio.
    }
  }

  Future<void> _cargarUno(web.AudioContext contexto, String archivo) async {
    try {
      final url = ui_web.assetManager.getAssetUrl(
        'assets/audio/blackjack/$archivo.wav',
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
    _despertar();
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
    } catch (_) {}
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
