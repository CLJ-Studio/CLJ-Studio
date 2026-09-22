import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/campos_aplicacion/editor_variantes.dart';

/// El editor de sabores tiene que aguantar lo que la gente escribe de verdad:
/// nombres largos, pantallas angostas y la letra agrandada del sistema.
///
/// Flutter hace fallar la prueba sola si algo se desborda, asi que basta con
/// dibujarlo en las condiciones malas para que salte.
Widget _enPantalla(
  Widget hijo, {
  double ancho = 320,
  double escalaTexto = 1,
}) => MediaQuery(
  data: MediaQueryData(
    size: Size(ancho, 640),
    textScaler: TextScaler.linear(escalaTexto),
  ),
  child: MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(width: ancho, child: hijo),
      ),
    ),
  ),
);

void main() {
  testWidgets('en una pantalla angosta no se desborda', (tester) async {
    await tester.pumpWidget(
      _enPantalla(
        EditorVariantes(
          variantes: const ['chocolate', 'vainilla'],
          alCambiar: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('un sabor de nombre largo no rompe la fila', (tester) async {
    await tester.pumpWidget(
      _enPantalla(
        EditorVariantes(
          variantes: const ['chocolate con almendras y dulce de leche'],
          alCambiar: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('con la letra del sistema agrandada tampoco', (tester) async {
    await tester.pumpWidget(
      _enPantalla(
        EditorVariantes(
          variantes: const ['queso', 'carne', 'pollo', 'jamon y queso'],
          alCambiar: (_) {},
        ),
        escalaTexto: 1.6,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin titulo propio no dibuja encabezado', (tester) async {
    // El formulario de publicar lo envuelve en una tarjeta que ya dice
    // "Sabores o tamaños"; dos titulos pegados decian lo mismo dos veces.
    await tester.pumpWidget(
      _enPantalla(EditorVariantes(variantes: const [], alCambiar: (_) {})),
    );
    expect(find.text('Sabores o tamaños'), findsNothing);

    await tester.pumpWidget(
      _enPantalla(
        EditorVariantes(
          titulo: 'Sabores o tamaños',
          variantes: const [],
          alCambiar: (_) {},
        ),
      ),
    );
    expect(find.text('Sabores o tamaños'), findsOneWidget);
  });

  testWidgets('llegado al tope, el campo se bloquea y lo dice', (
    tester,
  ) async {
    final llenas = List.generate(maximoVariantes, (i) => 'sabor $i');
    await tester.pumpWidget(
      _enPantalla(EditorVariantes(variantes: llenas, alCambiar: (_) {})),
    );
    expect(find.text('Ya son $maximoVariantes opciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
