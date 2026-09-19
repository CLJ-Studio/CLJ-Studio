import 'package:flutter/material.dart';

import 'configuracion_aplicacion/configuracion_tema.dart';
import 'funcionalidades/apertura_aplicacion/pantalla/pantalla_apertura.dart';

/// Entrada exclusiva para diseñar la pantalla de apertura en el navegador.
///
/// No inicializa Supabase, notificaciones, sesión ni el resto de la app. Esto
/// permite retocar la escena y ver cada cambio inmediatamente con hot reload.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _VistaPreviaApertura());
}

class _VistaPreviaApertura extends StatelessWidget {
  const _VistaPreviaApertura();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Vista previa · Apertura U market',
    debugShowCheckedModeBanner: false,
    theme: ConfiguracionTema.temaClaro,
    themeMode: ThemeMode.light,
    home: const PantallaApertura(),
  );
}
