import 'dart:io';

import 'package:image/image.dart' as img;

/// Mide la cara de la foto del crupier y escribe
/// `lib/funcionalidades/asistente_macias/diseno/piel_crupier.dart`.
///
/// La foto es pixel art: celdas de unos 9 x 9 px (en la foto de 512). Para
/// cambiarle la cara hay que borrar sus ojos, cejas y boca, y debajo tiene
/// que quedar la piel que habria si no estuvieran: con el mismo tono y el
/// mismo degrade que la rodea. Eso se calcula aca, celda por celda, como una
/// membrana que se apoya en la piel de alrededor (y nunca en el pelo ni en
/// el fondo).
///
/// Uso, desde Frontend: `dart run tool/medir_cara_crupier.dart`
void main() {
  final foto = img.decodeImage(
    File('assets/images/marca/macias_crupier.jpg').readAsBytesSync(),
  )!;
  const x0 = 135;
  const y0 = 149;
  const lado = 9;
  const columnas = 27;
  const filas = 22;

  // El color de cada celda: el promedio de su centro (los bordes de las
  // celdas vienen suavizados).
  final celdas = List.generate(filas, (j) {
    return List.generate(columnas, (i) {
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;
      var n = 0;
      for (var dy = 2; dy < lado - 2; dy++) {
        for (var dx = 2; dx < lado - 2; dx++) {
          final p = foto.getPixel(x0 + i * lado + dx, y0 + j * lado + dy);
          r += p.r;
          g += p.g;
          b += p.b;
          n++;
        }
      }
      return [r / n, g / n, b / n];
    });
  });

  bool esPiel(List<double> c) {
    final [r, g, b] = c;
    return r > 150 && r > g && g > b && r - b > 50;
  }

  // Lo que se borra de la foto: (columna, fila) de cada celda.
  final zonas = <String, Set<(int, int)>>{
    'cejaIzquierda': {
      for (var i = 1; i <= 10; i++) (i, 1),
      for (var i = 6; i <= 10; i++) (i, 2),
    },
    'cejaDerecha': {
      for (var i = 15; i <= 24; i++) (i, 1),
      for (var i = 15; i <= 24; i++) (i, 2),
    },
    // Con la sombra del parpado (la fila 3): un ojo cerrado o feliz no la
    // tiene, y si quedara se veria como una segunda ceja.
    'ojoIzquierdo': {
      for (var j = 3; j <= 9; j++)
        for (var i = 2; i <= 9; i++) (i, j),
    },
    'ojoDerecho': {
      for (var j = 3; j <= 9; j++)
        for (var i = 17; i <= 24; i++) (i, j),
    },
    'boca': {
      for (var i = 8; i <= 16; i++) (i, 18),
      for (var i = 8; i <= 16; i++) (i, 19),
      for (var i = 10; i <= 15; i++) (i, 20),
    },
  };
  final incognitas = zonas.values.expand((z) => z).toSet();

  // Arranca con el promedio de la piel que rodea a las zonas.
  final borde = <List<double>>[];
  for (final (i, j) in incognitas) {
    for (final (di, dj) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final (ni, nj) = (i + di, j + dj);
      if (incognitas.contains((ni, nj))) continue;
      final c = celdas[nj][ni];
      if (esPiel(c)) borde.add(c);
    }
  }
  final inicio = [
    for (var k = 0; k < 3; k++)
      borde.map((c) => c[k]).reduce((a, b) => a + b) / borde.length,
  ];
  final limpia = {
    for (final celda in incognitas) celda: [...inicio],
  };

  // Gauss-Seidel: cada celda borrada termina siendo el promedio de sus
  // vecinas (las borradas y la piel de la foto).
  for (var vuelta = 0; vuelta < 2000; vuelta++) {
    for (final celda in incognitas) {
      final (i, j) = celda;
      final suma = [0.0, 0.0, 0.0];
      var n = 0;
      for (final (di, dj) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final vecina = (i + di, j + dj);
        final List<double>? c;
        if (incognitas.contains(vecina)) {
          c = limpia[vecina];
        } else if (esPiel(celdas[vecina.$2][vecina.$1])) {
          c = celdas[vecina.$2][vecina.$1];
        } else {
          c = null;
        }
        if (c == null) continue;
        for (var k = 0; k < 3; k++) {
          suma[k] += c[k];
        }
        n++;
      }
      if (n == 0) continue;
      limpia[celda] = [for (var k = 0; k < 3; k++) suma[k] / n];
    }
  }

  String hex(List<double> c) {
    final [r, g, b] = [for (final v in c) v.round().clamp(0, 255)];
    return '0xFF${[r, g, b].map((v) => v.toRadixString(16).padLeft(2, '0').toUpperCase()).join()}';
  }

  final salida = StringBuffer()
    ..writeln(
      '// Generado por tool/medir_cara_crupier.dart a partir de la foto',
    )
    ..writeln(
      '// del crupier. No se edita a mano: si cambia la foto, se vuelve',
    )
    ..writeln('// a correr.')
    ..writeln()
    ..writeln(
      '/// La grilla del pixel art de la foto (de 512 x 512): celdas de',
    )
    ..writeln('/// [ladoCelda] px desde ([origenCeldaX], [origenCeldaY]).')
    ..writeln('const ladoCelda = ${lado.toDouble()};')
    ..writeln('const origenCeldaX = ${x0.toDouble()};')
    ..writeln('const origenCeldaY = ${y0.toDouble()};')
    ..writeln()
    ..writeln('/// La piel que hay debajo de cada parte de la cara: (columna,')
    ..writeln(
      '/// fila, color) de cada celda, como seria sin la ceja, el ojo o la',
    )
    ..writeln('/// boca encima.')
    ..writeln('typedef CeldaPiel = (int, int, int);')
    ..writeln();
  for (final MapEntry(key: nombre, value: zona) in zonas.entries) {
    final ordenadas = zona.toList()
      ..sort((a, b) => a.$2 != b.$2 ? a.$2 - b.$2 : a.$1 - b.$1);
    final nombreConst =
        'pielBajo${nombre[0].toUpperCase()}${nombre.substring(1)}';
    salida.writeln('const $nombreConst = <CeldaPiel>[');
    for (final (i, j) in ordenadas) {
      salida.writeln('  ($i, $j, ${hex(limpia[(i, j)]!)}),');
    }
    salida
      ..writeln('];')
      ..writeln();
  }
  final archivo = File(
    'lib/funcionalidades/asistente_macias/diseno/piel_crupier.dart',
  )..writeAsStringSync('${salida.toString().trimRight()}\n');
  stdout.writeln('Escrito ${archivo.path} (${incognitas.length} celdas)');

  // Para comparar: la foto y la piel limpia, celda por celda.
  final vista = img.Image(width: columnas * 18 * 2 + 20, height: filas * 18);
  img.fill(vista, color: img.ColorRgb8(0, 0, 0));
  for (var j = 0; j < filas; j++) {
    for (var i = 0; i < columnas; i++) {
      final original = celdas[j][i];
      final c = limpia[(i, j)] ?? original;
      for (final (desplazar, color) in [
        (0, original),
        (columnas * 18 + 20, c),
      ]) {
        img.fillRect(
          vista,
          x1: desplazar + i * 18,
          y1: j * 18,
          x2: desplazar + i * 18 + 17,
          y2: j * 18 + 17,
          color: img.ColorRgb8(
            color[0].round(),
            color[1].round(),
            color[2].round(),
          ),
        );
      }
    }
  }
  final temporal = Platform.environment['CRUPIER_VISTA'];
  if (temporal != null) {
    File(temporal).writeAsBytesSync(img.encodePng(vista));
  }
}
