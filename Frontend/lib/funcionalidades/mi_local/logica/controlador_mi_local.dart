import 'package:flutter/foundation.dart';

import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../datos/repositorio_mi_local.dart';

/// Local del estudiante y su inventario, persistidos en Supabase.
class ControladorMiLocal extends ChangeNotifier {
  ControladorMiLocal([this._repositorio = const RepositorioMiLocal()]);

  final RepositorioMiLocal _repositorio;

  LocalUniversitario? local;
  List<ProductoMarketplace> productos = const [];
  bool cargando = true;
  String? error;

  bool get tieneLocal => local != null;

  // Comodidades para la pantalla, que solo necesita mostrar estos datos.
  String? get nombre => local?.nombre;
  String? get descripcion => local?.descripcion;
  String get logo => local?.emoji ?? '🍽️';

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      local = await _repositorio.cargarLocal();
      productos = local == null
          ? const []
          : await _repositorio.cargarInventario(local!.id);
    } catch (_) {
      error = 'No se pudo cargar tu local.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> crearLocal({
    required String nuevoNombre,
    required String nuevaDescripcion,
    required String nuevoLogo,
    required String categoriaId,
  }) async {
    local = await _repositorio.crearLocal(
      nombre: nuevoNombre.trim(),
      descripcion: nuevaDescripcion.trim(),
      emoji: nuevoLogo,
      categoriaId: categoriaId,
    );
    productos = const [];
    notifyListeners();
  }

  Future<void> agregarProducto({
    required String nombre,
    required double precio,
    required int cantidad,
    String emoji = '🛍️',
  }) async {
    if (local == null) return;
    await _repositorio.agregarProducto(
      localId: local!.id,
      nombre: nombre.trim(),
      precio: precio,
      stock: cantidad,
      emoji: emoji,
    );
    // Se relee el inventario para tomar el id que genero la base.
    productos = await _repositorio.cargarInventario(local!.id);
    notifyListeners();
  }

  Future<void> cambiarCantidad(int indice, int cambio) async {
    final producto = productos[indice];
    final nuevoStock = (producto.stock + cambio).clamp(0, 999);
    if (nuevoStock == producto.stock) return;

    // Se refleja de inmediato y se revierte si el servidor rechaza.
    final anteriores = List<ProductoMarketplace>.from(productos);
    productos = [...productos]..[indice] = ProductoMarketplace(
      id: producto.id,
      localId: producto.localId,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      precio: producto.precio,
      emoji: producto.emoji,
      stock: nuevoStock,
      esServicio: producto.esServicio,
    );
    notifyListeners();

    try {
      await _repositorio.cambiarStock(producto.id, nuevoStock);
    } catch (_) {
      productos = anteriores;
      error = 'No se pudo actualizar el stock.';
      notifyListeners();
    }
  }

  Future<void> eliminarProducto(int indice) async {
    final producto = productos[indice];
    final anteriores = List<ProductoMarketplace>.from(productos);

    productos = [...productos]..removeAt(indice);
    notifyListeners();

    try {
      await _repositorio.eliminarProducto(producto.id);
    } catch (_) {
      productos = anteriores;
      error = 'No se pudo eliminar el producto.';
      notifyListeners();
    }
  }

  Future<void> cambiarDisponibilidad({required bool abierto}) async {
    if (local == null) return;
    await _repositorio.cambiarDisponibilidad(local!.id, abierto: abierto);
    await cargar();
  }
}
