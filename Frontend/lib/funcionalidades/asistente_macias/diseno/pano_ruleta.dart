import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logica/mesa_ruleta.dart';
import 'fichas_blackjack.dart';
import 'rueda_ruleta.dart';

/// Donde va cada cosa en el paño de la ruleta, de pie para el telefono: el
/// cero arriba, los numeros en 12 filas de 3, las docenas a la izquierda,
/// las apuestas de 1 a 1 a la derecha y las columnas abajo.
///
/// Tambien sabe que apuesta hay bajo un dedo: en el centro de un numero, un
/// pleno; sobre la linea entre dos, un caballo; en una esquina, un cuadro;
/// en el borde de afuera, una calle o una linea; y en la linea del cero, el
/// cero con sus vecinos.
class GeometriaPano {
  GeometriaPano(this.area) {
    const margen = 4.0;
    final ancho = area.width - 2 * margen;
    anchoDocenas = (ancho * .115).clamp(30.0, 46.0);
    anchoExteriores = (ancho * .17).clamp(50.0, 74.0);
    ancho3 = ancho - anchoDocenas - anchoExteriores;
    final altoLibre = area.height - 2 * margen;
    // 12 filas, el cero (1,2 filas) y las columnas (1 fila).
    alto = math.min(altoLibre / 14.2, 46.0);
    final arriba = area.top + margen + (altoLibre - 14.2 * alto) / 2;
    final izquierda = area.left + margen;
    numeros = Rect.fromLTWH(
      izquierda + anchoDocenas,
      arriba + 1.2 * alto,
      ancho3,
      12 * alto,
    );
    cero = Rect.fromLTWH(numeros.left, arriba, ancho3, 1.2 * alto);
    columnas = Rect.fromLTWH(numeros.left, numeros.bottom, ancho3, alto);
    docenas = Rect.fromLTWH(
      izquierda,
      numeros.top,
      anchoDocenas,
      numeros.height,
    );
    exteriores = Rect.fromLTWH(
      numeros.right,
      numeros.top,
      anchoExteriores,
      numeros.height,
    );
    fondo = Rect.fromLTRB(
      izquierda,
      arriba,
      exteriores.right,
      columnas.bottom,
    ).inflate(margen - 1);
  }

  final Rect area;
  late final double anchoDocenas;
  late final double anchoExteriores;
  late final double ancho3;

  /// El alto de una fila.
  late final double alto;
  late final Rect numeros;
  late final Rect cero;
  late final Rect columnas;
  late final Rect docenas;
  late final Rect exteriores;
  late final Rect fondo;

  /// El ancho de una columna de numeros.
  double get ancho => ancho3 / 3;

  /// Las apuestas de 1 a 1, de arriba hacia abajo.
  static final exterioresEnOrden = [
    Apuesta.falta(),
    Apuesta.par(),
    Apuesta.rojo(),
    Apuesta.negro(),
    Apuesta.impar(),
    Apuesta.pasa(),
  ];

  Rect celda(int numero) {
    if (numero == 0) return cero;
    final fila = (numero - 1) ~/ 3;
    final columna = (numero - 1) % 3;
    return Rect.fromLTWH(
      numeros.left + columna * ancho,
      numeros.top + fila * alto,
      ancho,
      alto,
    );
  }

  Rect cajaDocena(int docena) => Rect.fromLTWH(
    docenas.left,
    docenas.top + docena * 4 * alto,
    docenas.width,
    4 * alto,
  );

  Rect cajaColumna(int columna) => Rect.fromLTWH(
    columnas.left + columna * ancho,
    columnas.top,
    ancho,
    columnas.height,
  );

  Rect cajaExterior(int k) => Rect.fromLTWH(
    exteriores.left,
    exteriores.top + k * 2 * alto,
    exteriores.width,
    2 * alto,
  );

  /// Donde va la ficha de cada apuesta.
  Offset lugar(Apuesta apuesta) {
    final n = apuesta.numeros;
    double x(double columnas) => numeros.left + columnas * ancho;
    double y(double filas) => numeros.top + filas * alto;
    int fila(int numero) => (numero - 1) ~/ 3;
    int columna(int numero) => (numero - 1) % 3;
    return switch (apuesta.tipo) {
      TipoApuesta.pleno => celda(n.single).center,
      TipoApuesta.caballo when n.first == 0 => Offset(
        x(columna(n[1]) + .5),
        y(0),
      ),
      TipoApuesta.caballo => Offset.lerp(
        celda(n[0]).center,
        celda(n[1]).center,
        .5,
      )!,
      TipoApuesta.calle => Offset(x(0), y(fila(n.first) + .5)),
      TipoApuesta.trio => Offset(x(n.contains(1) ? 1 : 2), y(0)),
      TipoApuesta.cuadro => Offset(
        x(columna(n.first) + 1.0),
        y(fila(n.first) + 1.0),
      ),
      TipoApuesta.primerosCuatro => Offset(x(0), y(0)),
      TipoApuesta.linea => Offset(x(0), y(fila(n.first) + 1.0)),
      TipoApuesta.docena => cajaDocena((n.first - 1) ~/ 12).center,
      TipoApuesta.columna => cajaColumna(n.first - 1).center,
      _ => cajaExterior(exterioresEnOrden.indexOf(apuesta)).center,
    };
  }

  /// La apuesta que hay bajo [p], o null si no hay ninguna.
  Apuesta? apuestaEn(Offset p) {
    // Cuanto se acepta de cada lado de una linea: lo justo para un dedo.
    final cercaX = math.min(ancho * .2, 14.0);
    final cercaY = math.min(alto * .27, 10.0);
    final zona = Rect.fromLTRB(
      numeros.left - cercaX,
      numeros.top - cercaY,
      numeros.right + cercaX,
      numeros.bottom,
    );
    if (zona.contains(p)) {
      final x = p.dx - numeros.left;
      final y = p.dy - numeros.top;
      final lineaV = (x / ancho).round().clamp(0, 3);
      final lineaH = (y / alto).round().clamp(0, 12);
      final enV = (x - lineaV * ancho).abs() <= cercaX;
      final enH = (y - lineaH * alto).abs() <= cercaY && lineaH < 12;
      final columna = (x / ancho).floor().clamp(0, 2);
      final fila = (y / alto).floor().clamp(0, 11);
      final borde = lineaV == 0 || lineaV == 3;
      if (enV && enH) {
        if (lineaH == 0) {
          return borde
              ? Apuesta.primerosCuatro()
              : Apuesta.trio(conElUno: lineaV == 1);
        }
        if (borde) return Apuesta.linea(lineaH - 1);
        return Apuesta.cuadro(3 * lineaH - 3 + lineaV);
      }
      if (enV) {
        if (borde) return Apuesta.calle(fila);
        return Apuesta.caballo(3 * fila + lineaV, 3 * fila + lineaV + 1);
      }
      if (enH) {
        if (lineaH == 0) return Apuesta.caballo(0, columna + 1);
        return Apuesta.caballo(
          3 * (lineaH - 1) + columna + 1,
          3 * lineaH + columna + 1,
        );
      }
      if (x >= 0 && x <= numeros.width && y >= 0) {
        return Apuesta.pleno(3 * fila + columna + 1);
      }
    }
    if (cero.contains(p)) return Apuesta.pleno(0);
    if (docenas.contains(p)) {
      return Apuesta.docena(
        ((p.dy - numeros.top) / (4 * alto)).floor().clamp(0, 2),
      );
    }
    if (exteriores.contains(p)) {
      return exterioresEnOrden[((p.dy - numeros.top) / (2 * alto))
          .floor()
          .clamp(0, 5)];
    }
    if (columnas.contains(p)) {
      return Apuesta.columna(
        ((p.dx - numeros.left) / ancho).floor().clamp(0, 2),
      );
    }
    return null;
  }
}

/// El paño: el fieltro verde, los numeros en sus colores y las cajas de
/// afuera. Se pinta una vez; las fichas y las marcas van encima.
class PintorPano extends CustomPainter {
  PintorPano(this.g);

  final GeometriaPano g;

  static const _linea = Color(0xFFE9DDB4);
  static const _texto = Color(0xFFF7EEDC);

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = RRect.fromRectAndRadius(g.fondo, const Radius.circular(14));
    canvas
      ..drawRRect(
        fondo.shift(const Offset(0, 4)),
        Paint()
          ..color = const Color(0x88000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawRRect(
        fondo,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -.2),
            radius: 1.1,
            colors: [Color(0xFF13804A), Color(0xFF0B5A33), Color(0xFF07401F)],
            stops: [0, .6, 1],
          ).createShader(g.fondo),
      )
      ..drawRRect(
        fondo.deflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = ColoresRuleta.oro.withValues(alpha: .7),
      );
    final lapiz = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _linea.withValues(alpha: .75);
    final fuente = (g.alto * .5).clamp(10.0, 18.0);

    // Los numeros: cada uno en su color, con el fieltro entre medio.
    for (var n = 1; n <= 36; n++) {
      final caja = g.celda(n);
      final ficha = RRect.fromRectAndRadius(
        caja.deflate(math.min(2.6, g.alto * .08)),
        Radius.circular(g.alto * .16),
      );
      final color = ColoresRuleta.de(n);
      canvas.drawRRect(
        ficha,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.white, .1)!,
              Color.lerp(color, Colors.black, .2)!,
            ],
          ).createShader(caja),
      );
      _escribir(canvas, '$n', caja.center, fuente, _texto);
    }
    // El cero, con su techo en arco.
    final cero = g.cero.deflate(2.6);
    final techo = Path()
      ..moveTo(cero.left, cero.bottom)
      ..lineTo(cero.left, cero.top + cero.height * .45)
      ..quadraticBezierTo(cero.left, cero.top, cero.center.dx, cero.top)
      ..quadraticBezierTo(
        cero.right,
        cero.top,
        cero.right,
        cero.top + cero.height * .45,
      )
      ..lineTo(cero.right, cero.bottom)
      ..close();
    canvas.drawPath(
      techo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(ColoresRuleta.verde, Colors.white, .15)!,
            ColoresRuleta.verde,
          ],
        ).createShader(cero),
    );
    _escribir(
      canvas,
      '0',
      g.cero.center + const Offset(0, 2),
      fuente * 1.1,
      _texto,
    );

    // Las lineas del paño.
    canvas.drawRect(g.numeros, lapiz);
    for (var c = 1; c < 3; c++) {
      final x = g.numeros.left + c * g.ancho;
      canvas.drawLine(
        Offset(x, g.numeros.top),
        Offset(x, g.numeros.bottom),
        lapiz,
      );
    }
    for (var f = 1; f < 12; f++) {
      final y = g.numeros.top + f * g.alto;
      canvas.drawLine(
        Offset(g.numeros.left, y),
        Offset(g.numeros.right, y),
        lapiz,
      );
    }
    // Las docenas, escritas de costado.
    for (var d = 0; d < 3; d++) {
      final caja = g.cajaDocena(d);
      canvas.drawRect(caja, lapiz);
      canvas
        ..save()
        ..translate(caja.center.dx, caja.center.dy)
        ..rotate(-math.pi / 2);
      _escribir(
        canvas,
        '${d + 1}ª DOCENA',
        Offset.zero,
        (g.anchoDocenas * .36).clamp(9.0, 13.0),
        _texto,
        espaciado: 1.2,
      );
      canvas.restore();
    }
    // Las de 1 a 1.
    final chica = (g.anchoExteriores * .2).clamp(10.0, 14.0);
    for (final (k, apuesta) in GeometriaPano.exterioresEnOrden.indexed) {
      final caja = g.cajaExterior(k);
      canvas.drawRect(caja, lapiz);
      switch (apuesta.tipo) {
        case TipoApuesta.rojo || TipoApuesta.negro:
          _rombo(
            canvas,
            caja.center,
            math.min(caja.width * .62, caja.height * .5),
            apuesta.tipo == TipoApuesta.rojo
                ? ColoresRuleta.rojo
                : ColoresRuleta.negro,
          );
        default:
          _escribir(
            canvas,
            switch (apuesta.tipo) {
              TipoApuesta.falta => '1-18',
              TipoApuesta.par => 'PAR',
              TipoApuesta.impar => 'IMPAR',
              _ => '19-36',
            },
            caja.center,
            chica,
            _texto,
          );
      }
    }
    // Las columnas.
    for (var c = 0; c < 3; c++) {
      final caja = g.cajaColumna(c);
      canvas.drawRect(caja, lapiz);
      _escribir(canvas, '2 a 1', caja.center, chica, _texto);
    }
  }

  static void _rombo(Canvas canvas, Offset centro, double tamano, Color color) {
    final rombo = Path()
      ..moveTo(centro.dx, centro.dy - tamano / 2)
      ..lineTo(centro.dx + tamano * .62, centro.dy)
      ..lineTo(centro.dx, centro.dy + tamano / 2)
      ..lineTo(centro.dx - tamano * .62, centro.dy)
      ..close();
    canvas
      ..drawPath(rombo, Paint()..color = color)
      ..drawPath(
        rombo,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _linea.withValues(alpha: .85),
      );
  }

  static void _escribir(
    Canvas canvas,
    String texto,
    Offset centro,
    double tamano,
    Color color, {
    double espaciado = 0,
  }) {
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: tamano,
          height: 1,
          letterSpacing: espaciado,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pintor.paint(canvas, centro - Offset(pintor.width / 2, pintor.height / 2));
  }

  @override
  bool shouldRepaint(PintorPano viejo) => viejo.g.area != g.area;
}

/// Lo que se marca sobre el paño: los numeros que cubre la apuesta que se
/// esta por hacer, y el numero que salio (con su marcador).
class PintorMarcasPano extends CustomPainter {
  PintorMarcasPano({
    required this.g,
    this.presionada,
    this.ganador,
    this.latido,
  }) : super(repaint: latido);

  final GeometriaPano g;
  final Apuesta? presionada;
  final int? ganador;
  final Animation<double>? latido;

  @override
  void paint(Canvas canvas, Size size) {
    final apuesta = presionada;
    if (apuesta != null) {
      final luz = Paint()
        ..color = ColoresRuleta.oroClaro.withValues(alpha: .38);
      if (apuesta.tipo.exterior) {
        final caja = switch (apuesta.tipo) {
          TipoApuesta.docena => g.cajaDocena((apuesta.numeros.first - 1) ~/ 12),
          TipoApuesta.columna => g.cajaColumna(apuesta.numeros.first - 1),
          _ => g.cajaExterior(GeometriaPano.exterioresEnOrden.indexOf(apuesta)),
        };
        canvas.drawRect(caja, luz);
      }
      for (final n in apuesta.numeros) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            g.celda(n).deflate(1),
            const Radius.circular(5),
          ),
          luz,
        );
      }
      final lugar = g.lugar(apuesta);
      canvas
        ..drawCircle(
          lugar,
          13,
          Paint()
            ..color = ColoresRuleta.oroClaro.withValues(alpha: .35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        )
        ..drawCircle(
          lugar,
          10,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = ColoresRuleta.oroClaro,
        );
    }
    final numero = ganador;
    if (numero != null) {
      final caja = g.celda(numero);
      final t = latido?.value ?? 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(caja.inflate(2 * t), const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ColoresRuleta.oroClaro.withValues(alpha: .55 + .45 * t),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(caja, const Radius.circular(6)),
        Paint()
          ..color = ColoresRuleta.oroClaro.withValues(alpha: .12 + .14 * t)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      _marcador(canvas, Offset(caja.right - 9, caja.top + 9), g.alto);
    }
  }

  /// El marcador de cristal que el crupier pone sobre el numero ganador.
  static void _marcador(Canvas canvas, Offset centro, double alto) {
    final r = (alto * .26).clamp(6.0, 10.0);
    canvas
      ..drawCircle(
        centro + Offset(1.5, r * .8),
        r,
        Paint()
          ..color = const Color(0x77000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawCircle(
        centro,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.4),
            colors: [Color(0xFFFFFFFF), Color(0xFFE8C46A), Color(0xFF8A6414)],
          ).createShader(Rect.fromCircle(center: centro, radius: r)),
      )
      ..drawCircle(centro, r * .45, Paint()..color = const Color(0xCCFFFFFF));
  }

  @override
  bool shouldRepaint(PintorMarcasPano viejo) =>
      viejo.presionada != presionada ||
      viejo.ganador != ganador ||
      viejo.g.area != g.area;
}

/// Las fichas sobre el paño: una pila por lugar, con lo apostado escrito.
class PintorFichasPano extends CustomPainter {
  PintorFichasPano({required this.g, required this.apuestas});

  final GeometriaPano g;
  final Map<Apuesta, int> apuestas;

  double get radio => (math.min(g.ancho, g.alto) * .36).clamp(9.0, 15.0);

  @override
  void paint(Canvas canvas, Size size) {
    for (final MapEntry(key: apuesta, value: monto) in apuestas.entries) {
      if (monto <= 0) continue;
      pintarApuesta(canvas, g.lugar(apuesta), radio, monto);
    }
  }

  /// Una pila de fichas con su monto: la ficha de arriba es la mas grande
  /// que entra en el monto, y si hay mas de una se ve el canto de la de
  /// abajo.
  static void pintarApuesta(
    Canvas canvas,
    Offset centro,
    double radio,
    int monto,
  ) {
    final valor = MesaRuleta.apuestaMinima <= monto
        ? [
            1000,
            500,
            100,
            50,
            10,
          ].firstWhere((v) => v <= monto, orElse: () => 10)
        : 10;
    // Cuanto mas hay, mas alta la pila: un all in se tiene que ver.
    final alto = monto <= valor
        ? 1
        : monto < 3 * valor
        ? 2
        : monto < 10 * valor
        ? 3
        : 4;
    for (var i = alto - 1; i >= 1; i--) {
      pintarFicha(
        canvas,
        centro + Offset(0, radio * .22 * i),
        radio,
        valor,
        numero: false,
      );
    }
    pintarFicha(canvas, centro, radio, valor, numero: false);
    final texto = textoMonto(monto);
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize:
              radio *
              (texto.length <= 2
                  ? .82
                  : texto.length == 3
                  ? .7
                  : .58),
          height: 1,
          color: coloresFicha(valor).numero,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pintor.paint(canvas, centro - Offset(pintor.width / 2, pintor.height / 2));
  }

  /// "150", "1K", "2,5K", "3M": lo que entra en una ficha.
  static String textoMonto(int monto) {
    if (monto < 1000) return '$monto';
    if (monto >= 1000000) {
      final millones = monto / 1000000;
      if (millones == millones.roundToDouble() || millones >= 10) {
        return '${millones.round()}M';
      }
      return '${millones.toStringAsFixed(1).replaceAll('.', ',')}M';
    }
    final miles = monto / 1000;
    if (miles == miles.roundToDouble() || miles >= 10) {
      return '${miles.round()}K';
    }
    return '${miles.toStringAsFixed(1).replaceAll('.', ',')}K';
  }

  @override
  bool shouldRepaint(PintorFichasPano viejo) =>
      viejo.g.area != g.area || !_iguales(viejo.apuestas, apuestas);

  static bool _iguales(Map<Apuesta, int> a, Map<Apuesta, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
