import 'package:flutter/material.dart';

/// Aviso con reintento para cuando una carga del backend falla.
///
/// Antes estos fallos dejaban la pantalla en blanco sin explicacion.
class MensajeCatalogo extends StatelessWidget {
  const MensajeCatalogo({
    required this.mensaje,
    required this.alReintentar,
    this.icono = Icons.cloud_off_rounded,
    super.key,
  });

  final String mensaje;
  final VoidCallback alReintentar;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
    child: Column(
      children: [
        Icon(icono, size: 46, color: const Color(0xFFB8BDB8)),
        const SizedBox(height: 14),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF858585), height: 1.4),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: alReintentar,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.4),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text(
            'Reintentar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
