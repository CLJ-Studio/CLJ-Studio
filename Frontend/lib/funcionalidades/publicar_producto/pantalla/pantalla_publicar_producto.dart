import 'package:flutter/material.dart';

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
            Text(
              'Crear publicación',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Comparte productos o servicios con la comunidad UPSA.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 24),
            if (widget.miLocal.cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // Solo informa el destino cuando hay un local formal; el
              // espacio personal es interno y no hace falta mencionarlo.
              if (widget.miLocal.tieneLocalFormal) ...[
                _AvisoDestino(nombreLocal: widget.miLocal.nombre!),
                const SizedBox(height: 18),
              ],
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

/// Indica en qué local quedará la publicación.
class _AvisoDestino extends StatelessWidget {
  const _AvisoDestino({required this.nombreLocal});

  final String nombreLocal;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(
          Icons.storefront_rounded,
          size: 19,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Se publicará en $nombreLocal',
            style: const TextStyle(
              color: Color(0xFF3F6146),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
