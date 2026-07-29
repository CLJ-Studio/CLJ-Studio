import 'package:flutter/material.dart';

import '../datos/repositorio_acceso_upsa.dart';
import '../pantalla/pantalla_acceso_upsa.dart';

/// Une pantalla y repositorio del acceso UPSA.
class ArbolAccesoUpsa extends StatelessWidget {
  const ArbolAccesoUpsa({this.alAccederLocal, super.key});

  final VoidCallback? alAccederLocal;

  @override
  Widget build(BuildContext context) {
    return PantallaAccesoUpsa(
      repositorio: const RepositorioAccesoUpsa(),
      alAccederLocal: alAccederLocal,
    );
  }
}
