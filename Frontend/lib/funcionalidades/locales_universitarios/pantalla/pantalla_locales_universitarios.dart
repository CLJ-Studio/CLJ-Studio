import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../inicio_marketplace/diseno/barra_categorias_marketplace.dart';
import '../diseno/buscador_locales.dart';
import '../diseno/encabezado_locales.dart';
import '../diseno/invitacion_abrir_local.dart';
import '../diseno/lista_locales.dart';
import '../logica/controlador_locales.dart';
import 'pantalla_detalle_local.dart';

/// Catálogo de negocios del campus, con búsqueda y filtros de categoría.
class PantallaLocalesUniversitarios extends StatefulWidget {
  const PantallaLocalesUniversitarios({
    required this.alCrearLocal,
    required this.yaTieneLocal,
    super.key,
  });

  final VoidCallback alCrearLocal;
  final bool yaTieneLocal;

  @override
  State<PantallaLocalesUniversitarios> createState() =>
      _PantallaLocalesUniversitariosState();
}

class _PantallaLocalesUniversitariosState
    extends State<PantallaLocalesUniversitarios> {
  final controlador = ControladorLocales();

  @override
  void initState() {
    super.initState();
    controlador.cargar();
    controlador.iniciarTiempoReal();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
      child: ContenidoCentrado(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoLocales(),
            const SizedBox(height: 20),
            BuscadorLocales(alCambiar: controlador.buscar),
            const SizedBox(height: 12),
            BarraCategoriasMarketplace(
              categorias: controlador.categorias,
              categoriaId: controlador.categoriaId,
              alSeleccionar: controlador.seleccionarCategoria,
            ),
            const SizedBox(height: 20),
            // La invitacion va siempre visible: abrir un local no deberia
            // depender de tener seleccionada una categoria concreta.
            InvitacionAbrirLocal(
              alPresionar: widget.alCrearLocal,
              yaTieneLocal: widget.yaTieneLocal,
            ),
            const SizedBox(height: 24),
            if (controlador.cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
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
