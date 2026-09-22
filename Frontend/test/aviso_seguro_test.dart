import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/estados_aplicacion/aviso_seguro.dart';

/// Reproduce el fallo que aparecio la primera vez que la aplicacion corrio en
/// un telefono de verdad (un Samsung A15):
///
///   setState() or markNeedsBuild() called during build.
///
/// Hace falta que coincidan dos cosas en el mismo frame: un controlador que
/// avisa desde `initState` -o sea en plena construccion- y alguien
/// escuchandolo. Por eso no lo vio ni el analizador ni ninguna prueba de
/// pantalla suelta.
class _Controlador extends ChangeNotifier with AvisoSeguro {}

/// Arranca su carga desde initState, como hacen los controladores de verdad.
class _PantallaQueCarga extends StatefulWidget {
  const _PantallaQueCarga({required this.controlador, required this.seguro});

  final _Controlador controlador;

  /// Con `false` avisa a la brava, que es como estaba antes.
  final bool seguro;

  @override
  State<_PantallaQueCarga> createState() => _PantallaQueCargaState();
}

class _PantallaQueCargaState extends State<_PantallaQueCarga> {
  @override
  void initState() {
    super.initState();
    if (widget.seguro) {
      widget.controlador.avisar();
    } else {
      // ignore: invalid_use_of_protected_member
      widget.controlador.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _arbol(_Controlador controlador, {required bool seguro}) => MaterialApp(
  home: AnimatedBuilder(
    // Alguien escuchando mientras se construye: es la otra mitad del fallo.
    animation: controlador,
    builder: (_, _) =>
        _PantallaQueCarga(controlador: controlador, seguro: seguro),
  ),
);

void main() {
  testWidgets('avisar() desde initState no rompe la construccion', (
    tester,
  ) async {
    final controlador = _Controlador();
    addTearDown(controlador.dispose);

    await tester.pumpWidget(_arbol(controlador, seguro: true));
    expect(tester.takeException(), isNull);

    // Y el aviso no se pierde: llega al terminar el frame.
    var avisos = 0;
    controlador.addListener(() => avisos++);
    controlador.avisar();
    await tester.pump();
    expect(avisos, 1);
  });

  testWidgets('sin el, la construccion falla (asi estaba antes)', (
    tester,
  ) async {
    final controlador = _Controlador();
    addTearDown(controlador.dispose);

    await tester.pumpWidget(_arbol(controlador, seguro: false));

    // Si esto dejara de fallar, la prueba de arriba ya no probaria nada.
    //
    // No se exige un tipo concreto: en el telefono llega como FlutterError
    // ("setState() called during build") y en el banco de pruebas como una
    // asercion del framework. Lo que importa es que avisar a la brava
    // durante la construccion revienta, de una forma o de otra.
    expect(
      tester.takeException(),
      isNotNull,
      reason:
          'avisar a la brava durante la construccion tiene que seguir '
          'fallando; si no, la prueba de arriba no prueba nada',
    );
  });
}
