import 'package:flutter/material.dart';

/// Categoría tipada usada por filtros y formularios.
class CategoriaMarketplace {
  const CategoriaMarketplace({
    required this.id,
    required this.nombre,
    required this.icono,
  });

  /// Mapea una fila de `categories`.
  factory CategoriaMarketplace.desdeMapa(Map<String, dynamic> fila) =>
      CategoriaMarketplace(
        id: fila['id'] as String,
        nombre: fila['name'] as String,
        icono: iconoPorNombre(fila['icon_name'] as String?),
      );

  /// Filtro de interfaz: no existe como fila en la base.
  static const todas = CategoriaMarketplace(
    id: 'todas',
    nombre: 'Todo',
    icono: Icons.grid_view_rounded,
  );

  /// Flutter elimina en compilacion los iconos que nadie referencia, asi que
  /// no se puede construir un IconData desde un codigo dinamico: hace falta
  /// este mapa explicito entre `categories.icon_name` y el icono real.
  static IconData iconoPorNombre(String? nombre) => switch (nombre) {
    'lunch_dining_rounded' => Icons.lunch_dining_rounded,
    'devices_rounded' => Icons.devices_rounded,
    'handyman_rounded' => Icons.handyman_rounded,
    'menu_book_rounded' => Icons.menu_book_rounded,
    'grid_view_rounded' => Icons.grid_view_rounded,
    _ => Icons.category_rounded,
  };

  final String id;
  final String nombre;
  final IconData icono;
}
