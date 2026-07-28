import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../inicio_marketplace/diseno/campus_collapsing_header.dart';
import '../../pedidos/pantalla/pantalla_pedidos_completa.dart';
import '../diseno/invitacion_abrir_local.dart';
import '../diseno/lista_locales.dart';
import '../logica/controlador_locales.dart';
import 'pantalla_detalle_local.dart';

/// Catálogo de negocios del campus, con búsqueda y filtros de categoría.
class PantallaLocalesUniversitarios extends StatefulWidget {
  const PantallaLocalesUniversitarios({
    required this.alCrearLocal,
    required this.yaTieneLocal,
    this.controladorExterno,
    this.mostrarEncabezado = true,
    super.key,
  });

  final VoidCallback alCrearLocal;
  final bool yaTieneLocal;
  final ControladorLocales? controladorExterno;
  final bool mostrarEncabezado;

  @override
  State<PantallaLocalesUniversitarios> createState() =>
      _PantallaLocalesUniversitariosState();
}

class _PantallaLocalesUniversitariosState
    extends State<PantallaLocalesUniversitarios> {
  late final controlador = widget.controladorExterno ?? ControladorLocales();

  @override
  void initState() {
    super.initState();
    if (widget.controladorExterno == null) {
      controlador.cargar();
      controlador.iniciarTiempoReal();
    }
  }

  @override
  void dispose() {
    if (widget.controladorExterno == null) controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([controlador, SesionUsuario.instancia]),
    builder: (context, _) => CustomScrollView(
      slivers: [
        if (widget.mostrarEncabezado)
          CampusCollapsingHeader(
            nombre: SesionUsuario.instancia.primerNombre,
            avatarUrl: SesionUsuario.instancia.perfil?.avatarUrl,
            mostrarCategorias: false,
            categorias: controlador.categorias,
            categoriaId: controlador.categoriaId,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // El acceso al local propio tiene prioridad sobre el
                  // contenido recomendado.
                  InvitacionAbrirLocal(
                    alPresionar: widget.alCrearLocal,
                    yaTieneLocal: widget.yaTieneLocal,
                  ),
                  if (controlador.soloDestacados) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Locales destacados',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        TextButton(
                          onPressed: controlador.mostrarTodos,
                          child: const Text(
                            'Quitar filtro',
                            style: TextStyle(
                              color: Color(0xFF5C8A63),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ] else
                    const SizedBox(height: 20),
                  if (controlador.cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: IndicadorCarga(tamanio: 140)),
                    )
                  else if (controlador.error case final String mensaje)
                    MensajeCatalogo(
                      mensaje: mensaje,
                      alReintentar: controlador.cargar,
                    )
                  else if (controlador.locales.isEmpty)
                    const _SinLocales()
                  else
                    ListaLocales(
                      locales: controlador.locales,
                      construirDetalle: (_, local) =>
                          PantallaDetalleLocal(local: local),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SinLocales extends StatelessWidget {
  const _SinLocales();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 46,
          color: Color(0xFFB8BDB8),
        ),
        const SizedBox(height: 14),
        Text(
          'Todavía no hay locales aquí',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Puedes ser el primero en abrir el tuyo.',
          style: TextStyle(color: Color(0xFF7B817D)),
        ),
      ],
    ),
  );
}
