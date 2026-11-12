import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/categoria_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/local_universitario.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/publicidad.dart';

/// El inicio bajaba solo las 120 publicaciones mas recientes: lo anterior no
/// se podia ver ni buscar. Ahora "cargar mas" trae la tanda siguiente y el
/// buscador tambien le pregunta a la base.
void main() {
  late _CatalogoFalso repositorio;
  late ControladorInicioMarketplace controlador;

  Future<void> cargar(WidgetTester tester) async {
    final carga = controlador.cargar();
    await tester.pump(const Duration(seconds: 1));
    await carga;
  }

  setUp(() {
    repositorio = _CatalogoFalso(250);
    controlador = ControladorInicioMarketplace(repositorio);
  });

  tearDown(() => controlador.dispose());

  testWidgets('cargar mas sigue en el servidor cuando se acaba lo bajado', (
    tester,
  ) async {
    await cargar(tester);
    expect(repositorio.pedidas, [0]);

    var vueltas = 0;
    while (controlador.hayMasPublicaciones && vueltas++ < 100) {
      controlador.cargarMasPublicaciones();
      await tester.pump();
    }

    final ids = [for (final p in controlador.estado.publicaciones) p.id];
    expect(ids, hasLength(250), reason: 'todo el catalogo, sin repetir');
    expect(ids.toSet(), hasLength(250));
    expect(repositorio.pedidas, [0, 120, 240]);
  });

  testWidgets(
    'una categoria que no esta en lo bajado se busca en el servidor',
    (tester) async {
      await cargar(tester);

      controlador.seleccionarCategoria('libros');
      await tester.pump();

      final libros = controlador.estado.publicaciones;
      expect(libros, isNotEmpty);
      expect(libros.every((p) => p.categoriaId == 'libros'), isTrue);
    },
  );

  testWidgets('el buscador encuentra lo que no esta en lo bajado', (
    tester,
  ) async {
    await cargar(tester);
    expect(
      controlador.resultadosBusqueda.where((p) => p.nombre == 'Mesa antigua'),
      isEmpty,
    );

    for (final texto in ['m', 'me', 'mes', 'mesa', 'mesa ant']) {
      controlador.buscar(texto);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(ControladorInicioMarketplace.esperaBusqueda);

    expect(repositorio.busquedas, [
      'mesa ant',
    ], reason: 'una, al dejar de escribir');
    expect(
      controlador.resultadosBusqueda.where((p) => p.nombre == 'Mesa antigua'),
      hasLength(1),
    );
  });
}

const _local = LocalUniversitario(
  id: 'l1',
  nombre: 'Tienda del campus',
  categoriaId: 'comida',
  categoria: 'Comida',
  descripcion: '',
  calificacion: 4.5,
  tiempoEstimado: '10 min',
  estaAbierto: true,
  costoEntrega: 0,
  emoji: '🛍️',
  colorHexadecimal: 0xFFFFAA00,
);

/// [total] publicaciones, de la mas reciente a la mas vieja. Solo las 30 mas
/// viejas son libros, y la ultima es una mesa antigua.
class _CatalogoFalso extends RepositorioInicioMarketplace {
  _CatalogoFalso(int total)
    : _catalogo = [
        for (var i = 0; i < total; i++)
          ProductoMarketplace(
            id: 'p$i',
            localId: 'l1',
            nombre: i == total - 1 ? 'Mesa antigua' : 'Cosa $i',
            descripcion: '',
            precio: 10,
            emoji: '🛍️',
            stock: 1,
            categoriaId: i >= total - 30 ? 'libros' : 'varios',
            local: _local,
          ),
      ];

  final List<ProductoMarketplace> _catalogo;

  /// Desde donde se pidio cada tanda.
  final pedidas = <int>[];

  /// Lo que se le pregunto al buscador de la base.
  final busquedas = <String>[];

  @override
  Future<({List<ProductoMarketplace> publicaciones, int filas})>
  obtenerPublicaciones({
    int desde = 0,
    int cantidad = RepositorioInicioMarketplace.tandaPublicaciones,
  }) async {
    pedidas.add(desde);
    final tanda = _catalogo.skip(desde).take(cantidad).toList();
    return (publicaciones: tanda, filas: tanda.length);
  }

  @override
  Future<List<ProductoMarketplace>> buscarPublicaciones(
    String texto, {
    int cantidad = 60,
  }) async {
    busquedas.add(texto);
    return [
      for (final p in _catalogo)
        if (p.nombre.toLowerCase().contains(texto)) p,
    ].take(cantidad).toList();
  }

  @override
  Future<List<CategoriaMarketplace>> obtenerCategorias() async => const [];

  @override
  Future<List<ProductoMarketplace>> obtenerPublicacionesPopulares() async =>
      const [];

  @override
  Future<List<LocalUniversitario>> obtenerLocalesMasVistos() async => const [];

  @override
  Future<List<Publicidad>> obtenerPublicidad() async => const [];
}
