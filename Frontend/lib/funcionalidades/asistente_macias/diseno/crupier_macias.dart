import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cartas_blackjack.dart';
import 'piel_crupier.dart';

/// MacIAs de crupier: chaleco, camisa y moño, en su pixel art de siempre.
const rutaFotoCrupier = 'assets/images/marca/macias_crupier.jpg';

/// Las caras de MacIAs en la mesa, como los personajes de una novela
/// visual: cambian con lo que pasa y con lo que dice.
enum ExpresionCrupier {
  normal,
  feliz,
  risa,
  canchero,
  guino,
  sorprendido,
  triste,
  nervioso,
  enojado,
}

/// Los cuadros de un parpadeo.
enum ParpadeoCrupier { abiertos, medio, cerrados }

enum _Ojos { foto, feliz, medio, cerrado, sorprendido, triste, enojado }

enum _Cejas { foto, relajadas, arriba, tristes, enojadas, baja }

enum _Boca {
  foto,
  media,
  abierta,
  sonrisa,
  risaMedia,
  risa,
  o,
  triste,
  ondulada,
  canchera,
  apretada,
}

enum _Efecto { rubor, gota, brillos, vena, exclamacion, lagrima }

/// Una cara: los ojos y las cejas (el de la izquierda de la foto primero),
/// la boca quieta, a medio abrir y abierta (mientras habla va y viene entre
/// las tres), y los efectos de anime que la acompañan.
typedef _Cara = ({
  (_Ojos, _Ojos) ojos,
  (_Cejas, _Cejas) cejas,
  (_Boca, _Boca, _Boca) boca,
  Set<_Efecto> efectos,
});

const _caras = <ExpresionCrupier, _Cara>{
  ExpresionCrupier.normal: (
    ojos: (_Ojos.foto, _Ojos.foto),
    cejas: (_Cejas.foto, _Cejas.foto),
    boca: (_Boca.foto, _Boca.media, _Boca.abierta),
    efectos: <_Efecto>{},
  ),
  ExpresionCrupier.feliz: (
    ojos: (_Ojos.feliz, _Ojos.feliz),
    cejas: (_Cejas.relajadas, _Cejas.relajadas),
    boca: (_Boca.sonrisa, _Boca.risaMedia, _Boca.risa),
    efectos: {_Efecto.rubor},
  ),
  ExpresionCrupier.risa: (
    ojos: (_Ojos.feliz, _Ojos.feliz),
    cejas: (_Cejas.relajadas, _Cejas.relajadas),
    boca: (_Boca.risa, _Boca.risaMedia, _Boca.risa),
    efectos: {_Efecto.rubor, _Efecto.brillos},
  ),
  ExpresionCrupier.canchero: (
    ojos: (_Ojos.medio, _Ojos.medio),
    cejas: (_Cejas.arriba, _Cejas.baja),
    boca: (_Boca.canchera, _Boca.media, _Boca.abierta),
    efectos: <_Efecto>{},
  ),
  ExpresionCrupier.guino: (
    ojos: (_Ojos.feliz, _Ojos.foto),
    cejas: (_Cejas.relajadas, _Cejas.relajadas),
    boca: (_Boca.sonrisa, _Boca.risaMedia, _Boca.risa),
    efectos: {_Efecto.brillos},
  ),
  ExpresionCrupier.sorprendido: (
    ojos: (_Ojos.sorprendido, _Ojos.sorprendido),
    cejas: (_Cejas.arriba, _Cejas.arriba),
    boca: (_Boca.o, _Boca.media, _Boca.abierta),
    efectos: {_Efecto.exclamacion},
  ),
  ExpresionCrupier.triste: (
    ojos: (_Ojos.triste, _Ojos.triste),
    cejas: (_Cejas.tristes, _Cejas.tristes),
    boca: (_Boca.triste, _Boca.media, _Boca.abierta),
    efectos: {_Efecto.lagrima},
  ),
  ExpresionCrupier.nervioso: (
    ojos: (_Ojos.foto, _Ojos.foto),
    cejas: (_Cejas.tristes, _Cejas.tristes),
    boca: (_Boca.ondulada, _Boca.media, _Boca.abierta),
    efectos: {_Efecto.gota, _Efecto.rubor},
  ),
  ExpresionCrupier.enojado: (
    ojos: (_Ojos.enojado, _Ojos.enojado),
    cejas: (_Cejas.enojadas, _Cejas.enojadas),
    boca: (_Boca.apretada, _Boca.media, _Boca.abierta),
    efectos: {_Efecto.vena},
  ),
};

// ======================================================= el pixel art nuevo
// Cada gesto se dibuja celda por celda sobre la grilla de la foto, con los
// colores de la misma foto. "." deja la piel (o la foto, fuera de lo que se
// borra), "+" conserva la foto aunque este en lo que se borra (la mitad de
// abajo del ojo bajo un parpado, por ejemplo) y cada letra es un color.

const _paleta = <String, int>{
  'K': 0xFF1C0B05, // el contorno del ojo
  'k': 0xFF3B1C10, // las pestañas, mas suaves
  'N': 0xFF2C140B, // la pupila
  'W': 0xFFEDE8E2, // lo blanco del ojo
  'G': 0xFFB2A99F, // su sombra
  'E': 0xFF55301F, // la ceja
  'e': 0xFF84503A, // su borde
  'L': 0xFFA34E37, // el labio, oscuro
  'l': 0xFFC25C45, // el labio
  'p': 0xFFD66F55, // el labio de abajo
  'M': 0xFF4A1A12, // la boca por dentro
  'T': 0xFFF3ECE5, // los dientes
  'U': 0xFFC9605A, // la lengua
  'q': 0x2EFF5A70, // el rubor, por fuera
  'Q': 0x52FF5A70, // el rubor
};

/// El ojo de la izquierda de la foto (8 x 6 celdas, desde la columna 2 y
/// la fila 4). El otro es su reflejo.
const _mapasOjo = <_Ojos, List<String>>{
  _Ojos.feliz: [
    '........',
    '..KKK...',
    '.K...K..',
    'K.....K.',
    '........',
    '........',
  ],
  _Ojos.medio: [
    '........',
    '........',
    'KKKKKKKk',
    '++++++++',
    '++++++++',
    '++++++++',
  ],
  _Ojos.cerrado: [
    '........',
    '........',
    '........',
    'K......k',
    '.KKKKKK.',
    '........',
  ],
  _Ojos.sorprendido: [
    '..KKKK..',
    '.KGGGGK.',
    'KWWNNWWK',
    'KWWNNWWK',
    '.KWWWWK.',
    '..KKKK..',
  ],
  _Ojos.triste: [
    '......Kk',
    '....KK++',
    '..KK++++',
    'KK++++++',
    '++++++++',
    '++++++++',
  ],
  _Ojos.enojado: [
    'Kk......',
    '++KK....',
    '++++KK..',
    '++++++KK',
    '++++++++',
    '++++++++',
  ],
};

/// La ceja de la izquierda de la foto (10 x 4 celdas, desde la columna 1 y
/// la fila 0): su punta de afuera a la izquierda.
const _mapasCeja = <_Cejas, List<String>>{
  _Cejas.relajadas: ['..........', '...eEEEe..', '.eE.....Ee', '..........'],
  _Cejas.arriba: ['...eEEEe..', '.eE.....Ee', '..........', '..........'],
  _Cejas.tristes: ['........eE', '.....eEE..', '.eEEe.....', '..........'],
  _Cejas.enojadas: ['..........', 'eEe.......', '..eEEe....', '.....eEEE.'],
  _Cejas.baja: ['..........', '..........', '.eEEEEEEe.', '..........'],
};

/// La boca (11 x 5 celdas, desde la columna 7 y la fila 17).
const _mapasBoca = <_Boca, List<String>>{
  _Boca.media: [
    '...........',
    '..LlllllL..',
    '...LMMML...',
    '...........',
    '...........',
  ],
  _Boca.abierta: [
    '...........',
    '..LLLLLLL..',
    '..LTTTTTL..',
    '..LMMMMML..',
    '...LLLLL...',
  ],
  _Boca.sonrisa: [
    '.L.......L.',
    '..LlllllL..',
    '....ppp....',
    '...........',
    '...........',
  ],
  _Boca.risaMedia: [
    '..L.....L..',
    '..LTTTTTL..',
    '...LMMML...',
    '....LLL....',
    '...........',
  ],
  _Boca.risa: [
    '.LLLLLLLLL.',
    '.LTTTTTTTL.',
    '..LMMMMML..',
    '...LUUUL...',
    '....LLL....',
  ],
  _Boca.o: [
    '....LLL....',
    '...LMMML...',
    '...LMMML...',
    '....LLL....',
    '...........',
  ],
  _Boca.triste: [
    '...........',
    '...lLLLl...',
    '..L.....L..',
    '.L.......L.',
    '...........',
  ],
  _Boca.ondulada: [
    '...........',
    '..LL..LL...',
    '.L..LL..LL.',
    '...........',
    '...........',
  ],
  _Boca.canchera: [
    '...........',
    '........LL.',
    '..LLLLLL...',
    '....ppp....',
    '...........',
  ],
  _Boca.apretada: [
    '...........',
    '..LLLLLLL..',
    '...........',
    '...........',
    '...........',
  ],
};

/// El rubor, en la mejilla de la izquierda (desde la columna 2 y la fila 12).
const _mapaRubor = ['.qQQq.', 'qQQQQq'];

// Los efectos de anime, tambien en pixel art.
const _paletaEfectos = <String, int>{
  'b': 0xFF2F6FB0, // el borde de la gota
  'c': 0xFF9ED8FF, // el agua
  'H': 0xFFFFFFFF, // un brillo
  'y': 0xFFFFC94A, // los brillitos
  'v': 0xFFE53935, // la venita
  'K': 0xFF3A2A00, // el borde del "!"
  'Y': 0xFFFFD54F, // el "!"
};

const _gota = ['..b..', '.bcb.', 'bcccb', 'bHccb', '.bbb.'];

const _lagrima = ['.b.', 'bcb', '.b.'];

const _brilloGrande = [
  '...y...',
  '...y...',
  '..yHy..',
  'yyHHHyy',
  '..yHy..',
  '...y...',
  '...y...',
];

const _brilloChico = ['.y.', 'yHy', '.y.'];

const _vena = ['.v.v.', 'vv.vv', '.....', 'vv.vv', '.v.v.'];

const _exclamacion = [
  'KKK',
  'KYK',
  'KYK',
  'KYK',
  'KKK',
  '...',
  'KKK',
  'KYK',
  'KKK',
];

/// Una celda de la grilla de la foto, en sus 512 px.
Rect _celda(int columna, int fila) => Rect.fromLTWH(
  origenCeldaX + columna * ladoCelda,
  origenCeldaY + fila * ladoCelda,
  ladoCelda,
  ladoCelda,
);

/// Un dibujo de pixel art armado una vez: un camino por color.
class _Dibujo {
  _Dibujo(
    List<String> filas, {
    required Map<String, int> paleta,
    int columna = 0,
    int fila = 0,
    Offset? origen,
    double lado = ladoCelda,
    bool espejo = false,
  }) {
    final caminos = <int, Path>{};
    for (final (j, texto) in filas.indexed) {
      final letras = espejo ? texto.split('').reversed : texto.split('');
      for (final (i, letra) in letras.indexed) {
        if (letra == '+') {
          conservar.add((columna + i, fila + j));
          continue;
        }
        final color = paleta[letra];
        if (color == null) continue;
        final celda = origen == null
            ? _celda(columna + i, fila + j)
            : Rect.fromLTWH(
                origen.dx + i * lado,
                origen.dy + j * lado,
                lado,
                lado,
              );
        // Las opacas se pisan apenas con las vecinas, para que entre dos
        // colores no se vea una rendija; las transparentes no, o se
        // oscurecerian en el borde.
        final opaca = (color >>> 24) == 0xFF;
        (caminos[color] ??= Path()).addRect(opaca ? celda.inflate(.35) : celda);
      }
    }
    _trazos = [
      for (final MapEntry(key: color, value: camino) in caminos.entries)
        (Color(color), camino),
    ];
  }

  /// Las celdas en las que se ve la foto aunque se borre lo de abajo.
  final conservar = <(int, int)>{};
  late final List<(Color, Path)> _trazos;

  void pintar(Canvas canvas, [double opacidad = 1]) {
    final pintura = Paint();
    for (final (color, camino) in _trazos) {
      pintura.color = opacidad >= 1
          ? color
          : color.withValues(alpha: color.a * opacidad);
      canvas.drawPath(camino, pintura);
    }
  }
}

/// Cada dibujo se arma la primera vez que hace falta y queda guardado.
final _dibujos = <Object, _Dibujo>{};

_Dibujo _ojo(_Ojos ojo, {required bool derecho}) => _dibujos.putIfAbsent(
  (ojo, derecho),
  () => _Dibujo(
    _mapasOjo[ojo]!,
    paleta: _paleta,
    columna: derecho ? 17 : 2,
    fila: 4,
    espejo: derecho,
  ),
);

_Dibujo _ceja(_Cejas ceja, {required bool derecha}) => _dibujos.putIfAbsent(
  (ceja, derecha),
  () => _Dibujo(
    _mapasCeja[ceja]!,
    paleta: _paleta,
    columna: derecha ? 15 : 1,
    espejo: derecha,
  ),
);

_Dibujo _boca(_Boca boca) => _dibujos.putIfAbsent(
  boca,
  () => _Dibujo(_mapasBoca[boca]!, paleta: _paleta, columna: 7, fila: 17),
);

_Dibujo _rubor({required bool derecho}) => _dibujos.putIfAbsent(
  ('rubor', derecho),
  () => _Dibujo(
    _mapaRubor,
    paleta: _paleta,
    columna: derecho ? 19 : 2,
    fila: 12,
    espejo: derecho,
  ),
);

/// Un efecto, centrado en el origen.
_Dibujo _efecto(List<String> mapa, double lado) => _dibujos.putIfAbsent(
  (mapa, lado),
  () => _Dibujo(
    mapa,
    paleta: _paletaEfectos,
    lado: lado,
    origen: Offset(-mapa.first.length * lado / 2, -mapa.length * lado / 2),
  ),
);

/// Dibuja a MacIAs: su foto y, encima, la cara que corresponde.
///
/// La foto es pixel art en celdas de 9 x 9 (en sus 512 px). Para cambiar un
/// gesto se borra esa parte con la piel que habria debajo, medida en la
/// misma foto (ver `piel_crupier.dart`), y se dibuja el gesto nuevo celda
/// por celda con los colores de la foto: asi parece hecho por la misma mano
/// y con el mismo tono de piel.
///
/// Mientras [mezcla] va de 0 a 1, la cara [anterior] se funde con la nueva.
class PintorCaraCrupier extends CustomPainter {
  PintorCaraCrupier({
    required this.foto,
    required this.expresion,
    this.anterior,
    this.mezcla = kAlwaysCompleteAnimation,
    this.parpadeo = ParpadeoCrupier.abiertos,
    this.boca = 0,
  }) : super(repaint: mezcla);

  final ui.Image foto;
  final ExpresionCrupier expresion;
  final ExpresionCrupier? anterior;
  final Animation<double> mezcla;
  final ParpadeoCrupier parpadeo;

  /// 0 con la boca quieta, 1 a medio abrir y 2 abierta.
  final int boca;

  /// Todo lo que puede cambiar de la cara, en los 512 px de la foto.
  static const _zona = Rect.fromLTRB(140, 140, 372, 352);

  @override
  void paint(Canvas canvas, Size size) {
    final enFoto = foto.width / 512;
    final pinturaFoto = Paint()..filterQuality = FilterQuality.medium;
    canvas
      ..drawImageRect(
        foto,
        Rect.fromLTWH(0, 0, foto.width.toDouble(), foto.height.toDouble()),
        Offset.zero & size,
        pinturaFoto,
      )
      ..save()
      ..scale(size.width / 512, size.height / 512);
    final t = mezcla.value;
    final antes = anterior;
    if (antes == null || antes == expresion || t >= 1) {
      _pintarCara(canvas, _caras[expresion]!);
    } else {
      _pintarCara(canvas, _caras[antes]!);
      // La cara nueva se pinta en una capa que va apareciendo encima, con
      // la foto debajo: se funden las dos sin que se asome la original.
      canvas
        ..saveLayer(_zona, Paint()..color = Color.fromRGBO(0, 0, 0, t))
        ..drawImageRect(
          foto,
          Rect.fromLTRB(
            _zona.left * enFoto,
            _zona.top * enFoto,
            _zona.right * enFoto,
            _zona.bottom * enFoto,
          ),
          _zona,
          pinturaFoto,
        );
      _pintarCara(canvas, _caras[expresion]!);
      canvas.restore();
    }
    canvas.restore();
  }

  _Ojos _parpadear(_Ojos ojo) => switch (parpadeo) {
    ParpadeoCrupier.abiertos => ojo,
    // A medias solo se nota en los ojos de la foto; los otros pasan
    // directo a cerrados.
    ParpadeoCrupier.medio => ojo == _Ojos.foto ? _Ojos.medio : ojo,
    ParpadeoCrupier.cerrados => ojo == _Ojos.feliz ? ojo : _Ojos.cerrado,
  };

  /// Las celdas nuevas con los bordes apenas suaves, como los de la foto.
  static final _suave = Paint()
    ..imageFilter = ui.ImageFilter.blur(sigmaX: .9, sigmaY: .9);

  void _pintarCara(Canvas canvas, _Cara cara) {
    final (cejaIzquierda, cejaDerecha) = cara.cejas;
    final (ojoIzquierdo, ojoDerecho) = cara.ojos;
    final izquierdo = _parpadear(ojoIzquierdo);
    final derecho = _parpadear(ojoDerecho);
    final (quieta, media, abierta) = cara.boca;
    final laBoca = switch (boca) {
      1 => media,
      2 => abierta,
      _ => quieta,
    };
    final rubor = cara.efectos.contains(_Efecto.rubor);
    // La cara de la foto tal cual: no hay nada que pintar encima.
    if (cejaIzquierda == _Cejas.foto &&
        cejaDerecha == _Cejas.foto &&
        izquierdo == _Ojos.foto &&
        derecho == _Ojos.foto &&
        laBoca == _Boca.foto &&
        !rubor) {
      return;
    }
    canvas.saveLayer(_zona, _suave);
    if (cejaIzquierda != _Cejas.foto) {
      _parte(
        canvas,
        _ceja(cejaIzquierda, derecha: false),
        pielBajoCejaIzquierda,
      );
    }
    if (cejaDerecha != _Cejas.foto) {
      _parte(canvas, _ceja(cejaDerecha, derecha: true), pielBajoCejaDerecha);
    }
    if (izquierdo != _Ojos.foto) {
      _parte(canvas, _ojo(izquierdo, derecho: false), pielBajoOjoIzquierdo);
    }
    if (derecho != _Ojos.foto) {
      _parte(canvas, _ojo(derecho, derecho: true), pielBajoOjoDerecho);
    }
    if (laBoca != _Boca.foto) _parte(canvas, _boca(laBoca), pielBajoBoca);
    if (rubor) {
      _rubor(derecho: false).pintar(canvas);
      _rubor(derecho: true).pintar(canvas);
    }
    canvas.restore();
  }

  /// Borra esa parte de la foto (salvo lo que el dibujo conserva) y dibuja
  /// el gesto encima.
  static void _parte(Canvas canvas, _Dibujo dibujo, List<CeldaPiel> piel) {
    final pintura = Paint();
    for (final (columna, fila, color) in piel) {
      if (dibujo.conservar.contains((columna, fila))) continue;
      pintura.color = Color(color);
      canvas.drawRect(_celda(columna, fila).inflate(.35), pintura);
    }
    dibujo.pintar(canvas);
  }

  @override
  bool shouldRepaint(PintorCaraCrupier viejo) =>
      viejo.foto != foto ||
      viejo.expresion != expresion ||
      viejo.anterior != anterior ||
      viejo.parpadeo != parpadeo ||
      viejo.boca != boca;
}

/// Los efectos de anime de cada cara (la gota de los nervios, la lagrima,
/// los brillitos, la venita, el "!"), en pixel art y en movimiento.
///
/// Va aparte de la cara: se mueve todo el tiempo, y asi la foto no se
/// vuelve a pintar en cada cuadro.
class PintorEfectosCrupier extends CustomPainter {
  PintorEfectosCrupier({
    required this.expresion,
    required this.efectos,
    this.anterior,
    this.mezcla = kAlwaysCompleteAnimation,
  }) : super(repaint: Listenable.merge([efectos, mezcla]));

  final ExpresionCrupier expresion;
  final ExpresionCrupier? anterior;

  /// Va de 0 a 1 una y otra vez.
  final Animation<double> efectos;
  final Animation<double> mezcla;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 512, size.height / 512);
    final t = efectos.value;
    final m = mezcla.value;
    final antes = anterior;
    if (antes != null && antes != expresion && m < 1) {
      _pintar(canvas, _caras[antes]!.efectos, t, 1 - m);
      _pintar(canvas, _caras[expresion]!.efectos, t, m);
    } else {
      _pintar(canvas, _caras[expresion]!.efectos, t, 1);
    }
    canvas.restore();
  }

  static void _pintar(
    Canvas canvas,
    Set<_Efecto> efectos,
    double t,
    double opacidad,
  ) {
    void dibujo(
      List<String> mapa,
      Offset centro, {
      double lado = 8,
      double escala = 1,
      double alfa = 1,
    }) {
      canvas
        ..save()
        ..translate(centro.dx, centro.dy)
        ..scale(escala);
      _efecto(mapa, lado).pintar(canvas, alfa * opacidad);
      canvas.restore();
    }

    for (final efecto in efectos) {
      switch (efecto) {
        case _Efecto.rubor:
          break;
        case _Efecto.gota:
          // Se resbala un poquito por la sien.
          dibujo(_gota, Offset(404, 154 + 9 * math.sin(t * math.pi)));
        case _Efecto.lagrima:
          dibujo(
            _lagrima,
            Offset(206 + 2 * t, 252 + 30 * t),
            lado: 7,
            alfa: t < .75 ? 1 : (1 - t) / .25,
          );
        case _Efecto.brillos:
          for (final (centro, desfase) in const [
            (Offset(76, 118), 0.0),
            (Offset(444, 96), .33),
            (Offset(452, 236), .66),
          ]) {
            final fase = (t + desfase) % 1;
            final grande = fase < .5;
            dibujo(
              grande ? _brilloGrande : _brilloChico,
              centro,
              lado: 6,
              escala: grande ? .8 + .4 * math.sin(fase * 2 * math.pi) : 1,
            );
          }
        case _Efecto.vena:
          dibujo(
            _vena,
            const Offset(366, 106),
            lado: 9,
            escala: 1 + .14 * math.sin(t * math.pi * 4).abs(),
          );
        case _Efecto.exclamacion:
          dibujo(
            _exclamacion,
            Offset(442, 84 - 6 * math.sin(t * math.pi * 2).abs()),
          );
      }
    }
  }

  @override
  bool shouldRepaint(PintorEfectosCrupier viejo) =>
      viejo.expresion != expresion || viejo.anterior != anterior;
}

/// Como se mueve MacIAs con cada cara.
enum _Salto { habla, festeja, lamenta, sorpresa }

/// MacIAs, el crupier: su retrato con marco dorado, que parpadea, habla y
/// cambia de cara.
///
/// Cuando cambia [latido] da un saltito (o niega con la cabeza, o se asusta,
/// segun la cara). Mientras [hablando], la boca se mueve.
class CrupierMacias extends StatefulWidget {
  const CrupierMacias({
    required this.tamano,
    this.expresion = ExpresionCrupier.normal,
    this.hablando = false,
    this.latido = 0,
    super.key,
  });

  final double tamano;
  final ExpresionCrupier expresion;
  final bool hablando;
  final int latido;

  @override
  State<CrupierMacias> createState() => _CrupierMaciasState();
}

class _CrupierMaciasState extends State<CrupierMacias>
    with TickerProviderStateMixin {
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final AnimationController _efectos = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// El fundido entre una cara y la siguiente.
  late final AnimationController _mezcla = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  final _azar = math.Random();
  Timer? _proximoParpadeo;
  Timer? _pasoParpadeo;
  Timer? _movimientoBoca;
  var _parpadeo = ParpadeoCrupier.abiertos;
  var _boca = 0;
  ExpresionCrupier? _anterior;
  var _sinMovimiento = false;

  ImageStream? _flujoFoto;
  ImageInfo? _foto;
  late final _alCargar = ImageStreamListener((info, _) {
    if (!mounted) {
      info.dispose();
      return;
    }
    setState(() {
      _foto?.dispose();
      _foto = info;
    });
  });

  @override
  void initState() {
    super.initState();
    _programarParpadeo();
    if (widget.hablando) _hablar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.disableAnimationsOf(context);
    _animarEfectos();
    // La foto se pinta a mano (debajo de la cara): hace falta la imagen.
    final flujo = const AssetImage(
      rutaFotoCrupier,
    ).resolve(createLocalImageConfiguration(context));
    if (flujo.key != _flujoFoto?.key) {
      _flujoFoto?.removeListener(_alCargar);
      _flujoFoto = flujo..addListener(_alCargar);
    }
  }

  @override
  void didUpdateWidget(CrupierMacias viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.latido != widget.latido) _salto.forward(from: 0);
    if (viejo.expresion != widget.expresion) {
      _anterior = viejo.expresion;
      if (_sinMovimiento) {
        _mezcla.value = 1;
      } else {
        _mezcla.forward(from: 0);
      }
      _animarEfectos();
    }
    if (viejo.hablando != widget.hablando) {
      if (widget.hablando) {
        _hablar();
      } else {
        _movimientoBoca?.cancel();
        _boca = 0;
      }
    }
  }

  @override
  void dispose() {
    _flujoFoto?.removeListener(_alCargar);
    _foto?.dispose();
    _proximoParpadeo?.cancel();
    _pasoParpadeo?.cancel();
    _movimientoBoca?.cancel();
    _salto.dispose();
    _efectos.dispose();
    _mezcla.dispose();
    super.dispose();
  }

  /// Parpadea cada dos a cinco segundos, y a veces dos veces seguidas, como
  /// una persona.
  void _programarParpadeo() {
    _proximoParpadeo = Timer(
      Duration(milliseconds: 2200 + _azar.nextInt(2800)),
      () {
        if (!mounted) return;
        _parpadear(veces: _azar.nextDouble() < .2 ? 2 : 1);
        _programarParpadeo();
      },
    );
  }

  /// Un parpadeo en cuadros, como en las novelas visuales: los ojos se
  /// cierran a medias, del todo, a medias otra vez y se abren.
  void _parpadear({int veces = 1}) {
    const cuadros = [
      (ParpadeoCrupier.medio, 40),
      (ParpadeoCrupier.cerrados, 70),
      (ParpadeoCrupier.medio, 40),
      (ParpadeoCrupier.abiertos, 150),
    ];
    var paso = 0;
    void siguiente() {
      if (!mounted) return;
      final (estado, espera) = cuadros[paso % cuadros.length];
      setState(() => _parpadeo = estado);
      paso++;
      if (paso < cuadros.length * veces) {
        _pasoParpadeo = Timer(Duration(milliseconds: espera), siguiente);
      }
    }

    _pasoParpadeo?.cancel();
    siguiente();
  }

  /// Mientras habla, la boca va y viene entre quieta, a medio abrir y
  /// abierta: nunca salta de cerrada a abierta de golpe.
  void _hablar() {
    _movimientoBoca?.cancel();
    _movimientoBoca = Timer.periodic(const Duration(milliseconds: 75), (_) {
      if (!mounted) return;
      final r = _azar.nextDouble();
      final siguiente = switch (_boca) {
        0 => r < .75 ? 1 : 0,
        1 => r < .6 ? 2 : 0,
        _ => r < .75 ? 1 : 2,
      };
      if (siguiente != _boca) setState(() => _boca = siguiente);
    });
  }

  /// Los efectos que se mueven (la gota, los brillos) solo corren mientras
  /// se ven.
  void _animarEfectos() {
    final efectos = _caras[widget.expresion]!.efectos;
    final seMueven = efectos.any((e) => e != _Efecto.rubor);
    if (seMueven && !_sinMovimiento) {
      if (!_efectos.isAnimating) _efectos.repeat();
    } else {
      _efectos
        ..stop()
        ..value = .3;
    }
  }

  _Salto get _comoSalta => switch (widget.expresion) {
    ExpresionCrupier.feliz ||
    ExpresionCrupier.risa ||
    ExpresionCrupier.guino => _Salto.festeja,
    ExpresionCrupier.triste ||
    ExpresionCrupier.nervioso ||
    ExpresionCrupier.enojado => _Salto.lamenta,
    ExpresionCrupier.sorprendido => _Salto.sorpresa,
    _ => _Salto.habla,
  };

  @override
  Widget build(BuildContext context) {
    final tamano = widget.tamano;
    final radio = BorderRadius.circular(tamano * .2);
    final foto = _foto?.image;
    final retrato = Container(
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * .035),
      decoration: BoxDecoration(
        borderRadius: radio,
        gradient: const SweepGradient(
          colors: [
            ColoresCarta.oroClaro,
            ColoresCarta.oro,
            Color(0xFF8A6414),
            ColoresCarta.oro,
            ColoresCarta.oroClaro,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tamano * .17),
        child: ColoredBox(
          color: Colors.white,
          // Si la foto tarda (en la web, la primera vez), aparece con un
          // fundido; si ya estaba, desde el primer cuadro.
          child: AnimatedOpacity(
            opacity: foto == null ? 0 : 1,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            child: foto == null
                ? const SizedBox.expand()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: PintorCaraCrupier(
                            foto: foto,
                            expresion: widget.expresion,
                            anterior: _anterior,
                            mezcla: _mezcla,
                            parpadeo: _parpadeo,
                            boca: widget.hablando ? _boca : 0,
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: PintorEfectosCrupier(
                            expresion: widget.expresion,
                            anterior: _anterior,
                            efectos: _efectos,
                            mezcla: _mezcla,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: 'MacIAs, el crupier',
      child: AnimatedBuilder(
        animation: _salto,
        child: retrato,
        builder: (context, hijo) {
          final t = _salto.value;
          final onda = math.sin(t * math.pi);
          final (dy, giro, crece) = switch (_comoSalta) {
            _Salto.habla => (-4 * onda, 0.0, .025 * onda),
            _Salto.festeja => (
              -13 * onda * (1 - t * .3),
              .06 * math.sin(t * math.pi * 3) * (1 - t),
              .07 * onda,
            ),
            _Salto.lamenta => (
              2 * onda,
              .08 * math.sin(t * math.pi * 4) * (1 - t),
              -.03 * onda,
            ),
            _Salto.sorpresa => (
              -16 * math.sin(math.min(1, t * 2) * math.pi),
              0.0,
              .1 * math.sin(math.min(1, t * 1.6) * math.pi),
            ),
          };
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.translationValues(0, dy, 0)
              ..rotateZ(giro)
              ..scaleByDouble(1 + crece, 1 + crece, 1, 1),
            child: hijo,
          );
        },
      ),
    );
  }
}

/// El cartelito con el nombre, debajo del retrato.
class PlacaCrupier extends StatelessWidget {
  const PlacaCrupier({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xE6141210),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ColoresCarta.oro.withValues(alpha: .8)),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Text(
        'CRUPIER',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w900,
          fontSize: 9.5,
          letterSpacing: 1.6,
          height: 1.2,
          color: ColoresCarta.oroClaro,
        ),
      ),
    ),
  );
}

/// Lo que dice MacIAs, como en una novela visual: una caja con su nombre
/// arriba, y el texto que aparece letra por letra.
///
/// Tocarla completa el texto de una. Avisa con [alHablar] cuando empieza y
/// cuando termina de "decirlo" (para mover la boca), y con [alSonar] cada
/// tantas letras (para la vocecita).
class DialogoCrupier extends StatefulWidget {
  const DialogoCrupier({
    required this.texto,
    this.msPorLetra = 28,
    this.alHablar,
    this.alSonar,
    super.key,
  });

  final String texto;
  final int msPorLetra;
  final ValueChanged<bool>? alHablar;
  final VoidCallback? alSonar;

  @override
  State<DialogoCrupier> createState() => _DialogoCrupierState();
}

class _DialogoCrupierState extends State<DialogoCrupier>
    with TickerProviderStateMixin {
  late final AnimationController _escritura = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: math.max(1, widget.texto.length * widget.msPorLetra),
    ),
  );
  late final AnimationController _cursor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  int _letras = 0;

  @override
  void initState() {
    super.initState();
    _escritura
      ..addListener(_avanzar)
      ..addStatusListener((estado) {
        if (estado != AnimationStatus.completed) return;
        widget.alHablar?.call(false);
        _cursor.repeat(reverse: true);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.alHablar?.call(true);
      _escritura.forward();
    });
  }

  void _avanzar() {
    final total = widget.texto.length;
    final letras = (_escritura.value * total).round().clamp(0, total);
    if (letras == _letras) return;
    var suena = false;
    for (var i = _letras; i < letras; i++) {
      if (i % 3 == 0 && widget.texto[i].trim().isNotEmpty) suena = true;
    }
    if (suena) widget.alSonar?.call();
    setState(() => _letras = letras);
  }

  void _completar() {
    if (_escritura.isAnimating) _escritura.value = 1;
  }

  @override
  void dispose() {
    _escritura.dispose();
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w800,
      fontSize: 13.5,
      height: 1.32,
      color: Color(0xFFF7EEDC),
    );
    final terminado = _letras >= widget.texto.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _completar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 11),
            padding: const EdgeInsets.fromLTRB(13, 15, 10, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF2271D18), Color(0xF2140F0C)],
              ),
              border: Border.all(
                color: ColoresCarta.oro.withValues(alpha: .85),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lo que falta escribir ya ocupa su lugar (transparente): la
                // caja no crece ni salta mientras aparecen las letras.
                Text.rich(
                  TextSpan(
                    style: estilo,
                    children: [
                      TextSpan(text: widget.texto.substring(0, _letras)),
                      TextSpan(
                        text: widget.texto.substring(_letras),
                        style: const TextStyle(color: Colors.transparent),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FadeTransition(
                    opacity: terminado ? _cursor : kAlwaysDismissedAnimation,
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: ColoresCarta.oroClaro,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ColoresCarta.oroClaro, ColoresCarta.oro],
                ),
                border: Border.all(color: const Color(0xFF5A3D08)),
              ),
              child: const Text(
                'MacIAs',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  height: 1.25,
                  color: Color(0xFF2B1E05),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
