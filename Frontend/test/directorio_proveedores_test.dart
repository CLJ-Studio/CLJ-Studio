import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/configuracion_usuario/modelos/usuario_upsa.dart';
import 'package:upsa_eat/funcionalidades/directorio_proveedores/datos/repositorio_directorio.dart';
import 'package:upsa_eat/funcionalidades/directorio_proveedores/diseno/editor_oferta_upsa.dart';
import 'package:upsa_eat/funcionalidades/directorio_proveedores/modelos/proveedor_upsa.dart';
import 'package:upsa_eat/funcionalidades/directorio_proveedores/modelos/solicitud_egresado.dart';
import 'package:upsa_eat/funcionalidades/directorio_proveedores/pantalla/pantalla_directorio_proveedores.dart';
import 'package:upsa_eat/funcionalidades/directorio_proveedores/pantalla/pantalla_solicitudes_egresado.dart';
import 'package:upsa_eat/funcionalidades/notificaciones/modelos/notificacion.dart';
import 'package:upsa_eat/funcionalidades/onboarding_usuario/modelos/borrador_onboarding.dart';

/// Tal como llega una fila de directorio_proveedores().
Map<String, dynamic> _fila({
  required String id,
  required String nombre,
  String descripcion = '',
  String? oferta,
  String categoriaId = 'comida',
  String categoria = 'Comida',
  bool egresado = false,
  String whatsapp = '59170012345',
  String dueno = 'Ana Pérez',
  String? carrera = 'Ingeniería Comercial',
}) => {
  'local_id': id,
  'nombre': nombre,
  'descripcion': descripcion,
  'oferta': oferta,
  'categoria_id': categoriaId,
  'categoria': categoria,
  'emoji': '🍰',
  'logo_path': null,
  'color_hex': 4294962902,
  'es_personal': false,
  'dueno': dueno,
  'carrera': carrera,
  'es_egresado': egresado,
  'anio_ingreso': egresado ? 2004 : 2023,
  'whatsapp': whatsapp,
  'calificacion': 4.8,
  'calificaciones': 12,
  'publicaciones': 3,
  'desde': '2026-09-01T12:00:00Z',
};

final _proveedores = [
  ProveedorUpsa.desdeMapa(
    _fila(
      id: 'l1',
      nombre: 'Bocaditos Ana',
      oferta: 'Catering para eventos de la universidad',
      egresado: true,
    ),
  ),
  ProveedorUpsa.desdeMapa(
    _fila(
      id: 'l2',
      nombre: 'Imprenta Rápida',
      descripcion: 'Impresiones y anillados',
      categoriaId: 'servicios',
      categoria: 'Servicios',
      dueno: 'Luis Rojas',
      carrera: null,
    ),
  ),
  ProveedorUpsa.desdeMapa(
    _fila(
      id: 'l3',
      nombre: 'Diseño Pixel',
      oferta: 'Diseño de logos y afiches',
      categoriaId: 'servicios',
      categoria: 'Servicios',
      whatsapp: '',
    ),
  ),
];

class _RepositorioFalso extends RepositorioDirectorio {
  _RepositorioFalso({
    this.proveedores = const [],
    this.fallar = 0,
    this.oferta,
  });

  final List<ProveedorUpsa> proveedores;

  /// Cuantas veces falla antes de contestar.
  int fallar;
  OfertaUpsa? oferta;
  final guardadas = <OfertaUpsa>[];
  List<SolicitudEgresado> solicitudes = const [];
  final resueltas = <String>[];

  @override
  Future<List<SolicitudEgresado>> solicitudesEgresado() async {
    if (fallar > 0) {
      fallar--;
      throw Exception('sin red');
    }
    return solicitudes;
  }

  @override
  Future<void> resolverEgresado(
    String usuarioId, {
    required bool aprobar,
  }) async => resueltas.add('$usuarioId:${aprobar ? 'si' : 'no'}');

  @override
  Future<List<ProveedorUpsa>> cargar() async {
    if (fallar > 0) {
      fallar--;
      throw Exception('sin red');
    }
    return proveedores;
  }

  @override
  Future<OfertaUpsa?> cargarOfertaPropia() async => oferta;

  @override
  Future<void> guardarOfertaPropia(OfertaUpsa oferta) async =>
      guardadas.add(oferta);
}

Future<void> _abrirDirectorio(
  WidgetTester tester,
  RepositorioDirectorio repo, {
  List<Uri>? enlaces,
  List<String>? locales,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaDirectorioProveedores(
        repositorio: repo,
        abrirWhatsapp: (enlace) async {
          enlaces?.add(enlace);
          return true;
        },
        abrirLocal: (_, id) async => locales?.add(id),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('el proveedor', () {
    test('muestra lo que le ofrece a la UPSA, o su descripcion', () {
      expect(
        _proveedores[0].queOfrece,
        'Catering para eventos de la universidad',
      );
      expect(_proveedores[1].queOfrece, 'Impresiones y anillados');
      expect(_proveedores[0].tipo, 'Egresado');
      expect(_proveedores[1].tipo, 'Estudiante');
    });

    test('se busca sin tildes y con palabras de campos distintos', () {
      expect(_proveedores[2].coincideCon('diseno'), isTrue);
      expect(_proveedores[1].coincideCon('IMPRESIONES'), isTrue);
      expect(_proveedores[0].coincideCon('catering egresado'), isTrue);
      expect(_proveedores[1].coincideCon('catering'), isFalse);
      expect(_proveedores[0].coincideCon('  '), isTrue);
    });

    test('el WhatsApp abre con un saludo ya escrito', () {
      final enlace = _proveedores[0].enlaceWhatsapp!;
      expect(enlace.host, 'wa.me');
      expect(enlace.path, '/59170012345');
      expect(enlace.queryParameters['text'], contains('Bocaditos Ana'));
      expect(_proveedores[2].enlaceWhatsapp, isNull);
    });
  });

  group('el perfil sin la migracion aplicada', () {
    test('carga igual, como estudiante y sin la opcion de egresado', () {
      final perfil = UsuarioUpsa.desdeMapa({
        'full_name': 'Ana Perez',
        'email': 'a2024110000@estudiantes.upsa.edu.bo',
      });
      expect(perfil.esCuentaUpsa, isFalse);
      expect(perfil.estadoEgresado, isNull);
    });

    test('con la 55, trae el tipo; sin la 56 no ofrece pedir la marca', () {
      final perfil = UsuarioUpsa.desdeMapa({
        'full_name': 'Unidad Prueba',
        'tipo_cuenta': 'upsa',
        'es_egresado': false,
        'area_upsa': 'DABE',
      });
      expect(perfil.esCuentaUpsa, isTrue);
      expect(perfil.estadoEgresado, isNull);
      expect(perfil.areaUpsa, 'DABE');
    });

    test('con la 56, sabe en que punto esta la marca de egresado', () {
      EstadoEgresado? estado(Map<String, dynamic> fila) =>
          UsuarioUpsa.desdeMapa({
            'full_name': 'Ana Perez',
            'es_egresado': false,
            'egresado_pedido_en': null,
            'egresado_rechazado_en': null,
            ...fila,
          }).estadoEgresado;

      expect(estado({}), EstadoEgresado.sinPedir);
      expect(
        estado({'egresado_pedido_en': '2026-10-18T10:00:00Z'}),
        EstadoEgresado.enRevision,
      );
      expect(
        estado({'egresado_rechazado_en': '2026-10-18T10:00:00Z'}),
        EstadoEgresado.rechazado,
      );
      expect(estado({'es_egresado': true}), EstadoEgresado.verificado);
    });
  });

  group('el registro inicial del personal', () {
    const base = BorradorOnboarding(
      nombreCompleto: 'Jose Benavente',
      whatsapp: '70012345',
      esCuentaUpsa: true,
    );

    test('pide area en vez de carrera', () {
      expect(base.error, 'Escribe tu área o unidad.');
      expect(base.copiarCon(area: 'Incubadora de Empresas').error, isNull);
    });

    test('a un estudiante le sigue pidiendo carrera', () {
      const estudiante = BorradorOnboarding(
        nombreCompleto: 'Ana Perez',
        whatsapp: '70012345',
        area: 'Algo',
      );
      expect(estudiante.error, 'Selecciona tu carrera.');
    });
  });

  group('la pantalla del directorio', () {
    testWidgets('lista los proveedores y filtra por tipo y busqueda', (
      tester,
    ) async {
      await _abrirDirectorio(
        tester,
        _RepositorioFalso(proveedores: _proveedores),
      );

      expect(find.text('3 emprendimientos'), findsOneWidget);
      expect(find.text('Bocaditos Ana'), findsOneWidget);
      expect(find.text('Egresado'), findsWidgets);
      // El año de ingreso, que no se puede inventar.
      expect(find.textContaining('Ingresó en 2004'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Egresados'));
      await tester.pump();
      expect(find.text('1 emprendimiento'), findsOneWidget);
      expect(find.text('Imprenta Rápida'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'diseno');
      await tester.pump();
      expect(find.text('Diseño Pixel'), findsOneWidget);
      expect(find.text('Bocaditos Ana'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zapatos');
      await tester.pump();
      expect(find.textContaining('Ningún proveedor coincide'), findsOneWidget);
    });

    testWidgets('filtra por categoria', (tester) async {
      await _abrirDirectorio(
        tester,
        _RepositorioFalso(proveedores: _proveedores),
      );
      // La fila de filtros se desplaza de costado.
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Servicios'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Servicios'));
      await tester.pump();
      expect(find.text('2 emprendimientos'), findsOneWidget);
      expect(find.text('Bocaditos Ana'), findsNothing);
    });

    testWidgets('contacta por WhatsApp y abre el local', (tester) async {
      final enlaces = <Uri>[];
      final locales = <String>[];
      await _abrirDirectorio(
        tester,
        _RepositorioFalso(proveedores: _proveedores),
        enlaces: enlaces,
        locales: locales,
      );

      await tester.tap(find.text('Contactar').first);
      await tester.pump();
      expect(enlaces.single.path, '/59170012345');

      await tester.tap(find.text('Ver local').first);
      await tester.pump();
      expect(locales, ['l1']);

      // Sin WhatsApp el boton queda apagado.
      await tester.enterText(find.byType(TextField), 'pixel');
      await tester.pump();
      final boton = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Contactar'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(boton.onPressed, isNull);
    });

    testWidgets('sin proveedores explica como se aparece', (tester) async {
      await _abrirDirectorio(tester, _RepositorioFalso());
      expect(find.textContaining('Todavía no hay emprendimientos'), findsOne);
    });

    testWidgets('si falla, deja reintentar', (tester) async {
      final repo = _RepositorioFalso(proveedores: _proveedores, fallar: 1);
      await _abrirDirectorio(tester, repo);
      expect(find.text('No se pudo cargar el directorio.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('3 emprendimientos'), findsOneWidget);
    });
  });

  group('lo que el dueño elige mostrarle a la UPSA', () {
    Future<void> abrir(WidgetTester tester, RepositorioDirectorio repo) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EditorOfertaUpsa(repositorio: repo),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('sin negocio o sin migracion no muestra nada', (tester) async {
      await abrir(tester, _RepositorioFalso());
      expect(find.text('Directorio de la UPSA'), findsNothing);
    });

    testWidgets('activa, escribe y guarda', (tester) async {
      final repo = _RepositorioFalso(
        oferta: const OfertaUpsa(localId: 'l9', activa: false, texto: ''),
      );
      await abrir(tester, repo);

      expect(find.text('Directorio de la UPSA'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Catering para eventos');
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump();

      final guardada = repo.guardadas.single;
      expect(guardada.localId, 'l9');
      expect(guardada.activa, isTrue);
      expect(guardada.texto, 'Catering para eventos');
      expect(find.textContaining('aparece en el directorio'), findsOneWidget);
    });
  });

  group('los avisos de egresados', () {
    Notificacion aviso(String tipo) => Notificacion.desdeMapa({
      'id': 'n1',
      'type': tipo,
      'title': 'Nueva solicitud de egresado',
      'body': 'Ana Viva (Derecho, ingresó en 2004) pide que verifiquen.',
      'created_at': '2026-10-18T10:00:00Z',
    });

    test('la solicitud se abre aunque no lleve pedido ni local', () {
      expect(aviso('egresado_por_verificar').llevaAAlgunSitio, isTrue);
      expect(aviso('egresado_resuelto').llevaAAlgunSitio, isFalse);
    });

    test('tienen su icono', () {
      expect(
        aviso('egresado_por_verificar').icono,
        Icons.workspace_premium_outlined,
      );
      expect(
        aviso('egresado_resuelto').icono,
        Icons.workspace_premium_outlined,
      );
    });
  });

  group('las solicitudes de egresados', () {
    final solicitudes = [
      SolicitudEgresado.desdeMapa({
        'usuario_id': 'u1',
        'nombre': 'Ana Viva',
        'correo': 'a2004210000@estudiantes.upsa.edu.bo',
        'registro': 'a2004210000',
        'anio_ingreso': 2004,
        'carrera': 'Derecho',
        'pedido_en': '2026-10-18T10:00:00Z',
      }),
      SolicitudEgresado.desdeMapa({
        'usuario_id': 'u2',
        'nombre': 'Luis Nuevo',
        'correo': 'a2025110000@estudiantes.upsa.edu.bo',
        'registro': 'a2025110000',
        'anio_ingreso': 2025,
        'carrera': null,
        'pedido_en': null,
      }),
    ];

    Future<void> abrir(WidgetTester tester, _RepositorioFalso repo) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: PantallaSolicitudesEgresado(repositorio: repo)),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('muestra el año de ingreso y aprueba o rechaza', (
      tester,
    ) async {
      final repo = _RepositorioFalso()..solicitudes = solicitudes;
      await abrir(tester, repo);

      expect(find.text('Ana Viva'), findsOneWidget);
      expect(find.text('Derecho · Ingresó en 2004'), findsOneWidget);
      expect(find.text('Ingresó en 2025'), findsOneWidget);

      await tester.tap(find.text('Aprobar').first);
      await tester.pump();
      await tester.pump();
      expect(repo.resueltas, ['u1:si']);
      expect(find.text('Ana Viva'), findsNothing);
      expect(find.textContaining('ya figura como egresado'), findsOneWidget);

      await tester.tap(find.text('Rechazar'));
      await tester.pump();
      await tester.pump();
      expect(repo.resueltas, ['u1:si', 'u2:no']);
      expect(find.text('No hay solicitudes pendientes.'), findsOneWidget);
    });

    testWidgets('si falla, deja reintentar', (tester) async {
      final repo = _RepositorioFalso(fallar: 1)..solicitudes = solicitudes;
      await abrir(tester, repo);
      expect(find.text('No se pudieron cargar las solicitudes.'), findsOne);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Ana Viva'), findsOneWidget);
    });
  });
}
