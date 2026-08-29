import 'package:flutter/material.dart';

/// Devuelve al acceso y elimina la navegación principal del historial.
class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({required this.alPresionar, super.key});
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: alPresionar,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF474646),
        foregroundColor: Color(0xFFE6E1D5),
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: const Text(
        'Cerrar sesión',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
