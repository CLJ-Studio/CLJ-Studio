import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/almacen_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/sonidos_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_casino.dart';

/// Un WAV leido a mano: mono, 16 bits.
class _Wav {
  _Wav(File archivo) {
    final bytes = archivo.readAsBytesSync();
    final datos = ByteData.sublistView(bytes);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    formato = datos.getUint16(20, Endian.little);
    canales = datos.getUint16(22, Endian.little);
    tasa = datos.getUint32(24, Endian.little);
    bits = datos.getUint16(34, Endian.little);
    var p = 12;
    var inicio = 44;
    var largo = bytes.length - 44;
    while (p + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(p, p + 4));
      final tam = datos.getUint32(p + 4, Endian.little);
      if (id == 'data') {
        inicio = p + 8;
        largo = tam;
        break;
      }
      p += 8 + tam;
    }
    muestras = [
      for (var i = 0; i < largo ~/ 2; i++)
        datos.getInt16(inicio + i * 2, Endian.little) / 32768,
    ];
    bytesTotal = bytes.length;
  }

  late final int formato;
  late final int canales;
  late final int tasa;
  late final int bits;
  late final List<double> muestras;
  late final int bytesTotal;

  double get segundos => muestras.length / tasa;

  double get picoDb {
    var pico = 0.0;
    for (final v in muestras) {
      pico = math.max(pico, v.abs());
    }
    return pico == 0 ? -99 : 20 * math.log(pico) / math.ln10;
  }
}

/// Lo que se le pidio al sistema de sonido, para ver cuantas veces suena.
class _Grabador implements SonidosMesa {
  final tocados = <SonidoMesa>[];
  final detenidos = <SonidoMesa>[];

  @override
  Future<void> preparar() async {}

  @override
  void tocar(SonidoMesa sonido, {double volumen = 1}) => tocados.add(sonido);

  @override
  void detener(SonidoMesa sonido) => detenidos.add(sonido);

  @override
  Future<void> liberar() async {}
}

void main() {
  final carpeta = Directory('assets/audio/casino');

  group('los archivos de sonido', () {
    test('cada sonido tiene todos sus archivos', () {
      for (final sonido in SonidoMesa.values) {
        for (final archivo in sonido.archivos) {
          expect(
            File('${carpeta.path}/$archivo.wav').existsSync(),
            isTrue,
            reason: '${sonido.name}: falta $archivo.wav',
          );
        }
      }
    });

    test('no sobra ninguno: todo lo que hay se usa', () {
      final usados = {
        for (final sonido in SonidoMesa.values) ...sonido.archivos,
      };
      final hay = {
        for (final f in carpeta.listSync().whereType<File>())
          f.uri.pathSegments.last.replaceAll('.wav', ''),
      };
      expect(hay.difference(usados), isEmpty);
    });

    test('estan sanos: mono de 16 bits, sin saturar ni clics', () {
      for (final archivo in carpeta.listSync().whereType<File>()) {
        final nombre = archivo.uri.pathSegments.last;
        final wav = _Wav(archivo);
        expect(wav.formato, 1, reason: '$nombre: no es PCM');
        expect(wav.canales, 1, reason: '$nombre: no es mono');
        expect(wav.bits, 16, reason: '$nombre: no es de 16 bits');
        expect(wav.tasa, anyOf(16000, 32000), reason: '$nombre: tasa rara');
        // Varios suenan a la vez y se suman: ninguno puede ir cerca del
        // maximo, o el telefono satura y suena roto.
        expect(wav.picoDb, lessThanOrEqualTo(-7.5), reason: '$nombre satura');
        expect(wav.picoDb, greaterThan(-30), reason: '$nombre casi no suena');
        // Empiezan y terminan en silencio: sin el "clic" de un corte seco.
        expect(
          wav.muestras.first.abs(),
          lessThan(.01),
          reason: '$nombre: empieza con un clic',
        );
        expect(
          wav.muestras.last.abs(),
          lessThan(.01),
          reason: '$nombre: termina con un clic',
        );
        // SoundPool (Android) no carga sonidos de mas de 1 MB.
        expect(wav.bytesTotal, lessThan(600 * 1024), reason: '$nombre pesa');
        expect(wav.segundos, lessThan(8), reason: '$nombre es muy largo');
      }
    });

    test('la voz es un murmullo suave, de tres largos', () {
      final largos = [
        for (final s in [
          SonidoMesa.vozCorta,
          SonidoMesa.vozMedia,
          SonidoMesa.vozLarga,
        ])
          _Wav(File('${carpeta.path}/${s.archivos.single}.wav')).segundos,
      ];
      expect(largos[0], lessThan(largos[1]));
      expect(largos[1], lessThan(largos[2]));
      for (final s in [
        SonidoMesa.vozCorta,
        SonidoMesa.vozMedia,
        SonidoMesa.vozLarga,
      ]) {
        // Mas bajo que cualquier ficha: es un fondo, no un sonido que se
        // pelea con los demas.
        expect(
          _Wav(File('${carpeta.path}/${s.archivos.single}.wav')).picoDb,
          lessThan(-15),
        );
      }
    });
  });

  group('el limitador de repeticiones', () {
    test('una rafaga suena como una tanda, no como diez golpes', () {
      var ahora = 0;
      final limite = LimitadorDeSonidos(ahoraMs: () => ahora);
      final sonaron = <int>[];
      for (ahora = 0; ahora < 200; ahora += 10) {
        if (limite.dejaPasar(SonidoMesa.ficha)) sonaron.add(ahora);
      }
      // Cada 45 ms como minimo: 0, 50, 100, 150.
      expect(sonaron, [0, 50, 100, 150]);
    });

    test('cada sonido lleva su propia cuenta', () {
      var ahora = 0;
      final limite = LimitadorDeSonidos(ahoraMs: () => ahora);
      expect(limite.dejaPasar(SonidoMesa.ficha), isTrue);
      expect(limite.dejaPasar(SonidoMesa.cartaCae), isTrue);
      ahora = 10;
      expect(limite.dejaPasar(SonidoMesa.ficha), isFalse);
      expect(limite.dejaPasar(SonidoMesa.cartaCae), isFalse);
      expect(limite.dejaPasar(SonidoMesa.cobrar), isTrue);
    });

    test('lo que no tiene separacion suena siempre', () {
      var ahora = 0;
      final limite = LimitadorDeSonidos(ahoraMs: () => ahora);
      for (var i = 0; i < 5; i++) {
        expect(limite.dejaPasar(SonidoMesa.ganar), isTrue);
      }
    });
  });

  group('la voz de MacIAs', () {
    test('a cada frase le toca el murmullo mas corto que le alcance', () {
      expect(VozCrupier.paraFrase(500), SonidoMesa.vozCorta);
      expect(VozCrupier.paraFrase(1100), SonidoMesa.vozCorta);
      expect(VozCrupier.paraFrase(1101), SonidoMesa.vozMedia);
      expect(VozCrupier.paraFrase(2000), SonidoMesa.vozMedia);
      expect(VozCrupier.paraFrase(3500), SonidoMesa.vozLarga);
    });

    test('una frase es un solo sonido, y se apaga al terminar', () {
      final grabador = _Grabador();
      final voz = VozCrupier(
        tocar: (s, {double volumen = 1}) => grabador.tocar(s, volumen: volumen),
        detener: grabador.detener,
      );
      voz.empezar(1800);
      expect(grabador.tocados, [SonidoMesa.vozMedia]);
      voz.terminar();
      expect(grabador.detenidos, [SonidoMesa.vozMedia]);
      // Terminar dos veces no apaga dos veces.
      voz.terminar();
      expect(grabador.detenidos, hasLength(1));
    });

    test('una frase nueva corta la anterior', () {
      final grabador = _Grabador();
      final voz = VozCrupier(
        tocar: (s, {double volumen = 1}) => grabador.tocar(s, volumen: volumen),
        detener: grabador.detener,
      );
      voz
        ..empezar(900)
        ..empezar(3000);
      expect(grabador.tocados, [SonidoMesa.vozCorta, SonidoMesa.vozLarga]);
      expect(grabador.detenidos, [SonidoMesa.vozCorta]);
    });

    testWidgets('en pantalla, una frase de 100 letras suena una sola vez', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final grabador = _Grabador();
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaCasino(
            nombre: 'Ana',
            almacen: AlmacenCasinoEnMemoria(),
            sonidos: grabador,
            sonidosDeMesas: const SonidosMesa.mudos(),
          ),
        ),
      );
      // Lo que tarda en saludar y en escribirse todo.
      for (var t = 0; t < 9000; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final voces = grabador.tocados.where(
        (s) =>
            s == SonidoMesa.vozCorta ||
            s == SonidoMesa.vozMedia ||
            s == SonidoMesa.vozLarga,
      );
      // Antes eran decenas (uno cada tres letras): ahora el saludo es uno.
      expect(voces, hasLength(1));
      expect(grabador.detenidos, contains(voces.single));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
