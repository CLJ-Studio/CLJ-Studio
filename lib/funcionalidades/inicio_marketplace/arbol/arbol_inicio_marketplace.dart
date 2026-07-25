import 'package:flutter/material.dart';

import '../../../arbol_aplicacion/arbol_dependencias.dart';
import '../logica/controlador_inicio_marketplace.dart';
import '../pantalla/pantalla_inicio_marketplace.dart';

/// Compone la pantalla de inicio con su repositorio y controlador.
class ArbolInicioMarketplace extends StatefulWidget {
  const ArbolInicioMarketplace({super.key});

  @override
  State<ArbolInicioMarketplace> createState() => _ArbolInicioMarketplaceState();
}

class _ArbolInicioMarketplaceState extends State<ArbolInicioMarketplace> {
  late final ControladorInicioMarketplace controlador =
      ControladorInicioMarketplace(ArbolDependencias.crearRepositorioInicio());

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PantallaInicioMarketplace(controlador: controlador);
}
