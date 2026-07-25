import 'package:flutter/material.dart';

import '../logica/controlador_publicacion.dart';
import 'boton_confirmar_publicacion.dart';
import 'campo_descripcion_publicacion.dart';
import 'campo_nombre_publicacion.dart';
import 'campo_precio_publicacion.dart';
import 'selector_categoria_publicacion.dart';
import 'selector_imagenes_publicacion.dart';
import 'selector_tipo_publicacion.dart';

/// Ensambla los campos reutilizables y aplica sus validaciones locales.
class FormularioPublicacion extends StatefulWidget {
  const FormularioPublicacion({required this.controlador, super.key});
  final ControladorPublicacion controlador;
  @override
  State<FormularioPublicacion> createState() => _FormularioPublicacionState();
}

class _FormularioPublicacionState extends State<FormularioPublicacion> {
  final llave = GlobalKey<FormState>();
  void publicar() {
    if (llave.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicacion simulada correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controlador,
    builder: (_, _) => Form(
      key: llave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectorTipoPublicacion(
            valor: widget.controlador.tipo,
            alCambiar: widget.controlador.seleccionarTipo,
          ),
          const SizedBox(height: 18),
          const CampoNombrePublicacion(),
          const SizedBox(height: 14),
          const CampoDescripcionPublicacion(),
          const SizedBox(height: 14),
          SelectorCategoriaPublicacion(
            valor: widget.controlador.categoria,
            alCambiar: widget.controlador.seleccionarCategoria,
          ),
          const SizedBox(height: 14),
          const CampoPrecioPublicacion(),
          const SizedBox(height: 14),
          const SelectorImagenesPublicacion(),
          const SizedBox(height: 22),
          BotonConfirmarPublicacion(alPresionar: publicar),
        ],
      ),
    ),
  );
}
