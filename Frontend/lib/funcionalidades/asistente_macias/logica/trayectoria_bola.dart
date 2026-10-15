import 'dart:math' as math;

import 'mesa_ruleta.dart';

/// Donde esta la bola en un instante: su angulo en la pantalla, a que
/// distancia del centro (en partes del radio de la rueda) y cuanto esta
/// saltando (0 apoyada, 1 lo mas alto de un salto).
typedef PosicionBola = ({double angulo, double radio, double altura});

/// Lo que se oye mientras gira: cuando y con que fuerza (0 a 1).
enum TipoGolpe { lanzamiento, rombo, casilla }

typedef GolpeBola = ({double segundo, TipoGolpe tipo, double fuerza});

/// Las medidas de la rueda que importan para la bola, en partes de su radio.
abstract final class RadiosRueda {
  /// Por donde rueda la bola mientras tiene velocidad.
  static const carril = .868;

  /// El centro del anillo de casillas, donde termina.
  static const casillas = .556;

  /// El radio de la bola.
  static const bola = .031;
}

/// Un giro de la ruleta, de principio a fin, armado para que la bola caiga
/// justo en el numero que ya salio.
///
/// El numero se sortea antes (con el azar del telefono) y aca solo se
/// calcula el camino: el cilindro gira a favor de las agujas del reloj y
/// frena despacio; la bola, lanzada en contra, da sus vueltas por el carril
/// perdiendo velocidad, cae, golpea un rombo, rebota entre las casillas y
/// se queda en la suya. Lo unico que se ajusta para acertar es la fuerza
/// del lanzamiento, en menos de una vuelta sobre seis o siete: no se nota.
///
/// Los angulos son de la pantalla (y hacia abajo): positivo es el sentido
/// de las agujas del reloj. Los tiempos, en segundos desde el lanzamiento.
class TrayectoriaBola {
  TrayectoriaBola({
    required this.casilla,
    required double ruedaInicial,
    double bolaInicial = -math.pi / 2,
    this.escala = 1,
    math.Random? azar,
  }) : assert(casilla >= 0 && casilla < 37),
       _rueda0 = ruedaInicial,
       _bola0 = bolaInicial {
    final r = azar ?? math.Random();
    // Cada giro un poco distinto: el crupier no lanza siempre igual.
    _vueltasRueda = .40 + .1 * r.nextDouble();
    _tCarril = 4.15 + .6 * r.nextDouble();
    _tCasillas = _tCarril + .72 + .1 * r.nextDouble();
    _rebotes = 1.45 + .3 * r.nextDouble();
    _subida = .25 + .25 * r.nextDouble();
    _calcularLanzamiento(nominal: 2 * math.pi * (2.45 + .35 * r.nextDouble()));
  }

  /// La casilla donde termina (su lugar en [ordenRueda]).
  final int casilla;

  /// Menos de 1: el giro rapido. Todo pasa igual, en menos tiempo.
  final double escala;

  final double _rueda0;
  final double _bola0;

  // El cilindro: velocidad inicial (vueltas por segundo) y cuanto tarda en
  // frenar.
  late final double _vueltasRueda;
  static const _frenoRueda = 12.0;

  // La bola: cuando deja el carril, cuando entra en las casillas y cuanto
  // tarda en quedarse quieta.
  late final double _tCarril;
  late final double _tCasillas;
  late final double _rebotes;
  late final double _subida;
  static const _frenoBola = 3.0;

  late double _velocidadBola;
  late double _recorridoCasillas;

  /// Cuando el rombo la hace saltar, en partes de la caida.
  static const _momentoRombo = .42;

  /// Cuando cae en cada casilla durante los rebotes (en partes del tiempo de
  /// rebote) y que tan alto salta despues.
  static const _caidas = [0.0, .29, .51, .67, .79, .88];
  static const _saltos = [.55, .34, .2, .11, .05];

  /// Cuanto dura, hasta que la bola queda quieta.
  double get duracion => (_tCasillas + _rebotes) * escala;

  /// Cuando la bola deja el carril (para que MacIAs diga "no va más" antes).
  double get dejaElCarril => _tCarril * escala;

  /// El angulo, en el cilindro, del centro de una casilla.
  static double anguloCasilla(int casilla) =>
      -math.pi / 2 + casilla * 2 * math.pi / ordenRueda.length;

  double get _velocidadRueda0 => 2 * math.pi * _vueltasRueda;

  double _anguloRuedaSin(double u) =>
      _rueda0 +
      _velocidadRueda0 * _frenoRueda * (1 - math.exp(-u / _frenoRueda));

  double _velocidadRuedaSin(double u) =>
      _velocidadRueda0 * math.exp(-u / _frenoRueda);

  /// El giro del cilindro en [segundo].
  double anguloRueda(double segundo) => _anguloRuedaSin(segundo / escala);

  /// La fuerza del lanzamiento para que la bola entre en las casillas con
  /// la velocidad justa y frene exactamente en la suya.
  ///
  /// Al entrar a las casillas la bola va, respecto del cilindro, a una
  /// velocidad que despues se gasta en [_rebotes] segundos con una curva
  /// (1 - s)^3: eso le hace recorrer un tramo fijo (lo que se le suma al
  /// angulo de la casilla). Todo es lineal en la velocidad inicial, asi que
  /// se despeja de una.
  void _calcularLanzamiento({required double nominal}) {
    final caida = math.exp(-_tCasillas / _frenoBola);
    final k = _frenoBola * (1 - caida);
    final a = k + caida * _rebotes / 3;
    final ruedaEnCasillas = _anguloRuedaSin(_tCasillas);
    final b =
        _bola0 -
        ruedaEnCasillas -
        anguloCasilla(casilla) -
        _velocidadRuedaSin(_tCasillas) * _rebotes / 3;
    // Entre las velocidades que acertan (una cada 2 pi), la primera que no
    // sea mas floja que la natural.
    final m = ((nominal * a - b) / (2 * math.pi)).ceil();
    _velocidadBola = (b + 2 * math.pi * m) / a;
    _recorridoCasillas =
        (_velocidadBola * caida + _velocidadRuedaSin(_tCasillas)) *
        _rebotes /
        3;
  }

  /// Lo que recorrio la bola (en contra de las agujas) hasta [u].
  double _recorrido(double u) =>
      _velocidadBola * _frenoBola * (1 - math.exp(-u / _frenoBola));

  /// Donde esta la bola en [segundo].
  PosicionBola bola(double segundo) {
    final u = segundo / escala;
    if (u <= _tCarril) {
      return (
        angulo: _bola0 - _recorrido(u),
        radio: RadiosRueda.carril,
        altura: 0,
      );
    }
    if (u <= _tCasillas) {
      // Baja por el cono hacia las casillas, cada vez mas rapido; a mitad
      // de camino golpea un rombo y salta.
      final p = (u - _tCarril) / (_tCasillas - _tCarril);
      var radio =
          RadiosRueda.carril -
          (RadiosRueda.carril - RadiosRueda.casillas) * p * p;
      var altura = 0.0;
      if (p > _momentoRombo) {
        final q = (p - _momentoRombo) / (1 - _momentoRombo);
        altura = _subida * 4 * q * (1 - q);
        radio += .035 * math.sin(math.pi * q);
      }
      return (angulo: _bola0 - _recorrido(u), radio: radio, altura: altura);
    }
    final s = u - _tCasillas;
    final rueda = _anguloRuedaSin(u);
    if (s >= _rebotes) {
      return (
        angulo: rueda + anguloCasilla(casilla),
        radio: RadiosRueda.casillas,
        altura: 0,
      );
    }
    final f = s / _rebotes;
    // Rebota entre los separadores: va y viene un poco mientras frena.
    final ancho = 2 * math.pi / ordenRueda.length;
    final vaiven =
        .45 *
        ancho *
        math.pow(math.sin(3 * math.pi * f), 2) *
        (1 - f) *
        (1 - f);
    final angulo =
        rueda +
        anguloCasilla(casilla) +
        _recorridoCasillas * math.pow(1 - f, 3) +
        vaiven;
    var altura = 0.0;
    for (var k = 0; k < _saltos.length; k++) {
      final desde = _caidas[k];
      final hasta = _caidas[k + 1];
      if (f >= desde && f < hasta) {
        final q = (f - desde) / (hasta - desde);
        altura = _saltos[k] * 4 * q * (1 - q);
        break;
      }
    }
    // En los saltos sube un poquito por la pared de la casilla.
    return (
      angulo: angulo,
      radio: RadiosRueda.casillas + .025 * altura,
      altura: altura,
    );
  }

  /// Lo que suena y cuando: el lanzamiento, el rombo y cada caida en una
  /// casilla, cada vez mas suave.
  List<GolpeBola> get golpes => [
    (segundo: 0, tipo: TipoGolpe.lanzamiento, fuerza: 1),
    (
      segundo: (_tCarril + (_tCasillas - _tCarril) * _momentoRombo) * escala,
      tipo: TipoGolpe.rombo,
      fuerza: .8 + .2 * _subida,
    ),
    for (final (k, caida) in _caidas.indexed)
      (
        segundo: (_tCasillas + caida * _rebotes) * escala,
        tipo: TipoGolpe.casilla,
        fuerza: math.pow(.72, k).toDouble(),
      ),
  ];
}
