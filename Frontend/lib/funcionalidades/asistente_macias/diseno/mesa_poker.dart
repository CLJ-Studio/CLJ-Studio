import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../elementos_compartidos/insignias/insignia_egresado.dart';
import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../logica/evaluador_poker.dart';
import '../logica/mesa_poker.dart';
import 'cartas_blackjack.dart';

/// Los colores de la mesa: los mismos del paño del blackjack, para que el
/// casino se vea como un solo lugar.
abstract final class ColoresPoker {
  static const fondo = Color(0xFF1A1614);
  static const oro = Color(0xFFF2CC5C);
  static const crema = ConfiguracionTema.crema;
  static const cremaApagada = Color(0x99E6E1D5);
  static const rojo = Color(0xFFB3202A);
  static const verde = Color(0xFF2E7D4F);
  static const placa = Color(0xE6141010);
}

/// La sala: oscura, con la luz de una lampara sobre la mesa.
class PintorSalaPoker extends CustomPainter {
  const PintorSalaPoker();

  @override
  void paint(Canvas canvas, Size size) {
    final todo = Offset.zero & size;
    canvas.drawRect(
      todo,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.1),
          radius: 1.05,
          colors: [Color(0xFF3A2A1E), Color(0xFF1E1713), Color(0xFF0E0B09)],
          stops: [0, .55, 1],
        ).createShader(todo),
    );
  }

  @override
  bool shouldRepaint(PintorSalaPoker viejo) => false;
}

/// La mesa ovalada: el riel de madera con su luz, la moldura dorada, el
/// paño y lo impreso en el (la linea de las apuestas y el nombre de la casa).
class PintorMesaPoker extends CustomPainter {
  const PintorMesaPoker();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final riel = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide / 2),
    );

    // La sombra que hace en el piso.
    canvas
      ..drawRRect(
        riel.shift(const Offset(0, 10)),
        Paint()
          ..color = const Color(0x99000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      )
      // La madera: clara arriba, donde pega la luz.
      ..drawRRect(
        riel,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7A5038), Color(0xFF452B1D), Color(0xFF22150E)],
            stops: [0, .5, 1],
          ).createShader(rect),
      )
      ..drawRRect(
        riel.deflate(1.4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
          ).createShader(rect),
      );

    // La moldura dorada entre la madera y el paño.
    final moldura = riel.deflate(10.5);
    canvas.drawRRect(
      moldura,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8C46A), Color(0xFF9C7224), Color(0xFFE8C46A)],
        ).createShader(rect),
    );

    // El paño, con una luz en el centro.
    final pano = riel.deflate(12.5);
    canvas
      ..drawRRect(
        pano,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -.12),
            radius: .95,
            colors: [
              Color(0xFF24A26C),
              Color(0xFF178153),
              Color(0xFF0D5C3B),
              Color(0xFF063522),
            ],
            stops: [0, .38, .76, 1],
          ).createShader(pano.outerRect),
      )
      ..save()
      ..clipRRect(pano);

    // La trama del fieltro: puntitos claros y oscuros, siempre los mismos.
    final azar = math.Random(11);
    final claro = Paint()..color = const Color(0x0AFFFFFF);
    final oscuro = Paint()..color = const Color(0x0D000000);
    final area = pano.outerRect;
    for (var i = 0; i < 1800; i++) {
      final x = area.left + azar.nextDouble() * area.width;
      final y = area.top + azar.nextDouble() * area.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), i.isEven ? claro : oscuro);
    }

    // El borde del paño queda en la sombra del riel.
    canvas
      ..drawRRect(
        pano,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..restore();

    // La linea dorada donde van las apuestas.
    canvas.drawRRect(
      pano.deflate(size.shortestSide * .13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x40F2CC5C),
    );

    // El nombre de la casa, impreso debajo de las cartas de la mesa.
    final logo = _texto(
      'MacIAs',
      math.min(40, size.width * .14),
      const Color(0x1FF2CC5C),
      espacio: 2,
    );
    final debajo = Offset(size.width / 2, size.height / 2 + size.height * .15);
    logo.paint(canvas, debajo - Offset(logo.width / 2, 0));
    final juego = _texto(
      "TEXAS HOLD'EM",
      9,
      const Color(0x2EF2CC5C),
      espacio: 3,
    );
    juego.paint(canvas, debajo + Offset(-juego.width / 2, logo.height + 1));
  }

  static TextPainter _texto(
    String texto,
    double tamano,
    Color color, {
    double espacio = 0,
  }) => TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w900,
        fontSize: tamano,
        letterSpacing: espacio,
        color: color,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  bool shouldRepaint(PintorMesaPoker viejo) => false;
}

/// Una carta del poker ("As"), boca arriba o boca abajo.
class CartaPoker extends StatelessWidget {
  const CartaPoker({
    required this.ancho,
    this.codigo,
    this.apagada = false,
    super.key,
  });

  final double ancho;

  /// Sin codigo se ve el dorso.
  final String? codigo;

  /// La de alguien que se retiro.
  final bool apagada;

  @override
  Widget build(BuildContext context) {
    final codigo = this.codigo;
    final carta = codigo == null ? null : CartasPoker.carta(codigo);
    return Semantics(
      label: codigo == null ? 'Carta tapada' : leer(codigo),
      child: Opacity(
        opacity: apagada ? .35 : 1,
        child: CartaDibujada(ancho: ancho, carta: carta),
      ),
    );
  }

  /// "As de picas", "10 de diamantes".
  static String leer(String codigo) {
    final rango = switch (codigo[0]) {
      'A' => 'As',
      'K' => 'Rey',
      'Q' => 'Reina',
      'J' => 'Jota',
      'T' => '10',
      final otro => otro,
    };
    final palo = switch (codigo[1]) {
      's' => 'picas',
      'h' => 'corazones',
      'd' => 'diamantes',
      _ => 'tréboles',
    };
    return '$rango de $palo';
  }
}

/// Una carta que se da vuelta cuando se conoce: de dorso a cara, girando.
/// La que ya llega conocida se ve de cara, sin girar.
///
/// [resaltada]: es de la mano que gano; sube un poco y brilla. [apagada]:
/// no forma parte, o es de alguien que se retiro.
class CartaVolteable extends StatefulWidget {
  const CartaVolteable({
    required this.ancho,
    this.codigo,
    this.giro = 0,
    this.apagada = false,
    this.resaltada = false,
    super.key,
  });

  final double ancho;
  final String? codigo;
  final double giro;
  final bool apagada;
  final bool resaltada;

  @override
  State<CartaVolteable> createState() => _CartaVolteableState();
}

class _CartaVolteableState extends State<CartaVolteable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vuelta = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
    value: widget.codigo == null ? 0 : 1,
  );

  @override
  void didUpdateWidget(CartaVolteable vieja) {
    super.didUpdateWidget(vieja);
    if (vieja.codigo == null && widget.codigo != null) {
      _vuelta.forward(from: 0);
    } else if (widget.codigo == null) {
      _vuelta.value = 0;
    }
  }

  @override
  void dispose() {
    _vuelta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codigo = widget.codigo;
    final cara = CartaPoker(ancho: widget.ancho, codigo: codigo);
    final dorso = CartaPoker(ancho: widget.ancho);
    return AnimatedBuilder(
      animation: _vuelta,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_vuelta.value);
        final angulo = (1 - t) * math.pi;
        final deCara = codigo != null && angulo <= math.pi / 2;
        Widget carta = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0015)
            ..rotateY(angulo),
          child: deCara
              ? cara
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: dorso,
                ),
        );
        if (widget.resaltada && deCara) {
          carta = DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.ancho * .12),
              boxShadow: const [
                BoxShadow(color: Color(0xCCF2CC5C), blurRadius: 12),
              ],
            ),
            child: carta,
          );
        }
        return AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          offset: Offset(0, widget.resaltada ? -.12 : 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: widget.apagada ? .42 : 1,
            child: Transform.rotate(angle: widget.giro, child: carta),
          ),
        );
      },
    );
  }
}

/// El lugar de una carta de la mesa que todavia no salio.
class HuecoCarta extends StatelessWidget {
  const HuecoCarta({required this.ancho, super.key});

  final double ancho;

  @override
  Widget build(BuildContext context) => Container(
    width: ancho,
    height: ancho * 1.4,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(ancho * .12),
      color: const Color(0x14000000),
      border: Border.all(color: const Color(0x38F2CC5C)),
    ),
  );
}

/// Lo que dice la ultima jugada de alguien, para la etiqueta del asiento.
String? textoAccion(String? accion) => switch (accion) {
  'ciega_chica' || 'ciega_grande' => 'Ciega',
  'pasar' => 'Pasa',
  'igualar' => 'Iguala',
  'subir' => 'Sube',
  'apostar' => 'Apuesta',
  'todo' => 'Todo',
  'retirarse' => 'Se retira',
  _ => null,
};

/// El color de cada jugada: lo que sube la apuesta, dorado; ir con todo,
/// rojo; igualar, verde; lo demas, oscuro.
(Color fondo, Color texto) coloresAccion(String? accion) => switch (accion) {
  'subir' || 'apostar' => (ColoresPoker.oro, const Color(0xFF2B1E05)),
  'todo' => (ColoresPoker.rojo, ColoresPoker.crema),
  'igualar' => (ColoresPoker.verde, ColoresPoker.crema),
  'retirarse' => (const Color(0xCC2A2522), ColoresPoker.cremaApagada),
  _ => (const Color(0xE61B120D), ColoresPoker.crema),
};

/// El reloj del turno alrededor de la foto: se vacia de a poco, y en los
/// ultimos segundos se pone rojo. Se repinta solo, sin redibujar la mesa.
class AnilloTurno extends StatelessWidget {
  const AnilloTurno({
    required this.fraccion,
    required this.diametro,
    super.key,
  });

  final ValueListenable<double> fraccion;
  final double diametro;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(diametro),
      painter: _PintorAnillo(fraccion),
    ),
  );
}

class _PintorAnillo extends CustomPainter {
  _PintorAnillo(this.fraccion) : super(repaint: fraccion);

  final ValueListenable<double> fraccion;

  @override
  void paint(Canvas canvas, Size size) {
    final f = fraccion.value.clamp(0.0, 1.0);
    final centro = size.center(Offset.zero);
    final radio = size.width / 2 - 2;
    final urgente = f < .25;
    final color = urgente ? const Color(0xFFE5484D) : ColoresPoker.oro;
    canvas
      ..drawCircle(
        centro,
        radio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = const Color(0x40F2CC5C),
      )
      ..drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        -math.pi / 2,
        2 * math.pi * f,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..color = color,
      )
      ..drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        -math.pi / 2,
        2 * math.pi * f,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = color.withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
  }

  @override
  bool shouldRepaint(_PintorAnillo viejo) => viejo.fraccion != fraccion;
}

/// Un asiento alrededor de la mesa: la ultima jugada arriba, la foto (con
/// el reloj del turno) y debajo la placa con el nombre y las fichas.
///
/// La foto queda siempre en [GeometriaMesa.centroFoto] de la caja: ahi
/// llegan las fichas que gana y de ahi salen las que apuesta.
class AsientoPokerVista extends StatelessWidget {
  const AsientoPokerVista({
    required this.asiento,
    required this.fichas,
    required this.esYo,
    this.jugador,
    this.turno,
    this.ganancia,
    super.key,
  });

  final AsientoPoker asiento;

  /// Las que se ven: pueden ir atras mientras las fichas viajan.
  final int fichas;
  final bool esYo;

  /// Null: no juega esta mano.
  final JugadorPoker? jugador;

  /// Si es su turno, cuanto le queda (de 1 a 0).
  final ValueListenable<double>? turno;

  /// Lo que cobro en la mano que termino.
  final int? ganancia;

  static const diametro = 50.0;

  @override
  Widget build(BuildContext context) {
    final jugador = this.jugador;
    final retirado = jugador?.retirado ?? false;
    final ganancia = this.ganancia;
    final accion = jugador?.todo ?? false ? 'todo' : jugador?.ultimaAccion;
    final texto = textoAccion(accion);
    final turno = this.turno;
    final etiqueta = ganancia != null
        ? _Etiqueta(
            key: ValueKey('gana$ganancia'),
            texto: '+${fichasPoker(ganancia)}',
            fondo: ColoresPoker.oro,
            color: const Color(0xFF2B1E05),
          )
        : texto == null
        ? null
        : _Etiqueta(
            key: ValueKey('$accion${jugador?.apuestaRonda}'),
            texto: texto,
            fondo: coloresAccion(accion).$1,
            color: coloresAccion(accion).$2,
          );

    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arriba de mi foto van mis cartas: mi etiqueta va al costado.
          SizedBox(height: 18, child: esYo ? null : etiqueta),
          const SizedBox(height: 2),
          SizedBox.square(
            dimension: diametro,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (esYo && etiqueta != null)
                  Positioned(right: diametro + 8, top: 16, child: etiqueta),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: retirado || asiento.afuera ? .45 : 1,
                  child: _Foto(asiento: asiento, ganador: ganancia != null),
                ),
                if (turno != null)
                  Positioned(
                    left: -5,
                    top: -5,
                    child: AnilloTurno(
                      fraccion: turno,
                      diametro: diametro + 10,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _Placa(
            asiento: asiento,
            fichas: fichas,
            esYo: esYo,
            enTurno: turno != null,
          ),
        ],
      ),
    );
  }
}

/// El nombre y las fichas, en una placa oscura; la mia con borde dorado.
class _Placa extends StatelessWidget {
  const _Placa({
    required this.asiento,
    required this.fichas,
    required this.esYo,
    required this.enTurno,
  });

  final AsientoPoker asiento;
  final int fichas;
  final bool esYo;
  final bool enTurno;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    constraints: const BoxConstraints(minWidth: 70, maxWidth: 92),
    padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
    decoration: BoxDecoration(
      color: ColoresPoker.placa,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: enTurno
            ? ColoresPoker.oro
            : esYo
            ? const Color(0x99F2CC5C)
            : const Color(0x33F2CC5C),
        width: enTurno ? 1.4 : 1,
      ),
      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NombreConInsignia(
          esYo ? 'Tú' : asiento.primerNombre,
          egresado: asiento.egresado,
          maxLines: 1,
          estilo: const TextStyle(
            color: ColoresPoker.crema,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            height: 1.15,
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: fichas.toDouble()),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, valor, _) => Text(
            asiento.afuera ? 'Afuera' : fichasPoker(valor.round()),
            style: const TextStyle(
              color: ColoresPoker.oro,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              height: 1.15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
}

String _fichas(int n) {
  final texto = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  return buffer.toString();
}

/// Un numero de fichas con puntos de miles: 12.500.
String fichasPoker(int n) => _fichas(n);

class _Foto extends StatelessWidget {
  const _Foto({required this.asiento, required this.ganador});

  final AsientoPoker asiento;
  final bool ganador;

  @override
  Widget build(BuildContext context) {
    final url = asiento.avatarUrl;
    final inicial = Center(
      child: Text(
        asiento.inicial,
        style: const TextStyle(
          color: Color(0xFF2B1E05),
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      width: AsientoPokerVista.diametro,
      height: AsientoPokerVista.diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColoresPoker.crema,
        border: Border.all(
          color: ganador ? ColoresPoker.oro : const Color(0xFF2E1F17),
          width: ganador ? 3 : 2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x80000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          if (ganador)
            const BoxShadow(
              color: Color(0xB3F2CC5C),
              blurRadius: 18,
              spreadRadius: 2,
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? inicial
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => inicial,
            ),
    );
  }
}

/// Un lugar libre: si estoy mirando, me puedo sentar tocandolo.
class AsientoLibre extends StatelessWidget {
  const AsientoLibre({this.alTocar, super.key});

  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: alTocar != null,
    label: alTocar == null ? 'Lugar libre' : 'Sentarme en este lugar',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: alTocar,
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: AsientoPokerVista.diametro,
              height: AsientoPokerVista.diametro,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x26000000),
                border: Border.all(color: const Color(0x40E6E1D5), width: 1.5),
              ),
              child: Icon(
                alTocar == null ? Icons.event_seat_outlined : Icons.add_rounded,
                color: const Color(0x66E6E1D5),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Libre',
              style: TextStyle(
                color: Color(0x66E6E1D5),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// La etiqueta de la ultima jugada: aparece con un saltito.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.fondo,
    required this.color,
    super.key,
  });

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutBack,
    builder: (context, t, hijo) => Transform.scale(
      scale: .55 + .45 * t,
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: hijo),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          height: 1.25,
        ),
      ),
    ),
  );
}

/// El boton del repartidor.
class BotonDealer extends StatelessWidget {
  const BotonDealer({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [Colors.white, Color(0xFFDCD6CC)],
        stops: [.6, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: const Text(
      'D',
      style: TextStyle(
        color: Color(0xFF1B1A1F),
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
    ),
  );
}

/// Al final, con que gano: en dorado, en medio de la mesa.
class ManoGanadora extends StatelessWidget {
  const ManoGanadora({required this.texto, super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutBack,
    builder: (context, t, hijo) => Transform.scale(
      scale: .7 + .3 * t,
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: hijo),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7DC8A), ColoresPoker.oro],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 10),
          BoxShadow(color: Color(0x66F2CC5C), blurRadius: 16),
        ],
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF2B1E05),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    ),
  );
}

/// "Par de ases": lo que tengo con la mesa, debajo de mis cartas.
String? nombreMano(int? valor) =>
    valor == null ? null : EvaluadorPoker.nombre(valor);

/// Un campo de texto para las hojas oscuras del poker. El del tema de la app
/// es claro, y sobre estas hojas el texto crema no se leia: "Mesa de Juan"
/// quedaba crema sobre crema.
class CampoPoker extends StatelessWidget {
  const CampoPoker({
    required this.controlador,
    required this.etiqueta,
    this.largoMaximo,
    this.alCambiar,
    super.key,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final int? largoMaximo;
  final ValueChanged<String>? alCambiar;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: ancho),
        );
    return TextField(
      controller: controlador,
      maxLength: largoMaximo,
      onChanged: alCambiar,
      cursorColor: ColoresPoker.oro,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        color: ColoresPoker.crema,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(
          color: ColoresPoker.cremaApagada,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: ColoresPoker.oro,
          fontWeight: FontWeight.w800,
        ),
        counterStyle: const TextStyle(color: ColoresPoker.cremaApagada),
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: borde(const Color(0x40F2CC5C)),
        enabledBorder: borde(const Color(0x40F2CC5C)),
        focusedBorder: borde(ColoresPoker.oro, 1.6),
      ),
    );
  }
}

/// Algo para elegir en las hojas del poker (las ciegas, cuanto subir):
/// oscuro, y dorado lo elegido. Los chips del tema salian claros y no
/// pegaban con la mesa.
class OpcionPoker extends StatelessWidget {
  const OpcionPoker({
    required this.texto,
    required this.elegida,
    required this.alTocar,
    this.detalle,
    super.key,
  });

  final String texto;

  /// Debajo, mas chico: "1.000 fichas", "40".
  final String? detalle;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    const oscuro = Color(0xFF2B1E05);
    return Semantics(
      button: true,
      selected: elegida,
      label: detalle == null ? texto : '$texto, $detalle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: alTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: elegida
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF2CC5C), Color(0xFFD9A21B)],
                  )
                : null,
            color: elegida ? null : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: elegida
                  ? const Color(0x00000000)
                  : const Color(0x40F2CC5C),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                style: TextStyle(
                  color: elegida ? oscuro : ColoresPoker.crema,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              if (detalle != null)
                Text(
                  detalle!,
                  style: TextStyle(
                    color: elegida
                        ? const Color(0xB32B1E05)
                        : ColoresPoker.cremaApagada,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
