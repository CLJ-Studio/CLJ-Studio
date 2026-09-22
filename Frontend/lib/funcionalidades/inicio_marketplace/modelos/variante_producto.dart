/// Un sabor, un tamano, un color: una version de la misma publicacion.
///
/// Es solo un nombre a proposito. Una empanada de queso y una de carne son el
/// mismo producto, con la misma foto y el mismo precio; lo unico que cambia
/// es como se llama. Si algun dia una variante necesita precio propio, se
/// agrega aqui y en `product_variants`, pero mientras no haga falta no hay
/// que arrastrar ese peso por el carrito y el historial de pedidos.
class VarianteProducto {
  const VarianteProducto({required this.id, required this.nombre});

  factory VarianteProducto.desdeMapa(Map<String, dynamic> fila) =>
      VarianteProducto(
        id: fila['id'] as String,
        nombre: (fila['name'] as String?) ?? '',
      );

  final String id;
  final String nombre;

  @override
  bool operator ==(Object other) =>
      other is VarianteProducto &&
      other.id == id &&
      other.nombre == nombre;

  @override
  int get hashCode => Object.hash(id, nombre);
}
