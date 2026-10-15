import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/almacen_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/sonidos_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_blackjack.dart';

List<Carta> _cartas(List<int> rangos) => [
  for (final (i, rango) in rangos.indexed)
    Carta(rango, Palo.values[i % 4], 700 + i),
];

void _comoTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// La mesa con el sabot en este orden: jugador, crupier, jugador, crupier
/// (tapada) y despues lo que se pida.
Future<void> _abrirMesa(
  WidgetTester tester,
  List<int> orden, {
  AlmacenCasino? almacen,
}) async {
  _comoTelefono(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaBlackjack(
        nombre: 'Ana',
        sabot: Sabot.ordenado(_cartas(orden)),
        azar: Random(1),
        almacen: almacen ?? AlmacenCasinoEnMemoria(),
        sonidos: const SonidosMesa.mudos(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Deja correr las animaciones de la mesa, cuadro por cuadro.
Future<void> _esperar(WidgetTester tester, int milisegundos) async {
  for (var t = 0; t < milisegundos; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('la mesa', () {
    testWidgets('una mano entera: apostar, repartir, plantarse y cobrar', (
      tester,
    ) async {
      final almacen = AlmacenCasinoEnMemoria();
      await _abrirMesa(tester, [10, 10, 9, 7], almacen: almacen);
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Apostar 100'));
      await _esperar(tester, 600);
      expect(find.bySemanticsLabel('Tus fichas: 900'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Repartir'));
      await _esperar(tester, 3000);
      await tester.tap(find.bySemanticsLabel(RegExp('^Plantarse')));
      await _esperar(tester, 6000);

      expect(find.text('Ganaste 100 fichas'), findsOneWidget);
      expect(find.bySemanticsLabel('Tus fichas: 1100'), findsOneWidget);
      // Las fichas quedan guardadas para la próxima.
      expect(await almacen.fichas(), 1100);
      final estadisticas = EstadisticasBlackjack.desdeJson(
        (await almacen.juego('blackjack'))!,
      );
      expect(estadisticas.ganadas, 1);
    });

    testWidgets('el botón Todo apuesta todas las fichas, sin tope', (
      tester,
    ) async {
      final almacen = AlmacenCasinoEnMemoria();
      await almacen.guardarFichas(20000);
      await _abrirMesa(tester, [10, 10, 9, 7], almacen: almacen);
      expect(find.bySemanticsLabel('Tus fichas: 20000'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Todo'));
      await _esperar(tester, 700);
      // Las 20.000, no las 5.000 de antes.
      expect(find.bySemanticsLabel('Tus fichas: 0'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Repartir'));
      await _esperar(tester, 3000);
      await tester.tap(find.bySemanticsLabel(RegExp('^Plantarse')));
      await _esperar(tester, 6000);
      expect(find.text('Ganaste 20.000 fichas'), findsOneWidget);
      expect(find.bySemanticsLabel('Tus fichas: 40000'), findsOneWidget);
    });

    testWidgets('el blackjack se anuncia y paga 3 a 2', (tester) async {
      await _abrirMesa(tester, [1, 9, 13, 7]);
      await tester.tap(find.bySemanticsLabel('Apostar 100'));
      await _esperar(tester, 500);
      await tester.tap(find.bySemanticsLabel('Repartir'));
      await _esperar(tester, 7000);
      expect(find.text('BLACKJACK'), findsOneWidget);
      expect(find.bySemanticsLabel('Tus fichas: 1150'), findsOneWidget);
    });

    testWidgets('la pista de MacIAs ilumina la jugada que conviene', (
      tester,
    ) async {
      await _abrirMesa(tester, [10, 10, 6, 7]);
      await tester.tap(find.bySemanticsLabel('Apostar 100'));
      await _esperar(tester, 500);
      await tester.tap(find.bySemanticsLabel('Repartir'));
      await _esperar(tester, 3000);
      await tester.tap(find.bySemanticsLabel('¿Qué haría MacIAs?'));
      await _esperar(tester, 400);
      expect(
        find.bySemanticsLabel('Rendirse (lo que haría MacIAs)'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Rendirse')));
      await _esperar(tester, 6000);
      expect(find.text('RENDIDO'), findsOneWidget);
      expect(find.bySemanticsLabel('Tus fichas: 950'), findsOneWidget);
    });

    testWidgets('sin fichas, MacIAs presta', (tester) async {
      final almacen = AlmacenCasinoEnMemoria();
      await almacen.guardarFichas(0);
      await _abrirMesa(tester, [10, 10, 9, 7], almacen: almacen);
      await _esperar(tester, 300);
      await tester.tap(find.bySemanticsLabel('Aceptar 1.000 fichas'));
      await _esperar(tester, 1500);
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await _esperar(tester, 6000);
    });
  });
}
