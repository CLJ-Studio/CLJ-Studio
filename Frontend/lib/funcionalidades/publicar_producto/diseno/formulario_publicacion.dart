import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../logica/controlador_publicacion.dart';
import 'boton_confirmar_publicacion.dart';
import 'campo_descripcion_publicacion.dart';
import 'campo_nombre_publicacion.dart';
import 'campo_precio_publicacion.dart';
import 'selector_emoji_publicacion.dart';
import 'selector_tipo_publicacion.dart';

/// Publica un producto o servicio. No exige local: si el estudiante no
/// tiene, el controlador crea su espacio personal por detras.
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
  bool _subiendoFoto = false;
  String? _fotoPath;

  @override
  void dispose() {
    nombre.dispose();
    descripcion.dispose();
    precio.dispose();
    stock.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    setState(() => _subiendoFoto = true);
    try {
      final ruta = await ServicioImagenes.elegirYSubir(etiqueta: 'producto');
      if (ruta != null) setState(() => _fotoPath = ruta);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo subir la foto.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
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
        imagePath: _fotoPath,
      );

      if (!mounted) return;
      nombre.clear();
      descripcion.clear();
      precio.clear();
      stock.text = '1';
      setState(() => _fotoPath = null);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.miLocal.tieneLocalFormal
                  ? 'Publicado en ${widget.miLocal.nombre}.'
                  : 'Publicación creada.',
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
          _SelectorFoto(
            fotoUrl: ServicioImagenes.urlPublica(_fotoPath),
            subiendo: _subiendoFoto,
            alElegir: _elegirFoto,
            alQuitar: () => setState(() => _fotoPath = null),
          ),
          const SizedBox(height: 14),
          // El emoji sigue siendo el respaldo visual cuando no hay foto.
          SelectorEmojiPublicacion(
            valor: widget.controlador.emoji,
            alCambiar: widget.controlador.seleccionarEmoji,
          ),
          const SizedBox(height: 22),
          BotonConfirmarPublicacion(
            alPresionar: _publicando || _subiendoFoto ? null : publicar,
          ),
        ],
      ),
    ),
  );
}

/// Foto opcional del producto: eleva mucho la tarjeta frente al emoji.
class _SelectorFoto extends StatelessWidget {
  const _SelectorFoto({
    required this.fotoUrl,
    required this.subiendo,
    required this.alElegir,
    required this.alQuitar,
  });

  final String? fotoUrl;
  final bool subiendo;
  final VoidCallback alElegir;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              fotoUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: 'Quitar foto',
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: alQuitar,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: subiendo ? null : alElegir,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC9CEC9)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            if (subiendo)
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              )
            else
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 38,
                color: Color(0xFF7C827E),
              ),
            const SizedBox(height: 8),
            Text(
              subiendo ? 'Subiendo foto...' : 'Agregar foto (opcional)',
              style: const TextStyle(color: Color(0xFF7C827E)),
            ),
          ],
        ),
      ),
    );
  }
}
