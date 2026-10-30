import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/diseno/bono_pesca.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/almacen_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_pesca.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/sonidos_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_pesca.dart';

void _comoTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Deja correr las animaciones, cuadro por cuadro.
Future<void> _esperar(WidgetTester tester, int milisegundos) async {
  for (var t = 0; t < milisegundos; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<AlmacenCasino> _abrir(
  WidgetTester tester, {
  required List<TiradaPesca> tiradas,
  int? fichas,
}) async {
  _comoTelefono(tester);
  final almacen = AlmacenCasinoEnMemoria();
  if (fichas != null) await almacen.guardarFichas(fichas);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaPesca(
        nombre: 'Ana',
        almacen: almacen,
        sonidos: const SonidosMesa.mudos(),
        tiradas: tiradas,
      ),
    ),
  );
  await _esperar(tester, 600);
  return almacen;
}

/// Toca y espera a que lleguen las fichas que salieron volando.
Future<void> _tocar(WidgetTester tester, Pattern etiqueta) async {
  await tester.tap(find.bySemanticsLabel(etiqueta));
  await _esperar(tester, 800);
}

void main() {
  group('el guion de la pesca', () {
    test('el medidor termina en lo pescado, y el pez sale entero', () {
      for (final pesca in [.1, .5, 2.0, 10.0, 25.0, 80.0, 150.0]) {
        final guion = GuionPesca(pesca: pesca);
        expect(guion.valor(0), .1);
        expect(guion.valor(guion.afuera), pesca);
        expect(guion.salida(1, guion.afuera), 1);
        expect(guion.fin, greaterThan(guion.afuera));
      }
    });

    test('el medidor nunca baja, ni con engaño', () {
      final guion = GuionPesca(pesca: 150, engano: 5);
      var antes = 0.0;
      for (var t = 0.0; t <= guion.fin; t += .01) {
        final valor = guion.valor(t);
        expect(valor, greaterThanOrEqualTo(antes - 1e-9), reason: '$t s');
        antes = valor;
      }
    });

    test('cada equipo llega cuando el pez pesa lo suyo', () {
      List<Equipo> equipos(double pesca) => [
        for (final llegada in GuionPesca(pesca: pesca).llegadas) llegada.equipo,
      ];
      expect(equipos(5), isEmpty);
      expect(equipos(10), [Equipo.grua]);
      expect(equipos(30), [Equipo.grua, Equipo.helicoptero]);
      expect(equipos(150), [
        Equipo.grua,
        Equipo.helicoptero,
        Equipo.carga,
        Equipo.robot,
      ]);
      // El robot solo puede salir por un rojazos.
      expect(Equipo.para(Pez.azulitos.maximo), Equipo.helicoptero);
      expect(Equipo.para(Pez.naranjotes.maximo), Equipo.carga);
      expect(Equipo.para(Pez.rojazos.maximo), Equipo.robot);
      // Mientras llega un equipo el medidor espera, y despues lo agarra.
      final guion = GuionPesca(pesca: 30);
      final grua = guion.llegadaDe(Equipo.grua)!;
      expect(guion.valor(grua.cuando + grua.dura / 2), 10);
      expect(guion.sostiene(grua.cuando), Equipo.cana);
      expect(guion.sostiene(grua.cuando + grua.dura), Equipo.grua);
      expect(guion.sostiene(guion.afuera), Equipo.helicoptero);
    });

    test('el engaño: solo naranjotes y rojazos grandes, y el chico vale '
        'poco', () {
      final azar = math.Random(3);
      var conEngano = 0;
      for (var i = 0; i < 400; i++) {
        expect(GuionPesca.elegirEngano(Pez.azulitos, 30, azar), isNull);
        expect(GuionPesca.elegirEngano(Pez.rojazos, 15, azar), isNull);
        final chico = GuionPesca.elegirEngano(Pez.naranjotes, 40, azar);
        if (chico != null) {
          conEngano++;
          expect(chico, inInclusiveRange(1, 8));
        }
      }
      // A veces si y a veces no.
      expect(conEngano, inInclusiveRange(150, 250));
    });

    test('con engaño, el chico sale entero antes de que lo trague el '
        'gigante', () {
      final guion = GuionPesca(pesca: 75, engano: 5);
      final chico = guion.chicoAfuera!;
      expect(guion.valor(chico), 5);
      expect(guion.salida(0, chico), 1);
      expect(guion.trago, greaterThan(chico));
      expect(guion.salida(1, guion.trago!), 0);
      expect(guion.valor(guion.afuera), 75);
    });

    test('el medidor se lee como en la mesa', () {
      expect(textoMedidor(.1), 'x0,1');
      expect(textoMedidor(.57), 'x0,5');
      expect(textoMedidor(37.8), 'x37');
      expect(textoMedidor(150), 'x150');
    });
  });

  group('la mesa de la pesca', () {
    testWidgets('un rojazos con moneda paga lo pescado por la moneda', (
      tester,
    ) async {
      final rojo = RuedaPesca.casillas.indexOf(Casilla.rojazos);
      final almacen = await _abrir(
        tester,
        tiradas: [
          TiradaPesca(
            multiplicadores: const Multiplicadores(
              moneda: (pez: Pez.rojazos, por: 3),
            ),
            casilla: rojo,
            pesca: 20,
          ),
        ],
      );
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await _tocar(tester, 'Ficha de 100');
      await _tocar(tester, RegExp('^Rojazos'));
      expect(find.bySemanticsLabel('Tus fichas: 900'), findsOneWidget);
      await _tocar(tester, RegExp('^Girar'));
      // La moneda, el giro y lo que salio: despues, el bono.
      await _esperar(tester, 15000);
      expect(find.byType(BonoPesca), findsOneWidget);
      await tester.tap(find.text('Saltar'));
      await _esperar(tester, 9000);
      expect(find.byType(BonoPesca), findsNothing);
      // La apuesta vuelve, y encima 100 x 20 x 3.
      expect(find.bySemanticsLabel('Tus fichas: 7000'), findsOneWidget);
      expect(find.text('Ganaste 6.000'), findsOneWidget);
      expect(await almacen.fichas(), 7000);
      final guardado = MesaPesca.desdeJson(await almacen.juego('pesca'));
      expect(guardado.estadisticas.bonos, 1);
      expect(guardado.historial.single.paga, 60);
      await _esperar(tester, 6000);
    });

    testWidgets('el hielo con bola de nieve paga lo que dice la bola', (
      tester,
    ) async {
      final azul = RuedaPesca.casillas.indexOf(Casilla.hieloAzul);
      await _abrir(
        tester,
        tiradas: [
          TiradaPesca(
            multiplicadores: Multiplicadores(nieve: {azul: 5}),
            casilla: azul,
          ),
        ],
      );
      await _tocar(tester, 'Ficha de 100');
      await _tocar(tester, RegExp('^Hielo azul'));
      await _tocar(tester, RegExp('^Hielo blanco'));
      expect(find.bySemanticsLabel('Tus fichas: 800'), findsOneWidget);
      await _tocar(tester, RegExp('^Girar'));
      await _esperar(tester, 16000);
      // Hielo azul: 100 + 500; el hielo blanco se pierde.
      expect(find.bySemanticsLabel('Tus fichas: 1400'), findsOneWidget);
      expect(find.text('Ganaste 400'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Lo último que salió: Hielo azul x5')),
        findsOneWidget,
      );
      await _esperar(tester, 6000);
    });

    testWidgets('"Todos" pone la ficha en los tres peces; deshacer y borrar '
        'la devuelven', (tester) async {
      await _abrir(
        tester,
        tiradas: [
          TiradaPesca(
            multiplicadores: Multiplicadores.ninguno,
            casilla: RuedaPesca.casillas.indexOf(Casilla.hieloBlanco),
          ),
        ],
      );
      await _tocar(tester, 'Ficha de 50');
      await _tocar(tester, RegExp('^Todos los peces'));
      expect(find.bySemanticsLabel('Tus fichas: 850'), findsOneWidget);
      await _tocar(tester, 'Deshacer');
      expect(find.bySemanticsLabel('Tus fichas: 900'), findsOneWidget);
      await _tocar(tester, 'Borrar todo');
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await _esperar(tester, 6000);
    });

    testWidgets('sin fichas, MacIAs presta', (tester) async {
      await _abrir(
        tester,
        fichas: 0,
        tiradas: [
          TiradaPesca(
            multiplicadores: Multiplicadores.ninguno,
            casilla: RuedaPesca.casillas.indexOf(Casilla.hieloBlanco),
          ),
        ],
      );
      await _tocar(tester, 'Aceptar 1.000 fichas');
      await _esperar(tester, 1000);
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await _esperar(tester, 6000);
    });
  });
}
