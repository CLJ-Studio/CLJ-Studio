import 'mesa_blackjack.dart';

/// Lo que haria MacIAs, y por que.
class ConsejoBlackjack {
  const ConsejoBlackjack(this.jugada, this.porque);

  final Jugada jugada;
  final String porque;
}

/// La estrategia basica del blackjack: la jugada que, a la larga, pierde
/// menos contra la casa.
///
/// Es la tabla clasica para seis mazos, crupier que se planta en 17 blando,
/// doblar despues de dividir y rendirse tarde. No adivina la proxima carta
/// (nadie puede): dice lo que conviene en promedio, que es lo mejor que se
/// puede hacer sin contar cartas.
abstract final class EstrategiaBlackjack {
  /// El consejo para la mano que se esta jugando. Null si no toca jugar.
  static ConsejoBlackjack? para(MesaBlackjack mesa) {
    if (mesa.fase != FaseMesa.jugando || mesa.manoNecesitaCarta) return null;
    final visible = mesa.cartaVisible;
    if (visible == null) return null;
    final mano = mesa.mano;
    final suya = visible.esAs ? 11 : visible.valor;
    final contra = visible.esAs ? 'un As' : 'un $suya';
    final total = mano.total;

    // Rendirse: solo con las peores manos duras contra las mejores del
    // crupier.
    final parDeOchos = mano.esPar && mano.cartas.first.valor == 8;
    if (mesa.puedeRendirse && !mano.blanda && !parDeOchos) {
      if ((total == 16 && suya >= 9) || (total == 15 && suya == 10)) {
        return ConsejoBlackjack(
          Jugada.rendirse,
          'Con $total contra $contra, yo me rindo: recupero la mitad. Es de '
          'las manos que más pierden.',
        );
      }
    }

    if (mesa.puedeDividir) {
      final consejo = _par(mano.cartas.first, suya, contra);
      if (consejo != null) return consejo;
    }

    if (mano.blanda) return _blanda(mesa, total, suya, contra);
    return _dura(mesa, total, suya, contra);
  }

  /// El seguro: casi nunca conviene.
  static const sobreElSeguro =
      'Yo no lo tomaría: con un As a la vista, el crupier tiene blackjack '
      'menos de 1 de cada 3 veces, y el seguro paga como si fuera 1 de cada 3.';

  static ConsejoBlackjack? _par(Carta carta, int suya, String contra) {
    final valor = carta.valor;
    final dividir = switch (valor) {
      1 || 8 => true,
      9 => suya != 7 && suya != 10 && suya != 11,
      7 => suya <= 7,
      6 => suya <= 6,
      4 => suya == 5 || suya == 6,
      2 || 3 => suya <= 7,
      _ => false,
    };
    if (!dividir) return null;
    final porque = switch (valor) {
      1 => 'Los ases siempre se dividen: son dos oportunidades de sacar 21.',
      8 =>
        'Un par de 8 suma 16, la peor mano que hay. Dividido, son dos manos '
            'que arrancan en 8.',
      9 =>
        'Dividir los 9 contra $contra: tu 18 se vuelve dos manos que pintan '
            'mejor.',
      _ =>
        'Contra $contra el crupier está flojo: dividir es poner más fichas '
            'cuando te conviene.',
    };
    return ConsejoBlackjack(Jugada.dividir, porque);
  }

  static ConsejoBlackjack _blanda(
    MesaBlackjack mesa,
    int total,
    int suya,
    String contra,
  ) {
    final puedeDoblar = mesa.puedeDoblar;
    ConsejoBlackjack doblarO(Jugada siNo, String porqueSiNo) => puedeDoblar
        ? ConsejoBlackjack(
            Jugada.doblar,
            'Un $total blando contra $contra: doblo. El crupier está en '
            'problemas y tu mano no se puede pasar con una carta.',
          )
        : ConsejoBlackjack(siNo, porqueSiNo);

    if (total >= 19) {
      return ConsejoBlackjack(
        Jugada.plantarse,
        'Con $total, me planto. Esa mano gana sola.',
      );
    }
    if (total == 18) {
      if (suya >= 3 && suya <= 6) {
        return doblarO(
          Jugada.plantarse,
          'Un 18 blando contra $contra: me planto, es buena mano.',
        );
      }
      if (suya == 2 || suya == 7 || suya == 8) {
        return ConsejoBlackjack(
          Jugada.plantarse,
          'Un 18 blando contra $contra: me planto, es buena mano.',
        );
      }
      return ConsejoBlackjack(
        Jugada.pedir,
        'Un 18 blando contra $contra: pido. El crupier pinta para 19 o 20, '
        'y una carta más no te puede pasar.',
      );
    }
    final doblarDesde = switch (total) {
      17 => 3,
      15 || 16 => 4,
      13 || 14 => 5,
      _ => 99,
    };
    if (suya >= doblarDesde && suya <= 6) {
      return doblarO(
        Jugada.pedir,
        'Un $total blando: pido. Ninguna carta te puede pasar.',
      );
    }
    return ConsejoBlackjack(
      Jugada.pedir,
      'Un $total blando: pido. Ninguna carta te puede pasar de 21.',
    );
  }

  static ConsejoBlackjack _dura(
    MesaBlackjack mesa,
    int total,
    int suya,
    String contra,
  ) {
    final puedeDoblar = mesa.puedeDoblar;
    if (total >= 17) {
      return ConsejoBlackjack(
        Jugada.plantarse,
        total == 21
            ? 'Tienes 21. No se toca.'
            : 'Con $total, me planto. Pedir acá es buscarse problemas.',
      );
    }
    if (total >= 13) {
      return suya <= 6
          ? ConsejoBlackjack(
              Jugada.plantarse,
              'Con $total contra $contra, me planto: que se arriesgue el '
              'crupier, que tiene que pedir hasta 17.',
            )
          : ConsejoBlackjack(
              Jugada.pedir,
              'Con $total contra $contra, pido. Duele, pero lo más probable es '
              'que el crupier llegue a 17 o mas.',
            );
    }
    if (total == 12) {
      return suya >= 4 && suya <= 6
          ? ConsejoBlackjack(
              Jugada.plantarse,
              'Con 12 contra $contra, me planto y dejo que el crupier se '
              'arriesgue.',
            )
          : ConsejoBlackjack(
              Jugada.pedir,
              'Con 12 contra $contra, pido: solo un 10 te pasa.',
            );
    }
    final doblarHasta = switch (total) {
      11 => 10,
      10 => 9,
      9 => 6,
      _ => 0,
    };
    final doblarDesde = total == 9 ? 3 : 2;
    if (puedeDoblar && suya >= doblarDesde && suya <= doblarHasta) {
      return ConsejoBlackjack(
        Jugada.doblar,
        total == 11
            ? 'Con 11, doblo: cualquier figura te deja en 21.'
            : 'Con $total contra $contra, doblo. Es el momento de apostar más.',
      );
    }
    return ConsejoBlackjack(Jugada.pedir, 'Con $total no hay riesgo: pido.');
  }
}
