import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mi_local/diseno/dialogo_producto.dart';
import '../../mi_local/datos/repositorio_mi_local.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../carrito_compras/logica/controlador_carrito_compras.dart';
import '../../carrito_compras/pantalla/pantalla_carrito_compras.dart';
import '../../favoritos/logica/controlador_favoritos.dart';
import '../../mi_local/diseno/dialogo_ajustar_stock.dart';
import '../diseno/hoja_reportar_publicacion.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../perfil_vendedor/pantalla/pantalla_perfil_publico_vendedor.dart';
import '../../visualizaciones/indicador_vistas.dart';
import '../../visualizaciones/servicio_visualizaciones.dart';

/// Detalle del producto con su galeria de fotos.
///
/// Antes las tarjetas agregaban al carrito con un toque, sin dar oportunidad
/// de ver el producto. En un marketplace la decision se toma mirando fotos.
class PantallaDetalleProducto extends StatefulWidget {
  const PantallaDetalleProducto({
    required this.producto,
    required this.local,
    this.vendedorNavegable = true,
    super.key,
  });

  final ProductoMarketplace producto;
  final LocalUniversitario local;

  /// Si la fila del vendedor lleva a algun sitio.
  ///
  /// Se apaga cuando se llega desde el propio local o desde el perfil de
  /// quien vende: en los dos casos apilaria la pantalla de la que se acaba
  /// de venir, y encadenando eso se puede ir perfil -> publicacion ->
  /// vendedor -> perfil sin fin. El enlace solo existe cuando lleva a algo
  /// que todavia no se esta viendo.
  final bool vendedorNavegable;

  @override
  State<PantallaDetalleProducto> createState() =>
      _PantallaDetalleProductoState();
}

class _PantallaDetalleProductoState extends State<PantallaDetalleProducto>
    with SingleTickerProviderStateMixin {
  static const _repositorio = RepositorioMiLocal();
  final _paginas = PageController();
  final _desplazamiento = ScrollController();
  late final AnimationController _controlModoImagen;
  late final Animation<double> _animacionModoImagen;
  int _pagina = 0;
  bool _imagenExpandida = false;
  late int _vistas = widget.producto.vistas;

  /// Copia viva: editar desde aqui debe verse sin salir y volver a entrar.
  late ProductoMarketplace _producto = widget.producto;

  /// Solo quien vende puede gestionar lo suyo. La comprobacion de verdad la
  /// hace la RLS del servidor; esto solo decide si se enseña el menu.
  bool get _esMio =>
      widget.local.duenoId.isNotEmpty &&
      widget.local.duenoId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _controlModoImagen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      reverseDuration: const Duration(milliseconds: 460),
    );
    _animacionModoImagen = CurvedAnimation(
      parent: _controlModoImagen,
      curve: const Cubic(0.16, 1, 0.3, 1),
      reverseCurve: const Cubic(0.7, 0, 0.84, 0),
    );
    unawaited(
      ServicioVisualizaciones.registrarProducto(_producto.id).then((total) {
        if (mounted && total > 0) setState(() => _vistas = total);
      }),
    );
  }

  @override
  void dispose() {
    _paginas.dispose();
    _desplazamiento.dispose();
    _controlModoImagen.dispose();
    super.dispose();
  }

  Future<void> _cambiarModoImagen({bool? expandir}) async {
    if (_producto.galeriaUrls.isEmpty) return;

    final debeExpandirse = expandir ?? !_imagenExpandida;
    if (debeExpandirse == _imagenExpandida && !_controlModoImagen.isAnimating) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _imagenExpandida = debeExpandirse);

    if (debeExpandirse && _desplazamiento.hasClients) {
      unawaited(
        _desplazamiento.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
    }

    final sinAnimaciones =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    await _controlModoImagen.animateTo(
      debeExpandirse ? 1 : 0,
      duration: sinAnimaciones
          ? Duration.zero
          : debeExpandirse
          ? _controlModoImagen.duration
          : _controlModoImagen.reverseDuration,
    );
  }

  bool get _favorito => ControladorFavoritos.instancia.contiene(_producto);

  Future<void> _agregar() async {
    final carrito = ControladorCarritoCompras.instancia;

    if (!_producto.hayExistencias) {
      _avisar('${_producto.nombre} está agotado.');
      return;
    }

    if (carrito.esDeOtroLocal(_producto)) {
      final reemplazar = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Vaciar el carrito'),
          content: Text(
            'Tu carrito tiene productos de ${carrito.local?.nombre ?? 'otro local'}. '
            'Solo puedes pedir de un local a la vez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(contexto).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF474646),
              ),
              child: const Text('Vaciar y agregar'),
            ),
          ],
        ),
      );
      if (reemplazar != true) return;
    }

    carrito.agregar(_producto, widget.local);
  }

  void _abrirCarrito() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PantallaCarritoCompras()),
  );

  Future<void> _editar() async {
    final datos = await mostrarDialogoProducto(context, producto: _producto);
    if (datos == null) return;

    try {
      await _repositorio.editarProducto(
        productoId: _producto.id,
        nombre: datos.nombre,
        precio: datos.precio,
        stock: datos.cantidad,
        emoji: datos.emoji,
        categoriaId: datos.categoriaId,
        descripcion: datos.descripcion,
        galeria: datos.galeria,
      );
      final actualizado = await const RepositorioInicioMarketplace()
          .obtenerPublicacion(_producto.id);
      if (!mounted) return;
      if (actualizado != null) setState(() => _producto = actualizado);
      _avisar('Publicación actualizada.');
    } catch (_) {
      if (mounted) _avisar('No se pudo guardar el cambio.');
    }
  }

  /// Corrige las unidades tras una venta hecha en persona, sin abrir el
  /// diálogo completo de edición.
  Future<void> _ajustarStock() async {
    final cambiado = await mostrarDialogoAjustarStock(context, _producto);
    if (!cambiado || !mounted) return;

    final actualizado = await const RepositorioInicioMarketplace()
        .obtenerPublicacion(_producto.id);
    if (!mounted) return;
    if (actualizado != null) setState(() => _producto = actualizado);
    _avisar('Unidades actualizadas.');
  }

  Future<void> _alternarVisibilidad() async {
    final visible = !_producto.disponible;
    try {
      await _repositorio.cambiarVisibilidad(_producto.id, visible: visible);
      if (!mounted) return;
      setState(() => _producto = _producto.copiarCon(disponible: visible));
      _avisar(visible ? 'Vuelve a estar visible.' : 'Ya no se muestra.');
    } catch (_) {
      if (mounted) _avisar('No se pudo cambiar la visibilidad.');
    }
  }

  Future<void> _relanzar() async {
    try {
      await _repositorio.relanzarProducto(_producto.id);
      if (mounted) _avisar('Vuelve al inicio del catálogo.');
    } catch (_) {
      if (mounted) _avisar('No se pudo relanzar.');
    }
  }

  Future<void> _eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text(
          'Se eliminará "${_producto.nombre}" para siempre. '
          'Si solo quieres dejar de mostrarla, usa "Ocultar".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAE7960),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await _repositorio.eliminarProducto(_producto.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _avisar('No se pudo eliminar.');
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final fotos = _producto.galeriaUrls;

    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFFE6E1D5),
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([
          ControladorCarritoCompras.instancia,
          _animacionModoImagen,
        ]),
        builder: (context, _) {
          final carrito = ControladorCarritoCompras.instancia;
          final indice = carrito.elementos.indexWhere(
            (elemento) => elemento.producto.id == _producto.id,
          );
          if (indice < 0) return const SizedBox.shrink();
          final cantidad = carrito.elementos[indice].cantidad;

          return Transform.translate(
            offset: Offset(0, 90 * _animacionModoImagen.value),
            child: Opacity(
              opacity: 1 - _animacionModoImagen.value,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: FilledButton(
                                onPressed: _abrirCarrito,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF474646),
                                  shape: const StadiumBorder(),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Ver carrito',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Bs ${carrito.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 126,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Color(0xFFE6E1D5),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFE6E1D5),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18474646),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: IconButton(
                                    tooltip: cantidad == 1
                                        ? 'Eliminar del carrito'
                                        : 'Disminuir cantidad',
                                    onPressed: () => cantidad == 1
                                        ? carrito.eliminar(indice)
                                        : carrito.disminuir(indice),
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      color: Color(0xFF474646),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$cantidad',
                                  style: const TextStyle(
                                    color: Color(0xFF474646),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    tooltip: 'Aumentar cantidad',
                                    onPressed: _producto.hayExistencias
                                        ? () => carrito.aumentar(indice)
                                        : null,
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF474646),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      body: LayoutBuilder(
        builder: (context, limites) => AnimatedBuilder(
          animation: _animacionModoImagen,
          builder: (context, _) {
            final progreso = _animacionModoImagen.value;
            final altoGaleria =
                330 + ((limites.maxHeight + 30) - 330) * progreso;

            return SingleChildScrollView(
              controller: _desplazamiento,
              physics: _imagenExpandida
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          _Galeria(
                            fotos: fotos,
                            emoji: _producto.emoji,
                            prefijoHero: _producto.id,
                            controlador: _paginas,
                            pagina: _pagina,
                            alCambiarPagina: (i) => setState(() => _pagina = i),
                            alto: altoGaleria,
                            progresoExpansion: progreso,
                            alPresionar: () =>
                                _cambiarModoImagen(expandir: true),
                          ),
                          Positioned(
                            top: MediaQuery.paddingOf(context).top + 12,
                            left: 18,
                            child: _BotonCircular(
                              icono: Icons.arrow_back_rounded,
                              etiqueta: 'Volver',
                              alPresionar: () => Navigator.maybePop(context),
                            ),
                          ),
                          if (fotos.isNotEmpty)
                            Positioned(
                              top: MediaQuery.paddingOf(context).top + 68,
                              right: 18,
                              child: Semantics(
                                button: true,
                                label: 'Ampliar imagen del producto',
                                child: _BotonCircular(
                                  icono: _imagenExpandida
                                      ? Icons.close_fullscreen_rounded
                                      : Icons.fullscreen_rounded,
                                  etiqueta: _imagenExpandida
                                      ? 'Volver a la información del producto'
                                      : 'Ver imagen completa',
                                  alPresionar: _cambiarModoImagen,
                                ),
                              ),
                            ),
                          Positioned(
                            top: MediaQuery.paddingOf(context).top + 12,
                            right: 18,
                            child: Row(
                              children: [
                                if (!_esMio) ...[
                                  _BotonCircular(
                                    icono: Icons.flag_outlined,
                                    etiqueta: 'Reportar publicación',
                                    alPresionar: () => mostrarHojaReportar(
                                      context,
                                      productoId: _producto.id,
                                      nombreProducto: _producto.nombre,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                if (_esMio) ...[
                                  _MenuGestionProducto(
                                    disponible: _producto.disponible,
                                    alSeleccionar: (opcion) => switch (opcion) {
                                      'editar' => _editar(),
                                      'stock' => _ajustarStock(),
                                      'ocultar' => _alternarVisibilidad(),
                                      'relanzar' => _relanzar(),
                                      _ => _eliminar(),
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                AnimatedBuilder(
                                  animation: ControladorFavoritos.instancia,
                                  builder: (_, _) => _BotonCircular(
                                    icono: _favorito
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    colorIcono: _favorito
                                        ? const Color(0xFFAE7960)
                                        : const Color(0xFF474646),
                                    etiqueta: 'Guardar en favoritos',
                                    alPresionar: () => ControladorFavoritos
                                        .instancia
                                        .alternar(_producto),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Transform.translate(
                        offset: Offset(0, -22 + (18 * progreso)),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 110),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE6E1D5),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Spacer(),
                                  IndicadorVistas(total: _vistas),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _producto.nombre,
                                style: const TextStyle(
                                  color: Color(0xFF474646),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Bs ${_producto.precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF474646),
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _producto.esServicio
                                        ? 'Servicio'
                                        : _producto.stock > 0
                                        ? '${_producto.stock} disponibles'
                                        : 'Agotado',
                                    style: TextStyle(
                                      color: _producto.hayExistencias
                                          ? const Color(0xFF474646)
                                          : const Color(0xFFAE7960),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: FilledButton(
                                  onPressed: _producto.hayExistencias
                                      ? _agregar
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF474646),
                                    disabledBackgroundColor: const Color(
                                      0xFFBBBCA7,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    _producto.hayExistencias
                                        ? 'Agregar al carrito'
                                        : 'Agotado',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 38,
                                color: Color(0xFFE6E1D5),
                              ),
                              const Text(
                                'Acerca de este producto',
                                style: TextStyle(
                                  color: Color(0xFF474646),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _DescripcionProducto(
                                texto: _producto.descripcion.isEmpty
                                    ? 'El vendedor no añadió una descripción para este producto.'
                                    : _producto.descripcion,
                              ),
                              const SizedBox(height: 26),
                              const Text(
                                'Publicado por',
                                style: TextStyle(
                                  color: Color(0xFF474646),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _Vendedor(
                                local: widget.local,
                                producto: _producto,
                                navegable: widget.vendedorNavegable,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DescripcionProducto extends StatefulWidget {
  const _DescripcionProducto({required this.texto});

  final String texto;

  @override
  State<_DescripcionProducto> createState() => _DescripcionProductoState();
}

class _DescripcionProductoState extends State<_DescripcionProducto> {
  bool _expandida = false;

  static const _estilo = TextStyle(
    color: Color(0xFF848381),
    fontSize: 15,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final medidor = TextPainter(
        text: TextSpan(text: widget.texto, style: _estilo),
        textDirection: Directionality.of(context),
        maxLines: 9,
      )..layout(maxWidth: constraints.maxWidth);
      final superaNueveLineas = medidor.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.texto,
            maxLines: _expandida ? null : 9,
            overflow: _expandida ? TextOverflow.visible : TextOverflow.ellipsis,
            style: _estilo,
          ),
          if (superaNueveLineas || _expandida)
            GestureDetector(
              onTap: () => setState(() => _expandida = !_expandida),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _expandida ? 'Ver menos' : '… más',
                  style: const TextStyle(
                    color: Color(0xFF474646),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _BotonCircular extends StatelessWidget {
  const _BotonCircular({
    required this.icono,
    required this.etiqueta,
    required this.alPresionar,
    this.colorIcono = const Color(0xFF474646),
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback alPresionar;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) => Material(
    color: Color(0xFFE6E1D5),
    shape: const CircleBorder(),
    elevation: 1,
    child: IconButton(
      tooltip: etiqueta,
      onPressed: alPresionar,
      icon: Icon(icono, color: colorIcono),
    ),
  );
}

class _MenuGestionProducto extends StatelessWidget {
  const _MenuGestionProducto({
    required this.disponible,
    required this.alSeleccionar,
  });

  final bool disponible;
  final ValueChanged<String> alSeleccionar;

  @override
  Widget build(BuildContext context) => Material(
    color: Color(0xFFE6E1D5),
    shape: const CircleBorder(),
    elevation: 1,
    child: PopupMenuButton<String>(
      tooltip: 'Gestionar publicación',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: alSeleccionar,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'editar',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'stock',
          child: ListTile(
            leading: Icon(Icons.tag_outlined),
            title: Text('Ajustar unidades'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'ocultar',
          child: ListTile(
            leading: Icon(
              disponible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            title: Text(disponible ? 'Ocultar' : 'Mostrar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'relanzar',
          child: ListTile(
            leading: Icon(Icons.arrow_upward_rounded),
            title: Text('Relanzar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'eliminar',
          child: ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFAE7960),
            ),
            title: Text('Eliminar', style: TextStyle(color: Color(0xFFAE7960))),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );
}

class _Galeria extends StatefulWidget {
  const _Galeria({
    required this.fotos,
    required this.emoji,
    required this.prefijoHero,
    required this.controlador,
    required this.pagina,
    required this.alCambiarPagina,
    required this.alto,
    required this.progresoExpansion,
    required this.alPresionar,
  });

  final List<String> fotos;
  final String emoji;
  final String prefijoHero;
  final PageController controlador;
  final int pagina;
  final ValueChanged<int> alCambiarPagina;
  final double alto;
  final double progresoExpansion;
  final VoidCallback alPresionar;

  @override
  State<_Galeria> createState() => _GaleriaState();
}

class _GaleriaState extends State<_Galeria> {
  late final PageController _paginasAmpliadas = PageController(
    initialPage: widget.pagina,
  );

  @override
  void didUpdateWidget(covariant _Galeria oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pagina != oldWidget.pagina &&
        _paginasAmpliadas.hasClients &&
        (_paginasAmpliadas.page?.round() ?? widget.pagina) != widget.pagina) {
      _paginasAmpliadas.jumpToPage(widget.pagina);
    }
  }

  @override
  void dispose() {
    _paginasAmpliadas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fotos.isEmpty) {
      return Container(
        height: widget.alto,
        color: const Color(0xFFE6E1D5),
        alignment: Alignment.center,
        child: Text(widget.emoji, style: const TextStyle(fontSize: 110)),
      );
    }

    Widget imagen(String url, BoxFit ajuste) => Image.network(
      url,
      fit: ajuste,
      errorBuilder: (_, _, _) => ColoredBox(
        color: const Color(0xFFE6E1D5),
        child: Center(
          child: Text(widget.emoji, style: const TextStyle(fontSize: 90)),
        ),
      ),
    );

    final progresoVisor = ((widget.progresoExpansion - .94) / .06).clamp(
      0.0,
      1.0,
    );
    final estaAmpliada = widget.progresoExpansion >= .995;

    return Semantics(
      button: !estaAmpliada,
      label: estaAmpliada
          ? 'Imagen ampliada. Pellizca para acercar y arrastra para explorar.'
          : 'Mostrar imagen completa',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.progresoExpansion < .1 ? widget.alPresionar : null,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: widget.alto,
              color: Color.lerp(
                const Color(0xFFE6E1D5),
                Colors.white,
                widget.progresoExpansion,
              ),
              child: PageView.builder(
                controller: widget.controlador,
                onPageChanged: widget.alCambiarPagina,
                itemCount: widget.fotos.length,
                itemBuilder: (_, i) => Hero(
                  tag: '${widget.prefijoHero}-imagen-producto-$i',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: 1 - widget.progresoExpansion,
                        child: imagen(widget.fotos[i], BoxFit.cover),
                      ),
                      Opacity(
                        opacity: widget.progresoExpansion,
                        child: imagen(widget.fotos[i], BoxFit.contain),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !estaAmpliada,
                child: Opacity(
                  opacity: progresoVisor,
                  child: PhotoViewGallery.builder(
                    itemCount: widget.fotos.length,
                    pageController: _paginasAmpliadas,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    scrollPhysics: const ClampingScrollPhysics(),
                    onPageChanged: (indice) {
                      if (widget.controlador.hasClients) {
                        widget.controlador.jumpToPage(indice);
                      }
                      widget.alCambiarPagina(indice);
                    },
                    loadingBuilder: (_, progreso) => Center(
                      child: SizedBox.square(
                        dimension: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: const Color(0xFF474646),
                          value: progreso?.expectedTotalBytes == null
                              ? null
                              : progreso!.cumulativeBytesLoaded /
                                    progreso.expectedTotalBytes!,
                        ),
                      ),
                    ),
                    builder: (_, indice) => PhotoViewGalleryPageOptions(
                      key: ValueKey(widget.fotos[indice]),
                      imageProvider: NetworkImage(widget.fotos[indice]),
                      semanticLabel:
                          'Imagen del producto, ${indice + 1} de ${widget.fotos.length}',
                      minScale: PhotoViewComputedScale.contained,
                      initialScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      basePosition: Alignment.center,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: const Color(0xFFE6E1D5),
                        child: Center(
                          child: Text(
                            widget.emoji,
                            style: const TextStyle(fontSize: 90),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.fotos.length > 1)
              Padding(
                padding: EdgeInsets.only(
                  bottom:
                      12 +
                      (MediaQuery.paddingOf(context).bottom *
                          widget.progresoExpansion),
                ),
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.fotos.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == widget.pagina ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              i == widget.pagina
                                  ? const Color(0xFFE6E1D5)
                                  : const Color(0x8AE6E1D5),
                              i == widget.pagina
                                  ? const Color(0xFF474646)
                                  : const Color(0x59474646),
                              widget.progresoExpansion,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Vendedor extends StatelessWidget {
  const _Vendedor({
    required this.local,
    required this.producto,
    this.navegable = true,
  });

  final LocalUniversitario local;
  final ProductoMarketplace producto;

  /// Cuando es falso se pinta igual pero sin responder al toque.
  final bool navegable;

  /// El bloque siempre representa a la persona; la marca queda como contexto.
  String get _subtitulo =>
      local.esPersonal ? 'Vende por su cuenta' : local.nombreVisible;

  @override
  Widget build(BuildContext context) {
    final colorContenido = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFFE6E1D5)
        : Color(0xFF474646);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: !navegable
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PantallaPerfilPublicoVendedor(
                  local: local,
                  publicacionInicial: producto,
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: switch (local.vendedorAvatarUrl) {
                final String url => Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      local.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                _ => Center(
                  child: Text(
                    local.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    local.vendedorNombre,
                    style: TextStyle(
                      color: colorContenido,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitulo,
                    style: TextStyle(color: colorContenido, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Sin flecha si no lleva a ningun sitio: prometerla y no
            // responder es peor que no ponerla.
            if (navegable)
              Icon(Icons.chevron_right_rounded, color: colorContenido),
          ],
        ),
      ),
    );
  }
}
