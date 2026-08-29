import 'package:flutter/material.dart';

/// Botón de acceso institucional con Google.
class BotonContinuarGoogle extends StatelessWidget {
  const BotonContinuarGoogle({
    required this.habilitado,
    required this.alPresionar,
    super.key,
  });
  final bool habilitado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF474646),
          foregroundColor: Color(0xFFE6E1D5),
          disabledBackgroundColor: const Color(0xFFE6E1D5),
          shape: const StadiumBorder(),
        ),
        onPressed: habilitado ? alPresionar : null,
        icon: const Text(
          'G',
          style: TextStyle(
            color: Color(0xFF969A82),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        label: const Text('Continuar con Google'),
      ),
    );
  }
}
