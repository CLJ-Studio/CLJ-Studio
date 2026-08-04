import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../arbol_aplicacion/arbol_dependencias.dart';
import '../../inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import '../../inicio_marketplace/pantalla/pantalla_inicio_marketplace.dart';
import '../../locales_universitarios/logica/controlador_locales.dart';
import '../../locales_universitarios/pantalla/pantalla_locales_universitarios.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../../mi_local/pantalla/pantalla_administrar_local.dart';
import '../../mi_local/pantalla/pantalla_crear_local.dart';
import '../../notificaciones/logica/navegador_notificaciones.dart';
import '../../perfil_vendedor/pantalla/pantalla_perfil_vendedor.dart';
import '../../publicar_producto/arbol/arbol_publicar_producto.dart';
import '../logica/controlador_navegacion_principal.dart';
import '../pantalla/pantalla_navegacion_principal.dart';

/// Une inicio, locales, publicación, configuración y la barra inferior.
class ArbolNavegacionPrincipal extends StatefulWidget {
  const ArbolNavegacionPrincipal({this.alCerrarSesion, super.key});

  final VoidCallback? alCerrarSesion;

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
    miLocal.cargar();
    miLocal.iniciarTiempoReal();
    inicio.cargar();
    locales.cargar();
    inicio.iniciarTiempoReal();
    locales.iniciarTiempoReal();
    _abrirDestinoDeNotificacion();
  }

  /// Al tocar una notificacion del sistema, `push_sw.js` navega o abre la
  /// app con el destino en la URL (`?notif_local=...`) porque un service
  /// worker no puede llamar directamente al Navigator de Flutter. Aqui se
  /// lee esa URL una sola vez al arrancar y se completa la navegacion.
  void _abrirDestinoDeNotificacion() {
    final parametros = Uri.base.queryParameters;
    final pedidoId = parametros['notif_pedido'];
    final localId = parametros['notif_local'];
    final productoId = parametros['notif_producto'];
    if (pedidoId == null && localId == null && productoId == null) return;

    // Se limpia antes de navegar: si la persona recarga despues, no debe
    // volver a saltar a la misma notificacion vieja.
    web.window.history.replaceState(null, '', web.window.location.pathname);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NavegadorNotificaciones.abrir(
        context,
        pedidoId: pedidoId,
        localId: localId,
        productoId: productoId,
      );
    });
  }

  @override
  void dispose() {
    controlador.dispose();
    miLocal.dispose();
    inicio.dispose();
    locales.dispose();
    super.dispose();
  }

  /// Con negocio abierto lleva a administrarlo; sin el, al alta.
  void _alCerrarLocal(String localId) {
    locales.quitarLocal(localId);
    // Los productos del negocio tambien deben desaparecer de Inicio.
    inicio.cargar();
  }

  void _abrirLocal() {
    if (miLocal.tieneLocalFormal) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaAdministrarLocal(
            controlador: miLocal,
            alCerrarLocal: _alCerrarLocal,
          ),
        ),
      );
      return;
    }
    _abrirCreacion();
  }

  void _abrirCreacion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaCrearLocal(
          controlador: miLocal,
          alCompletar: () {
            // Recien creado, se abre directo su administracion.
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaAdministrarLocal(
                  controlador: miLocal,
                  alCerrarLocal: _alCerrarLocal,
                ),
              ),
            );
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
        PantallaInicioMarketplace(
          controlador: inicio,
          mostrarUbicacion: miLocal.tieneLocalFormal,
          alVerLocalesDestacados: () {
            locales.mostrarSoloDestacados();
            controlador.seleccionarIndice(1);
          },
        ),
        PantallaLocalesUniversitarios(
          alCrearLocal: _abrirLocal,
          // Un espacio personal no cuenta: la invitacion a abrir un local
          // formal debe seguir visible para el vendedor casual.
          yaTieneLocal: miLocal.tieneLocalFormal,
          mostrarUbicacion: miLocal.tieneLocalFormal,
          controladorExterno: locales,
        ),
        ArbolPublicarProducto(miLocal: miLocal),
        PantallaPerfilVendedor(
          controlador: miLocal,
          alCerrarSesion: widget.alCerrarSesion,
        ),
      ];
      return PantallaNavegacionPrincipal(
        controlador: controlador,
        pantallas: pantallas,
      );
    },
  );
}
