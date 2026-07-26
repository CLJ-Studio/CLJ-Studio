import 'package:flutter/material.dart';

/// Confirma únicamente la validación local del formulario.
class BotonConfirmarPublicacion extends StatelessWidget {
  const BotonConfirmarPublicacion({required this.alPresionar, super.key});
  final VoidCallback alPresionar;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: alPresionar,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF5C8A63),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 17),
      ),
      icon: const Icon(Icons.publish_rounded),
      label: const Text(
        'Publicar',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
