import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/tiempo_real/consulta_compartida.dart';

/// El inicio bajaba la lista de locales tres veces cada vez que cargaba.
void main() {
  late int consultas;
  late Completer<int> respuesta;
  late DateTime ahora;
  late ConsultaCompartida<int> compartida;

  setUp(() {
    consultas = 0;
    respuesta = Completer<int>();
    ahora = DateTime(2026, 11, 12, 10);
    compartida = ConsultaCompartida<int>(() {
      consultas++;
      return respuesta.future;
    }, reloj: () => ahora);
  });

  test('tres llamadas juntas son una sola consulta', () async {
    final pedidas = [
      compartida.pedir(),
      compartida.pedir(),
      compartida.pedir(),
    ];
    respuesta.complete(7);

    expect(await Future.wait(pedidas), [7, 7, 7]);
    expect(consultas, 1);
  });

  test('una llamada despues de terminar trae datos frescos', () async {
    respuesta.complete(1);
    await compartida.pedir();

    respuesta = Completer<int>()..complete(2);
    expect(await compartida.pedir(), 2);
    expect(consultas, 2);
  });

  test(
    'si falla, fallan todas las que esperaban y la siguiente reintenta',
    () async {
      final pedidas = [compartida.pedir(), compartida.pedir()];
      respuesta.completeError(StateError('sin red'));
      for (final pedida in pedidas) {
        await expectLater(pedida, throwsStateError);
      }

      respuesta = Completer<int>()..complete(3);
      expect(await compartida.pedir(), 3);
      expect(consultas, 2);
    },
  );

  test('reciente reusa lo de hace poco y despues vuelve a preguntar', () async {
    respuesta.complete(1);
    await compartida.pedir();

    ahora = ahora.add(const Duration(seconds: 30));
    expect(await compartida.reciente(const Duration(minutes: 1)), 1);
    expect(consultas, 1);

    ahora = ahora.add(const Duration(minutes: 1));
    respuesta = Completer<int>()..complete(2);
    expect(await compartida.reciente(const Duration(minutes: 1)), 2);
    expect(consultas, 2);
  });
}
