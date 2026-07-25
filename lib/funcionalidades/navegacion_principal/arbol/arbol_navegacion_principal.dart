import 'package:flutter/material.dart';

import '../../configuracion_usuario/arbol/arbol_configuracion_usuario.dart';
import '../../inicio_marketplace/arbol/arbol_inicio_marketplace.dart';
import '../../locales_universitarios/arbol/arbol_locales_universitarios.dart';
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
  static const pantallas = <Widget>[
    ArbolInicioMarketplace(),
    ArbolLocalesUniversitarios(),
    ArbolPublicarProducto(),
    ArbolConfiguracionUsuario(),
  ];
  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PantallaNavegacionPrincipal(
    controlador: controlador,
    pantallas: pantallas,
  );
}
