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

  // Queso vale lo que el producto; carne cuesta mas.
  const queso = VarianteProducto(id: 'v-queso', nombre: 'Queso');
  const carne = VarianteProducto(id: 'v-carne', nombre: 'Carne', precio: 11);

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
    expect(carrito.elementos.map((e) => e.variante?.nombre), [
      'Queso',
      'Carne',
    ]);
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

  test('cada sabor cobra lo suyo, y el total los suma bien', () {
    carrito.agregar(empanada, local, variante: queso);
    carrito.agregar(empanada, local, variante: carne);

    // Queso no cambia el precio: vale lo que el producto.
    expect(carrito.elementos.first.precioUnitario, 8);
    expect(carrito.elementos.last.precioUnitario, 11);
    expect(carrito.subtotal, 19);
  });

  test('sin precio propio, el sabor vale lo que el producto', () {
    expect(queso.precioSobre(8), 8);
    expect(carne.precioSobre(8), 11);
  });

  test('la tarjeta anuncia el mas barato cuando los precios varian', () {
    expect(empanada.preciosVarian, isTrue);
    expect(empanada.precioMinimo, 8);

    const iguales = ProductoMarketplace(
      id: 'p-3',
      localId: 'local-1',
      nombre: 'Salteña',
      descripcion: '',
      precio: 9,
      emoji: '🥟',
      stock: 4,
      variantes: [
        VarianteProducto(id: 'a', nombre: 'Pollo'),
        VarianteProducto(id: 'b', nombre: 'Carne'),
      ],
    );
    // Ningun sabor cambia el precio: no hay nada que anunciar con "desde".
    expect(iguales.preciosVarian, isFalse);
    expect(iguales.precioMinimo, 9);
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
