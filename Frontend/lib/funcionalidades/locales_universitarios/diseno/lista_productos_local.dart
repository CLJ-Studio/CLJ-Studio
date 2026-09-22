import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/foto_producto.dart';
import '../../../elementos_compartidos/tarjetas_aplicacion/estilo_tarjeta_producto.dart';
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
        const separacion = 12.0;
        final anchoTarjeta =
            (restricciones.maxWidth - separacion * (columnas - 1)) / columnas;
        // El alto de la celda se calcula, no se elige. Antes era un numero
        // suelto (270) y la foto se quedaba con lo que sobrara: en un telefono
        // ancho salia con otra forma que en uno angosto, y distinta de como se
        // veia la misma publicacion en el inicio. Ahora manda la foto, que
        // tiene proporcion fija, y al texto se le reserva su parte.
        final altoTexto =
            _altoTexto *
            MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: separacion,
            mainAxisSpacing: 14,
            mainAxisExtent: anchoTarjeta / proporcionFotoProducto + altoTexto,
          ),
          itemBuilder: (_, indice) =>
              _TarjetaProducto(producto: productos[indice], local: local),
        );
      },
    ),
  );
}

/// Lo que ocupa el bloque de texto bajo la foto, con la tipografia comun.
const _altoTexto = 134.0;

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
          // `widget.local` solo viene informado en el catalogo de un
          // local concreto; en el inicio y en favoritos es null porque
          // ahi se mezclan varios vendedores.
          vendedorNavegable: widget.local == null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: oscuro ? const Color(0xFF474646) : Colors.white,
      borderRadius: EstiloTarjetaProducto.borde,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrirDetalle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: oscuro ? const Color(0xFF474646) : Colors.white,
            ),
            borderRadius: EstiloTarjetaProducto.borde,
            boxShadow: oscuro
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x17474646),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  FotoProducto(
                    url: widget.producto.imagenUrl,
                    // Fijo: con mas columnas las tarjetas son aun mas
                    // chicas, asi que esto sobra en todos los tamanos.
                    anchoVisible: 220,
                    alFallar: _FondoEmoji(emoji: widget.producto.emoji),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: IconButton(
                      tooltip: 'Guardar en favoritos',
                      onPressed: () =>
                          ControladorFavoritos.instancia.alternar(
                            widget.producto,
                          ),
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFFAE7960),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 11, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: EstiloTarjetaProducto.nombre(context),
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
                        style: EstiloTarjetaProducto.apoyo(context),
                      ),
                      // Quien vende, en la propia tarjeta: sin esto habia que
                      // abrir cada publicacion para saber de quien era, y en
                      // un campus eso es justo lo que decide si te interesa.
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
                              size: 12,
                              color: EstiloTarjetaProducto.apoyo(context).color,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vendedor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: EstiloTarjetaProducto.apoyo(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bs ${widget.producto.precio.toStringAsFixed(2)}',
                              style: EstiloTarjetaProducto.precio(context),
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
