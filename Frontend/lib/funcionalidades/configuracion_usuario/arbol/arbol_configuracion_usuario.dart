import 'package:flutter/material.dart';
import '../pantalla/pantalla_configuracion_usuario.dart';

/// Ensambla las preferencias del usuario.
class ArbolConfiguracionUsuario extends StatelessWidget {
  const ArbolConfiguracionUsuario({this.alCerrarSesion, super.key});

  final VoidCallback? alCerrarSesion;

  @override
  Widget build(BuildContext context) =>
      PantallaConfiguracionUsuario(alCerrarSesion: alCerrarSesion);
}
