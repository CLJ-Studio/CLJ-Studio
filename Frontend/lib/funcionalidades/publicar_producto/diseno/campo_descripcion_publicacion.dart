import 'package:flutter/material.dart';

/// Descripción multilínea del anuncio.
class CampoDescripcionPublicacion extends StatelessWidget {
  const CampoDescripcionPublicacion({required this.controlador, super.key});

  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controlador,
    maxLines: 4,
    decoration: const InputDecoration(
      labelText: 'Descripcion',
      alignLabelWithHint: true,
    ),
    validator: (valor) => valor == null || valor.trim().isEmpty
        ? 'Agrega una descripcion.'
        : null,
  );
}
