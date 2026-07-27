import 'package:flutter/material.dart';

import '../../carrito_compras/logica/controlador_carrito_compras.dart';
import '../../favoritos/logica/controlador_favoritos.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../pantalla/pantalla_detalle_producto.dart';

/// Cuadrícula responsiva de productos inspirada en un catálogo de mercado.
class ListaProductosLocal extends StatelessWidget {
  const ListaProductosLocal({required this.productos, this.local, super.key});

  final List<ProductoMarketplace> productos;

  /// Local comun a todos los productos (catalogo de un vendedor).
  /// En listas mixtas como favoritos se omite y cada producto trae el suyo.
  final LocalUniversitario? local;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ControladorFavoritos.instancia,
    builder: (context, _) => LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth >= 840
            ? 4
            : restricciones.maxWidth >= 560
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: columnas == 2 ? 282 : 292,
          ),
          itemBuilder: (_, indice) =>
              _TarjetaProducto(producto: productos[indice], local: local),
        );
      },
    ),
  );
}

class _TarjetaProducto extends StatefulWidget {
  const _TarjetaProducto({required this.producto, this.local});

  final ProductoMarketplace producto;
  final LocalUniversitario? local;

  @override
  State<_TarjetaProducto> createState() => _TarjetaProductoState();
}

class _TarjetaProductoState extends State<_TarjetaProducto> {
  bool get _favorito =>
      ControladorFavoritos.instancia.contiene(widget.producto);

  /// El local del catalogo si lo hay; si no, el que trae el propio producto.
  LocalUniversitario? get _local => widget.local ?? widget.producto.local;

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _abrirDetalle() {
    final local = _local;
    if (local == null) {
      _avisar('No se pudo identificar el local de este producto.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaDetalleProducto(
          producto: widget.producto,
          local: local,
        ),
      ),
    );
  }

  Future<void> _agregar() async {
    final carrito = ControladorCarritoCompras.instancia;
    final local = _local;

    if (local == null) {
      _avisar('No se pudo identificar el local de este producto.');
      return;
    }
    if (!widget.producto.hayExistencias) {
      _avisar('${widget.producto.nombre} está agotado.');
      return;
    }

    // Un pedido = un local. Si el carrito ya tiene items de otro vendedor,
    // se pide confirmacion antes de descartarlos.
    if (carrito.esDeOtroLocal(widget.producto)) {
      final reemplazar = await _confirmarCambioDeLocal(carrito.local?.nombre);
      if (reemplazar != true) return;
    }

    carrito.agregar(widget.producto, local);
    if (mounted) _avisar('${widget.producto.nombre} agregado al carrito');
  }

  Future<bool?> _confirmarCambioDeLocal(String? localActual) =>
      showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Vaciar el carrito'),
          content: Text(
            'Tu carrito tiene productos de ${localActual ?? 'otro local'}. '
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

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      // Tocar la tarjeta abre el detalle con las fotos; el boton "+" de
      // abajo sigue agregando directo para quien ya sabe lo que quiere.
      onTap: _abrirDetalle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFECEFED)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 2),
                    // Foto real si el vendedor subio una; emoji si no.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: switch (widget.producto.imagenUrl) {
                        final String url => Image.network(
                          url,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, _, _) => _FondoEmoji(
                            emoji: widget.producto.emoji,
                          ),
                        ),
                        _ => _FondoEmoji(emoji: widget.producto.emoji),
                      },
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF739376),
                      ),
                      onPressed: () => ControladorFavoritos.instancia.alternar(
                        widget.producto,
                      ),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          _favorito
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(_favorito),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2EA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _cantidad(widget.producto),
                      style: const TextStyle(
                        color: Color(0xFF739376),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF292A29),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: Color(0xFF739376),
                      ),
                      SizedBox(width: 3),
                      Text(
                        '10–15 min',
                        style: TextStyle(
                          color: Color(0xFF858585),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bs ${widget.producto.precio.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF202220),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF55785A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _agregar,
                        icon: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String _cantidad(ProductoMarketplace producto) {
    final coincidencia = RegExp(
      r'\d+\s*(?:ml|hojas)',
      caseSensitive: false,
    ).firstMatch(producto.descripcion);
    return coincidencia?.group(0) ?? '1 unidad';
  }
}

/// Respaldo visual cuando el producto no tiene foto (o esta fallo al cargar).
class _FondoEmoji extends StatelessWidget {
  const _FondoEmoji({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF1F6F0),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 68))),
  );
}
