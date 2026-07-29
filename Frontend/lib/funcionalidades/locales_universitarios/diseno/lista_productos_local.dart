import 'package:flutter/material.dart';

import '../../favoritos/logica/controlador_favoritos.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../visualizaciones/indicador_vistas.dart';
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
            mainAxisSpacing: 14,
            mainAxisExtent: columnas == 2 ? 270 : 282,
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
        builder: (_) =>
            PantallaDetalleProducto(producto: widget.producto, local: local),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = oscuro ? Colors.white : Colors.black;
    return Material(
      color: oscuro ? const Color(0xFF151815) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrirDetalle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: oscuro ? const Color(0xFF283028) : const Color(0xFFE9E4DD),
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: oscuro
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x174A3928),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    switch (widget.producto.imagenUrl) {
                      final String url => Image.network(
                        url,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, _, _) =>
                            _FondoEmoji(emoji: widget.producto.emoji),
                      ),
                      _ => _FondoEmoji(emoji: widget.producto.emoji),
                    },
                    Positioned(
                      top: 7,
                      right: 7,
                      child: IconButton(
                        tooltip: 'Guardar en favoritos',
                        onPressed: () => ControladorFavoritos.instancia
                            .alternar(widget.producto),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                        ),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _favorito
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(_favorito),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 11, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 15,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.producto.descripcion.isEmpty
                          ? (widget.producto.esServicio
                                ? 'Servicio disponible'
                                : 'Producto disponible')
                          : widget.producto.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Quien vende, en la propia tarjeta: sin esto habia que
                    // abrir cada publicacion para saber de quien era, y en un
                    // campus eso es justo lo que decide si te interesa.
                    if (widget.producto.local?.nombreVisible
                        case final String vendedor
                        when vendedor.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            widget.producto.local!.esPersonal
                                ? Icons.person_rounded
                                : Icons.storefront_rounded,
                            size: 11,
                            color: colorTexto,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vendedor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorTexto,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bs ${widget.producto.precio.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colorTexto,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IndicadorVistas(
                          total: widget.producto.vistas,
                          compacto: true,
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
  }
}

/// Respaldo visual cuando el producto no tiene foto (o esta fallo al cargar).
class _FondoEmoji extends StatelessWidget {
  const _FondoEmoji({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 48, 48, 48)
        : const Color.fromARGB(255, 240, 240, 240),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 68))),
  );
}
