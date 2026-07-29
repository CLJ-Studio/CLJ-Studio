import 'package:flutter/material.dart';

/// Barra persistente; el tercer espacio corresponde al botón `+` flotante.
class BarraNavegacionInferior extends StatelessWidget {
  const BarraNavegacionInferior({
    required this.indice,
    required this.alCambiar,
    super.key,
  });
  final int indice;
  final ValueChanged<int> alCambiar;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: alCambiar,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Locales',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Publicar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    ),
  );
}
