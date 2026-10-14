import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/estrategia_blackjack.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/frases_crupier.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_blackjack.dart';

/// Cartas por su rango (1 es el As, 11-13 las figuras). Los palos van
/// rotando: para las cuentas no importan.
List<Carta> _cartas(List<int> rangos) => [
  for (final (i, rango) in rangos.indexed)
    Carta(rango, Palo.values[i % 4], 1000 + i),
];

Mano _mano(List<int> rangos) => Mano()..cartas.addAll(_cartas(rangos));

/// Una mesa con el sabot en este orden: jugador, crupier (visible), jugador,
/// crupier (tapada), y despues lo que se pida.
MesaBlackjack _mesa(List<int> orden, {int apuesta = 100, int fichas = 1000}) {
  final mesa = MesaBlackjack(
    fichas: fichas,
    sabot: Sabot.ordenado(_cartas(orden)),
  )..sumar(apuesta);
  while (mesa.apuesta < apuesta) {
    mesa.sumar(MesaBlackjack.valoresFichas.first);
  }
  return mesa;
}

/// Reparte las cuatro primeras cartas como lo hace la pantalla.
void _repartir(MesaBlackjack mesa) {
  mesa
    ..empezar()
    ..darAJugador()
    ..darACrupier()
    ..darAJugador()
    ..darACrupier()
    ..trasRepartir();
}

/// Juega el crupier hasta plantarse.
void _turnoCrupier(MesaBlackjack mesa) {
  mesa.revelar();
  while (mesa.crupierDebePedir) {
    mesa.crupierPide();
  }
  mesa.terminarCrupier();
}

void main() {
  group('el valor de una mano', () {
    test('el As vale 11 mientras no se pase', () {
      expect(_mano([1, 13]).total, 21);
      expect(_mano([1, 13]).esBlackjack, isTrue);
      expect(_mano([1, 6]).total, 17);
      expect(_mano([1, 6]).blanda, isTrue);
      expect(_mano([1, 6]).totalDicho, '7 / 17');
      expect(_mano([1, 6, 10]).total, 17);
      expect(_mano([1, 6, 10]).blanda, isFalse);
      expect(_mano([1, 1]).total, 12);
      expect(_mano([1, 1, 9]).total, 21);
      expect(_mano([13, 12, 2]).sePaso, isTrue);
    });

    test('un 21 de tres cartas no es blackjack', () {
      expect(_mano([7, 7, 7]).total, 21);
      expect(_mano([7, 7, 7]).esBlackjack, isFalse);
    });
  });

  group('el sabot', () {
    test('seis mazos completos, cada carta distinta', () {
      final sabot = Sabot(azar: Random(1));
      final cartas = [for (var i = 0; i < 312; i++) sabot.sacar()];
      expect(cartas.map((c) => c.id).toSet(), hasLength(312));
      for (var rango = 1; rango <= 13; rango++) {
        expect(cartas.where((c) => c.rango == rango), hasLength(24));
      }
    });

    test('se baraja al salir la carta de corte, entre el 70 y el 80 %', () {
      final sabot = Sabot(azar: Random(2));
      var sacadas = 0;
      while (!sabot.tocaBarajar) {
        sabot.sacar();
        sacadas++;
      }
      expect(sacadas / 312, inInclusiveRange(.69, .81));
    });

    test('dos sabots de verdad nunca salen iguales', () {
      final uno = Sabot();
      final otro = Sabot();
      final a = [for (var i = 0; i < 20; i++) uno.sacar().toString()];
      final b = [for (var i = 0; i < 20; i++) otro.sacar().toString()];
      expect(a, isNot(b));
    });
  });

  group('una ronda', () {
    test('19 contra 17: gana el jugador y cobra el doble', () {
      final mesa = _mesa([10, 10, 9, 7]);
      _repartir(mesa);
      expect(mesa.fase, FaseMesa.jugando);
      expect(mesa.fichas, 900);
      mesa.plantarse();
      expect(mesa.fase, FaseMesa.crupier);
      _turnoCrupier(mesa);
      expect(mesa.resultados.single.desenlace, Desenlace.gana);
      expect(mesa.fichas, 1100);
      expect(mesa.netoRonda, 100);
    });

    test('el crupier se planta en un 17 blando', () {
      final mesa = _mesa([10, 1, 8, 6, 5]);
      _repartir(mesa);
      mesa
        ..decidirSeguro(tomar: false)
        ..plantarse();
      _turnoCrupier(mesa);
      expect(mesa.crupier.cartas, hasLength(2));
      expect(mesa.resultados.single.desenlace, Desenlace.gana);
    });

    test('el crupier pide con 16', () {
      final mesa = _mesa([10, 10, 8, 6, 5]);
      _repartir(mesa);
      mesa.plantarse();
      _turnoCrupier(mesa);
      expect(mesa.crupier.total, 21);
      expect(mesa.resultados.single.desenlace, Desenlace.pierde);
      expect(mesa.fichas, 900);
    });

    test('el blackjack paga 3 a 2 y termina la mano', () {
      final mesa = _mesa([1, 9, 13, 7]);
      _repartir(mesa);
      expect(mesa.fase, FaseMesa.resultado);
      expect(mesa.resultados.single.desenlace, Desenlace.blackjack);
      expect(mesa.fichas, 1150);
    });

    test('con un As a la vista se ofrece seguro, y paga 2 a 1', () {
      final mesa = _mesa([10, 1, 9, 13]);
      _repartir(mesa);
      expect(mesa.fase, FaseMesa.seguro);
      expect(mesa.costoSeguro, 50);
      mesa.decidirSeguro(tomar: true);
      expect(mesa.fase, FaseMesa.resultado);
      expect(mesa.resultados.single.desenlace, Desenlace.pierde);
      expect(mesa.pagoSeguro, 150);
      // Perdio 100 de la mano, el seguro le devolvio 150 por 50: queda igual.
      expect(mesa.fichas, 1000);
    });

    test('si el crupier no tiene blackjack, el seguro se pierde', () {
      final mesa = _mesa([10, 1, 9, 5]);
      _repartir(mesa);
      mesa.decidirSeguro(tomar: true);
      expect(mesa.fase, FaseMesa.jugando);
      expect(mesa.fichas, 850);
    });

    test('con un 10 a la vista el crupier espia: su blackjack gana ya', () {
      final mesa = _mesa([10, 13, 9, 1]);
      _repartir(mesa);
      expect(mesa.fase, FaseMesa.resultado);
      expect(mesa.resultados.single.desenlace, Desenlace.pierde);
    });

    test('blackjack contra blackjack es empate', () {
      final mesa = _mesa([1, 13, 12, 1]);
      _repartir(mesa);
      mesa.decidirSeguro(tomar: false);
      expect(mesa.resultados.single.desenlace, Desenlace.empata);
      expect(mesa.fichas, 1000);
    });

    test('pasarse pierde sin que el crupier juegue', () {
      final mesa = _mesa([10, 10, 6, 7, 9]);
      _repartir(mesa);
      mesa.pedir();
      expect(mesa.fase, FaseMesa.resultado);
      expect(mesa.resultados.single.desenlace, Desenlace.sePaso);
      expect(mesa.crupier.cartas, hasLength(2));
    });

    test('llegar a 21 pidiendo planta la mano sola', () {
      final mesa = _mesa([10, 10, 6, 7, 5]);
      _repartir(mesa);
      mesa.pedir();
      expect(mesa.fase, FaseMesa.crupier);
    });
  });

  group('las jugadas', () {
    test('doblar: una carta, el doble de apuesta', () {
      final mesa = _mesa([5, 10, 6, 7, 10]);
      _repartir(mesa);
      expect(mesa.puedeDoblar, isTrue);
      mesa.doblar();
      expect(mesa.manos.single.apuesta, 200);
      expect(mesa.manos.single.cartas, hasLength(3));
      expect(mesa.fase, FaseMesa.crupier);
      _turnoCrupier(mesa);
      expect(mesa.fichas, 1200);
    });

    test('dividir un par: dos manos con su apuesta', () {
      final mesa = _mesa([8, 10, 8, 9, 3, 10]);
      _repartir(mesa);
      expect(mesa.puedeDividir, isTrue);
      mesa.dividir();
      expect(mesa.manos, hasLength(2));
      expect(mesa.fichas, 800);
      expect(mesa.manoNecesitaCarta, isTrue);
      mesa
        ..darAJugador()
        ..completarDivision();
      expect(mesa.mano.total, 11);
      // Doblar despues de dividir esta permitido.
      expect(mesa.puedeDoblar, isTrue);
      mesa.plantarse();
      expect(mesa.manoActual, 1);
      expect(mesa.manoNecesitaCarta, isTrue);
      mesa
        ..darAJugador()
        ..completarDivision();
      expect(mesa.mano.total, 18);
      mesa.plantarse();
      expect(mesa.fase, FaseMesa.crupier);
    });

    test('se puede volver a dividir hasta cuatro manos', () {
      final mesa = _mesa([8, 10, 8, 9, 8, 8, 8, 2, 2, 2, 2]);
      _repartir(mesa);
      mesa.dividir();
      mesa.darAJugador();
      mesa.completarDivision();
      expect(mesa.puedeDividir, isTrue);
      mesa.dividir();
      mesa.darAJugador();
      mesa.completarDivision();
      mesa.dividir();
      expect(mesa.manos, hasLength(4));
      mesa.darAJugador();
      mesa.completarDivision();
      expect(mesa.puedeDividir, isFalse);
    });

    test('los ases divididos reciben una sola carta', () {
      final mesa = _mesa([1, 10, 1, 7, 13, 9]);
      _repartir(mesa);
      mesa.dividir();
      mesa
        ..darAJugador()
        ..completarDivision();
      // A + K despues de dividir: 21, pero no blackjack, y se planta solo.
      expect(mesa.manoActual, 1);
      mesa
        ..darAJugador()
        ..completarDivision();
      expect(mesa.fase, FaseMesa.crupier);
      _turnoCrupier(mesa);
      expect(mesa.resultados.map((r) => r.desenlace), [
        Desenlace.gana,
        Desenlace.gana,
      ]);
      // Paga 1 a 1, no 3 a 2.
      expect(mesa.fichas, 1200);
    });

    test('rendirse devuelve la mitad, y solo al principio', () {
      final mesa = _mesa([10, 10, 6, 9]);
      _repartir(mesa);
      expect(mesa.puedeRendirse, isTrue);
      mesa.rendirse();
      expect(mesa.fase, FaseMesa.resultado);
      expect(mesa.resultados.single.desenlace, Desenlace.rendida);
      expect(mesa.fichas, 950);
    });

    test('no se dobla ni divide sin fichas', () {
      final mesa = _mesa([8, 10, 8, 9], apuesta: 600, fichas: 1000);
      _repartir(mesa);
      expect(mesa.puedeDoblar, isFalse);
      expect(mesa.puedeDividir, isFalse);
    });
  });

  group('la apuesta', () {
    test('se arma con fichas y respeta lo que hay', () {
      final mesa = MesaBlackjack(fichas: 120);
      mesa
        ..sumar(100)
        ..sumar(50);
      expect(mesa.apuesta, 100);
      mesa.sumar(10);
      expect(mesa.apuesta, 110);
      mesa.irConTodo();
      expect(mesa.apuesta, 120);
      mesa.borrarApuesta();
      expect(mesa.puedeRepartir, isFalse);
    });

    test('sin fichas, la casa presta', () {
      final mesa = MesaBlackjack(fichas: 0);
      expect(mesa.enQuiebra, isTrue);
      mesa.rescatar();
      expect(mesa.fichas, MesaBlackjack.fichasIniciales);
      expect(mesa.estadisticas.rescates, 1);
    });
  });

  group('las estadisticas', () {
    test('cuentan manos, blackjacks y rachas', () {
      final mesa = _mesa([1, 9, 13, 7, 10, 10, 9, 7]);
      _repartir(mesa);
      mesa
        ..nuevaRonda()
        ..sumar(100);
      _repartir(mesa);
      mesa.plantarse();
      _turnoCrupier(mesa);
      final e = mesa.estadisticas;
      expect(e.manos, 2);
      expect(e.ganadas, 2);
      expect(e.blackjacks, 1);
      expect(e.rachaActual, 2);
      expect(e.mejorRacha, 2);
      expect(e.mayorPremio, 150);
      expect(EstadisticasBlackjack.desdeJson(e.aJson()).blackjacks, 1);
    });
  });

  group('la estrategia de MacIAs', () {
    Jugada? consejo(List<int> jugador, int suya) {
      final mesa = _mesa([jugador[0], suya, jugador[1], 7]);
      _repartir(mesa);
      if (mesa.fase == FaseMesa.seguro) mesa.decidirSeguro(tomar: false);
      return EstrategiaBlackjack.para(mesa)?.jugada;
    }

    test('las jugadas de manual', () {
      expect(consejo([10, 6], 10), Jugada.rendirse);
      expect(consejo([10, 6], 6), Jugada.plantarse);
      expect(consejo([10, 5], 9), Jugada.pedir);
      expect(consejo([6, 5], 6), Jugada.doblar);
      expect(consejo([8, 8], 10), Jugada.dividir);
      expect(consejo([1, 1], 6), Jugada.dividir);
      expect(consejo([13, 12], 6), Jugada.plantarse);
      expect(consejo([10, 2], 4), Jugada.plantarse);
      expect(consejo([10, 2], 2), Jugada.pedir);
      expect(consejo([1, 7], 3), Jugada.doblar);
      expect(consejo([1, 7], 8), Jugada.plantarse);
      expect(consejo([1, 7], 9), Jugada.pedir);
      expect(consejo([5, 5], 6), Jugada.doblar);
      expect(consejo([9, 9], 7), Jugada.plantarse);
    });

    test('siempre explica por que', () {
      final mesa = _mesa([10, 10, 6, 7]);
      _repartir(mesa);
      expect(EstrategiaBlackjack.para(mesa)!.porque, contains('16'));
    });
  });

  group('lo que dice MacIAs', () {
    test('cada momento tiene frases y no repite las ultimas', () {
      for (final momento in MomentoCrupier.values) {
        expect(FrasesCrupier.frases[momento], isNotEmpty, reason: '$momento');
      }
      final frases = FrasesCrupier(azar: Random(4), nombre: 'Juan');
      final dichas = [
        for (var i = 0; i < 6; i++) frases.decir(MomentoCrupier.reparto),
      ];
      expect(dichas.toSet(), hasLength(6));
    });

    test('usa el nombre, o lo omite si no hay', () {
      final con = FrasesCrupier(azar: Random(1), nombre: 'Ana');
      final sin = FrasesCrupier(azar: Random(1));
      for (var i = 0; i < 8; i++) {
        expect(con.decir(MomentoCrupier.ganaste), isNot(contains('{n}')));
        expect(sin.decir(MomentoCrupier.ganaste), isNot(contains('{n}')));
      }
    });
  });
}
