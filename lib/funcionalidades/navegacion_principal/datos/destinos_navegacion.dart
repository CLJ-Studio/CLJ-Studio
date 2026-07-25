import 'package:flutter/material.dart';
import '../modelos/destino_navegacion.dart';

/// Configuración central de etiquetas e iconos de navegación.
abstract final class DestinosNavegacion {
  static const todos = [
    DestinoNavegacion(etiqueta: 'Inicio', icono: Icons.home_outlined),
    DestinoNavegacion(etiqueta: 'Locales', icono: Icons.storefront_outlined),
    DestinoNavegacion(etiqueta: 'Publicar', icono: Icons.add),
    DestinoNavegacion(
      etiqueta: 'Configuracion',
      icono: Icons.settings_outlined,
    ),
  ];
}
