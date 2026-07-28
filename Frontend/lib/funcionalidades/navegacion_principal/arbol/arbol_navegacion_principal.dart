import 'package:flutter/material.dart';

import '../../../arbol_aplicacion/arbol_dependencias.dart';
import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../configuracion_usuario/arbol/arbol_configuracion_usuario.dart';
import '../../inicio_marketplace/diseno/campus_collapsing_header.dart';
import '../../inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import '../../inicio_marketplace/pantalla/pantalla_inicio_marketplace.dart';
import '../../locales_universitarios/logica/controlador_locales.dart';
import '../../locales_universitarios/pantalla/pantalla_locales_universitarios.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../../mi_local/pantalla/pantalla_crear_local.dart';
import '../../mi_local/pantalla/pantalla_mi_local.dart';
import '../../publicar_producto/arbol/arbol_publicar_producto.dart';
import '../../pedidos/pantalla/pantalla_pedidos_completa.dart';
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
  late final inicio = ControladorInicioMarketplace(
    ArbolDependencias.crearRepositorioInicio(),
  );
  final locales = ControladorLocales();

  @override
  void initState() {
    super.initState();
    // Define si aparece la pestaña "Tu local" en la barra inferior.
    miLocal.cargar();
    miLocal.iniciarTiempoReal();
    inicio.cargar();
    locales.cargar();
    inicio.iniciarTiempoReal();
    locales.iniciarTiempoReal();
  }

  @override
  void dispose() {
    controlador.dispose();
    miLocal.dispose();
    inicio.dispose();
    locales.dispose();
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
    animation: Listenable.merge([miLocal, controlador]),
    builder: (context, _) {
      final enLocales = controlador.indice == 1;
      final pantallas = <Widget>[
        PantallaInicioMarketplace(
          controlador: inicio,
          mostrarEncabezado: false,
        ),
        PantallaLocalesUniversitarios(
          alCrearLocal: _abrirCreacion,
          // Un espacio personal no cuenta: la invitacion a abrir un local
          // formal debe seguir visible para el vendedor casual.
          yaTieneLocal: miLocal.tieneLocalFormal,
          controladorExterno: locales,
          mostrarEncabezado: false,
        ),
        ArbolPublicarProducto(miLocal: miLocal),
        if (miLocal.tieneLocal) PantallaMiLocal(controlador: miLocal),
        const ArbolConfiguracionUsuario(),
      ];
      return PantallaNavegacionPrincipal(
        controlador: controlador,
        pantallas: pantallas,
        mostrarMiLocal: miLocal.tieneLocal,
        encabezadoExploracion: AnimatedBuilder(
          animation: Listenable.merge([
            inicio,
            locales,
            SesionUsuario.instancia,
          ]),
          builder: (context, _) {
            final categorias = enLocales
                ? locales.categorias
                : inicio.estado.categorias;
            final categoriaId = enLocales
                ? locales.categoriaId
                : inicio.estado.categoriaId;
            return CampusFixedHeader(
              nombre: SesionUsuario.instancia.primerNombre,
              categorias: categorias,
              categoriaId: categoriaId,
              alBuscar: enLocales ? locales.buscar : inicio.buscar,
              alSeleccionarCategoria: enLocales
                  ? locales.seleccionarCategoria
                  : inicio.seleccionarCategoria,
              alAbrirCarrito: () =>
                  Navigator.of(context).pushNamed(ConfiguracionRutas.carrito),
              alAbrirPedidos: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PantallaPedidosCompleta(),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
