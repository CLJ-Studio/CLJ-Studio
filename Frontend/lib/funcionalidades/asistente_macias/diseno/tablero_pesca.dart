import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../elementos_compartidos/animaciones/escala_al_presionar.dart';
import '../logica/mesa_pesca.dart';
import 'dibujos_pesca.dart';
import 'fichas_blackjack.dart';

/// Donde se apuesta: los dos hielos (1 a 1), los tres peces del bono y
/// "Todos", que pone la ficha en los tres peces.
class TableroPesca extends StatelessWidget {
  const TableroPesca({
    required this.montos,
    required this.llaves,
    required this.alTocar,
    required this.alTocarTodos,
    this.moneda,
    this.ganadora,
    this.habilitado = true,
    super.key,
  });

  /// Lo que hay apostado en cada casilla.
  final Map<Casilla, int> montos;

  /// Para saber donde esta cada casilla (las fichas vuelan hacia ahi).
  final Map<Casilla, GlobalKey> llaves;
  final ValueChanged<Casilla> alTocar;
  final VoidCallback alTocarTodos;

  /// La moneda de oro de esta ronda: su pez muestra cuanto multiplica.
  final ({Pez pez, int por})? moneda;

  /// Lo que salio: brilla, y lo demas se apaga.
  final Casilla? ganadora;
  final bool habilitado;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 92,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 62,
          child: Column(
            children: [
              for (final hielo in const [
                Casilla.hieloBlanco,
                Casilla.hieloAzul,
              ])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: hielo == Casilla.hieloBlanco ? 4 : 0,
                    ),
                    child: _Hielo(
                      key: llaves[hielo],
                      casilla: hielo,
                      monto: montos[hielo] ?? 0,
                      brillo: ganadora == hielo,
                      apagado: ganadora != null && ganadora != hielo,
                      alTocar: habilitado ? () => alTocar(hielo) : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        for (final pez in Pez.values) ...[
          Expanded(
            child: _Pez(
              key: llaves[pez.casilla],
              pez: pez,
              monto: montos[pez.casilla] ?? 0,
              moneda: moneda?.pez == pez ? moneda!.por : null,
              brillo: ganadora == pez.casilla,
              apagado: ganadora != null && ganadora != pez.casilla,
              alTocar: habilitado ? () => alTocar(pez.casilla) : null,
            ),
          ),
          const SizedBox(width: 5),
        ],
        SizedBox(
          width: 44,
          child: _Todos(alTocar: habilitado ? alTocarTodos : null),
        ),
      ],
    ),
  );
}

/// Una casilla del tablero: se achica al tocarla, brilla si salio y se
/// apaga si no.
class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.etiqueta,
    required this.colores,
    required this.brillo,
    required this.apagado,
    required this.alTocar,
    required this.child,
    this.borde = Colors.white,
  });

  final String etiqueta;
  final List<Color> colores;
  final bool brillo;
  final bool apagado;
  final VoidCallback? alTocar;
  final Widget child;
  final Color borde;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(12);
    return Semantics(
      button: true,
      enabled: alTocar != null,
      label: etiqueta,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: apagado ? .45 : 1,
        child: EscalaAlPresionar(
          escala: .94,
          builder: (context, alResaltar) => AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            decoration: BoxDecoration(
              borderRadius: radio,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colores,
              ),
              border: Border.all(
                color: brillo ? Colors.white : borde.withValues(alpha: .55),
                width: brillo ? 2.4 : 1.2,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
                if (brillo)
                  BoxShadow(
                    color: colores.first.withValues(alpha: .9),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radio,
                onTap: alTocar,
                onHighlightChanged: alResaltar,
                child: ClipRRect(
                  borderRadius: radio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      // El brillo de arriba: la casilla parece de vidrio.
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radio,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .28),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.white.withValues(alpha: .26),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hielo extends StatelessWidget {
  const _Hielo({
    required this.casilla,
    required this.monto,
    required this.brillo,
    required this.apagado,
    required this.alTocar,
    super.key,
  });

  final Casilla casilla;
  final int monto;
  final bool brillo;
  final bool apagado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final blanco = casilla == Casilla.hieloBlanco;
    final tinta = blanco ? ColoresPesca.hieloAzulOscuro : Colors.white;
    return _Casilla(
      etiqueta:
          '${casilla.nombre}, paga 1 a 1'
          '${monto > 0 ? ', tienes ${conMiles(monto)}' : ''}',
      colores: blanco
          ? const [Colors.white, ColoresPesca.hieloSombra]
          : const [ColoresPesca.hieloAzul, ColoresPesca.hieloAzulOscuro],
      borde: blanco ? ColoresPesca.hieloAzul : Colors.white,
      brillo: brillo,
      apagado: apagado,
      alTocar: alTocar,
      // El copo y lo que paga arriba; lo apostado, debajo.
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _PintorBloque(blanco: blanco)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 14,
                    child: CustomPaint(painter: _PintorCopo(tinta)),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '1:1',
                    style: TextStyle(
                      color: tinta,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              if (monto > 0) ...[
                const SizedBox(height: 2),
                _Monto(monto: monto),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Pez extends StatelessWidget {
  const _Pez({
    required this.pez,
    required this.monto,
    required this.brillo,
    required this.apagado,
    required this.alTocar,
    this.moneda,
    super.key,
  });

  final Pez pez;
  final int monto;
  final int? moneda;
  final bool brillo;
  final bool apagado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final (claro, oscuro) = ColoresPesca.deCasilla(pez.casilla);
    return _Casilla(
      etiqueta:
          '${pez.nombre}, bono de pesca hasta ${textoPor(pez.maximo)}'
          '${monto > 0 ? ', tienes ${conMiles(monto)}' : ''}',
      colores: [claro, oscuro],
      brillo: brillo,
      apagado: apagado,
      alTocar: alTocar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _Destellos(fase: pez.index * .31)),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 6),
                PezVivo(pez: pez, ancho: 50, fase: pez.index * .27),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      pez.nombre.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        height: 1,
                        letterSpacing: .3,
                        shadows: [
                          Shadow(color: Color(0x88000000), blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.black.withValues(alpha: .22),
                  child: Text(
                    'hasta ${textoPor(pez.maximo)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (monto > 0)
            Positioned(top: 3, left: 3, child: _Monto(monto: monto)),
          // La moneda va encima: es lo que mas importa en esa ronda.
          if (moneda != null)
            Positioned(top: 3, right: 3, child: _Insignia(texto: 'x$moneda')),
        ],
      ),
    );
  }
}

class _Todos extends StatelessWidget {
  const _Todos({required this.alTocar});

  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) => _Casilla(
    etiqueta: 'Todos los peces: la ficha en los tres',
    colores: const [Color(0xFF9DB7C6), Color(0xFF5E7E91)],
    brillo: false,
    apagado: false,
    alTocar: alTocar,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final pez in Pez.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: PezVivo(pez: pez, ancho: 24, fase: pez.index * .33),
          ),
        const SizedBox(height: 3),
        const Text(
          'TODOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 9.5,
            height: 1,
          ),
        ),
      ],
    ),
  );
}

/// Lo apostado en una casilla: una ficha y el monto.
class _Monto extends StatelessWidget {
  const _Monto({required this.monto});

  final int monto;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(monto),
    tween: Tween(begin: .7, end: 1),
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutBack,
    builder: (context, escala, hijo) =>
        Transform.scale(scale: escala, child: hijo),
    child: Container(
      padding: const EdgeInsets.fromLTRB(2, 2, 6, 2),
      decoration: BoxDecoration(
        color: const Color(0xE6111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x99D9A21B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FichaDibujada(valor: _fichaDe(monto), diametro: 14),
          const SizedBox(width: 3),
          // Un monto largo (un pago de 12.500) se achica en vez de salirse
          // de la casilla.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                conMiles(monto),
                style: const TextStyle(
                  color: Color(0xFFF7E7B5),
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  static int _fichaDe(int monto) {
    for (final valor in const [1000, 500, 100, 50]) {
      if (monto >= valor) return valor;
    }
    return 10;
  }
}

/// El multiplicador de la moneda sobre una casilla.
class _Insignia extends StatelessWidget {
  const _Insignia({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 420),
    curve: Curves.elasticOut,
    builder: (context, t, hijo) => Transform.scale(scale: t, child: hijo),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .7)),
        boxShadow: const [BoxShadow(color: Color(0x99F5C542), blurRadius: 8)],
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: ColoresPesca.texto,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          height: 1,
        ),
      ),
    ),
  );
}

/// El bloque de las casillas de hielo: facetas mas claras y oscuras y
/// rayitas de escarcha.
class _PintorBloque extends CustomPainter {
  const _PintorBloque({required this.blanco});

  final bool blanco;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, h * .55)
          ..lineTo(w * .55, 0)
          ..lineTo(w, 0)
          ..lineTo(w, h * .15)
          ..lineTo(w * .2, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: blanco ? .35 : .12),
      )
      ..drawPath(
        Path()
          ..moveTo(w * .65, h)
          ..lineTo(w, h * .45)
          ..lineTo(w, h)
          ..close(),
        Paint()
          ..color = (blanco ? const Color(0xFF7FA6BC) : Colors.black)
              .withValues(alpha: .12),
      );
    final escarcha = Paint()
      ..strokeWidth = .8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: blanco ? .9 : .45);
    for (final (x, y, l) in const [
      (.12, .2, .1),
      (.8, .3, .08),
      (.25, .8, .12),
      (.7, .78, .07),
      (.5, .15, .06),
    ]) {
      canvas.drawLine(
        Offset(w * x, h * y),
        Offset(w * (x + l), h * (y - l * .6)),
        escarcha,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorBloque viejo) => viejo.blanco != blanco;
}

/// Lo que se mueve en la casilla de un pez: cada tanto un brillo la cruza
/// en diagonal, y del pez suben burbujas.
class _Destellos extends StatefulWidget {
  const _Destellos({required this.fase});

  final double fase;

  @override
  State<_Destellos> createState() => _DestellosState();
}

class _DestellosState extends State<_Destellos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _vida.stop();
    } else if (!_vida.isAnimating) {
      _vida.repeat();
    }
  }

  @override
  void dispose() {
    _vida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _PintorDestellos(_vida, widget.fase)),
    ),
  );
}

class _PintorDestellos extends CustomPainter {
  _PintorDestellos(this.vida, this.fase) : super(repaint: vida);

  final Animation<double> vida;
  final double fase;

  @override
  void paint(Canvas canvas, Size size) {
    final t = (vida.value + fase) % 1;
    final w = size.width;
    final h = size.height;
    // El brillo: una franja que cruza en diagonal.
    if (t < .22) {
      final x = -w * .5 + (w * 2) * (t / .22);
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + w * .22, 0)
          ..lineTo(x - w * .18, h)
          ..lineTo(x - w * .4, h)
          ..close(),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .32),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x - w * .4, 0, w * .62, h)),
      );
    }
    // Las burbujas, que salen de la boca del pez y suben.
    final burbuja = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final edad = (t * 2 + i / 3) % 1;
      burbuja.color = Colors.white.withValues(alpha: .55 * (1 - edad));
      canvas.drawCircle(
        Offset(w * .74 + math.sin(edad * 9 + i) * 3, h * .32 - edad * h * .3),
        1.5 + edad * 2,
        burbuja,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDestellos viejo) => viejo.fase != fase;
}

class _PintorCopo extends CustomPainter {
  const _PintorCopo(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarCopo(canvas, size.center(Offset.zero), size.width * .42, color);

  @override
  bool shouldRepaint(_PintorCopo viejo) => viejo.color != color;
}
