/// Un sabor, un tamano, un color: una version de la misma publicacion.
///
/// El precio es OPCIONAL. Nulo significa "vale lo que el producto", que es el
/// caso normal: quien vende empanadas de queso y de carne al mismo precio no
/// tiene que escribirlo dos veces. Ponerlo solo hace falta cuando un sabor
/// cuesta distinto, y entonces ese precio manda sobre el del producto.
class VarianteProducto {
  const VarianteProducto({required this.id, required this.nombre, this.precio});

  factory VarianteProducto.desdeMapa(Map<String, dynamic> fila) =>
      VarianteProducto(
        id: fila['id'] as String,
        nombre: (fila['name'] as String?) ?? '',
        precio: (fila['price'] as num?)?.toDouble(),
      );

  final String id;
  final String nombre;

  /// Nulo si esta variante no cambia el precio del producto.
  final double? precio;

  /// Lo que cuesta esta variante sabiendo cuanto cuesta el producto.
  double precioSobre(double precioProducto) => precio ?? precioProducto;

  @override
  bool operator ==(Object other) =>
      other is VarianteProducto &&
      other.id == id &&
      other.nombre == nombre &&
      other.precio == precio;

  @override
  int get hashCode => Object.hash(id, nombre, precio);
}

/// Una variante tal como se escribe en el formulario, todavia sin id.
///
/// Es un tipo aparte de [VarianteProducto] a proposito: alli el id siempre
/// existe porque viene del servidor, y el carrito y los pedidos dependen de
/// eso. Aqui todavia no hay nada guardado.
class VarianteEditable {
  const VarianteEditable({required this.nombre, this.precio});

  factory VarianteEditable.desdeJson(Map<String, dynamic> json) =>
      VarianteEditable(
        nombre: (json['nombre'] as String?) ?? '',
        precio: (json['precio'] as num?)?.toDouble(),
      );

  final String nombre;

  /// Nulo si vale lo mismo que el producto.
  final double? precio;

  Map<String, dynamic> aJson() => {'nombre': nombre, 'precio': precio};

  VarianteEditable copiarCon({String? nombre, double? precio, bool? sinPrecio}) =>
      VarianteEditable(
        nombre: nombre ?? this.nombre,
        precio: (sinPrecio ?? false) ? null : (precio ?? this.precio),
      );
}
