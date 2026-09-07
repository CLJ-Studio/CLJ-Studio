import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/notificacion.dart';
import 'destino_notificacion_sistema.dart';

const _claveNotificacionesActivas = 'notificaciones_nativas_activas';
const _claveUltimoTokenApns = 'apns_ultimo_token';
const _canalApns = MethodChannel('com.cljstudio.umarket/notificaciones');

/// Notificaciones nativas de las aplicaciones instaladas.
///
/// iPhone se registra directamente con APNs, sin Firebase. Android conserva
/// por ahora las notificaciones locales creadas por la lógica de U market.
abstract final class ServicioPush {
  static final _pluginLocal = FlutterLocalNotificationsPlugin();
  static final _destinos =
      StreamController<DestinoNotificacionSistema>.broadcast();

  static bool _inicializado = false;
  static bool _permisoConcedido = false;
  static bool _denegado = false;
  static String _entornoApns = 'sandbox';
  static DestinoNotificacionSistema? _destinoPendiente;

  static bool get soportado => Platform.isIOS || Platform.isAndroid;
  static bool get yaConcedido => _permisoConcedido;
  static bool get denegado => _denegado;
  static String? ultimoError;

  static Stream<DestinoNotificacionSistema> get destinosAbiertos =>
      _destinos.stream;

  static Future<void> inicializar() async {
    if (!soportado || _inicializado) return;
    ultimoError = null;

    try {
      if (Platform.isIOS) {
        _canalApns.setMethodCallHandler(_manejarLlamadaNativa);
        final estado = await _canalApns.invokeMapMethod<String, dynamic>(
          'initialize',
        );
        _aplicarEstadoApns(estado);
        final payload = estado?['initialPayload'];
        if (payload is Map) {
          _registrarDestino(Map<String, dynamic>.from(payload), emitir: false);
        }
        final token = estado?['token'] as String?;
        final preferencias = await SharedPreferences.getInstance();
        if (token != null &&
            (preferencias.getBool(_claveNotificacionesActivas) ?? false)) {
          await _guardarTokenApns(token);
        }
      } else {
        const ajustes = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
        await _pluginLocal.initialize(
          settings: ajustes,
          onDidReceiveNotificationResponse: (respuesta) {
            _registrarPayloadLocal(respuesta.payload);
          },
        );
        _permisoConcedido = await _permisoAndroid();
        final lanzamiento = await _pluginLocal
            .getNotificationAppLaunchDetails();
        if (lanzamiento?.didNotificationLaunchApp ?? false) {
          _registrarPayloadLocal(
            lanzamiento?.notificationResponse?.payload,
            emitir: false,
          );
        }
      }
      _inicializado = true;
    } catch (fallo) {
      ultimoError = fallo.toString();
    }
  }

  static Future<void> _manejarLlamadaNativa(MethodCall llamada) async {
    final argumentos = llamada.arguments;
    if (llamada.method == 'notificationOpened' && argumentos is Map) {
      _registrarDestino(Map<String, dynamic>.from(argumentos));
      return;
    }
    if (llamada.method == 'tokenUpdated' && argumentos is Map) {
      final datos = Map<String, dynamic>.from(argumentos);
      _aplicarEstadoApns(datos);
      final preferencias = await SharedPreferences.getInstance();
      if (preferencias.getBool(_claveNotificacionesActivas) ?? false) {
        final token = datos['token'] as String?;
        if (token != null) await _guardarTokenApns(token);
      }
    }
  }

  static void _aplicarEstadoApns(Map<String, dynamic>? estado) {
    if (estado == null) return;
    _permisoConcedido = estado['enabled'] as bool? ?? false;
    _entornoApns = estado['environment'] as String? ?? 'sandbox';
  }

  static void _registrarPayloadLocal(String? payload, {bool emitir = true}) {
    if (payload == null || payload.isEmpty) return;
    try {
      _registrarDestino(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
        emitir: emitir,
      );
    } catch (_) {}
  }

  static void _registrarDestino(
    Map<String, dynamic> datos, {
    bool emitir = true,
  }) {
    final destino = DestinoNotificacionSistema.desdeMapa(datos);
    if (!destino.tieneDestino) return;
    _destinoPendiente = destino;
    if (emitir) _destinos.add(destino);
  }

  static Future<DestinoNotificacionSistema?> consumirDestinoInicial() async {
    final destino = _destinoPendiente;
    _destinoPendiente = null;
    return destino;
  }

  static Future<bool> _permisoAndroid() async =>
      await _pluginLocal
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled() ??
      true;

  static Future<bool> estaActivo() async {
    await inicializar();
    if (!_inicializado) return false;

    final preferencias = await SharedPreferences.getInstance();
    final habilitadoEnLaApp =
        preferencias.getBool(_claveNotificacionesActivas) ?? false;

    if (Platform.isIOS) {
      final estado = await _canalApns.invokeMapMethod<String, dynamic>(
        'status',
      );
      _aplicarEstadoApns(estado);
      final token = estado?['token'] as String?;
      if (habilitadoEnLaApp && token != null) {
        await _guardarTokenApns(token);
      }
    } else {
      _permisoConcedido = await _permisoAndroid();
    }
    return habilitadoEnLaApp && _permisoConcedido;
  }

  static Future<bool> activar() async {
    ultimoError = null;
    await inicializar();
    if (!_inicializado) return false;

    try {
      if (Platform.isIOS) {
        final estado = await _canalApns.invokeMapMethod<String, dynamic>(
          'requestPermissionAndRegister',
        );
        _aplicarEstadoApns(estado);
        final token = estado?['token'] as String?;
        if (!_permisoConcedido || token == null) {
          _denegado = !_permisoConcedido;
          return false;
        }
        await _guardarTokenApns(token);
      } else {
        _permisoConcedido =
            await _pluginLocal
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            true;
        if (!_permisoConcedido) {
          _denegado = true;
          return false;
        }
      }

      _denegado = false;
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setBool(_claveNotificacionesActivas, true);
      return true;
    } catch (fallo) {
      ultimoError = fallo.toString();
      return false;
    }
  }

  static Future<void> _guardarTokenApns(String token) async {
    final cliente = Supabase.instance.client;
    final usuario = cliente.auth.currentUser;
    if (usuario == null) return;

    final preferencias = await SharedPreferences.getInstance();
    final anterior = preferencias.getString(_claveUltimoTokenApns);
    if (anterior != null && anterior != token) {
      await cliente
          .from('push_subscriptions')
          .delete()
          .eq('endpoint', 'apns:$anterior');
    }

    await cliente.from('push_subscriptions').upsert({
      'user_id': usuario.id,
      'endpoint': 'apns:$token',
      'p256dh': 'apns',
      'auth': 'ios_$_entornoApns',
    }, onConflict: 'endpoint');
    await preferencias.setString(_claveUltimoTokenApns, token);
  }

  static Future<bool> desactivar() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      if (Platform.isIOS) {
        final token = preferencias.getString(_claveUltimoTokenApns);
        if (token != null) {
          await Supabase.instance.client
              .from('push_subscriptions')
              .delete()
              .eq('endpoint', 'apns:$token');
        }
        await _canalApns.invokeMethod<void>('disable');
        await preferencias.remove(_claveUltimoTokenApns);
      } else {
        await _pluginLocal.cancelAll();
      }
      await preferencias.setBool(_claveNotificacionesActivas, false);
      return true;
    } catch (fallo) {
      ultimoError = fallo.toString();
      return false;
    }
  }

  /// Android crea el aviso localmente. En iPhone el mismo aviso ya llega por
  /// APNs, así que aquí no se duplica.
  static Future<void> mostrar(Notificacion notificacion) async {
    if (Platform.isIOS || !await estaActivo()) return;

    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'avisos_umarket',
        'Avisos de U market',
        channelDescription: 'Pedidos, mensajes y actividad de U market.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    final payload = jsonEncode({
      'order_id': notificacion.pedidoId,
      'store_id': notificacion.localId,
      'product_id': notificacion.productoId,
    });
    await _pluginLocal.show(
      id: notificacion.id.hashCode & 0x7fffffff,
      title: notificacion.titulo,
      body: notificacion.cuerpo,
      notificationDetails: detalles,
      payload: payload,
    );
  }
}
