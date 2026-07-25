import 'package:flutter/material.dart';

import '../funcionalidades/inicio_marketplace/modelos/categoria_marketplace.dart';

/// Categorías temporales; serán reemplazadas por el endpoint `/categorias`.
abstract final class CategoriasPrueba {
  static const List<CategoriaMarketplace> todos = [
    CategoriaMarketplace(
      id: 'todas',
      nombre: 'Todo',
      icono: Icons.grid_view_rounded,
    ),
    CategoriaMarketplace(
      id: 'comida',
      nombre: 'Comida',
      icono: Icons.lunch_dining_rounded,
    ),
    CategoriaMarketplace(
      id: 'tecnologia',
      nombre: 'Tecnologia',
      icono: Icons.devices_rounded,
    ),
    CategoriaMarketplace(
      id: 'servicios',
      nombre: 'Servicios',
      icono: Icons.handyman_rounded,
    ),
    CategoriaMarketplace(
      id: 'papeleria',
      nombre: 'Papeleria',
      icono: Icons.edit_note_rounded,
    ),
    CategoriaMarketplace(
      id: 'libros',
      nombre: 'Libros',
      icono: Icons.menu_book_rounded,
    ),
    CategoriaMarketplace(
      id: 'otros',
      nombre: 'Otros',
      icono: Icons.more_horiz_rounded,
    ),
  ];
}
