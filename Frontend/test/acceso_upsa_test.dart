import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upsa_eat/funcionalidades/acceso_upsa/datos/repositorio_acceso_upsa.dart';
import 'package:upsa_eat/funcionalidades/acceso_upsa/datos/servicio_autenticacion_correo.dart';
import 'package:upsa_eat/funcionalidades/acceso_upsa/diseno/campo_codigo_verificacion.dart';
import 'package:upsa_eat/funcionalidades/acceso_upsa/pantalla/pantalla_acceso_upsa.dart';

const _registro = '2024111234';
const _correo = 'a2024111234@estudiantes.upsa.edu.bo';

/// Lo que mando el telefono de un amigo: el pedido salio, pero la respuesta
/// no volvio.
final _sinRed = AuthRetryableFetchException(
  message:
      'ClientException: Failed to fetch, '
      'uri=https://tujqaxohgpeoxxezbzzp.supabase.co/auth/v1/otp?',
);

/// Contesta lo que se le diga, sin salir a internet.
class _HttpFalso extends http.BaseClient {
  _HttpFalso(this.responder);

  final http.StreamedResponse Function(http.BaseRequest pedido) responder;
  final pedidos = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest pedido) async {
    pedidos.add(pedido);
    return responder(pedido);
  }
}

/// El cliente de Supabase de verdad, con la red de mentira: asi la prueba
/// pasa por el mismo codigo que convierte el fallo del navegador en error.
ServicioAutenticacionCorreo _servicioSobre(_HttpFalso red) =>
    ServicioAutenticacionCorreo(
      SupabaseClient(
        'https://tujqaxohgpeoxxezbzzp.supabase.co',
        'clave-de-prueba',
        httpClient: red,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
          autoRefreshToken: false,
        ),
      ),
    );

/// Como contesta el servidor de autenticacion de Supabase.
http.StreamedResponse _respuesta(int estado, Map<String, Object?> cuerpo) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(cuerpo))),
      estado,
      headers: {
        'content-type': 'application/json',
        'x-supabase-api-version': '2024-01-01',
      },
    );

/// Contesta en orden lo que se le pida; la ultima respuesta se repite.
class _RepositorioFalso extends RepositorioAccesoUpsa {
  _RepositorioFalso({
    this.envios = const [CodigoEnviado()],
    this.verificaciones = const [null],
  });

  final List<EnvioCodigo> envios;
  final List<FalloVerificacion?> verificaciones;
  final pedidos = <String>[];
  final verificados = <String>[];

  /// Si esta, el servidor no contesta hasta que se complete.
  Completer<void>? retener;

  @override
  Future<EnvioCodigo> enviarCodigo(String correo) async {
    pedidos.add(correo);
    await retener?.future;
    return envios[(pedidos.length - 1).clamp(0, envios.length - 1)];
  }

  @override
  Future<FalloVerificacion?> verificarCodigo({
    required String correo,
    required String codigo,
  }) async {
    verificados.add(codigo);
    return verificaciones[(verificados.length - 1).clamp(
      0,
      verificaciones.length - 1,
    )];
  }
}

Future<void> _abrir(WidgetTester tester, RepositorioAccesoUpsa repo) async {
  // Un telefono, no la ventana de 800x600 de las pruebas.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: PantallaAccesoUpsa(repositorio: repo)),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pedirCodigo(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), _registro);
  await tester.pump();
  await _tocar(tester, 'Enviarme el código');
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
}

/// El reintento automatico espera un momento antes de volver a pedir.
Future<void> _dejarReintentar(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1300));
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

Future<void> _escribirCodigo(WidgetTester tester, String codigo) async {
  await tester.enterText(find.byType(TextField), codigo);
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

bool _casillasEnRojo(WidgetTester tester) => tester
    .widget<CampoCodigoVerificacion>(find.byType(CampoCodigoVerificacion))
    .hayError;

VoidCallback? _reenviar(WidgetTester tester) => tester
    .widget<TextButton>(find.widgetWithText(TextButton, 'Reenviar código'))
    .onPressed;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('el numero de registro', () {
    test('acepta los formatos de verdad, tambien los de antes', () {
      // Hoy suele ir 11 o 12 despues del año; en 2004 tambien habia 21, y
      // los egresados de los 90 conservan su correo.
      for (final registro in [
        '2024110000',
        '2024120000',
        '2004219999',
        '1992110000',
        '1984120001',
      ]) {
        expect(
          ServicioAutenticacionCorreo.registroValido(registro),
          isTrue,
          reason: registro,
        );
      }
      expect(
        ServicioAutenticacionCorreo.normalizarCorreo('2004219999'),
        'a2004219999@estudiantes.upsa.edu.bo',
      );
    });

    test('corta lo que no puede ser un registro', () {
      for (final registro in [
        '8382848283',
        '1983110000',
        '${DateTime.now().year + 1}110000',
        '202411000',
        '20241100001',
        '',
      ]) {
        expect(
          ServicioAutenticacionCorreo.registroValido(registro),
          isFalse,
          reason: registro,
        );
      }
    });
  });

  group('el correo del personal', () {
    test('docentes y unidades entran con su correo de la UPSA', () {
      expect(
        ServicioAutenticacionCorreo.normalizarCorreoPersonal('josebenavente'),
        'josebenavente@upsa.edu.bo',
      );
      expect(
        ServicioAutenticacionCorreo.normalizarCorreoPersonal('DABE'),
        'dabe@upsa.edu.bo',
      );
      expect(
        ServicioAutenticacionCorreo.normalizarCorreoPersonal(
          ' jmguerra@upsa.edu.bo ',
        ),
        'jmguerra@upsa.edu.bo',
      );
    });

    test('no deja colar otro dominio ni algo que no es un correo', () {
      for (final entrada in [
        'a2024110000@estudiantes.upsa.edu.bo',
        'alguien@gmail.com',
        'jose benavente',
        'x',
        '.jose',
        '',
      ]) {
        expect(
          ServicioAutenticacionCorreo.normalizarCorreoPersonal(entrada),
          isNull,
          reason: entrada,
        );
      }
    });
  });

  group('lo que significa cada respuesta del servidor', () {
    test('un corte de red no se sabe si mando el correo', () {
      expect(
        ServicioAutenticacionCorreo.clasificarEnvio(_sinRed),
        isA<EnvioSinConfirmar>().having((e) => e.porRed, 'porRed', isTrue),
      );
    });

    test('un 500 tampoco confirma ni niega el envio', () {
      final fallo = AuthRetryableFetchException(
        message:
            '{"code":500,"error_code":"unexpected_failure",'
            '"msg":"Error sending magic link email"}',
        statusCode: '500',
      );
      expect(
        ServicioAutenticacionCorreo.clasificarEnvio(fallo),
        isA<EnvioSinConfirmar>().having((e) => e.porRed, 'porRed', isFalse),
      );
    });

    test('si frena por pedirlo seguido, es que ya salio uno', () {
      const fallo = AuthApiException(
        'For security purposes, you can only request this after 42 seconds.',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      );
      expect(
        ServicioAutenticacionCorreo.clasificarEnvio(fallo),
        isA<CodigoReciente>().having((e) => e.segundos, 'segundos', 42),
      );
    });

    test('el tope de correos por hora no pasa por un codigo reciente', () {
      const fallo = AuthApiException(
        'Email rate limit exceeded',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      );
      expect(
        ServicioAutenticacionCorreo.clasificarEnvio(fallo),
        isA<EnvioRechazado>().having(
          (e) => e.motivo,
          'motivo',
          contains('última hora'),
        ),
      );
    });

    test('un alta rechazada es un no, aunque llegue como 500', () {
      final fallo = AuthRetryableFetchException(
        message:
            '{"code":500,"error_code":"unexpected_failure",'
            '"msg":"Database error saving new user"}',
        statusCode: '500',
      );
      expect(
        ServicioAutenticacionCorreo.clasificarEnvio(fallo),
        isA<EnvioRechazado>(),
      );
    });

    test('ningun motivo muestra texto tecnico', () {
      final fallos = <AuthException>[
        _sinRed,
        const AuthApiException('DOMINIO_NO_INSTITUCIONAL: gmail.com no esta'),
        const AuthApiException('Signups not allowed for otp', code: 'x_y'),
        const AuthApiException('Email rate limit exceeded'),
        const AuthApiException(
          'Request rate limit reached',
          code: 'over_request_rate_limit',
        ),
        const AuthApiException('Signups not allowed', code: 'signup_disabled'),
      ];
      for (final fallo in fallos) {
        final resultado = ServicioAutenticacionCorreo.clasificarEnvio(fallo);
        if (resultado is! EnvioRechazado) continue;
        for (final tecnico in ['Exception', 'uri=', 'http', '{', 'allowed']) {
          expect(resultado.motivo, isNot(contains(tecnico)), reason: '$fallo');
        }
      }
      final verificacion = ServicioAutenticacionCorreo.clasificarVerificacion(
        _sinRed,
      );
      expect(verificacion.mensaje, isNot(contains('Exception')));
    });

    test('un codigo mal escrito no dice que caduco', () {
      // El servidor contesta igual para uno equivocado y para uno vencido.
      final fallo = ServicioAutenticacionCorreo.clasificarVerificacion(
        const AuthApiException(
          'Token has expired or is invalid',
          statusCode: '403',
          code: 'otp_expired',
        ),
      );
      expect(fallo.codigoMalo, isTrue);
      expect(fallo.mensaje, isNot(contains('caducó')));
      expect(fallo.mensaje, contains('último correo'));
    });

    test('un corte al verificar no culpa al codigo', () {
      final fallo = ServicioAutenticacionCorreo.clasificarVerificacion(_sinRed);
      expect(fallo.codigoMalo, isFalse);
      expect(fallo.mensaje, contains('conexión'));
    });
  });

  group('por el camino real del cliente de Supabase', () {
    test('el error del navegador del amigo no se toma como un no', () async {
      final red = _HttpFalso(
        (pedido) => throw http.ClientException('Failed to fetch', pedido.url),
      );
      final resultado = await _servicioSobre(red).enviarCodigo(_correo);

      expect(red.pedidos.single.url.path, '/auth/v1/otp');
      expect(
        resultado,
        isA<EnvioSinConfirmar>().having((e) => e.porRed, 'porRed', isTrue),
      );
    });

    test('pide el codigo para el correo del registro', () async {
      final red = _HttpFalso((_) => _respuesta(200, {}));
      final resultado = await _servicioSobre(red).enviarCodigo(_correo);

      expect(resultado, isA<CodigoEnviado>());
      final cuerpo = (red.pedidos.single as http.Request).body;
      expect(jsonDecode(cuerpo), containsPair('email', _correo));
    });

    test('el freno por pedirlo seguido se lee como codigo reciente', () async {
      final red = _HttpFalso(
        (_) => _respuesta(429, {
          'code': 'over_email_send_rate_limit',
          'message':
              'For security purposes, you can only request this after 37 '
              'seconds.',
        }),
      );
      expect(
        await _servicioSobre(red).enviarCodigo(_correo),
        isA<CodigoReciente>().having((e) => e.segundos, 'segundos', 37),
      );
    });

    test('un codigo equivocado se lee como codigo malo', () async {
      final red = _HttpFalso(
        (_) => _respuesta(403, {
          'code': 'otp_expired',
          'message': 'Token has expired or is invalid',
        }),
      );
      final fallo = await _servicioSobre(
        red,
      ).verificarCodigo(correo: _correo, codigo: '123456');

      expect(red.pedidos.single.url.path, '/auth/v1/verify');
      expect(fallo?.codigoMalo, isTrue);
    });

    test(
      'si la red se corta al verificar, el codigo no tiene la culpa',
      () async {
        final red = _HttpFalso(
          (pedido) => throw http.ClientException('Failed to fetch', pedido.url),
        );
        final fallo = await _servicioSobre(
          red,
        ).verificarCodigo(correo: _correo, codigo: '123456');

        expect(fallo?.codigoMalo, isFalse);
        expect(fallo?.mensaje, contains('conexión'));
      },
    );
  });

  group('la pantalla de acceso', () {
    testWidgets('si se corta la red, el codigo se puede escribir igual', (
      tester,
    ) async {
      final repo = _RepositorioFalso(
        envios: const [EnvioSinConfirmar(porRed: true)],
      );
      await _abrir(tester, repo);
      await _pedirCodigo(tester);
      await _dejarReintentar(tester);

      // Lo probo dos veces (el reintento automatico) y no volvio al
      // principio: el correo pudo haber salido.
      expect(repo.pedidos, [_correo, _correo]);
      expect(find.byType(CampoCodigoVerificacion), findsOneWidget);
      expect(find.text('Pedimos un código para'), findsOneWidget);
      expect(find.textContaining('Se cortó la conexión'), findsOneWidget);
      expect(find.textContaining('ClientException'), findsNothing);
      expect(_casillasEnRojo(tester), isFalse);
      expect(_reenviar(tester), isNotNull, reason: 'reenviar sin esperar');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('codigo_pendiente_correo'), _correo);
      expect(prefs.getBool('codigo_pendiente_confirmado'), isFalse);

      // El codigo que si llego al correo entra.
      await _escribirCodigo(tester, '123456');
      expect(repo.verificados, ['123456']);
    });

    testWidgets('un parpadeo de la red se reintenta solo', (tester) async {
      final repo = _RepositorioFalso(
        envios: const [EnvioSinConfirmar(porRed: true), CodigoEnviado()],
      );
      await _abrir(tester, repo);
      await _pedirCodigo(tester);
      await _dejarReintentar(tester);

      expect(repo.pedidos, hasLength(2));
      expect(find.text('Te enviamos un código a'), findsOneWidget);
      expect(find.textContaining('Reenviar en'), findsOneWidget);
      expect(find.textContaining('Se cortó'), findsNothing);
    });

    testWidgets('mientras se envia no dice que ya se envio', (tester) async {
      final repo = _RepositorioFalso()..retener = Completer<void>();
      await _abrir(tester, repo);
      await _pedirCodigo(tester);

      expect(find.text('Enviando un código a'), findsOneWidget);
      expect(find.text('Te enviamos un código a'), findsNothing);

      repo.retener!.complete();
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(find.text('Te enviamos un código a'), findsOneWidget);
    });

    testWidgets('si el servidor frena, el codigo que ya llego sigue', (
      tester,
    ) async {
      final repo = _RepositorioFalso(envios: const [CodigoReciente(42)]);
      await _abrir(tester, repo);
      await _pedirCodigo(tester);

      expect(find.byType(CampoCodigoVerificacion), findsOneWidget);
      expect(find.text('Te enviamos un código a'), findsOneWidget);
      expect(find.textContaining('Ya te mandamos un código'), findsOneWidget);
      expect(find.text('Reenviar en 42s'), findsOneWidget);
      expect(repo.pedidos, hasLength(1), reason: 'sin reintento');
    });

    testWidgets('el personal de la UPSA entra con su correo', (tester) async {
      final repo = _RepositorioFalso();
      await _abrir(tester, repo);
      await _tocar(
        tester,
        '¿Eres docente o personal de la UPSA? Entra con tu correo',
      );
      await tester.pump();

      expect(find.text('Tu correo de la UPSA'), findsOneWidget);
      // Si pega el correo entero, el dominio no se repite.
      await tester.enterText(
        find.byType(TextField),
        'josebenavente@upsa.edu.bo',
      );
      await tester.pump();
      await _tocar(tester, 'Enviarme el código');
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(repo.pedidos, ['josebenavente@upsa.edu.bo']);
      expect(find.text('josebenavente@upsa.edu.bo'), findsOneWidget);
    });

    testWidgets('un egresado con un registro de antes puede pedir el codigo', (
      tester,
    ) async {
      final repo = _RepositorioFalso();
      await _abrir(tester, repo);
      await tester.enterText(find.byType(TextField), '2004219999');
      await tester.pump();

      expect(find.textContaining('Después del año'), findsNothing);
      expect(find.textContaining('formato'), findsNothing);
      await _tocar(tester, 'Enviarme el código');
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(repo.pedidos, ['a2004219999@estudiantes.upsa.edu.bo']);
    });

    testWidgets('en un telefono el registro entero se ve, sin desplazarse', (
      tester,
    ) async {
      await _abrir(tester, _RepositorioFalso());
      await tester.enterText(find.byType(TextField), _registro);
      await tester.pump();

      // El dominio no entraba al lado del numero: el campo se corria y
      // mostraba "a11234", como si se hubiera comido los primeros digitos.
      final decoracion = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(decoracion.suffixText, isNull);
      expect(decoracion.helperText, '@estudiantes.upsa.edu.bo');
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.renderEditable.offset.pixels, 0);
    });

    testWidgets('un rechazo de verdad vuelve al registro sin borrarlo', (
      tester,
    ) async {
      final repo = _RepositorioFalso(
        envios: const [EnvioRechazado('Ese correo no es válido.')],
      );
      await _abrir(tester, repo);
      await _pedirCodigo(tester);

      expect(find.byType(CampoCodigoVerificacion), findsNothing);
      expect(find.text('Ese correo no es válido.'), findsOneWidget);
      // Antes el campo volvia vacio, aunque la pantalla guardaba el numero.
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.controller?.text, _registro);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('codigo_pendiente_correo'), isNull);
    });

    testWidgets('al volver a abrir la app sigue en el paso del codigo', (
      tester,
    ) async {
      // La app se descarto mientras se leia el correo, con el pedido sin
      // respuesta.
      SharedPreferences.setMockInitialValues({
        'codigo_pendiente_correo': _correo,
        'codigo_pendiente_enviado': DateTime.now().millisecondsSinceEpoch,
        'codigo_pendiente_confirmado': false,
      });
      await _abrir(tester, _RepositorioFalso());

      expect(find.byType(CampoCodigoVerificacion), findsOneWidget);
      expect(find.text('Pedimos un código para'), findsOneWidget);
      expect(find.text(_correo), findsOneWidget);
      expect(_reenviar(tester), isNotNull);
    });

    testWidgets('lo guardado por la version anterior cuenta como enviado', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'codigo_pendiente_correo': _correo,
        'codigo_pendiente_enviado': DateTime.now().millisecondsSinceEpoch,
      });
      await _abrir(tester, _RepositorioFalso());

      expect(find.text('Te enviamos un código a'), findsOneWidget);
      expect(find.textContaining('Reenviar en'), findsOneWidget);
    });

    testWidgets('un codigo equivocado pinta las casillas; un corte no', (
      tester,
    ) async {
      final repo = _RepositorioFalso(
        verificaciones: [
          ServicioAutenticacionCorreo.clasificarVerificacion(
            const AuthApiException(
              'Token has expired or is invalid',
              code: 'otp_expired',
            ),
          ),
          ServicioAutenticacionCorreo.clasificarVerificacion(_sinRed),
        ],
      );
      await _abrir(tester, repo);
      await _pedirCodigo(tester);

      await _escribirCodigo(tester, '123456');
      expect(_casillasEnRojo(tester), isTrue);
      expect(find.textContaining('Ese código no sirve'), findsOneWidget);

      // Al corregir, el rojo se va.
      await _escribirCodigo(tester, '12345');
      expect(_casillasEnRojo(tester), isFalse);
      expect(find.textContaining('Ese código no sirve'), findsNothing);

      await _escribirCodigo(tester, '123457');
      expect(repo.verificados, ['123456', '123457']);
      expect(_casillasEnRojo(tester), isFalse);
      expect(find.textContaining('Se cortó la conexión'), findsOneWidget);
    });

    testWidgets('pedir otro vacia las casillas y avisa cual usar', (
      tester,
    ) async {
      final repo = _RepositorioFalso(
        envios: const [EnvioSinConfirmar(porRed: true), CodigoEnviado()],
      );
      await _abrir(tester, repo);
      await _pedirCodigo(tester);
      await _dejarReintentar(tester);
      expect(repo.pedidos, hasLength(2));
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      // Salio al reintentar; al minuto se puede pedir otro.
      await tester.pump(const Duration(seconds: 61));
      await _tocar(tester, 'Reenviar código');
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(repo.pedidos, hasLength(3));
      expect(find.textContaining('usa el del último correo'), findsOneWidget);
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.controller?.text ?? '', isEmpty);
    });
  });
}
