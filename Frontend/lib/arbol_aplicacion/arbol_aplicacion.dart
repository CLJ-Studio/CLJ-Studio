import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configuracion_aplicacion/modo_local.dart';
import '../configuracion_aplicacion/configuracion_tema.dart';
import '../funcionalidades/inicio_marketplace/logica/ubicacion_comprador.dart';
import '../funcionalidades/acceso_upsa/arbol/arbol_acceso_upsa.dart';
import '../funcionalidades/apertura_aplicacion/pantalla/pantalla_apertura.dart';
import '../funcionalidades/navegacion_principal/arbol/arbol_navegacion_principal.dart';
import '../funcionalidades/instalacion_app/logica/controlador_instalacion.dart';
import 'arbol_rutas.dart';
import 'porton_autenticacion.dart';

/// Ensambla la configuración global, el tema y las rutas de la aplicación.
class ArbolAplicacion extends StatefulWidget {
  const ArbolAplicacion({super.key});

  @override
  State<ArbolAplicacion> createState() => _ArbolAplicacionState();
}

class _ArbolAplicacionState extends State<ArbolAplicacion> {
  static const _claveAperturaInicialMostrada = 'apertura_inicial_mostrada';

  final _navegador = GlobalKey<NavigatorState>();
  bool _accesoLocalCompletado = false;
  bool? _mostrandoApertura;
  Timer? _temporizadorApertura;

  @override
  void initState() {
    super.initState();
    ControladorInstalacion.instancia.cargar();
    UbicacionComprador.instancia.cargar();
    _prepararAperturaInicial();
  }

  /// Muestra la animación únicamente la primera vez que se abre la app.
  /// La marca se guarda al terminar para que una interrupción no la omita.
  Future<void> _prepararAperturaInicial() async {
    final preferencias = await SharedPreferences.getInstance();
    final yaFueMostrada =
        preferencias.getBool(_claveAperturaInicialMostrada) ?? false;

    if (!mounted) return;
    if (yaFueMostrada) {
      setState(() => _mostrandoApertura = false);
      return;
    }

    setState(() => _mostrandoApertura = true);
    // La escena vive el tiempo suficiente para completar todos sus movimientos.
    _temporizadorApertura = Timer(const Duration(milliseconds: 3200), () async {
      await preferencias.setBool(_claveAperturaInicialMostrada, true);
      if (mounted) setState(() => _mostrandoApertura = false);
    });
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

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navegador,
    title: 'U market',
    debugShowCheckedModeBanner: false,
    theme: ConfiguracionTema.temaClaro,
    themeMode: ThemeMode.light,
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
      child: switch (_mostrandoApertura) {
        null => const ColoredBox(
          key: ValueKey('preparando-apertura'),
          color: Color(0xFFF8F4EC),
        ),
        true => const PantallaApertura(key: ValueKey('apertura')),
        false => KeyedSubtree(
          key: const ValueKey('contenido-principal'),
          child: _contenidoPrincipal(),
        ),
      },
    ),
  );
}
