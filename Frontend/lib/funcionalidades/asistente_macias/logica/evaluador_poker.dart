import 'mesa_blackjack.dart' show Carta, Palo;

/// Las cartas del poker como las guarda el servidor: rango y palo, "As" es
/// el as de picas y "Td" el diez de diamantes.
abstract final class CartasPoker {
  static const rangos = '23456789TJQKA';

  /// "As" -> la Carta que dibuja la mesa (el As es el rango 1).
  static Carta? carta(String codigo, {int id = 0}) {
    if (codigo.length != 2) return null;
    final indice = rangos.indexOf(codigo[0]);
    final palo = switch (codigo[1]) {
      's' => Palo.picas,
      'h' => Palo.corazones,
      'd' => Palo.diamantes,
      'c' => Palo.treboles,
      _ => null,
    };
    if (indice < 0 || palo == null) return null;
    return Carta(indice == 12 ? 1 : indice + 2, palo, id);
  }

  /// 2 a 14: el As vale 14 (y 1 en la escalera A-2-3-4-5).
  static int rango(String codigo) => rangos.indexOf(codigo[0]) + 2;
}

/// Lo mismo que poker_valor_cinco() y poker_mejor_valor() del servidor: un
/// numero que crece con la mano. La categoria va arriba (8 escalera de color
/// ... 0 carta alta) y debajo, en cinco grupos de 4 bits, los rangos que
/// desempatan. El servidor decide quien gana; esto es para nombrar la mano.
abstract final class EvaluadorPoker {
  static int valorCinco(List<String> cartas) {
    final rangos = cartas.map(CartasPoker.rango).toList()
      ..sort((a, b) => b.compareTo(a));
    final color = cartas.map((c) => c[1]).toSet().length == 1;

    final cuenta = <int, int>{};
    for (final r in rangos) {
      cuenta[r] = (cuenta[r] ?? 0) + 1;
    }
    final grupos = cuenta.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : b.key.compareTo(a.key),
      );
    var orden = [for (final g in grupos) g.key];
    final patron = grupos.map((g) => g.value).join();

    var alta = 0;
    if (patron == '11111') {
      if (rangos.first - rangos.last == 4) {
        alta = rangos.first;
      } else if (rangos.join(',') == '14,5,4,3,2') {
        alta = 5;
      }
    }

    final categoria = switch (patron) {
      _ when alta > 0 && color => 8,
      '41' => 7,
      '32' => 6,
      _ when color => 5,
      _ when alta > 0 => 4,
      '311' => 3,
      '221' => 2,
      '2111' => 1,
      _ => 0,
    };
    if (alta > 0) orden = [alta];

    var valor = categoria;
    for (var i = 0; i < 5; i++) {
      valor = valor * 16 + (i < orden.length ? orden[i] : 0);
    }
    return valor;
  }

  /// La mejor de cinco entre todas (dos propias y hasta cinco de la mesa).
  static int mejorValor(List<String> cartas) {
    if (cartas.length <= 5) return valorCinco(cartas);
    var mejor = -1;
    final n = cartas.length;
    for (var a = 0; a < n; a++) {
      for (var b = a + 1; b < n; b++) {
        final cinco = [
          for (var i = 0; i < n; i++)
            if (i != a && i != b) cartas[i],
        ];
        if (cinco.length != 5) continue;
        final valor = valorCinco(cinco);
        if (valor > mejor) mejor = valor;
      }
    }
    if (n == 6) {
      for (var a = 0; a < n; a++) {
        final valor = valorCinco([
          for (var i = 0; i < n; i++)
            if (i != a) cartas[i],
        ]);
        if (valor > mejor) mejor = valor;
      }
    }
    return mejor;
  }

  static int categoria(int valor) => valor >> 20;

  /// "Full de reyes y treses", "Par de ases", "Escalera de color".
  static String nombre(int valor) {
    final primero = (valor >> 16) & 15;
    final segundo = (valor >> 12) & 15;
    return switch (categoria(valor)) {
      8 => primero == 14 ? 'Escalera real' : 'Escalera de color',
      7 => 'Póker de ${_plural(primero)}',
      6 => 'Full de ${_plural(primero)} y ${_plural(segundo)}',
      5 => 'Color',
      4 => 'Escalera',
      3 => 'Trío de ${_plural(primero)}',
      2 => 'Doble par: ${_plural(primero)} y ${_plural(segundo)}',
      1 => 'Par de ${_plural(primero)}',
      _ => 'Carta alta',
    };
  }

  static String _plural(int rango) => switch (rango) {
    2 => 'doses',
    3 => 'treses',
    4 => 'cuatros',
    5 => 'cincos',
    6 => 'seises',
    7 => 'sietes',
    8 => 'ochos',
    9 => 'nueves',
    10 => 'dieces',
    11 => 'jotas',
    12 => 'reinas',
    13 => 'reyes',
    _ => 'ases',
  };
}
