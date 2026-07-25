import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../datos_prueba/usuario_prueba.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_local.dart';
import '../diseno/campus_collapsing_header.dart';
import '../diseno/seccion_locales_universitarios.dart';
import '../logica/controlador_inicio_marketplace.dart';

/// Pantalla principal que reacciona al estado de filtros del controlador.
class PantallaInicioMarketplace extends StatelessWidget {
  const PantallaInicioMarketplace({required this.controlador, super.key});
  final ControladorInicioMarketplace controlador;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (context, _) {
      final estado = controlador.estado;
      return CustomScrollView(
        slivers: [
          CampusCollapsingHeader(
            nombre: UsuarioPrueba.estudiante.nombre,
            categorias: controlador.repositorio.obtenerCategorias(),
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
                child: SeccionLocalesUniversitarios(
                  locales: estado.locales,
                  construirDetalle: (_, local) => PantallaDetalleLocal(
                    local: local,
                    productos: controlador.repositorio.obtenerProductos(
                      local.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
