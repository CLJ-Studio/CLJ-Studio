import 'dart:math' as math;

import 'casino.dart';

/// Lo que hay en cada casilla de la rueda de la pesca, y donde se apuesta:
/// los dos hielos pagan al instante; los tres peces abren el bono.
enum Casilla {
  hieloBlanco('Hielo blanco'),
  hieloAzul('Hielo azul'),
  azulitos('Azulitos'),
  naranjotes('Naranjotes'),
  rojazos('Rojazos');

  const Casilla(this.nombre);

  final String nombre;

  bool get esHielo => this == hieloBlanco || this == hieloAzul;

  Pez? get pez => switch (this) {
    azulitos => Pez.azulitos,
    naranjotes => Pez.naranjotes,
    rojazos => Pez.rojazos,
    _ => null,
  };
}

/// Los peces del bono, del mas chico al mas grande. Cada uno vale entre
/// 0,1 y su maximo a 1, segun el que se pesque.
enum Pez {
  /// Hasta 30 a 1.
  azulitos(30, [
    (.1, 5),
    (.5, 6),
    (1, 7),
    (2, 8),
    (3, 9),
    (4, 9),
    (5, 10),
    (7, 10),
    (10, 10),
    (12, 8),
    (15, 7),
    (20, 5),
    (25, 3),
    (30, 3),
  ]),

  /// Hasta 80 a 1.
  naranjotes(80, [
    (.1, 5),
    (.5, 5),
    (1, 5),
    (2, 6),
    (5, 8),
    (8, 9),
    (10, 10),
    (15, 10),
    (20, 10),
    (25, 9),
    (30, 8),
    (40, 6),
    (50, 4),
    (60, 3),
    (80, 2),
  ]),

  /// Hasta 150 a 1.
  rojazos(150, [
    (.1, 4),
    (1, 5),
    (2, 5),
    (5, 6),
    (10, 8),
    (15, 8),
    (20, 9),
    (30, 10),
    (40, 10),
    (50, 10),
    (75, 9),
    (100, 7),
    (125, 5),
    (150, 4),
  ]);

  const Pez(this.maximo, this.tabla);

  /// Lo mas que paga, sin moneda.
  final double maximo;

  /// Lo que puede valer el que se pesca, con su peso: cuanto mas peso, mas
  /// seguido sale. Los chicos son los comunes y los grandes, los raros.
  final List<(double valor, int peso)> tabla;

  Casilla get casilla => switch (this) {
    azulitos => Casilla.azulitos,
    naranjotes => Casilla.naranjotes,
    rojazos => Casilla.rojazos,
  };

  String get nombre => casilla.nombre;

  /// Lo que vale en promedio un pez pescado (para las pruebas).
  double get promedio {
    final total = tabla.fold<int>(0, (s, f) => s + f.$2);
    return tabla.fold<double>(0, (s, f) => s + f.$1 * f.$2) / total;
  }
}

/// La rueda: 53 casillas. Hielo blanco y azul alternados (23 y 23), y entre
/// ellos los peces: cuatro de Azulitos, dos de Naranjotes y un solo Rojazo.
abstract final class RuedaPesca {
  static final List<Casilla> casillas = _armar();

  static int get cantidad => casillas.length;

  /// Cuantas casillas hay de cada cosa.
  static int cuantas(Casilla tipo) => casillas.where((c) => c == tipo).length;

  static List<Casilla> _armar() {
    // Los peces repartidos alrededor, con el hielo entre uno y otro.
    const peces = [
      Casilla.rojazos,
      Casilla.azulitos,
      Casilla.naranjotes,
      Casilla.azulitos,
      Casilla.azulitos,
      Casilla.naranjotes,
      Casilla.azulitos,
    ];
    const hielos = [7, 7, 6, 7, 6, 7, 6];
    final rueda = <Casilla>[];
    var blanco = true;
    for (var i = 0; i < peces.length; i++) {
      rueda.add(peces[i]);
      for (var j = 0; j < hielos[i]; j++) {
        rueda.add(blanco ? Casilla.hieloBlanco : Casilla.hieloAzul);
        blanco = !blanco;
      }
    }
    return List.unmodifiable(rueda);
  }
}

/// Lo que se sortea antes de girar: las bolas de nieve, que caen sobre
/// casillas de hielo y multiplican lo que pagan, y la moneda de oro, que
/// multiplica todos los peces de un tipo. Hay rondas sin nada.
class Multiplicadores {
  const Multiplicadores({this.nieve = const {}, this.moneda});

  /// Casilla de la rueda -> cuanto multiplica (de 2 a 10).
  final Map<int, int> nieve;

  /// El pez que se lleva la moneda, y cuanto multiplica.
  final ({Pez pez, int por})? moneda;

  static const ninguno = Multiplicadores();

  bool get hayAlguno => nieve.isNotEmpty || moneda != null;

  /// Lo que multiplica la casilla [casilla] si es de hielo.
  int enHielo(int casilla) => nieve[casilla] ?? 1;

  /// Lo que multiplica la moneda a [pez] (1 si no le toco).
  int enPez(Pez pez) => moneda?.pez == pez ? moneda!.por : 1;
}

/// Una ronda entera, sorteada de una vez antes de mostrarla: los
/// multiplicadores, donde para la rueda y, si cae un pez, lo que vale el que
/// se pesca. La rueda, la moneda y la caña solo lo muestran.
class TiradaPesca {
  const TiradaPesca({
    required this.multiplicadores,
    required this.casilla,
    this.pesca,
  });

  final Multiplicadores multiplicadores;

  /// Donde para la rueda.
  final int casilla;

  /// Lo que vale el pez pescado, sin la moneda (solo si cae un pez).
  final double? pesca;

  Casilla get tipo => RuedaPesca.casillas[casilla];

  /// Cuanto paga a 1 lo que salio, para quien aposto ahi.
  double get pagaA1 {
    final pez = tipo.pez;
    if (pez == null) return multiplicadores.enHielo(casilla).toDouble();
    return (pesca ?? 0) * multiplicadores.enPez(pez);
  }
}

/// El azar de la pesca. Todo sale del azar seguro del telefono.
abstract final class SorteoPesca {
  /// Rondas sin ninguna bola de nieve.
  static const sinNieve = .2;

  /// Cuantas bolas caen cuando caen, con su peso.
  static const bolas = [(2, 15), (3, 25), (4, 30), (5, 20), (6, 10)];

  /// Lo que multiplica cada bola, con su peso.
  static const valoresNieve = [
    (2, 25),
    (3, 25),
    (4, 20),
    (5, 14),
    (7, 10),
    (10, 6),
  ];

  /// Rondas con moneda de oro.
  static const conMoneda = .35;

  /// A que pez le toca la moneda: al mas chico, mas seguido.
  static const pecesMoneda = [
    (Pez.azulitos, 50),
    (Pez.naranjotes, 33),
    (Pez.rojazos, 17),
  ];

  /// Lo que multiplica la moneda, con su peso.
  static const valoresMoneda = [
    (2, 28),
    (3, 24),
    (4, 16),
    (5, 12),
    (6, 8),
    (7, 6),
    (8, 4),
    (10, 2),
  ];

  static TiradaPesca tirada(math.Random azar) {
    final multiplicadores = sortearMultiplicadores(azar);
    final casilla = azar.nextInt(RuedaPesca.cantidad);
    final pez = RuedaPesca.casillas[casilla].pez;
    return TiradaPesca(
      multiplicadores: multiplicadores,
      casilla: casilla,
      pesca: pez == null ? null : pescar(pez, azar),
    );
  }

  static Multiplicadores sortearMultiplicadores(math.Random azar) {
    final nieve = <int, int>{};
    if (azar.nextDouble() >= sinNieve) {
      final hielos = [
        for (var i = 0; i < RuedaPesca.cantidad; i++)
          if (RuedaPesca.casillas[i].esHielo) i,
      ]..shuffle(azar);
      final cuantas = _elegir(bolas, azar);
      for (final casilla in hielos.take(cuantas)) {
        nieve[casilla] = _elegir(valoresNieve, azar);
      }
    }
    ({Pez pez, int por})? moneda;
    if (azar.nextDouble() < conMoneda) {
      moneda = (
        pez: _elegir(pecesMoneda, azar),
        por: _elegir(valoresMoneda, azar),
      );
    }
    return Multiplicadores(nieve: nieve, moneda: moneda);
  }

  /// Lo que vale el pez que se pesca.
  static double pescar(Pez pez, math.Random azar) => _elegir(pez.tabla, azar);

  static T _elegir<T>(List<(T, int)> opciones, math.Random azar) {
    final total = opciones.fold<int>(0, (s, o) => s + o.$2);
    var tiro = azar.nextInt(total);
    for (final (valor, peso) in opciones) {
      if (tiro < peso) return valor;
      tiro -= peso;
    }
    return opciones.last.$1;
  }

  /// Lo que devuelve en promedio cada ficha apostada en [casilla]: la cuenta
  /// exacta, con las bolas de nieve y la moneda. Un poco menos que 1: la
  /// ventaja de la casa.
  static double devolucion(Casilla casilla) {
    final n = RuedaPesca.cantidad;
    double promedio(List<(int, int)> opciones) {
      final total = opciones.fold<int>(0, (s, o) => s + o.$2);
      return opciones.fold<double>(0, (s, o) => s + o.$1 * o.$2) / total;
    }

    final pez = casilla.pez;
    if (pez == null) {
      // Cuantas bolas caen en promedio, repartidas entre los 46 hielos.
      final hielos = RuedaPesca.casillas.where((c) => c.esHielo).length;
      final bolasPorRonda = (1 - sinNieve) * promedio(bolas);
      final conBola = bolasPorRonda / hielos;
      final paga = 1 + conBola * (promedio(valoresNieve) - 1);
      return RuedaPesca.cuantas(casilla) / n * (1 + paga);
    }
    final pesoPez = pecesMoneda.firstWhere((p) => p.$1 == pez).$2;
    final totalPeces = pecesMoneda.fold<int>(0, (s, p) => s + p.$2);
    final moneda =
        1 + conMoneda * pesoPez / totalPeces * (promedio(valoresMoneda) - 1);
    return RuedaPesca.cuantas(casilla) / n * (1 + pez.promedio * moneda);
  }
}

/// Lo que cobra una apuesta que gano: la apuesta mas lo que paga.
typedef GanadaPesca = ({Casilla casilla, int monto, int cobra});

/// Lo que paso en una ronda.
class ResultadoPesca {
  const ResultadoPesca({
    required this.tirada,
    required this.ganadoras,
    required this.perdedoras,
  });

  final TiradaPesca tirada;
  final List<GanadaPesca> ganadoras;
  final List<({Casilla casilla, int monto})> perdedoras;

  int get apostado =>
      ganadoras.fold(0, (s, g) => s + g.monto) +
      perdedoras.fold(0, (s, p) => s + p.monto);

  /// Todo lo que vuelve a tus fichas.
  int get cobrado => ganadoras.fold(0, (s, g) => s + g.cobra);

  int get neto => cobrado - apostado;
}

/// Lo que se recuerda de cada ronda para el historial: que salio y cuanto
/// pagaba.
typedef SalidaPesca = ({Casilla casilla, double paga});

class EstadisticasPesca {
  EstadisticasPesca();

  factory EstadisticasPesca.desdeJson(Map<String, dynamic> json) =>
      EstadisticasPesca()
        ..giros = json['giros'] as int? ?? 0
        ..ganados = json['ganados'] as int? ?? 0
        ..apostado = json['apostado'] as int? ?? 0
        ..cobrado = json['cobrado'] as int? ?? 0
        ..mayorPremio = json['mayorPremio'] as int? ?? 0
        ..bonos = json['bonos'] as int? ?? 0
        ..mayorPesca = (json['mayorPesca'] as num?)?.toDouble() ?? 0
        ..fichasMaximas =
            json['fichasMaximas'] as int? ?? Casino.fichasIniciales
        ..rescates = json['rescates'] as int? ?? 0
        ..rachaActual = json['rachaActual'] as int? ?? 0
        ..mejorRacha = json['mejorRacha'] as int? ?? 0;

  int giros = 0;

  /// Giros en los que salio ganando.
  int ganados = 0;
  int apostado = 0;
  int cobrado = 0;
  int mayorPremio = 0;

  /// Veces que cayo un pez.
  int bonos = 0;

  /// El pez mas grande que salio, con su moneda (a 1).
  double mayorPesca = 0;
  int fichasMaximas = Casino.fichasIniciales;
  int rescates = 0;
  int rachaActual = 0;
  int mejorRacha = 0;

  int get porcentajeGanados => giros == 0 ? 0 : (ganados * 100 / giros).round();

  void registrar(ResultadoPesca resultado, {required int fichas}) {
    giros++;
    apostado += resultado.apostado;
    cobrado += resultado.cobrado;
    if (resultado.tirada.tipo.pez != null) {
      bonos++;
      mayorPesca = math.max(mayorPesca, resultado.tirada.pagaA1);
    }
    if (resultado.neto > 0) {
      ganados++;
      rachaActual++;
      mejorRacha = math.max(mejorRacha, rachaActual);
      mayorPremio = math.max(mayorPremio, resultado.neto);
    } else {
      rachaActual = 0;
    }
    fichasMaximas = math.max(fichasMaximas, fichas);
  }

  Map<String, dynamic> aJson() => {
    'giros': giros,
    'ganados': ganados,
    'apostado': apostado,
    'cobrado': cobrado,
    'mayorPremio': mayorPremio,
    'bonos': bonos,
    'mayorPesca': mayorPesca,
    'fichasMaximas': fichasMaximas,
    'rescates': rescates,
    'rachaActual': rachaActual,
    'mejorRacha': mejorRacha,
  };
}

/// La mesa de la pesca: las fichas, lo apostado y lo que fue saliendo.
class MesaPesca {
  MesaPesca({
    int? fichas,
    EstadisticasPesca? estadisticas,
    List<SalidaPesca>? historial,
    List<(Casilla, int)>? anterior,
  }) : fichas = fichas ?? Casino.fichasIniciales,
       estadisticas = estadisticas ?? EstadisticasPesca(),
       historial = [...?historial],
       _anterior = [...?anterior];

  static const apuestaMinima = 10;
  static const largoHistorial = 14;

  /// Las fichas que no estan apostadas.
  int fichas;
  final EstadisticasPesca estadisticas;

  /// Lo que fue saliendo, lo ultimo primero.
  final List<SalidaPesca> historial;

  final _apuestas = <Casilla, int>{};

  /// Cada ficha puesta, en orden: para deshacer de a una.
  final _puestas = <(Casilla, int)>[];

  /// Lo de la ronda anterior: para repetirla.
  List<(Casilla, int)> _anterior;

  Map<Casilla, int> get apuestas => Map.unmodifiable(_apuestas);

  int get enMesa => _apuestas.values.fold(0, (s, m) => s + m);

  /// Todas tus fichas, las apostadas incluidas.
  int get total => fichas + enMesa;

  int montoEn(Casilla casilla) => _apuestas[casilla] ?? 0;

  bool get hayApuestas => _apuestas.isNotEmpty;

  /// Sin tope: se puede apostar hasta la ultima ficha.
  bool puedeApostar(int monto) => monto >= apuestaMinima && monto <= fichas;

  int get todo => fichas;

  bool get puedeIrConTodo => fichas >= apuestaMinima;

  bool apostar(Casilla casilla, int monto) {
    if (!puedeApostar(monto)) return false;
    fichas -= monto;
    _apuestas[casilla] = montoEn(casilla) + monto;
    _puestas.add((casilla, monto));
    return true;
  }

  /// La misma ficha en los tres peces. Si no alcanza para los tres, nada.
  List<(Casilla, int)> apostarALosPeces(int monto) {
    if (monto < apuestaMinima || monto * 3 > fichas) return const [];
    return [
      for (final pez in Pez.values)
        if (apostar(pez.casilla, monto)) (pez.casilla, monto),
    ];
  }

  (Casilla, int)? deshacer() {
    if (_puestas.isEmpty) return null;
    final (casilla, monto) = _puestas.removeLast();
    final queda = montoEn(casilla) - monto;
    if (queda > 0) {
      _apuestas[casilla] = queda;
    } else {
      _apuestas.remove(casilla);
    }
    fichas += monto;
    return (casilla, monto);
  }

  Map<Casilla, int> borrar() {
    final todo = Map.of(_apuestas);
    fichas += enMesa;
    _apuestas.clear();
    _puestas.clear();
    return todo;
  }

  int get _sumaAnterior => _anterior.fold(0, (s, a) => s + a.$2);

  bool get puedeRepetir =>
      _apuestas.isEmpty && _anterior.isNotEmpty && _sumaAnterior <= fichas;

  List<(Casilla, int)> repetir() {
    if (!puedeRepetir) return const [];
    return [
      for (final (casilla, monto) in _anterior)
        if (apostar(casilla, monto)) (casilla, monto),
    ];
  }

  bool get puedeDoblar => _apuestas.isNotEmpty && enMesa <= fichas;

  List<(Casilla, int)> doblar() {
    if (!puedeDoblar) return const [];
    return [
      for (final MapEntry(key: casilla, value: monto) in Map.of(
        _apuestas,
      ).entries)
        if (apostar(casilla, monto)) (casilla, monto),
    ];
  }

  bool get enQuiebra => fichas + enMesa < apuestaMinima;

  /// MacIAs presta otra vez las fichas de regalo.
  void rescatar() {
    fichas += Casino.fichasIniciales;
    estadisticas.rescates++;
  }

  /// Salio [tirada]: cada apuesta ganadora cobra lo suyo mas lo que paga
  /// (lo que no da una ficha entera, se lo queda la casa); las demas se
  /// pierden.
  ResultadoPesca liquidar(TiradaPesca tirada) {
    final ganadoras = <GanadaPesca>[];
    final perdedoras = <({Casilla casilla, int monto})>[];
    for (final MapEntry(key: casilla, value: monto) in _apuestas.entries) {
      if (casilla == tirada.tipo) {
        final premio = (monto * tirada.pagaA1 + 1e-9).floor();
        ganadoras.add((casilla: casilla, monto: monto, cobra: monto + premio));
      } else {
        perdedoras.add((casilla: casilla, monto: monto));
      }
    }
    final resultado = ResultadoPesca(
      tirada: tirada,
      ganadoras: ganadoras,
      perdedoras: perdedoras,
    );
    fichas += resultado.cobrado;
    _anterior = [
      for (final MapEntry(key: casilla, value: monto) in _apuestas.entries)
        (casilla, monto),
    ];
    _apuestas.clear();
    _puestas.clear();
    historial.insert(0, (casilla: tirada.tipo, paga: tirada.pagaA1));
    if (historial.length > largoHistorial) historial.removeLast();
    estadisticas.registrar(resultado, fichas: fichas);
    return resultado;
  }

  /// Para guardar lo de la pesca (las fichas van aparte, en el casino).
  Map<String, dynamic> aJson() => {
    'estadisticas': estadisticas.aJson(),
    'historial': [
      for (final s in historial) {'c': s.casilla.name, 'x': s.paga},
    ],
    'anterior': [
      for (final (casilla, monto) in _anterior)
        {'c': casilla.name, 'monto': monto},
    ],
  };

  factory MesaPesca.desdeJson(Map<String, dynamic>? json, {int? fichas}) {
    if (json == null) return MesaPesca(fichas: fichas);
    Casilla? casilla(Object? nombre) =>
        Casilla.values.where((c) => c.name == nombre).firstOrNull;
    try {
      return MesaPesca(
        fichas: fichas,
        estadisticas: EstadisticasPesca.desdeJson(
          json['estadisticas'] as Map<String, dynamic>,
        ),
        historial: [
          for (final s in (json['historial'] as List<dynamic>? ?? const []))
            if (s is Map<String, dynamic>)
              if (casilla(s['c']) case final c?)
                (casilla: c, paga: (s['x'] as num?)?.toDouble() ?? 1),
        ],
        anterior: [
          for (final a in (json['anterior'] as List<dynamic>? ?? const []))
            if (a is Map<String, dynamic>)
              if (casilla(a['c']) case final c?) (c, a['monto'] as int? ?? 0),
        ].where((a) => a.$2 >= apuestaMinima).toList(),
      );
    } catch (_) {
      // Algo que ya no se entiende: la mesa empieza de nuevo.
      return MesaPesca(fichas: fichas);
    }
  }
}

/// "x0,1", "x5", "x12,5": un multiplicador como se lee en la mesa.
String textoPor(double valor) {
  if (valor == valor.roundToDouble()) return 'x${valor.round()}';
  return 'x${valor.toStringAsFixed(1).replaceAll('.', ',')}';
}
