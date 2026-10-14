import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/almacen_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/cerebro_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conocimiento_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/controlador_chat_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/memoria_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/sonidos_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_chat_macias.dart';

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
  AlmacenBlackjack? almacen,
}) async {
  _comoTelefono(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaBlackjack(
        nombre: 'Ana',
        sabot: Sabot.ordenado(_cartas(orden)),
        azar: Random(1),
        almacen: almacen ?? AlmacenBlackjackEnMemoria(),
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

CerebroMacias _cerebro() => CerebroMacias(
  contexto: () => ContextoMacias(
    nombre: 'Juan',
    ahora: DateTime(2026, 10, 7, 15, 30),
    version: '1.0',
  ),
  azar: Random(2),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('la palabra secreta', () {
    test('"blackjack" invita a jugar con un sí y un no', () {
      final respuesta = _cerebro().escribir('blackjack');
      expect(respuesta.intencion, 'juego:blackjack');
      expect(respuesta.burbujas.last.opciones.map((o) => o.id), [
        'o:blackjack_si',
        'o:blackjack_no',
      ]);
    });

    test('decir que sí abre la mesa y deja el botón para volver', () {
      final cerebro = _cerebro()..escribir('Blackjack!');
      final respuesta = cerebro.escribir('si');
      final burbuja = respuesta.burbujas.single;
      expect(burbuja.abrir, DestinoMacias.blackjack);
      expect(burbuja.acciones.single.destino, DestinoMacias.blackjack);
    });

    test('tocar el sí también la abre', () {
      final cerebro = _cerebro();
      final invitacion = cerebro.escribir('blackjack');
      final respuesta = cerebro.elegir(invitacion.burbujas.last.opciones.first);
      expect(respuesta.burbujas.single.abrir, DestinoMacias.blackjack);
    });

    test('"no" la deja para otro día', () {
      final cerebro = _cerebro()..escribir('blackjack');
      expect(cerebro.escribir('no').intencion, 'juego:fin');
    });

    test('es secreta: no está en el menú de juegos', () {
      final juegos = _cerebro().escribir('juguemos');
      expect(
        juegos.burbujas.last.opciones.map((o) => o.texto.toLowerCase()),
        isNot(contains(contains('blackjack'))),
      );
    });

    testWidgets('desde el chat, el sí abre la mesa sola', (tester) async {
      _comoTelefono(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaChatMacias(
            ritmo: const RitmoMacias(inmediato: true),
            almacen: AlmacenMaciasEnMemoria(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'blackjack');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Opción 1: Sí, ¡a jugar!'));
      await _esperar(tester, 1600);
      expect(find.byType(PantallaBlackjack), findsOneWidget);
      // Se cierra la mesa: el chat sigue ahí.
      await tester.tap(find.byTooltip('Salir de la mesa'));
      await _esperar(tester, 6000);
      expect(find.byType(PantallaBlackjack), findsNothing);
    });
  });

  group('la mesa', () {
    testWidgets('una mano entera: apostar, repartir, plantarse y cobrar', (
      tester,
    ) async {
      final almacen = AlmacenBlackjackEnMemoria();
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
      final guardado = await almacen.cargar();
      expect(guardado!.fichas, 1100);
      expect(guardado.estadisticas.ganadas, 1);
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
      final almacen = AlmacenBlackjackEnMemoria();
      await almacen.guardar(0, EstadisticasBlackjack());
      await _abrirMesa(tester, [10, 10, 9, 7], almacen: almacen);
      await _esperar(tester, 300);
      await tester.tap(find.bySemanticsLabel('Aceptar 1.000 fichas'));
      await _esperar(tester, 1500);
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await _esperar(tester, 6000);
    });
  });
}
