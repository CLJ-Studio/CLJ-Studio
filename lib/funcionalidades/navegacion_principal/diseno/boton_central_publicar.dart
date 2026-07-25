import 'package:flutter/material.dart';

/// Acción central destacada para crear publicaciones.
class BotonCentralPublicar extends StatelessWidget {
  const BotonCentralPublicar({
    required this.activo,
    required this.alPresionar,
    super.key,
  });
  final bool activo;
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => FloatingActionButton(
    onPressed: alPresionar,
    tooltip: 'Publicar',
    elevation: activo ? 5 : 1,
    child: const Icon(Icons.add_rounded, size: 30),
  );
}
