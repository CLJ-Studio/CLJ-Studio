import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/campos_aplicacion/editor_variantes.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/variante_producto.dart';

/// "No me deja poner mas sabores". Lo que pasaba: el formulario guarda lo
/// que el editor le devuelve y se lo vuelve a pasar en cada redibujo. Las
/// filas vacias no se devuelven -una variante sin nombre no es nada-, asi que
/// tras tocar "Agregar otra" el editor tenia una fila mas de las que el
/// formulario sabia. Al primer redibujo (abrir el teclado alcanza) el editor
/// veia cantidades distintas, creia que el cambio venia de fuera y se
/// reiniciaba: la fila nueva desaparecia antes de poder escribir en ella.
class _Formulario extends StatefulWidget {
  const _Formulario();

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  List<VarianteEditable> variantes = const [];
  int redibujos = 0;

  /// Lo que hace el formulario real despues de publicar.
  void vaciar() => setState(() => variantes = const []);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            EditorVariantes(
              precioProducto: 10,
              variantes: variantes,
              alCambiar: (nuevas) => setState(() => variantes = nuevas),
            ),
            // Un redibujo del formulario por cualquier otro motivo, como el
            // que provoca el teclado al abrirse.
            TextButton(
              onPressed: () => setState(() => redibujos++),
              child: const Text('redibujar'),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('la fila nueva sobrevive a un redibujo del formulario', (
    tester,
  ) async {
    await tester.pumpWidget(const _Formulario());

    await tester.tap(find.text('Agregar una opción'));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2)); // nombre + precio

    // El formulario se redibuja antes de que se escriba nada.
    await tester.tap(find.text('redibujar'));
    await tester.pump();
    expect(
      find.byType(TextField),
      findsNWidgets(2),
      reason: 'la fila recien agregada no puede desaparecer',
    );
  });

  testWidgets('se pueden agregar varias, una tras otra', (tester) async {
    await tester.pumpWidget(const _Formulario());

    await tester.tap(find.text('Agregar una opción'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'chocolate');
    await tester.pump();

    await tester.tap(find.text('Agregar otra'));
    await tester.pump();
    await tester.tap(find.text('redibujar'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(2), 'vainilla');
    await tester.pump();

    await tester.tap(find.text('Agregar otra'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(4), 'frutilla');
    await tester.pump();

    final estado = tester.state<_FormularioState>(find.byType(_Formulario));
    expect(estado.variantes.map((v) => v.nombre), [
      'chocolate',
      'vainilla',
      'frutilla',
    ]);
  });

  testWidgets('si el formulario se vacia desde fuera, el editor tambien', (
    tester,
  ) async {
    // Despues de publicar, el formulario se limpia: el editor tiene que
    // seguirlo y no quedarse con las filas de la publicacion anterior.
    await tester.pumpWidget(const _Formulario());
    await tester.tap(find.text('Agregar una opción'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'chocolate');
    await tester.pump();

    final estado = tester.state<_FormularioState>(find.byType(_Formulario));
    estado.vaciar();
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
  });
}
