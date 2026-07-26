import 'package:flutter/material.dart';

/// Explica por qué se solicita una cuenta institucional.
class MensajeAccesoExclusivo extends StatelessWidget {
  const MensajeAccesoExclusivo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Al continuar aceptas los términos y la política de privacidad. '
      'Acceso exclusivo para estudiantes UPSA.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 11, height: 1.45),
    );
  }
}
