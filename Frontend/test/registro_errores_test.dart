import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/sesion/registro_errores.dart';

void main() {
  late List<Map<String, Object?>> enviados;
  late RegistroErrores registro;

  setUp(() {
    enviados = [];
    registro = RegistroErrores((datos) async => enviados.add(datos));
  });

  test('el mismo error se manda una sola vez por sesion', () async {
    final pila = StackTrace.current;
    registro
      ..anotar(StateError('se rompio'), pila)
      ..anotar(StateError('se rompio'), pila)
      ..anotar(StateError('otro'), pila);
    await Future<void>.delayed(Duration.zero);

    expect(enviados, hasLength(2));
    expect(enviados.first['p_mensaje'], 'Bad state: se rompio');
    expect(enviados.first['p_version'], isNotEmpty);
  });

  test('no manda mas de maximoPorSesion distintos', () async {
    for (var i = 0; i < 50; i++) {
      registro.anotar(StateError('error $i'), null);
    }
    await Future<void>.delayed(Duration.zero);

    expect(enviados, hasLength(RegistroErrores.maximoPorSesion));
  });

  test('recorta lo largo', () async {
    registro.anotar(StateError('x' * 3000), null, contexto: 'y' * 1000);
    await Future<void>.delayed(Duration.zero);

    expect((enviados.single['p_mensaje']! as String).length, 500);
    expect((enviados.single['p_contexto']! as String).length, 300);
  });

  test('si mandar falla, no rompe nada', () async {
    final fallaAlLlamar = RegistroErrores((_) => throw StateError('sin red'));
    final fallaDespues = RegistroErrores(
      (_) => Future<void>.error(StateError('sin red')),
    );

    fallaAlLlamar.anotar(StateError('a'), null);
    fallaDespues.anotar(StateError('b'), null);
    await Future<void>.delayed(Duration.zero);
  });
}
