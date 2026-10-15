import 'dart:math';

import 'casino.dart';

/// Los cuatro palos de la baraja francesa.
enum Palo { picas, corazones, diamantes, treboles }

/// Una carta del sabot.
///
/// [id] la distingue de sus gemelas de los otros mazos: el sabot tiene seis
/// ases de picas, y en la mesa cada uno es una carta distinta que vuela por
/// su cuenta.
class Carta {
  const Carta(this.rango, this.palo, this.id);

  /// 1 es el As; 11, 12 y 13 son J, Q y K.
  final int rango;
  final Palo palo;
  final int id;

  /// Lo que suma: las figuras valen 10 y el As 1 (o 11, eso lo decide la
  /// mano).
  int get valor => rango > 10 ? 10 : rango;

  bool get esAs => rango == 1;

  bool get esRoja => palo == Palo.corazones || palo == Palo.diamantes;

  /// "A", "7", "10", "K".
  String get nombre => switch (rango) {
    1 => 'A',
    11 => 'J',
    12 => 'Q',
    13 => 'K',
    _ => '$rango',
  };

  /// Como se la nombra en voz alta: "un As", "un 10", "una K".
  String get dicha => switch (rango) {
    1 => 'un As',
    11 || 12 || 13 => 'una $nombre',
    _ => 'un $nombre',
  };

  @override
  String toString() => '$nombre${palo.name[0]}';
}

/// El sabot: seis mazos barajados juntos, como en un casino.
///
/// Se baraja con el azar del sistema (`Random.secure`), no con una semilla:
/// cada sabot es una mezcla nueva entre los 312 factorial ordenes posibles,
/// asi que ninguna partida se repite. La carta de corte cae en un lugar
/// distinto cada vez, entre el 70 y el 80 % del sabot, para que nadie sepa
/// exactamente cuando se vuelve a barajar.
class Sabot {
  Sabot({this.mazos = 6, Random? azar}) : _azar = azar ?? Random.secure() {
    barajar();
  }

  /// Un sabot con las cartas en este orden (la primera es la primera que
  /// sale). Para las pruebas: con un orden conocido se sabe que va a pasar.
  Sabot.ordenado(List<Carta> cartas, {this.mazos = 6})
    : _azar = Random(0),
      _fijo = true {
    _cartas.addAll(cartas.reversed);
    _siguienteId = cartas.length;
  }

  final int mazos;
  final Random _azar;
  bool _fijo = false;
  final List<Carta> _cartas = [];
  int _siguienteId = 0;
  int _corte = 0;

  /// Cuantas veces se barajo desde que se abrio la mesa.
  int barajadas = 0;

  int get total => mazos * 52;
  int get quedan => _cartas.length;

  /// Lo que se jugo del sabot, de 0 a 1.
  double get usado => _fijo ? 0 : 1 - _cartas.length / total;

  /// Salio la carta de corte: antes de la proxima mano se baraja.
  bool get tocaBarajar => !_fijo && _cartas.length <= _corte;

  void barajar() {
    _cartas
      ..clear()
      ..addAll([
        for (var mazo = 0; mazo < mazos; mazo++)
          for (final palo in Palo.values)
            for (var rango = 1; rango <= 13; rango++)
              Carta(rango, palo, _siguienteId++),
      ])
      ..shuffle(_azar);
    _corte = (total * (.20 + _azar.nextDouble() * .10)).round();
    barajadas++;
  }

  Carta sacar() {
    if (_cartas.isEmpty) barajar();
    return _cartas.removeLast();
  }
}

/// Las cartas de alguien en la mesa: una mano del jugador o la del crupier.
class Mano {
  Mano({this.apuesta = 0, this.deDivision = false});

  final List<Carta> cartas = [];
  int apuesta;

  /// Salio de dividir un par. Un 21 asi no es blackjack.
  bool deDivision;

  bool doblada = false;
  bool rendida = false;
  bool plantada = false;

  int get _duro => cartas.fold(0, (suma, carta) => suma + carta.valor);

  bool get _tieneAs => cartas.any((carta) => carta.esAs);

  /// El mejor total: un As vale 11 mientras no pase de 21.
  int get total {
    final duro = _duro;
    return _tieneAs && duro + 10 <= 21 ? duro + 10 : duro;
  }

  /// Hay un As contando 11: "blanda", porque una carta mas no la revienta.
  bool get blanda => _tieneAs && _duro + 10 <= 21;

  /// Lo que se muestra: "7 / 17" mientras es blanda y no esta cerrada.
  String get totalDicho =>
      blanda && total < 21 && !plantada ? '$_duro / $total' : '$total';

  bool get esBlackjack => !deDivision && cartas.length == 2 && total == 21;

  bool get sePaso => total > 21;

  /// Dos cartas del mismo valor: se pueden dividir. Una K y una Q tambien
  /// (las dos valen 10), como en la mayoria de los casinos.
  bool get esPar => cartas.length == 2 && cartas[0].valor == cartas[1].valor;

  /// Dividida de un par de ases: recibe una sola carta.
  bool get deAses => deDivision && cartas.isNotEmpty && cartas.first.esAs;

  /// Ya no se juega: se planto, se rindio, se paso o llego a 21.
  bool get terminada =>
      plantada || rendida || sePaso || (cartas.length >= 2 && total == 21);
}

/// En que momento esta la mesa.
enum FaseMesa {
  /// Se arma la apuesta con las fichas.
  apostando,

  /// Salen las cuatro primeras cartas.
  repartiendo,

  /// El crupier muestra un As: se ofrece el seguro.
  seguro,

  /// Juega la persona: pedir, plantarse, doblar, dividir, rendirse.
  jugando,

  /// Juega el crupier: da vuelta su carta y pide hasta 17.
  crupier,

  /// Se pago todo: se ven los resultados.
  resultado,
}

/// Lo que se puede hacer con una mano.
enum Jugada { pedir, plantarse, doblar, dividir, rendirse }

/// Como termino una mano.
enum Desenlace { blackjack, gana, empata, pierde, sePaso, rendida }

/// Como termino una mano y cuanto volvio a las fichas (apuesta incluida).
class ResultadoMano {
  const ResultadoMano(this.desenlace, this.apuesta, this.pago);

  final Desenlace desenlace;
  final int apuesta;
  final int pago;

  /// Lo que se gano (o se perdio, si es negativo) con esta mano.
  int get neto => pago - apuesta;
}

/// Lo que paso en todas las manos, para el cuadro de estadisticas.
class EstadisticasBlackjack {
  EstadisticasBlackjack();

  factory EstadisticasBlackjack.desdeJson(Map<String, dynamic> json) =>
      EstadisticasBlackjack()
        ..manos = json['manos'] as int? ?? 0
        ..ganadas = json['ganadas'] as int? ?? 0
        ..perdidas = json['perdidas'] as int? ?? 0
        ..empatadas = json['empatadas'] as int? ?? 0
        ..blackjacks = json['blackjacks'] as int? ?? 0
        ..rachaActual = json['racha'] as int? ?? 0
        ..mejorRacha = json['mejorRacha'] as int? ?? 0
        ..fichasMaximas = json['fichasMaximas'] as int? ?? 0
        ..mayorPremio = json['mayorPremio'] as int? ?? 0
        ..rescates = json['rescates'] as int? ?? 0;

  int manos = 0;
  int ganadas = 0;
  int perdidas = 0;
  int empatadas = 0;
  int blackjacks = 0;

  /// Manos ganadas seguidas (las empatadas no la cortan).
  int rachaActual = 0;
  int mejorRacha = 0;
  int fichasMaximas = 0;

  /// Lo mas que se gano en una sola ronda.
  int mayorPremio = 0;

  /// Las veces que la casa presto fichas por quedarse en cero.
  int rescates = 0;

  /// De 0 a 100, sin contar los empates.
  int get porcentajeGanadas {
    final decididas = ganadas + perdidas;
    return decididas == 0 ? 0 : (ganadas * 100 / decididas).round();
  }

  void registrar(List<ResultadoMano> resultados, int netoRonda, int fichas) {
    for (final resultado in resultados) {
      manos++;
      switch (resultado.desenlace) {
        case Desenlace.blackjack:
          blackjacks++;
          ganadas++;
          rachaActual++;
        case Desenlace.gana:
          ganadas++;
          rachaActual++;
        case Desenlace.empata:
          empatadas++;
        case Desenlace.pierde || Desenlace.sePaso || Desenlace.rendida:
          perdidas++;
          rachaActual = 0;
      }
      mejorRacha = max(mejorRacha, rachaActual);
    }
    mayorPremio = max(mayorPremio, netoRonda);
    fichasMaximas = max(fichasMaximas, fichas);
  }

  Map<String, dynamic> aJson() => {
    'manos': manos,
    'ganadas': ganadas,
    'perdidas': perdidas,
    'empatadas': empatadas,
    'blackjacks': blackjacks,
    'racha': rachaActual,
    'mejorRacha': mejorRacha,
    'fichasMaximas': fichasMaximas,
    'mayorPremio': mayorPremio,
    'rescates': rescates,
  };
}

/// Una mesa de blackjack con las reglas de casino de siempre.
///
/// - Seis mazos; se baraja al salir la carta de corte.
/// - El crupier pide hasta 16 y se planta en todos los 17, blandos incluidos.
/// - El blackjack paga 3 a 2; el seguro, 2 a 1.
/// - El crupier espia su carta tapada si muestra un As o un 10: si tiene
///   blackjack, la mano termina ahi.
/// - Se dobla con las dos primeras cartas, tambien despues de dividir.
/// - Se divide hasta tener cuatro manos. Los ases divididos reciben una sola
///   carta y no se vuelven a dividir.
/// - Rendirse (tarde, despues de que el crupier revisa): se recupera la mitad.
///
/// No sabe nada de pantallas ni de animaciones: la pantalla pide cada carta
/// cuando le toca mostrarla, y asi decide el ritmo.
class MesaBlackjack {
  MesaBlackjack({
    this.fichas = fichasIniciales,
    Sabot? sabot,
    EstadisticasBlackjack? estadisticas,
  }) : sabot = sabot ?? Sabot(),
       estadisticas = estadisticas ?? EstadisticasBlackjack();

  static const fichasIniciales = Casino.fichasIniciales;

  /// Las fichas de la mesa (las del casino). Armando la apuesta con ellas
  /// siempre salen multiplos de 10; el "todo" puede ser cualquier cantidad, y
  /// el 3 a 2 del blackjack y la mitad del seguro se redondean hacia abajo.
  static const valoresFichas = Casino.valoresFichas;
  static const apuestaMinima = 10;
  static const maximoManos = 4;

  final Sabot sabot;
  final EstadisticasBlackjack estadisticas;

  int fichas;

  /// La apuesta que se esta armando.
  int apuesta = 0;

  /// La de la mano anterior, para "repetir".
  int ultimaApuesta = 0;

  FaseMesa fase = FaseMesa.apostando;

  final List<Mano> manos = [];
  int manoActual = 0;
  final Mano crupier = Mano();

  /// La carta tapada del crupier ya se dio vuelta.
  bool ocultaRevelada = false;

  int seguro = 0;
  List<ResultadoMano> resultados = const [];

  /// Lo que devolvio el seguro (0 si no habia o si se perdio).
  int pagoSeguro = 0;

  int _fichasAlEmpezar = 0;

  /// Lo que se gano o perdio en la ronda que termino.
  int get netoRonda => fichas - _fichasAlEmpezar;

  Mano get mano => manos[manoActual];

  /// La carta que el crupier deja ver.
  Carta? get cartaVisible =>
      crupier.cartas.isEmpty ? null : crupier.cartas.first;

  // ---------------------------------------------------------------- apuesta
  /// Sin tope: se puede apostar hasta la ultima ficha que quede.
  bool puedeSumar(int ficha) =>
      fase == FaseMesa.apostando && apuesta + ficha <= fichas;

  void sumar(int ficha) {
    if (puedeSumar(ficha)) apuesta += ficha;
  }

  void borrarApuesta() {
    if (fase == FaseMesa.apostando) apuesta = 0;
  }

  bool get puedeRepetir =>
      fase == FaseMesa.apostando &&
      ultimaApuesta >= apuestaMinima &&
      ultimaApuesta <= fichas &&
      apuesta != ultimaApuesta;

  void repetir() {
    if (puedeRepetir) apuesta = ultimaApuesta;
  }

  bool get puedeDoblarApuesta =>
      fase == FaseMesa.apostando && apuesta > 0 && apuesta * 2 <= fichas;

  void doblarApuesta() {
    if (puedeDoblarApuesta) apuesta *= 2;
  }

  /// El "all in": todas las fichas que hay, hasta la ultima, sin tope.
  bool get puedeIrConTodo =>
      fase == FaseMesa.apostando && fichas >= apuestaMinima && fichas > apuesta;

  void irConTodo() {
    if (puedeIrConTodo) apuesta = fichas;
  }

  bool get puedeRepartir =>
      fase == FaseMesa.apostando &&
      apuesta >= apuestaMinima &&
      apuesta <= fichas;

  /// Sin fichas para la apuesta minima: la casa presta.
  bool get enQuiebra =>
      fase == FaseMesa.apostando && fichas + apuesta < apuestaMinima;

  void rescatar() {
    fichas += fichasIniciales;
    estadisticas.rescates++;
  }

  // ----------------------------------------------------------------- ronda
  /// La apuesta sale de las fichas y empieza la ronda. Las cartas las pide la
  /// pantalla, una por una, para mostrarlas volando.
  void empezar() {
    if (!puedeRepartir) return;
    if (sabot.tocaBarajar) sabot.barajar();
    _fichasAlEmpezar = fichas;
    fichas -= apuesta;
    ultimaApuesta = apuesta;
    manos
      ..clear()
      ..add(Mano(apuesta: apuesta));
    manoActual = 0;
    crupier.cartas.clear();
    ocultaRevelada = false;
    seguro = 0;
    pagoSeguro = 0;
    resultados = const [];
    apuesta = 0;
    fase = FaseMesa.repartiendo;
  }

  /// Una carta a la mano que se juega (o a la [indice]).
  Carta darAJugador([int? indice]) {
    final carta = sabot.sacar();
    manos[indice ?? manoActual].cartas.add(carta);
    return carta;
  }

  /// Una carta al crupier. La segunda va tapada hasta que le toque jugar.
  Carta darACrupier() {
    final carta = sabot.sacar();
    crupier.cartas.add(carta);
    return carta;
  }

  /// Despues del reparto: el seguro, los blackjacks o a jugar.
  void trasRepartir() {
    if (fase != FaseMesa.repartiendo) return;
    if (cartaVisible!.esAs && costoSeguro > 0) {
      fase = FaseMesa.seguro;
      return;
    }
    _revisarBlackjacks();
  }

  int get costoSeguro => manos.isEmpty ? 0 : manos.first.apuesta ~/ 2;

  bool get puedeAsegurar => fase == FaseMesa.seguro && fichas >= costoSeguro;

  void decidirSeguro({required bool tomar}) {
    if (fase != FaseMesa.seguro) return;
    if (tomar && puedeAsegurar) {
      seguro = costoSeguro;
      fichas -= seguro;
    }
    _revisarBlackjacks();
  }

  /// El crupier espia: con blackjack de alguno de los dos, la mano termina.
  void _revisarBlackjacks() {
    if (crupier.esBlackjack || manos.first.esBlackjack) {
      _liquidar();
      return;
    }
    fase = FaseMesa.jugando;
  }

  // ----------------------------------------------------------------- jugar
  bool get _jugando => fase == FaseMesa.jugando && !mano.terminada;

  /// Una mano dividida que todavia tiene una sola carta: la pantalla le da
  /// la segunda y llama a [completarDivision].
  bool get manoNecesitaCarta =>
      fase == FaseMesa.jugando && mano.cartas.length == 1;

  bool get puedePedir => _jugando && !manoNecesitaCarta && !mano.deAses;

  bool get puedePlantarse => _jugando && !manoNecesitaCarta;

  bool get puedeDoblar =>
      _jugando &&
      mano.cartas.length == 2 &&
      !mano.deAses &&
      fichas >= mano.apuesta;

  bool get puedeDividir =>
      _jugando &&
      mano.esPar &&
      !mano.deAses &&
      manos.length < maximoManos &&
      fichas >= mano.apuesta;

  bool get puedeRendirse =>
      _jugando &&
      manos.length == 1 &&
      mano.cartas.length == 2 &&
      !mano.deDivision;

  bool puede(Jugada jugada) => switch (jugada) {
    Jugada.pedir => puedePedir,
    Jugada.plantarse => puedePlantarse,
    Jugada.doblar => puedeDoblar,
    Jugada.dividir => puedeDividir,
    Jugada.rendirse => puedeRendirse,
  };

  /// Null si no se podia pedir.
  Carta? pedir() {
    if (!puedePedir) return null;
    final carta = darAJugador();
    if (mano.terminada) _avanzar();
    return carta;
  }

  void plantarse() {
    if (!puedePlantarse) return;
    mano.plantada = true;
    _avanzar();
  }

  /// Dobla la apuesta, recibe una sola carta y se planta. Null si no se
  /// podia doblar.
  Carta? doblar() {
    if (!puedeDoblar) return null;
    fichas -= mano.apuesta;
    mano
      ..apuesta *= 2
      ..doblada = true;
    final carta = darAJugador();
    mano.plantada = true;
    _avanzar();
    return carta;
  }

  /// Parte el par en dos manos con la misma apuesta. La pantalla le da su
  /// segunda carta a cada una cuando le toca (ver [manoNecesitaCarta]).
  void dividir() {
    if (!puedeDividir) return;
    final original = mano;
    fichas -= original.apuesta;
    final segunda = Mano(apuesta: original.apuesta, deDivision: true);
    segunda.cartas.add(original.cartas.removeLast());
    original.deDivision = true;
    manos.insert(manoActual + 1, segunda);
  }

  /// Despues de la segunda carta de una mano dividida: los ases se plantan
  /// solos, y un 21 tambien.
  void completarDivision() {
    if (fase != FaseMesa.jugando) return;
    if (mano.deAses) mano.plantada = true;
    if (mano.terminada) _avanzar();
  }

  void rendirse() {
    if (!puedeRendirse) return;
    mano.rendida = true;
    _avanzar();
  }

  /// A la siguiente mano que falta jugar, o al crupier.
  void _avanzar() {
    while (manoActual < manos.length && manos[manoActual].terminada) {
      manoActual++;
    }
    if (manoActual < manos.length) return;
    manoActual = manos.length - 1;
    final quedaAlguna = manos.any((m) => !m.sePaso && !m.rendida);
    if (quedaAlguna) {
      fase = FaseMesa.crupier;
    } else {
      _liquidar();
    }
  }

  // --------------------------------------------------------------- crupier
  void revelar() => ocultaRevelada = true;

  /// Pide hasta 16; en 17 se planta, tambien en un 17 blando.
  bool get crupierDebePedir =>
      fase == FaseMesa.crupier && ocultaRevelada && crupier.total < 17;

  Carta crupierPide() => darACrupier();

  void terminarCrupier() {
    if (fase == FaseMesa.crupier) _liquidar();
  }

  // ---------------------------------------------------------------- pagos
  void _liquidar() {
    ocultaRevelada = true;
    final total = crupier.total;
    final suBlackjack = crupier.esBlackjack;
    final sePaso = total > 21;
    resultados = [
      for (final m in manos)
        if (m.rendida)
          ResultadoMano(Desenlace.rendida, m.apuesta, m.apuesta ~/ 2)
        else if (m.sePaso)
          ResultadoMano(Desenlace.sePaso, m.apuesta, 0)
        else if (m.esBlackjack && !suBlackjack)
          ResultadoMano(Desenlace.blackjack, m.apuesta, m.apuesta * 5 ~/ 2)
        else if (suBlackjack && !m.esBlackjack)
          ResultadoMano(Desenlace.pierde, m.apuesta, 0)
        else if (suBlackjack)
          ResultadoMano(Desenlace.empata, m.apuesta, m.apuesta)
        else if (sePaso || m.total > total)
          ResultadoMano(Desenlace.gana, m.apuesta, m.apuesta * 2)
        else if (m.total == total)
          ResultadoMano(Desenlace.empata, m.apuesta, m.apuesta)
        else
          ResultadoMano(Desenlace.pierde, m.apuesta, 0),
    ];
    pagoSeguro = seguro > 0 && suBlackjack ? seguro * 3 : 0;
    fichas += resultados.fold(0, (suma, r) => suma + r.pago) + pagoSeguro;
    estadisticas.registrar(resultados, netoRonda, fichas);
    fase = FaseMesa.resultado;
  }

  /// Se recogen las cartas y se vuelve a apostar.
  void nuevaRonda() {
    if (fase != FaseMesa.resultado) return;
    manos.clear();
    manoActual = 0;
    crupier.cartas.clear();
    ocultaRevelada = false;
    seguro = 0;
    pagoSeguro = 0;
    resultados = const [];
    fase = FaseMesa.apostando;
  }
}
