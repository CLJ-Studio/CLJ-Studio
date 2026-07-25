import '../funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';

/// Productos simulados vinculados mediante `localId`.
abstract final class ProductosPrueba {
  static const List<ProductoMarketplace> todos = [
    ProductoMarketplace(
      id: 'cafe',
      localId: 'cafeteria',
      nombre: 'Cafe americano',
      descripcion: 'Cafe recien preparado, 300 ml.',
      precio: 12,
      emoji: '☕',
    ),
    ProductoMarketplace(
      id: 'sandwich',
      localId: 'cafeteria',
      nombre: 'Sandwich universitario',
      descripcion: 'Jamon, queso y vegetales frescos.',
      precio: 22,
      emoji: '🥪',
    ),
    ProductoMarketplace(
      id: 'jugo',
      localId: 'snack',
      nombre: 'Jugo natural',
      descripcion: 'Fruta de temporada, sin conservantes.',
      precio: 15,
      emoji: '🥤',
    ),
    ProductoMarketplace(
      id: 'cable',
      localId: 'tech',
      nombre: 'Cable USB-C',
      descripcion: 'Cable reforzado de carga y datos.',
      precio: 45,
      emoji: '🔌',
    ),
    ProductoMarketplace(
      id: 'cuaderno',
      localId: 'libreria',
      nombre: 'Cuaderno universitario',
      descripcion: '100 hojas cuadriculadas.',
      precio: 28,
      emoji: '📓',
    ),
  ];
}
