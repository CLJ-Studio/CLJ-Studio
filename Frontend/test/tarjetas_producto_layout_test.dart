import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/local_universitario.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/locales_universitarios/diseno/lista_productos_local.dart';

/// El alto de cada celda de la cuadricula pasó a calcularse (foto en 4:3 mas
/// el bloque de texto) en vez de ser un numero fijo. Si esa cuenta se queda
/// corta, la tarjeta se desborda y aparece la franja amarilla y negra.
///
/// Se prueba en lo estrecho y con la letra agrandada, que es donde revienta.
const _local = LocalUniversitario(
  id: 'local-1',
  nombre: 'Doña Empanada',
  categoriaId: 'comida',
  categoria: 'Comida',
  descripcion: '',
  calificacion: 0,
  tiempoEstimado: '10 min',
  estaAbierto: true,
  costoEntrega: 0,
  emoji: '🥟',
  colorHexadecimal: 0xFFFFFFFF,
);

ProductoMarketplace _producto(String nombre, String descripcion) =>
    ProductoMarketplace(
      id: nombre,
      localId: 'local-1',
      nombre: nombre,
      descripcion: descripcion,
      precio: 12.5,
      emoji: '🥟',
      stock: 5,
      local: _local,
    );

Future<void> _dibujar(
  WidgetTester tester, {
  required double ancho,
  double escalaTexto = 1,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(ancho, 800),
        textScaler: TextScaler.linear(escalaTexto),
      ),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: ancho,
              child: ListaProductosLocal(
                local: _local,
                productos: [
                  _producto('Empanada', 'Recién hecha'),
                  _producto(
                    'Empanada de carne cortada a cuchillo con papa',
                    'Una descripción bastante larga que debería recortarse sola',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('en un teléfono angosto no se desborda', (tester) async {
    await _dibujar(tester, ancho: 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en un teléfono ancho tampoco', (tester) async {
    // Este es el caso que el alto fijo de antes no cubría: mas ancho de
    // columna significa foto mas alta, y el texto se quedaba sin sitio.
    await _dibujar(tester, ancho: 500);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en tableta, con tres y cuatro columnas', (tester) async {
    await _dibujar(tester, ancho: 700);
    expect(tester.takeException(), isNull);
    await _dibujar(tester, ancho: 900);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con la letra del sistema agrandada, en todo el rango', (
    tester,
  ) async {
    for (final escala in [1.25, 1.5, 1.75, 2.0]) {
      await _dibujar(tester, ancho: 360, escalaTexto: escala);
      expect(tester.takeException(), isNull, reason: 'se desborda a $escala');
    }
  });
}
