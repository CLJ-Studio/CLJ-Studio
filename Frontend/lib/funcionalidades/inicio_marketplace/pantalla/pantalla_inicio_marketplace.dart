import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../locales_universitarios/diseno/lista_productos_local.dart';
import '../../pedidos/pantalla/pantalla_pedidos_completa.dart';
import '../diseno/campus_collapsing_header.dart';
import '../logica/controlador_inicio_marketplace.dart';
import '../logica/estado_inicio_marketplace.dart';

/// Feed con todo lo que se publica en el campus.
///
/// Muestra publicaciones y no locales: el catalogo de cada vendedor vive en
/// la seccion Locales, y aqui se mezcla todo como en cualquier marketplace.
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
            alAbrirPedidos: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PantallaPedidosCompleta(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
            sliver: SliverToBoxAdapter(
              child: ContenidoCentrado(
                anchoMaximo: 1000,
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
                  EstadoInicioMarketplace(publicaciones: []) =>
                    _FeedVacio(hayFiltro: estado.categoriaId != 'todas' ||
                        estado.busqueda.isNotEmpty),
                  _ => ListaProductosLocal(
                    productos: estado.publicaciones,
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

class _FeedVacio extends StatelessWidget {
  const _FeedVacio({required this.hayFiltro});

  final bool hayFiltro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 50,
          color: Color(0xFFB8BDB8),
        ),
        const SizedBox(height: 16),
        Text(
          hayFiltro
              ? 'Nada por aquí todavía'
              : 'Sé el primero en publicar',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          hayFiltro
              ? 'Prueba con otra categoría o busca otra cosa.'
              : 'Lo que publiques aparecerá aquí para toda la comunidad.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7B817D)),
        ),
      ],
    ),
  );
}
