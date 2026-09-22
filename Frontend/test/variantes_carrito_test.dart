import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/carrito_compras/logica/controlador_carrito_compras.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/local_universitario.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/variante_producto.dart';

/// Lo que se comprueba aqui es que el carrito NO junte lo que el vendedor
/// tiene que preparar por separado. Es todo el sentido de las variantes: si
/// dos sabores caen en una misma linea, al vendedor le llegan "3 empanadas" y
/// no sabe cuantas de cada una.
void main() {
  const local = LocalUniversitario(
    id: 'local-1',
    nombre: 'Doña Empanada',
    categoriaId: 'comida',
    categoria: 'Comida',
    descripcion: '',
    calificacion: 0,
    tiempoEstimado: '10 min',
    estaAbierto: true,
    costoEntrega: 0,
    emoji: '🥟',
    colorHexadecimal: 0xFFFFFFFF,
  );

  const queso = VarianteProducto(id: 'v-queso', nombre: 'Queso');
  const carne = VarianteProducto(id: 'v-carne', nombre: 'Carne');

  const empanada = ProductoMarketplace(
    id: 'p-1',
    localId: 'local-1',
    nombre: 'Empanada',
    descripcion: '',
    precio: 8,
    emoji: '🥟',
    stock: 20,
    variantes: [queso, carne],
  );

  final carrito = ControladorCarritoCompras.instancia;
  setUp(carrito.vaciar);

  test('dos sabores del mismo producto son dos lineas', () {
    carrito.agregar(empanada, local, variante: queso);
    carrito.agregar(empanada, local, variante: carne);

    expect(carrito.elementos, hasLength(2));
    expect(carrito.unidades, 2);
    expect(
      carrito.elementos.map((e) => e.variante?.nombre),
      ['Queso', 'Carne'],
    );
  });

  test('el mismo sabor dos veces suma cantidad, no lineas', () {
    carrito.agregar(empanada, local, variante: queso);
    carrito.agregar(empanada, local, variante: queso);

    expect(carrito.elementos, hasLength(1));
    expect(carrito.elementos.single.cantidad, 2);
  });

  test('el sabor elegido viaja al pedido como id, nunca como nombre', () {
    carrito.agregar(empanada, local, variante: carne);

    final items = carrito.aItemsDePedido();
    expect(items.single['variant_id'], 'v-carne');
    // El nombre lo lee el servidor de la base, igual que el precio: si
    // viajara desde aqui, cualquiera podria pedir un sabor que no existe.
    expect(items.single.containsKey('variant_name'), isFalse);
  });

  test('un producto sin variantes no manda variant_id', () {
    const cuaderno = ProductoMarketplace(
      id: 'p-2',
      localId: 'local-1',
      nombre: 'Cuaderno',
      descripcion: '',
      precio: 15,
      emoji: '📓',
      stock: 3,
    );
    carrito.agregar(cuaderno, local);

    expect(cuaderno.exigeVariante, isFalse);
    expect(carrito.aItemsDePedido().single.containsKey('variant_id'), isFalse);
  });
}
