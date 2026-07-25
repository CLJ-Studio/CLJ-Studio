import 'package:flutter/material.dart';

import '../configuracion_aplicacion/configuracion_rutas.dart';
import '../configuracion_aplicacion/configuracion_tema.dart';
import '../funcionalidades/acceso_upsa/arbol/arbol_acceso_upsa.dart';
import 'arbol_rutas.dart';

/// Ensambla la configuración global, el tema y las rutas de la aplicación.
class ArbolAplicacion extends StatelessWidget {
  const ArbolAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPSA Eat',
      debugShowCheckedModeBanner: false,
      theme: ConfiguracionTema.temaClaro,
      initialRoute: ConfiguracionRutas.acceso,
      onGenerateRoute: ArbolRutas.generarRuta,
      home: const ArbolAccesoUpsa(),
    );
  }
}
