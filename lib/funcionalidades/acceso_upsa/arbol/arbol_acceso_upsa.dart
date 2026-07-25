import 'package:flutter/material.dart';

import '../datos/repositorio_acceso_upsa.dart';
import '../datos/servicio_autenticacion_google.dart';
import '../logica/controlador_acceso_upsa.dart';
import '../pantalla/pantalla_acceso_upsa.dart';

/// Une pantalla, controlador y repositorio del acceso UPSA.
class ArbolAccesoUpsa extends StatefulWidget {
  const ArbolAccesoUpsa({super.key});

  @override
  State<ArbolAccesoUpsa> createState() => _ArbolAccesoUpsaState();
}

class _ArbolAccesoUpsaState extends State<ArbolAccesoUpsa> {
  final controlador = ControladorAccesoUpsa();

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PantallaAccesoUpsa(
      controlador: controlador,
      repositorio: const RepositorioAccesoUpsa(ServicioAutenticacionGoogle()),
    );
  }
}
