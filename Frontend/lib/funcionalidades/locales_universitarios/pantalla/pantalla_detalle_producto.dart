import 'dart:async';

import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../elementos_compartidos/imagenes/visor_imagen_producto/visor_imagen_producto.dart';
import '../../mi_local/diseno/dialogo_producto.dart';
import '../../mi_local/datos/repositorio_mi_local.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../carrito_compras/logica/controlador_carrito_compras.dart';
import '../../carrito_compras/pantalla/pantalla_carrito_compras.dart';
import '../../favoritos/logica/controlador_favoritos.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import 'pantalla_detalle_local.dart';
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

class _PantallaDetalleProductoState extends State<PantallaDetalleProducto> {
  static const _repositorio = RepositorioMiLocal();
  final _paginas = PageController();
  int _pagina = 0;
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
    unawaited(
      ServicioVisualizaciones.registrarProducto(_producto.id).then((total) {
        if (mounted && total > 0) setState(() => _vistas = total);
      }),
    );
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
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
                backgroundColor: const Color(0xFF55785A),
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
              backgroundColor: const Color(0xFFB3453B),
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
      backgroundColor: Colors.white,
      bottomNavigationBar: AnimatedBuilder(
        animation: ControladorCarritoCompras.instancia,
        builder: (context, _) {
          final carrito = ControladorCarritoCompras.instancia;
          final indice = carrito.elementos.indexWhere(
            (elemento) => elemento.producto.id == _producto.id,
          );
          if (indice < 0) return const SizedBox.shrink();
          final cantidad = carrito.elementos[indice].cantidad;

          return SafeArea(
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
                              backgroundColor: const Color(0xFF185D4E),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE1E1E1)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
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
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              '$cantidad',
                              style: const TextStyle(
                                color: Colors.black,
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
                                  color: Colors.black,
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
          );
        },
      ),
      body: SingleChildScrollView(
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
                            icono: Icons.fullscreen_rounded,
                            etiqueta: 'Ver imagen a pantalla completa',
                            alPresionar: () async {
                              final indice = await VisorImagenProducto.abrir(
                                context: context,
                                imagenes: fotos,
                                indiceInicial: _pagina,
                                prefijoHero: _producto.id,
                                etiquetaSemantica: _producto.nombre,
                              );
                              if (!mounted || indice == null) return;
                              setState(() => _pagina = indice);
                              if (_paginas.hasClients) {
                                _paginas.jumpToPage(indice);
                              }
                            },
                          ),
                        ),
                      ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 12,
                      right: 18,
                      child: Row(
                        children: [
                          if (_esMio) ...[
                            _MenuGestionProducto(
                              disponible: _producto.disponible,
                              alSeleccionar: (opcion) => switch (opcion) {
                                'editar' => _editar(),
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
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF222222),
                              etiqueta: 'Guardar en favoritos',
                              alPresionar: () => ControladorFavoritos.instancia
                                  .alternar(_producto),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 110),
                    decoration: const BoxDecoration(
                      color: Colors.white,
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
                            color: Color(0xFF111111),
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
                                color: Color(0xFF185D4E),
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
                                    ? const Color(0xFF185D4E)
                                    : const Color(0xFFB3453B),
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
                              backgroundColor: const Color(0xFF185D4E),
                              disabledBackgroundColor: const Color(0xFFB8C7C2),
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
                        const Divider(height: 38, color: Color(0xFFE5E5E5)),
                        const Text(
                          'Acerca de este producto',
                          style: TextStyle(
                            color: Color(0xFF171717),
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
                            color: Color(0xFF171717),
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
    color: Color(0xFF666666),
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
                    color: Color(0xFF185D4E),
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
    this.colorIcono = const Color(0xFF222222),
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback alPresionar;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
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
    color: Colors.white,
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
              color: Color(0xFFB3453B),
            ),
            title: Text('Eliminar', style: TextStyle(color: Color(0xFFB3453B))),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );
}

class _Galeria extends StatelessWidget {
  const _Galeria({
    required this.fotos,
    required this.emoji,
    required this.prefijoHero,
    required this.controlador,
    required this.pagina,
    required this.alCambiarPagina,
  });

  final List<String> fotos;
  final String emoji;
  final String prefijoHero;
  final PageController controlador;
  final int pagina;
  final ValueChanged<int> alCambiarPagina;

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) {
      return Container(
        height: 330,
        color: const Color(0xFFFFE9DE),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 110)),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: controlador,
            onPageChanged: alCambiarPagina,
            itemCount: fotos.length,
            itemBuilder: (_, i) => Hero(
              tag: '$prefijoHero-imagen-producto-$i',
              child: Image.network(
                fotos[i],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: const Color(0xFFFFE9DE),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 90)),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (fotos.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < fotos.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == pagina ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == pagina ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
      ],
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

  /// Quien vende siempre tiene nombre y cara. Si es un negocio manda la
  /// marca y debajo va la persona detras; si vende por su cuenta manda su
  /// nombre y no hace falta segunda linea.
  String? get _subtitulo =>
      local.esPersonal ? 'Vende por su cuenta' : local.personaDetras;

  @override
  Widget build(BuildContext context) {
    final colorContenido = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // Cada cosa lleva a lo suyo: si el producto es de un negocio, se abre
      // el local con su catalogo; si lo vende alguien por su cuenta, no hay
      // local que abrir y se va a su perfil. Antes siempre iba al perfil,
      // asi que tocar el nombre de una tienda llevaba a una pantalla de
      // persona que no tenia ni carrera ni sentido.
      onTap: !navegable
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => local.esPersonal
                    ? PantallaPerfilPublicoVendedor(
                        local: local,
                        publicacionInicial: producto,
                      )
                    : PantallaDetalleLocal(local: local),
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
                  // Manda la marca si hay negocio, y la persona si vende
                  // por su cuenta. Al reves salia el nombre de la persona
                  // dos veces y la tienda no aparecia por ningun lado.
                  Text(
                    local.nombreVisible,
                    style: TextStyle(
                      color: colorContenido,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (_subtitulo case final String texto) ...[
                    const SizedBox(height: 2),
                    Text(
                      texto,
                      style: TextStyle(color: colorContenido, fontSize: 12),
                    ),
                  ],
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
