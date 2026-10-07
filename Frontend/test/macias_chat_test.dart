import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/diseno/burbujas_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/controlador_chat_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/memoria_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/pantalla/pantalla_chat_macias.dart';
import 'package:upsa_eat/funcionalidades/configuracion_usuario/pantalla/pantalla_ayuda.dart';

/// Del tamano de un telefono: en la pantalla de prueba por defecto (800 x
/// 600) casi nada entra y el chat baja solo hasta el ultimo mensaje.
void _comoTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Future<void> _abrirChat(
  WidgetTester tester, {
  RitmoMacias ritmo = const RitmoMacias(inmediato: true),
  AlmacenMacias? almacen,
}) async {
  _comoTelefono(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaChatMacias(
        ritmo: ritmo,
        almacen: almacen ?? AlmacenMaciasEnMemoria(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// El chat baja solo al ultimo mensaje; esto lo sube hasta el saludo.
Future<void> _subirAlPrincipio(WidgetTester tester) async {
  await tester.drag(
    find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.vertical,
    ),
    const Offset(0, 5000),
  );
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pumpAndSettle();
}

void main() {
  // Lo que abre Ayuda usa el almacen de verdad, que lee las preferencias.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('saluda y muestra el menu de doce opciones', (tester) async {
    await _abrirChat(tester);

    expect(find.bySemanticsLabel(RegExp(r'^Opción \d+:')), findsNWidgets(12));
    expect(
      find.bySemanticsLabel('Opción 12: Hablar con una persona'),
      findsOne,
    );

    await _subirAlPrincipio(tester);
    expect(find.textContaining('Soy ', findRichText: true), findsOneWidget);
  });

  testWidgets('la cabecera dice quien es y que esta verificado', (
    tester,
  ) async {
    await _abrirChat(tester);

    expect(find.text('MacIAs'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Verificado')), findsWidgets);
    expect(find.text('Asistente virtual de U market'), findsOneWidget);
  });

  testWidgets('tocar una opcion la manda y responde', (tester) async {
    await _abrirChat(tester);

    await tester.tap(find.bySemanticsLabel('Opción 3: Publicar para vender'));
    await tester.pumpAndSettle();

    // La burbuja propia con lo elegido, y la seccion abierta.
    expect(
      find.descendant(
        of: find.byType(BurbujaPropia, skipOffstage: false),
        matching: find.text('Publicar para vender', skipOffstage: false),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('¿Vas a vender algo?', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('escribir una pregunta la contesta', (tester) async {
    await _abrirChat(tester);
    await _escribir(tester, '¿cómo pongo sabores?');

    expect(
      find.text('¿cómo pongo sabores?', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Sabores o tamaños', findRichText: true),
      findsOneWidget,
    );
    // El campo queda vacio para la siguiente pregunta.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('el codigo sale en su bloque, con letra de codigo y Copiar', (
    tester,
  ) async {
    await _abrirChat(tester);
    await _escribir(tester, 'hola mundo en c++');

    expect(find.text('Copiar', skipOffstage: false), findsWidgets);
    final codigo = tester.widget<Text>(
      find.textContaining('#include <iostream>', skipOffstage: false).first,
    );
    expect(codigo.style?.fontFamily, TextoMacias.fuenteCodigo);
  });

  testWidgets('mientras prepara la respuesta se ve que escribe', (
    tester,
  ) async {
    _comoTelefono(tester);
    // Recien abierto, a ritmo normal: todavia esta escribiendo el saludo.
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaChatMacias(
          ritmo: const RitmoMacias(),
          almacen: AlmacenMaciasEnMemoria(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(EscribiendoMacias), findsOneWidget);
    expect(find.text('escribiendo…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(EscribiendoMacias), findsNothing);
    expect(find.text('Asistente virtual de U market'), findsOneWidget);
  });

  testWidgets('al volver, la conversacion sigue donde quedo', (tester) async {
    final almacen = AlmacenMaciasEnMemoria();
    await _abrirChat(tester, almacen: almacen);
    await _escribir(tester, 'me llamo Valeria');

    // Sale del chat y vuelve a entrar.
    await tester.pumpWidget(const SizedBox());
    await _abrirChat(tester, almacen: almacen);

    expect(find.text('me llamo Valeria', skipOffstage: false), findsOneWidget);
    // Sigue la misma conversacion: no la empieza de nuevo con otro saludo.
    expect(
      find.textContaining(
        'Qué bueno verte',
        findRichText: true,
        skipOffstage: false,
      ),
      findsNothing,
    );
    expect(
      find.textContaining('Mucho gusto, Valeria', findRichText: true),
      findsOneWidget,
    );
    // Y se acuerda del nombre.
    await _escribir(tester, 'como me llamo?');
    expect(
      find.textContaining('Te llamas Valeria', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('al volver despues de un examen, pregunta como le fue', (
    tester,
  ) async {
    final almacen = AlmacenMaciasEnMemoria();
    final hace2Dias = DateTime.now().subtract(const Duration(days: 2));
    await almacen.guardar(
      [
        MensajeMacias(
          id: 0,
          autor: AutorMensaje.persona,
          texto: 'tengo parcial de cálculo',
        ),
      ],
      MemoriaMacias(
        examenes: [
          ExamenMacias(materia: 'cálculo', fecha: hace2Dias, tipo: 'parcial'),
        ],
      ),
    );
    await _abrirChat(tester, almacen: almacen);

    expect(
      find.textContaining(
        '¿Cómo te fue en el parcial de cálculo',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await _escribir(tester, 'bien!');
    expect(
      find.textContaining('Felicidades', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('el menú de la cabecera ya no tiene modo meme', (tester) async {
    await _abrirChat(tester);
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();

    expect(find.text('Borrar la conversación'), findsOneWidget);
    expect(find.text('Olvidar lo que sabe de mí'), findsOneWidget);
    expect(find.text('Modo meme'), findsNothing);
  });

  testWidgets('desde Ayuda se llega a MacIAs', (tester) async {
    _comoTelefono(tester);
    await tester.pumpWidget(const MaterialApp(home: PantallaAyuda()));

    final boton = find.bySemanticsLabel(
      'Chatea con MacIAs, asistente virtual verificado',
    );
    expect(boton, findsOneWidget);
    // Lo de siempre sigue ahi.
    expect(find.text('Contactar a soporte'), findsOneWidget);
    expect(find.text('Preguntas frecuentes'), findsOneWidget);

    await tester.tap(boton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaChatMacias), findsOneWidget);
  });
}
