import 'package:flutter/material.dart';

/// Devuelve al acceso y elimina la navegación principal del historial.
class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({required this.alPresionar, super.key});
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: alPresionar,
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text('Cerrar sesion', style: TextStyle(color: Colors.red)),
    ),
  );
}
