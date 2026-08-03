import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../inicio_marketplace/diseno/campus_collapsing_header.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
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
    builder: (context, _) {
      final buscando = controlador.busqueda.trim().isNotEmpty;
      final localesVisibles = buscando
          ? controlador.catalogoCompleto
          : controlador.locales;

      return Stack(
        children: [
          CustomScrollView(
            physics: buscando ? const NeverScrollableScrollPhysics() : null,
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
                  alAbrirCarrito: () => Navigator.of(
                    context,
                  ).pushNamed(ConfiguracionRutas.carrito),
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
                        else if (localesVisibles.isEmpty)
                          const _SinLocales()
                        else
                          ListaLocales(
                            locales: localesVisibles,
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
          if (buscando)
            Positioned.fill(
              top: widget.mostrarEncabezado ? 118 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  controlador.buscar('');
                },
              ),
            ),
          Positioned(
            top: widget.mostrarEncabezado ? 118 : 0,
            left: 14,
            right: 14,
            child: IgnorePointer(
              ignoring: !buscando,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: buscando ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  scale: buscando ? 1 : .72,
                  child: Material(
                    elevation: 18,
                    shadowColor: const Color(0x55000000),
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 390),
                      child: _ResultadosBusquedaLocales(
                        consulta: controlador.busqueda,
                        locales: controlador.catalogoCompleto,
                        alCerrar: () => controlador.buscar(''),
                      ),
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

class _ResultadosBusquedaLocales extends StatelessWidget {
  const _ResultadosBusquedaLocales({
    required this.consulta,
    required this.locales,
    required this.alCerrar,
  });

  final String consulta;
  final List<LocalUniversitario> locales;
  final VoidCallback alCerrar;

  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u');

  @override
  Widget build(BuildContext context) {
    final buscado = _normalizar(consulta.trim());
    final resultados = locales.where((local) {
      return _normalizar(local.nombreVisible).contains(buscado) ||
          _normalizar(local.descripcion).contains(buscado) ||
          _normalizar(local.categoria).contains(buscado) ||
          _normalizar(local.vendedorNombre).contains(buscado);
    }).toList();

    if (resultados.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF9BA09C)),
            SizedBox(height: 10),
            Text(
              'No encontramos locales',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 4),
            Text(
              'Prueba escribiendo otro nombre o categoría.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7B817D)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: resultados.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, indice) {
        final local = resultados[indice];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE3EEE5),
            foregroundColor: const Color(0xFF2F4034),
            backgroundImage: local.logoUrl == null
                ? null
                : NetworkImage(local.logoUrl!),
            child: local.logoUrl == null ? Text(local.emoji) : null,
          ),
          title: Text(
            local.nombreVisible,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(local.categoria),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            alCerrar();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaDetalleLocal(local: local),
              ),
            );
          },
        );
      },
    );
  }
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
