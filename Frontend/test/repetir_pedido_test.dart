import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/variante_producto.dart';
import 'package:upsa_eat/funcionalidades/pedidos/logica/repetir_pedido.dart';
import 'package:upsa_eat/funcionalidades/pedidos/modelos/pedido.dart';

const _queso = VarianteProducto(id: 'v-queso', nombre: 'Queso');
const _carne = VarianteProducto(id: 'v-carne', nombre: 'Carne', precio: 9);

const _empanada = ProductoMarketplace(
  id: 'p-empanada',
  localId: 'l-1',
  nombre: 'Empanada',
  descripcion: '',
  precio: 7,
  emoji: '🥟',
  stock: 5,
  variantes: [_queso, _carne],
);

const _jugo = ProductoMarketplace(
  id: 'p-jugo',
  localId: 'l-1',
  nombre: 'Jugo',
  descripcion: '',
  precio: 5,
  emoji: '🧃',
  stock: 10,
);

ItemPedido _item(String nombre, int cantidad, {String? id, String? variante}) =>
    ItemPedido(
      nombre: nombre,
      emoji: '',
      precioUnitario: 0,
      cantidad: cantidad,
      productoId: id,
      variante: variante,
    );

void main() {
  test('vuelve con el mismo sabor, aunque cambie mayusculas', () {
    final r = repetirPedido(
      [_item('Empanada', 2, id: 'p-empanada', variante: ' carne ')],
      const [_empanada],
    );
    expect(r.lineas.single.$2, _carne);
    expect(r.lineas.single.$3, 2);
    expect((r.omitidos, r.sinSabor), (0, 0));
  });

  test('si el sabor ya no existe no inventa otro', () {
    final r = repetirPedido(
      [
        _item('Empanada', 1, id: 'p-empanada', variante: 'Pollo'),
        _item('Jugo', 1, id: 'p-jugo'),
      ],
      const [_empanada, _jugo],
    );
    expect(r.lineas.single.$1, _jugo);
    expect(r.lineas.single.$2, isNull);
    expect(r.sinSabor, 1);
  });

  test('un pedido sin sabor de un producto que ahora tiene sabores', () {
    final r = repetirPedido(
      [_item('Empanada', 1, id: 'p-empanada')],
      const [_empanada],
    );
    expect(r.lineas, isEmpty);
    expect(r.sinSabor, 1);
  });

  test('dos sabores del mismo producto comparten el stock', () {
    final r = repetirPedido(
      [
        _item('Empanada', 4, id: 'p-empanada', variante: 'Queso'),
        _item('Empanada', 4, id: 'p-empanada', variante: 'Carne'),
      ],
      const [_empanada],
    );
    expect([for (final l in r.lineas) l.$3], [4, 1]);
  });

  test('lo que ya no esta cuenta como omitido', () {
    final r = repetirPedido([_item('Torta', 1, id: 'p-torta')], const [_jugo]);
    expect(r.lineas, isEmpty);
    expect(r.omitidos, 1);
  });
}
