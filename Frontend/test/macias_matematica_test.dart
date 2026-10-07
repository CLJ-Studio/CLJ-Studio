import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/matematica_macias.dart';

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
      expect(_r('resuelve x^3 = 8'), contains('primer y segundo grado'));
      expect(_r('resuelve 2y = 4'), contains('x como incógnita'));
      expect(_r('calcula 2x+3'), contains('signo igual'));
    });

    test('una ecuación sin "resuelve" también se reconoce', () {
      expect(_r('2x + 3 = 11'), contains('**x = 4**'));
    });
  });
}
