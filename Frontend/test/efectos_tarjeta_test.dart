import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/animaciones/escala_al_presionar.dart';
import 'package:upsa_eat/elementos_compartidos/imagenes/foto_producto.dart';

double _escala(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

Widget _tarjeta({VoidCallback? alTocar}) => EscalaAlPresionar(
  builder: (_, alResaltar) => Material(
    child: InkWell(
      onTap: alTocar ?? () {},
      onHighlightChanged: alResaltar,
      child: const SizedBox(width: 160, height: 200),
    ),
  ),
);

void main() {
  group('la tarjeta responde al dedo', () {
    testWidgets('se hunde mientras se mantiene presionada', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Center(child: _tarjeta())));
      expect(_escala(tester), 1);

      final gesto = await tester.startGesture(
        tester.getCenter(find.byType(InkWell)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(_escala(tester), lessThan(1));

      await gesto.up();
      await tester.pumpAndSettle();
      expect(_escala(tester), 1);
    });

    testWidgets('un toque rapido igual se alcanza a ver', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Center(child: _tarjeta())));

      // Bajar y subir en el mismo instante: el resaltado se enciende y se
      // apaga en el mismo cuadro.
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(_escala(tester), lessThan(1), reason: 'sigue hundida un momento');

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(_escala(tester), 1);
    });

    testWidgets('pasar la lista con el dedo no la hunde', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            children: [for (var i = 0; i < 6; i++) _tarjeta()],
          ),
        ),
      );

      final gesto = await tester.startGesture(
        tester.getCenter(find.byType(InkWell).first),
      );
      // Arranca a desplazar antes de que el toque se confirme.
      await gesto.moveBy(const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 150));
      for (final escala in tester.widgetList<AnimatedScale>(
        find.byType(AnimatedScale),
      )) {
        expect(escala.scale, 1);
      }
      await gesto.up();
      await tester.pumpAndSettle();
    });
  });

  group('la foto viaja de la tarjeta al detalle', () {
    const etiqueta = 'descubre-p1-imagen-producto-0';

    Future<void> abrir(WidgetTester tester) async {
      final navegador = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navegador,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 160,
                height: 120,
                child: FotoProductoViajera(
                  etiqueta: etiqueta,
                  radio: 16,
                  child: Container(
                    key: const ValueKey('foto de la tarjeta'),
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      navegador.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Hero(
              tag: etiqueta,
              child: Container(
                key: const ValueKey('foto del detalle'),
                width: 400,
                height: 300,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('en el vuelo se ve la foto de la tarjeta, ya cargada', (
      tester,
    ) async {
      await abrir(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Lo que vuela es la foto de la tarjeta; la del detalle (que en la app
      // todavia podria estar bajando) espera escondida a que aterrice.
      final enVuelo = find.descendant(
        of: find.byType(ClipRRect),
        matching: find.byKey(const ValueKey('foto de la tarjeta')),
      );
      expect(enVuelo, findsOneWidget);

      // Las esquinas se van enderezando en el camino.
      final recorte = tester.widget<ClipRRect>(
        find.ancestor(of: enVuelo, matching: find.byType(ClipRRect)).first,
      );
      final radio = (recorte.borderRadius as BorderRadius).topLeft.x;
      expect(radio, inExclusiveRange(0, 16));

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('foto del detalle')), findsOneWidget);
    });

    testWidgets('la etiqueta tiene la forma que usa el detalle', (
      tester,
    ) async {
      expect(etiquetaFotoProducto('descubre-p1', 0), etiqueta);
    });
  });
}
