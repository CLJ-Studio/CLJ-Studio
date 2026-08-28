import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import 'selector_categoria_publicacion.dart';
import '../../inicio_marketplace/modelos/categoria_marketplace.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../../elementos_compartidos/imagenes/selector_galeria.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../datos/borrador_publicacion.dart';
import '../logica/controlador_publicacion.dart';
import 'boton_confirmar_publicacion.dart';
import 'campo_descripcion_publicacion.dart';
import 'campo_nombre_publicacion.dart';
import 'campo_precio_publicacion.dart';

/// Publica un producto. No exige local: si el estudiante no tiene, el
/// controlador crea su espacio personal por detrás.
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
  final stock = TextEditingController();

  List<String> _galeria = const [];
  List<CategoriaMarketplace> _categorias = const [];
  String? _categoriaId;
  bool _publicando = false;
  bool _revisandoBorrador = true;
  bool _limpiandoFormulario = false;

  @override
  void initState() {
    super.initState();
    // El formulario simplificado publica productos; ya no pide elegir entre
    // producto y servicio como un paso separado.
    widget.controlador.seleccionarTipo('Producto');
    _cargarCategorias();
    _ofrecerBorrador();
    // Cada cambio se guarda: si el usuario sale a sacar una foto o se le
    // cierra la pestana, al volver encuentra lo que habia escrito.
    for (final campo in [nombre, descripcion, precio, stock]) {
      campo.addListener(_alCambiarCampo);
    }
  }

  @override
  void dispose() {
    for (final campo in [nombre, descripcion, precio, stock]) {
      campo.removeListener(_alCambiarCampo);
      campo.dispose();
    }
    super.dispose();
  }

  void _alCambiarCampo() {
    if (_limpiandoFormulario) return;
    _guardarBorrador();
    if (mounted) setState(() {});
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
              backgroundColor: ConfiguracionTema.verdeMarca,
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
      widget.controlador.seleccionarEmoji(borrador.emoji);
      setState(() => _galeria = borrador.galeria);
    } else {
      await AlmacenBorrador.borrar();
    }
    if (mounted) setState(() => _revisandoBorrador = false);
  }

  void _guardarBorrador() {
    if (_revisandoBorrador || _limpiandoFormulario) return;
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

  /// Las mismas que filtran el inicio: si aqui hubiera otra lista, algo
  /// publicado podria caer en una categoria que la barra no ofrece.
  Future<void> _cargarCategorias() async {
    try {
      final lista = await const RepositorioInicioMarketplace()
          .obtenerCategorias();
      if (mounted) setState(() => _categorias = lista);
    } catch (_) {
      // Sin categorias el paso no aparece; publicar sigue funcionando y la
      // publicacion hereda la del local.
    }
  }

  Future<void> publicar() async {
    if (!(llave.currentState?.validate() ?? false)) return;

    setState(() => _publicando = true);
    try {
      await widget.miLocal.agregarProducto(
        nombre: nombre.text,
        precio: double.parse(precio.text.replaceAll(',', '.')),
        // La cantidad es opcional. Una publicación nueva conserva una unidad
        // disponible cuando el usuario deja el campo vacío.
        cantidad: int.tryParse(stock.text) ?? 1,
        emoji: widget.controlador.emoji,
        descripcion: descripcion.text,
        esServicio: false,
        galeria: _galeria,
        categoriaId: _categoriaId,
      );

      if (!mounted) return;
      // Mientras se vacian los controladores no se autoguarda cada estado
      // intermedio; de lo contrario el ultimo campo vuelve a crear el
      // borrador que acabamos de borrar.
      _limpiandoFormulario = true;
      try {
        nombre.clear();
        descripcion.clear();
        precio.clear();
        stock.clear();
        widget.controlador.seleccionarTipo('Producto');
        widget.controlador.seleccionarEmoji('🛍️');
        setState(() => _galeria = const []);
        await AlmacenBorrador.borrar();
      } finally {
        _limpiandoFormulario = false;
      }

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
    builder: (_, _) {
      final oscuro = Theme.of(context).brightness == Brightness.dark;
      final pasosObligatorios = [
        nombre.text.trim().length >= 3 && descripcion.text.trim().isNotEmpty,
        double.tryParse(precio.text.replaceAll(',', '.')) != null,
      ];
      final pasoActivo = pasosObligatorios.indexWhere((valor) => !valor);
      final formularioCompleto = pasosObligatorios.every((valor) => valor);
      final colorTextoSecundario = oscuro ? Colors.white : Colors.black;

      return Form(
        key: llave,
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: colorTextoSecundario,
              displayColor: colorTextoSecundario,
            ),
            inputDecorationTheme: Theme.of(context).inputDecorationTheme
                .copyWith(
                  filled: true,
                  fillColor: oscuro
                      ? const Color(0xFF090B09)
                      : const Color(0xFFF1F5F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: ConfiguracionTema.verdeMarca,
                      width: 1.5,
                    ),
                  ),
                  labelStyle: TextStyle(color: colorTextoSecundario),
                  hintStyle: TextStyle(color: colorTextoSecundario),
                  prefixIconColor: colorTextoSecundario,
                  prefixStyle: TextStyle(color: colorTextoSecundario),
                ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PasoPublicacion(
                numero: '01',
                completo: pasosObligatorios[0],
                activo: pasoActivo == 0,
                child: _TarjetaFormulario(
                  titulo: 'Cuéntanos lo esencial',
                  child: Column(
                    children: [
                      CampoNombrePublicacion(controlador: nombre),
                      const SizedBox(height: 13),
                      CampoDescripcionPublicacion(controlador: descripcion),
                      if (_categorias.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SelectorCategoriaPublicacion(
                          categorias: _categorias,
                          seleccionada: _categoriaId,
                          alSeleccionar: (id) =>
                              setState(() => _categoriaId = id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _PasoPublicacion(
                numero: '02',
                completo: pasosObligatorios[1],
                activo: pasoActivo == 1,
                child: _TarjetaFormulario(
                  titulo: 'Precio y disponibilidad',
                  child: LayoutBuilder(
                    builder: (context, restricciones) {
                      final precioWidget = CampoPrecioPublicacion(
                        controlador: precio,
                      );
                      final stockWidget = TextFormField(
                        controller: stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Si quieres, indica la cantidad',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return null;
                          }
                          final cantidad = int.tryParse(valor);
                          return cantidad == null || cantidad < 0
                              ? 'Ingresa una cantidad válida.'
                              : null;
                        },
                      );
                      if (restricciones.maxWidth < 520) {
                        return Column(
                          children: [
                            precioWidget,
                            const SizedBox(height: 13),
                            stockWidget,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: precioWidget),
                          const SizedBox(width: 13),
                          Expanded(child: stockWidget),
                        ],
                      );
                    },
                  ),
                ),
              ),
              _PasoPublicacion(
                numero: '03',
                completo: _galeria.isNotEmpty,
                activo: pasoActivo == -1,
                ultimo: true,
                child: _TarjetaFormulario(
                  titulo: 'Fotos opcionales',
                  child: SelectorGaleria(
                    rutas: _galeria,
                    alCambiar: (rutas) {
                      setState(() => _galeria = rutas);
                      _guardarBorrador();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              BotonConfirmarPublicacion(
                alPresionar: _publicando || !formularioCompleto
                    ? null
                    : publicar,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PasoPublicacion extends StatelessWidget {
  const _PasoPublicacion({
    required this.numero,
    required this.completo,
    required this.activo,
    required this.child,
    this.ultimo = false,
  });

  final String numero;
  final bool completo;
  final bool activo;
  final bool ultimo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: EdgeInsets.only(left: 54, bottom: ultimo ? 0 : 16),
        child: child,
      ),
      if (!ultimo)
        Positioned(
          left: 21.5,
          top: 38,
          bottom: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            width: 5,
            decoration: BoxDecoration(
              color: completo
                  ? ConfiguracionTema.verdeMarca
                  : const Color(0xFFDFE4DF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      Positioned(
        left: 3,
        top: 0,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: activo ? 38 : 32,
              height: activo ? 38 : 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completo
                    ? ConfiguracionTema.verdeMarca
                    : activo
                    ? Colors.white
                    : const Color(0xFFDFE4DF),
                shape: BoxShape.circle,
                border: activo
                    ? Border.all(color: ConfiguracionTema.verdeMarca, width: 4)
                    : null,
                boxShadow: activo
                    ? const [
                        BoxShadow(color: Color(0x44138A5B), blurRadius: 12),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: completo
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('completo'),
                        color: Colors.white,
                        size: 18,
                      )
                    : Text(
                        numero,
                        key: ValueKey(numero),
                        style: TextStyle(
                          color: activo
                              ? ConfiguracionTema.verdeMarca
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _TarjetaFormulario extends StatelessWidget {
  const _TarjetaFormulario({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: oscuro ? const Color(0xFF19161B) : Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: oscuro ? Colors.white : Colors.black,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
