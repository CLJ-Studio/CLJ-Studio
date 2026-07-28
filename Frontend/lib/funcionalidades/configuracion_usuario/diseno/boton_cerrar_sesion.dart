import 'package:flutter/material.dart';

/// Devuelve al acceso y elimina la navegación principal del historial.
class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({
    required this.alPresionar,
    this.oscuro = false,
    super.key,
  });
  final VoidCallback alPresionar;
  final bool oscuro;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: alPresionar,
      style: FilledButton.styleFrom(
        backgroundColor: oscuro
            ? const Color(0xFF5C8A63)
            : const Color(0xFFEFF84D),
        foregroundColor: oscuro ? Colors.white : const Color(0xFF223C24),
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
