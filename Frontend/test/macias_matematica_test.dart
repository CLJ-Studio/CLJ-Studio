import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/matematica_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/utilidades_macias.dart';

String? _r(String mensaje) => MatematicaMacias.responder(mensaje);

void main() {
  group('cuentas', () {
    const casos = {
      'calcula (3 + 4) * 2^3': '**56**',
      '2+2': '**4**',
      'cuánto es 0.1 + 0.2': '**0.3**',
      '3x4': '**12**',
      'calcula raiz(144)/3': '**4**',
      '√16 + 2²': '**8**',
      'cuanto es 2 más 3 al cuadrado': '**11**',
      '10 entre 4': '**2.5**',
      '-2^2': '**−4**',
      '2^-1': '**0.5**',
      'calcula 3,5 * 2': '**7**',
      'calcula 1/3': '**0.3333333333**',
      'sen(pi/6)': '**0.5**',
      'calcula log(1000)': '**3**',
      'calcula 2(3+4)': '**14**',
    };
    for (final MapEntry(key: entrada, value: esperado) in casos.entries) {
      test('$entrada = $esperado', () {
        expect(_r(entrada), contains(esperado));
      });
    }

    test('el seno sin pi se toma en grados, y lo avisa', () {
      final respuesta = _r('sen 30')!;
      expect(respuesta, contains('**0.5**'));
      expect(respuesta, contains('grados'));
    });

    test('dividir entre cero se explica, no revienta', () {
      expect(_r('calcula 1/0'), contains('cero'));
      expect(_r('calcula raiz(-4)'), contains('reales'));
    });

    test('lo que no es una cuenta sigue su camino', () {
      expect(_r('2 pedidos'), isNull);
      expect(_r('calcula mi promedio'), isNull);
      expect(_r('hola'), isNull);
      expect(_r('quiero 3 empanadas'), isNull);
    });
  });

  group('ecuaciones', () {
    test('primer grado, con paréntesis y pasos', () {
      final r = _r('resuelve 3(x-2) = x+4')!;
      expect(r, contains('primer grado'));
      expect(r, contains('**x = 5**'));
    });

    test('primer grado con fracciones queda en enteros', () {
      final r = _r('resuelve x/2 + 1 = 4')!;
      expect(r, contains('x − 6 = 0'));
      expect(r, contains('**x = 6**'));
    });

    test('primer grado con resultado fraccionario', () {
      expect(_r('resuelve 3x = 7'), contains('**x = 7/3 ≈ 2.333333333**'));
    });

    test('segundo grado con raíces enteras, y su factorización', () {
      final r = _r('x^2 - 5x + 6 = 0')!;
      expect(r, contains('Δ = b² − 4ac = 25 − 24 = 1'));
      expect(r, contains('**x₁ = 3, x₂ = 2**'));
      expect(r, contains('(x − 3)(x − 2) = 0'));
    });

    test('segundo grado con raíces fraccionarias', () {
      expect(
        _r('resuelve 2x^2 + 3x - 2 = 0'),
        contains('**x₁ = 1/2 ≈ 0.5, x₂ = −2**'),
      );
    });

    test('raíz doble', () {
      final r = _r('x² - 6x + 9 = 0')!;
      expect(r, contains('**x = 3**'));
      expect(r, contains('(x − 3)² = 0'));
    });

    test('raíz que no es exacta, simplificada', () {
      final r = _r('resuelve x^2 = 12')!;
      expect(r, contains('**x = ±2√3**'));
      expect(r, contains('x₁ ≈ 3.464101615'));
    });

    test('raíces complejas', () {
      final r = _r('resuelve x^2 + 2x + 5 = 0')!;
      expect(r, contains('no tiene soluciones reales'));
      expect(r, contains('x = −1 ± 2i'));
      expect(_r('resuelve x^2 + x + 1 = 0'), contains('x = (−1 ± i√3) / 2'));
    });

    test('identidades y ecuaciones sin solución', () {
      expect(_r('resuelve 2(x+1) = 2x + 2'), contains('Toda x es solución'));
      expect(_r('resuelve x + 1 = x + 2'), contains('No tiene solución'));
    });

    test('lo que todavía no resuelve lo dice', () {
      expect(_r('resuelve x^5 = 8'), contains('hasta grado 4'));
      expect(_r('resuelve 2y = 4'), contains('x como incógnita'));
      expect(_r('calcula 2x+3'), contains('signo igual'));
    });

    test('grado 3 y 4: se resuelven si se pueden factorizar', () {
      final cubica = _r('resuelve x^3 - 6x^2 + 11x - 6 = 0')!;
      expect(cubica, contains('Ecuación de grado 3'));
      expect(cubica, contains('(x − 1)(x − 2)(x − 3) = 0'));
      expect(cubica, contains('**Soluciones: x = 1, x = 2, x = 3**'));
      // x³ = 8: una raiz real y dos complejas.
      final ocho = _r('resuelve x^3 = 8')!;
      expect(ocho, contains('x = 2'));
      expect(ocho, contains('x = −1 ± i√3'));
      // Bicuadrada: x⁴ − 5x² + 4 = (x − 2)(x − 1)(x + 1)(x + 2).
      expect(
        _r('resuelve x^4 - 5x^2 + 4 = 0'),
        contains('**Soluciones: x = −2, x = −1, x = 1, x = 2**'),
      );
      // Sin raices racionales: lo dice en vez de inventar.
      expect(_r('resuelve x^3 = 2'), contains('No tiene raíces racionales'));
    });

    test('una ecuación sin "resuelve" también se reconoce', () {
      expect(_r('2x + 3 = 11'), contains('**x = 4**'));
    });
  });

  group('derivadas e integrales', () {
    test('derivada de un polinomio, término a término', () {
      expect(
        _r('derivada de x^3 + 2x'),
        contains('**d/dx (x³ + 2x) = 3x² + 2**'),
      );
      expect(_r('deriva 5'), contains('= 0**'));
      expect(_r('cual es la derivada de x^2'), contains('= 2x**'));
    });

    test('derivadas básicas', () {
      expect(_r('derivada de sen x'), contains('cos(x)'));
      expect(_r('derivada de ln(x)'), contains('1/x'));
    });

    test('integral indefinida, con su + C', () {
      expect(_r('integral de 3x^2'), contains('**∫ (3x²) dx = x³ + C**'));
      expect(_r('integra x^2'), contains('(1/3)x³ + C'));
      expect(_r('∫ 2x dx'), contains('x² + C'));
      expect(_r('integral de sen x'), contains('−cos(x) + C'));
      expect(_r('integral de 1/x'), contains('ln|x| + C'));
    });

    test('integral definida, con los límites en cualquier orden', () {
      expect(_r('integral de x^2 de 0 a 2'), contains('8/3 ≈ 2.666666667'));
      expect(_r('integral de 0 a 2 de x^2'), contains('8/3'));
      expect(_r('integral de 2x de -1 a 1'), contains('= 0**'));
    });

    test('lo que es un tema y no una cuenta, sigue de largo', () {
      expect(_r('integral definida'), isNull);
      expect(_r('integrales impropias'), isNull);
      expect(_r('derivada de una suma'), isNull);
    });

    test('lo que todavía no integra, lo dice', () {
      expect(_r('integral de x * sen x'), contains('integración por partes'));
    });
  });

  group('factorizar y desarrollar', () {
    test('factoriza con raíces racionales', () {
      expect(_r('factoriza x^2 - 5x + 6'), contains('= (x − 2)(x − 3)**'));
      expect(_r('factoriza x^2 - 9'), contains('= (x + 3)(x − 3)**'));
      expect(_r('factoriza 2x^2 + 3x - 2'), contains('(x + 2)(2x − 1)'));
      expect(_r('factoriza x^3 - x'), contains('x(x + 1)(x − 1)'));
      expect(_r('factoriza x^2 - 6x + 9'), contains('(x − 3)²'));
      expect(_r('factoriza 2x^2 - 8'), contains('2(x + 2)(x − 2)'));
    });

    test('lo que no se separa más, lo explica', () {
      expect(_r('factoriza x^2 + 1'), contains('no se puede factorizar'));
      expect(_r('factoriza x^2 - 2'), contains('no se puede factorizar'));
    });

    test('desarrolla productos y potencias', () {
      expect(_r('desarrolla (x + 2)^3'), contains('**x³ + 6x² + 12x + 8**'));
      expect(_r('expande (x - 1)(x + 1)'), contains('**x² − 1**'));
    });

    test('"simplifica" fuera de matemáticas no es una cuenta', () {
      expect(_r('simplifica tu respuesta'), isNull);
      expect(_r('factoriza esto por favor'), isNull);
    });
  });

  group('cuentas rápidas', () {
    String? r(String mensaje) => CuentasRapidasMacias.responder(mensaje)?.texto;

    test('porcentajes y descuentos', () {
      expect(r('cuánto es el 15% de 200'), contains('**30**'));
      expect(r('20 por ciento de 150'), contains('**30**'));
      expect(r('200 con 15% de descuento'), contains('queda en **170**'));
      expect(r('100 más el 13%'), contains('da **113**'));
      expect(r('qué porcentaje es 30 de 120'), contains('**25 %**'));
    });

    test('promedios', () {
      expect(r('promedio de 70, 80 y 95'), contains('**81.67**'));
      expect(r('promedio de 70,80,90'), contains('**80**'));
      expect(r('promedio de 70,5 y 80'), contains('**75.25**'));
    });

    test('unidades', () {
      expect(
        r('5 km a millas'),
        contains('**5 kilómetros = 3.106855961 millas**'),
      );
      expect(r('30 grados a fahrenheit'), contains('**30 °C = 86 °F**'));
      expect(r('100 f a c'), contains('37.77777778 °C'));
      expect(
        r('cuántos centímetros son 5 pulgadas'),
        contains('12.7 centímetros'),
      );
      expect(r('convierte 10 libras a kg'), contains('4.5359237 kilos'));
      expect(r('2 horas en minutos'), contains('120 minutos'));
      expect(r('1 litro a ml'), contains('1000 mililitros'));
      expect(r('5 km a kilos'), contains('miden cosas distintas'));
    });

    test('lo que no es una cuenta rápida sigue de largo', () {
      expect(r('tengo 2 pedidos'), isNull);
      expect(r('voy en 5 min a la u'), isNull);
      expect(r('hola'), isNull);
    });
  });
}
