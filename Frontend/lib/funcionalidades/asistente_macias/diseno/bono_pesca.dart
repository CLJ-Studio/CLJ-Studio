import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../logica/mesa_pesca.dart';
import '../logica/sonidos_casino.dart';
import 'crupier_macias.dart';
import 'dibujos_pesca.dart';
import 'fichas_blackjack.dart';

/// Las etapas del bono, en orden.
enum EtapaBono { hielo, cardumen, pesca, captura, tarjeta }

/// Con que se saca el pez: cuanto mas vale (mas pesa), mas grande el
/// equipo. Cada uno llega cuando el medidor pasa su [desde].
enum Equipo {
  cana(0),
  grua(10),
  helicoptero(25),
  carga(50),
  robot(100);

  const Equipo(this.desde);

  /// Desde cuanto vale el pez hace falta.
  final double desde;

  /// El equipo que hace falta para un pez que vale [valor].
  static Equipo para(double valor) =>
      values.lastWhere((e) => valor >= e.desde - 1e-9);
}

/// Un tramo de la pesca: el medidor sube de [desde] a [hasta] mientras sale
/// del hoyo el pez [cual] (0 el chico del engaño, 1 el de verdad).
typedef TramoPesca = ({
  double inicio,
  double fin,
  double desde,
  double hasta,
  int cual,
});

/// Cuando llega un equipo y cuanto tarda en llegar.
typedef LlegadaEquipo = ({double cuando, Equipo equipo, double dura});

/// La pesca entera, decidida antes de mostrarla. Los tiempos van en
/// segundos desde que empieza la pesca.
///
/// El medidor sube sin parar, de x0,1 hasta lo pescado, y el pez sale del
/// hoyo a la par. Cada vez que pasa el [Equipo.desde] de un equipo se
/// detiene: llega el equipo nuevo y agarra el hilo. Con [engano] (solo
/// naranjotes y rojazos grandes), primero sale entero un pez chico que vale
/// eso y parece que termino; pero sale del hielo uno gigante, se lo traga y
/// la pesca sigue.
class GuionPesca {
  GuionPesca({required this.pesca, this.engano, this.ritmo = 1}) {
    double s(double segundos) => segundos * ritmo;
    var t = s(.8);
    var v = .1;
    var cual = engano == null ? 1 : 0;

    // Sube parejo en veces: de x1 a x10 tarda lo mismo que de x10 a x100.
    // El ultimo tramo se hace esperar un poco mas.
    void tramo(double hasta, {bool ultimo = false}) {
      final dura = s(.5 + .55 * math.log(hasta / v) + (ultimo ? .7 : 0));
      tramos.add((
        inicio: t,
        fin: t + dura,
        desde: v,
        hasta: hasta,
        cual: cual,
      ));
      t += dura;
      v = hasta;
    }

    void subir(double hasta, {bool ultimo = false}) {
      for (final equipo in Equipo.values.skip(1)) {
        if (equipo.desde > v + 1e-9 && equipo.desde <= hasta + 1e-9) {
          tramo(equipo.desde);
          final dura = s(equipo == Equipo.robot ? 2.2 : 1.6);
          llegadas.add((cuando: t, equipo: equipo, dura: dura));
          t += dura;
        }
      }
      tramo(hasta, ultimo: ultimo);
    }

    final chico = engano;
    if (chico != null) {
      subir(chico);
      chicoAfuera = t;
      t += s(1.2);
      trago = t;
      t += duraTrago;
      cual = 1;
    }
    subir(pesca, ultimo: true);
    afuera = t;
    fin = t + s(.6);
  }

  /// Lo que vale el pez de verdad, sin la moneda.
  final double pesca;

  /// Lo que vale el pez chico del engaño, si hay.
  final double? engano;

  /// 1 normal; mas chico, mas rapido.
  final double ritmo;

  final tramos = <TramoPesca>[];
  final llegadas = <LlegadaEquipo>[];

  /// Cuando termina de salir el pez chico del engaño.
  double? chicoAfuera;

  /// Cuando sale el gigante a tragarse al chico.
  double? trago;

  /// Cuando termina de salir el pez de verdad.
  late final double afuera;

  /// Cuando termina la pesca.
  late final double fin;

  /// Lo que tarda el gigante en tragarse al chico y volver al agua.
  double get duraTrago => 1.9 * ritmo;

  /// El pez chico del engaño: solo con naranjotes y rojazos de x20 para
  /// arriba, y la mitad de las veces. Vale poco (de x1 a x8): parece que la
  /// pesca termina ahi.
  static double? elegirEngano(Pez pez, double pesca, math.Random azar) {
    if (pez == Pez.azulitos || pesca < 20) return null;
    if (azar.nextDouble() >= .5) return null;
    final chicos = [
      for (final (v, _) in pez.tabla)
        if (v >= 1 && v <= 8) v,
    ];
    return chicos[azar.nextInt(chicos.length)];
  }

  /// Lo largo del pez, en altos de la escena: los que valen mucho son
  /// enormes.
  static double largo(double valor) =>
      .13 * math.pow(1 + valor, .33).toDouble();

  /// Lo grueso del pez, en proporcion a lo largo: los enormes son largos y
  /// flacos.
  static double grosor(double valor) =>
      (.56 - .05 * math.log(1 + valor)).clamp(.3, .56);

  /// Lo que marca el medidor en el segundo [t].
  double valor(double t) {
    var v = .1;
    for (final tramo in tramos) {
      if (t <= tramo.inicio) return v;
      if (t < tramo.fin) {
        final u = Curves.easeInOutSine.transform(
          (t - tramo.inicio) / (tramo.fin - tramo.inicio),
        );
        return tramo.desde * math.pow(tramo.hasta / tramo.desde, u).toDouble();
      }
      v = tramo.hasta;
    }
    return v;
  }

  /// Cuanto salio del agua el pez [cual] en el segundo [t] (0 a 1): sale
  /// mientras el medidor sube y se queda quieto mientras llega un equipo.
  double salida(int cual, double t) {
    var total = 0.0;
    var hecho = 0.0;
    for (final tramo in tramos) {
      if (tramo.cual != cual) continue;
      final dura = tramo.fin - tramo.inicio;
      total += dura;
      hecho += (t - tramo.inicio).clamp(0.0, dura);
    }
    return total == 0 ? 1 : hecho / total;
  }

  /// El medidor esta subiendo.
  bool subiendo(double t) =>
      tramos.any((tramo) => t >= tramo.inicio && t < tramo.fin);

  /// El ultimo tiron, antes de que salga: la caña da sacudones.
  bool tironFinal(double t) {
    final ultimo = tramos.last;
    return t < ultimo.fin &&
        t >= ultimo.fin - (ultimo.fin - ultimo.inicio) * .45;
  }

  LlegadaEquipo? llegadaDe(Equipo equipo) =>
      llegadas.where((l) => l.equipo == equipo).firstOrNull;

  /// Quien tiene el hilo en el segundo [t]: el equipo nuevo lo agarra a los
  /// dos tercios de su llegada.
  Equipo sostiene(double t) {
    var quien = Equipo.cana;
    for (final llegada in llegadas) {
      if (t >= llegada.cuando + llegada.dura * .7) quien = llegada.equipo;
    }
    return quien;
  }

  /// Cuando suelta el hilo [equipo] porque lo agarra el siguiente; null si
  /// no lo suelta.
  double? soltado(Equipo equipo) {
    final i = equipo == Equipo.cana
        ? -1
        : llegadas.indexWhere((l) => l.equipo == equipo);
    if (equipo != Equipo.cana && i < 0) return null;
    if (i + 1 >= llegadas.length) return null;
    final siguiente = llegadas[i + 1];
    return siguiente.cuando + siguiente.dura * .7;
  }
}

/// Lo que marca el medidor: con un decimal debajo de x1; entero de ahi para
/// arriba.
String textoMedidor(double valor) =>
    valor >= 1 ? 'x${valor.floor()}' : textoPor((valor * 10).floor() / 10);

/// El bono de pesca: cayo un pez en la rueda y MacIAs va a pescar.
///
///  1. Todo se congela y la casilla del pez baja girando al hoyo.
///  2. Abajo del hielo nada el cardumen, cada pez con lo que puede valer.
///  3. MacIAs recoge el hilo: el medidor de oro sube y el pez sale del hoyo
///     a la par, cada vez mas grande. Si pesa mucho llega la grua, despues
///     un helicoptero, uno de carga y, para los enormes, un robot que sale
///     del hielo. A veces (naranjotes y rojazos) sale uno chico y un
///     gigante se lo traga.
///  4. El pez queda colgando con lo que vale; si su pez tenia moneda, se
///     multiplica.
///  5. La tarjeta: lo que pago.
///
/// Lo que se pesca ya viene sorteado: la escena solo lo muestra.
class BonoPesca extends StatefulWidget {
  const BonoPesca({
    required this.pez,
    required this.pesca,
    required this.moneda,
    required this.apostado,
    required this.premio,
    required this.alTerminar,
    this.sonar,
    this.ritmo = 1,
    this.azar,
    super.key,
  });

  final Pez pez;

  /// Lo que vale el pez pescado, sin la moneda.
  final double pesca;

  /// Lo que multiplica la moneda (1 si no le toco).
  final int moneda;

  /// Lo apostado a este pez (0 si nada).
  final int apostado;

  /// Lo que se gana ademas de la apuesta.
  final int premio;
  final VoidCallback alTerminar;
  final void Function(SonidoMesa sonido, {double volumen})? sonar;

  /// 1 normal; mas chico, mas rapido.
  final double ritmo;

  /// Para lo que no decide nada: si hay engaño y de cuanto es el chico.
  final math.Random? azar;

  @override
  State<BonoPesca> createState() => _BonoPescaState();
}

class _BonoPescaState extends State<BonoPesca>
    with SingleTickerProviderStateMixin {
  late final Ticker _reloj = createTicker(_alTick);
  final _tiempo = ValueNotifier<double>(0);

  late final GuionPesca _guion = GuionPesca(
    pesca: widget.pesca,
    engano: GuionPesca.elegirEngano(
      widget.pez,
      widget.pesca,
      widget.azar ?? math.Random(),
    ),
    ritmo: widget.ritmo,
  );

  /// Cuando empieza cada etapa, en segundos.
  late final Map<EtapaBono, double> _inicio;
  late final double _fin;
  final _sonados = <String>{};
  double _proximoCarrete = 0;
  bool _terminado = false;

  /// La camara del lago: se aleja cuando el pez y el equipo no entran.
  double _camara = 1;
  Size? _tamano;

  /// El paisaje del lago grabado, para el tamaño que tiene.
  ui.Picture? _paisaje;
  Size? _tamanoPaisaje;

  double _s(double segundos) => segundos * widget.ritmo;

  @override
  void initState() {
    super.initState();
    var t = 0.0;
    _inicio = {};
    for (final (etapa, dura) in [
      (EtapaBono.hielo, _s(1.9)),
      (EtapaBono.cardumen, _s(3.6)),
      (EtapaBono.pesca, _guion.fin),
      (EtapaBono.captura, _s(widget.moneda > 1 ? 2.9 : 2.1)),
      (EtapaBono.tarjeta, _s(2.9)),
    ]) {
      _inicio[etapa] = t;
      t += dura;
    }
    _fin = t;
    _reloj.start();
  }

  @override
  void dispose() {
    _paisaje?.dispose();
    _reloj.dispose();
    _tiempo.dispose();
    super.dispose();
  }

  void _alTick(Duration transcurrido) {
    final t = transcurrido.inMicroseconds / 1e6 + _salteado;
    final dt = t - _tiempo.value;
    final tamano = _tamano;
    final enLago = t - _inicio[EtapaBono.pesca]!;
    if (tamano != null && enLago >= 0) {
      // La camara va y viene suave, como si la manejara alguien.
      final ideal = _Escena(tamano, enLago, _guion, widget.pez).camaraIdeal;
      _camara = dt > 0 && dt < .5
          ? _camara + (ideal - _camara) * (1 - math.exp(-dt * 2.4))
          : ideal;
    }
    _tiempo.value = t;
    _sonidos(t);
    if (t >= _fin && !_terminado) {
      _terminado = true;
      _reloj.stop();
      widget.alTerminar();
    }
  }

  EtapaBono _etapa(double t) {
    var actual = EtapaBono.hielo;
    for (final etapa in EtapaBono.values) {
      if (t >= _inicio[etapa]!) actual = etapa;
    }
    return actual;
  }

  /// Cuanto va de la etapa, de 0 a 1.
  double _de(EtapaBono etapa, double t) {
    final inicio = _inicio[etapa]!;
    final i = EtapaBono.values.indexOf(etapa);
    final fin = i + 1 < EtapaBono.values.length
        ? _inicio[EtapaBono.values[i + 1]]!
        : _fin;
    return ((t - inicio) / math.max(.001, fin - inicio)).clamp(0.0, 1.0);
  }

  /// Suena una sola vez, cuando llega su momento. Si ya paso hace rato (se
  /// salto), no suena.
  void _una(String clave, double t, double cuando, VoidCallback que) {
    if (t < cuando || !_sonados.add(clave)) return;
    if (t - cuando < .35) que();
  }

  void _sonidos(double t) {
    final sonar = widget.sonar;
    if (sonar == null) return;
    _una('hielo', t, _s(.1), () => sonar(SonidoMesa.hielo, volumen: .9));
    _una('hoyo', t, _s(1.45), () => sonar(SonidoMesa.chapuzon, volumen: .55));
    _una(
      'burbujas',
      t,
      _inicio[EtapaBono.cardumen]! + _s(.1),
      () => sonar(SonidoMesa.burbujas, volumen: .7),
    );
    final pesca = _inicio[EtapaBono.pesca]!;
    final captura = _inicio[EtapaBono.captura]!;
    final g = _guion;
    final enLago = t - pesca;
    _una(
      'pica',
      t,
      pesca + _s(.8),
      () => sonar(SonidoMesa.chapuzon, volumen: .45),
    );
    // El carrete recoge mientras el medidor sube.
    if (t < captura && g.subiendo(enLago) && t >= _proximoCarrete) {
      _proximoCarrete = t + _s(.42);
      sonar(SonidoMesa.carrete, volumen: g.tironFinal(enLago) ? .95 : .65);
    }
    for (final (i, llegada) in g.llegadas.indexed) {
      _una('llega$i', t, pesca + llegada.cuando, () {
        RetroalimentacionHaptica.accion();
        switch (llegada.equipo) {
          case Equipo.grua:
            sonar(SonidoMesa.grua, volumen: .9);
          case Equipo.helicoptero:
            sonar(SonidoMesa.helicoptero, volumen: .85);
          case Equipo.carga:
            sonar(SonidoMesa.helicoptero);
          case Equipo.robot:
            sonar(SonidoMesa.hielo);
            sonar(SonidoMesa.robot);
          case Equipo.cana:
            break;
        }
      });
    }
    if (g.chicoAfuera case final chico?) {
      _una(
        'chico',
        t,
        pesca + chico,
        () => sonar(SonidoMesa.chapuzon, volumen: .6),
      );
    }
    if (g.trago case final trago?) {
      final dura = g.duraTrago;
      _una('quiebra', t, pesca + trago + dura * .1, () {
        RetroalimentacionHaptica.exito();
        sonar(SonidoMesa.hielo);
        sonar(SonidoMesa.chapuzon);
      });
      _una(
        'traga',
        t,
        pesca + trago + dura * .44,
        () => sonar(SonidoMesa.trago),
      );
    }
    _una('afuera', t, pesca + g.afuera, () {
      RetroalimentacionHaptica.accion();
      sonar(SonidoMesa.chapuzon);
    });
    if (widget.moneda > 1) {
      _una('moneda', t, captura + _s(1.3), () => sonar(SonidoMesa.moneda));
    }
    _una(
      'tarjeta',
      t,
      _inicio[EtapaBono.tarjeta]!,
      () => sonar(
        widget.apostado > 0 ? SonidoMesa.ganar : SonidoMesa.boton,
        volumen: .85,
      ),
    );
  }

  /// Lo que se salto con "Saltar", en segundos: el reloj sigue de ahi.
  double _salteado = 0;

  void _saltar() {
    final tarjeta = _inicio[EtapaBono.tarjeta]!;
    final t = _tiempo.value;
    if (t >= tarjeta) return;
    _salteado += tarjeta - t;
    _proximoCarrete = double.infinity;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: _tiempo,
    builder: (context, t, _) {
      final etapa = _etapa(t);
      final cardumen = _inicio[EtapaBono.cardumen]!;
      final enCardumen = _de(EtapaBono.cardumen, t);
      return Stack(
        fit: StackFit.expand,
        children: [
          // Cada escena entra sobre la anterior, que sigue debajo hasta que
          // la tapa: a traves del bono nunca se ve la mesa.
          if (etapa == EtapaBono.hielo ||
              (etapa == EtapaBono.cardumen && enCardumen < .2))
            _escenaHielo(etapa == EtapaBono.hielo ? t : cardumen),
          if (etapa == EtapaBono.cardumen ||
              (etapa == EtapaBono.pesca &&
                  t < _inicio[EtapaBono.pesca]! + _s(.5)))
            _Cardumen(
              key: const ValueKey('cardumen'),
              pez: widget.pez,
              tiempo: t - cardumen,
              entrada: enCardumen,
            ),
          if (etapa.index >= EtapaBono.pesca.index) _escenaPesca(t, etapa),
          if (etapa == EtapaBono.tarjeta) _tarjeta(t),
          if (etapa.index < EtapaBono.tarjeta.index)
            Positioned(
              top: 8,
              right: 10,
              child: SafeArea(
                child: TextButton.icon(
                  onPressed: _saltar,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: .28),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.fast_forward_rounded, size: 18),
                  label: const Text(
                    'Saltar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  // =================================================================== hielo
  Widget _escenaHielo(double t) {
    final p = _de(EtapaBono.hielo, t);
    final escarcha = Curves.easeOut.transform((p / .3).clamp(0.0, 1.0));
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: escarcha,
          child: RepaintBoundary(
            child: CustomPaint(painter: _PintorEscarcha(avance: p)),
          ),
        ),
        LayoutBuilder(
          builder: (context, caja) {
            final centro = caja.biggest.center(Offset.zero);
            // La casilla del pez sube desde abajo, gira y se hunde en el hoyo.
            final sube = Curves.easeOutCubic.transform(
              ((p - .12) / .38).clamp(0.0, 1.0),
            );
            final hunde = Curves.easeInCubic.transform(
              ((p - .55) / .4).clamp(0.0, 1.0),
            );
            final y = ui.lerpDouble(caja.maxHeight + 60, centro.dy + 40, sube)!;
            final escala = (1 - hunde) * (.8 + .4 * sube);
            final hoyo = Curves.easeOutBack.transform(
              ((p - .45) / .3).clamp(0.0, 1.0),
            );
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: centro.dy - 150,
                  child: Opacity(
                    opacity: escarcha,
                    child: _TituloHielo(brillo: (p - .2) / .45 * 1.6 - .3),
                  ),
                ),
                if (hoyo > 0)
                  Positioned(
                    left: centro.dx - 70 * hoyo,
                    top: centro.dy + 40 - 26 * hoyo,
                    width: 140 * hoyo,
                    height: 52 * hoyo,
                    child: const CustomPaint(painter: _PintorHoyoChico()),
                  ),
                if (escala > .02)
                  Positioned(
                    left: centro.dx - 48,
                    top: y - 48,
                    width: 96,
                    height: 96,
                    child: Transform.rotate(
                      angle: (sube + hunde) * math.pi * 1.5,
                      child: Transform.scale(
                        scale: escala,
                        child: _CasillaPez(pez: widget.pez),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =================================================================== pesca
  Widget _escenaPesca(double t, EtapaBono etapa) {
    final g = _guion;
    final enLago = t - _inicio[EtapaBono.pesca]!;
    final inicioCaptura = _inicio[EtapaBono.captura]!;
    final entrada = (enLago / _s(.5)).clamp(0.0, 1.0);
    final enCaptura = etapa.index >= EtapaBono.captura.index;
    final total = widget.pesca * widget.moneda;
    final conMoneda = widget.moneda > 1 && t >= inicioCaptura + _s(1.3);
    final etiqueta = enCaptura
        ? textoPor(conMoneda ? total : widget.pesca)
        : null;
    final dicho = enCaptura ? null : _dichoEn(enLago);
    return Opacity(
      opacity: entrada,
      child: LayoutBuilder(
        builder: (context, caja) {
          final tamano = _tamano = caja.biggest;
          final escena = _Escena(
            tamano,
            enLago,
            g,
            widget.pez,
            camara: _camara,
          );
          final boca = escena.aPantalla(escena.bocaSostenida);
          // Con el robot, la etiqueta va del otro lado de sus garras.
          final aLaIzquierda = escena.sostiene == Equipo.robot;
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _PintorLago(
                    escena: escena,
                    tiempo: t,
                    paisaje: _paisajePara(tamano),
                  ),
                ),
              ),
              // MacIAs en su recuadro de hielo, como en la transmision.
              Positioned(
                left: 12,
                bottom: 18,
                child: _Camara(expresion: _caraEn(enLago, enCaptura)),
              ),
              if (dicho != null)
                Positioned(
                  left: 70,
                  bottom: 98,
                  child: _Bocadillo(key: ValueKey(dicho), texto: dicho),
                ),
              if (!enCaptura)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 26,
                  child: Center(
                    child: _Medidor(
                      valor: g.valor(enLago),
                      tiembla: g.tironFinal(enLago),
                      tiempo: t,
                    ),
                  ),
                ),
              if (etiqueta != null)
                Positioned(
                  left: aLaIzquierda ? null : boca.dx + 26,
                  right: aLaIzquierda ? tamano.width - boca.dx + 26 : null,
                  top: boca.dy - 18,
                  child: _EtiquetaPescado(
                    key: ValueKey(etiqueta),
                    texto: etiqueta,
                    grande: conMoneda,
                  ),
                ),
              if (widget.moneda > 1 &&
                  enCaptura &&
                  t >= inicioCaptura + _s(.8) &&
                  !conMoneda)
                Positioned(
                  left: aLaIzquierda ? boca.dx - 110 : boca.dx + 32,
                  top: boca.dy - 70,
                  child: _MonedaQueLlega(
                    texto: 'x${widget.moneda}',
                    avance: ((t - inicioCaptura - _s(.8)) / _s(.5)).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ui.Picture _paisajePara(Size tamano) {
    final grabado = _paisaje;
    if (grabado != null && tamano == _tamanoPaisaje) return grabado;
    grabado?.dispose();
    _tamanoPaisaje = tamano;
    return _paisaje = _grabarPaisaje(tamano.width, tamano.height);
  }

  /// Lo que dice MacIAs desde su recuadro mientras pesca.
  String? _dichoEn(double t) {
    final g = _guion;
    for (final llegada in g.llegadas) {
      if (t >= llegada.cuando && t < llegada.cuando + llegada.dura + _s(.3)) {
        return switch (llegada.equipo) {
          Equipo.grua => '¡Pesa! Traigan la grúa.',
          Equipo.helicoptero => '¡No sale! ¡Un helicóptero!',
          Equipo.carga => '¡Más grande! ¡El de carga!',
          Equipo.robot => '¡¿Un robot?! ¡Sáquenlo!',
          Equipo.cana => null,
        };
      }
    }
    final chico = g.chicoAfuera;
    final trago = g.trago;
    if (chico != null && trago != null) {
      if (t >= chico && t < trago) return 'Uno chiquito… bueno.';
      if (t >= trago + g.duraTrago * .2 && t < trago + g.duraTrago + _s(.6)) {
        return '¡¿Qué?! ¡Se lo tragó!';
      }
    }
    return null;
  }

  ExpresionCrupier _caraEn(double t, bool enCaptura) {
    if (enCaptura) {
      final total = widget.pesca * widget.moneda;
      return total >= 20
          ? ExpresionCrupier.sorprendido
          : total >= 3
          ? ExpresionCrupier.risa
          : ExpresionCrupier.canchero;
    }
    final g = _guion;
    final trago = g.trago;
    if (trago != null && t >= trago && t < trago + g.duraTrago + _s(.6)) {
      return ExpresionCrupier.sorprendido;
    }
    for (final llegada in g.llegadas) {
      if (t >= llegada.cuando && t < llegada.cuando + llegada.dura + _s(.3)) {
        return ExpresionCrupier.sorprendido;
      }
    }
    final chico = g.chicoAfuera;
    if (chico != null && t >= chico && (trago == null || t < trago)) {
      return ExpresionCrupier.guino;
    }
    if (g.tironFinal(t)) return ExpresionCrupier.nervioso;
    return ExpresionCrupier.canchero;
  }

  // ================================================================= tarjeta
  Widget _tarjeta(double t) {
    final p = Curves.easeOutBack.transform(
      ((t - _inicio[EtapaBono.tarjeta]!) / _s(.45)).clamp(0.0, 1.0),
    );
    final total = widget.pesca * widget.moneda;
    final apostado = widget.apostado;
    final desde = t - _inicio[EtapaBono.tarjeta]!;
    // El premio se cuenta de cero para arriba.
    final cuenta = Curves.easeOutCubic.transform(
      ((desde - _s(.25)) / _s(1.2)).clamp(0.0, 1.0),
    );
    final linea = apostado == 0
        ? 'No le apostaste a los ${widget.pez.nombre}'
        : 'Ganaste ${conMiles((widget.premio * cuenta).round())}';
    final detalle = apostado == 0
        ? 'La próxima, una ficha en ${widget.pez.nombre}.'
        : 'Tu apuesta de ${conMiles(apostado)} vuelve, y ${textoPor(total)} '
              'encima.';
    return ColoredBox(
      color: Colors.black.withValues(alpha: .35 * p.clamp(0.0, 1.0)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (apostado > 0)
            IgnorePointer(
              child: CustomPaint(
                painter: _PintorFestejo(tiempo: desde, entrada: p),
              ),
            ),
          // Las monedas saltan desde atras de la tarjeta.
          if (apostado > 0)
            LluviaDeMonedas(
              origen: const Offset(.5, .44),
              cuantas: total >= 20 ? 40 : 18,
            ),
          Center(
            child: Transform.scale(
              scale: .6 + .4 * p,
              child: Opacity(
                opacity: p.clamp(0.0, 1.0),
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xF2FFFFFF), Color(0xE6CFE3EE)],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 24),
                      BoxShadow(color: Color(0x80BFE3F5), blurRadius: 30),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PezDibujado(pez: widget.pez, ancho: 150, boca: true),
                          Positioned(
                            right: -14,
                            top: -10,
                            child: _EtiquetaPescado(
                              texto: textoPor(total),
                              grande: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        linea,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ColoresPesca.texto,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detalle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4F6B7C),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detras de la tarjeta de un premio: rayos de luz dorada que giran
/// despacio y destellos que titilan alrededor.
class _PintorFestejo extends CustomPainter {
  const _PintorFestejo({required this.tiempo, required this.entrada});

  /// Segundos desde que aparecio la tarjeta.
  final double tiempo;

  /// Lo que entro la tarjeta (0 a 1).
  final double entrada;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero) + Offset(0, -size.height * .03);
    final largo = size.longestSide * .75;
    final fuerza = entrada.clamp(0.0, 1.0);
    final rayos = Path();
    for (var i = 0; i < 14; i++) {
      final a = tiempo * .25 + i * 2 * math.pi / 14;
      final b = a + .09;
      rayos
        ..moveTo(centro.dx, centro.dy)
        ..lineTo(
          centro.dx + math.cos(a) * largo,
          centro.dy + math.sin(a) * largo,
        )
        ..lineTo(
          centro.dx + math.cos(b) * largo,
          centro.dy + math.sin(b) * largo,
        )
        ..close();
    }
    canvas.drawPath(
      rayos,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ColoresPesca.oroClaro.withValues(alpha: .5 * fuerza),
            ColoresPesca.oro.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: largo)),
    );
    final azar = math.Random(31);
    for (var i = 0; i < 16; i++) {
      final angulo = azar.nextDouble() * 2 * math.pi;
      final lejos = size.shortestSide * (.42 + azar.nextDouble() * .3);
      final brilla = math.max(
        0,
        math.sin(tiempo * (3 + azar.nextDouble() * 3) + i),
      );
      pintarDestello(
        canvas,
        centro + Offset(math.cos(angulo), math.sin(angulo)) * lejos,
        (5 + azar.nextDouble() * 9) * brilla * fuerza,
        Colors.white.withValues(alpha: .95),
        angulo: tiempo,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorFestejo viejo) =>
      viejo.tiempo != tiempo || viejo.entrada != entrada;
}

/// "PESCA EN EL HIELO", tallado en el hielo, con un brillo que lo cruza.
class _TituloHielo extends StatelessWidget {
  const _TituloHielo({this.brillo = -1});

  /// Donde va el brillo, de -0,3 (antes de entrar) a 1,3 (ya paso).
  final double brillo;

  @override
  Widget build(BuildContext context) {
    final titulo = _titulo();
    if (brillo <= -.3 || brillo >= 1.3) return titulo;
    return Stack(
      alignment: Alignment.center,
      children: [
        titulo,
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (caja) => LinearGradient(
            begin: const Alignment(-1, -.5),
            end: const Alignment(1, .5),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .95),
              Colors.white.withValues(alpha: 0),
            ],
            stops: [
              (brillo - .12).clamp(0.0, 1.0),
              brillo.clamp(0.0, 1.0),
              (brillo + .12).clamp(0.0, 1.0),
            ],
          ).createShader(caja),
          child: _titulo(),
        ),
      ],
    );
  }

  Widget _titulo() {
    TextStyle estilo(double tamano) => TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w900,
      fontSize: tamano,
      height: .95,
      letterSpacing: 1.5,
      color: const Color(0xFF8FB4C9),
      shadows: const [
        Shadow(color: Colors.white, offset: Offset(0, 2)),
        Shadow(color: Color(0x665B8399), offset: Offset(0, -1.5)),
      ],
    );
    return Column(
      children: [
        Text('PESCA', style: estilo(56)),
        Text('EN EL HIELO', style: estilo(30)),
      ],
    );
  }
}

/// La casilla del pez que cayo, con su dibujo y su nombre.
class _CasillaPez extends StatelessWidget {
  const _CasillaPez({required this.pez});

  final Pez pez;

  @override
  Widget build(BuildContext context) {
    final (claro, oscuro) = ColoresPesca.deCasilla(pez.casilla);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [claro, oscuro],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: claro.withValues(alpha: .8), blurRadius: 18),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PezDibujado(pez: pez, ancho: 64),
          const SizedBox(height: 4),
          Text(
            pez.nombre.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// MacIAs en su recuadro de hielo.
class _Camara extends StatelessWidget {
  const _Camara({required this.expresion});

  final ExpresionCrupier expresion;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFBFD9E6)],
      ),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10)],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: const Color(0xFF9CC7E4),
        child: CrupierMacias(
          tamano: 70,
          expresion: expresion,
          hablando: false,
          latido: expresion.index,
        ),
      ),
    ),
  );
}

/// Lo que dice MacIAs desde su recuadro, en un globo.
class _Bocadillo extends StatelessWidget {
  const _Bocadillo({required this.texto, super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutBack,
    builder: (context, t, hijo) => Transform.scale(
      scale: .6 + .4 * t,
      alignment: Alignment.bottomLeft,
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: hijo),
    ),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(3),
        ),
        boxShadow: [BoxShadow(color: Color(0x44000000), blurRadius: 10)],
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: ColoresPesca.texto,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          height: 1.2,
        ),
      ),
    ),
  );
}

/// El medidor de oro: lo que va valiendo el pez mientras sale, con los
/// numeros que ruedan como en un contador. En el ultimo tiron, tiembla.
class _Medidor extends StatelessWidget {
  const _Medidor({
    required this.valor,
    required this.tiembla,
    required this.tiempo,
  });

  final double valor;
  final bool tiembla;
  final double tiempo;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 1.35, end: 1),
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutBack,
    builder: (context, escala, hijo) => Transform.translate(
      offset: Offset(tiembla ? math.sin(tiempo * 70) * 3 : 0, 0),
      child: Transform.scale(scale: escala, child: hijo),
    ),
    child: Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xCC0F2533),
        border: Border.all(color: ColoresPesca.oro, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x99F5C542), blurRadius: 16)],
      ),
      child: CustomPaint(
        size: Size(textoMedidor(valor).length * 18.0 + 4, 32),
        painter: _PintorContador(valor),
      ),
    ),
  );
}

/// Los numeros del medidor: cada columna rueda hacia el siguiente, como en
/// un contador de verdad.
class _PintorContador extends CustomPainter {
  const _PintorContador(this.valor);

  final double valor;

  static final _estilo = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w900,
    fontSize: 30,
    height: 1,
    color: ColoresPesca.oroClaro,
    shadows: [
      Shadow(
        color: const Color(0xFFB8860B).withValues(alpha: .7),
        blurRadius: 8,
      ),
    ],
  );

  TextPainter _letra(String texto) => TextPainter(
    text: TextSpan(text: texto, style: _estilo),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    // Cada columna: lo que muestra, lo que viene y cuanto rodo (0 a 1).
    final columnas = <(String, String?, double)>[('x', null, 0)];
    if (valor >= 1) {
      final entero = valor.floor();
      final resto = valor - entero;
      final digitos = '$entero';
      for (var i = 0; i < digitos.length; i++) {
        final posicion = digitos.length - 1 - i;
        final abajo = math.pow(10, posicion).toInt();
        // Rueda la ultima, y las de la izquierda solo cuando las de la
        // derecha estan en 9.
        final rueda = posicion == 0 || entero % abajo == abajo - 1
            ? resto
            : 0.0;
        final d = int.parse(digitos[i]);
        columnas.add((digitos[i], '${(d + 1) % 10}', rueda));
      }
    } else {
      final decimas = valor * 10;
      final d = decimas.floor().clamp(0, 9);
      columnas
        ..add(('0', null, 0))
        ..add((',', null, 0))
        ..add(('$d', d < 9 ? '${d + 1}' : null, d < 9 ? decimas - d : 0));
    }
    var x = 2.0;
    for (final (actual, siguiente, rueda) in columnas) {
      final letra = _letra(actual);
      final ancho = actual == ',' || actual == 'x' ? letra.width : 18.0;
      final y = (size.height - letra.height) / 2;
      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(x, 0, ancho, size.height));
      final corrido = Curves.easeInOut.transform(rueda) * size.height;
      letra.paint(canvas, Offset(x + (ancho - letra.width) / 2, y - corrido));
      if (siguiente != null && rueda > 0) {
        final otra = _letra(siguiente);
        otra.paint(
          canvas,
          Offset(x + (ancho - otra.width) / 2, y - corrido + size.height),
        );
      }
      canvas.restore();
      x += ancho;
    }
  }

  @override
  bool shouldRepaint(_PintorContador viejo) => viejo.valor != valor;
}

/// Lo que vale el pescado, al lado del pez.
class _EtiquetaPescado extends StatelessWidget {
  const _EtiquetaPescado({required this.texto, this.grande = false, super.key});

  final String texto;
  final bool grande;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 520),
    curve: Curves.elasticOut,
    builder: (context, t, hijo) => Transform.scale(scale: t, child: hijo),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: grande ? 14 : 11,
        vertical: grande ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColoresPesca.oroClaro,
            ColoresPesca.oro,
            ColoresPesca.oroOscuro,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: const [
          BoxShadow(color: Color(0xAAF5C542), blurRadius: 18),
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: ColoresPesca.texto,
          fontWeight: FontWeight.w900,
          fontSize: grande ? 26 : 20,
          height: 1,
        ),
      ),
    ),
  );
}

/// La moneda de oro que vuela hasta el pez y lo multiplica.
class _MonedaQueLlega extends StatelessWidget {
  const _MonedaQueLlega({required this.texto, required this.avance});

  final String texto;
  final double avance;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOutCubic.transform(avance);
    return Transform.translate(
      offset: Offset(0, -60 * (1 - t)),
      child: Transform.scale(
        scale: .6 + .5 * math.sin(t * math.pi) + .4 * t,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-.3, -.4),
              colors: [
                ColoresPesca.oroClaro,
                ColoresPesca.oro,
                ColoresPesca.oroOscuro,
              ],
            ),
            boxShadow: [BoxShadow(color: Color(0xCCF5C542), blurRadius: 18)],
          ),
          child: Text(
            texto,
            style: const TextStyle(
              color: Color(0xFF6B4A05),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// La escarcha que tapa todo: hielo esmerilado y cristales que crecen
/// desde los bordes hacia el centro, con algun destello.
class _PintorEscarcha extends CustomPainter {
  const _PintorEscarcha({this.avance = 1});

  /// Cuanto crecieron los cristales (0 a 1).
  final double avance;

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F3F8), Color(0xFFC9DEEA), Color(0xFFDDEBF3)],
        ).createShader(todo),
    );
    // Vetas finas del hielo, apenas.
    final azar = math.Random(5);
    final w = size.width;
    final h = size.height;
    final veta = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..strokeWidth = .7;
    for (var i = 0; i < 140; i++) {
      final desde = Offset(azar.nextDouble() * w, azar.nextDouble() * h);
      final angulo = azar.nextDouble() * math.pi;
      final largo = 10 + azar.nextDouble() * 40;
      canvas.drawLine(
        desde,
        desde + Offset(math.cos(angulo), math.sin(angulo)) * largo,
        veta,
      );
    }
    // Los cristales: ramas que nacen en los bordes y se abren hacia
    // adentro, como la escarcha en un vidrio.
    final crece = Curves.easeOutCubic.transform((avance / .7).clamp(0.0, 1.0));
    final rama = Paint()..strokeCap = StrokeCap.round;
    void crecer(Offset desde, double angulo, double largo, int nivel) {
      if (nivel > 3 || largo < 3) return;
      final hasta = desde + Offset(math.cos(angulo), math.sin(angulo)) * largo;
      rama
        ..strokeWidth = math.max(.6, 2.6 - nivel * .6)
        ..color = Colors.white.withValues(alpha: .75 - nivel * .14);
      canvas.drawLine(desde, hasta, rama);
      for (final f in [.38, .7]) {
        final punto = Offset.lerp(desde, hasta, f)!;
        crecer(punto, angulo + .8, largo * .46, nivel + 1);
        crecer(punto, angulo - .8, largo * .46, nivel + 1);
      }
    }

    if (crece > 0) {
      for (var i = 0; i < 14; i++) {
        final lado = i % 4;
        final u = azar.nextDouble();
        final (desde, hacia) = switch (lado) {
          0 => (Offset(u * w, 0), math.pi / 2),
          1 => (Offset(w, u * h), math.pi),
          2 => (Offset(u * w, h), -math.pi / 2),
          _ => (Offset(0, u * h), 0.0),
        };
        crecer(
          desde,
          hacia + (azar.nextDouble() - .5) * .9,
          math.min(w, h) * (.18 + azar.nextDouble() * .14) * crece,
          0,
        );
      }
    }
    // Los destellos del hielo.
    for (var i = 0; i < 9; i++) {
      final donde = Offset(azar.nextDouble() * w, azar.nextDouble() * h);
      final brilla = math.max(0.0, math.sin(avance * 12 + i * 2.1));
      pintarDestello(
        canvas,
        donde,
        8 * brilla,
        Colors.white.withValues(alpha: .9 * brilla),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorEscarcha viejo) => viejo.avance != avance;
}

/// El hoyo en el hielo de la escarcha, donde baja la casilla.
class _PintorHoyoChico extends CustomPainter {
  const _PintorHoyoChico();

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Offset.zero & size;
    canvas
      ..drawOval(
        oval.inflate(6),
        Paint()..color = Colors.white.withValues(alpha: .9),
      )
      ..drawOval(
        oval,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFF07263B), Color(0xFF1B5C80)],
          ).createShader(oval),
      );
  }

  @override
  bool shouldRepaint(_PintorHoyoChico viejo) => false;
}

/// Un pez del cardumen.
class _Nadador {
  _Nadador(math.Random azar, this.valor)
    : profundidad = azar.nextDouble(),
      y = .14 + azar.nextDouble() * .78,
      fase = azar.nextDouble() * math.pi * 2,
      corrido = azar.nextDouble(),
      haciaLaDerecha = azar.nextDouble() < .75;

  final double valor;

  /// 0 lejos (chico y borroso), 1 cerca.
  final double profundidad;
  final double y;
  final double fase;
  final double corrido;
  final bool haciaLaDerecha;

  /// Lo que vale, escrito: se arma una sola vez (siempre del mismo tamaño
  /// y color), no en cada cuadro.
  TextPainter? _etiqueta;
  TextPainter etiqueta(double ancho, double opacidad) =>
      _etiqueta ??= TextPainter(
        text: TextSpan(
          text: textoPor(valor),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: ancho * .24,
            height: 1,
            color: Colors.white.withValues(alpha: opacidad),
            shadows: [
              Shadow(
                color: const Color(0xFF06223A).withValues(alpha: .8 * opacidad),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
}

/// Bajo el hielo: el cardumen del pez que cayo, cada uno con lo que puede
/// valer. Los grandes nadan lejos.
class _Cardumen extends StatefulWidget {
  const _Cardumen({
    required this.pez,
    required this.tiempo,
    required this.entrada,
    super.key,
  });

  final Pez pez;
  final double tiempo;
  final double entrada;

  @override
  State<_Cardumen> createState() => _CardumenState();
}

class _CardumenState extends State<_Cardumen> {
  late final List<_Nadador> _peces = () {
    final azar = math.Random();
    final total = widget.pez.tabla.fold<int>(0, (s, f) => s + f.$2);
    double sortear() {
      var tiro = azar.nextInt(total);
      for (final (v, peso) in widget.pez.tabla) {
        if (tiro < peso) return v;
        tiro -= peso;
      }
      return widget.pez.tabla.last.$1;
    }

    final peces = [
      for (var i = 0; i < 26; i++) _Nadador(azar, sortear()),
      // El mas grande siempre anda por ahi.
      _Nadador(azar, widget.pez.maximo),
    ]..sort((a, b) => a.profundidad.compareTo(b.profundidad));
    return peces;
  }();

  @override
  void dispose() {
    for (final pescado in _peces) {
      pescado._etiqueta?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: Curves.easeOut.transform((widget.entrada / .12).clamp(0.0, 1.0)),
    child: CustomPaint(
      painter: _PintorCardumen(
        pez: widget.pez,
        peces: _peces,
        tiempo: widget.tiempo,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _PintorCardumen extends CustomPainter {
  _PintorCardumen({
    required this.pez,
    required this.peces,
    required this.tiempo,
  });

  final Pez pez;
  final List<_Nadador> peces;
  final double tiempo;

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7EC3E6), Color(0xFF2675A8), Color(0xFF0A2C49)],
          stops: [0, .45, 1],
        ).createShader(todo),
    );
    // La luz que entra por el hielo, en rayos que se mecen.
    for (var i = 0; i < 6; i++) {
      final x = w * (.05 + i * .18) + math.sin(tiempo * .6 + i) * 18;
      final rayo = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w * .07, 0)
        ..lineTo(x + w * .24, h)
        ..lineTo(x + w * .1, h)
        ..close();
      canvas.drawPath(
        rayo,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .2),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x, 0, w * .24, h)),
      );
    }
    // El techo de hielo, visto desde abajo.
    final techo = Path()..moveTo(0, 0);
    for (var x = 0.0; x <= w; x += w / 12) {
      techo.lineTo(x, h * .05 + math.sin(x * .05) * h * .015);
    }
    techo
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(
      techo,
      Paint()..color = const Color(0xFFDDEFF8).withValues(alpha: .85),
    );

    // La luz que baila en el agua: una red de ondas claras que se mueve.
    final onda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: .07);
    for (var j = 0; j < 7; j++) {
      final red = Path();
      for (var x = -10.0; x <= w + 10; x += 12) {
        final y =
            h * (.1 + j * .075) +
            math.sin(x * .035 + tiempo * 1.4 + j * 1.7) * 9 +
            math.sin(x * .09 - tiempo * 2.1 + j) * 4;
        if (x < 0) {
          red.moveTo(x, y);
        } else {
          red.lineTo(x, y);
        }
      }
      canvas.drawPath(red, onda);
    }
    // Las algas del fondo, que se mecen.
    for (var i = 0; i < 9; i++) {
      final x = w * (.04 + i * .12) + (i * 17 % 9);
      final alto = h * (.14 + (i * 37 % 10) / 10 * .16);
      final mece = math.sin(tiempo * 1.3 + i * 1.1) * w * .04;
      final alga = Path()
        ..moveTo(x - 5, h)
        ..quadraticBezierTo(
          x + mece * .3 - 6,
          h - alto * .5,
          x + mece,
          h - alto,
        )
        ..quadraticBezierTo(x + mece * .3 + 6, h - alto * .5, x + 5, h)
        ..close();
      canvas.drawPath(
        alga,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF0E4D47),
            const Color(0xFF1C6E5E),
            (i % 3) / 2,
          )!.withValues(alpha: .85),
      );
    }
    // Lo que flota en el agua.
    final mota = Paint()..color = Colors.white.withValues(alpha: .22);
    for (var i = 0; i < 30; i++) {
      final x = (i * 71 % w + tiempo * (6 + i % 5)) % w;
      final y = (i * 113 % h - tiempo * (4 + i % 3) * 2) % h;
      canvas.drawCircle(Offset(x, y), .8 + (i % 3) * .5, mota);
    }

    // Burbujas que suben.
    final burbuja = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .5);
    for (var i = 0; i < 24; i++) {
      final velocidad = 40 + (i * 37 % 50);
      final y = h - ((tiempo * velocidad + i * 97) % (h * 1.1));
      final x = (i * 53 % w) + math.sin(tiempo * 2 + i) * 8;
      canvas.drawCircle(Offset(x, y), 2 + (i % 4), burbuja);
    }

    // Los peces, del mas lejano al mas cercano.
    for (final pescado in peces) {
      final z = pescado.profundidad;
      final ancho =
          ui.lerpDouble(46, 120, z)! * (pez == Pez.rojazos ? 1.15 : 1);
      final velocidad = ui.lerpDouble(26, 80, z)!;
      final recorrido = w + ancho * 2;
      final avance =
          (pescado.corrido * recorrido + tiempo * velocidad) % recorrido;
      final x = pescado.haciaLaDerecha ? -ancho + avance : w + ancho - avance;
      final y =
          h * pescado.y +
          math.sin(tiempo * 2.2 + pescado.fase) * 6 -
          ancho * .28;
      final caja = Rect.fromLTWH(x - ancho / 2, y, ancho, ancho * .56);
      final opacidad = ui.lerpDouble(.32, 1, z)!;
      canvas.save();
      if (!pescado.haciaLaDerecha) {
        canvas
          ..translate(caja.center.dx, 0)
          ..scale(-1, 1)
          ..translate(-caja.center.dx, 0);
      }
      pintarPez(
        canvas,
        caja,
        pez,
        opacidad: opacidad,
        cola: math.sin(tiempo * (7 + z * 4) + pescado.fase) * .3,
        conDetalle: z > .5,
      );
      canvas.restore();
      // Lo que vale, sobre el lomo.
      final letra = pescado.etiqueta(ancho, opacidad);
      letra.paint(
        canvas,
        caja.center - Offset(letra.width / 2 - ancho * .06, letra.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorCardumen viejo) => viejo.tiempo != tiempo;
}

Offset _rotar(Offset p, double angulo) => Offset(
  p.dx * math.cos(angulo) - p.dy * math.sin(angulo),
  p.dx * math.sin(angulo) + p.dy * math.cos(angulo),
);

/// Donde esta cada cosa del lago en el segundo [t] de la pesca, en las
/// medidas del lago sin alejar la camara. La usan el pintor y lo que va
/// encima (la etiqueta del pez), asi coinciden.
class _Escena {
  _Escena(this.size, this.t, this.guion, this.pez, {this.camara = 1})
    : hoyo = Offset(size.width * .6, size.height * .8),
      pivote = Offset(size.width * .6, size.height * .86) {
    final h = size.height;
    final chico = guion.engano;
    largoChico = chico == null ? 0 : GuionPesca.largo(chico) * h;
    grosorChico = chico == null ? 0 : GuionPesca.grosor(chico);
    largoGrande = GuionPesca.largo(guion.pesca) * h;
    grosorGrande = GuionPesca.grosor(guion.pesca);
    sostiene = guion.sostiene(t);
    bocaSostenida = _bocaSostenidaEn(t);
  }

  final Size size;
  final double t;
  final GuionPesca guion;
  final Pez pez;

  /// 1 de cerca; menos, alejada.
  final double camara;
  final Offset hoyo;

  /// Desde donde se aleja la camara: el hielo, debajo del hoyo.
  final Offset pivote;
  late final double largoChico;
  late final double grosorChico;
  late final double largoGrande;
  late final double grosorGrande;

  /// Quien tiene el hilo.
  late final Equipo sostiene;

  /// La boca que tiene el hilo (o la garra del robot).
  late final Offset bocaSostenida;

  double get _w => size.width;
  double get _h => size.height;
  double get _r => guion.ritmo;

  /// Del lago a la pantalla, con la camara.
  Offset aPantalla(Offset punto) => pivote + (punto - pivote) * camara;

  double get anchoChico => largoChico * grosorChico;
  double get anchoGrande => largoGrande * grosorGrande;

  /// Lo que va del trago (0 a 1, y sigue despues); null si no hay engaño o
  /// todavia no salio el gigante.
  double? _trago(double tt) {
    final trago = guion.trago;
    if (trago == null || tt < trago) return null;
    return (tt - trago) / guion.duraTrago;
  }

  /// El chico se ve hasta que el gigante cierra la boca.
  bool get chicoVisible {
    if (guion.engano == null) return false;
    final d = _trago(t);
    return d == null || d < .47;
  }

  Offset _bocaChicoEn(double tt) {
    final afuera = guion.chicoAfuera!;
    if (tt < afuera) {
      return Offset(hoyo.dx, hoyo.dy - guion.salida(0, tt) * largoChico);
    }
    final colgado = Curves.easeOutCubic.transform(
      ((tt - afuera) / (.5 * _r)).clamp(0.0, 1.0),
    );
    return Offset(hoyo.dx, hoyo.dy - largoChico - _h * .035 * colgado);
  }

  Offset get bocaChico => _bocaChicoEn(t);

  /// Cuanto del pez grande salio del agua (0 a 1). Despues del trago, al
  /// gigante le asoma la punta antes de que empiece a subir.
  double _salidaGrandeEn(double tt) {
    final d = _trago(tt);
    if (guion.engano == null) return guion.salida(1, tt);
    if (d == null || d < .79) return 0;
    return .07 * ((d - .79) / .21).clamp(0.0, 1.0) + .93 * guion.salida(1, tt);
  }

  double get salidaGrande => _salidaGrandeEn(t);

  Offset _bocaGrandeEn(double tt) {
    final despues = tt - guion.afuera;
    if (despues < 0) {
      return Offset(hoyo.dx, hoyo.dy - _salidaGrandeEn(tt) * largoGrande);
    }
    final sube = Curves.easeOutCubic.transform(
      (despues / (.7 * _r)).clamp(0.0, 1.0),
    );
    return Offset(hoyo.dx, hoyo.dy - largoGrande - _h * .05 * sube);
  }

  Offset get bocaGrande => _bocaGrandeEn(t);

  /// Lo alto que sale la bocaza del gigante mientras se traga al chico.
  double _altoBocazaEn(double tt) {
    final d = _trago(tt);
    if (d == null || d < .1 || d >= .8) return 0;
    final pico = largoChico + _h * .13;
    if (d < .32) return pico * Curves.easeOutBack.transform((d - .1) / .22);
    if (d < .53) return pico;
    return pico * (1 - Curves.easeInCubic.transform((d - .53) / .27));
  }

  double get altoBocaza => _altoBocazaEn(t);

  /// Lo abierta que esta la bocaza (0 cerrada, 1 abierta del todo).
  double get abreBocaza {
    final d = _trago(t);
    if (d == null || d < .1) return 0;
    if (d < .29) return (d - .1) / .19;
    if (d < .42) return 1;
    return 1 - ((d - .42) / .08).clamp(0.0, 1.0);
  }

  Offset _bocaSostenidaEn(double tt) {
    final d = _trago(tt);
    if (guion.engano != null && (d == null || d < .47)) {
      return _bocaChicoEn(tt);
    }
    if (d != null && d < .8) {
      return Offset(hoyo.dx, hoyo.dy - _altoBocazaEn(tt));
    }
    return _bocaGrandeEn(tt);
  }

  /// El hoyo se agranda (se rompe el hielo) para que pase el pez.
  double get anchoHoyo {
    var ancho = 0.0;
    if (chicoVisible) {
      ancho = anchoChico * math.min(1, guion.salida(0, t) / .25);
    }
    final d = _trago(t);
    if (d != null && d >= .1) ancho = math.max(ancho, anchoGrande * 1.15);
    ancho = math.max(ancho, anchoGrande * math.min(1, salidaGrande / .25));
    return math.max(_w * .3, ancho * 1.3);
  }

  /// El pez que sale patalea mientras lo sacan.
  double get meneo =>
      guion.subiendo(t) && t < guion.afuera ? math.sin(t * 9) * .025 : 0;

  /// Afuera, colgado, se balancea (salvo que lo tenga el robot).
  double get balanceo {
    final despues = t - guion.afuera;
    if (despues < 0 || sostiene == Equipo.robot) return 0;
    return math.sin(despues * 2.6) * .07 * math.exp(-despues * .3);
  }

  double get meneoChico {
    final afuera = guion.chicoAfuera;
    if (afuera == null) return 0;
    if (t < afuera) return guion.subiendo(t) ? math.sin(t * 9) * .03 : 0;
    // Mientras sube la bocaza, patalea.
    if (_trago(t) != null) return math.sin(t * 22) * .12;
    return math.sin((t - afuera) * 2.8) * .08;
  }

  /// La camara tiembla con los golpes: cuando el gigante rompe el hielo,
  /// cuando sale el robot y cuando el pez termina de salir.
  Offset get sacudon {
    var sacudon = Offset.zero;
    void golpe(double? cuando, double fuerza) {
      if (cuando == null) return;
      final d = (t - cuando) / _r;
      if (d < 0 || d > .6) return;
      final queda = 1 - d / .6;
      sacudon +=
          Offset(math.sin(d * 70), math.cos(d * 53)) * _h * fuerza * queda;
    }

    final trago = guion.trago;
    golpe(trago == null ? null : trago + guion.duraTrago * .1, .012);
    golpe(guion.llegadaDe(Equipo.robot)?.cuando, .016);
    golpe(guion.afuera, guion.pesca >= 25 ? .008 : .003);
    return sacudon;
  }

  // ------------------------------------------------------------- la caña
  Offset get mango => Offset(_w * .13, _h * .835);
  Offset get horqueta => mango + Offset(_w * .1, -_h * .065);

  /// Cuanto se dobla la caña: mientras tiene el pez y el medidor sube.
  double get tensionCana {
    if (sostiene != Equipo.cana) return 0;
    if (!guion.subiendo(t)) return .25;
    return .4 + .6 * math.min(1, guion.valor(t) / 10);
  }

  Offset get puntaCana {
    final tension = tensionCana;
    final sacudon = tension > 0 && guion.tironFinal(t)
        ? math.sin(t * 38) * _h * .006
        : 0.0;
    return Offset(
      _w * .53 + _w * .025 * tension,
      _h * .36 + _h * .07 * tension + sacudon,
    );
  }

  /// La manivela del carrete gira mientras recoge.
  double get vueltaCarrete {
    if (sostiene != Equipo.cana || !guion.subiendo(t)) return 0;
    return t * (guion.tironFinal(t) ? 14 : 7);
  }

  // ------------------------------------------------------------- la grua
  /// La grua: llega por la izquierda, para detras de la caña y levanta el
  /// brazo hasta arriba del pez.
  ({Offset camion, Offset base, Offset punta, double ruedas, double llega})?
  get grua {
    final llegada = guion.llegadaDe(Equipo.grua);
    if (llegada == null || t < llegada.cuando) return null;
    final a = ((t - llegada.cuando) / llegada.dura).clamp(0.0, 1.0);
    final llega = Curves.easeOutCubic.transform((a / .55).clamp(0.0, 1.0));
    final x = ui.lerpDouble(-_w * .9, _w * .32, llega)!;
    final camion = Offset(x, _h * .785);
    final base = camion + Offset(-_w * .1, -_h * .075);
    final soltado = guion.soltado(Equipo.grua);
    final boca = _bocaSostenidaEn(soltado == null ? t : math.min(t, soltado));
    final arriba = Offset(
      hoyo.dx + _w * .02,
      math.min(boca.dy - _h * .17, _h * .42),
    );
    final levanta = Curves.easeInOutCubic.transform(
      ((a - .45) / .4).clamp(0.0, 1.0),
    );
    final acostado = base + Offset(_w * .42, -_h * .04);
    return (
      camion: camion,
      base: base,
      punta: Offset.lerp(acostado, arriba, levanta)!,
      ruedas: x / (_h * .018),
      llega: a,
    );
  }

  // ------------------------------------------------------ los helicopteros
  double get largoHelicoptero => _w * .26;
  double get largoCarga => _w * .46;

  /// Donde se queda el helicoptero: arriba de la boca que tiene el hilo.
  Offset _arribaDe(Equipo equipo) {
    final soltado = guion.soltado(equipo);
    final boca = _bocaSostenidaEn(soltado == null ? t : math.min(t, soltado));
    return equipo == Equipo.carga
        ? boca + Offset(-_w * .03, -_h * .33)
        : boca + Offset(_w * .05, -_h * .27);
  }

  /// Un helicoptero: llega volando, se queda arriba del pez con el cable y,
  /// cuando lo agarra el siguiente equipo, se va.
  ({Offset centro, double inclinacion, double llega})? helicoptero(
    Equipo equipo,
  ) {
    final llegada = guion.llegadaDe(equipo);
    if (llegada == null || t < llegada.cuando) return null;
    final a = ((t - llegada.cuando) / llegada.dura).clamp(0.0, 1.0);
    final carga = equipo == Equipo.carga;
    final desde = carga
        ? Offset(-_w * .8, -_h * .15)
        : Offset(_w * 1.5, -_h * .1);
    final entra = Curves.easeOutCubic.transform((a / .65).clamp(0.0, 1.0));
    final vaiven = Offset(
      math.sin(t * 1.6) * _w * .012,
      math.sin(t * 2.3) * _h * .006,
    );
    var centro = Offset.lerp(desde, _arribaDe(equipo), entra)! + vaiven * entra;
    var inclinacion = (1 - entra) * (carga ? .2 : -.25);
    final soltado = guion.soltado(equipo);
    if (soltado != null && t > soltado + .2 * _r) {
      final se = ((t - soltado - .2 * _r) / (1.6 * _r)).clamp(0.0, 1.0);
      if (se >= 1) return null;
      final destino = carga
          ? Offset(-_w * 1.2, -_h * .7)
          : Offset(_w * 1.8, -_h * .6);
      centro = Offset.lerp(centro, destino, Curves.easeInCubic.transform(se))!;
      inclinacion = carga ? -.25 * se : .3 * se;
    }
    return (centro: centro, inclinacion: inclinacion, llega: a);
  }

  /// De donde cuelga el cable del helicoptero.
  Offset gancho(Offset centro, double inclinacion, {required bool carga}) {
    final bajo = carga
        ? Offset(0, largoCarga * .1)
        : Offset(-largoHelicoptero * .14, largoHelicoptero * .16);
    return centro + _rotar(bajo, inclinacion);
  }

  // ------------------------------------------------------------- el robot
  /// El robot: sale del hielo detras del pez y lo agarra con las dos garras.
  ({Offset pies, double alto, double sube, Offset garra, Offset garraAtras})?
  get robot {
    final llegada = guion.llegadaDe(Equipo.robot);
    if (llegada == null || t < llegada.cuando) return null;
    final a = ((t - llegada.cuando) / llegada.dura).clamp(0.0, 1.0);
    final alto = math.max(_h * .6, largoGrande * 1.02);
    final pies = Offset(hoyo.dx + alto * .16, hoyo.dy - _h * .005);
    final sube = Curves.easeOutCubic.transform((a / .5).clamp(0.0, 1.0));
    final agarra = Curves.easeInOutCubic.transform(
      ((a - .5) / .35).clamp(0.0, 1.0),
    );
    final ancho = alto * .48;
    final hombros = pies.dy - alto * .74;
    final boca = _bocaSostenidaEn(t);
    final reposo = Offset(pies.dx - ancho * .62, hombros + alto * .3);
    final reposoAtras = Offset(pies.dx + ancho * .64, hombros + alto * .3);
    final lomo = boca + Offset(-anchoGrande * .42, largoGrande * .16);
    final panza = boca + Offset(anchoGrande * .42, largoGrande * .32);
    return (
      pies: pies,
      alto: alto,
      sube: sube,
      garra: Offset.lerp(reposo, lomo, agarra)!,
      garraAtras: Offset.lerp(reposoAtras, panza, agarra)!,
    );
  }

  /// Lo que se aleja la camara para que entre todo: el pez, el equipo y el
  /// cielo de arriba (alli va el boton de saltar).
  double get camaraIdeal {
    var arriba = math.min(_h * .3, bocaSostenida.dy - _h * .05);
    var derecha = hoyo.dx + anchoHoyo / 2;
    final grua = this.grua;
    if (grua != null) arriba = math.min(arriba, grua.punta.dy - _h * .04);
    for (final equipo in [Equipo.helicoptero, Equipo.carga]) {
      final llegada = guion.llegadaDe(equipo);
      final soltado = guion.soltado(equipo);
      if (llegada == null || t < llegada.cuando) continue;
      if (soltado != null && t > soltado + .2 * _r) continue;
      final sobre = _arribaDe(equipo);
      final largo = equipo == Equipo.carga ? largoCarga : largoHelicoptero;
      arriba = math.min(arriba, sobre.dy - largo * .35);
      derecha = math.max(derecha, sobre.dx + largo * .6);
    }
    final robot = this.robot;
    if (robot != null) {
      arriba = math.min(arriba, robot.pies.dy - robot.alto * 1.02);
      derecha = math.max(derecha, robot.pies.dx + robot.alto * .3);
    }
    final alto = (pivote.dy - _h * .15) / (pivote.dy - arriba);
    final ancho = (_w * .97 - pivote.dx) / math.max(1, derecha - pivote.dx);
    return math.min(alto, ancho).clamp(.3, 1.0);
  }
}

/// El lago congelado: el cielo, las montañas, la cabaña con su bandera, la
/// caña de MacIAs, el hoyo y lo que sale de el, con el equipo que haga
/// falta. La camara se aleja si no entra.
class _PintorLago extends CustomPainter {
  _PintorLago({
    required this.escena,
    required this.tiempo,
    required this.paisaje,
  });

  final _Escena escena;

  /// El paisaje que no se mueve, ya dibujado.
  final ui.Picture paisaje;

  /// Los segundos del bono (la bandera, la nieve).
  final double tiempo;

  @override
  void paint(Canvas canvas, Size size) {
    final e = escena;
    final w = size.width;
    final h = size.height;
    final t = e.t;
    final r = e.guion.ritmo;
    final todo = Offset.zero & size;

    // El cielo de invierno: no se aleja, es el fondo. Azul arriba, claro y
    // un poco dorado sobre el horizonte, con el sol bajo y nubes que pasan.
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A8CC0),
            Color(0xFF94C4E6),
            Color(0xFFE1EFF8),
            Color(0xFFF9EED8),
          ],
          stops: [0, .36, .6, .78],
        ).createShader(todo),
    );
    final sol = Offset(w * .18, h * .38);
    canvas
      ..drawCircle(
        sol,
        w * .6,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFE2A8).withValues(alpha: .55),
              const Color(0xFFFFE2A8).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sol, radius: w * .6)),
      )
      ..drawCircle(sol, w * .045, Paint()..color = const Color(0xFFFFF6DE));
    for (final (y, escala, velocidad, fase) in [
      (h * .1, 1.0, 7.0, 0.0),
      (h * .19, .7, 10.0, .45),
      (h * .05, .55, 4.5, .8),
    ]) {
      final x = ((tiempo * velocidad / w + fase) % 1.5 - .25) * w;
      _nube(canvas, Offset(x, y), w * .2 * escala);
    }

    final sacudon = e.sacudon;
    canvas
      ..save()
      ..translate(sacudon.dx, sacudon.dy)
      ..translate(e.pivote.dx, e.pivote.dy)
      ..scale(e.camara)
      ..translate(-e.pivote.dx, -e.pivote.dy);
    canvas.drawPicture(paisaje);
    _paisajeVivo(canvas, w, h);

    // Lo que asoma del hielo se corta en el hielo.
    final sobreElHielo = Rect.fromLTRB(-w * 4, -h * 6, w * 6, e.hoyo.dy);

    // El robot, detras del pez: sube rompiendo el hielo.
    final robot = e.robot;
    Offset? hundido;
    if (robot != null) {
      hundido = Offset(0, (1 - robot.sube) * robot.alto);
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(-w * 4, -h * 6, w * 6, robot.pies.dy + 2));
      _pintarRobot(canvas, robot.pies + hundido, robot.alto, tiempo);
      canvas.restore();
    }

    final grua = e.grua;
    if (grua != null) {
      _pintarGrua(
        canvas,
        grua.camion,
        grua.base,
        grua.punta,
        grua.ruedas,
        w,
        h,
      );
    }
    _pintarCana(
      canvas,
      e.mango,
      e.horqueta,
      e.puntaCana,
      e.tensionCana,
      e.vueltaCarrete,
      w,
      h,
    );

    final anchoHoyo = e.anchoHoyo;
    // La sombra de lo que sale del agua, sobre el hielo (el sol esta a la
    // izquierda).
    final afuera = math.max(
      e.chicoVisible ? e.hoyo.dy - e.bocaChico.dy : 0.0,
      e.salidaGrande > 0 ? e.hoyo.dy - e.bocaGrande.dy : 0.0,
    );
    if (afuera > 0) {
      final sombra = Rect.fromCenter(
        center: e.hoyo + Offset(anchoHoyo * .35 + afuera * .3, anchoHoyo * .1),
        width: anchoHoyo * .4 + afuera * .7,
        height: anchoHoyo * .1 + afuera * .05,
      );
      canvas.drawOval(
        sombra,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF3A6A86).withValues(alpha: .28),
              const Color(0xFF3A6A86).withValues(alpha: 0),
            ],
          ).createShader(sombra),
      );
    }
    // El viento de las aspas del helicoptero levanta la nieve del hielo.
    if (e.sostiene == Equipo.helicoptero || e.sostiene == Equipo.carga) {
      _pintarVentarron(canvas, e.hoyo, anchoHoyo, tiempo);
    }
    _pintarTrozos(canvas, e.hoyo, anchoHoyo, adelante: false);
    _pintarHoyo(
      canvas,
      e.hoyo,
      anchoHoyo,
      tiempo,
      agitado: e.guion.subiendo(t) ? 1 : 0,
    );
    canvas
      ..save()
      ..clipRect(sobreElHielo);
    if (e.chicoVisible) {
      _pintarPezParado(
        canvas,
        e.bocaChico,
        e.largoChico,
        e.grosorChico,
        e.pez,
        giro: e.meneoChico,
        cola: math.sin(tiempo * 15) * .3,
      );
    }
    final bocaza = e.altoBocaza;
    if (bocaza > 0) {
      _pintarBocaza(
        canvas,
        e.hoyo,
        e.anchoGrande * 1.15,
        bocaza,
        e.abreBocaza,
        e.pez,
      );
    }
    if (e.salidaGrande > 0) {
      // Mientras lo sacan patalea fuerte; colgado, mueve la cola despacio.
      final pelea = e.guion.subiendo(t) && t < e.guion.afuera;
      _pintarPezParado(
        canvas,
        e.bocaGrande,
        e.largoGrande,
        e.grosorGrande,
        e.pez,
        giro: e.balanceo + e.meneo,
        cola: pelea
            ? math.sin(tiempo * 16) * .32
            : math.sin(tiempo * 4) * (e.sostiene == Equipo.robot ? .08 : .16),
      );
      // El agua que le chorrea al pez y cae al hoyo.
      _pintarChorreo(
        canvas,
        e.bocaGrande,
        e.hoyo.dy,
        e.hoyo.dy - e.bocaGrande.dy,
        e.anchoGrande,
        tiempo,
      );
    }
    canvas.restore();
    _pintarLabio(canvas, e.hoyo, anchoHoyo);
    _pintarTrozos(canvas, e.hoyo, anchoHoyo, adelante: true);

    // Las garras del robot, por delante del pez.
    if (robot != null && hundido != null) {
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(-w * 4, -h * 6, w * 6, robot.pies.dy + 2));
      _pintarBrazosRobot(
        canvas,
        robot.pies + hundido,
        robot.alto,
        robot.garra + hundido,
        robot.garraAtras + hundido,
      );
      canvas.restore();
    }

    _hilos(canvas, w, h);
    for (final equipo in [Equipo.carga, Equipo.helicoptero]) {
      final heli = e.helicoptero(equipo);
      if (heli == null) continue;
      if (equipo == Equipo.carga) {
        _pintarHelicopteroDeCarga(
          canvas,
          heli.centro,
          e.largoCarga,
          heli.inclinacion,
          tiempo,
        );
      } else {
        _pintarHelicoptero(
          canvas,
          heli.centro,
          e.largoHelicoptero,
          heli.inclinacion,
          tiempo,
        );
      }
    }

    // El agua que salta: cuando pica, cuando sale el chico y cuando sale el
    // grande. El hielo que vuela: cuando sale el gigante y el robot.
    final g = e.guion;
    _pintarGotas(canvas, e.hoyo, (t - .8 * r) / r, h * .35, 1);
    if (g.chicoAfuera case final chico?) {
      _pintarGotas(canvas, e.hoyo, (t - chico) / r, h * .5, 2);
    }
    _pintarGotas(canvas, e.hoyo, (t - g.afuera) / r, h * .8, 3);
    if (g.trago case final trago?) {
      _pintarEsquirlas(
        canvas,
        e.hoyo,
        (t - trago - g.duraTrago * .1) / r,
        h * 1.1,
        4,
      );
    }
    final llegadaRobot = g.llegadaDe(Equipo.robot);
    if (robot != null && llegadaRobot != null) {
      _pintarEsquirlas(
        canvas,
        robot.pies,
        (t - llegadaRobot.cuando) / r,
        h * 1.2,
        5,
      );
    }
    canvas.restore();

    // La nieve que cae, siempre cerca: chica y lejos, grande y borrosa
    // adelante.
    final copo = Paint();
    for (var i = 0; i < 70; i++) {
      final cerca = i % 10 == 0;
      final velocidad = (cerca ? 60 : 22) + (i * 13 % 30);
      final y = (tiempo * velocidad + i * 47) % (h + 40) - 20;
      final x = (i * 61 % w) + math.sin(tiempo * .8 + i) * 14;
      final p = Offset(x, y);
      if (cerca) {
        copo.shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: p, radius: 6));
        canvas.drawCircle(p, 6, copo);
      } else {
        copo
          ..shader = null
          ..color = Colors.white.withValues(alpha: .85);
        canvas.drawCircle(p, 1 + (i % 3) * .7, copo);
      }
    }
    // La viñeta, para que la mirada vaya al hoyo.
    canvas.drawRect(
      todo,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.2, .3),
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .18)],
        ).createShader(todo),
    );
  }

  /// Una nube de invierno: bolas blancas con la panza celeste.
  void _nube(Canvas canvas, Offset centro, double ancho) {
    final sombra = Paint()
      ..color = const Color(0xFFC9DFEE).withValues(alpha: .9);
    final blanca = Paint()..color = Colors.white.withValues(alpha: .92);
    for (final (x, y, r) in const [
      (-.3, .05, .2),
      (-.1, -.08, .27),
      (.14, -.04, .23),
      (.33, .06, .17),
    ]) {
      canvas.drawCircle(centro + Offset(x, y + .05) * ancho, ancho * r, sombra);
    }
    for (final (x, y, r) in const [
      (-.3, .02, .19),
      (-.1, -.11, .26),
      (.14, -.07, .22),
      (.33, .03, .16),
    ]) {
      canvas.drawCircle(centro + Offset(x, y) * ancho, ancho * r, blanca);
    }
  }

  /// Lo que se mueve del paisaje: los brillos de la nieve, el humo de las
  /// chimeneas y las banderas.
  void _paisajeVivo(Canvas canvas, double w, double h) {
    final horizonte = h * .46;
    final azar = math.Random(29);
    for (var i = 0; i < 34; i++) {
      final p = Offset(
        -w * .5 + azar.nextDouble() * w * 2,
        horizonte + 8 + azar.nextDouble() * h * .5,
      );
      final brilla = math.max(
        0.0,
        math.sin(tiempo * (2 + azar.nextDouble() * 2) + i * 1.7),
      );
      if (brilla > .2) {
        pintarDestello(
          canvas,
          p,
          2.2 + 3 * brilla,
          Colors.white.withValues(alpha: .9 * brilla),
        );
      }
    }
    for (final (x, ancho, baja) in _cabanas) {
      final piso = Offset(w * x, horizonte + h * baja);
      final anchoCabana = w * ancho;
      final alto = anchoCabana * .55;
      final pared = Rect.fromLTWH(piso.dx, piso.dy - alto, anchoCabana, alto);
      // El humo de la chimenea, que sube y se deshace.
      final chimenea = Offset(
        pared.right - anchoCabana * .2,
        pared.top - alto * .5,
      );
      final humo = Paint();
      for (var k = 0; k < 6; k++) {
        final edad = (tiempo * .3 + k / 6) % 1;
        humo.color = const Color(
          0xFFE9F0F4,
        ).withValues(alpha: .7 * (1 - edad) * math.min(1, edad * 5));
        canvas.drawCircle(
          chimenea +
              Offset(
                edad * anchoCabana * .5 + math.sin(edad * 7 + k) * 3,
                -edad * alto * 2.2,
              ),
          anchoCabana * (.04 + edad * .1),
          humo,
        );
      }
      // La bandera que flamea.
      final arriba = Offset(
        pared.right + anchoCabana * .3,
        piso.dy - alto * 1.6,
      );
      final bandera = Path()..moveTo(arriba.dx, arriba.dy);
      for (var i = 0; i <= 6; i++) {
        final bx = arriba.dx + anchoCabana * .32 * i / 6;
        bandera.lineTo(bx, arriba.dy + math.sin(tiempo * 5 + i) * 2.5);
      }
      for (var i = 6; i >= 0; i--) {
        final bx = arriba.dx + anchoCabana * .32 * i / 6;
        bandera.lineTo(
          bx,
          arriba.dy + alto * .32 + math.sin(tiempo * 5 + i) * 2.5,
        );
      }
      canvas.drawPath(bandera, Paint()..color = const Color(0xFFF5C542));
    }
  }

  /// El hilo (o el cable) de quien tiene el pez, y el del equipo que llega,
  /// que baja hasta la boca.
  void _hilos(Canvas canvas, double w, double h) {
    final e = escena;
    final hilo = Paint()
      ..strokeWidth = 1.4 / e.camara
      ..color = Colors.white.withValues(alpha: .92);
    final cable = Paint()
      ..strokeWidth = 2.4 / e.camara
      ..color = const Color(0xFF37474F);
    final boca = e.bocaSostenida;
    final grua = e.grua;
    switch (e.sostiene) {
      case Equipo.cana:
        canvas.drawLine(e.puntaCana, boca, hilo);
      case Equipo.grua:
        if (grua != null) {
          canvas.drawLine(grua.punta, boca, cable);
          _pintarGancho(canvas, boca, h * .012);
        }
      case Equipo.helicoptero || Equipo.carga:
        final heli = e.helicoptero(e.sostiene);
        if (heli != null) {
          final desde = e.gancho(
            heli.centro,
            heli.inclinacion,
            carga: e.sostiene == Equipo.carga,
          );
          canvas.drawLine(desde, boca, cable);
          _pintarGancho(canvas, boca, h * .012);
        }
      case Equipo.robot:
        break;
    }
    // El equipo que esta llegando baja el cable.
    double baja(double llega) => ((llega - .35) / .35).clamp(0.0, 1.0);
    if (grua != null && e.sostiene != Equipo.grua) {
      final antes = grua.llega < .7;
      final fin = antes
          ? Offset.lerp(grua.punta, boca, baja(grua.llega))!
          : grua.punta + Offset(0, h * .06);
      if (grua.llega > .35) {
        canvas.drawLine(grua.punta, fin, cable);
        _pintarGancho(canvas, fin, h * .012);
      }
    }
    for (final equipo in [Equipo.helicoptero, Equipo.carga]) {
      final heli = e.helicoptero(equipo);
      if (heli == null || e.sostiene == equipo || heli.llega >= .7) continue;
      if (heli.llega <= .35) continue;
      final desde = e.gancho(
        heli.centro,
        heli.inclinacion,
        carga: equipo == Equipo.carga,
      );
      final fin = Offset.lerp(desde, boca, baja(heli.llega))!;
      canvas.drawLine(desde, fin, cable);
      _pintarGancho(canvas, fin, h * .012);
    }
  }

  @override
  bool shouldRepaint(_PintorLago viejo) => true;
}

/// Un pez parado, con la boca arriba en [boca] (donde va el hilo) y el
/// cuerpo colgando hacia abajo.
void _pintarPezParado(
  Canvas canvas,
  Offset boca,
  double largo,
  double grosor,
  Pez pez, {
  double giro = 0,
  double cola = 0,
}) {
  canvas
    ..save()
    ..translate(boca.dx, boca.dy)
    ..rotate(-math.pi / 2 + giro);
  // pintarPez dibuja la cabeza a la derecha: la boca queda en el origen.
  final alto = largo * grosor;
  pintarPez(
    canvas,
    Rect.fromLTWH(-largo, -alto * .56, largo, alto),
    pez,
    boca: true,
    cola: cola,
  );
  canvas.restore();
}

/// El agua que le chorrea al pez que salio: gotas que se sueltan del
/// cuerpo y caen al hoyo.
void _pintarChorreo(
  Canvas canvas,
  Offset boca,
  double agua,
  double largo,
  double ancho,
  double tiempo,
) {
  if (largo < 6) return;
  final gota = Paint()..color = const Color(0xFFBFE3F5).withValues(alpha: .9);
  final brillo = Paint()..color = Colors.white.withValues(alpha: .9);
  for (var k = 0; k < 7; k++) {
    final edad = (tiempo * 1.3 + k / 7) % 1;
    final x = boca.dx + (((k * 37) % 9) / 9 - .5) * ancho * .7;
    final desde = boca.dy + largo * (.25 + ((k * 53) % 7) / 7 * .6);
    final y = desde + (agua - desde) * edad * edad;
    if (y > agua) continue;
    final tam = 1.4 + (k % 3) * .6;
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: tam * 1.4,
          height: tam * 2.2,
        ),
        gota,
      )
      ..drawCircle(Offset(x - tam * .2, y - tam * .3), tam * .3, brillo);
  }
}

/// El viento de las aspas: anillos de nieve que se abren sobre el hielo
/// alrededor del hoyo, y polvo de nieve que vuela hacia afuera.
void _pintarVentarron(
  Canvas canvas,
  Offset centro,
  double ancho,
  double tiempo,
) {
  for (var k = 0; k < 3; k++) {
    final fase = (tiempo * 1.2 + k / 3) % 1;
    final rx = ancho * (.6 + fase * 1.4);
    canvas.drawOval(
      Rect.fromCenter(center: centro, width: rx * 2, height: rx * .5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - fase) + .5
        ..color = Colors.white.withValues(alpha: .6 * (1 - fase)),
    );
  }
  final polvo = Paint();
  for (var k = 0; k < 18; k++) {
    final angulo = k / 18 * 2 * math.pi;
    final fase = (tiempo * 1.6 + k * .13) % 1;
    final lejos = ancho * (.55 + fase * 1.3);
    polvo.color = Colors.white.withValues(alpha: .75 * (1 - fase));
    canvas.drawCircle(
      centro +
          Offset(
            math.cos(angulo) * lejos,
            math.sin(angulo) * lejos * .25 - fase * 8,
          ),
      1.5 + fase * 2.5,
      polvo,
    );
  }
}

/// La bocaza del pez gigante que sale del hielo a tragarse al chico: la
/// cabeza vista de frente, con la boca abierta para arriba ([abre] 0
/// cerrada, 1 abierta del todo), los dientes y los ojos que miran al chico.
void _pintarBocaza(
  Canvas canvas,
  Offset base,
  double ancho,
  double alto,
  double abre,
  Pez pez,
) {
  final (lomo, flanco, panza) = ColoresPesca.dePez(pez);
  final mitad = ancho / 2;
  final arriba = base.dy - alto;
  final labio = mitad * (.5 + .5 * abre);
  final puntaLabio = arriba + alto * .08 * (1 - abre);
  final garganta = arriba + alto * (.5 * abre - .06 * (1 - abre));
  final izquierda = Offset(base.dx - labio, puntaLabio);
  final derecha = Offset(base.dx + labio, puntaLabio);
  final fondo = Offset(base.dx, garganta);

  // Las aletas del costado.
  final aleta = Paint()..color = lomo;
  for (final lado in [-1.0, 1.0]) {
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + lado * mitad * .9, base.dy - alto * .25)
        ..lineTo(base.dx + lado * mitad * 1.45, base.dy - alto * .48)
        ..lineTo(base.dx + lado * mitad * 1.25, base.dy - alto * .1)
        ..close(),
      aleta,
    );
  }
  final cuerpo = Path()
    ..moveTo(base.dx - mitad, base.dy + 4)
    ..cubicTo(
      base.dx - mitad * 1.08,
      base.dy - alto * .55,
      base.dx - labio * 1.1,
      puntaLabio + alto * .18,
      izquierda.dx,
      izquierda.dy,
    )
    ..quadraticBezierTo(base.dx - labio * .35, garganta, fondo.dx, fondo.dy)
    ..quadraticBezierTo(base.dx + labio * .35, garganta, derecha.dx, derecha.dy)
    ..cubicTo(
      base.dx + labio * 1.1,
      puntaLabio + alto * .18,
      base.dx + mitad * 1.08,
      base.dy - alto * .55,
      base.dx + mitad,
      base.dy + 4,
    )
    ..close();
  final caja = Rect.fromLTRB(base.dx - mitad, arriba, base.dx + mitad, base.dy);
  canvas.drawPath(
    cuerpo,
    Paint()
      ..shader = LinearGradient(
        colors: [lomo, flanco, panza, flanco, lomo],
        stops: const [0, .25, .5, .75, 1],
      ).createShader(caja),
  );
  // Las escamas, como en los demas peces.
  final escama = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(.8, ancho * .008)
    ..color = Colors.white.withValues(alpha: .2);
  final paso = ancho * .11;
  canvas
    ..save()
    ..clipPath(cuerpo);
  for (var fila = 0; fila < 8; fila++) {
    final y = arriba + alto * .55 + fila * paso * .8;
    for (var col = -5; col <= 5; col++) {
      final x = base.dx + col * paso + (fila.isOdd ? paso / 2 : 0);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: paso * .5),
        0,
        math.pi,
        false,
        escama,
      );
    }
  }
  canvas.restore();

  // Adentro de la boca: oscura, con la lengua y los dientes.
  if (abre > .04) {
    final boca = Path()
      ..moveTo(izquierda.dx, izquierda.dy)
      ..quadraticBezierTo(
        base.dx,
        puntaLabio - alto * .1 * abre,
        derecha.dx,
        derecha.dy,
      )
      ..quadraticBezierTo(base.dx + labio * .35, garganta, fondo.dx, fondo.dy)
      ..quadraticBezierTo(
        base.dx - labio * .35,
        garganta,
        izquierda.dx,
        izquierda.dy,
      )
      ..close();
    canvas
      ..drawPath(boca, Paint()..color = const Color(0xFF3B0710))
      ..drawOval(
        Rect.fromCenter(
          center: Offset(base.dx, garganta - alto * .07 * abre),
          width: labio * .7,
          height: alto * .1 * abre,
        ),
        Paint()..color = const Color(0xFFC2414F),
      );
    final diente = Paint()..color = Colors.white;
    for (final (lado, punta) in [(-1.0, izquierda), (1.0, derecha)]) {
      final tangente = (fondo - punta) / math.max(1, (fondo - punta).distance);
      final adentro = Offset(-lado, -.4) / Offset(-lado, -.4).distance;
      for (var i = 0; i < 4; i++) {
        final p = Offset.lerp(punta, fondo, .12 + i * .2)!;
        final tam = ancho * .045 * abre;
        final a = p - tangente * tam * .5;
        final b = p + tangente * tam * .5;
        final c = p + adentro * tam;
        canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy)
            ..lineTo(c.dx, c.dy)
            ..close(),
          diente,
        );
      }
    }
  }
  // Los labios.
  canvas.drawPath(
    Path()
      ..moveTo(izquierda.dx, izquierda.dy)
      ..quadraticBezierTo(base.dx - labio * .35, garganta, fondo.dx, fondo.dy)
      ..quadraticBezierTo(
        base.dx + labio * .35,
        garganta,
        derecha.dx,
        derecha.dy,
      ),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ancho * .025
      ..strokeCap = StrokeCap.round
      ..color = panza,
  );
  // Los ojos, que miran al chico.
  for (final lado in [-1.0, 1.0]) {
    final ojo = Offset(base.dx + lado * mitad * .55, arriba + alto * .52);
    final radio = ancho * .075;
    canvas
      ..drawCircle(ojo, radio, Paint()..color = Colors.white)
      ..drawCircle(
        ojo + Offset(-lado * radio * .15, -radio * .3),
        radio * .55,
        Paint()..color = const Color(0xFF0E1A22),
      )
      ..drawCircle(
        ojo + Offset(-lado * radio * .3, -radio * .5),
        radio * .18,
        Paint()..color = Colors.white,
      );
  }
}

/// El hoyo en el hielo: el agua oscura, con las ondas que hace el hilo.
void _pintarHoyo(
  Canvas canvas,
  Offset centro,
  double ancho,
  double tiempo, {
  double agitado = 0,
}) {
  final agujero = Rect.fromCenter(
    center: centro,
    width: ancho,
    height: ancho * .24,
  );
  canvas
    ..drawOval(
      agujero.inflate(ancho * .045),
      Paint()..color = const Color(0xFFBFD7E5),
    )
    ..drawOval(agujero.inflate(ancho * .02), Paint()..color = Colors.white)
    ..drawOval(
      agujero,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF0A2A40), Color(0xFF1C5F84)],
        ).createShader(agujero),
    );
  final onda = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  for (var i = 0; i < 3; i++) {
    final fase = (tiempo * (.7 + .7 * agitado) + i / 3) % 1;
    onda.color = Colors.white.withValues(alpha: .35 * (1 - fase));
    canvas.drawOval(
      Rect.fromCenter(
        center: centro,
        width: agujero.width * (.2 + .7 * fase),
        height: agujero.height * (.2 + .7 * fase),
      ),
      onda,
    );
  }
}

/// El borde de adelante del hoyo, por delante de lo que sale del agua.
void _pintarLabio(Canvas canvas, Offset centro, double ancho) {
  final borde = Rect.fromCenter(
    center: centro,
    width: ancho,
    height: ancho * .24,
  ).inflate(ancho * .02);
  canvas.drawArc(
    borde,
    0,
    math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ancho * .04
      ..color = Colors.white,
  );
}

/// Los trozos de hielo roto alrededor del hoyo: los de atras o los de
/// adelante. Cuanto mas grande el hoyo, mas grandes.
void _pintarTrozos(
  Canvas canvas,
  Offset centro,
  double ancho, {
  required bool adelante,
}) {
  final azar = math.Random(7);
  final relleno = Paint()..color = const Color(0xFFDDEEF7);
  final sombra = Paint()..color = const Color(0xFF9CC3DA);
  final brillo = Paint()
    ..color = Colors.white
    ..strokeWidth = math.max(1, ancho * .006);
  for (var i = 0; i < 16; i++) {
    final angulo = azar.nextDouble() * 2 * math.pi;
    final lejos = .52 + azar.nextDouble() * .2;
    final tam = ancho * (.03 + azar.nextDouble() * .045);
    if ((math.sin(angulo) > 0) != adelante) continue;
    final p =
        centro +
        Offset(
          math.cos(angulo) * ancho * lejos,
          math.sin(angulo) * ancho * .14 * lejos * 1.8,
        );
    final trozo = Path()
      ..moveTo(p.dx - tam, p.dy)
      ..lineTo(p.dx - tam * .3, p.dy - tam * .8)
      ..lineTo(p.dx + tam * .8, p.dy - tam * .5)
      ..lineTo(p.dx + tam, p.dy + tam * .2)
      ..close();
    canvas
      ..drawPath(trozo.shift(Offset(0, tam * .18)), sombra)
      ..drawPath(trozo, relleno)
      ..drawLine(
        Offset(p.dx - tam * .3, p.dy - tam * .8),
        Offset(p.dx + tam * .8, p.dy - tam * .5),
        brillo,
      );
  }
}

/// La caña, apoyada en una horqueta clavada en la nieve: el mango de corcho
/// abajo, el carrete colgando y la punta que se dobla hacia el hoyo.
void _pintarCana(
  Canvas canvas,
  Offset mango,
  Offset horqueta,
  Offset punta,
  double tension,
  double vuelta,
  double w,
  double h,
) {
  final suelo = Offset(horqueta.dx - w * .012, h * .815);
  canvas.drawOval(
    Rect.fromCenter(
      center: suelo + const Offset(0, 2),
      width: w * .17,
      height: h * .026,
    ),
    Paint()..color = const Color(0xFFFDFEFF),
  );
  final palo = Paint()
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF5C3B22);
  final cruce = horqueta + const Offset(0, 7);
  canvas
    ..drawLine(suelo, cruce, palo)
    ..drawLine(cruce, horqueta + const Offset(-7, -6), palo..strokeWidth = 4)
    ..drawLine(cruce, horqueta + const Offset(7, -5), palo);
  final control =
      Offset.lerp(horqueta, punta, .5)! +
      Offset(-w * .08 * (1 - tension * .4), -h * .08 + tension * h * .05);
  final cana = Path()
    ..moveTo(horqueta.dx, horqueta.dy)
    ..quadraticBezierTo(control.dx, control.dy, punta.dx, punta.dy);
  canvas
    ..drawPath(
      cana,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A1A1A),
    )
    ..drawPath(
      cana,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB0242F),
    )
    ..drawLine(
      mango,
      horqueta,
      Paint()
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A2414),
    )
    ..drawLine(
      mango,
      horqueta,
      Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFC9A26B),
    );
  // El carrete, colgando del mango, con la manivela que gira mientras
  // recoge.
  final colgado = Offset.lerp(mango, horqueta, .5)!;
  final carrete = colgado + const Offset(0, 12);
  canvas
    ..drawLine(
      carrete,
      colgado,
      Paint()
        ..strokeWidth = 3
        ..color = const Color(0xFF2B2F33),
    )
    ..drawCircle(carrete, 10, Paint()..color = const Color(0xFF2B2F33))
    ..drawCircle(carrete, 6.5, Paint()..color = const Color(0xFF9AA5AD))
    ..drawLine(
      carrete,
      carrete + Offset(math.cos(vuelta), math.sin(vuelta)) * 12,
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2B2F33),
    );
}

/// El gancho al final del cable.
void _pintarGancho(Canvas canvas, Offset donde, double tam) {
  final gancho = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = tam * .35
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF455A64);
  canvas
    ..drawRect(
      Rect.fromCenter(
        center: donde - Offset(0, tam * 1.2),
        width: tam * 1.1,
        height: tam * 1.4,
      ),
      Paint()..color = const Color(0xFFF5C542),
    )
    ..drawArc(
      Rect.fromCircle(center: donde + Offset(0, tam * .2), radius: tam * .6),
      -math.pi * .1,
      math.pi * 1.2,
      false,
      gancho,
    );
}

/// La grua: un camion rojo con estabilizadores y un brazo telescopico que
/// va de [base] a [punta].
void _pintarGrua(
  Canvas canvas,
  Offset camion,
  Offset base,
  Offset punta,
  double ruedas,
  double w,
  double h,
) {
  final largo = w * .52;
  final alto = h * .055;
  const rojo = Color(0xFFC62828);
  const rojoOscuro = Color(0xFF8E1B1B);
  const gris = Color(0xFF37474F);
  final piso = camion.dy;
  // Los estabilizadores, apoyados en el hielo.
  final pata = Paint()
    ..color = gris
    ..strokeWidth = alto * .22
    ..strokeCap = StrokeCap.round;
  canvas
    ..drawLine(
      Offset(camion.dx - largo * .44, piso - alto * .9),
      Offset(camion.dx - largo * .5, piso + alto * .05),
      pata,
    )
    ..drawLine(
      Offset(camion.dx + largo * .24, piso - alto * .9),
      Offset(camion.dx + largo * .3, piso + alto * .05),
      pata,
    );
  // El chasis, con su franja blanca.
  final chasis = Rect.fromLTWH(
    camion.dx - largo / 2,
    piso - alto * 1.45,
    largo * .78,
    alto,
  );
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(chasis, Radius.circular(alto * .2)),
      Paint()..color = rojo,
    )
    ..drawRect(
      Rect.fromLTWH(
        chasis.left,
        chasis.top + alto * .58,
        chasis.width,
        alto * .14,
      ),
      Paint()..color = Colors.white.withValues(alpha: .85),
    );
  // La cabina, adelante.
  final cabina = Rect.fromLTWH(
    chasis.right - largo * .02,
    piso - alto * 2.1,
    largo * .22,
    alto * 1.65,
  );
  canvas
    ..drawRRect(
      RRect.fromRectAndCorners(
        cabina,
        topLeft: Radius.circular(alto * .2),
        topRight: Radius.circular(alto * .6),
        bottomLeft: Radius.circular(alto * .1),
        bottomRight: Radius.circular(alto * .2),
      ),
      Paint()..color = rojo,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cabina.left + cabina.width * .45,
          cabina.top + alto * .18,
          cabina.width * .45,
          alto * .55,
        ),
        Radius.circular(alto * .1),
      ),
      Paint()..color = const Color(0xFF90CAF9),
    );
  // Las ruedas, que giran mientras llega.
  for (final f in [.1, .26, .62, .88]) {
    final centro = Offset(camion.dx - largo / 2 + largo * f, piso - alto * .32);
    canvas
      ..drawCircle(centro, alto * .34, Paint()..color = const Color(0xFF1E2327))
      ..drawCircle(
        centro,
        alto * .15,
        Paint()..color = const Color(0xFF9AA5AD),
      );
    for (var k = 0; k < 3; k++) {
      final angulo = ruedas + k * math.pi * 2 / 3;
      canvas.drawLine(
        centro,
        centro + Offset(math.cos(angulo), math.sin(angulo)) * alto * .14,
        Paint()
          ..strokeWidth = alto * .05
          ..color = const Color(0xFF1E2327),
      );
    }
  }
  // El piston, la torreta y el brazo.
  canvas.drawLine(
    Offset(base.dx + largo * .12, chasis.top),
    Offset.lerp(base, punta, .3)!,
    Paint()
      ..strokeWidth = alto * .2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB0BEC5),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base + Offset(0, alto * .25),
        width: largo * .2,
        height: alto * .9,
      ),
      Radius.circular(alto * .15),
    ),
    Paint()..color = gris,
  );
  final dir = punta - base;
  final largoBrazo = dir.distance;
  if (largoBrazo < 1) return;
  final normal = Offset(-dir.dy, dir.dx) / largoBrazo;
  final grueso = alto * .55;
  final a = base + normal * grueso / 2;
  final b = punta + normal * grueso * .22;
  final c = punta - normal * grueso * .22;
  final d = base - normal * grueso / 2;
  final brazo = Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(c.dx, c.dy)
    ..lineTo(d.dx, d.dy)
    ..close();
  canvas
    ..drawPath(brazo, Paint()..color = rojo)
    ..drawPath(
      brazo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = alto * .06
        ..color = rojoOscuro,
    );
  // Las juntas del brazo telescopico.
  for (final f in [.38, .62, .82]) {
    final p = Offset.lerp(base, punta, f)!;
    final mitad = ui.lerpDouble(grueso / 2, grueso * .22, f)!;
    canvas.drawLine(
      p + normal * mitad,
      p - normal * mitad,
      Paint()
        ..strokeWidth = alto * .1
        ..color = Colors.white,
    );
  }
  canvas.drawCircle(punta, alto * .22, Paint()..color = gris);
}

/// Un helicoptero chico, rojo y blanco, con el rotor que gira borroso.
/// [inclinacion] lo inclina hacia donde va.
void _pintarHelicoptero(
  Canvas canvas,
  Offset centro,
  double largo,
  double inclinacion,
  double tiempo,
) {
  final alto = largo * .3;
  const rojo = Color(0xFFD32F2F);
  const oscuro = Color(0xFF263238);
  canvas
    ..save()
    ..translate(centro.dx, centro.dy)
    ..rotate(inclinacion);
  // La cola, con su aleta y su rotor chico.
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(largo * .02, -alto * .2, largo * .5, alto * .17),
        Radius.circular(alto * .08),
      ),
      Paint()..color = rojo,
    )
    ..drawPath(
      Path()
        ..moveTo(largo * .44, -alto * .12)
        ..lineTo(largo * .5, -alto * .62)
        ..lineTo(largo * .56, -alto * .62)
        ..lineTo(largo * .54, -alto * .06)
        ..close(),
      Paint()..color = rojo,
    );
  final cola = Offset(largo * .53, -alto * .42);
  final giroCola = Offset(math.cos(tiempo * 40), math.sin(tiempo * 40));
  final paleta = Paint()
    ..color = oscuro.withValues(alpha: .7)
    ..strokeWidth = alto * .05
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    cola + giroCola * alto * .2,
    cola - giroCola * alto * .2,
    paleta,
  );
  // El cuerpo, blanco con la panza roja, y la ventana del frente.
  final cuerpo = Rect.fromCenter(
    center: Offset(-largo * .14, 0),
    width: largo * .55,
    height: alto,
  );
  canvas
    ..drawOval(cuerpo, Paint()..color = Colors.white)
    ..save()
    ..clipPath(Path()..addOval(cuerpo))
    ..drawRect(
      Rect.fromLTRB(
        cuerpo.left,
        cuerpo.center.dy + alto * .05,
        cuerpo.right,
        cuerpo.bottom,
      ),
      Paint()..color = rojo,
    )
    ..restore()
    ..drawOval(
      Rect.fromCenter(
        center: Offset(-largo * .32, -alto * .1),
        width: largo * .17,
        height: alto * .5,
      ),
      Paint()..color = const Color(0xFF90CAF9),
    )
    ..drawOval(
      Rect.fromCenter(
        center: Offset(-largo * .3, -alto * .18),
        width: largo * .07,
        height: alto * .16,
      ),
      Paint()..color = Colors.white.withValues(alpha: .7),
    );
  // Los patines.
  final patin = Paint()
    ..color = oscuro
    ..strokeWidth = alto * .07
    ..strokeCap = StrokeCap.round;
  canvas
    ..drawLine(
      Offset(-largo * .42, alto * .78),
      Offset(largo * .1, alto * .78),
      patin,
    )
    ..drawLine(
      Offset(-largo * .3, alto * .45),
      Offset(-largo * .32, alto * .78),
      patin,
    )
    ..drawLine(Offset(-largo * .02, alto * .45), Offset(0, alto * .78), patin);
  // El rotor de arriba, girando: un disco borroso y una paleta.
  final eje = Offset(-largo * .14, -alto * .62);
  final vuelta = math.sin(tiempo * 47);
  canvas
    ..drawLine(Offset(-largo * .14, -alto * .48), eje, patin)
    ..drawOval(
      Rect.fromCenter(center: eje, width: largo * 1.15, height: alto * .16),
      Paint()..color = oscuro.withValues(alpha: .14),
    )
    ..drawLine(
      eje + Offset(largo * .57 * vuelta, 0),
      eje - Offset(largo * .57 * vuelta, 0),
      Paint()
        ..color = oscuro.withValues(alpha: .75)
        ..strokeWidth = alto * .06
        ..strokeCap = StrokeCap.round,
    )
    ..restore();
}

/// El helicoptero de carga: largo, con un rotor en cada punta.
void _pintarHelicopteroDeCarga(
  Canvas canvas,
  Offset centro,
  double largo,
  double inclinacion,
  double tiempo,
) {
  final alto = largo * .2;
  const rojo = Color(0xFFC62828);
  const oscuro = Color(0xFF263238);
  canvas
    ..save()
    ..translate(centro.dx, centro.dy)
    ..rotate(inclinacion)
    // La torre de atras, mas alta.
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(largo * .3, -alto * 1.0, largo * .18, alto * .8),
        Radius.circular(alto * .15),
      ),
      Paint()..color = rojo,
    );
  final cuerpo = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: largo, height: alto),
    Radius.circular(alto * .45),
  );
  canvas
    ..drawRRect(cuerpo, Paint()..color = Colors.white)
    ..save()
    ..clipRRect(cuerpo)
    ..drawRect(
      Rect.fromLTRB(-largo / 2, -alto / 2, largo / 2, -alto * .05),
      Paint()..color = rojo,
    )
    ..restore();
  // Las ventanas y la cabina.
  for (var i = 0; i < 6; i++) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -largo * .26 + i * largo * .085,
          -alto * .02,
          largo * .05,
          alto * .2,
        ),
        Radius.circular(alto * .05),
      ),
      Paint()..color = const Color(0xFF90CAF9),
    );
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-largo * .5, -alto * .42, largo * .13, alto * .38),
      Radius.circular(alto * .15),
    ),
    Paint()..color = const Color(0xFF90CAF9),
  );
  for (final x in [-.32, .28]) {
    canvas.drawCircle(
      Offset(largo * x, alto * .6),
      alto * .16,
      Paint()..color = oscuro,
    );
  }
  // Los dos rotores.
  for (final (x, y) in [
    (-largo * .38, -alto * .75),
    (largo * .39, -alto * 1.15),
  ]) {
    final eje = Offset(x, y);
    final vuelta = math.sin(tiempo * 43 + x);
    canvas
      ..drawLine(
        eje + Offset(0, alto * .3),
        eje,
        Paint()
          ..color = oscuro
          ..strokeWidth = alto * .1,
      )
      ..drawOval(
        Rect.fromCenter(center: eje, width: largo * .62, height: alto * .2),
        Paint()..color = oscuro.withValues(alpha: .14),
      )
      ..drawLine(
        eje + Offset(largo * .3 * vuelta, 0),
        eje - Offset(largo * .3 * vuelta, 0),
        Paint()
          ..color = oscuro.withValues(alpha: .75)
          ..strokeWidth = alto * .08
          ..strokeCap = StrokeCap.round,
      );
  }
  canvas.restore();
}

/// El robot que sale del hielo a sacar los peces enormes: acero, con un
/// visor amarillo, el corazon que brilla y una baliza roja. Los brazos van
/// aparte ([_pintarBrazosRobot]), por delante del pez.
void _pintarRobot(Canvas canvas, Offset pies, double alto, double tiempo) {
  const acero = Color(0xFF56636E);
  const oscuro = Color(0xFF2B333A);
  const claro = Color(0xFF8D9BA6);
  const naranja = Color(0xFFF29F05);
  final ancho = alto * .48;
  final cadera = pies.dy - alto * .42;
  final hombros = pies.dy - alto * .74;
  // Las piernas.
  for (final lado in [-1.0, 1.0]) {
    final x = pies.dx + lado * ancho * .2;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - ancho * .1,
            cadera,
            x + ancho * .1,
            pies.dy - alto * .2,
          ),
          Radius.circular(ancho * .04),
        ),
        Paint()..color = acero,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - ancho * .09,
            pies.dy - alto * .2,
            x + ancho * .09,
            pies.dy - alto * .04,
          ),
          Radius.circular(ancho * .04),
        ),
        Paint()..color = acero,
      )
      ..drawCircle(
        Offset(x, pies.dy - alto * .2),
        ancho * .1,
        Paint()..color = oscuro,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - ancho * .17,
            pies.dy - alto * .05,
            x + ancho * .17,
            pies.dy,
          ),
          Radius.circular(ancho * .04),
        ),
        Paint()..color = oscuro,
      );
  }
  // La cadera y el cuerpo.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pies.dx, cadera),
        width: ancho * .62,
        height: alto * .07,
      ),
      Radius.circular(ancho * .05),
    ),
    Paint()..color = oscuro,
  );
  final torso = Path()
    ..moveTo(pies.dx - ancho * .5, hombros)
    ..lineTo(pies.dx + ancho * .5, hombros)
    ..lineTo(pies.dx + ancho * .34, cadera - alto * .02)
    ..lineTo(pies.dx - ancho * .34, cadera - alto * .02)
    ..close();
  canvas
    ..drawPath(
      torso,
      Paint()
        ..shader = const LinearGradient(colors: [claro, acero, oscuro])
            .createShader(
              Rect.fromLTRB(
                pies.dx - ancho * .5,
                hombros,
                pies.dx + ancho * .5,
                cadera,
              ),
            ),
    )
    // Las franjas naranjas.
    ..save()
    ..clipPath(torso);
  final franja = Paint()
    ..strokeWidth = ancho * .06
    ..color = naranja;
  for (final f in [.15, .85]) {
    canvas.drawLine(
      Offset(pies.dx - ancho * .5 + ancho * f, hombros),
      Offset(pies.dx - ancho * .5 + ancho * f + ancho * .1, cadera),
      franja,
    );
  }
  canvas.restore();
  // El corazon que brilla.
  final nucleo = Offset(pies.dx, hombros + alto * .14);
  final late = .6 + .4 * math.sin(tiempo * 5);
  canvas
    ..drawCircle(nucleo, ancho * .13, Paint()..color = oscuro)
    ..drawCircle(
      nucleo,
      ancho * .12,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: .5 * late)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ancho * .05),
    )
    ..drawCircle(nucleo, ancho * .07, Paint()..color = const Color(0xFFFFE082));
  // La cabeza, con el visor y la baliza.
  final cabeza = Rect.fromCenter(
    center: Offset(pies.dx, hombros - alto * .07),
    width: ancho * .4,
    height: alto * .12,
  );
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(cabeza, Radius.circular(ancho * .06)),
      Paint()..color = acero,
    )
    // El visor, que brilla y late como si mirara.
    ..drawOval(
      Rect.fromCenter(
        center: cabeza.center,
        width: cabeza.width * 1.5,
        height: cabeza.height * 1.1,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(
                  0xFFFFD54F,
                ).withValues(alpha: .45 + .25 * math.sin(tiempo * 3)),
                const Color(0xFFFFD54F).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCenter(
                center: cabeza.center,
                width: cabeza.width * 1.5,
                height: cabeza.height * 1.1,
              ),
            ),
    )
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: cabeza.center,
          width: cabeza.width * .8,
          height: cabeza.height * .28,
        ),
        Radius.circular(ancho * .03),
      ),
      Paint()..color = const Color(0xFFFFE57F),
    )
    // Los dos ojos, mas claros dentro del visor.
    ..drawCircle(
      cabeza.center - Offset(cabeza.width * .2, 0),
      cabeza.height * .1,
      Paint()..color = Colors.white,
    )
    ..drawCircle(
      cabeza.center + Offset(cabeza.width * .2, 0),
      cabeza.height * .1,
      Paint()..color = Colors.white,
    );
  // El vapor que larga por las ventilas de la espalda.
  final vapor = Paint();
  for (final lado in [-1.0, 1.0]) {
    final ventila = Offset(pies.dx + lado * ancho * .38, hombros - alto * .02);
    for (var k = 0; k < 4; k++) {
      final edad = (tiempo * .9 + k / 4 + (lado > 0 ? .5 : 0)) % 1;
      vapor.color = Colors.white.withValues(alpha: .55 * (1 - edad));
      canvas.drawCircle(
        ventila + Offset(lado * edad * ancho * .2, -edad * alto * .16),
        ancho * (.04 + edad * .07),
        vapor,
      );
    }
  }
  final baliza = Offset(pies.dx, cabeza.top - ancho * .04);
  canvas
    ..drawCircle(
      baliza,
      ancho * .2,
      Paint()
        ..color = const Color(
          0xFFE53935,
        ).withValues(alpha: .3 * (1 + math.sin(tiempo * 9)) / 2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ancho * .06),
    )
    ..drawCircle(baliza, ancho * .07, Paint()..color = const Color(0xFFE53935));
}

/// Los brazos del robot: de los hombros a las garras, que agarran al pez.
void _pintarBrazosRobot(
  Canvas canvas,
  Offset pies,
  double alto,
  Offset garra,
  Offset garraAtras,
) {
  const acero = Color(0xFF56636E);
  const oscuro = Color(0xFF2B333A);
  const naranja = Color(0xFFF29F05);
  final ancho = alto * .48;
  final hombros = pies.dy - alto * .74;
  for (final (hombro, mano) in [
    (Offset(pies.dx + ancho * .52, hombros + alto * .02), garraAtras),
    (Offset(pies.dx - ancho * .52, hombros + alto * .02), garra),
  ]) {
    final codo = Offset.lerp(hombro, mano, .5)! + Offset(0, ancho * .18);
    final brazo = Paint()
      ..color = acero
      ..strokeWidth = ancho * .16
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(hombro, codo, brazo)
      ..drawLine(codo, mano, brazo..strokeWidth = ancho * .14)
      ..drawCircle(codo, ancho * .09, Paint()..color = oscuro);
    // La garra: tres dedos.
    final hacia = (mano - codo) / math.max(1, (mano - codo).distance);
    final normal = Offset(-hacia.dy, hacia.dx);
    final dedo = Paint()
      ..color = oscuro
      ..strokeWidth = ancho * .055
      ..strokeCap = StrokeCap.round;
    for (final abre in [-1.0, 0.0, 1.0]) {
      canvas.drawLine(
        mano,
        mano + hacia * ancho * .13 + normal * ancho * .1 * abre,
        dedo,
      );
    }
    canvas
      ..drawCircle(hombro, ancho * .15, Paint()..color = acero)
      ..drawArc(
        Rect.fromCircle(center: hombro, radius: ancho * .15),
        math.pi * 1.1,
        math.pi * .8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ancho * .05
          ..color = naranja,
      );
  }
}

/// El agua que salta del hoyo: gotas que suben y caen. [edad] en segundos
/// desde que salto.
void _pintarGotas(
  Canvas canvas,
  Offset origen,
  double edad,
  double fuerza,
  int semilla,
) {
  if (edad < 0 || edad > 1.2) return;
  final azar = math.Random(semilla);
  final gota = Paint()
    ..color = const Color(
      0xFFBFE3F5,
    ).withValues(alpha: (1.2 - edad).clamp(0.0, 1.0));
  for (var i = 0; i < 18; i++) {
    final angulo = -math.pi / 2 + (azar.nextDouble() - .5) * 2.2;
    final v = fuerza * (.4 + azar.nextDouble() * .7);
    final tam = fuerza * (.006 + azar.nextDouble() * .01);
    canvas.drawCircle(
      origen +
          Offset(
            math.cos(angulo) * v * edad * .5,
            math.sin(angulo) * v * edad + fuerza * 1.1 * edad * edad,
          ),
      tam,
      gota,
    );
  }
}

/// El hielo roto que vuela: trozos que giran y caen. [edad] en segundos
/// desde que se rompio.
void _pintarEsquirlas(
  Canvas canvas,
  Offset origen,
  double edad,
  double fuerza,
  int semilla,
) {
  if (edad < 0 || edad > 1.6) return;
  final azar = math.Random(semilla);
  final alfa = (1.6 - edad).clamp(0.0, 1.0);
  final relleno = Paint()
    ..color = const Color(0xFFE3F2FA).withValues(alpha: alfa);
  final borde = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, fuerza * .002)
    ..color = Colors.white.withValues(alpha: alfa);
  for (var i = 0; i < 26; i++) {
    final angulo = -math.pi / 2 + (azar.nextDouble() - .5) * 2.6;
    final v = fuerza * (.45 + azar.nextDouble() * .75);
    final tam = fuerza * (.01 + azar.nextDouble() * .025);
    final gira = (azar.nextDouble() - .5) * 14;
    final p =
        origen +
        Offset(
          math.cos(angulo) * v * edad * .6,
          math.sin(angulo) * v * edad + fuerza * 1.1 * edad * edad,
        );
    final trozo = Path()
      ..moveTo(-tam, -tam * .4)
      ..lineTo(tam * .2, -tam)
      ..lineTo(tam, tam * .1)
      ..lineTo(-tam * .3, tam * .8)
      ..close();
    canvas
      ..save()
      ..translate(p.dx, p.dy)
      ..rotate(gira * edad)
      ..drawPath(trozo, relleno)
      ..drawPath(trozo, borde)
      ..restore();
  }
}

/// Las cabañas del campamento: donde estan (en anchos de la escena), lo
/// anchas que son y cuanto bajan del horizonte (en altos).
const _cabanas = [(.02, .2, .015), (-.62, .15, .01), (1.15, .13, .008)];

/// El paisaje del lago que no se mueve (las montañas, los pinos, el hielo,
/// las cabañas y el muelle), dibujado una sola vez: en cada cuadro se
/// repite la grabacion, que es mucho mas barato.
ui.Picture _grabarPaisaje(double w, double h) {
  final grabadora = ui.PictureRecorder();
  final canvas = Canvas(grabadora);
  final horizonte = h * .46;
  // Las montañas, en tres capas (las de atras mas claras), con nieve en
  // las puntas y el lado de la sombra (el sol esta a la izquierda).
  for (final (alto, color, paso, semilla) in [
    (.17, const Color(0xFFC3D9E8), .16, 2),
    (.12, const Color(0xFFA7C6DA), .12, 4),
    (.07, const Color(0xFF8DB2C9), .09, 6),
  ]) {
    final r = math.Random(semilla);
    final picos = <Offset>[];
    var x = -w * 3.0;
    var arriba = true;
    while (x <= w * 4) {
      picos.add(
        Offset(
          x,
          horizonte -
              h *
                  alto *
                  (arriba
                      ? .6 + r.nextDouble() * .4
                      : .12 + r.nextDouble() * .25),
        ),
      );
      x += w * paso * (.7 + r.nextDouble() * .6);
      arriba = !arriba;
    }
    final cordillera = Path()..moveTo(-w * 3, horizonte + 1);
    for (final p in picos) {
      cordillera.lineTo(p.dx, p.dy);
    }
    cordillera
      ..lineTo(w * 4, horizonte + 1)
      ..close();
    canvas.drawPath(
      cordillera,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, .3)!, color],
        ).createShader(Rect.fromLTRB(0, horizonte - h * alto, w, horizonte)),
    );
    final sombra = Paint()
      ..color = const Color(0xFF52789A).withValues(alpha: .16);
    final nieve = Paint()..color = Colors.white.withValues(alpha: .9);
    for (var i = 1; i < picos.length - 1; i++) {
      final pico = picos[i];
      final antes = picos[i - 1];
      final despues = picos[i + 1];
      if (pico.dy > antes.dy || pico.dy > despues.dy) continue;
      canvas
        ..drawPath(
          Path()
            ..moveTo(pico.dx, pico.dy)
            ..lineTo(despues.dx, despues.dy)
            ..lineTo(pico.dx + (despues.dx - pico.dx) * .35, horizonte)
            ..close(),
          sombra,
        )
        ..drawPath(
          Path()
            ..moveTo(pico.dx, pico.dy)
            ..lineTo(
              Offset.lerp(pico, despues, .3)!.dx,
              Offset.lerp(pico, despues, .3)!.dy,
            )
            ..lineTo(
              pico.dx + (despues.dx - pico.dx) * .1,
              Offset.lerp(pico, despues, .22)!.dy,
            )
            ..lineTo(
              pico.dx - (pico.dx - antes.dx) * .08,
              Offset.lerp(pico, antes, .26)!.dy,
            )
            ..lineTo(
              Offset.lerp(pico, antes, .3)!.dx,
              Offset.lerp(pico, antes, .3)!.dy,
            )
            ..close(),
          nieve,
        );
    }
  }
  // Los pinos nevados en la orilla de enfrente.
  final azar = math.Random(13);
  for (var i = 0; i < 46; i++) {
    final x = -w * 2.4 + i * w * .11 + azar.nextDouble() * w * .05;
    final alto = h * (.028 + azar.nextDouble() * .026);
    _pintarPino(canvas, Offset(x, horizonte + 3), alto);
  }
  // El lago: nieve blanca con sombras celestes, hasta donde se vea.
  canvas.drawRect(
    Rect.fromLTRB(-w * 4, horizonte, w * 5, h * 6),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF7FBFE), Color(0xFFE3EEF5), Color(0xFFD2E3ED)],
        stops: [0, .4, 1],
      ).createShader(Rect.fromLTRB(0, horizonte, w, h * 1.2)),
  );
  final banda = Paint()..color = const Color(0xFFBCD4E3).withValues(alpha: .45);
  for (final (x, y, ancho) in const [
    (.15, .56, .7),
    (.75, .63, .9),
    (.4, .72, 1.1),
    (-.6, .6, .8),
    (1.5, .68, 1.0),
  ]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * x, h * y),
        width: w * ancho,
        height: h * .025,
      ),
      banda,
    );
  }
  // El campamento: la de adelante y las de al lado, que se ven cuando la
  // camara se aleja.
  for (final (x, ancho, baja) in _cabanas) {
    _pintarCabana(canvas, Offset(w * x, horizonte + h * baja), w * ancho);
  }
  // El muelle de madera donde esta la caña.
  final tabla = Paint();
  for (var i = 0; i < 6; i++) {
    final izquierda = -w * .06 + i * w * .065;
    tabla.color = i.isEven ? const Color(0xFF8A6239) : const Color(0xFF7A5430);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(izquierda, h * .832, w * .062, h * .03),
        const Radius.circular(2),
      ),
      tabla,
    );
    canvas.drawCircle(
      Offset(izquierda + w * .012, h * .837),
      1.2,
      Paint()..color = const Color(0xFF3E2716),
    );
  }
  canvas
    ..drawRect(
      Rect.fromLTWH(-w * .06, h * .858, w * .39, h * .006),
      Paint()..color = const Color(0xFF4E321B),
    )
    // La nieve sobre el borde del muelle.
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * .06, h * .828, w * .39, h * .007),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: .9),
    );
  return grabadora.endRecording();
}

void _pintarPino(Canvas canvas, Offset base, double alto) {
  const verde = Color(0xFF2F5A4E);
  final ancho = alto * .62;
  for (var piso = 0; piso < 3; piso++) {
    final abajo = base.dy - alto * (.08 + piso * .27);
    final mitad = ancho / 2 * (1 - piso * .24);
    final punta = abajo - alto * .42;
    canvas
      ..drawPath(
        Path()
          ..moveTo(base.dx - mitad, abajo)
          ..lineTo(base.dx, punta)
          ..lineTo(base.dx + mitad, abajo)
          ..close(),
        Paint()..color = verde,
      )
      ..drawPath(
        Path()
          ..moveTo(base.dx - mitad * .6, abajo - alto * .08)
          ..lineTo(base.dx, punta)
          ..lineTo(base.dx + mitad * .5, abajo - alto * .1)
          ..quadraticBezierTo(
            base.dx,
            abajo - alto * .18,
            base.dx - mitad * .6,
            abajo - alto * .08,
          )
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
  }
}

void _pintarCabana(Canvas canvas, Offset piso, double ancho) {
  final alto = ancho * .55;
  final pared = Rect.fromLTWH(piso.dx, piso.dy - alto, ancho, alto);
  final chimenea = Offset(pared.right - ancho * .2, pared.top - alto * .5);
  canvas
    ..drawRect(
      Rect.fromLTWH(
        chimenea.dx - ancho * .04,
        chimenea.dy,
        ancho * .08,
        alto * .5,
      ),
      Paint()..color = const Color(0xFF4B3424),
    )
    ..drawRect(
      pared,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7A5232), Color(0xFF5C3B22)],
        ).createShader(pared),
    )
    ..drawRect(
      Rect.fromLTWH(
        pared.left + ancho * .14,
        pared.top + alto * .3,
        ancho * .22,
        alto * .28,
      ),
      Paint()..color = const Color(0xFFFFD27A),
    )
    ..drawRect(
      Rect.fromLTWH(
        pared.left + ancho * .6,
        pared.top + alto * .32,
        ancho * .2,
        alto * .68,
      ),
      Paint()..color = const Color(0xFF3E2716),
    );
  final techo = Path()
    ..moveTo(pared.left - ancho * .08, pared.top + alto * .05)
    ..lineTo(pared.left + ancho * .1, pared.top - alto * .32)
    ..lineTo(pared.right - ancho * .1, pared.top - alto * .32)
    ..lineTo(pared.right + ancho * .08, pared.top + alto * .05)
    ..close();
  canvas.drawPath(techo, Paint()..color = Colors.white);
  // El mastil de la bandera (la bandera flamea: va aparte).
  final mastil = Offset(pared.right + ancho * .3, piso.dy);
  canvas.drawLine(
    mastil,
    mastil - Offset(0, alto * 1.6),
    Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF7E8B93),
  );
}
