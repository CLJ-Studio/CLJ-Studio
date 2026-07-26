import 'package:flutter/material.dart';

import '../../mi_local/logica/controlador_mi_local.dart';
import '../logica/controlador_publicacion.dart';
import 'boton_confirmar_publicacion.dart';
import 'campo_descripcion_publicacion.dart';
import 'campo_nombre_publicacion.dart';
import 'campo_precio_publicacion.dart';
import 'selector_emoji_publicacion.dart';
import 'selector_tipo_publicacion.dart';

/// Publica un producto o servicio dentro del local del estudiante.
///
/// Antes guardaba en una lista en memoria paralela al inventario de Mi Local:
/// dos caminos que creaban "productos" sin hablarse. Ahora es uno solo, porque
/// en este marketplace todo producto pertenece a un local.
class FormularioPublicacion extends StatefulWidget {
  const FormularioPublicacion({
    required this.controlador,
    required this.miLocal,
    super.key,
  });

  final ControladorPublicacion controlador;
  final ControladorMiLocal miLocal;

  @override
  State<FormularioPublicacion> createState() => _FormularioPublicacionState();
}

class _FormularioPublicacionState extends State<FormularioPublicacion> {
  final llave = GlobalKey<FormState>();
  final nombre = TextEditingController();
  final descripcion = TextEditingController();
  final precio = TextEditingController();
  final stock = TextEditingController(text: '1');
  bool _publicando = false;

  @override
  void dispose() {
    nombre.dispose();
    descripcion.dispose();
    precio.dispose();
    stock.dispose();
    super.dispose();
  }

  Future<void> publicar() async {
    if (!(llave.currentState?.validate() ?? false)) return;

    setState(() => _publicando = true);
    try {
      await widget.miLocal.agregarProducto(
        nombre: nombre.text,
        precio: double.parse(precio.text.replaceAll(',', '.')),
        // Un servicio no lleva inventario: el backend lo trata como
        // siempre disponible.
        cantidad: widget.controlador.esServicio
            ? 0
            : (int.tryParse(stock.text) ?? 0),
        emoji: widget.controlador.emoji,
      );

      if (!mounted) return;
      nombre.clear();
      descripcion.clear();
      precio.clear();
      stock.text = '1';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Publicado en ${widget.miLocal.nombre ?? 'tu local'}.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo publicar. Intenta de nuevo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _publicando = false);
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
          CampoPrecioPublicacion(controlador: precio),
          // La categoria vive en el local, no en cada producto: por eso ya
          // no se pregunta aqui. En su lugar se pide el stock, que si hacia
          // falta y el formulario no tenia.
          if (!widget.controlador.esServicio) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: stock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad disponible',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (valor) {
                final cantidad = int.tryParse(valor ?? '');
                if (cantidad == null || cantidad < 0) {
                  return 'Ingresa una cantidad válida.';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 18),
          SelectorEmojiPublicacion(
            valor: widget.controlador.emoji,
            alCambiar: widget.controlador.seleccionarEmoji,
          ),
          const SizedBox(height: 22),
          BotonConfirmarPublicacion(
            alPresionar: _publicando ? null : publicar,
          ),
        ],
      ),
    ),
  );
}
