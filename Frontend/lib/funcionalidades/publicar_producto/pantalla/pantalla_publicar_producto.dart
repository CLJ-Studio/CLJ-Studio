import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
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
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
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
              const _EncabezadoPublicar(),
              const SizedBox(height: 22),
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

class _EncabezadoPublicar extends StatelessWidget {
  const _EncabezadoPublicar();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 24, 18, 24),
    decoration: BoxDecoration(
      color: ConfiguracionTema.verdeMarca,
      borderRadius: BorderRadius.circular(30),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PUBLICA EN MINUTOS',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Convierte una idea\nen tu próxima venta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Agrega los datos, el precio y una buena foto.',
                style: TextStyle(color: Color(0xE6FFFFFF), height: 1.3),
              ),
            ],
          ),
        ),
        SizedBox(width: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Icon(
              Icons.add_photo_alternate_rounded,
              color: ConfiguracionTema.verdeMarca,
              size: 38,
            ),
          ),
        ),
      ],
    ),
  );
}
