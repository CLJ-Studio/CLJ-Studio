import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../diseno/formulario_publicacion.dart';
import '../logica/controlador_publicacion.dart';

/// Publicacion directa: no exige tener un local formal.
///
/// Si el estudiante no tiene local, al publicar se crea por detras un
/// espacio personal que hace de contenedor. "Abrir tu local" vive en la
/// seccion Locales, para quien quiera una vitrina formal.
class PantallaPublicarProducto extends StatefulWidget {
  const PantallaPublicarProducto({required this.miLocal, super.key});

  final ControladorMiLocal miLocal;

  @override
  State<PantallaPublicarProducto> createState() =>
      _PantallaPublicarProductoState();
}

class _PantallaPublicarProductoState extends State<PantallaPublicarProducto> {
  final controlador = ControladorPublicacion();

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.miLocal,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
      child: ContenidoCentrado(
        anchoMaximo: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.miLocal.cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: IndicadorCarga(tamanio: 140)),
              )
            else ...[
              FormularioPublicacion(
                controlador: controlador,
                miLocal: widget.miLocal,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
