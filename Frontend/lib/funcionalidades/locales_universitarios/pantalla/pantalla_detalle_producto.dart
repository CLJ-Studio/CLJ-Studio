import 'dart:async';

import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../mi_local/diseno/dialogo_producto.dart';
import '../../mi_local/datos/repositorio_mi_local.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../carrito_compras/diseno/barra_resumen_carrito.dart';
import '../../carrito_compras/logica/controlador_carrito_compras.dart';
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
    final colorContenido = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorContenido,
        actions: [
          // Solo para quien vende: gestionar lo propio se hacia unicamente
          // desde Tu local, asi que una publicacion suelta no se podia
          // editar ni borrar desde ninguna parte.
          if (_esMio)
            PopupMenuButton<String>(
              tooltip: 'Gestionar publicación',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (opcion) => switch (opcion) {
                'editar' => _editar(),
                'ocultar' => _alternarVisibilidad(),
                'relanzar' => _relanzar(),
                _ => _eliminar(),
              },
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
                      _producto.disponible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    title: Text(_producto.disponible ? 'Ocultar' : 'Mostrar'),
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
                    title: Text(
                      'Eliminar',
                      style: TextStyle(color: Color(0xFFB3453B)),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          AnimatedBuilder(
            animation: ControladorFavoritos.instancia,
            builder: (context, _) => IconButton(
              tooltip: 'Guardar en favoritos',
              onPressed: () =>
                  ControladorFavoritos.instancia.alternar(_producto),
              icon: Icon(
                _favorito
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: const Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BarraResumenCarrito(localId: widget.local.id),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Galeria(
                  fotos: fotos,
                  emoji: _producto.emoji,
                  controlador: _paginas,
                  pagina: _pagina,
                  alCambiarPagina: (i) => setState(() => _pagina = i),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _producto.nombre,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colorContenido,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bs ${_producto.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      IndicadorVistas(total: _vistas),
                      const SizedBox(height: 6),
                      Text(
                        _producto.esServicio
                            ? 'Servicio'
                            : _producto.stock > 0
                            ? '${_producto.stock} disponibles'
                            : 'Agotado',
                        style: TextStyle(
                          color: _producto.hayExistencias
                              ? colorContenido
                              : const Color(0xFFB3453B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_producto.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          _producto.descripcion,
                          style: TextStyle(color: colorContenido, height: 1.5),
                        ),
                      ],
                      const Divider(height: 36),
                      _Vendedor(
                        local: widget.local,
                        producto: _producto,
                        navegable: widget.vendedorNavegable,
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _producto.hayExistencias ? _agregar : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: Text(
                            _producto.hayExistencias
                                ? 'Agregar al carrito'
                                : 'Agotado',
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
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria({
    required this.fotos,
    required this.emoji,
    required this.controlador,
    required this.pagina,
    required this.alCambiarPagina,
  });

  final List<String> fotos;
  final String emoji;
  final PageController controlador;
  final int pagina;
  final ValueChanged<int> alCambiarPagina;

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) {
      return Container(
        height: 320,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 110)),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: controlador,
            onPageChanged: alCambiarPagina,
            itemCount: fotos.length,
            itemBuilder: (_, i) => Image.network(
              fotos[i],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 90)),
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
