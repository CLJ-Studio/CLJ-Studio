import 'package:flutter/material.dart';

/// Categoría tipada usada por filtros y formularios.
class CategoriaMarketplace {
  const CategoriaMarketplace({
    required this.id,
    required this.nombre,
    required this.icono,
  });

  final String id;
  final String nombre;
  final IconData icono;
}
