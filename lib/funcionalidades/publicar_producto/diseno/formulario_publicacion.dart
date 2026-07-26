import 'package:flutter/material.dart';

import '../logica/controlador_mis_publicaciones.dart';
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
  final nombre = TextEditingController();
  final descripcion = TextEditingController();
  final precio = TextEditingController();

  @override
  void dispose() {
    nombre.dispose();
    descripcion.dispose();
    precio.dispose();
    super.dispose();
  }

  void publicar() {
    if (llave.currentState?.validate() ?? false) {
      ControladorMisPublicaciones.instancia.publicar(
        tipo: widget.controlador.tipo,
        nombre: nombre.text,
        descripcion: descripcion.text,
        categoria: widget.controlador.categoria,
        precio: double.parse(precio.text),
      );
      nombre.clear();
      descripcion.clear();
      precio.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación guardada en Mis publicaciones.'),
        ),
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
          CampoNombrePublicacion(controlador: nombre),
          const SizedBox(height: 14),
          CampoDescripcionPublicacion(controlador: descripcion),
          const SizedBox(height: 14),
          SelectorCategoriaPublicacion(
            valor: widget.controlador.categoria,
            alCambiar: widget.controlador.seleccionarCategoria,
          ),
          const SizedBox(height: 14),
          CampoPrecioPublicacion(controlador: precio),
          const SizedBox(height: 14),
          const SelectorImagenesPublicacion(),
          const SizedBox(height: 22),
          BotonConfirmarPublicacion(alPresionar: publicar),
        ],
      ),
    ),
  );
}
