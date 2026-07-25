import 'package:flutter/material.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../diseno/formulario_publicacion.dart';
import '../logica/controlador_publicacion.dart';

/// Pantalla responsiva de publicación temporal.
class PantallaPublicarProducto extends StatefulWidget {
  const PantallaPublicarProducto({super.key});
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
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
    child: ContenidoCentrado(
      anchoMaximo: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crear publicacion',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Text(
            'Comparte productos o servicios con la comunidad UPSA.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          FormularioPublicacion(controlador: controlador),
        ],
      ),
    ),
  );
}
