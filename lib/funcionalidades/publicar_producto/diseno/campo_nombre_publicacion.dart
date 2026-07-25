import 'package:flutter/material.dart';

/// Nombre obligatorio del producto o servicio.
class CampoNombrePublicacion extends StatelessWidget {
  const CampoNombrePublicacion({super.key});
  @override
  Widget build(BuildContext context) => TextFormField(
    decoration: const InputDecoration(
      labelText: 'Nombre',
      prefixIcon: Icon(Icons.sell_outlined),
    ),
    validator: (valor) => valor == null || valor.trim().length < 3
        ? 'Ingresa al menos 3 caracteres.'
        : null,
  );
}
