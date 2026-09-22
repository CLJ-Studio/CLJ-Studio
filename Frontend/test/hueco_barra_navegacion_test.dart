import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/navegacion_principal/diseno/barra_navegacion_inferior.dart';

/// Cuanto hueco hace falta dejar abajo para que la barra flotante no tape el
/// contenido, y de donde sacarlo sin adivinar.
///
/// Trece pantallas llevaban su propio numero a ojo (96, 100, 110, 120, 126) y
/// ninguna sumaba el area segura del telefono, asi que en un movil con barra
/// de gestos el ultimo campo quedaba debajo de la barra de navegacion.
void main() {
  testWidgets('la barra mide mas que varios de los huecos escritos a mano', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BarraNavegacionInferior(
            indice: 0,
            alCambiar: (_) {},
          ),
        ),
      ),
    );

    final alto = tester.getSize(find.byType(BarraNavegacionInferior)).height;
    // Sin contar todavia el area segura del dispositivo.
    expect(alto, greaterThan(90));
  });

  testWidgets(
    'con extendBody, el cuerpo recibe el hueco en MediaQuery.padding',
    (tester) async {
      late double huecoInformado;

      // Un telefono con barra de gestos: 34 px de area segura abajo.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: MaterialApp(
            home: Scaffold(
              extendBody: true,
              bottomNavigationBar: BarraNavegacionInferior(
                indice: 0,
                alCambiar: (_) {},
              ),
              body: Builder(
                builder: (context) {
                  huecoInformado = MediaQuery.paddingOf(context).bottom;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      final alto = tester.getSize(find.byType(BarraNavegacionInferior)).height;

      // Esto es lo que justifica el arreglo: el propio Scaffold ya sabe
      // cuanto ocupa la barra y lo publica en el padding del cuerpo. No hay
      // que estimarlo en cada pantalla; hay que leerlo.
      expect(huecoInformado, alto);
      expect(huecoInformado, greaterThan(120));
    },
  );
}
