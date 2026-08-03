import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Precio numérico con validación visual básica.
class CampoPrecioPublicacion extends StatelessWidget {
  const CampoPrecioPublicacion({required this.controlador, super.key});

  final TextEditingController controlador;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controlador,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
    ],
    decoration: const InputDecoration(
      hintText: 'Define el precio',
      prefixText: 'Bs ',
    ),
    validator: (valor) => double.tryParse(valor ?? '') == null
        ? 'Ingresa un precio valido.'
        : null,
  );
}
