import 'package:flutter/foundation.dart';

/// Producto sencillo administrado por el dueño del local.
class ProductoInventario {
  const ProductoInventario({
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  final String nombre;
  final double precio;
  final int cantidad;

  ProductoInventario copiarCon({int? cantidad}) => ProductoInventario(
    nombre: nombre,
    precio: precio,
    cantidad: cantidad ?? this.cantidad,
  );
}

/// Conserva el local creado y su inventario durante la sesión actual.
class ControladorMiLocal extends ChangeNotifier {
  String? nombre;
  String? descripcion;
  String logo = '🍽️';
  final List<ProductoInventario> productos = [];

  bool get tieneLocal => nombre != null;

  void crearLocal({
    required String nuevoNombre,
    required String nuevaDescripcion,
    required String nuevoLogo,
  }) {
    nombre = nuevoNombre.trim();
    descripcion = nuevaDescripcion.trim();
    logo = nuevoLogo;
    notifyListeners();
  }

  void agregarProducto({
    required String nombre,
    required double precio,
    required int cantidad,
  }) {
    productos.add(
      ProductoInventario(
        nombre: nombre.trim(),
        precio: precio,
        cantidad: cantidad,
      ),
    );
    notifyListeners();
  }

  void cambiarCantidad(int indice, int cambio) {
    final actual = productos[indice];
    final nuevaCantidad = (actual.cantidad + cambio).clamp(0, 999);
    productos[indice] = actual.copiarCon(cantidad: nuevaCantidad);
    notifyListeners();
  }

  void eliminarProducto(int indice) {
    productos.removeAt(indice);
    notifyListeners();
  }
}
