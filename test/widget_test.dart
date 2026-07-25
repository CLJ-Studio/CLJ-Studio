import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/arbol_aplicacion/arbol_aplicacion.dart';

void main() {
  testWidgets('muestra el acceso UPSA al iniciar', (tester) async {
    await tester.pumpWidget(const ArbolAplicacion());

    expect(find.text('UPSA Eat'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('@estudiantes.upsa.edu.bo'), findsOneWidget);
  });
}
