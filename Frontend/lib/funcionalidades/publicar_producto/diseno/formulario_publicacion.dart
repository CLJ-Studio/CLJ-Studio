import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/selector_galeria.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../datos/borrador_publicacion.dart';
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

  List<String> _galeria = const [];
  bool _publicando = false;
  bool _revisandoBorrador = true;

  @override
  void initState() {
    super.initState();
    _ofrecerBorrador();
    // Cada cambio se guarda: si el usuario sale a sacar una foto o se le
    // cierra la pestana, al volver encuentra lo que habia escrito.
    for (final campo in [nombre, descripcion, precio, stock]) {
      campo.addListener(_guardarBorrador);
    }
  }

  @override
  void dispose() {
    for (final campo in [nombre, descripcion, precio, stock]) {
      campo.removeListener(_guardarBorrador);
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _ofrecerBorrador() async {
    final borrador = await AlmacenBorrador.cargar();
    if (!mounted) return;

    if (borrador == null) {
      setState(() => _revisandoBorrador = false);
      return;
    }

    final retomar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Publicación sin terminar'),
        content: Text(
          'Dejaste "${borrador.resumen}" a medias. ¿Quieres continuarla?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5C8A63),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (retomar == true) {
      nombre.text = borrador.nombre;
      descripcion.text = borrador.descripcion;
      precio.text = borrador.precio;
      stock.text = borrador.stock;
      widget.controlador.seleccionarTipo(borrador.tipo);
      widget.controlador.seleccionarEmoji(borrador.emoji);
      setState(() => _galeria = borrador.galeria);
    } else {
      await AlmacenBorrador.borrar();
    }
    if (mounted) setState(() => _revisandoBorrador = false);
  }

  void _guardarBorrador() {
    if (_revisandoBorrador) return;
    AlmacenBorrador.guardar(
      BorradorPublicacion(
        tipo: widget.controlador.tipo,
        nombre: nombre.text,
        descripcion: descripcion.text,
        precio: precio.text,
        stock: stock.text,
        emoji: widget.controlador.emoji,
        galeria: _galeria,
      ),
    );
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
        descripcion: descripcion.text,
        esServicio: widget.controlador.esServicio,
        galeria: _galeria,
      );

      if (!mounted) return;
      // Publicado: el borrador ya cumplio su funcion.
      await AlmacenBorrador.borrar();
      nombre.clear();
      descripcion.clear();
      precio.clear();
      stock.text = '1';
      setState(() => _galeria = const []);

      if (!mounted) return;
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
    } catch (fallo) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              fallo.toString().contains('CONTENIDO_NO_PERMITIDO')
                  ? 'Revisa el texto: contiene palabras no permitidas.'
                  : 'No se pudo publicar. Intenta de nuevo.',
            ),
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
            alCambiar: (valor) {
              widget.controlador.seleccionarTipo(valor);
              _guardarBorrador();
            },
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
          const SizedBox(height: 20),
          SelectorGaleria(
            rutas: _galeria,
            alCambiar: (rutas) {
              setState(() => _galeria = rutas);
              _guardarBorrador();
            },
          ),
          const SizedBox(height: 18),
          // El emoji sigue siendo el respaldo visual cuando no hay fotos.
          SelectorEmojiPublicacion(
            valor: widget.controlador.emoji,
            alCambiar: (valor) {
              widget.controlador.seleccionarEmoji(valor);
              _guardarBorrador();
            },
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
