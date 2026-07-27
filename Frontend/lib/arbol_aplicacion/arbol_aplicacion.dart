import 'package:flutter/material.dart';

import '../configuracion_aplicacion/configuracion_tema.dart';
import '../configuracion_aplicacion/controlador_tema.dart';
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

  @override
  void initState() {
    super.initState();
    tema.cargar();
    ControladorInstalacion.instancia.cargar();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: tema,
    builder: (context, _) => MaterialApp(
      title: 'UPSA Eat',
      debugShowCheckedModeBanner: false,
      theme: ConfiguracionTema.temaClaro,
      darkTheme: ConfiguracionTema.temaOscuro,
      themeMode: tema.modo,
      onGenerateRoute: ArbolRutas.generarRuta,
      home: const PortonAutenticacion(),
    ),
  );
}
