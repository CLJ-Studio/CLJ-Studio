import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_local.dart';
import '../diseno/campus_collapsing_header.dart';
import '../diseno/seccion_locales_universitarios.dart';
import '../logica/controlador_inicio_marketplace.dart';
import '../logica/estado_inicio_marketplace.dart';

/// Pantalla principal que reacciona al estado de filtros del controlador.
class PantallaInicioMarketplace extends StatelessWidget {
  const PantallaInicioMarketplace({required this.controlador, super.key});
  final ControladorInicioMarketplace controlador;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    // Escucha ambos: los filtros del feed y el perfil compartido, para que
    // el saludo se actualice en cuanto el perfil termine de cargar.
    animation: Listenable.merge([controlador, SesionUsuario.instancia]),
    builder: (context, _) {
      final estado = controlador.estado;
      return CustomScrollView(
        slivers: [
          CampusCollapsingHeader(
            nombre: SesionUsuario.instancia.primerNombre,
            categorias: estado.categorias,
            categoriaId: estado.categoriaId,
            alBuscar: controlador.buscar,
            alSeleccionarCategoria: controlador.seleccionarCategoria,
            alAbrirCarrito: () =>
                Navigator.of(context).pushNamed(ConfiguracionRutas.carrito),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 120),
            sliver: SliverToBoxAdapter(
              child: ContenidoCentrado(
                child: switch (estado) {
                  EstadoInicioMarketplace(cargando: true) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  EstadoInicioMarketplace(error: final String mensaje) =>
                    MensajeCatalogo(
                      mensaje: mensaje,
                      alReintentar: controlador.cargar,
                    ),
                  _ => SeccionLocalesUniversitarios(
                    locales: estado.locales,
                    construirDetalle: (_, local) =>
                        PantallaDetalleLocal(local: local),
                  ),
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}
