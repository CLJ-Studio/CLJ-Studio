import 'package:flutter/material.dart';

import '../../carrito_compras/logica/controlador_carrito_compras.dart';
import '../../favoritos/logica/controlador_favoritos.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Detalle del producto con su galeria de fotos.
///
/// Antes las tarjetas agregaban al carrito con un toque, sin dar oportunidad
/// de ver el producto. En un marketplace la decision se toma mirando fotos.
class PantallaDetalleProducto extends StatefulWidget {
  const PantallaDetalleProducto({
    required this.producto,
    required this.local,
    super.key,
  });

  final ProductoMarketplace producto;
  final LocalUniversitario local;

  @override
  State<PantallaDetalleProducto> createState() =>
      _PantallaDetalleProductoState();
}

class _PantallaDetalleProductoState extends State<PantallaDetalleProducto> {
  final _paginas = PageController();
  int _pagina = 0;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  bool get _favorito =>
      ControladorFavoritos.instancia.contiene(widget.producto);

  Future<void> _agregar() async {
    final carrito = ControladorCarritoCompras.instancia;

    if (!widget.producto.hayExistencias) {
      _avisar('${widget.producto.nombre} está agotado.');
      return;
    }

    if (carrito.esDeOtroLocal(widget.producto)) {
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
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Vaciar y agregar'),
            ),
          ],
        ),
      );
      if (reemplazar != true) return;
    }

    carrito.agregar(widget.producto, widget.local);
    if (mounted) _avisar('${widget.producto.nombre} agregado al carrito');
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
    final fotos = widget.producto.galeriaUrls;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        actions: [
          AnimatedBuilder(
            animation: ControladorFavoritos.instancia,
            builder: (context, _) => IconButton(
              tooltip: 'Guardar en favoritos',
              onPressed: () =>
                  ControladorFavoritos.instancia.alternar(widget.producto),
              icon: Icon(
                _favorito
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Galeria(
                  fotos: fotos,
                  emoji: widget.producto.emoji,
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
                        widget.producto.nombre,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bs ${widget.producto.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.producto.esServicio
                            ? 'Servicio'
                            : widget.producto.stock > 0
                            ? '${widget.producto.stock} disponibles'
                            : 'Agotado',
                        style: TextStyle(
                          color: widget.producto.hayExistencias
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : const Color(0xFFB3453B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.producto.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          widget.producto.descripcion,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const Divider(height: 36),
                      _Vendedor(local: widget.local),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: widget.producto.hayExistencias
                              ? _agregar
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: Text(
                            widget.producto.hayExistencias
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
  const _Vendedor({required this.local});

  final LocalUniversitario local;

  /// Quien vende siempre tiene nombre y cara. Si es un negocio manda la
  /// marca y debajo va la persona detras; si vende por su cuenta manda su
  /// nombre y no hace falta segunda linea.
  String? get _subtitulo {
    if (local.esPersonal) return 'Vende por su cuenta';
    return local.vendedorNombre.isEmpty ? null : 'Por ${local.vendedorNombre}';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          shape: BoxShape.circle,
        ),
        child: switch (local.vendedorAvatarUrl) {
          final String url => Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Text(local.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          _ => Center(
            child: Text(local.emoji, style: const TextStyle(fontSize: 20)),
          ),
        },
      ),
      const SizedBox(width: 12),
      // Quien vende siempre tiene nombre y cara. Si es un negocio, manda la
      // marca y debajo va la persona detras; si vende por su cuenta, manda
      // su nombre. "Vendedor independiente" solo decia que no habia negocio.
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local.esPersonal ? local.vendedorNombre : local.nombre,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            // Sin nombre no se pinta un "Por" colgando de la nada.
            if (_subtitulo case final String texto) ...[
              const SizedBox(height: 2),
              Text(
                texto,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
