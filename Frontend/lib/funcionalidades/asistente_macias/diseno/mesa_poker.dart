import 'dart:math' as math;

import 'package:flutter/material.dart';

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
}

/// El paño ovalado, con su riel de madera.
class PintorMesaPoker extends CustomPainter {
  const PintorMesaPoker();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radio = Radius.circular(size.shortestSide / 2);
    final riel = RRect.fromRectAndRadius(rect, radio);
    canvas
      ..drawRRect(
        riel.shift(const Offset(0, 6)),
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )
      ..drawRRect(
        riel,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A3D2E), Color(0xFF2E1F17), Color(0xFF1B120D)],
          ).createShader(rect),
      )
      ..drawRRect(
        riel.deflate(1.2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0x40FFFFFF),
      );

    final pano = riel.deflate(13);
    canvas
      ..drawRRect(
        pano,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -.2),
            radius: .9,
            colors: [
              Color(0xFF1F9461),
              Color(0xFF137449),
              Color(0xFF0B5235),
              Color(0xFF063623),
            ],
            stops: [0, .4, .78, 1],
          ).createShader(pano.outerRect),
      )
      ..save()
      ..clipRRect(pano);

    // La trama del fieltro: puntitos claros y oscuros, siempre los mismos.
    final azar = math.Random(11);
    final claro = Paint()..color = const Color(0x0AFFFFFF);
    final oscuro = Paint()..color = const Color(0x0D000000);
    final area = pano.outerRect;
    for (var i = 0; i < 1600; i++) {
      final x = area.left + azar.nextDouble() * area.width;
      final y = area.top + azar.nextDouble() * area.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), i.isEven ? claro : oscuro);
    }
    canvas.restore();

    // La linea dorada donde van las apuestas.
    canvas.drawRRect(
      pano.deflate(size.shortestSide * .13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x40F2CC5C),
    );
  }

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
      label: codigo == null ? 'Carta tapada' : _leer(codigo),
      child: Opacity(
        opacity: apagada ? .35 : 1,
        child: CartaDibujada(ancho: ancho, carta: carta),
      ),
    );
  }

  static String _leer(String codigo) {
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

/// Las cinco de la mesa: las que salieron y el lugar de las que faltan.
class CartasComunitarias extends StatelessWidget {
  const CartasComunitarias({
    required this.cartas,
    required this.ancho,
    super.key,
  });

  final List<String> cartas;
  final double ancho;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 5; i++)
        Padding(
          padding: EdgeInsets.only(right: i == 4 ? 0 : ancho * .1),
          child: i < cartas.length
              ? TweenAnimationBuilder<double>(
                  key: ValueKey(cartas[i]),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (context, t, hijo) => Transform.scale(
                    scale: .6 + .4 * t,
                    child: Opacity(opacity: t.clamp(0, 1), child: hijo),
                  ),
                  child: CartaPoker(ancho: ancho, codigo: cartas[i]),
                )
              : Container(
                  width: ancho,
                  height: ancho * 1.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ancho * .12),
                    border: Border.all(color: const Color(0x33F2CC5C)),
                  ),
                ),
        ),
    ],
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

/// Un asiento alrededor de la mesa: la foto, el nombre, las fichas, la
/// ultima jugada, el boton del repartidor y el reloj del turno.
class AsientoPokerVista extends StatelessWidget {
  const AsientoPokerVista({
    required this.asiento,
    required this.jugador,
    required this.esBoton,
    required this.esTurno,
    required this.fraccionTurno,
    required this.esYo,
    required this.mostrarCartas,
    this.ganancia,
    super.key,
  });

  /// Null: el asiento esta libre.
  final AsientoPoker? asiento;

  /// Null: no juega esta mano.
  final JugadorPoker? jugador;
  final bool esBoton;
  final bool esTurno;

  /// Cuanto le queda del turno, de 1 a 0.
  final double fraccionTurno;
  final bool esYo;

  /// Mostrar sus cartas tapadas (o las vistas, al final).
  final bool mostrarCartas;

  /// Lo que cobro en la mano que termino.
  final int? ganancia;

  static const diametro = 50.0;

  @override
  Widget build(BuildContext context) {
    final asiento = this.asiento;
    if (asiento == null) {
      return const _AsientoLibre();
    }
    final jugador = this.jugador;
    final retirado = jugador?.retirado ?? false;
    final accion = textoAccion(jugador?.ultimaAccion);
    final vistas = jugador?.cartasVistas;
    final valor = jugador?.valor;
    final ganancia = this.ganancia;

    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 18,
            child: accion == null
                ? null
                : _Etiqueta(texto: accion, fuerte: jugador?.todo ?? false),
          ),
          const SizedBox(height: 2),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (esTurno)
                SizedBox(
                  width: diametro + 8,
                  height: diametro + 8,
                  child: CircularProgressIndicator(
                    value: fraccionTurno,
                    strokeWidth: 3.2,
                    color: fraccionTurno < .25
                        ? const Color(0xFFE5484D)
                        : ColoresPoker.oro,
                    backgroundColor: const Color(0x33F2CC5C),
                  ),
                ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: retirado || asiento.afuera ? .45 : 1,
                child: _Foto(asiento: asiento, ganador: ganancia != null),
              ),
              if (esBoton)
                const Positioned(right: -4, bottom: -2, child: _BotonDealer()),
              if (mostrarCartas && jugador != null && !retirado)
                Positioned(
                  left: -16,
                  bottom: -4,
                  child: _DosCartas(cartas: vistas),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            esYo ? 'Tú' : asiento.primerNombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColoresPoker.crema,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          Text(
            asiento.afuera ? 'Afuera' : _fichas(asiento.fichas),
            style: const TextStyle(
              color: ColoresPoker.oro,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          if (ganancia != null)
            Text(
              '+${_fichas(ganancia)}',
              style: const TextStyle(
                color: ColoresPoker.oro,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            )
          else if (valor != null && vistas != null)
            Text(
              EvaluadorPoker.nombre(valor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ColoresPoker.cremaApagada,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
        ],
      ),
    );
  }
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
    return Container(
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
          if (ganador)
            const BoxShadow(color: Color(0x99F2CC5C), blurRadius: 14),
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

class _AsientoLibre extends StatelessWidget {
  const _AsientoLibre();

  @override
  Widget build(BuildContext context) => SizedBox(
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
            border: Border.all(color: const Color(0x40E6E1D5), width: 1.5),
          ),
          child: const Icon(
            Icons.event_seat_outlined,
            color: Color(0x55E6E1D5),
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
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.fuerte});

  final String texto;
  final bool fuerte;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
    decoration: BoxDecoration(
      color: fuerte ? const Color(0xFFB3202A) : const Color(0xCC1B120D),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x40F2CC5C)),
    ),
    child: Text(
      texto,
      style: const TextStyle(
        color: ColoresPoker.crema,
        fontWeight: FontWeight.w800,
        fontSize: 10.5,
      ),
    ),
  );
}

class _BotonDealer extends StatelessWidget {
  const _BotonDealer();

  @override
  Widget build(BuildContext context) => Container(
    width: 19,
    height: 19,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
    ),
    child: const Text(
      'D',
      style: TextStyle(
        color: Color(0xFF1B1A1F),
        fontWeight: FontWeight.w900,
        fontSize: 10.5,
      ),
    ),
  );
}

/// Las dos cartas de alguien: tapadas, o vistas al final.
class _DosCartas extends StatelessWidget {
  const _DosCartas({this.cartas});

  final List<String>? cartas;

  @override
  Widget build(BuildContext context) {
    final cartas = this.cartas;
    final ancho = cartas == null ? 17.0 : 22.0;
    return SizedBox(
      width: ancho * 1.7,
      height: ancho * 1.4,
      child: Stack(
        children: [
          Transform.rotate(
            angle: -.12,
            child: CartaPoker(ancho: ancho, codigo: cartas?.first),
          ),
          Positioned(
            left: ancho * .7,
            child: Transform.rotate(
              angle: .1,
              child: CartaPoker(ancho: ancho, codigo: cartas?.last),
            ),
          ),
        ],
      ),
    );
  }
}

/// La apuesta de alguien en esta ronda, delante de su asiento.
class ApuestaEnMesa extends StatelessWidget {
  const ApuestaEnMesa({required this.monto, super.key});

  final int monto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFB3202A),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        _fichas(monto),
        style: const TextStyle(
          color: ColoresPoker.crema,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 3)],
        ),
      ),
    ],
  );
}
