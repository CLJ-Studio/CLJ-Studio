import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/billetera_casino.dart';

/// Como casino_sincronizar() en el servidor: la primera vez toma las del
/// telefono, despues suma lo que cambio, y un lote repetido cuenta una vez.
class _ServidorFalso implements ServidorBilletera {
  int fichas = 1000;
  bool migrada = false;
  bool sinRed = false;
  int enMesa = 0;
  String? mesa;
  final aplicados = <String>{};
  final llamadas = <({String lote, int delta, int? inicial})>[];

  @override
  Future<SaldoCasino> sincronizar({
    required String lote,
    required int delta,
    int? inicial,
  }) async {
    llamadas.add((lote: lote, delta: delta, inicial: inicial));
    if (sinRed) throw Exception('sin red');
    if (aplicados.add(lote)) {
      if (!migrada && inicial != null) {
        fichas = math.max(0, fichas - 1000 + inicial);
      } else {
        fichas = math.max(0, fichas + delta);
      }
      migrada = true;
    }
    return SaldoCasino(fichas: fichas, enMesa: enMesa, mesa: mesa);
  }
}

void main() {
  late _ServidorFalso servidor;

  AlmacenCasinoServidor almacen() =>
      AlmacenCasinoServidor('u1', servidor: servidor);

  setUp(() {
    servidor = _ServidorFalso();
  });

  test('la primera vez se lleva al servidor las fichas del telefono', () async {
    SharedPreferences.setMockInitialValues({'macias.u1.casino.fichas': 5000});
    final casino = almacen();

    expect(await casino.fichas(), 5000);
    expect(servidor.fichas, 5000);
    expect(servidor.llamadas.single.inicial, 5000);

    // Despues solo viaja lo que cambio.
    await casino.fichas();
    expect(servidor.llamadas.last.inicial, isNull);
    expect(servidor.llamadas.last.delta, 0);
  });

  test('sin fichas guardadas, arranca con las de regalo', () async {
    SharedPreferences.setMockInitialValues({});
    final casino = almacen();
    expect(await casino.fichas(), 1000);
    expect(servidor.llamadas.single.inicial, isNull);
  });

  test('manda lo que cambio y no el total: lo del poker se respeta', () async {
    SharedPreferences.setMockInitialValues({'macias.u1.casino.fichas': 2000});
    final casino = almacen();
    expect(await casino.fichas(), 2000);

    // Mientras juega al blackjack, vuelven 700 de una mesa de poker (desde
    // otro telefono). El blackjack gana 100 y guarda su total: 2.100.
    servidor.fichas += 700;
    await casino.guardarFichas(2100);
    expect(await casino.fichas(), 2800);
    expect(servidor.fichas, 2800);
  });

  test('sin red, el lote espera y sale una sola vez', () async {
    SharedPreferences.setMockInitialValues({'macias.u1.casino.fichas': 1000});
    final casino = almacen();
    expect(await casino.fichas(), 1000);

    servidor.sinRed = true;
    await casino.guardarFichas(1300);
    // Sin red se sigue jugando con la copia del telefono.
    expect(await casino.fichas(), 1300);
    expect(servidor.fichas, 1000);
    await casino.guardarFichas(1250);

    servidor.sinRed = false;
    expect(await casino.fichas(), 1250);
    expect(servidor.fichas, 1250);

    // El primer lote que fallo volvio a salir con el mismo nombre.
    final intentos = servidor.llamadas.where((l) => l.delta == 300).toList();
    expect(intentos.length, greaterThan(1));
    expect(intentos.map((l) => l.lote).toSet(), hasLength(1));

    // Y si el servidor lo vuelve a recibir, no lo cuenta otra vez.
    await casino.fichas();
    expect(servidor.fichas, 1250);
  });

  test('sabe lo que hay sentado en una mesa de poker', () async {
    SharedPreferences.setMockInitialValues({});
    servidor
      ..enMesa = 1500
      ..mesa = 'Mesa de Juan';
    final casino = almacen();
    await casino.fichas();
    expect(casino.enPoker, (fichas: 1500, mesa: 'Mesa de Juan'));
  });

  test('lo de cada juego y el sonido quedan en el telefono', () async {
    SharedPreferences.setMockInitialValues({});
    final casino = almacen();
    await casino.guardarJuego('ruleta', {'giros': 3});
    await casino.guardarSonido(false);
    expect(await casino.juego('ruleta'), {'giros': 3});
    expect(await casino.conSonido(), isFalse);
  });

  test('un lote es un uuid v4', () {
    final lote = nuevoLote();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(lote),
      isTrue,
    );
    expect(nuevoLote(), isNot(lote));
  });
}
