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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 1.5),
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
