import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/onboarding_usuario/datos/repositorio_onboarding.dart';
import 'package:upsa_eat/funcionalidades/onboarding_usuario/logica/controlador_onboarding.dart';
import 'package:upsa_eat/funcionalidades/onboarding_usuario/modelos/borrador_onboarding.dart';
import 'package:upsa_eat/funcionalidades/onboarding_usuario/modelos/carrera_upsa.dart';
import 'package:upsa_eat/funcionalidades/onboarding_usuario/pantalla/pantalla_onboarding.dart';

/// El perfil recien creado de alguien del personal: en el nombre solo esta
/// la parte del correo.
class _RepositorioFalso extends RepositorioOnboarding {
  _RepositorioFalso({required this.esCuentaUpsa});

  final bool esCuentaUpsa;
  final enviados = <String>[];

  @override
  Future<({String? nombre, bool esCuentaUpsa})> cargarPerfilInicial() async =>
      (nombre: 'josebenavente', esCuentaUpsa: esCuentaUpsa);

  @override
  Future<List<CarreraUpsa>> cargarCarreras() async => const [
    CarreraUpsa(
      id: 'ing-sistemas',
      nombre: 'Ing. de Sistemas',
      facultad: 'FIN',
    ),
  ];

  @override
  Future<void> completar(BorradorOnboarding borrador) async =>
      enviados.add('estudiante');

  @override
  Future<void> completarUpsa(BorradorOnboarding borrador) async => enviados.add(
    'upsa: ${borrador.nombreCompleto} | ${borrador.area} | '
    '${borrador.whatsappNormalizado}',
  );
}

Future<ControladorOnboarding> _abrir(
  WidgetTester tester,
  _RepositorioFalso repo,
  VoidCallback alCompletar,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controlador = ControladorOnboarding(repo);
  addTearDown(controlador.dispose);
  await controlador.cargarDatosIniciales();
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaOnboarding(
        controlador: controlador,
        alCompletar: alCompletar,
      ),
    ),
  );
  await tester.pump();
  return controlador;
}

void main() {
  testWidgets('el personal pone su area, no una carrera', (tester) async {
    final repo = _RepositorioFalso(esCuentaUpsa: true);
    var completo = false;
    await _abrir(tester, repo, () => completo = true);

    expect(find.text('Área o unidad'), findsOneWidget);
    expect(find.text('Carrera'), findsNothing);
    // La parte del correo no pasa por un nombre: el campo esta vacio y se
    // puede escribir.
    expect(find.text('josebenavente'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre completo'),
      'Jose Benavente',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Área o unidad'),
      'Incubadora de Empresas',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'WhatsApp'),
      '70012345',
    );
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump();

    expect(repo.enviados, [
      'upsa: Jose Benavente | Incubadora de Empresas | 70012345',
    ]);
    expect(completo, isTrue);
  });

  testWidgets('a un estudiante le sigue pidiendo la carrera', (tester) async {
    await _abrir(tester, _RepositorioFalso(esCuentaUpsa: false), () {});
    expect(find.text('Carrera'), findsOneWidget);
    expect(find.text('Área o unidad'), findsNothing);
  });
}
