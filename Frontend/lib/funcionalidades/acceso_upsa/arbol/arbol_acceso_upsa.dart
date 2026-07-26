import 'package:flutter/material.dart';

import '../datos/repositorio_acceso_upsa.dart';
import '../datos/servicio_autenticacion_google.dart';
import '../pantalla/pantalla_acceso_upsa.dart';

/// Une pantalla y repositorio del acceso UPSA.
class ArbolAccesoUpsa extends StatelessWidget {
  const ArbolAccesoUpsa({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaAccesoUpsa(
      repositorio: RepositorioAccesoUpsa(ServicioAutenticacionGoogle()),
    );
  }
}
