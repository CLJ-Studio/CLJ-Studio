import 'package:flutter/material.dart';

import '../configuracion_aplicacion/configuracion_rutas.dart';
import '../funcionalidades/acceso_upsa/arbol/arbol_acceso_upsa.dart';
import '../funcionalidades/carrito_compras/arbol/arbol_carrito_compras.dart';
import '../funcionalidades/navegacion_principal/arbol/arbol_navegacion_principal.dart';

/// Centraliza la navegación para poder migrar luego a rutas del backend o web.
abstract final class ArbolRutas {
  static Route<void> generarRuta(RouteSettings configuracion) {
    final Widget pagina = switch (configuracion.name) {
      ConfiguracionRutas.principal => const ArbolNavegacionPrincipal(),
      ConfiguracionRutas.carrito => const ArbolCarritoCompras(),
      _ => const ArbolAccesoUpsa(),
    };
    return _RutaSinDeslizamiento<void>(
      builder: (_) => pagina,
      settings: configuracion,
    );
  }
}

/// Ruta Material que conserva el botón Atrás, pero desactiva el gesto lateral.
class _RutaSinDeslizamiento<T> extends MaterialPageRoute<T> {
  _RutaSinDeslizamiento({required super.builder, super.settings});

  @override
  bool get popGestureEnabled => false;
}
