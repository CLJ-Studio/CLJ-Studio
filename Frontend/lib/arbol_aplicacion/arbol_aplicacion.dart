import 'package:flutter/material.dart';

import '../configuracion_aplicacion/configuracion_tema.dart';
import 'arbol_rutas.dart';
import 'porton_autenticacion.dart';

/// Ensambla la configuración global, el tema y las rutas de la aplicación.
class ArbolAplicacion extends StatelessWidget {
  const ArbolAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPSA Eat',
      debugShowCheckedModeBanner: false,
      theme: ConfiguracionTema.temaClaro,
      onGenerateRoute: ArbolRutas.generarRuta,
      home: const PortonAutenticacion(),
    );
  }
}
