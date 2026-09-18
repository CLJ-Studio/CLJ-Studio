import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsa_eat/funcionalidades/acceso_upsa/arbol/arbol_acceso_upsa.dart';

/// Comprueba la primera pantalla que ve alguien al abrir la aplicación.
///
/// Se monta el acceso directamente, y no `ArbolAplicacion` entero, porque el
/// árbol completo pasa por el portón de autenticación y este pregunta por
/// `Supabase.instance` en su initState. En una prueba no hay servidor al que
/// conectarse, así que montarlo entero solo comprobaba que Supabase no estaba
/// inicializado.
void main() {
  setUp(() {
    // `CuentasRecordadas` y `CodigoPendiente` leen del dispositivo al arrancar
    // la pantalla. Sin esto, el complemento no responde en una prueba.
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> montarAcceso(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ArbolAccesoUpsa())),
    );
    // Una pasada mas: al arrancar se consulta el dispositivo, y hasta que esa
    // espera termina la pantalla todavia no esta como la ve el estudiante.
    await tester.pump();
  }

  testWidgets('pide el número de registro al abrir', (tester) async {
    await montarAcceso(tester);

    expect(find.text('Número de registro'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('el dominio institucional está a la vista', (tester) async {
    // El dominio va fijo dentro del campo: si se pudiera escribir entero,
    // alguien intentaria entrar con su correo personal y solo se enteraria
    // del rechazo despues de pedir el codigo.
    await montarAcceso(tester);

    expect(find.text('@estudiantes.upsa.edu.bo'), findsOneWidget);
  });

  testWidgets('no ofrece entrar con Google', (tester) async {
    // El acceso es por codigo al correo institucional. El boton de Google
    // quedo sin usarse, y esta prueba lo dejaba pasar porque fallaba antes,
    // al montar la aplicacion entera.
    await montarAcceso(tester);

    expect(find.text('Continuar con Google'), findsNothing);
  });
}
