import 'package:flutter/material.dart';

/// Nombre obligatorio del producto o servicio.
class CampoNombrePublicacion extends StatelessWidget {
  const CampoNombrePublicacion({required this.controlador, super.key});

  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controlador,
    decoration: const InputDecoration(
      hintText: 'Un nombre claro para tu publicación',
      prefixIcon: Icon(Icons.sell_outlined),
    ),
    validator: (valor) => valor == null || valor.trim().length < 3
        ? 'Ingresa al menos 3 caracteres.'
        : null,
  );
}
