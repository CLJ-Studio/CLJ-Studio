import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/categoria_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/local_universitario.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/publicidad.dart';

/// El inicio se redibujaba cada pocos segundos aunque nada visible cambiara:
/// tres escuchas avisando por separado, un sondeo que corria siempre, y cada
/// visita a una publicacion contaba como cambio. Esto fija el arreglo.
void main() {
  late _RepositorioFalso repositorio;
  late ControladorInicioMarketplace controlador;
  late int redibujos;

  Future<void> cargar(WidgetTester tester) async {
    final carga = controlador.cargar();
    await tester.pump(const Duration(seconds: 1));
    await carga;
    redibujos = 0;
    repositorio.consultas = 0;
  }

  setUp(() {
    repositorio = _RepositorioFalso();
    controlador = ControladorInicioMarketplace(repositorio);
    redibujos = 0;
    controlador.addListener(() => redibujos++);
  });

  tearDown(() => controlador.dispose());

  testWidgets('muchos avisos seguidos son una sola recarga', (tester) async {
    await cargar(tester);

    controlador
      ..simularAviso()
      ..simularAviso()
      ..simularAviso();
    await tester.pump(Duration.zero);

    expect(repositorio.consultas, 1);
  });

  testWidgets('una visita sumada no redibuja el inicio', (tester) async {
    await cargar(tester);

    repositorio.productos = [_producto(vistas: 999)];
    controlador.simularAviso();
    await tester.pump(Duration.zero);

    expect(repositorio.consultas, 1);
    expect(redibujos, 0);
  });

  testWidgets('un cambio visible si redibuja', (tester) async {
    await cargar(tester);

    repositorio.productos = [_producto(precio: 12)];
    controlador.simularAviso();
    await tester.pump(Duration.zero);

    expect(redibujos, 1);
    expect(controlador.estado.publicaciones.single.precio, 12);
  });

  testWidgets('cerrar el local se ve, aunque sea un dato del local', (
    tester,
  ) async {
    await cargar(tester);

    repositorio.productos = [_producto(abierto: false)];
    controlador.simularAviso();
    await tester.pump(Duration.zero);

    expect(redibujos, 1);
  });

  testWidgets('la segunda recarga espera la pausa', (tester) async {
    await cargar(tester);

    controlador.simularAviso();
    await tester.pump(Duration.zero);
    expect(repositorio.consultas, 1);

    controlador.simularAviso();
    await tester.pump(const Duration(seconds: 2));
    expect(repositorio.consultas, 1, reason: 'todavia dentro de la pausa');

    await tester.pump(ControladorInicioMarketplace.pausaEntreRecargas);
    expect(repositorio.consultas, 2);
  });

  testWidgets('un aviso que llega durante una recarga no se pierde', (
    tester,
  ) async {
    await cargar(tester);

    final enCamino = Completer<void>();
    repositorio.retener = enCamino;
    controlador.simularAviso();
    await tester.pump(Duration.zero);
    expect(repositorio.consultas, 1);

    // El vendedor cambia el precio mientras la recarga anterior viaja.
    controlador.simularAviso();
    repositorio
      ..retener = null
      ..productos = [_producto(precio: 15)];
    enCamino.complete();
    await tester.pump(Duration.zero);
    await tester.pump(ControladorInicioMarketplace.pausaEntreRecargas);

    expect(repositorio.consultas, 2);
    expect(controlador.estado.publicaciones.single.precio, 15);
  });

  testWidgets('despues de cerrar la pantalla no se recarga nada', (
    tester,
  ) async {
    await cargar(tester);
    final otro = ControladorInicioMarketplace(repositorio);
    otro.dispose();

    otro.simularAviso();
    await tester.pump(ControladorInicioMarketplace.pausaEntreRecargas);

    expect(repositorio.consultas, 0);
  });
}

const _local = LocalUniversitario(
  id: 'l1',
  nombre: 'Salteñas Doña Rosa',
  categoriaId: 'comida',
  categoria: 'Comida',
  descripcion: '',
  calificacion: 4.5,
  tiempoEstimado: '10 min',
  estaAbierto: true,
  costoEntrega: 0,
  emoji: '🥟',
  colorHexadecimal: 0xFFFFAA00,
);

ProductoMarketplace _producto({
  double precio = 10,
  int vistas = 3,
  bool abierto = true,
}) => ProductoMarketplace(
  id: 'p1',
  localId: 'l1',
  nombre: 'Salteña de pollo',
  descripcion: 'Jugosa',
  precio: precio,
  emoji: '🥟',
  stock: 5,
  vistas: vistas,
  local: abierto
      ? _local
      : const LocalUniversitario(
          id: 'l1',
          nombre: 'Salteñas Doña Rosa',
          categoriaId: 'comida',
          categoria: 'Comida',
          descripcion: '',
          calificacion: 4.5,
          tiempoEstimado: '10 min',
          estaAbierto: false,
          costoEntrega: 0,
          emoji: '🥟',
          colorHexadecimal: 0xFFFFAA00,
        ),
);

class _RepositorioFalso extends RepositorioInicioMarketplace {
  _RepositorioFalso();

  List<ProductoMarketplace> productos = [_producto()];
  int consultas = 0;

  /// Si no es nulo, la consulta no termina hasta que se complete.
  Completer<void>? retener;

  @override
  Future<List<CategoriaMarketplace>> obtenerCategorias() async => const [];

  @override
  Future<List<ProductoMarketplace>> obtenerPublicaciones() async {
    consultas++;
    // Lo que habia al salir la consulta, aunque cambie mientras viaja.
    final respuesta = List.of(productos);
    final espera = retener;
    if (espera != null) await espera.future;
    return respuesta;
  }

  @override
  Future<List<ProductoMarketplace>> obtenerPublicacionesPopulares() async =>
      const [];

  @override
  Future<List<LocalUniversitario>> obtenerLocalesMasVistos() async => const [];

  @override
  Future<List<Publicidad>> obtenerPublicidad() async => const [];
}
