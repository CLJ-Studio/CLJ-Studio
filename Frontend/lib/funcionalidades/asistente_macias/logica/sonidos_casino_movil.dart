import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'sonidos_casino.dart';

SonidosMesa crearSonidos(Set<SonidoMesa> cuales) => _SonidosMovil(cuales);

/// Un reproductor listo para sonar, con el volumen que tiene puesto: cambiar
/// el volumen es una llamada mas al sistema, asi que solo se hace si cambia.
class _Voz {
  _Voz(this.reproductor);

  final AudioPlayer reproductor;
  double volumen = 1;

  /// Cuantas veces se uso. Un fundido que empezo antes de que volviera a
  /// sonar no puede apagar el sonido nuevo.
  int usos = 0;
}

/// En Android y iPhone: un pequeño grupo de reproductores por sonido, en
/// modo de baja latencia (en Android, el SoundPool del sistema).
///
/// En Android cada vez que suena algo se crea una pista de audio nueva, y en
/// algunos telefonos (el A15 de Samsung, por ejemplo) arrancar muchas de
/// golpe atrasa el mezclador y se oyen cortes. Por eso se cuida cada llamada:
/// los sonidos que se repiten muy seguido se descartan ([LimitadorDeSonidos])
/// y el volumen solo se cambia cuando hace falta.
class _SonidosMovil implements SonidosMesa {
  _SonidosMovil(this._cuales);

  final Set<SonidoMesa> _cuales;
  final _azar = Random();
  final _limite = LimitadorDeSonidos();
  final _reproductores = <String, List<_Voz>>{};
  final _turnos = <String, int>{};

  /// El ultimo reproductor que se uso para cada sonido: el que se apaga.
  final _ultimo = <SonidoMesa, _Voz>{};
  Future<void>? _preparando;
  bool _liberado = false;

  /// Que suene encima de la musica, sin pausarla ni bajarla.
  static final _contexto = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  @override
  Future<void> preparar() => _preparando ??= _cargar();

  /// Todos a la vez: lo que carga primero ya suena mientras el resto llega.
  Future<void> _cargar() => Future.wait([
    for (final sonido in _cuales)
      for (final archivo in sonido.archivos)
        _cargarArchivo(archivo, sonido.copias),
  ]);

  Future<void> _cargarArchivo(String archivo, int copias) async {
    final lista = _reproductores[archivo] = <_Voz>[];
    for (var i = 0; i < copias; i++) {
      if (_liberado) return;
      final reproductor = AudioPlayer();
      try {
        await reproductor.setAudioContext(_contexto);
        await reproductor.setPlayerMode(PlayerMode.lowLatency);
        await reproductor.setReleaseMode(ReleaseMode.stop);
        await reproductor.setSource(AssetSource('audio/casino/$archivo.wav'));
        if (_liberado) {
          unawaited(reproductor.dispose());
          return;
        }
        lista.add(_Voz(reproductor));
      } catch (_) {
        // Un sonido que no carga no frena la mesa: se juega sin el.
        unawaited(reproductor.dispose());
      }
    }
  }

  @override
  void tocar(SonidoMesa sonido, {double volumen = 1}) {
    if (!_limite.dejaPasar(sonido)) return;
    final archivo = sonido.archivos[_azar.nextInt(sonido.archivos.length)];
    final lista = _reproductores[archivo];
    if (lista == null || lista.isEmpty) return;
    final turno = _turnos[archivo] ?? 0;
    _turnos[archivo] = turno + 1;
    final voz = lista[turno % lista.length];
    voz.usos++;
    _ultimo[sonido] = voz;
    unawaited(_reproducir(voz, volumen.clamp(0.0, 1.0)));
  }

  Future<void> _reproducir(_Voz voz, double volumen) async {
    try {
      // Sin parar antes, volveria a "reanudar" el sonido que ya termino y no
      // sonaria nada.
      await voz.reproductor.stop();
      if ((voz.volumen - volumen).abs() > .001) {
        voz.volumen = volumen;
        await voz.reproductor.setVolume(volumen);
      }
      await voz.reproductor.resume();
    } catch (_) {}
  }

  @override
  void detener(SonidoMesa sonido) {
    final voz = _ultimo.remove(sonido);
    if (voz != null) unawaited(_apagar(voz));
  }

  /// Baja el volumen en cuatro pasos y para: sin el clic de cortar de golpe.
  /// Si mientras tanto el mismo reproductor vuelve a sonar, lo deja en paz.
  Future<void> _apagar(_Voz voz) async {
    final uso = voz.usos;
    try {
      final base = voz.volumen;
      for (var paso = 3; paso >= 1; paso--) {
        if (voz.usos != uso) return;
        voz.volumen = base * paso / 4;
        await voz.reproductor.setVolume(voz.volumen);
        await Future<void>.delayed(const Duration(milliseconds: 35));
      }
      if (voz.usos == uso) await voz.reproductor.stop();
    } catch (_) {}
  }

  @override
  Future<void> liberar() async {
    _liberado = true;
    final todos = [for (final lista in _reproductores.values) ...lista];
    _reproductores.clear();
    for (final voz in todos) {
      try {
        await voz.reproductor.dispose();
      } catch (_) {}
    }
  }
}
