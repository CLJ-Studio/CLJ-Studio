import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../arbol_aplicacion/arbol_dependencias.dart';
import '../../../configuracion_aplicacion/modo_local.dart';
import '../../inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import '../../inicio_marketplace/logica/estado_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/categoria_marketplace.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
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
    if (ModoLocal.activo) {
      _cargarDatosLocales();
      return;
    }
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

  void _cargarDatosLocales() {
    const categorias = [
      CategoriaMarketplace.todas,
      CategoriaMarketplace(
        id: 'comida',
        nombre: 'Comida',
        icono: Icons.lunch_dining_rounded,
      ),
      CategoriaMarketplace(
        id: 'servicios',
        nombre: 'Servicios',
        icono: Icons.handyman_rounded,
      ),
      CategoriaMarketplace(
        id: 'tecnologia',
        nombre: 'Tecnología',
        icono: Icons.devices_rounded,
      ),
    ];
    const local = LocalUniversitario(
      id: 'local-diseno',
      nombre: 'Mi local',
      categoriaId: 'comida',
      categoria: 'Comida',
      descripcion: 'Vista local para diseñar la interfaz.',
      calificacion: 5,
      tiempoEstimado: '15 min',
      estaAbierto: true,
      costoEntrega: 0,
      emoji: '🍔',
      colorHexadecimal: 0xFFF1F6F0,
      vistas: 248,
    );
    const producto = ProductoMarketplace(
      id: 'producto-diseno',
      localId: 'local-diseno',
      nombre: 'Producto de muestra',
      descripcion: 'Puedes editar libremente esta interfaz.',
      precio: 20,
      emoji: '🍔',
      stock: 10,
      local: local,
      vistas: 93,
    );

    miLocal
      ..negocio = local
      ..productos = const [producto]
      ..cargando = false;
    inicio.estado = const EstadoInicioMarketplace(
      categorias: categorias,
      publicaciones: [producto],
      cargando: false,
    );
    locales
      ..categorias = categorias
      ..locales = const [local]
      ..cargando = false;
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
  void _abrirLocal() {
    if (miLocal.tieneLocalFormal) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaAdministrarLocal(controlador: miLocal),
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
            if (ModoLocal.activo) {
              final nuevoLocal = miLocal.negocio;
              if (nuevoLocal != null) {
                locales.actualizarLocalDePrueba(nuevoLocal);
              }
            }
            // Recien creado, se abre directo su administracion.
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaAdministrarLocal(controlador: miLocal),
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
