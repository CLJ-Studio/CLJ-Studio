import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../configuracion_aplicacion/configuracion_supabase.dart';
import '../configuracion_aplicacion/modo_local.dart';
import '../configuracion_aplicacion/configuracion_tema.dart';
import '../elementos_compartidos/animaciones/precargador_animaciones.dart';
import '../funcionalidades/inicio_marketplace/logica/ubicacion_comprador.dart';
import '../funcionalidades/acceso_upsa/arbol/arbol_acceso_upsa.dart';
import '../funcionalidades/apertura_aplicacion/pantalla/pantalla_apertura.dart';
import '../funcionalidades/inicio_marketplace/pantalla/pantalla_esqueleto_inicio_marketplace.dart';
import '../funcionalidades/navegacion_principal/arbol/arbol_navegacion_principal.dart';
import '../funcionalidades/instalacion_app/logica/controlador_instalacion.dart';
import '../funcionalidades/notificaciones/datos/servicio_push.dart';
import '../funcionalidades/venta_rapida/datos/servicio_atajo_venta_rapida.dart';
import 'arbol_rutas.dart';
import 'pantalla_sin_conexion.dart';
import 'porton_autenticacion.dart';

/// En que punto esta la conexion con el servidor.
enum _Servidor { conectando, listo, fallo }

/// Ensambla la configuración global, el tema y las rutas de la aplicación.
class ArbolAplicacion extends StatefulWidget {
  const ArbolAplicacion({super.key});

  @override
  State<ArbolAplicacion> createState() => _ArbolAplicacionState();
}

class _ArbolAplicacionState extends State<ArbolAplicacion> {
  final _navegador = GlobalKey<NavigatorState>();
  bool _accesoLocalCompletado = false;
  bool _mostrandoApertura = true;
  Timer? _temporizadorApertura;
  var _servidor = ModoLocal.activo ? _Servidor.listo : _Servidor.conectando;

  @override
  void initState() {
    super.initState();
    _conectar();
    _temporizadorApertura = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _mostrandoApertura = false);
    });
  }

  /// Conecta con Supabase CON LA APLICACION YA EN PANTALLA.
  ///
  /// Antes esto se hacia antes de `runApp`, o sea antes de que existiera un
  /// solo pixel. Los veinte segundos de tope se pasaban mirando el fondo del
  /// HTML, que es crema, sin nada encima: exactamente la pantalla de la que
  /// nadie sabia salir. Aqui dentro esos mismos segundos transcurren bajo la
  /// animacion de apertura, y si fallan hay a donde ir.
  Future<void> _conectar() async {
    if (ModoLocal.activo) return;
    if (_servidor != _Servidor.conectando) {
      setState(() => _servidor = _Servidor.conectando);
    }
    try {
      await Supabase.initialize(
        url: ConfiguracionSupabase.url,
        publishableKey: ConfiguracionSupabase.publishableKey,
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() => _servidor = _Servidor.listo);
      _arrancarExtras();
    } catch (_) {
      if (mounted) setState(() => _servidor = _Servidor.fallo);
    }
  }

  /// El atajo de iPhone y las notificaciones. Son extras: que tarden o fallen
  /// no puede costar el arranque, y los dos hablan con el sistema operativo
  /// por un canal que puede no responder nunca. Por eso van sueltos, con la
  /// aplicacion ya funcionando, y cada uno con su propio tope.
  void _arrancarExtras() {
    PrecargadorAnimaciones.iniciar();
    ControladorInstalacion.instancia.cargar();
    UbicacionComprador.instancia.cargar();
    for (final arrancar in [
      ServicioAtajoVentaRapida.inicializar,
      ServicioPush.inicializar,
    ]) {
      unawaited(
        arrancar().timeout(const Duration(seconds: 15)).catchError((_) {
          // Sin atajo o sin notificaciones se puede vivir; sin aplicacion no.
        }),
      );
    }
  }

  @override
  void dispose() {
    _temporizadorApertura?.cancel();
    super.dispose();
  }

  Widget _contenidoPrincipal() => ModoLocal.activo
      ? _accesoLocalCompletado
            ? ArbolNavegacionPrincipal(
                alCerrarSesion: () {
                  setState(() => _accesoLocalCompletado = false);
                  _navegador.currentState?.popUntil((ruta) => ruta.isFirst);
                },
              )
            : ArbolAccesoUpsa(
                alAccederLocal: () =>
                    setState(() => _accesoLocalCompletado = true),
              )
      : const PortonAutenticacion();

  /// Que se ve en cada momento del arranque.
  ///
  /// Ya no existe el estado en blanco. Mientras no se sepa si toca la
  /// animacion de apertura, o mientras esta corriendo, o mientras se conecta
  /// con el servidor, SIEMPRE hay algo dibujado. Un hueco del color del tema
  /// es indistinguible de una aplicacion rota.
  Widget _pantallaActual() {
    if (_servidor == _Servidor.fallo) {
      return PantallaSinConexion(alReintentar: _conectar);
    }
    if (_mostrandoApertura) {
      return const PantallaApertura(key: ValueKey('apertura'));
    }
    if (_servidor == _Servidor.conectando) {
      return const PantallaEsqueletoInicioMarketplace(
        key: ValueKey('inicio-esqueleto-servidor'),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('contenido-principal'),
      child: _contenidoPrincipal(),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navegador,
    title: 'U market',
    debugShowCheckedModeBanner: false,
    theme: ConfiguracionTema.temaClaro,
    themeMode: ThemeMode.light,
    // Los textos que pone Flutter (el calendario, "Cancelar", "Pegar"), en
    // español: sin esto salían en inglés aunque el teléfono esté en español.
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    onGenerateRoute: ArbolRutas.generarRuta,
    // Flutter conserva el teclado al tocar fuera en iOS y Android. Se
    // reemplaza esa acción una sola vez para todos los campos de la app;
    // tocar otro campo sigue enfocándolo normalmente.
    builder: (context, child) => Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (intent) {
                intent.focusNode.unfocus();
                return null;
              },
            ),
      },
      child: child ?? const SizedBox.shrink(),
    ),
    home: AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _pantallaActual(),
    ),
  );
}
