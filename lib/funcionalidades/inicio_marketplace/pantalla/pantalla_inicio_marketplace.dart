import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../datos_prueba/usuario_prueba.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_local.dart';
import '../diseno/barra_busqueda_marketplace.dart';
import '../diseno/barra_categorias_marketplace.dart';
import '../diseno/encabezado_inicio_marketplace.dart';
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
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
        child: ContenidoCentrado(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoInicioMarketplace(
                nombre: UsuarioPrueba.estudiante.nombre,
                alAbrirCarrito: () =>
                    Navigator.of(context).pushNamed(ConfiguracionRutas.carrito),
              ),
              const SizedBox(height: 24),
              BarraBusquedaMarketplace(alCambiar: controlador.buscar),
              const SizedBox(height: 18),
              BarraCategoriasMarketplace(
                categorias: controlador.repositorio.obtenerCategorias(),
                categoriaId: estado.categoriaId,
                alSeleccionar: controlador.seleccionarCategoria,
              ),
              const SizedBox(height: 28),
              SeccionLocalesUniversitarios(
                locales: estado.locales,
                construirDetalle: (_, local) => PantallaDetalleLocal(
                  local: local,
                  productos: controlador.repositorio.obtenerProductos(local.id),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
