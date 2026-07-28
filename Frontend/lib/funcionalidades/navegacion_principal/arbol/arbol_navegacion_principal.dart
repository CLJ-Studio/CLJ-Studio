import 'package:flutter/material.dart';

import '../../../arbol_aplicacion/arbol_dependencias.dart';
import '../../configuracion_usuario/arbol/arbol_configuracion_usuario.dart';
import '../../inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import '../../inicio_marketplace/pantalla/pantalla_inicio_marketplace.dart';
import '../../locales_universitarios/logica/controlador_locales.dart';
import '../../locales_universitarios/pantalla/pantalla_locales_universitarios.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../../mi_local/pantalla/pantalla_crear_local.dart';
import '../../publicar_producto/pantalla/seccion_publicar_mi_local.dart';
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
  final segmentoPublicar = ValueNotifier<int>(0);
  late final inicio = ControladorInicioMarketplace(
    ArbolDependencias.crearRepositorioInicio(),
  );
  final locales = ControladorLocales();

  @override
  void initState() {
    super.initState();
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
    segmentoPublicar.dispose();
    inicio.dispose();
    locales.dispose();
    super.dispose();
  }

  void _abrirCreacion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaCrearLocal(
          controlador: miLocal,
          alCompletar: () {
            segmentoPublicar.value = 1;
            controlador.seleccionarIndice(2);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([miLocal, controlador]),
    builder: (context, _) {
      final pantallas = <Widget>[
        PantallaInicioMarketplace(controlador: inicio),
        PantallaLocalesUniversitarios(
          alCrearLocal: _abrirCreacion,
          // Un espacio personal no cuenta: la invitacion a abrir un local
          // formal debe seguir visible para el vendedor casual.
          yaTieneLocal: miLocal.tieneLocalFormal,
          controladorExterno: locales,
        ),
        SeccionPublicarMiLocal(miLocal: miLocal, segmento: segmentoPublicar),
        const ArbolConfiguracionUsuario(),
      ];
      return PantallaNavegacionPrincipal(
        controlador: controlador,
        pantallas: pantallas,
      );
    },
  );
}
