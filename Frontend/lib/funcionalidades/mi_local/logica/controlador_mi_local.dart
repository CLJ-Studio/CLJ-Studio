import 'package:flutter/foundation.dart';

import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
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

  /// El stock baja solo cuando alguien compra: el inventario debe reflejarlo
  /// sin que el dueno recargue.
  late final _escucha = EscuchaTabla(
    tabla: 'products',
    alCambiar: _refrescarInventario,
  );

  void iniciarTiempoReal() => _escucha.iniciar();

  @override
  void dispose() {
    _escucha.detener();
    super.dispose();
  }

  Future<void> _refrescarInventario() async {
    if (local == null) return;
    try {
      productos = await _repositorio.cargarInventario(local!.id);
      notifyListeners();
    } catch (_) {
      // Se reintenta en el siguiente evento o sondeo.
    }
  }

  /// Hay donde publicar (local formal o espacio personal).
  bool get tieneLocal => local != null;

  /// Local formal abierto por el estudiante. Un espacio personal NO cuenta:
  /// la invitacion "Abre tu local" debe seguir visible para quien solo
  /// publica de manera casual.
  bool get tieneLocalFormal => local != null && !local!.esPersonal;

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

  /// Garantiza un contenedor donde publicar. Si el estudiante no tiene nada,
  /// crea el espacio personal por detras, sin pedirle abrir un local.
  Future<void> asegurarEspacioPersonal() async {
    if (local != null) return;
    local = await _repositorio.crearEspacioPersonal(
      nombreEstudiante: SesionUsuario.instancia.primerNombre,
    );
    productos = const [];
    notifyListeners();
  }

  Future<void> crearLocal({
    required String nuevoNombre,
    required String nuevaDescripcion,
    required String nuevoLogo,
    required String categoriaId,
    String? logoPath,
  }) async {
    local = await _repositorio.crearLocal(
      nombre: nuevoNombre.trim(),
      descripcion: nuevaDescripcion.trim(),
      emoji: nuevoLogo,
      categoriaId: categoriaId,
      logoPath: logoPath,
    );
    // Si venia de un espacio personal, el inventario ya publicado se
    // conserva: solo cambio la identidad del store.
    productos = await _repositorio.cargarInventario(local!.id);
    notifyListeners();
  }

  Future<void> agregarProducto({
    required String nombre,
    required double precio,
    required int cantidad,
    String emoji = '🛍️',
    String? descripcion,
    bool esServicio = false,
    List<String> galeria = const [],
  }) async {
    await asegurarEspacioPersonal();
    await _repositorio.agregarProducto(
      localId: local!.id,
      nombre: nombre.trim(),
      precio: precio,
      stock: cantidad,
      emoji: emoji,
      descripcion: descripcion,
      esServicio: esServicio,
      galeria: galeria,
    );
    // Se relee el inventario para tomar el id que genero la base.
    productos = await _repositorio.cargarInventario(local!.id);
    notifyListeners();
  }

  Future<void> editarProducto({
    required String productoId,
    required String nombre,
    required double precio,
    required int cantidad,
    required String emoji,
    String? descripcion,
    List<String> galeria = const [],
  }) async {
    await _repositorio.editarProducto(
      productoId: productoId,
      nombre: nombre.trim(),
      precio: precio,
      stock: cantidad,
      emoji: emoji,
      descripcion: descripcion,
      galeria: galeria,
    );
    await _refrescarInventario();
  }

  /// Ocultar conserva la publicacion; borrar la elimina para siempre.
  Future<void> cambiarVisibilidad(int indice) async {
    final producto = productos[indice];
    final visible = !producto.disponible;

    productos = [...productos]
      ..[indice] = producto.copiarCon(disponible: visible);
    notifyListeners();

    try {
      await _repositorio.cambiarVisibilidad(producto.id, visible: visible);
    } catch (_) {
      productos = [...productos]..[indice] = producto;
      error = 'No se pudo cambiar la visibilidad.';
      notifyListeners();
    }
  }

  /// Vuelve a poner la publicacion al tope del catalogo.
  Future<void> relanzarProducto(int indice) async {
    try {
      await _repositorio.relanzarProducto(productos[indice].id);
      await _refrescarInventario();
    } catch (_) {
      error = 'No se pudo relanzar la publicación.';
      notifyListeners();
    }
  }

  Future<void> cambiarCantidad(int indice, int cambio) async {
    final producto = productos[indice];
    final nuevoStock = (producto.stock + cambio).clamp(0, 999);
    if (nuevoStock == producto.stock) return;

    // Se refleja de inmediato y se revierte si el servidor rechaza.
    final anteriores = List<ProductoMarketplace>.from(productos);
    productos = [...productos]
      ..[indice] = producto.copiarCon(stock: nuevoStock);
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
