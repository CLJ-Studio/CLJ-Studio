import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/diseno/pano_ruleta.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/almacen_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/cerebro_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conocimiento_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/controlador_chat_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/memoria_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_ruleta.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/sonidos_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_chat_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_ruleta.dart';

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

CerebroMacias _cerebro() => CerebroMacias(
  contexto: () => ContextoMacias(
    nombre: 'Juan',
    ahora: DateTime(2026, 10, 15, 15, 30),
    version: '1.0',
  ),
  azar: Random(2),
);

Future<void> _abrirRuleta(
  WidgetTester tester, {
  required AlmacenCasino almacen,
  List<int> numeros = const [17],
}) async {
  _comoTelefono(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaRuleta(
        nombre: 'Ana',
        almacen: almacen,
        sonidos: const SonidosMesa.mudos(),
        numeros: numeros,
      ),
    ),
  );
  await _esperar(tester, 400);
}

/// Apoya el dedo donde va esa apuesta en el paño, y lo levanta.
Future<void> _apostar(WidgetTester tester, Apuesta apuesta) async {
  final pano = tester.getRect(find.bySemanticsLabel('El paño de la ruleta'));
  final g = GeometriaPano(pano);
  final dedo = await tester.startGesture(g.lugar(apuesta));
  await tester.pump(const Duration(milliseconds: 50));
  await dedo.up();
  await _esperar(tester, 450);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('la palabra secreta', () {
    test('"casino" invita a entrar con un sí y un no', () {
      final respuesta = _cerebro().escribir('casino');
      expect(respuesta.intencion, 'juego:casino');
      expect(respuesta.burbujas.last.opciones.map((o) => o.id), [
        'o:casino_si',
        'o:casino_no',
      ]);
    });

    test('"blackjack" ya no es la palabra', () {
      expect(_cerebro().escribir('blackjack').intencion, isNot('juego:casino'));
    });

    test('decir que sí abre el casino y deja el botón para volver', () {
      final cerebro = _cerebro()..escribir('Casino!');
      final respuesta = cerebro.escribir('si');
      final burbuja = respuesta.burbujas.single;
      expect(burbuja.abrir, DestinoMacias.casino);
      expect(burbuja.acciones.single.destino, DestinoMacias.casino);
    });

    test('tocar el sí también lo abre', () {
      final cerebro = _cerebro();
      final invitacion = cerebro.escribir('vamos al casino');
      final respuesta = cerebro.elegir(invitacion.burbujas.last.opciones.first);
      expect(respuesta.burbujas.single.abrir, DestinoMacias.casino);
    });

    test('"no" lo deja para otro día', () {
      final cerebro = _cerebro()..escribir('casino');
      expect(cerebro.escribir('no').intencion, 'juego:fin');
    });

    test('es secreto: no está en el menú de juegos', () {
      final juegos = _cerebro().escribir('juguemos');
      expect(
        juegos.burbujas.last.opciones.map((o) => o.texto.toLowerCase()),
        isNot(contains(contains('casino'))),
      );
    });

    testWidgets('desde el chat, el sí abre el casino solo', (tester) async {
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
      await tester.enterText(find.byType(TextField), 'casino');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Opción 1: Sí, ¡entremos!'));
      await _esperar(tester, 1800);
      expect(find.byType(PantallaCasino), findsOneWidget);
      await tester.tap(find.byTooltip('Salir del casino'));
      await _esperar(tester, 6000);
      expect(find.byType(PantallaCasino), findsNothing);
    });
  });

  group('la entrada del casino', () {
    Future<AlmacenCasino> abrir(WidgetTester tester, {int? fichas}) async {
      _comoTelefono(tester);
      final almacen = AlmacenCasinoEnMemoria();
      if (fichas != null) await almacen.guardarFichas(fichas);
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaCasino(
            nombre: 'Ana',
            almacen: almacen,
            sonidos: const SonidosMesa.mudos(),
            sonidosDeMesas: const SonidosMesa.mudos(),
          ),
        ),
      );
      await _esperar(tester, 1600);
      return almacen;
    }

    testWidgets('muestra las tres mesas y tus fichas', (tester) async {
      await abrir(tester, fichas: 2500);
      expect(find.bySemanticsLabel('Tus fichas: 2500'), findsOneWidget);
      expect(find.bySemanticsLabel('Jugar a la ruleta'), findsOneWidget);
      expect(find.bySemanticsLabel('Jugar al blackjack'), findsOneWidget);
      expect(find.bySemanticsLabel('Póker, próximamente'), findsOneWidget);
      await _esperar(tester, 8000);
    });

    testWidgets('el póker todavía no abre: MacIAs avisa', (tester) async {
      await abrir(tester);
      await tester.tap(find.bySemanticsLabel('Póker, próximamente'));
      await _esperar(tester, 600);
      expect(find.byType(PantallaRuleta), findsNothing);
      expect(find.byType(PantallaBlackjack), findsNothing);
      await _esperar(tester, 8000);
    });

    testWidgets('las mesas comparten las fichas', (tester) async {
      await abrir(tester, fichas: 3210);
      await tester.tap(find.bySemanticsLabel('Jugar al blackjack'));
      await _esperar(tester, 1200);
      expect(find.byType(PantallaBlackjack), findsOneWidget);
      expect(find.bySemanticsLabel('Tus fichas: 3210'), findsOneWidget);
      await tester.tap(find.byTooltip('Salir de la mesa'));
      await _esperar(tester, 1200);
      await tester.tap(find.bySemanticsLabel('Jugar a la ruleta'));
      await _esperar(tester, 1200);
      expect(find.byType(PantallaRuleta), findsOneWidget);
      expect(find.bySemanticsLabel('Tus fichas: 3210'), findsOneWidget);
      await tester.tap(find.byTooltip('Salir de la mesa'));
      await _esperar(tester, 9000);
    });
  });

  group('la ruleta', () {
    testWidgets('un pleno al 17 paga 35 a 1', (tester) async {
      final almacen = AlmacenCasinoEnMemoria();
      await _abrirRuleta(tester, almacen: almacen);
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Ficha de 100'));
      await _esperar(tester, 200);
      await _apostar(tester, Apuesta.pleno(17));
      expect(find.bySemanticsLabel('Tus fichas: 900'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^Girar')));
      await _esperar(tester, 16000);
      expect(find.bySemanticsLabel('Tus fichas: 4500'), findsOneWidget);
      expect(find.text('Ganaste 3.500'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Últimos números: 17')),
        findsOneWidget,
      );
      expect(await almacen.fichas(), 4500);
      final guardado = MesaRuleta.desdeJson(await almacen.juego('ruleta'));
      expect(guardado.estadisticas.plenos, 1);
      expect(guardado.historial, [17]);
      await _esperar(tester, 6000);
    });

    testWidgets('si no sale, la casa se lleva la apuesta', (tester) async {
      final almacen = AlmacenCasinoEnMemoria();
      await _abrirRuleta(tester, almacen: almacen, numeros: [17]);
      await tester.tap(find.bySemanticsLabel('Ficha de 50'));
      await _esperar(tester, 200);
      await _apostar(tester, Apuesta.rojo());
      await _apostar(tester, Apuesta.caballo(0, 2));
      await tester.tap(find.bySemanticsLabel(RegExp('^Girar')));
      await _esperar(tester, 16000);
      expect(find.bySemanticsLabel('Tus fichas: 900'), findsOneWidget);
      expect(find.text('Perdiste 100'), findsOneWidget);
      await _esperar(tester, 6000);
    });

    testWidgets('deshacer y borrar devuelven las fichas', (tester) async {
      await _abrirRuleta(tester, almacen: AlmacenCasinoEnMemoria());
      await _apostar(tester, Apuesta.docena(0));
      await _apostar(tester, Apuesta.calle(3));
      await _apostar(tester, Apuesta.cuadro(16));
      expect(find.bySemanticsLabel('Tus fichas: 970'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Deshacer'));
      await _esperar(tester, 600);
      expect(find.bySemanticsLabel('Tus fichas: 980'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Borrar todo'));
      await _esperar(tester, 700);
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await _esperar(tester, 6000);
    });

    testWidgets('con el dedo apoyado dice qué apuesta es y cuánto paga', (
      tester,
    ) async {
      await _abrirRuleta(tester, almacen: AlmacenCasinoEnMemoria());
      final pano = tester.getRect(
        find.bySemanticsLabel('El paño de la ruleta'),
      );
      final g = GeometriaPano(pano);
      final dedo = await tester.startGesture(g.lugar(Apuesta.caballo(17, 20)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Caballo 17-20'), findsOneWidget);
      expect(find.text('Paga 17 a 1'), findsOneWidget);
      await dedo.cancel();
      await _esperar(tester, 6000);
    });

    testWidgets('la ficha ALL IN apuesta todo, sin tope de 5.000', (
      tester,
    ) async {
      final almacen = AlmacenCasinoEnMemoria();
      await almacen.guardarFichas(50000);
      await _abrirRuleta(tester, almacen: almacen, numeros: [17]);
      expect(find.bySemanticsLabel('Tus fichas: 50000'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('All in'));
      await _esperar(tester, 300);
      expect(find.textContaining('ALL IN · 50.000'), findsOneWidget);
      await _apostar(tester, Apuesta.negro());
      // Las fichas todavia viajan (un all in tarda un poco mas): "Girar"
      // espera a que lleguen.
      await _esperar(tester, 600);
      // Todas, hasta la ultima: no quedan fichas, y el all in se apaga solo.
      expect(find.bySemanticsLabel('Tus fichas: 0'), findsOneWidget);
      expect(find.textContaining('ALL IN ·'), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp('^Girar')));
      await _esperar(tester, 16000);
      // Salio el 17 (negro): la apuesta paga 1 a 1 sobre las 50.000.
      expect(find.bySemanticsLabel('Tus fichas: 100000'), findsOneWidget);
      expect(find.text('Ganaste 50.000'), findsOneWidget);
      expect(await almacen.fichas(), 100000);
      await _esperar(tester, 6000);
    });

    testWidgets('se puede poner mas de 5.000 en un mismo lugar', (
      tester,
    ) async {
      final almacen = AlmacenCasinoEnMemoria();
      await almacen.guardarFichas(20000);
      await _abrirRuleta(tester, almacen: almacen);
      await tester.tap(find.bySemanticsLabel('Ficha de 1.000'));
      await _esperar(tester, 200);
      for (var i = 0; i < 6; i++) {
        await _apostar(tester, Apuesta.rojo());
      }
      expect(find.bySemanticsLabel('Tus fichas: 14000'), findsOneWidget);
      expect(find.text('No te alcanzan las fichas'), findsNothing);
      await _esperar(tester, 6000);
    });

    testWidgets('sin fichas, MacIAs presta', (tester) async {
      final almacen = AlmacenCasinoEnMemoria();
      await almacen.guardarFichas(0);
      await _abrirRuleta(tester, almacen: almacen);
      await tester.tap(find.bySemanticsLabel('Aceptar 1.000 fichas'));
      await _esperar(tester, 1500);
      expect(find.bySemanticsLabel('Tus fichas: 1000'), findsOneWidget);
      await _esperar(tester, 6000);
    });
  });

  group('el paño', () {
    final g = GeometriaPano(const Rect.fromLTWH(6, 300, 400, 480));

    test('cada apuesta se hace tocando su lugar', () {
      final todas = [
        for (var n = 0; n <= 36; n++) Apuesta.pleno(n),
        for (var n = 1; n <= 36; n++)
          if (n % 3 != 0) Apuesta.caballo(n, n + 1),
        for (var n = 1; n <= 33; n++) Apuesta.caballo(n, n + 3),
        for (var n = 1; n <= 3; n++) Apuesta.caballo(0, n),
        for (var f = 0; f < 12; f++) Apuesta.calle(f),
        for (var n = 1; n <= 32; n++)
          if (n % 3 != 0) Apuesta.cuadro(n),
        for (var f = 0; f < 11; f++) Apuesta.linea(f),
        Apuesta.trio(conElUno: true),
        Apuesta.trio(conElUno: false),
        Apuesta.primerosCuatro(),
        for (var d = 0; d < 3; d++) Apuesta.docena(d),
        for (var c = 0; c < 3; c++) Apuesta.columna(c),
        ...GeometriaPano.exterioresEnOrden,
      ];
      for (final apuesta in todas) {
        expect(g.apuestaEn(g.lugar(apuesta)), apuesta, reason: apuesta.nombre);
      }
    });

    test('fuera del paño no hay apuesta', () {
      expect(g.apuestaEn(const Offset(2, 290)), isNull);
      expect(g.apuestaEn(Offset(g.exteriores.right + 20, 500)), isNull);
    });
  });

  group('el almacén del casino', () {
    test('las fichas del blackjack de antes pasan al casino', () async {
      SharedPreferences.setMockInitialValues({
        'macias.u1.blackjack': jsonEncode({
          'fichas': 2345,
          'estadisticas': {'manos': 12},
        }),
        'macias.blackjack.sonido': false,
      });
      final almacen = AlmacenCasinoLocal('u1');
      expect(await almacen.fichas(), 2345);
      expect((await almacen.juego('blackjack'))!['manos'], 12);
      expect(await almacen.conSonido(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('macias.u1.blackjack'), isFalse);
    });

    test('cada cuenta tiene sus fichas', () async {
      final ana = AlmacenCasinoLocal('ana');
      final beto = AlmacenCasinoLocal('beto');
      await ana.guardarFichas(5000);
      expect(await ana.fichas(), 5000);
      expect(await beto.fichas(), isNull);
      await ana.guardarJuego('ruleta', {'giros': 3});
      expect((await ana.juego('ruleta'))!['giros'], 3);
      expect(await beto.juego('ruleta'), isNull);
    });
  });
}
