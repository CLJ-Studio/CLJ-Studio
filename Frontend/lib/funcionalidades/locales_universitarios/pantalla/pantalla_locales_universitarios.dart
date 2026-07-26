import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/diseno/barra_categorias_marketplace.dart';
import '../../inicio_marketplace/logica/controlador_inicio_marketplace.dart';
import 'pantalla_detalle_local.dart';
import '../diseno/buscador_locales.dart';
import '../diseno/encabezado_locales.dart';
import '../diseno/filtros_locales.dart';
import '../diseno/invitacion_abrir_local.dart';
import '../diseno/lista_locales.dart';

/// Catálogo completo con búsqueda y filtros de categoría.
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
  late final controlador = ControladorInicioMarketplace(
    const RepositorioInicioMarketplace(),
  );

  @override
  void initState() {
    super.initState();
    controlador.cargar();
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
            const FiltrosLocales(),
            const SizedBox(height: 12),
            BarraCategoriasMarketplace(
              categorias: controlador.estado.categorias,
              categoriaId: controlador.estado.categoriaId,
              alSeleccionar: controlador.seleccionarCategoria,
            ),
            const SizedBox(height: 20),
            if (controlador.estado.categoriaId == 'comida') ...[
              InvitacionAbrirLocal(
                alPresionar: widget.alCrearLocal,
                yaTieneLocal: widget.yaTieneLocal,
              ),
              const SizedBox(height: 24),
            ],
            if (controlador.estado.cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controlador.estado.error case final String mensaje)
              MensajeCatalogo(
                mensaje: mensaje,
                alReintentar: controlador.cargar,
              )
            else
              ListaLocales(
                locales: controlador.estado.locales,
                construirDetalle: (_, local) =>
                    PantallaDetalleLocal(local: local),
              ),
          ],
        ),
      ),
    ),
  );
}
