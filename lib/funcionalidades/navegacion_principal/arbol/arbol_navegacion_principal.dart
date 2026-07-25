import 'package:flutter/material.dart';

import '../../configuracion_usuario/arbol/arbol_configuracion_usuario.dart';
import '../../inicio_marketplace/arbol/arbol_inicio_marketplace.dart';
import '../../locales_universitarios/arbol/arbol_locales_universitarios.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../../mi_local/pantalla/pantalla_crear_local.dart';
import '../../mi_local/pantalla/pantalla_mi_local.dart';
import '../../publicar_producto/arbol/arbol_publicar_producto.dart';
import '../logica/controlador_navegacion_principal.dart';
import '../pantalla/pantalla_navegacion_principal.dart';

/// Une inicio, locales, publicación, configuración y la barra inferior.
class ArbolNavegacionPrincipal extends StatefulWidget {
  const ArbolNavegacionPrincipal({super.key});
  @override
  State<ArbolNavegacionPrincipal> createState() =>
      _ArbolNavegacionPrincipalState();
}

class _ArbolNavegacionPrincipalState extends State<ArbolNavegacionPrincipal> {
  final controlador = ControladorNavegacionPrincipal();
  final miLocal = ControladorMiLocal();

  @override
  void dispose() {
    controlador.dispose();
    miLocal.dispose();
    super.dispose();
  }

  void _abrirCreacion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaCrearLocal(
          controlador: miLocal,
          alCompletar: () => controlador.seleccionarIndice(3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: miLocal,
    builder: (context, _) {
      final pantallas = <Widget>[
        const ArbolInicioMarketplace(),
        ArbolLocalesUniversitarios(
          alCrearLocal: _abrirCreacion,
          yaTieneLocal: miLocal.tieneLocal,
        ),
        const ArbolPublicarProducto(),
        if (miLocal.tieneLocal) PantallaMiLocal(controlador: miLocal),
        const ArbolConfiguracionUsuario(),
      ];
      return PantallaNavegacionPrincipal(
        controlador: controlador,
        pantallas: pantallas,
        mostrarMiLocal: miLocal.tieneLocal,
      );
    },
  );
}
