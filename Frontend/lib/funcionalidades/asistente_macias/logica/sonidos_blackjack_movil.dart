import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'sonidos_blackjack.dart';

SonidosMesa crearSonidos() => _SonidosMovil();

/// En Android y iPhone: un pequeño grupo de reproductores por sonido, en
/// modo de baja latencia (en Android, el SoundPool del sistema).
class _SonidosMovil implements SonidosMesa {
  final _azar = Random();
  final _reproductores = <String, List<AudioPlayer>>{};
  final _turnos = <String, int>{};
  Future<void>? _preparando;
  bool _liberado = false;

  /// Que suene encima de la musica, sin pausarla ni bajarla.
  static final _contexto = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  @override
  Future<void> preparar() => _preparando ??= _cargar();

  Future<void> _cargar() async {
    for (final sonido in SonidoMesa.values) {
      for (final archivo in sonido.archivos) {
        final lista = <AudioPlayer>[];
        for (var i = 0; i < sonido.copias; i++) {
          if (_liberado) return;
          final reproductor = AudioPlayer();
          try {
            await reproductor.setAudioContext(_contexto);
            await reproductor.setPlayerMode(PlayerMode.lowLatency);
            await reproductor.setReleaseMode(ReleaseMode.stop);
            await reproductor.setSource(
              AssetSource('audio/blackjack/$archivo.wav'),
            );
            lista.add(reproductor);
          } catch (_) {
            // Un sonido que no carga no frena la mesa: se juega sin el.
            unawaited(reproductor.dispose());
          }
        }
        _reproductores[archivo] = lista;
      }
    }
  }

  @override
  void tocar(SonidoMesa sonido, {double volumen = 1}) {
    final archivo = sonido.archivos[_azar.nextInt(sonido.archivos.length)];
    final lista = _reproductores[archivo];
    if (lista == null || lista.isEmpty) return;
    final turno = _turnos[archivo] ?? 0;
    _turnos[archivo] = turno + 1;
    unawaited(_reproducir(lista[turno % lista.length], volumen));
  }

  Future<void> _reproducir(AudioPlayer reproductor, double volumen) async {
    try {
      await reproductor.stop();
      await reproductor.setVolume(volumen.clamp(0.0, 1.0));
      await reproductor.resume();
    } catch (_) {}
  }

  @override
  Future<void> liberar() async {
    _liberado = true;
    final todos = [for (final lista in _reproductores.values) ...lista];
    _reproductores.clear();
    for (final reproductor in todos) {
      try {
        await reproductor.dispose();
      } catch (_) {}
    }
  }
}
