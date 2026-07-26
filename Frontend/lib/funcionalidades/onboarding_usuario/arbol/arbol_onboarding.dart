import 'package:flutter/material.dart';

import '../datos/repositorio_onboarding.dart';
import '../logica/controlador_onboarding.dart';
import '../pantalla/pantalla_onboarding.dart';

/// Une pantalla, controlador y repositorio del onboarding.
class ArbolOnboarding extends StatefulWidget {
  const ArbolOnboarding({required this.alCompletar, super.key});

  final VoidCallback alCompletar;

  @override
  State<ArbolOnboarding> createState() => _ArbolOnboardingState();
}

class _ArbolOnboardingState extends State<ArbolOnboarding> {
  final controlador = ControladorOnboarding(const RepositorioOnboarding());

  @override
  void initState() {
    super.initState();
    controlador.cargarDatosIniciales();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PantallaOnboarding(
    controlador: controlador,
    alCompletar: widget.alCompletar,
  );
}
