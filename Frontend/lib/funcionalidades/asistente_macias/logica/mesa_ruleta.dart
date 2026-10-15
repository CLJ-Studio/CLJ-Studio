import 'dart:math' as math;

import 'casino.dart';

/// El cilindro europeo: un solo cero y los numeros en su orden de siempre,
/// en el sentido de las agujas del reloj desde el cero.
const ordenRueda = <int>[
  0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, //
  5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26,
];

const _rojos = {
  1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36, //
};

enum ColorRuleta { verde, rojo, negro }

ColorRuleta colorDe(int numero) => numero == 0
    ? ColorRuleta.verde
    : _rojos.contains(numero)
    ? ColorRuleta.rojo
    : ColorRuleta.negro;

/// Como lo canta el crupier: "17 negro", "cero".
String numeroDicho(int numero) => switch (colorDe(numero)) {
  ColorRuleta.verde => 'cero',
  ColorRuleta.rojo => '$numero rojo',
  ColorRuleta.negro => '$numero negro',
};

/// Todo lo que dice un numero: "Negro · Impar · Falta".
String detalleNumero(int numero) {
  if (numero == 0) return 'Cero · gana la casa';
  return [
    if (colorDe(numero) == ColorRuleta.rojo) 'Rojo' else 'Negro',
    if (numero.isEven) 'Par' else 'Impar',
    if (numero <= 18) 'Falta' else 'Pasa',
  ].join(' · ');
}

/// Las apuestas de la ruleta, con lo que paga cada una (a 1).
enum TipoApuesta {
  pleno(35),
  caballo(17),
  calle(11),
  trio(11),
  cuadro(8),
  primerosCuatro(8),
  linea(5),
  docena(2),
  columna(2),
  rojo(1),
  negro(1),
  par(1),
  impar(1),
  falta(1),
  pasa(1);

  const TipoApuesta(this.paga);

  final int paga;

  /// Las de afuera de los numeros: docenas, columnas y las de 1 a 1.
  bool get exterior => index >= TipoApuesta.docena.index;
}

/// Un lugar del paño: los numeros que cubre y como paga.
///
/// En el paño los numeros van en 12 filas de 3 (1-2-3 arriba, 34-35-36
/// abajo) y el cero encima de todo.
class Apuesta {
  Apuesta._(this.tipo, List<int> numeros)
    : numeros = List.unmodifiable(numeros..sort());

  factory Apuesta.pleno(int numero) {
    RangeError.checkValueInInterval(numero, 0, 36, 'numero');
    return Apuesta._(TipoApuesta.pleno, [numero]);
  }

  /// Dos numeros vecinos en el paño: uno al lado del otro, uno encima del
  /// otro, o el cero con el 1, el 2 o el 3.
  factory Apuesta.caballo(int a, int b) {
    final menor = math.min(a, b);
    final mayor = math.max(a, b);
    final valido =
        (menor == 0 && mayor >= 1 && mayor <= 3) ||
        (menor >= 1 && mayor <= 36 && mayor - menor == 3) ||
        (menor >= 1 &&
            mayor <= 36 &&
            mayor - menor == 1 &&
            (menor - 1) ~/ 3 == (mayor - 1) ~/ 3);
    if (!valido) throw ArgumentError('$a y $b no son vecinos en el paño');
    return Apuesta._(TipoApuesta.caballo, [menor, mayor]);
  }

  /// Los tres numeros de una fila (0 es la del 1-2-3).
  factory Apuesta.calle(int fila) {
    RangeError.checkValueInInterval(fila, 0, 11, 'fila');
    return Apuesta._(TipoApuesta.calle, [
      for (var c = 1; c <= 3; c++) 3 * fila + c,
    ]);
  }

  /// El cero con el 1 y el 2, o con el 2 y el 3.
  factory Apuesta.trio({required bool conElUno}) =>
      Apuesta._(TipoApuesta.trio, conElUno ? [0, 1, 2] : [0, 2, 3]);

  /// Cuatro numeros en cuadrado; [menor] es el de arriba a la izquierda.
  factory Apuesta.cuadro(int menor) {
    if (menor < 1 || menor > 32 || menor % 3 == 0) {
      throw ArgumentError('No hay cuadro desde el $menor');
    }
    return Apuesta._(TipoApuesta.cuadro, [
      menor,
      menor + 1,
      menor + 3,
      menor + 4,
    ]);
  }

  /// El 0, el 1, el 2 y el 3.
  factory Apuesta.primerosCuatro() =>
      Apuesta._(TipoApuesta.primerosCuatro, [0, 1, 2, 3]);

  /// Dos filas seguidas: seis numeros. [fila] es la de arriba (0 a 10).
  factory Apuesta.linea(int fila) {
    RangeError.checkValueInInterval(fila, 0, 10, 'fila');
    return Apuesta._(TipoApuesta.linea, [
      for (var n = 3 * fila + 1; n <= 3 * fila + 6; n++) n,
    ]);
  }

  /// Del 1 al 12 (0), del 13 al 24 (1) o del 25 al 36 (2).
  factory Apuesta.docena(int docena) {
    RangeError.checkValueInInterval(docena, 0, 2, 'docena');
    return Apuesta._(TipoApuesta.docena, [
      for (var n = 12 * docena + 1; n <= 12 * docena + 12; n++) n,
    ]);
  }

  /// La columna del 1 (0), la del 2 (1) o la del 3 (2).
  factory Apuesta.columna(int columna) {
    RangeError.checkValueInInterval(columna, 0, 2, 'columna');
    return Apuesta._(TipoApuesta.columna, [
      for (var n = columna + 1; n <= 36; n += 3) n,
    ]);
  }

  factory Apuesta.rojo() => Apuesta._(TipoApuesta.rojo, [
    for (var n = 1; n <= 36; n++)
      if (colorDe(n) == ColorRuleta.rojo) n,
  ]);

  factory Apuesta.negro() => Apuesta._(TipoApuesta.negro, [
    for (var n = 1; n <= 36; n++)
      if (colorDe(n) == ColorRuleta.negro) n,
  ]);

  factory Apuesta.par() =>
      Apuesta._(TipoApuesta.par, [for (var n = 2; n <= 36; n += 2) n]);

  factory Apuesta.impar() =>
      Apuesta._(TipoApuesta.impar, [for (var n = 1; n <= 36; n += 2) n]);

  /// Del 1 al 18.
  factory Apuesta.falta() =>
      Apuesta._(TipoApuesta.falta, [for (var n = 1; n <= 18; n++) n]);

  /// Del 19 al 36.
  factory Apuesta.pasa() =>
      Apuesta._(TipoApuesta.pasa, [for (var n = 19; n <= 36; n++) n]);

  /// De vuelta desde su [clave], o null si no es una apuesta valida.
  static Apuesta? desdeClave(String clave) {
    final partes = clave.split(':');
    if (partes.length != 2) return null;
    final tipo = TipoApuesta.values.where((t) => t.name == partes[0]);
    if (tipo.isEmpty) return null;
    final numeros = partes[1].split('-').map(int.tryParse).toList();
    if (numeros.any((n) => n == null)) return null;
    final n = numeros.cast<int>();
    try {
      final apuesta = switch (tipo.first) {
        TipoApuesta.pleno => Apuesta.pleno(n.single),
        TipoApuesta.caballo => Apuesta.caballo(n[0], n[1]),
        TipoApuesta.calle => Apuesta.calle((n.first - 1) ~/ 3),
        TipoApuesta.trio => Apuesta.trio(conElUno: n.contains(1)),
        TipoApuesta.cuadro => Apuesta.cuadro(n.first),
        TipoApuesta.primerosCuatro => Apuesta.primerosCuatro(),
        TipoApuesta.linea => Apuesta.linea((n.first - 1) ~/ 3),
        TipoApuesta.docena => Apuesta.docena((n.first - 1) ~/ 12),
        TipoApuesta.columna => Apuesta.columna(n.first - 1),
        TipoApuesta.rojo => Apuesta.rojo(),
        TipoApuesta.negro => Apuesta.negro(),
        TipoApuesta.par => Apuesta.par(),
        TipoApuesta.impar => Apuesta.impar(),
        TipoApuesta.falta => Apuesta.falta(),
        TipoApuesta.pasa => Apuesta.pasa(),
      };
      return apuesta.clave == clave ? apuesta : null;
    } catch (_) {
      return null;
    }
  }

  final TipoApuesta tipo;

  /// De menor a mayor.
  final List<int> numeros;

  /// Identifica el lugar: "caballo:17-20".
  String get clave => '${tipo.name}:${numeros.join('-')}';

  bool gana(int numero) => numeros.contains(numero);

  /// Lo que vuelve si gana: lo apostado mas el premio.
  int cobra(int monto) => monto * (tipo.paga + 1);

  static const _orden = ['Primera', 'Segunda', 'Tercera'];

  /// Como se llama en la mesa: "Caballo 17-20", "Rojo".
  String get nombre => switch (tipo) {
    TipoApuesta.pleno => 'Pleno al ${numeros.single}',
    TipoApuesta.caballo => 'Caballo ${numeros.join('-')}',
    TipoApuesta.calle => 'Calle ${numeros.join('-')}',
    TipoApuesta.trio => 'Trío ${numeros.join('-')}',
    TipoApuesta.cuadro => 'Cuadro ${numeros.join('-')}',
    TipoApuesta.primerosCuatro => 'Los cuatro primeros (0-1-2-3)',
    TipoApuesta.linea => 'Línea del ${numeros.first} al ${numeros.last}',
    TipoApuesta.docena => '${_orden[(numeros.first - 1) ~/ 12]} docena',
    TipoApuesta.columna => '${_orden[numeros.first - 1]} columna',
    TipoApuesta.rojo => 'Rojo',
    TipoApuesta.negro => 'Negro',
    TipoApuesta.par => 'Par',
    TipoApuesta.impar => 'Impar',
    TipoApuesta.falta => 'Falta (1 a 18)',
    TipoApuesta.pasa => 'Pasa (19 a 36)',
  };

  @override
  bool operator ==(Object other) => other is Apuesta && other.clave == clave;

  @override
  int get hashCode => clave.hashCode;

  @override
  String toString() => clave;
}

/// Una apuesta que gano: lo puesto y lo que vuelve (puesto mas premio).
typedef ApuestaGanadora = ({Apuesta apuesta, int monto, int cobra});

/// Lo que paso en un giro.
class ResultadoRuleta {
  const ResultadoRuleta({
    required this.numero,
    required this.ganadoras,
    required this.perdedoras,
  });

  final int numero;
  final List<ApuestaGanadora> ganadoras;
  final List<({Apuesta apuesta, int monto})> perdedoras;

  int get apostado =>
      ganadoras.fold(0, (s, g) => s + g.monto) +
      perdedoras.fold(0, (s, p) => s + p.monto);

  /// Lo que vuelve a tus fichas.
  int get cobrado => ganadoras.fold(0, (s, g) => s + g.cobra);

  int get neto => cobrado - apostado;

  bool get acertoPleno =>
      ganadoras.any((g) => g.apuesta.tipo == TipoApuesta.pleno);
}

/// Lo que se juega en la ruleta, entre una visita y otra.
class EstadisticasRuleta {
  EstadisticasRuleta();

  factory EstadisticasRuleta.desdeJson(Map<String, dynamic> json) {
    final e = EstadisticasRuleta()
      ..giros = json['giros'] as int? ?? 0
      ..ganados = json['ganados'] as int? ?? 0
      ..apostado = json['apostado'] as int? ?? 0
      ..cobrado = json['cobrado'] as int? ?? 0
      ..mayorPremio = json['mayorPremio'] as int? ?? 0
      ..plenos = json['plenos'] as int? ?? 0
      ..fichasMaximas = json['fichasMaximas'] as int? ?? Casino.fichasIniciales
      ..rescates = json['rescates'] as int? ?? 0
      ..rachaActual = json['rachaActual'] as int? ?? 0
      ..mejorRacha = json['mejorRacha'] as int? ?? 0;
    final veces = json['veces'] as List<dynamic>?;
    if (veces != null && veces.length == 37) {
      for (var n = 0; n < 37; n++) {
        e.veces[n] = veces[n] as int;
      }
    }
    return e;
  }

  int giros = 0;

  /// Giros en los que salio ganando.
  int ganados = 0;
  int apostado = 0;
  int cobrado = 0;
  int mayorPremio = 0;
  int plenos = 0;
  int fichasMaximas = Casino.fichasIniciales;
  int rescates = 0;
  int rachaActual = 0;
  int mejorRacha = 0;

  /// Cuantas veces salio cada numero, del 0 al 36.
  final veces = List<int>.filled(37, 0);

  int get porcentajeGanados => giros == 0 ? 0 : (ganados * 100 / giros).round();

  /// Los numeros que mas salieron (los "calientes"), hasta [cuantos].
  List<int> masSalidos(int cuantos) {
    final numeros = [
      for (var n = 0; n < 37; n++)
        if (veces[n] > 0) n,
    ]..sort((a, b) => veces[b].compareTo(veces[a]));
    return numeros.take(cuantos).toList();
  }

  void registrar(ResultadoRuleta resultado, {required int fichas}) {
    giros++;
    veces[resultado.numero]++;
    apostado += resultado.apostado;
    cobrado += resultado.cobrado;
    if (resultado.neto > 0) {
      ganados++;
      rachaActual++;
      mejorRacha = math.max(mejorRacha, rachaActual);
      mayorPremio = math.max(mayorPremio, resultado.neto);
    } else {
      rachaActual = 0;
    }
    if (resultado.acertoPleno) plenos++;
    fichasMaximas = math.max(fichasMaximas, fichas);
  }

  Map<String, dynamic> aJson() => {
    'giros': giros,
    'ganados': ganados,
    'apostado': apostado,
    'cobrado': cobrado,
    'mayorPremio': mayorPremio,
    'plenos': plenos,
    'fichasMaximas': fichasMaximas,
    'rescates': rescates,
    'rachaActual': rachaActual,
    'mejorRacha': mejorRacha,
    'veces': veces,
  };
}

/// La mesa de ruleta: las fichas, lo apostado en el paño y lo que va
/// saliendo.
class MesaRuleta {
  MesaRuleta({
    int? fichas,
    EstadisticasRuleta? estadisticas,
    List<int>? historial,
    List<(Apuesta, int)>? anterior,
  }) : fichas = fichas ?? Casino.fichasIniciales,
       estadisticas = estadisticas ?? EstadisticasRuleta(),
       historial = [...?historial],
       _anterior = [...?anterior];

  static const apuestaMinima = 10;

  /// Los ultimos numeros que se recuerdan.
  static const largoHistorial = 18;

  /// Las fichas que no estan en el paño.
  int fichas;
  final EstadisticasRuleta estadisticas;

  /// Lo que fue saliendo, el ultimo primero.
  final List<int> historial;

  final _apuestas = <Apuesta, int>{};

  /// Cada ficha puesta, en orden: para deshacer de a una.
  final _puestas = <(Apuesta, int)>[];

  /// Lo de la ronda anterior: para repetirla.
  List<(Apuesta, int)> _anterior;

  Map<Apuesta, int> get apuestas => Map.unmodifiable(_apuestas);

  List<(Apuesta, int)> get anterior => List.unmodifiable(_anterior);

  int get enMesa => _apuestas.values.fold(0, (s, m) => s + m);

  /// Todas tus fichas, las del paño incluidas.
  int get total => fichas + enMesa;

  int montoEn(Apuesta apuesta) => _apuestas[apuesta] ?? 0;

  bool get hayApuestas => _apuestas.isNotEmpty;

  /// Sin tope: se puede apostar hasta la ultima ficha que quede.
  bool puedeApostar(Apuesta apuesta, int monto) =>
      monto >= apuestaMinima && monto <= fichas;

  /// Todo lo que te queda fuera del paño, para ponerlo de una en un lugar:
  /// el "all in". Puede ser cualquier cantidad, no solo de las que se arman
  /// con las fichas del estante.
  int get todo => fichas;

  bool get puedeIrConTodo => fichas >= apuestaMinima;

  bool apostar(Apuesta apuesta, int monto) {
    if (!puedeApostar(apuesta, monto)) return false;
    fichas -= monto;
    _apuestas[apuesta] = montoEn(apuesta) + monto;
    _puestas.add((apuesta, monto));
    return true;
  }

  /// Saca la ultima ficha que se puso.
  (Apuesta, int)? deshacer() {
    if (_puestas.isEmpty) return null;
    final (apuesta, monto) = _puestas.removeLast();
    final queda = montoEn(apuesta) - monto;
    if (queda > 0) {
      _apuestas[apuesta] = queda;
    } else {
      _apuestas.remove(apuesta);
    }
    fichas += monto;
    return (apuesta, monto);
  }

  /// Levanta todo el paño: las fichas vuelven.
  Map<Apuesta, int> borrar() {
    final todo = Map.of(_apuestas);
    fichas += enMesa;
    _apuestas.clear();
    _puestas.clear();
    return todo;
  }

  int get _sumaAnterior => _anterior.fold(0, (s, a) => s + a.$2);

  bool get puedeRepetir =>
      _apuestas.isEmpty && _anterior.isNotEmpty && _sumaAnterior <= fichas;

  /// Pone otra vez lo de la ronda anterior.
  List<(Apuesta, int)> repetir() {
    if (!puedeRepetir) return const [];
    return [
      for (final (apuesta, monto) in _anterior)
        if (apostar(apuesta, monto)) (apuesta, monto),
    ];
  }

  bool get puedeDoblar => _apuestas.isNotEmpty && enMesa <= fichas;

  /// Dobla todo lo que hay en el paño.
  List<(Apuesta, int)> doblar() {
    if (!puedeDoblar) return const [];
    return [
      for (final MapEntry(key: apuesta, value: monto) in Map.of(
        _apuestas,
      ).entries)
        if (apostar(apuesta, monto)) (apuesta, monto),
    ];
  }

  /// Sin fichas ni para la apuesta minima.
  bool get enQuiebra => fichas + enMesa < apuestaMinima;

  /// MacIAs presta otra vez las fichas de regalo.
  void rescatar() {
    fichas += Casino.fichasIniciales;
    estadisticas.rescates++;
  }

  /// El numero que sale: el azar del telefono, todos con la misma chance.
  static int sortear(math.Random azar) => azar.nextInt(37);

  /// Salio [numero]: se paga lo que gano y la casa se lleva lo demas.
  ResultadoRuleta liquidar(int numero) {
    RangeError.checkValueInInterval(numero, 0, 36, 'numero');
    final ganadoras = <ApuestaGanadora>[];
    final perdedoras = <({Apuesta apuesta, int monto})>[];
    for (final MapEntry(key: apuesta, value: monto) in _apuestas.entries) {
      if (apuesta.gana(numero)) {
        ganadoras.add((
          apuesta: apuesta,
          monto: monto,
          cobra: apuesta.cobra(monto),
        ));
      } else {
        perdedoras.add((apuesta: apuesta, monto: monto));
      }
    }
    final resultado = ResultadoRuleta(
      numero: numero,
      ganadoras: ganadoras,
      perdedoras: perdedoras,
    );
    fichas += resultado.cobrado;
    _anterior = [
      for (final MapEntry(key: apuesta, value: monto) in _apuestas.entries)
        (apuesta, monto),
    ];
    _apuestas.clear();
    _puestas.clear();
    historial.insert(0, numero);
    if (historial.length > largoHistorial) historial.removeLast();
    estadisticas.registrar(resultado, fichas: fichas);
    return resultado;
  }

  /// Para guardar lo de la ruleta (las fichas van aparte, en el casino).
  Map<String, dynamic> aJson() => {
    'estadisticas': estadisticas.aJson(),
    'historial': historial,
    'anterior': [
      for (final (apuesta, monto) in _anterior)
        {'clave': apuesta.clave, 'monto': monto},
    ],
  };

  /// La mesa como quedo, con [fichas] del casino.
  factory MesaRuleta.desdeJson(Map<String, dynamic>? json, {int? fichas}) {
    if (json == null) return MesaRuleta(fichas: fichas);
    try {
      return MesaRuleta(
        fichas: fichas,
        estadisticas: EstadisticasRuleta.desdeJson(
          json['estadisticas'] as Map<String, dynamic>,
        ),
        historial: [
          for (final n in (json['historial'] as List<dynamic>? ?? const []))
            if (n is int && n >= 0 && n <= 36) n,
        ],
        anterior: [
          for (final a in (json['anterior'] as List<dynamic>? ?? const []))
            if (a is Map<String, dynamic>)
              if (Apuesta.desdeClave(a['clave'] as String? ?? '')
                  case final apuesta?)
                (apuesta, a['monto'] as int? ?? 0),
        ].where((a) => a.$2 >= apuestaMinima).toList(),
      );
    } catch (_) {
      // Algo que ya no se entiende: la mesa empieza de nuevo.
      return MesaRuleta(fichas: fichas);
    }
  }
}
