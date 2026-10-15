import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/casino.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_ruleta.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/trayectoria_bola.dart';

/// La diferencia entre dos angulos, entre -pi y pi.
double _diferencia(double a, double b) {
  final d = (a - b) % (2 * math.pi);
  return d > math.pi ? d - 2 * math.pi : d;
}

void main() {
  group('la rueda', () {
    test('tiene los 37 numeros, una vez cada uno', () {
      expect(ordenRueda, hasLength(37));
      expect(ordenRueda.toSet(), {for (var n = 0; n <= 36; n++) n});
      expect(ordenRueda.first, 0);
    });

    test('los colores se alternan alrededor del cilindro', () {
      for (var i = 1; i < 36; i++) {
        expect(
          colorDe(ordenRueda[i]),
          isNot(colorDe(ordenRueda[i + 1])),
          reason: 'entre ${ordenRueda[i]} y ${ordenRueda[i + 1]}',
        );
      }
      final rojos = [
        for (var n = 1; n <= 36; n++) n,
      ].where((n) => colorDe(n) == ColorRuleta.rojo);
      expect(rojos, hasLength(18));
      expect(colorDe(0), ColorRuleta.verde);
      expect(colorDe(32), ColorRuleta.rojo);
      expect(colorDe(26), ColorRuleta.negro);
    });

    test('el crupier canta el numero', () {
      expect(numeroDicho(17), '17 negro');
      expect(numeroDicho(32), '32 rojo');
      expect(numeroDicho(0), 'cero');
      expect(detalleNumero(17), 'Negro · Impar · Falta');
      expect(detalleNumero(36), 'Rojo · Par · Pasa');
    });
  });

  group('las apuestas', () {
    final todas = [
      for (var n = 0; n <= 36; n++) Apuesta.pleno(n),
      Apuesta.caballo(0, 2),
      Apuesta.caballo(17, 20),
      Apuesta.caballo(17, 18),
      for (var f = 0; f < 12; f++) Apuesta.calle(f),
      Apuesta.trio(conElUno: true),
      Apuesta.trio(conElUno: false),
      Apuesta.cuadro(1),
      Apuesta.cuadro(32),
      Apuesta.primerosCuatro(),
      for (var f = 0; f < 11; f++) Apuesta.linea(f),
      for (var d = 0; d < 3; d++) Apuesta.docena(d),
      for (var c = 0; c < 3; c++) Apuesta.columna(c),
      Apuesta.rojo(),
      Apuesta.negro(),
      Apuesta.par(),
      Apuesta.impar(),
      Apuesta.falta(),
      Apuesta.pasa(),
    ];

    test('cada una paga lo justo para lo que cubre (36 / n - 1)', () {
      for (final apuesta in todas) {
        expect(
          apuesta.tipo.paga,
          36 ~/ apuesta.numeros.length - 1,
          reason: apuesta.nombre,
        );
        expect(36 % apuesta.numeros.length, 0, reason: apuesta.nombre);
      }
    });

    test('cubren los numeros de su lugar en el paño', () {
      expect(Apuesta.calle(5).numeros, [16, 17, 18]);
      expect(Apuesta.cuadro(16).numeros, [16, 17, 19, 20]);
      expect(Apuesta.linea(0).numeros, [1, 2, 3, 4, 5, 6]);
      expect(Apuesta.columna(0).numeros.take(3), [1, 4, 7]);
      expect(Apuesta.columna(2).numeros.last, 36);
      expect(Apuesta.docena(1).numeros.first, 13);
      expect(Apuesta.rojo().numeros, contains(1));
      expect(Apuesta.rojo().gana(0), isFalse);
      expect(Apuesta.par().gana(0), isFalse);
    });

    test('solo hay caballos y cuadros entre vecinos', () {
      expect(() => Apuesta.caballo(3, 4), throwsArgumentError);
      expect(() => Apuesta.caballo(1, 5), throwsArgumentError);
      expect(() => Apuesta.caballo(0, 4), throwsArgumentError);
      expect(() => Apuesta.cuadro(3), throwsArgumentError);
      expect(() => Apuesta.cuadro(33), throwsArgumentError);
      expect(Apuesta.caballo(20, 17), Apuesta.caballo(17, 20));
    });

    test('se recuperan desde su clave, y nada invalido', () {
      for (final apuesta in todas) {
        expect(Apuesta.desdeClave(apuesta.clave), apuesta);
      }
      expect(Apuesta.desdeClave('pleno:40'), isNull);
      expect(Apuesta.desdeClave('caballo:3-4'), isNull);
      expect(Apuesta.desdeClave('rojo:1-2'), isNull);
      expect(Apuesta.desdeClave('nada'), isNull);
    });
  });

  group('la mesa', () {
    test('apostar saca de tus fichas y deshacer las devuelve', () {
      final mesa = MesaRuleta(fichas: 1000);
      expect(mesa.apostar(Apuesta.pleno(17), 100), isTrue);
      expect(mesa.apostar(Apuesta.pleno(17), 50), isTrue);
      expect(mesa.apostar(Apuesta.rojo(), 10), isTrue);
      expect(mesa.fichas, 840);
      expect(mesa.enMesa, 160);
      expect(mesa.montoEn(Apuesta.pleno(17)), 150);
      expect(mesa.deshacer(), (Apuesta.rojo(), 10));
      expect(mesa.deshacer(), (Apuesta.pleno(17), 50));
      expect(mesa.montoEn(Apuesta.pleno(17)), 100);
      mesa.borrar();
      expect(mesa.fichas, 1000);
      expect(mesa.hayApuestas, isFalse);
    });

    test('no se apuesta lo que no hay, pero si hasta la ultima ficha', () {
      final mesa = MesaRuleta(fichas: 100);
      expect(mesa.apostar(Apuesta.negro(), 500), isFalse);
      expect(mesa.apostar(Apuesta.negro(), 5), isFalse);
      // Sin tope por lugar: tampoco el de las 5.000 de antes.
      final rica = MesaRuleta(fichas: 20000);
      expect(rica.apostar(Apuesta.negro(), 5000), isTrue);
      expect(rica.apostar(Apuesta.negro(), 5000), isTrue);
      expect(rica.apostar(Apuesta.negro(), 10000), isTrue);
      expect(rica.montoEn(Apuesta.negro()), 20000);
      expect(rica.fichas, 0);
    });

    test('el all in pone todas las fichas, sean las que sean', () {
      final rica = MesaRuleta(fichas: 2345670);
      expect(rica.puedeIrConTodo, isTrue);
      expect(rica.apostar(Apuesta.pleno(7), rica.todo), isTrue);
      expect(rica.fichas, 0);
      expect(rica.montoEn(Apuesta.pleno(7)), 2345670);
      final resultado = rica.liquidar(7);
      expect(resultado.cobrado, 2345670 * 36);
      expect(rica.fichas, 2345670 * 36);

      // Tambien las que no son multiplo de 10 (queda un 5 despues de un 3 a 2).
      final chica = MesaRuleta(fichas: 25);
      expect(chica.apostar(Apuesta.rojo(), chica.todo), isTrue);
      expect(chica.fichas, 0);
      expect(chica.liquidar(1).cobrado, 50);

      // Con menos de la apuesta minima no hay all in.
      expect(MesaRuleta(fichas: 5).puedeIrConTodo, isFalse);
    });

    test('doblar no tiene tope', () {
      final mesa = MesaRuleta(fichas: 30000)
        ..apostar(Apuesta.docena(0), 5000)
        ..apostar(Apuesta.rojo(), 5000);
      expect(mesa.puedeDoblar, isTrue);
      mesa.doblar();
      expect(mesa.montoEn(Apuesta.docena(0)), 10000);
      expect(mesa.montoEn(Apuesta.rojo()), 10000);
      expect(mesa.fichas, 10000);
    });

    test('un pleno paga 35 a 1 y lo demas se pierde', () {
      final mesa = MesaRuleta(fichas: 1000)
        ..apostar(Apuesta.pleno(17), 10)
        ..apostar(Apuesta.rojo(), 100)
        ..apostar(Apuesta.impar(), 50);
      final resultado = mesa.liquidar(17);
      expect(resultado.cobrado, 10 * 36 + 50 * 2);
      expect(resultado.perdedoras.single.apuesta, Apuesta.rojo());
      expect(mesa.fichas, 1000 - 160 + 460);
      expect(resultado.neto, 300);
      expect(resultado.acertoPleno, isTrue);
      expect(mesa.historial, [17]);
      expect(mesa.estadisticas.plenos, 1);
      expect(mesa.estadisticas.mayorPremio, 300);
    });

    test('con el cero pierden las de afuera', () {
      final mesa = MesaRuleta(fichas: 1000)
        ..apostar(Apuesta.rojo(), 100)
        ..apostar(Apuesta.par(), 100)
        ..apostar(Apuesta.primerosCuatro(), 10);
      final resultado = mesa.liquidar(0);
      expect(resultado.cobrado, 90);
      expect(mesa.fichas, 1000 - 210 + 90);
      expect(mesa.estadisticas.ganados, 0);
    });

    test('repetir y doblar la ronda', () {
      final mesa = MesaRuleta(fichas: 1000)
        ..apostar(Apuesta.docena(0), 100)
        ..apostar(Apuesta.cuadro(1), 20);
      mesa.liquidar(36);
      expect(mesa.puedeRepetir, isTrue);
      mesa.repetir();
      expect(mesa.enMesa, 120);
      mesa.doblar();
      expect(mesa.montoEn(Apuesta.docena(0)), 200);
      expect(mesa.montoEn(Apuesta.cuadro(1)), 40);
    });

    test('sin fichas, MacIAs presta', () {
      final mesa = MesaRuleta(fichas: 5);
      expect(mesa.enQuiebra, isTrue);
      mesa.rescatar();
      expect(mesa.fichas, 5 + Casino.fichasIniciales);
      expect(mesa.estadisticas.rescates, 1);
    });

    test('se guarda y se recupera', () {
      final mesa = MesaRuleta(fichas: 1000)
        ..apostar(Apuesta.caballo(8, 11), 30);
      mesa.liquidar(11);
      final vuelta = MesaRuleta.desdeJson(mesa.aJson(), fichas: 777);
      expect(vuelta.fichas, 777);
      expect(vuelta.historial, [11]);
      expect(vuelta.anterior, [(Apuesta.caballo(8, 11), 30)]);
      expect(vuelta.estadisticas.giros, 1);
      expect(vuelta.estadisticas.veces[11], 1);
      expect(MesaRuleta.desdeJson({'raro': true}, fichas: 50).fichas, 50);
    });

    test('el sorteo da todos los numeros', () {
      final azar = math.Random(7);
      final salieron = {
        for (var i = 0; i < 2000; i++) MesaRuleta.sortear(azar),
      };
      expect(salieron, {for (var n = 0; n <= 36; n++) n});
    });
  });

  group('la bola', () {
    test('termina siempre en la casilla que salio', () {
      final azar = math.Random(3);
      for (var i = 0; i < 400; i++) {
        final casilla = azar.nextInt(37);
        final trayectoria = TrayectoriaBola(
          casilla: casilla,
          ruedaInicial: azar.nextDouble() * 20,
          bolaInicial: azar.nextDouble() * 2 * math.pi,
          escala: i.isEven ? 1 : .6,
          azar: azar,
        );
        for (final despues in [0.0, .5, 3.0]) {
          final t = trayectoria.duracion + despues;
          final bola = trayectoria.bola(t);
          final esperado =
              trayectoria.anguloRueda(t) +
              TrayectoriaBola.anguloCasilla(casilla);
          expect(
            _diferencia(bola.angulo, esperado).abs(),
            lessThan(1e-9),
            reason: 'casilla $casilla, giro $i',
          );
          expect(bola.radio, RadiosRueda.casillas);
          expect(bola.altura, 0);
        }
      }
    });

    test('no da saltos: el camino es continuo en cada cambio de tramo', () {
      final azar = math.Random(11);
      for (var i = 0; i < 100; i++) {
        final trayectoria = TrayectoriaBola(
          casilla: azar.nextInt(37),
          ruedaInicial: azar.nextDouble() * 6,
          azar: azar,
        );
        const paso = 1 / 240;
        var anterior = trayectoria.bola(0);
        for (var t = paso; t < trayectoria.duracion + .5; t += paso) {
          final ahora = trayectoria.bola(t);
          // A 240 cuadros por segundo la bola nunca avanza mas de un
          // octavo de vuelta, ni salta de golpe hacia adentro o afuera.
          expect(
            _diferencia(ahora.angulo, anterior.angulo).abs(),
            lessThan(math.pi / 4),
            reason: 'giro $i, t = $t',
          );
          expect((ahora.radio - anterior.radio).abs(), lessThan(.02));
          anterior = ahora;
        }
      }
    });

    test('la bola va en contra del cilindro y frena', () {
      final trayectoria = TrayectoriaBola(
        casilla: 5,
        ruedaInicial: 0,
        azar: math.Random(1),
      );
      double velocidad(double t) =>
          _diferencia(
            trayectoria.bola(t + .01).angulo,
            trayectoria.bola(t).angulo,
          ) /
          .01;
      expect(velocidad(.2), lessThan(0));
      expect(velocidad(.2).abs(), greaterThan(velocidad(3).abs()));
      // Arranca entre 2 y 4 vueltas por segundo, como un lanzamiento real.
      expect(velocidad(0).abs() / (2 * math.pi), inInclusiveRange(2.0, 4.0));
      expect(
        trayectoria.anguloRueda(1),
        greaterThan(trayectoria.anguloRueda(0)),
      );
    });

    test('los golpes vienen en orden y cada vez mas suaves', () {
      final trayectoria = TrayectoriaBola(
        casilla: 20,
        ruedaInicial: 1,
        azar: math.Random(2),
      );
      final golpes = trayectoria.golpes;
      expect(golpes.first.tipo, TipoGolpe.lanzamiento);
      expect(golpes[1].tipo, TipoGolpe.rombo);
      for (var i = 1; i < golpes.length; i++) {
        expect(golpes[i].segundo, greaterThan(golpes[i - 1].segundo));
      }
      final casillas = golpes
          .where((g) => g.tipo == TipoGolpe.casilla)
          .toList();
      for (var i = 1; i < casillas.length; i++) {
        expect(casillas[i].fuerza, lessThan(casillas[i - 1].fuerza));
      }
      expect(casillas.last.segundo, lessThan(trayectoria.duracion));
    });
  });
}
