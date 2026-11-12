import 'dart:math' as math;

import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../inicio_marketplace/modelos/variante_producto.dart';
import '../modelos/pedido.dart';

/// Lo que se puede volver a pedir de un pedido viejo, con lo que hay hoy en
/// el local.
typedef Repeticion = ({
  List<(ProductoMarketplace, VarianteProducto?, int)> lineas,
  int omitidos,
  int sinSabor,
});

/// Arma de nuevo las lineas de [items] con los [productos] actuales del
/// local.
///
/// Un producto con sabores vuelve con el MISMO sabor de la vez pasada. Si ese
/// sabor ya no existe no se adivina otro (podria costar distinto o no ser lo
/// que quiere): cuenta en `sinSabor` para que elija desde el local. Lo que ya
/// no esta, o no tiene stock, cuenta en `omitidos`.
Repeticion repetirPedido(
  List<ItemPedido> items,
  List<ProductoMarketplace> productos,
) {
  final lineas = <(ProductoMarketplace, VarianteProducto?, int)>[];
  // Lo que ya se tomo de cada producto: dos sabores del mismo producto salen
  // del mismo stock.
  final usado = <String, int>{};
  var omitidos = 0;
  var sinSabor = 0;
  for (final item in items) {
    final producto = _encontrarProducto(item, productos);
    if (producto == null || !producto.disponible) {
      omitidos++;
      continue;
    }
    VarianteProducto? variante;
    if (producto.variantes.isNotEmpty) {
      variante = _encontrarVariante(item, producto);
      if (variante == null) {
        sinSabor++;
        continue;
      }
    }
    final yaUsado = usado[producto.id] ?? 0;
    final cantidad = producto.esServicio
        ? item.cantidad
        : math.min(item.cantidad, producto.stock - yaUsado);
    if (cantidad <= 0) {
      omitidos++;
      continue;
    }
    usado[producto.id] = yaUsado + cantidad;
    lineas.add((producto, variante, cantidad));
  }
  return (lineas: lineas, omitidos: omitidos, sinSabor: sinSabor);
}

/// El sabor que se pidio, por su nombre: el pedido lo guarda congelado y sin
/// id.
VarianteProducto? _encontrarVariante(
  ItemPedido item,
  ProductoMarketplace producto,
) {
  final nombre = item.variante?.trim().toLowerCase();
  if (nombre == null || nombre.isEmpty) return null;
  for (final variante in producto.variantes) {
    if (variante.nombre.trim().toLowerCase() == nombre) return variante;
  }
  return null;
}

ProductoMarketplace? _encontrarProducto(
  ItemPedido item,
  List<ProductoMarketplace> productos,
) {
  for (final producto in productos) {
    if (item.productoId != null && producto.id == item.productoId) {
      return producto;
    }
  }
  final nombre = item.nombre.trim().toLowerCase();
  for (final producto in productos) {
    if (producto.nombre.trim().toLowerCase() == nombre) return producto;
  }
  return null;
}
