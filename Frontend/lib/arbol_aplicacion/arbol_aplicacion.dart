import 'package:flutter/material.dart';

import '../configuracion_aplicacion/modo_local.dart';
import '../configuracion_aplicacion/configuracion_tema.dart';
import '../configuracion_aplicacion/controlador_tema.dart';
import '../funcionalidades/inicio_marketplace/logica/ubicacion_comprador.dart';
import '../funcionalidades/acceso_upsa/arbol/arbol_acceso_upsa.dart';
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
  final tema = ControladorTema.instancia;
  final _navegador = GlobalKey<NavigatorState>();
  bool _accesoLocalCompletado = false;

  @override
  void initState() {
    super.initState();
    tema.cargar();
    ControladorInstalacion.instancia.cargar();
    UbicacionComprador.instancia.cargar();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: tema,
    builder: (context, _) => MaterialApp(
      navigatorKey: _navegador,
      title: 'UPSA Eat',
      debugShowCheckedModeBanner: false,
      theme: ConfiguracionTema.temaClaro,
      darkTheme: ConfiguracionTema.temaOscuro,
      themeMode: tema.modo,
      onGenerateRoute: ArbolRutas.generarRuta,
      home: ModoLocal.activo
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
          : const PortonAutenticacion(),
    ),
  );
}
