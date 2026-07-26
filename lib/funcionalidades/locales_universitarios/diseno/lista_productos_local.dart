import 'package:flutter/material.dart';

import '../../favoritos/logica/controlador_favoritos.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Cuadrícula responsiva de productos inspirada en un catálogo de mercado.
class ListaProductosLocal extends StatelessWidget {
  const ListaProductosLocal({required this.productos, super.key});

  final List<ProductoMarketplace> productos;

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
              _TarjetaProducto(producto: productos[indice]),
        );
      },
    ),
  );
}

class _TarjetaProducto extends StatefulWidget {
  const _TarjetaProducto({required this.producto});

  final ProductoMarketplace producto;

  @override
  State<_TarjetaProducto> createState() => _TarjetaProductoState();
}

class _TarjetaProductoState extends State<_TarjetaProducto> {
  bool get _favorito =>
      ControladorFavoritos.instancia.contiene(widget.producto);

  String? get _imagen => switch (widget.producto.id) {
    'cafe' => 'assets/images/real/coffee2.jpg',
    'sandwich' => 'assets/images/real/hamburger.jpg',
    'jugo' => 'assets/images/real/fruit.jpg',
    _ => null,
  };

  void _agregar() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${widget.producto.nombre} agregado al carrito'),
          duration: const Duration(milliseconds: 1100),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: _agregar,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: _imagen == null
                          ? ColoredBox(
                              color: const Color(0xFFF1F6F0),
                              child: Center(
                                child: Text(
                                  widget.producto.emoji,
                                  style: const TextStyle(fontSize: 68),
                                ),
                              ),
                            )
                          : Image.asset(
                              _imagen!,
                              fit: BoxFit.cover,
                              cacheWidth: 600,
                              filterQuality: FilterQuality.low,
                            ),
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
