import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Recorta la cabeza de MacIAs de su foto de crupier y escribe
/// `assets/images/marca/macias_cabeza.png`: el pelo, la cara y el cuello, con
/// el fondo transparente, para ponerla sobre el cuerpo que se le dibuja en la
/// pesca. Queda en la misma grilla de 512 que la foto: las caras
/// (`PintorCaraCrupier`) se le pintan igual que a la foto entera.
///
/// El fondo es el blanco que toca el borde de la foto (asi no se borran los
/// brillos de los ojos). En el filo, lo transparente sale de cuanto blanco
/// tiene cada pixel, y a su color se le saca ese blanco: si no, quedaria un
/// halo claro sobre el cielo. Abajo, donde empiezan el cuello de la camisa y
/// el moño (que se dibujan con el cuerpo), solo queda la piel del cuello, y
/// se corta con un fundido.
///
/// Uso, desde Frontend: `dart run tool/recortar_cabeza_crupier.dart`
void main() {
  final foto = img.decodeImage(
    File('assets/images/marca/macias_crupier.jpg').readAsBytesSync(),
  )!;
  final ancho = foto.width;
  final alto = foto.height;
  int r(int x, int y) => foto.getPixel(x, y).r.toInt();
  int g(int x, int y) => foto.getPixel(x, y).g.toInt();
  int b(int x, int y) => foto.getPixel(x, y).b.toInt();
  int claro(int x, int y) => math.min(r(x, y), math.min(g(x, y), b(x, y)));
  bool dentro(int x, int y) => x >= 0 && y >= 0 && x < ancho && y < alto;

  // 1. El fondo: lo claro que se conecta con el borde.
  final fondo = List.generate(alto, (_) => List.filled(ancho, false));
  final cola = Queue<(int, int)>();
  void probar(int x, int y) {
    if (!dentro(x, y) || fondo[y][x] || claro(x, y) < 200) return;
    fondo[y][x] = true;
    cola.add((x, y));
  }

  for (var x = 0; x < ancho; x++) {
    probar(x, 0);
    probar(x, alto - 1);
  }
  for (var y = 0; y < alto; y++) {
    probar(0, y);
    probar(ancho - 1, y);
  }
  while (cola.isNotEmpty) {
    final (x, y) = cola.removeFirst();
    probar(x + 1, y);
    probar(x - 1, y);
    probar(x, y + 1);
    probar(x, y - 1);
  }

  // 2. Del cuello para abajo solo queda la piel (ni la camisa ni el
  // chaleco), y de la fila del corte para abajo, nada.
  const cuello = 366;
  const corte = 404;
  for (var y = cuello; y < alto; y++) {
    for (var x = 0; x < ancho; x++) {
      final piel = r(x, y) >= 110 && r(x, y) - b(x, y) >= 35;
      if (y >= corte || !piel) fondo[y][x] = true;
    }
  }

  // 3. La cabeza: lo que se conecta con la cara.
  final cabeza = List.generate(alto, (_) => List.filled(ancho, false));
  final pila = [(256, 250)];
  cabeza[250][256] = true;
  while (pila.isNotEmpty) {
    final (x, y) = pila.removeLast();
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nx = x + dx;
      final ny = y + dy;
      if (!dentro(nx, ny) || cabeza[ny][nx] || fondo[ny][nx]) continue;
      cabeza[ny][nx] = true;
      pila.add((nx, ny));
    }
  }

  // 4. Lo lejos que esta cada pixel de la cabeza del borde, hasta una celda
  // y un poco: las celdas del filo vienen mezcladas con el blanco del fondo
  // (enteras, no solo su ultimo pixel).
  const filo = 10;
  final distancia = List.generate(alto, (_) => List.filled(ancho, 99));
  final frente = Queue<(int, int)>();
  for (var y = 0; y < alto; y++) {
    for (var x = 0; x < ancho; x++) {
      if (!cabeza[y][x]) continue;
      var borde = y == 0;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx;
        final ny = y + dy;
        if (dentro(nx, ny) && !cabeza[ny][nx]) borde = true;
      }
      if (borde) {
        distancia[y][x] = 1;
        frente.add((x, y));
      }
    }
  }
  while (frente.isNotEmpty) {
    final (x, y) = frente.removeFirst();
    final d = distancia[y][x];
    if (d >= filo + 6) continue;
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nx = x + dx;
      final ny = y + dy;
      if (!dentro(nx, ny) || !cabeza[ny][nx]) continue;
      if (distancia[ny][nx] <= d + 1) continue;
      distancia[ny][nx] = d + 1;
      frente.add((nx, ny));
    }
  }

  // El color de adentro mas cercano (ya sin mezclar con el fondo): con el se
  // calcula cuanto blanco tiene cada pixel del filo.
  (double, double, double)? adentro(int x, int y) {
    for (var radio = 4; radio <= 22; radio += 3) {
      var n = 0;
      var sr = 0.0;
      var sg = 0.0;
      var sb = 0.0;
      for (var dy = -radio; dy <= radio; dy++) {
        for (var dx = -radio; dx <= radio; dx++) {
          final nx = x + dx;
          final ny = y + dy;
          if (!dentro(nx, ny) || !cabeza[ny][nx]) continue;
          if (distancia[ny][nx] <= filo) continue;
          sr += r(nx, ny);
          sg += g(nx, ny);
          sb += b(nx, ny);
          n++;
        }
      }
      if (n > 0) return (sr / n, sg / n, sb / n);
    }
    return null;
  }

  final salida = img.Image(width: ancho, height: alto, numChannels: 4);
  var izquierda = ancho;
  var derecha = 0;
  var arriba = alto;
  var abajo = 0;
  for (var y = 0; y < alto; y++) {
    for (var x = 0; x < ancho; x++) {
      if (!cabeza[y][x]) {
        salida.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      var cr = r(x, y).toDouble();
      var cg = g(x, y).toDouble();
      var cb = b(x, y).toDouble();
      var alfa = 1.0;
      if (distancia[y][x] <= filo) {
        final color = adentro(x, y);
        if (color != null) {
          final (fr, fg, fb) = color;
          final minimo = math.min(fr, math.min(fg, fb));
          final visto = math.min(cr, math.min(cg, cb));
          // Solo lo que es mas claro que adentro tiene blanco del fondo.
          if (visto > minimo) {
            alfa = ((255 - visto) / math.max(1, 255 - minimo)).clamp(0.0, 1.0);
            if (alfa > .02) {
              cr = ((cr - (1 - alfa) * 255) / alfa).clamp(0, 255);
              cg = ((cg - (1 - alfa) * 255) / alfa).clamp(0, 255);
              cb = ((cb - (1 - alfa) * 255) / alfa).clamp(0, 255);
            }
          }
        }
      }
      // El fundido de abajo del cuello.
      if (y >= corte - 12) alfa *= (corte - y) / 12;
      final a = (alfa * 255).round().clamp(0, 255);
      salida.setPixelRgba(x, y, cr.round(), cg.round(), cb.round(), a);
      if (a > 128) {
        izquierda = math.min(izquierda, x);
        derecha = math.max(derecha, x);
        arriba = math.min(arriba, y);
        abajo = math.max(abajo, y);
      }
    }
  }
  File(
    'assets/images/marca/macias_cabeza.png',
  ).writeAsBytesSync(img.encodePng(salida, level: 9));
  stdout.writeln(
    'macias_cabeza.png: cabeza de ($izquierda, $arriba) a ($derecha, $abajo)',
  );
}
