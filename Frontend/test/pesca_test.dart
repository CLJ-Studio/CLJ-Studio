import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_pesca.dart';

/// Una tirada armada a mano: para no depender del azar.
TiradaPesca _tirada(
  Casilla tipo, {
  Map<int, int> nieve = const {},
  ({Pez pez, int por})? moneda,
  double? pesca,
}) {
  final casilla = RuedaPesca.casillas.indexOf(tipo);
  return TiradaPesca(
    multiplicadores: Multiplicadores(nieve: nieve, moneda: moneda),
    casilla: casilla,
    pesca: pesca ?? (tipo.pez == null ? null : 5),
  );
}

void main() {
  group('la rueda', () {
    test('53 casillas: 23 y 23 de hielo, 4 azulitos, 2 naranjotes y 1 '
        'rojazo', () {
      expect(RuedaPesca.cantidad, 53);
      expect(RuedaPesca.cuantas(Casilla.hieloBlanco), 23);
      expect(RuedaPesca.cuantas(Casilla.hieloAzul), 23);
      expect(RuedaPesca.cuantas(Casilla.azulitos), 4);
      expect(RuedaPesca.cuantas(Casilla.naranjotes), 2);
      expect(RuedaPesca.cuantas(Casilla.rojazos), 1);
    });

    test('dos peces nunca quedan juntos, y el hielo se alterna', () {
      final rueda = RuedaPesca.casillas;
      for (var i = 0; i < rueda.length; i++) {
        final esta = rueda[i];
        final siguiente = rueda[(i + 1) % rueda.length];
        expect(esta.pez != null && siguiente.pez != null, isFalse);
        if (esta.esHielo && siguiente.esHielo) {
          expect(esta, isNot(siguiente), reason: 'casillas $i y ${i + 1}');
        }
      }
    });

    test('los peces van de 0,1 a su maximo', () {
      for (final pez in Pez.values) {
        final valores = [for (final (v, _) in pez.tabla) v];
        expect(valores.first, .1);
        expect(valores.last, pez.maximo);
      }
      expect(Pez.azulitos.maximo, 30);
      expect(Pez.naranjotes.maximo, 80);
      expect(Pez.rojazos.maximo, 150);
    });
  });

  group('lo que devuelve cada apuesta', () {
    test('la casa se queda un poco, como en la ruleta (entre 94 y 97 %)', () {
      for (final casilla in Casilla.values) {
        final devuelve = SorteoPesca.devolucion(casilla);
        expect(
          devuelve,
          inInclusiveRange(.94, .97),
          reason: '${casilla.nombre}: ${(devuelve * 100).toStringAsFixed(2)} %',
        );
      }
    });

    test('400.000 rondas al azar dan lo mismo que la cuenta', () {
      final azar = math.Random(7);
      const rondas = 400000;
      final cobrado = {for (final c in Casilla.values) c: 0.0};
      var conNieve = 0;
      var conMoneda = 0;
      for (var i = 0; i < rondas; i++) {
        final tirada = SorteoPesca.tirada(azar);
        if (tirada.multiplicadores.nieve.isNotEmpty) conNieve++;
        if (tirada.multiplicadores.moneda != null) conMoneda++;
        cobrado[tirada.tipo] = cobrado[tirada.tipo]! + 1 + tirada.pagaA1;
      }
      for (final casilla in Casilla.values) {
        final simulado = cobrado[casilla]! / rondas;
        // Cuatro desvios de lo que varia cada una en 400.000 rondas: los
        // peces grandes son raros y con la moneda llegan a pagar x300, asi
        // que varian mucho mas que el hielo.
        final margen = switch (casilla) {
          Casilla.hieloBlanco || Casilla.hieloAzul => .01,
          Casilla.azulitos => .04,
          Casilla.naranjotes => .055,
          Casilla.rojazos => .075,
        };
        expect(
          simulado,
          closeTo(SorteoPesca.devolucion(casilla), margen),
          reason: casilla.nombre,
        );
      }
      // Hay rondas sin multiplicadores y rondas con.
      expect(conNieve / rondas, closeTo(.8, .01));
      expect(conMoneda / rondas, closeTo(.35, .01));
    });
  });

  group('la mesa', () {
    test('el hielo paga 1 a 1, y con bola de nieve lo que diga', () {
      final mesa = MesaPesca(fichas: 1000)
        ..apostar(Casilla.hieloBlanco, 100)
        ..apostar(Casilla.hieloAzul, 50);
      final resultado = mesa.liquidar(_tirada(Casilla.hieloBlanco));
      expect(resultado.ganadoras.single.cobra, 200);
      expect(resultado.perdedoras.single.monto, 50);
      expect(mesa.fichas, 1050);

      final casilla = RuedaPesca.casillas.indexOf(Casilla.hieloAzul);
      mesa.apostar(Casilla.hieloAzul, 100);
      final conBola = mesa.liquidar(
        TiradaPesca(
          multiplicadores: Multiplicadores(nieve: {casilla: 5}),
          casilla: casilla,
        ),
      );
      expect(conBola.ganadoras.single.cobra, 600, reason: '100 + 5 a 1');
    });

    test('un pez paga lo que vale por la moneda, y la apuesta vuelve', () {
      final mesa = MesaPesca(fichas: 1000)..apostar(Casilla.rojazos, 100);
      final resultado = mesa.liquidar(
        _tirada(Casilla.rojazos, pesca: 20, moneda: (pez: Pez.rojazos, por: 3)),
      );
      expect(resultado.ganadoras.single.cobra, 100 + 100 * 60);

      // El mas chico: x0,1 de 15 es 1,5 fichas; la que no es entera queda.
      mesa.apostar(Casilla.azulitos, 15);
      final chico = mesa.liquidar(_tirada(Casilla.azulitos, pesca: .1));
      expect(chico.ganadoras.single.cobra, 16);
      // La moneda de otro pez no le suma.
      mesa.apostar(Casilla.azulitos, 100);
      final ajena = mesa.liquidar(
        _tirada(
          Casilla.azulitos,
          pesca: 10,
          moneda: (pez: Pez.naranjotes, por: 10),
        ),
      );
      expect(ajena.ganadoras.single.cobra, 1100);
    });

    test('a los tres peces de una, si alcanza', () {
      final mesa = MesaPesca(fichas: 100);
      expect(mesa.apostarALosPeces(50), isEmpty);
      expect(mesa.apostarALosPeces(30), hasLength(3));
      expect(mesa.fichas, 10);
      expect(mesa.montoEn(Casilla.naranjotes), 30);
    });

    test('deshacer, repetir y doblar', () {
      final mesa = MesaPesca(fichas: 1000)
        ..apostar(Casilla.hieloBlanco, 100)
        ..apostar(Casilla.azulitos, 50);
      expect(mesa.deshacer(), (Casilla.azulitos, 50));
      mesa.liquidar(_tirada(Casilla.hieloAzul));
      expect(mesa.repetir(), [(Casilla.hieloBlanco, 100)]);
      expect(mesa.doblar(), [(Casilla.hieloBlanco, 100)]);
      expect(mesa.montoEn(Casilla.hieloBlanco), 200);
    });

    test('lo que sale queda en el historial y en las estadisticas', () {
      final mesa = MesaPesca(fichas: 1000)..apostar(Casilla.naranjotes, 10);
      mesa.liquidar(_tirada(Casilla.naranjotes, pesca: 40));
      expect(mesa.historial.first, (casilla: Casilla.naranjotes, paga: 40.0));
      expect(mesa.estadisticas.bonos, 1);
      expect(mesa.estadisticas.mayorPesca, 40);
      expect(mesa.estadisticas.mayorPremio, 400);
    });

    test('se guarda y se recupera', () {
      final mesa = MesaPesca(fichas: 1000)..apostar(Casilla.rojazos, 20);
      mesa.liquidar(_tirada(Casilla.rojazos, pesca: .1));
      final copia = MesaPesca.desdeJson(mesa.aJson(), fichas: mesa.fichas);
      expect(copia.historial, mesa.historial);
      expect(copia.estadisticas.bonos, 1);
      expect(copia.repetir(), [(Casilla.rojazos, 20)]);
      expect(MesaPesca.desdeJson({'raro': true}, fichas: 5).fichas, 5);
    });

    test('se escribe como en la mesa', () {
      expect(textoPor(.1), 'x0,1');
      expect(textoPor(5), 'x5');
      expect(textoPor(1.5), 'x1,5');
    });
  });
}
