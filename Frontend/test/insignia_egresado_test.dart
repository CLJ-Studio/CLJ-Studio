import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/insignias/insignia_egresado.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_poker.dart';
import 'package:upsa_eat/funcionalidades/configuracion_usuario/modelos/usuario_upsa.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/categoria_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/local_universitario.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/publicidad.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/pantalla/pantalla_inicio_marketplace.dart';
import 'package:upsa_eat/funcionalidades/pedidos/modelos/pedido.dart';

// Sin el espaciado del tema, para medir el nombre igual que se dibuja.
const _estilo18 = TextStyle(fontSize: 18, letterSpacing: 0);

/// Los egresados que verifico un admin llevan una insignia dorada junto al
/// nombre, como la de Instagram, donde sea que aparezca. Solo ellos: pedirla
/// no basta.
void main() {
  Widget enCaja(Widget hijo, {double ancho = 360}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: ancho, child: hijo),
      ),
    ),
  );

  group('NombreConInsignia', () {
    testWidgets('sin la marca es solo el nombre', (tester) async {
      await tester.pumpWidget(
        enCaja(const NombreConInsignia('Ana Pérez', egresado: false)),
      );

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.byType(InsigniaEgresado), findsNothing);
    });

    testWidgets('egresado verificado: el sello dorado, a la derecha', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        enCaja(
          const NombreConInsignia(
            'Ana Pérez',
            egresado: true,
            estilo: _estilo18,
          ),
        ),
      );

      final sello = find.byType(InsigniaEgresado);
      expect(sello, findsOneWidget);
      final icono = tester.widget<Icon>(
        find.descendant(of: sello, matching: find.byType(Icon)),
      );
      expect(icono.icon, Icons.verified_rounded);
      expect(icono.color, InsigniaEgresado.dorado);
      // Crece con la letra: junto a un titulo grande no queda como un punto.
      expect(tester.getSize(sello).width, closeTo(18 * 1.05, .01));
      // Justo despues del nombre, con su respiro.
      final medida = TextPainter(
        text: const TextSpan(text: 'Ana Pérez', style: _estilo18),
        textDirection: TextDirection.ltr,
      )..layout();
      addTearDown(medida.dispose);
      final nombre = tester.getRect(find.byType(NombreConInsignia));
      expect(
        tester.getRect(sello).left - nombre.left,
        closeTo(medida.width + 18 * 1.05 * .2, 1),
      );
      // Quien usa lector de pantalla la oye junto con el nombre.
      expect(
        find.bySemanticsLabel(RegExp(r'^Ana\W+Pérez\W+Egresado verificado$')),
        findsOneWidget,
      );
      semantica.dispose();
    });

    testWidgets('en varias lineas va pegada a la ultima palabra', (
      tester,
    ) async {
      const estilo = TextStyle(fontSize: 20, letterSpacing: 0);
      final medida = TextPainter(
        text: const TextSpan(text: 'Ana Pérez', style: estilo),
        textDirection: TextDirection.ltr,
      )..layout();
      addTearDown(medida.dispose);

      // Entra el nombre, pero no el nombre con la insignia: suelta, la
      // insignia bajaba sola al segundo renglon.
      await tester.pumpWidget(
        enCaja(
          const NombreConInsignia('Ana Pérez', egresado: true, estilo: estilo),
          ancho: medida.width + 2,
        ),
      );

      final nombre = tester.getRect(find.byType(NombreConInsignia));
      final sello = tester.getRect(find.byType(InsigniaEgresado));
      final ultima = tester.getRect(find.textContaining('Pérez'));
      expect(nombre.height, greaterThan(medida.height * 1.5));
      // "Pérez" bajo con ella, y la insignia va despues, no al principio.
      expect(ultima.top, greaterThan(nombre.top + medida.height / 2));
      expect(sello.center.dy, greaterThan(nombre.center.dy));
      expect(sello.left - nombre.left, greaterThan(20 * 3));
    });

    testWidgets('en una linea, el nombre se corta antes que la insignia', (
      tester,
    ) async {
      const nombre = 'María Fernanda de los Ángeles Gutiérrez Saavedra';
      await tester.pumpWidget(
        enCaja(
          const NombreConInsignia(
            nombre,
            egresado: true,
            maxLines: 1,
            estilo: TextStyle(fontSize: 18),
          ),
          ancho: 160,
        ),
      );

      expect(tester.takeException(), isNull);
      final caja = tester.getRect(find.byType(NombreConInsignia));
      final sello = tester.getRect(find.byType(InsigniaEgresado));
      final texto = tester.getRect(find.text(nombre));
      expect(sello.width, closeTo(18 * 1.05, .01));
      expect(sello.right, lessThanOrEqualTo(caja.right + .01));
      expect(
        tester.widget<Text>(find.text(nombre)).overflow,
        TextOverflow.ellipsis,
      );
      // Justo despues de los "…", sin un hueco en el medio.
      expect(sello.left - texto.right, closeTo(18 * .25, .5));
    });

    testWidgets('en una linea crece con la letra del sistema', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: enCaja(
            const NombreConInsignia(
              'Ana',
              egresado: true,
              maxLines: 1,
              estilo: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(InsigniaEgresado)).width,
        closeTo(16 * 1.5 * 1.05, .01),
      );
    });

    testWidgets('en varias lineas crece con la letra una sola vez', (
      tester,
    ) async {
      const estilo = TextStyle(fontSize: 16, letterSpacing: 0);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: enCaja(
            const NombreConInsignia(
              'Ana Pérez',
              egresado: true,
              estilo: estilo,
            ),
          ),
        ),
      );

      final palabra = TextPainter(
        text: const TextSpan(text: 'Pérez', style: estilo),
        textDirection: TextDirection.ltr,
      )..layout();
      addTearDown(palabra.dispose);
      expect(
        tester.getRect(find.byType(InsigniaEgresado)).width,
        closeTo(16 * 1.05 * 1.5, .01),
      );
      // La pieza entera, como el resto del texto: escalada dos veces
      // quedaba mas grande que "Ana".
      expect(
        tester.getRect(find.textContaining('Pérez')).width,
        closeTo((palabra.width + 16 * 1.05 * 1.3) * 1.5, 1),
      );
    });

    testWidgets('dentro de un texto que sigue', (tester) async {
      const estilo = TextStyle(fontSize: 12);
      Widget linea(bool egresado) => enCaja(
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'De '),
              ...nombreConInsigniaEnTexto(
                'Ana Pérez',
                egresado: egresado,
                estilo: estilo,
              ),
              const TextSpan(text: ' · Derecho'),
            ],
          ),
          style: estilo,
        ),
      );

      await tester.pumpWidget(linea(true));
      expect(find.byType(InsigniaEgresado), findsOneWidget);

      // Sin la marca queda el mismo texto de siempre.
      await tester.pumpWidget(linea(false));
      expect(find.text('De Ana Pérez · Derecho'), findsOneWidget);
      expect(find.byType(InsigniaEgresado), findsNothing);
    });
  });

  group('de donde sale la marca', () {
    test('el local dice si quien vende es egresado verificado', () {
      final conMarca = LocalUniversitario.desdeMapa({
        'id': 'l1',
        'name': 'Ana Pérez',
        'vendedor_egresado': true,
      });
      expect(conMarca.vendedorEgresado, isTrue);
      expect(conMarca.copiarCon(vistas: 9).vendedorEgresado, isTrue);

      // Sin la migracion 60 la columna no llega: sin insignia y sin fallar.
      expect(
        LocalUniversitario.desdeMapa({
          'id': 'l2',
          'name': 'Beto',
        }).vendedorEgresado,
        isFalse,
      );
    });

    test('el pedido dice cual de los dos es egresado', () {
      Map<String, dynamic> fila(Map<String, dynamic> marcas) => {
        'id': 'o1',
        'status': 'solicitado',
        'buyer_id': 'c1',
        'seller_id': 'v1',
        'store_id': 'l1',
        'created_at': '2026-10-18T12:00:00Z',
        'expires_at': '2026-10-18T12:30:00Z',
        ...marcas,
      };

      final pedido = Pedido.desdeMapa(
        fila({'buyer_egresado': true, 'seller_egresado': false}),
      );
      expect(pedido.compradorEgresado, isTrue);
      expect(pedido.vendedorEgresado, isFalse);

      final sinColumnas = Pedido.desdeMapa(fila(const {}));
      expect(sinColumnas.compradorEgresado, isFalse);
      expect(sinColumnas.vendedorEgresado, isFalse);
    });

    test('cada asiento del poker dice si es egresado', () {
      final mesa = EstadoMesaPoker.desdeMapa({
        'sala': {'id': 's1', 'nombre': 'Mesa de Ana'},
        'asientos': [
          {
            'posicion': 0,
            'usuario_id': 'u1',
            'nombre': 'Ana Pérez',
            'fichas': 1000,
            'egresado': true,
          },
          {
            'posicion': 1,
            'usuario_id': 'u2',
            'nombre': 'Beto Rojas',
            'fichas': 1000,
          },
        ],
      });

      expect(mesa.asiento(0)!.egresado, isTrue);
      expect(mesa.asiento(1)!.egresado, isFalse);
    });

    test('el perfil propio la lleva solo con la marca aprobada', () {
      UsuarioUpsa perfil(Map<String, dynamic> egresado) =>
          UsuarioUpsa.desdeMapa({'full_name': 'Ana Pérez', ...egresado});

      expect(
        perfil({
          'es_egresado': true,
          'egresado_pedido_en': null,
        }).esEgresadoVerificado,
        isTrue,
      );
      // Pedirla no basta: la aprueba un admin.
      expect(
        perfil({
          'es_egresado': false,
          'egresado_pedido_en': '2026-10-18T12:00:00Z',
        }).esEgresadoVerificado,
        isFalse,
      );
      expect(perfil(const {}).esEgresadoVerificado, isFalse);
    });
  });

  testWidgets('en el buscador la persona egresada sale con la insignia', (
    tester,
  ) async {
    final controlador = ControladorInicioMarketplace(_RepositorioFalso());
    addTearDown(controlador.dispose);
    final carga = controlador.cargar();
    await tester.pump(const Duration(seconds: 1));
    await carga;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PantallaInicioMarketplace(controlador: controlador),
        ),
      ),
    );
    controlador.buscar('ana');
    await tester.pump(const Duration(milliseconds: 300));

    Finder resultado(String subtitulo) => find.ancestor(
      of: find.text(subtitulo),
      matching: find.byType(ListTile),
    );

    expect(resultado('Egresado verificado'), findsOneWidget);
    // "Pérez" va en una pieza con la insignia, para que bajen juntas.
    for (final parte in ['Ana ', 'Pérez']) {
      expect(
        find.descendant(
          of: resultado('Egresado verificado'),
          matching: find.textContaining(parte),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: resultado('Egresado verificado'),
        matching: find.byType(InsigniaEgresado),
      ),
      findsOneWidget,
    );
    // Anabel tambien vende, pero nadie verifico que egreso.
    expect(
      find.descendant(
        of: resultado('Persona'),
        matching: find.text('Anabel Rojas'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: resultado('Persona'),
        matching: find.byType(InsigniaEgresado),
      ),
      findsNothing,
    );
  });
}

LocalUniversitario _espacioDe(
  String id,
  String dueno, {
  required String duenoId,
  required bool egresado,
}) => LocalUniversitario(
  id: id,
  nombre: dueno,
  categoriaId: 'servicios',
  categoria: 'Servicios',
  descripcion: '',
  calificacion: 5,
  tiempoEstimado: '',
  estaAbierto: true,
  costoEntrega: 0,
  emoji: '📚',
  colorHexadecimal: 0xFFE6E1D5,
  esPersonal: true,
  vendedorNombre: dueno,
  vendedorEgresado: egresado,
  duenoId: duenoId,
);

class _RepositorioFalso extends RepositorioInicioMarketplace {
  _RepositorioFalso();

  @override
  Future<List<CategoriaMarketplace>> obtenerCategorias() async => const [];

  @override
  Future<List<ProductoMarketplace>> obtenerPublicaciones() async => [
    ProductoMarketplace(
      id: 'p1',
      localId: 'l1',
      nombre: 'Clases de cálculo',
      descripcion: 'Para el parcial',
      precio: 50,
      emoji: '📚',
      stock: 1,
      local: _espacioDe('l1', 'Ana Pérez', duenoId: 'u1', egresado: true),
    ),
    ProductoMarketplace(
      id: 'p2',
      localId: 'l2',
      nombre: 'Torta de chocolate',
      descripcion: 'Por porciones',
      precio: 12,
      emoji: '🍰',
      stock: 8,
      local: _espacioDe('l2', 'Anabel Rojas', duenoId: 'u2', egresado: false),
    ),
  ];

  @override
  Future<List<ProductoMarketplace>> obtenerPublicacionesPopulares() async =>
      const [];

  @override
  Future<List<LocalUniversitario>> obtenerLocalesMasVistos() async => const [];

  @override
  Future<List<Publicidad>> obtenerPublicidad() async => const [];
}
